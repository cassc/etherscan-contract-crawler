// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin-contracts-v4.8/token/ERC20/ERC20.sol";

contract Mmo is ERC20 {

    address private constant _MMO_TREASURY = 0x61D5B9CE3Faee42e234530750f56c85eC8DfF47A;

    constructor() ERC20("MMO Token", "MMO") {
        _mint(_MMO_TREASURY, 10000000e18);
    }
}