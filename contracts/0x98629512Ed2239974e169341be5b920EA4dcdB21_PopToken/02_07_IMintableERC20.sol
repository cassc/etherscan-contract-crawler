// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IMintableERC20 is IERC20 {
    function mint(uint amount) public virtual;
    function mintTo(address account, uint amount) public virtual;
    function burn(uint amount) public virtual;
    function setMinter(address account, bool isMinter) public virtual;
}