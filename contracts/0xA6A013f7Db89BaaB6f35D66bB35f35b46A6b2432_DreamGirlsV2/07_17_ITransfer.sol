// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


abstract contract ITransfer {
    function transfer(address to, uint256 amount) public virtual returns (bool);
}