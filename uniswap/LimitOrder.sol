pragma solidity ^0.6.6;

import './UniswapRouter.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract LimitSwap{
    uint256 public flatcost = 2 finney;
    
    uint256 public paymentsFulfilled;
    address public admin;
    uint64 public currentid;
    address public uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router uniswapRouter;
    
    mapping(uint64 => address) requester;
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
    receive() external payable {
        revert(); //revert mistaken eth
    }
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
    function fulfillSwap(uint64 id, address[] calldata path) external {
        require(id <= currentid, 'invalid id');
        
        if(inaddress[id] == address(0)){
            if(outexact[id]){
                uniswapRouter.swapETHForExactTokens{value: inamt[id]}(
                    outamt[id], path, requester[id], deadline[id]
                    );
            }else{
               uniswapRouter.swapExactETHForTokens{value: inamt[id]}(
                   outamt[id], path, requester[id], deadline[id]
                   ); 
            }
        } else if(outaddress[id] == address(0)){
            if(outexact[id]){
                uniswapRouter.swapTokensForExactETH(
                    outamt[id], inamt[id], path, requester[id], deadline[id]
                    );
            }else{
                uniswapRouter.swapExactTokensForETH(
                    inamt[id], outamt[id], path, requester[id], deadline[id]
                    );
            }
        } else {
            require(path[0] == inaddress[id] && path[path.length - 1] == outaddress[id], 'invalid path');
            if(outexact[id]){
                uniswapRouter.swapTokensForExactTokens(
                    inamt[id], outamt[id], path, requester[id], deadline[id]
                    );
            }else{
                uniswapRouter.swapExactTokensForTokens(
                    outamt[id], inamt[id], path, requester[id], deadline[id]
                    );
            }
        }
        emit Fulfilled(id, msg.sender, path);
    }
    function batchRefund(uint64[] memory ids) external {
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
    event Fulfilled(uint64 indexed id, address indexed fulfiller, address[] path);
}