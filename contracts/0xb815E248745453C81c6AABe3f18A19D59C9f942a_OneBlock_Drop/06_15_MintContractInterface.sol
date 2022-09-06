// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MintContractInterface {
    function mintFromBurn(uint256 _amount, address _caller) external;
}