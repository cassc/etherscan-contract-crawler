// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract IGoldz {
    function burn(uint256 amount) public virtual;
    function balanceOf(address account) public view virtual returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);
}