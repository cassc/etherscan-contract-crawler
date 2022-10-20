// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract VestingModule is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => uint256) public totalAllocation;
    mapping(address => uint256) public lastClaimedTimestamp;

    uint256 public start;
    uint256 public duration;

    IERC20Upgradeable public token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize(
        IERC20Upgradeable _token,
        uint256 _start,
        uint256 _duration
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        token = _token;
        start = _start;
        duration = _duration;
    }

    function release() external {
        uint256 releasable_ = releasable(msg.sender);

        require(releasable_ != 0, "VestingModule: Not eligible for release");
        require(
            block.timestamp > start,
            "VestingModule: The vesting has not started"
        );

        lastClaimedTimestamp[msg.sender] = block.timestamp;

        token.safeTransfer(msg.sender, releasable_);
    }

    function releasable(address claimer) public view returns (uint256) {
        //Before the vesting begins
        if (block.timestamp <= start) {
            return 0;
        }

        uint256 lastClaimedTimestamp_ = lastClaimedTimestamp[claimer];
        uint256 totalAllocation_ = totalAllocation[claimer];

        if (lastClaimedTimestamp_ == 0) {
            lastClaimedTimestamp_ = start;
        }

        // After the end of vesting
        if (block.timestamp >= start + duration) {
            return
                ((start + duration - lastClaimedTimestamp_) *
                    totalAllocation_) / duration;
        }

        // During the vesting period
        return
            ((block.timestamp - lastClaimedTimestamp_) * totalAllocation_) /
            duration;
    }

    function addAllocations(
        address[] memory addresses,
        uint256[] memory allocations
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            totalAllocation[addresses[i]] = allocations[i];
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}