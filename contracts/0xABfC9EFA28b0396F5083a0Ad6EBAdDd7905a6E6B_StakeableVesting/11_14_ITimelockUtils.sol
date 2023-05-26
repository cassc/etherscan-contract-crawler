//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IClaimUtils.sol";

interface ITimelockUtils is IClaimUtils {
    event DepositedByTimelockManager(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
        );

    event DepositedVesting(
        address indexed user,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 userUnstaked,
        uint256 userVesting
        );

    event VestedTimelock(
        address indexed user,
        uint256 amount,
        uint256 userVesting
        );

    function deposit(
        address source,
        uint256 amount,
        address userAddress
        )
        external;

    function depositWithVesting(
        address source,
        uint256 amount,
        address userAddress,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external;

    function updateTimelockStatus(address userAddress)
        external;
}