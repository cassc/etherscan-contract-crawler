// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWrappedToken.sol";

interface IETHBridge {
    // events
    event Mint(
        uint256[] nonces,
        IWrappedToken[] tokens,
        address[] recipients,
        uint256[] amounts
    );
    event Burn(
        IWrappedToken token,
        address burner,
        address recipient,
        uint256 amount
    );
}