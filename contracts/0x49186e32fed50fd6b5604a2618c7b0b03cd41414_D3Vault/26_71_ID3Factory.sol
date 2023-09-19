/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Factory {
    function breedD3Pool(address poolCreator, address maker, uint256 poolType) external returns (address newPool);
}