// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity 0.8.17;

interface IBurnedKevins {
    function mint(uint[] calldata tokenIds, address recipient) external;
}