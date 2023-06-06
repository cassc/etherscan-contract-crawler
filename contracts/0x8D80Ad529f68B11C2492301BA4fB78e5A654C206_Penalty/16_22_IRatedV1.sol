// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

interface IRatedV1 {
    function getViolationsForValidator(bytes32 _pubKeyRoot) external returns (uint256[] memory violatedEpoch);

    function isValidatorInDispute(bytes32 _pubKeyRoot) external returns (bool _isInUnfinishedDispute);
}