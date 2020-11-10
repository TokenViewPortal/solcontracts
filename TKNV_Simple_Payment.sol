// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TKNV_Simple_Payment{
    address owner;
    mapping(address => uint256) deposited;
    
    constructor(address o) public {
        owner = o;
    }
    
    function deposit() public payable {
        deposited[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    } 
    
    function ownerWithdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    
    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    event Deposit(address indexed user, uint256 amt);
}