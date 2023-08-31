// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";

contract Registry {
    mapping(address => bool) public tokens;

    event TokenRegistered(address token);

    error TokenAlreadyRegistered();
    error TokenNotRegistered();

    function register(address newToken) external {
        if (tokens[newToken]) {
            revert TokenAlreadyRegistered();
        }

        tokens[newToken] = true;
        emit TokenRegistered(newToken);
    }

    function isRegistered(address token) public view returns (bool) {
        if (!tokens[token]) {
            revert TokenNotRegistered();
        }

        return tokens[token];
    }
}