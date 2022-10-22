// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";

interface IWToken is IToken {
    function deposit() external payable;

    function withdraw(uint wad) external;
}