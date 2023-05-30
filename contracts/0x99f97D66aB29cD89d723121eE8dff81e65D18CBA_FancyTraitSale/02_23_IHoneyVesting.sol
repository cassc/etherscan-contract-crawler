// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract IHoneyVesting {
    function spendHoney(
        uint256[] calldata _fancyBearTokens, 
        uint256[] calldata _amountPerFancyBearToken, 
        uint256[] calldata _honeyJarTokens,
        uint256[] calldata _amountPerHoneyJarToken
    )
        external
        virtual;
}