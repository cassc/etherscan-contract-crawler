//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDelegationUtils.sol";

interface ITransferUtils is IDelegationUtils{
    event Deposited(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
        );

    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 userUnstaked
        );

    event CalculatingUserLocked(
        address indexed user,
        uint256 nextIndEpoch,
        uint256 oldestLockedEpoch
        );

    event CalculatedUserLocked(
        address indexed user,
        uint256 amount
        );

    function depositRegular(uint256 amount)
        external;

    function withdrawRegular(uint256 amount)
        external;

    function precalculateUserLocked(
        address userAddress,
        uint256 noEpochsPerIteration
        )
        external
        returns (bool finished);

    function withdrawPrecalculated(uint256 amount)
        external;
}