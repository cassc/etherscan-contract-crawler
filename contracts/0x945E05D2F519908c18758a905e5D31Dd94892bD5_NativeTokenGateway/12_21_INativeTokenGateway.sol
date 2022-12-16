// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IPool.sol";

interface INativeTokenGateway {
    function deposit(IPool pool_) external payable;

    function withdraw(IPool pool_, uint256 amount_) external;
}