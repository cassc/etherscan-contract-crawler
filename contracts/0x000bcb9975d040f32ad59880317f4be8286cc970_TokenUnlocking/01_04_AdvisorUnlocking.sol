// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenUnlocking is Ownable {
    address public immutable lbr;

    mapping(address => UnlockingRule) public UnlockingInfo;
    mapping(address => bool) _paused;

    event Withdraw(address indexed _addr, uint256 _amount, uint256 _timestamp);
  
    event SetUnlockRule(
        address indexed _addr,
        uint256 _totalLocked,
        uint256 _duration,
        uint256 _unlockStartTime,
        uint256 _lastWithdrawTime
      
    );


    constructor(address _lbr) {
        lbr = _lbr;
    }

    struct UnlockingRule {
        uint256 totalLocked;
        uint256 duration;
        uint256 unlockStartTime;
        uint256 lastWithdrawTime;
        address[] whitelist;
    }

    modifier whenNotPaused(address _user) {
        require(!_paused[_user], "Vest is paused.");
        _;
    }

    function setPause(address _user, bool val) external onlyOwner {
        _paused[_user] = val;
    }

    function setUnlockRule(
        address _addr,
        uint256 _totalLocked,
        uint256 _duration,
        uint256 _unlockStartTime,
        uint256 _lastWithdrawTime,
        address[] calldata _whitelist
    ) external onlyOwner {
        require(_unlockStartTime != 0, "Invalid time");
        require(
            UnlockingInfo[_addr].lastWithdrawTime == 0,
            "This rule has already been set."
        );
        UnlockingInfo[_addr].totalLocked = _totalLocked;
        UnlockingInfo[_addr].unlockStartTime = _unlockStartTime;
        UnlockingInfo[_addr].lastWithdrawTime = _lastWithdrawTime;
        UnlockingInfo[_addr].duration = _duration;
        UnlockingInfo[_addr].whitelist = _whitelist;
        emit SetUnlockRule(
            _addr,
            _totalLocked,
            _duration,
            _unlockStartTime,
            _lastWithdrawTime
        );
    }

    function addWhitelistAddresses(
        address addr,
        address[] calldata addrs
    ) external  {
        require(_checkWhitelist(addr), "The account is not in the whitelist.");
        UnlockingInfo[addr].whitelist = addrs;
    }

    function _checkWhitelist(address _addr) internal view returns(bool) {
        
        address[] storage whitelist = UnlockingInfo[_addr].whitelist;
        bool isWhitelist = false;
        for(uint256 i=0; i< whitelist.length;i++){
            if(whitelist[i] == msg.sender){
                isWhitelist = true;
                break;
            }
        }
        return isWhitelist;
    }


    function getUserUnlockInfo(
        address _addr
    ) external view returns (UnlockingRule memory) {
        return UnlockingInfo[_addr];
    }

    function getRewards(address addr) public view returns (uint256) {
        if (
            block.timestamp <= UnlockingInfo[addr].unlockStartTime ||
            UnlockingInfo[addr].unlockStartTime == 0
        ) return 0;
        
        uint256 unlockEndTime = UnlockingInfo[addr].unlockStartTime + UnlockingInfo[addr].duration;
        uint256 rate = UnlockingInfo[addr].totalLocked / UnlockingInfo[addr].duration;
        uint256 reward = block.timestamp > unlockEndTime ? (unlockEndTime - UnlockingInfo[addr].lastWithdrawTime) * rate : (block.timestamp - UnlockingInfo[addr].lastWithdrawTime) * rate;
        return reward;
        
    }

    function withdraw(address addr) external whenNotPaused(addr) {
        require(_checkWhitelist(addr), "The account is not in the whitelist.");
        require(block.timestamp >= UnlockingInfo[addr].unlockStartTime, "The time has not yet arrived.");
        uint256 unlockEndTime = UnlockingInfo[addr].unlockStartTime + UnlockingInfo[addr].duration;
        uint256 canClaimAmount = getRewards(addr);
       
        if (canClaimAmount > 0) {
             if (block.timestamp > unlockEndTime) {
                UnlockingInfo[addr].lastWithdrawTime = unlockEndTime;
            } else {
                UnlockingInfo[addr].lastWithdrawTime = block.timestamp;
            }
            IERC20(lbr).transfer(msg.sender, canClaimAmount);
            emit Withdraw(addr, canClaimAmount, block.timestamp);
        }
    }

    function withdrawTokenEmergency(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }


 
}