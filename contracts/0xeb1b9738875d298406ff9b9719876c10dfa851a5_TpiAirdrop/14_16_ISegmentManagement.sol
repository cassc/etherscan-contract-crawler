// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title  Partial interface for Segment management contract for Tonpound gNFT token
interface ISegmentManagement is IAccessControl {
    /// @notice View method to read Tonpound TPI token
    /// @return Address of TPI token contract
    function TPI() external view returns (address);
}