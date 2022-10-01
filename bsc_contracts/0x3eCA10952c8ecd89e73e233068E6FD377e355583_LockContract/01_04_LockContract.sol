// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockContract is Ownable {
    struct UserDetail {
        bool isActive;
        uint256 amount;
        bytes32 csprAddr;
        bool isSecpKey;
        bytes1 prefix;
    }

    mapping(address => UserDetail) public users;
    mapping(uint256 => address) public usersByIndex;
    uint256 public totalUser;
    uint256 public totalLocked;

    uint256 public endTime;
    address public swprToken;

    constructor(uint256 _endTime, address _swprToken) {
        swprToken = _swprToken;
        endTime = _endTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function getEndTime()
        external
        view
        returns (uint256 endTime_, uint256 currentTime_)
    {
        endTime_ = endTime;
        currentTime_ = block.timestamp;
    }

    function setCsprAddr(
        bytes32 _csprAddr,
        bool _isSecpKey,
        bytes1 _prefix
    ) external {
        if (users[msg.sender].isActive != true) {
            usersByIndex[totalUser++] = msg.sender;
            users[msg.sender] = UserDetail(
                true,
                0,
                _csprAddr,
                _isSecpKey,
                _prefix
            );
            return;
        }
        users[msg.sender].csprAddr = _csprAddr;
        users[msg.sender].isSecpKey = _isSecpKey;
        users[msg.sender].prefix = _prefix;
    }

    function lockSwprToken(uint256 _amount) external {
        require(_amount >= 0, "Lock: Invalid amount");
        require(
            IERC20(swprToken).balanceOf(msg.sender) >= _amount,
            "Lock: Not enough balance"
        );
        require(
            IERC20(swprToken).allowance(msg.sender, address(this)) >= _amount,
            "Lock: Not enough approval"
        );
        require(users[msg.sender].isActive, "Lock: Not active");

        IERC20(swprToken).transferFrom(msg.sender, address(this), _amount);

        totalLocked += _amount;
        users[msg.sender].amount += _amount;
    }

    struct User {
        address user;
        uint256 amount;
        bytes32 csprAddr;
        bool isSecpKey;
        bytes1 prefix;
    }

    function getAllUsers() external view returns (User[] memory) {
        User[] memory allUsers = new User[](totalUser);
        for (uint256 i = 0; i < totalUser; i++) {
            address user = usersByIndex[i];
            allUsers[i] = User(
                user,
                users[user].amount,
                users[user].csprAddr,
                users[user].isSecpKey,
                users[user].prefix
            );
        }
        return allUsers;
    }
}