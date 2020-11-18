//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract Tokenview is ERC20{
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    uint256 public pricepertoken = 25000000000000;
    uint256 public supplycap = 90000000000000000000000000;
    address public owner;
    bool public paused;
    
    /**
     * @param o set as owner admin 
     **/
    constructor(address o) public ERC20("Tokenview", "TKNV") {
        _mint(o, 50000000000000000000000000);
        owner = o;
    }
    
    //User
    /**
     * @dev 1 * 10^18 represents 1 TKNV
     * */
    function purchaseTokens() external payable {
        require(!paused, 'Purchasing is currently disabled');
        require(msg.value >= pricepertoken, "Insufficient payment, you must buy at least 1 token");
        _transfer(owner, msg.sender, msg.value/pricepertoken*1000000000000000000);
    }
    
    //Admin
    /**
     *@param amt the number of tokens to mint 
     **/
    function mintTokens(uint256 amt) public onlyOwner {
        require(totalSupply() + amt <= supplycap, 'Exceeded supply cap');
        _mint(msg.sender, amt);
    }
    
    /**
     * @dev burns tokens from owner
     * @param amt the number of tokens to burn
     **/
    function burnTokens(uint256 amt) public onlyOwner {
        _burn(owner, amt);
    }
    
    /**
     * @param newprice price per token to set
     **/
    function setPrice(uint256 newprice) public onlyOwner {
        pricepertoken = newprice;
    }
    /**
     * @dev turns paused on/off
     **/
    function switchPause() public onlyOwner{
        paused = !paused;
    }
    /**
     * @dev withdraws all eth from contract
     **/
    function foundationWithdraw() public onlyOwner{
        msg.sender.transfer(address(this).balance);
    }
}