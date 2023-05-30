// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";


////PONZICOIN.sol

contract PONZICOIN is ERC20{
    constructor(address _to) ERC20("PONZICOIN", "PONZI") {
        _mint(_to, 420690000000000 * 10 ** decimals());
    }

}