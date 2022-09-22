// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurrencyConverterInterface.sol";

contract DummyCurrencyConverter is CurrencyConverterInterface{

    function centToWEI(uint256 centValue) external pure returns (uint256)
    {
        centValue = 0;
        return 10;
    }
     
}