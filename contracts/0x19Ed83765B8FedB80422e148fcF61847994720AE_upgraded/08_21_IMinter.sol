// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


abstract contract IMinter {
    function mint(address _to) public virtual;
}