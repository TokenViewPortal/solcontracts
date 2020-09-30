//"SPDX-License-Identifier: MIT"
pragma solidity ^0.6.0;

interface Tokenview{
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
}

contract TokenviewVestments{
    
    uint256 totalVested;
    address owner;
    uint32 public bucketID;
    address tknvContractAddress;
    Tokenview tknv;
    
    mapping(uint32 => address[]) public beneficiaries;
    mapping(uint32 => uint256) public totalTokensLocked;
    mapping(uint32 => uint256) public lockTime;
    mapping(uint32 => uint256) public unlockTimestep;
    mapping(uint32 => uint256) public unlockFinal;
    mapping(uint32 => mapping(address => uint256)) public withdrawn;
    
    constructor(address _owner, address _tknvAddress) public {
        owner = _owner;
        tknvContractAddress = _tknvAddress;
        tknv = Tokenview(_tknvAddress);
    }
    
    //reverts if eth is sent to contract
    receive() external payable{
        revert();
    }
    
    //User
    /**
     * @param ID the contract bucketID
     * @dev withdraws all available unlocked tokens
     **/
    function Withdraw(uint32 ID) public {
        bool found;
        for(uint i = 0; i < beneficiaries[ID].length; i++){
            if(msg.sender == beneficiaries[ID][i]){ found = true; }
        }
        uint256 currentWithdrawn = withdrawn[ID][msg.sender];
        
        require(found, "Sender must be a beneficiary of bucketID");
        require(((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length) - currentWithdrawn > 0, "No unlocked tokens available");
        
        if((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length
            > totalTokensLocked[ID] / beneficiaries[ID].length){
            withdrawn[ID][msg.sender] += totalTokensLocked[ID] / beneficiaries[ID].length - currentWithdrawn;
            totalVested -= totalTokensLocked[ID] / beneficiaries[ID].length - currentWithdrawn;
            tknv.transfer(msg.sender, totalTokensLocked[ID] / beneficiaries[ID].length - currentWithdrawn);
        }else{
            withdrawn[ID][msg.sender] += ((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length) - currentWithdrawn;
            totalVested -= ((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length) - currentWithdrawn;
            tknv.transfer(msg.sender, ((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length) - currentWithdrawn);
        }
    }
    
    function CheckAvailableAmount(uint32 ID) public view returns (uint256){
        bool found;
        for(uint i = 0; i < beneficiaries[ID].length; i++){
            if(msg.sender == beneficiaries[ID][i]){ found = true; }
        }
        if(!found){return 0;}
        
        if((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length
            > totalTokensLocked[ID] / beneficiaries[ID].length){
            return totalTokensLocked[ID] / beneficiaries[ID].length - withdrawn[ID][msg.sender];
        }else{
            return((block.timestamp - lockTime[ID])/unlockTimestep[ID] * (totalTokensLocked[ID] / ((unlockFinal[ID] - lockTime[ID])/unlockTimestep[ID])) / beneficiaries[ID].length) - withdrawn[ID][msg.sender];
        }
    }
    
    //Admin
    function VestDaily(address[] memory _beneficiaries, uint256 _totalTokens, uint _days) public {
        ConfigVest(_beneficiaries, _totalTokens, 1 days, 1 days * _days + block.timestamp);
    }
    
    function VestWeekly(address[] memory _beneficiaries, uint256 _totalTokens, uint _weeks) public {
        ConfigVest(_beneficiaries, _totalTokens, 7 days, 7 days * _weeks + block.timestamp);
    }
    
    function VestMonthly(address[] memory _beneficiaries, uint256 _totalTokens, uint _months) public {
        ConfigVest(_beneficiaries, _totalTokens, 30 days, 30 days * _months + block.timestamp);
    }
    
    /**
    * @dev will leave dust if number of beneficiaries is not a multiple of totalTokensLocked
    **/
    function ConfigVest(address[] memory _beneficiaries, uint256 _totalTokens, uint256 _unlockTimestep, uint256 _unlockFinal) public {
        require(msg.sender == owner, "Sender must be owner");
        require(_totalTokens > 0, "Trying to vest 0 tokens");
        require(tknv.balanceOf(address(this)) - totalVested >= _totalTokens, "First send TKNV tokens to cover the vest");
        bucketID += 1;
        beneficiaries[bucketID] = _beneficiaries;
        totalTokensLocked[bucketID] = _totalTokens;
        unlockTimestep[bucketID] = _unlockTimestep;
        unlockFinal[bucketID] = _unlockFinal;
        lockTime[bucketID] = block.timestamp;
        totalVested += _totalTokens;
        
        emit Vested(bucketID, _beneficiaries, _totalTokens, _unlockTimestep, _unlockFinal);
    }
    
    function SetOwner(address newOwner) public {
        require(msg.sender == owner, "Sender must be owner");
        owner = newOwner;
    }
    
    event Vested(uint32 indexed bucketID, address[] beneficiaries, uint256 totalTokens, uint256 unlockTimestep, uint256 unlockFinal);
}