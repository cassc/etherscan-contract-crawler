// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AllowList} from "./abstract/AllowList.sol";
import {ICreatorAuth} from "./interfaces/ICreatorAuth.sol";

/// @title CreatorAuth - Creator allowlist
/// @notice An allowlist of approved creator addresses.
contract CreatorAuth is ICreatorAuth, AllowList {
    string public constant NAME = "CreatorAuth";
    string public constant VERSION = "0.0.1";

    constructor(address _controller) AllowList(_controller) {}
}