// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

////HORATIO.sol

contract HORATIO is ERC20, Ownable{
    constructor(address _to) ERC20("HORATIO", "$RATIO") {
        _mint(_to, 420000000000 * 10 ** decimals());
    }

}