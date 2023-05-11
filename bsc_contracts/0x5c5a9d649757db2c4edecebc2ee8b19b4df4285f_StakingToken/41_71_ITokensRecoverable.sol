// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./IERC20.sol";

interface ITokensRecoverable {
    function recoverTokens(IERC20 token) external;
}