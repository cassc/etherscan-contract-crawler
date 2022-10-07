// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Vesting is Initializable {
    // Half year
    uint256 public constant MINIMUM_LOCK_TIME = 15768000;

    address public recipient;

    IERC20 public token;

    uint256 public lockedAmount;
    uint256 public claimedAmount;

    uint256 public unlockStartTime;
    uint256 public cliffTime;
    uint256 public lockEndTime;

    event VestingInitialized(address indexed _recipient, uint256 _lockPeriod, uint256 _amount);

    event VestingClaimed(address _beneficiary, uint256 _amount);

    address initializeAdmin;
    bool isInitialized;

    function setInitializeAdmin(address _initializeAdmin) public {
        require(initializeAdmin == address(0));
        initializeAdmin = _initializeAdmin;
    }

    function initialize(
        address _tokenAddress,
        address _recipient,
        uint256 _lockPeriod,
        uint256 _cliffTime,
        uint256 _amount
    ) external initializer {
        require(initializeAdmin == address(0) || msg.sender == initializeAdmin, "!initializeAdmin");
        require(_tokenAddress != address(0), "Token address cannot be zero address");
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_lockPeriod >= MINIMUM_LOCK_TIME, "Lock period should be greater than MINIMUM_LOCK_TIME");
        require(_amount > 0, "Amount must be greater than zero");

        uint256 currentTime = block.timestamp;

        token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) == _amount, "Wrong token balance");

        recipient = _recipient;

        cliffTime = _cliffTime;
        unlockStartTime = currentTime + _cliffTime;
        lockEndTime = currentTime + _cliffTime + _lockPeriod;

        lockedAmount = _amount;
        emit VestingInitialized(_recipient, _lockPeriod, _amount);
        isInitialized = true;
    }

    function unlockedAmount() public view returns (uint256) {
        require(isInitialized, "!isInitialized");
        uint256 currentTime = block.timestamp;

        if (currentTime <= unlockStartTime) {
            return 0;
        }

        return
            Math.min((lockedAmount * (currentTime - unlockStartTime)) / (lockEndTime - unlockStartTime), lockedAmount);
    }

    function unclaimed() public view returns (uint256) {
        require(isInitialized, "!isInitialized");
        uint256 _unlockedAmount = unlockedAmount();
        uint256 _claimedAmount = claimedAmount;

        if (_claimedAmount == _unlockedAmount) {
            return 0;
        }

        return _unlockedAmount - _claimedAmount;
    }

    function claim(address _beneficiary, uint256 _amount) public {
        require(isInitialized, "!isInitialized");
        require(msg.sender == recipient, "Only the recipient can claim");
        require(_amount > 0, "Amount must be greater than zero");
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");

        uint256 _unclaimed = unclaimed();

        require(_amount <= _unclaimed, "Amount must be less than or equal to unclaimed amount");
        claimedAmount += _amount;

        token.transfer(_beneficiary, _amount);

        emit VestingClaimed(_beneficiary, _amount);
    }
}