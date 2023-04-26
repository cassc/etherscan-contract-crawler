// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokensLocker is Ownable, ReentrancyGuard {
    uint256 public platformFee;
    uint256 public uniqueLokers;

    struct LockData {
        uint256 amount;
        address token;
        uint256 startTime;
        uint256 endTime;
        bool isWithdrawn;
    }

    struct UserData {
        bool isExists;
        uint256 lockCount;
        mapping(uint256 => LockData) lockRecord;
    }

    event LOCK(address locker, uint256 amount, address token);
    event WITHDRAW(address locker, uint256 amount, address token);

    mapping(address => UserData) internal users;

    constructor(uint256 _platformFee) {
        platformFee = _platformFee;
    }

    function lock(
        uint256 _amount,
        uint256 _endTime,
        address _token
    ) public payable {
        require(msg.value == platformFee, "Pay the platform fee");
        require(_endTime > block.timestamp, "End Time should be in future");
        if (!users[msg.sender].isExists) {
            users[msg.sender].isExists = true;
            uniqueLokers++;
        }
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        UserData storage user = users[msg.sender];
        LockData storage userLock = user.lockRecord[user.lockCount];
        userLock.amount = _amount;
        userLock.token = _token;
        userLock.startTime = block.timestamp;
        userLock.endTime = _endTime;
        user.lockCount++;

        emit LOCK(_msgSender(), _amount, _token);
    }

    function unlock(uint256 _index) public nonReentrant {
        UserData storage user = users[msg.sender];
        LockData storage userLock = user.lockRecord[_index];
        require(
            block.timestamp >= userLock.endTime,
            "Wait for Lock duration to End"
        );
        require(!userLock.isWithdrawn, "Already Withdrawn");
        require(_index < user.lockCount, "Lock Does not Exist");
        address _token = userLock.token;
        uint256 _amount = userLock.amount;
        userLock.isWithdrawn = true;

        IERC20(_token).transfer(msg.sender, _amount);
        emit WITHDRAW(_msgSender(), _amount, _token);
    }

    function changePlatformFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }

    function withdrawEth(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
    } 
    function getUserInfo(
        address _user
    ) public view returns (bool _isExists, uint256 _lockCount) {
        UserData storage user = users[_user];
        _isExists = user.isExists;
        _lockCount = user.lockCount;
    }

    function getUserLockInfo(
        address _user,
        uint256 _index
    )
        public
        view
        returns (
            uint256 _amount,
            uint256 _startTime,
            address _token,
            uint256 _endTime,
            bool _isWithdrawn
        )
    {
        LockData storage userLock = users[_user].lockRecord[_index];
        _amount = userLock.amount;
        _startTime = userLock.startTime;
        _endTime = userLock.endTime;
        _isWithdrawn = userLock.isWithdrawn;
        _token = userLock.token;
    }
}