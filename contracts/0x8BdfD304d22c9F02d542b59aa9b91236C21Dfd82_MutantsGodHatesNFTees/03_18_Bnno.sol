// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Bnno {
    function burnBanana(address burnTokenAddress) external virtual;

    function balanceOf(address account, uint256 id) public view virtual
        returns (uint256);
}