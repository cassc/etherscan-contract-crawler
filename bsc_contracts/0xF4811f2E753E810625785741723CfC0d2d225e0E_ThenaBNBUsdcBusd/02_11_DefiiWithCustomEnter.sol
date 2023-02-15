// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";

abstract contract DefiiWithCustomEnter is Defii {
    function enterWithParams(bytes memory params) external onlyOwner {
        _enterWithParams(params);
    }

    function _enterWithParams(bytes memory params) internal virtual;

    function _enter() internal virtual override {
        revert("Run enterWithParams");
    }
}