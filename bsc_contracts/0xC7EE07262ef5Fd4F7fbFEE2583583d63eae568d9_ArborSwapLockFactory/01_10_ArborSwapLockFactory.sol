// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "contracts/ArborSwapRewardsLockSimple.sol";
import "contracts/ArborSwapRewardsLockVesting.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract ArborSwapLockFactory is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _lockIds;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address payable public feeAddr;
    uint256 public lockFeeSimple;
    uint256 public lockFeeVesting;

    address[] public locks;
    mapping(address => EnumerableSet.UintSet) private _userLockIds;
    EnumerableSet.AddressSet private _lockedTokens;
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds;

    mapping(uint256 => address) lockIdToAddy;
    event LogCreateSimpleLock(address lock, address owner);
    event LogCreateVestingLock(address lock, address owner);
    event LogSetFeeSimple(uint256 fee);
    event LogSetFeeVesting(uint256 fee);
    event LogSetFeeAddress(address fee);

    function createSimpleLock(uint _duration, uint256 amount, address _token) external payable{
        require(msg.value >= lockFeeSimple, "Not enough BNB sent");
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "Insufficient funds.");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");
        ArborSwapRewardsLockSimple lock = new ArborSwapRewardsLockSimple(msg.sender,_duration,amount, _token, address(this));
        uint256 lockId = _lockIds.current();
        address lockAddy = lock.getAddress();
        _lockIds.increment();
        locks.push(lockAddy);
        _userLockIds[msg.sender].add(lockId);
        _lockedTokens.add(_token);
        _tokenToLockIds[_token].add(lockId);
        lockIdToAddy[lockId] = lockAddy;
        IERC20(_token).transferFrom(msg.sender, lockAddy, amount);
        lock.lock();
        feeAddr.transfer(msg.value);
        emit LogCreateSimpleLock(lockAddy, msg.sender);
    }

    function createVestingLock(
        uint _numberOfPortions,
        uint timeBetweenPortions,
        uint distributionStartDate,
        uint _TGEPortionUnlockingTime,
        uint256 _TGEPortionPercent,
        address _token, 
        uint256 amount) external payable {

        require(msg.value >= lockFeeVesting, "Not enough BNB sent");
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "Insufficient funds.");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");

        ArborSwapRewardsLockVesting lock = new ArborSwapRewardsLockVesting(
        _numberOfPortions,
        timeBetweenPortions,
        distributionStartDate,
        _TGEPortionUnlockingTime,
        msg.sender,
        _token,
        address(this));

        uint256 lockId = _lockIds.current();
        address lockAddy = lock.getAddress();
        _lockIds.increment();
        locks.push(lockAddy);
        _userLockIds[msg.sender].add(lockId);
        _lockedTokens.add(_token);
        _tokenToLockIds[_token].add(lockId);
        lockIdToAddy[lockId] = lockAddy;
        IERC20(_token).transferFrom(msg.sender, lockAddy, amount);
        lock.lock(amount, _TGEPortionPercent);
        feeAddr.transfer(msg.value);

        emit LogCreateVestingLock(lockAddy, msg.sender);
    }

    function setFeeSimple(uint256 fee) external onlyOwner{
        require(fee != lockFeeSimple, "Already set to this value"); 
        lockFeeSimple = fee;
        emit LogSetFeeSimple(fee);
    }

    function setFeeVesting(uint256 fee) external onlyOwner{
        require(fee != lockFeeVesting, "Already set to this value"); 
        lockFeeVesting = fee;
        emit LogSetFeeVesting(fee);
    }

    function setFeeAddress(address payable fee) external onlyOwner{
        require(fee != feeAddr, "Already set to this value"); 
        feeAddr = fee;
        emit LogSetFeeAddress(fee);
    }

    function getTotalLockCount() external view returns (uint256) {
        // Returns total lock count, regardless of whether it has been unlocked or not
        return locks.length;
    }

    function getLockAt(uint256 index) external view returns (address) {
        return locks[index];
    }

    function getLockById(uint256 lockId) public view returns (address) {
        return lockIdToAddy[lockId];
    }

    function allTokenLockedCount() public view returns (uint256) {
        return _lockedTokens.length();
    }

    function lockCountForUser(address user)
        public
        view
        returns (uint256)
    {
        return _userLockIds[user].length();
    }

    function locksForUser(address user)
        external
        view
        returns (address[] memory)
    {
        uint256 length = _userLockIds[user].length();
        address[] memory userLocks = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userLockIds[user].at(i));
        }
        return userLocks;
    }

    function lockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (address)
    {
        require(lockCountForUser(user) > index, "Invalid index");
        return getLockById(_userLockIds[user].at(index));
    }

    function totalLockCountForToken(address token)
        external
        view
        returns (uint256)
    {
        return _tokenToLockIds[token].length();
    }
}