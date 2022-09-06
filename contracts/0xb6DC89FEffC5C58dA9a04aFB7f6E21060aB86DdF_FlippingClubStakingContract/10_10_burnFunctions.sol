// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface burnFunctions {
    function burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        external;
}