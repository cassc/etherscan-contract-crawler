// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUPG {
    function Payment(
        address wallet,
        address source,
        uint256 id
    ) external payable;
}