// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface CryptoPunksInterface {
    function punkIndexToAddress(uint256 punkIndex)
        external
        view
        returns (address);

    function getPunk(uint256 punkIndex) external;
}