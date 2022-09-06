// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./Administered.sol";

abstract contract AdministeredSVG is Administered {
    bytes32 public constant MODERATOR = keccak256("MODERATOR");
}