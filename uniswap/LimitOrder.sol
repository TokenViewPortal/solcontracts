pragma solidity ^0.6.6;

import './UniswapRouter.sol';

contract LimitOrder{
    uint256 public flatcost = 2 finney;
    
    uint256 public paymentsFulfilled;
    address public admin;
    uint64 public currentid;
    address public uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router uniswapRouter;
    
    mapping(uint64 => address payable) requester;
    mapping(uint64 => address) inaddress;
    mapping(uint64 => address) outaddress;
    mapping(uint64 => uint256) inamt;
    mapping(uint64 => uint256) outamt;
    mapping(uint64 => uint256) deadline; 
    mapping(uint64 => bool) outexact;
    mapping(address => mapping(uint64 => uint256)) public paymentBalance;
    
    constructor() public {
        admin = msg.sender;
        uniswapRouter = IUniswapV2Router(uniswapRouterAddress);
    }
    receive() external payable {}
    /**
	 * @dev adds inamount to paymentBalance, so that eth given to contract, but not fulfilled, can be refunded
	 * */
	function requestSwapExactTokenForTokens(address intoken, address outtoken, uint256 inamount, uint256 minoutamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost, 'invalid payment');
	 
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = intoken;
	    outaddress[currentid] = outtoken;
	    inamt[currentid] = inamount;
	    outamt[currentid] = minoutamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = false;
	    
	    ERC20 it = ERC20(intoken);
	    it.transferFrom(msg.sender, address(this), inamount); //transfer tokens from user to this
	    it.approve(uniswapRouterAddress, inamount); //approve uniswap router to spend tokens
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
	/**
	 * @dev adds inamount to paymentBalance, so that eth given to contract, but not fulfilled, can be refunded
	 * */
	function requestSwapTokenForExactTokens(address intoken, address outtoken, uint256 inamount, uint256 outamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost, 'invalid payment');
	    
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = intoken;
	    outaddress[currentid] = outtoken;
	    inamt[currentid] = inamount;
	    outamt[currentid] = outamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = true;
	    
	    ERC20 it = ERC20(intoken);
	    it.transferFrom(msg.sender, address(this), inamount); //transfer tokens from user to this
	    it.approve(uniswapRouterAddress, inamount); //approve uniswap router to spend tokens
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
	/**
	 * @dev adds inamount to paymentBalance, so that eth given to contract, but not fulfilled, can be refunded
	 * */
	function requestSwapExactETHForTokens(address outtoken, uint256 inamount, uint256 outamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost + inamount, 'invalid payment');
	    
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost + inamount;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = address(0);
	    outaddress[currentid] = outtoken;
	    inamt[currentid] = inamount;
	    outamt[currentid] = outamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = true;
	    
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
	/**
	 * @dev adds inamount to paymentBalance, so that eth given to contract, but not fulfilled, can be refunded
	 * */
	function requestSwapEthForExactTokens(address outtoken, uint256 inamount, uint256 outamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost + inamount, 'invalid payment');
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost + inamount;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = address(0);
	    outaddress[currentid] = outtoken;
	    inamt[currentid] = inamount;
	    outamt[currentid] = outamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = true;
	    
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
	function requestSwapTokensForExactETH(address intoken, uint256 inamount, uint256 outamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost, 'invalid payment');
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = intoken;
	    outaddress[currentid] = address(0);
	    inamt[currentid] = inamount;
	    outamt[currentid] = outamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = true;
	    
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
	function requestSwapExactTokensForETH(address intoken, uint256 inamount, uint256 outamount, uint256 expiretime) 
	external payable{
	    require(msg.value == flatcost, 'invalid payment');
	    currentid++;
	    paymentBalance[msg.sender][currentid] += flatcost;
	    requester[currentid] = msg.sender;
	    inaddress[currentid] = intoken;
	    outaddress[currentid] = address(0);
	    inamt[currentid] = inamount;
	    outamt[currentid] = outamount;
	    deadline[currentid] = expiretime;
	    outexact[currentid] = true;
	    
	    emit Requested(currentid, msg.sender, inamt[currentid], outamt[currentid], expiretime, outexact[currentid]);
	}
    function fulfillSwap(uint64 id, address[] memory path) external {
        require(id <= currentid, 'invalid id');
        if(inaddress[id] == address(0)){
            uniswapRouter.swapETHForExactTokens{value: inamt[id]}(
                outamt[id], path, requester[id], deadline[id]
                );
            //safeTransfer(outaddress[id], requester[id], outamt[id]/2);
            //erc20 = ERC20(outaddress[id]);
            //erc20.transfer(requester[id], outamt[id]);
        } else if(outaddress[id] == address(0)){
            ERC20 spending = ERC20(path[0]);
            spending.approve(uniswapRouterAddress, inamt[id]);
            uniswapRouter.swapTokensForExactETH(
                outamt[id], inamt[id], path, requester[id], deadline[id]
                );
            requester[id].transfer(outamt[id]);
        } else {
            require(path[0] == inaddress[id] && path[path.length - 1] == outaddress[id], 'invalid path');
            ERC20 spending = ERC20(path[0]);
            spending.approve(uniswapRouterAddress, inamt[id]);
            uniswapRouter.swapTokensForExactTokens(
                inamt[id], outamt[id], path, requester[id], deadline[id]
                );
        }
        emit Fulfilled(id, msg.sender,  outamt[id], path);
    }
    function batchRefundTokens(uint64[] memory ids) external {
        address tokenaddress = outaddress[ids[0]];
        uint256 refund;
        uint64[] memory successfulRefunds = new uint64[](ids.length);
        for(uint i = 0; i < ids.length; i++){
            require(requester[ids[i]] == msg.sender || admin == msg.sender);
            require(outaddress[ids[i]] == tokenaddress, "You may only batch refunds for the same token address");
            if(paymentBalance[msg.sender][ids[i]] > 0){
                successfulRefunds[i] = ids[i];
                refund += paymentBalance[msg.sender][ids[i]];
                paymentBalance[msg.sender][ids[i]] = 0;
            }
        }
        ERC20 t = ERC20(tokenaddress);
        t.transfer(msg.sender, refund);
        emit Refunded(successfulRefunds);
    }
    function batchRefundEth(uint64[] memory ids) external {
        uint256 refund;
        uint64[] memory successfulRefunds = new uint64[](ids.length);
        for(uint i = 0; i < ids.length; i++){
            require(requester[ids[i]] == msg.sender || admin == msg.sender);
            if(paymentBalance[msg.sender][ids[i]] > 0){
                successfulRefunds[i] = ids[i];
                refund += paymentBalance[msg.sender][ids[i]];
                paymentBalance[msg.sender][ids[i]] = 0;
            }
        }
        msg.sender.transfer(refund);
        emit Refunded(successfulRefunds);
    }
    //admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }
    function withdrawPayments() external onlyAdmin{
        msg.sender.transfer(paymentsFulfilled);
    }
    function setAdmin(address newadmin) external onlyAdmin{
        admin = newadmin;
    }
    function setCost(uint256 newCost) external onlyAdmin{
        flatcost = newCost;
    }
    function setUni(address newUniAddress) external onlyAdmin {
        uniswapRouterAddress = newUniAddress;
        uniswapRouter = IUniswapV2Router(newUniAddress);
    }
    event Refunded(uint64[] ids);
    event Requested(uint64 indexed id, address indexed requester, uint256 inamt, uint256 outamt, uint256 deadline, bool outexact);
    event Fulfilled(uint64 indexed id, address indexed fulfiller, uint256 outamt, address[] path);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}