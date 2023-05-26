// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract HelixLP is ERC20 {
    constructor () ERC20(/*name=*/"Helix LPs", /*symbol=*/"HELIX-LP", /*decimals=*/18) {}
}