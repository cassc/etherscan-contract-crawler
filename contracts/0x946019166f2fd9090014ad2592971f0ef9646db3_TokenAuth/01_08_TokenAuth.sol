// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AllowList} from "./abstract/AllowList.sol";
import {ITokenAuth} from "./interfaces/ITokenAuth.sol";

/// @title TokenAuth - Token allowlist
/// @notice An allowlist of approved ERC20 tokens.
contract TokenAuth is ITokenAuth, AllowList {
    string public constant NAME = "TokenAuth";
    string public constant VERSION = "0.0.1";

    constructor(address _controller) AllowList(_controller) {}
}