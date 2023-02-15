// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./BaseAgTokenSideChain.sol";

/// @title AgTokenSideChain
/// @author Angle Labs, Inc.
/// @notice Implementation for Angle agTokens to be deployed on chains where there is no need to support
/// bridging and swapping in and out from other bridge tokens
contract AgTokenSideChain is BaseAgTokenSideChain {
    function initialize(
        string memory name_,
        string memory symbol_,
        address _treasury
    ) external {
        _initialize(name_, symbol_, _treasury);
    }
}