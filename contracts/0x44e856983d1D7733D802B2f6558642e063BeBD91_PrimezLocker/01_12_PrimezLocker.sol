// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Utils.sol";

struct LockItem {
    address user;
    uint256 start;
    uint256 end;
    uint256 amount;
}

contract PrimezLocker is Ownable, Lockable , ILocker{

    using SafeERC20 for ERC20;

    mapping(address => LockItem) private lockedItems;
    mapping(address => bool) private whitelist;
    address private ERC20Address;

    // systemLock = false: unlock for all system
    bool private systemLock = true;

    event Lock(address addr, uint256 start, uint256 end, uint256 amount);
    event TransferAndLock(address addr, uint256 start, uint256 end, uint256 amount);

    constructor(){}

    function setTokenAddress(address _ERC20) external onlyOwner {
        ERC20Address = _ERC20;
    }
    /**
    * Check condition for locking
    * If lockInfo != exist or lockInfo is expired => true
    **/
    function checkLocked(address _user) internal view returns (bool){
      return !whitelist[_user] ? true : (block.timestamp >= lockedItems[_user].end);
   }

    /**
    * duration: (uint256): seconds
    **/
    function lock(address _user, uint256 duration, uint256 amountLock) external onlyLocker {
        // Each address can lock only one time
        require(checkLocked(_user), "This address has been locked");

        whitelist[_user] = true;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        LockItem memory lockItem = LockItem({
            user: _user,
            start: startTime,
            end: endTime,
            amount: amountLock
        });

        lockedItems[_user] = lockItem;
        emit Lock(_user, startTime, endTime, amountLock);
    }

    /**
    * duration: (uint256): seconds
    **/
    function transferAndLock(address _user, uint256 duration, uint256 amountLock) external onlyLocker {
        // Each address can lock only one time
        require(checkLocked(_user), "This address has been locked");

        whitelist[_user] = true;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        LockItem memory lockItem = LockItem({
            user: _user,
            start: startTime,
            end: endTime,
            amount: amountLock
        });

        lockedItems[_user] = lockItem;
        ERC20(ERC20Address).safeTransferFrom(owner, _user, amountLock);
        emit TransferAndLock(_user, startTime, endTime, amountLock);
    }

    function isLocked(address _user, uint256 newBalance) external view override returns (bool){
        require((msg.sender == ERC20Address)||(msg.sender == owner), "You are not allowed");
        
        // Unlock for all system
        if(!systemLock)
            return false;

        if (!whitelist[_user])
            return false;

        uint256 lockAmount = getLockedAmount(_user);

        if(lockAmount == 0)
            return false;

        return newBalance < lockAmount;
    }

    function getLockedAmount(address _user) public view returns (uint256){
        // Unlock for all system
        if(!systemLock)
            return 0;

        if (checkLocked(_user))
            return 0;

        return lockedItems[_user].amount;
    }

    function getLockedInfo(address _user) external view returns (LockItem memory){
        return lockedItems[_user];
    }

    function setSystemLock(bool _systemLock) public onlyLocker {
        systemLock = _systemLock;
    }

    function getSystemLock() public view returns (bool){
        return systemLock;
    }
}