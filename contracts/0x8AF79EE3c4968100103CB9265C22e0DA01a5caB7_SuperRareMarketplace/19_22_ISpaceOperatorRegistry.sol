// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title ISpaceOperatorRegistry
/// @notice The interface for the SpaceOperatorRegistry
interface ISpaceOperatorRegistry {
    function getPlatformCommission(address _operator)
        external
        view
        returns (uint8);

    function setPlatformCommission(address _operator, uint8 _commission)
        external;

    function isApprovedSpaceOperator(address _operator)
        external
        view
        returns (bool);

    function setSpaceOperatorApproved(address _operator, bool _approved)
        external;
}