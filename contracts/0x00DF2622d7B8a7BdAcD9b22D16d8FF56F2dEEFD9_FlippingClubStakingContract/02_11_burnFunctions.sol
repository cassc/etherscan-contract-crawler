// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface burnFunctions {
    function burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        external;
}