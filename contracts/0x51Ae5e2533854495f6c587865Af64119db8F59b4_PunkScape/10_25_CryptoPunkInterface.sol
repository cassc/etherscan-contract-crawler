// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CryptoPunks {
    function balanceOf(address owner) external view returns(uint256);
    function punkIndexToAddress(uint index) external view returns(address);
}