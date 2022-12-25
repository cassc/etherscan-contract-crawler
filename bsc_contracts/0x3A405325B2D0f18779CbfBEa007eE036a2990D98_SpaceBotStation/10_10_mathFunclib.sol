// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

library mathFuncs {
    uint constant DECIMALS = 10**18; 

    function decMul18(uint x, uint y) internal pure returns (uint decProd) {
        decProd = x * y / DECIMALS;
    }

    function decDiv18(uint x, uint y) internal pure returns (uint decQuotient) {
        require(y != 0, "Division by zero");
        decQuotient = x * DECIMALS / y;
    }
}