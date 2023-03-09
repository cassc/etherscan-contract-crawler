// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Bitfax is ERC20,Ownable {
    constructor(address _to) ERC20("Bitfax", "BTF") {
        _mint(_to, 100000000 * 10 ** decimals());
    }
}