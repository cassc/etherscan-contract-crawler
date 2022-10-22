// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";

interface IMinimaxBase {
    function create(
        address pool,
        bytes calldata poolArgs,
        IToken token,
        uint amount
    ) external returns (uint);

    function deposit(uint positionIndex, uint amount) external;

    function withdraw(
        uint positionIndex,
        uint amount,
        bool amountAll
    ) external returns (bool closed);
}