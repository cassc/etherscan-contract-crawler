//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IArbOnePrecompile {

    function getPricesInWei()  external view returns (uint, uint, uint, uint, uint, uint);
}