// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CurrencyConverterInterface{

    function centToWEI(uint256 centValue) external view returns (uint256);
     
}