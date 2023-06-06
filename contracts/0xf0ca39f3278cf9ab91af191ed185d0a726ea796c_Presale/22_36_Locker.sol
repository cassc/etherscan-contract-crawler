// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Locker {

    LockerInfo private lockerInfo;
    
    uint immutable public updateFee;
    address immutable public master;

    enum Status {LOCKED, REDEEMED}

    struct LockerInfo {
        uint id;
        address owner; 
        IERC20 token;
        uint numOfTokensLocked;
        uint unlockTime;
        uint lockTime;
        Status status;
    }

    event LockerUpdated (uint id, uint numOfTokens, uint unlockTime, uint status);
    event LockerUnlocked (uint id, uint numOfTokens, uint unlockTime, uint status);

    constructor (
        uint _lockerID, 
        address _owner, 
        IERC20 _token, 
        uint _numOfTokens, 
        uint _unlockTime,
        uint _updateFee
    ) 
    {
        updateFee = _updateFee;
        master = payable(msg.sender);
        lockerInfo = LockerInfo(_lockerID, _owner, _token, _numOfTokens, _unlockTime, block.timestamp, Status.LOCKED);    
    }

    /// @notice this is the function to increase locker time
    /// @param additionTimeInSeconds should be in seconds 
    function addMoreTimeToLocker(uint additionTimeInSeconds) public payable {
        require(msg.value >= updateFee, "Insufficient funds");

        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(_lockerInfo.status == Status.LOCKED, "Locker is expired, can't be updated");

        lockerInfo.unlockTime += additionTimeInSeconds;

        emit LockerUpdated (
            _lockerInfo.id, 
            _lockerInfo.numOfTokensLocked, 
            _lockerInfo.unlockTime + additionTimeInSeconds, 
            0
        );

        sendFundsToMaster(msg.value);

    }

    /// @notice this is the function to increase number of tokens
    /// @param additionTokens should be already approved 
    function addMoreTokensToLocker(uint additionTokens) public payable {
        require(msg.value >= updateFee, "Insufficient funds");

        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(_lockerInfo.status == Status.LOCKED, "Locker is expired, can't be updated");

        lockerInfo.numOfTokensLocked += additionTokens;

        _lockerInfo.token.transferFrom(msg.sender, address(this), additionTokens);

        emit LockerUpdated (
            _lockerInfo.id, 
            _lockerInfo.numOfTokensLocked + additionTokens, 
            _lockerInfo.unlockTime, 
            0
        );

        sendFundsToMaster(msg.value);
        
    }

    /// @notice this is the function to unlock the locked tokens 
    function unlockTokens() public {
        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(block.timestamp >= lockerInfo.unlockTime, "Not unlocked yet");
        require(_lockerInfo.status == Status.LOCKED, "Already redeemed");

        lockerInfo.status = Status.REDEEMED;

        _lockerInfo.token.transfer(_lockerInfo.owner, _lockerInfo.numOfTokensLocked);
        
        emit LockerUnlocked (_lockerInfo.id, _lockerInfo.numOfTokensLocked, block.timestamp, 1);

    }

    /// @notice A getter functions to read the locker information 
    function getLockerInfo() public view returns (LockerInfo memory) {
        return lockerInfo;
    }

    /// @notice internal functions to trasfer collected fees to the master contract
    function sendFundsToMaster(uint _funds) internal {
        (bool res,) = payable(master).call{value: _funds}("");
        require(res, "cannot send funds to master"); 
    }


}