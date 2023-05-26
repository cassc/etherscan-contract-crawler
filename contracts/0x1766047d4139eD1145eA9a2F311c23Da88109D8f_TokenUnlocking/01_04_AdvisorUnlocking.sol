// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenUnlocking is Ownable {
    address public immutable lbr;

    mapping(address => UnlockingRule) public UnlockingInfo;

    event Withdraw(address indexed _user, uint256 _amount, uint256 _timestamp);
    event WithdrawDirect(
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );

    event SetUnlockingRules(
        address indexed _user,
        uint256 _directUnlock,
        uint256 directUnlockTime,
        uint256 _totalLocked,
        uint256 _duration,
        uint256 _unlockStartTime,
        uint256 _lastWithdrawTime
    );

    constructor(address _lbr) {
        lbr = _lbr;
    }

    struct UnlockingRule {
        uint256 directUnlock;
        uint256 directUnlockTime;
        uint256 totalLocked;
        uint256 duration;
        uint256 unlockStartTime;
        uint256 lastWithdrawTime;
    }

    function setUnlockingRules(
        address _user,
        uint256 _directUnlock,
        uint256 _directUnlockTime,
        uint256 _duration,
        uint256 _totalLocked,
        uint256 _unlockStartTime
    ) external onlyOwner {
       
        UnlockingInfo[_user].directUnlock = _directUnlock;
        UnlockingInfo[_user].directUnlockTime = _directUnlockTime;
        UnlockingInfo[_user].totalLocked = _totalLocked;
        UnlockingInfo[_user].duration = _duration;
        UnlockingInfo[_user].unlockStartTime = _unlockStartTime;
        UnlockingInfo[_user].lastWithdrawTime = _unlockStartTime;
        emit SetUnlockingRules(
            _user,
            _directUnlock,
            _directUnlockTime,
            _totalLocked,
            _duration,
            _unlockStartTime,
            _unlockStartTime
        );
    }

    function getUserUnlockingInfo(
        address _user
    ) external view returns (UnlockingRule memory) {
        return UnlockingInfo[_user];
    }

    function getClaimableAmount(address _user) public view returns (uint256) {
        if (
            block.timestamp <= UnlockingInfo[_user].unlockStartTime ||
            UnlockingInfo[_user].unlockStartTime == 0
        ) return 0;
        uint256 unlockEndTime = UnlockingInfo[_user].unlockStartTime +
            UnlockingInfo[_user].duration;
        uint256 unstakeRate = UnlockingInfo[_user].totalLocked /
            UnlockingInfo[_user].duration;
        uint256 reward = block.timestamp > unlockEndTime
            ? (unlockEndTime - UnlockingInfo[_user].lastWithdrawTime) *
                unstakeRate
            : (block.timestamp - UnlockingInfo[_user].lastWithdrawTime) *
                unstakeRate;
        return reward;
    }

    function withdraw() public {
        require(
            block.timestamp >= UnlockingInfo[msg.sender].unlockStartTime,
            "The time has not yet arrived."
        );
        uint256 unlockEndTime = UnlockingInfo[msg.sender].unlockStartTime +
            UnlockingInfo[msg.sender].duration;
        uint256 amount = getClaimableAmount(msg.sender);

        if (amount > 0) {
            if (block.timestamp > unlockEndTime) {
                UnlockingInfo[msg.sender].lastWithdrawTime = unlockEndTime;
            } else {
                UnlockingInfo[msg.sender].lastWithdrawTime = block.timestamp;
            }

            IERC20(lbr).transfer(msg.sender, amount);
            emit Withdraw(msg.sender, amount, block.timestamp);
        }
    }

    function withdrawDirect() public {
        require(
            block.timestamp >= UnlockingInfo[msg.sender].directUnlockTime,
            "The time has not yet arrived."
        );
        uint256 amount = UnlockingInfo[msg.sender].directUnlock;
        UnlockingInfo[msg.sender].directUnlock = 0;
        if (amount > 0) {
            IERC20(lbr).transfer(msg.sender, amount);
            emit WithdrawDirect(msg.sender, amount, block.timestamp);
        }
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }
}