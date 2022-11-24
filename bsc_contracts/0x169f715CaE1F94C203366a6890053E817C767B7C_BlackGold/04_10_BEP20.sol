// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBEP20Additions.sol";

abstract contract BEP20 is Ownable, ERC20, IBEP20Additions {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function getOwner() external view override returns (address) {
        return owner();
    }
}