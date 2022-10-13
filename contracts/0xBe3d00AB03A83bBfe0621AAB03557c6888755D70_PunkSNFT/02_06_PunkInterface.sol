// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface PunkInterface {
    function punkIndexToAddress(uint256 _punkId)
        external
        view
        returns (address);

    function balanceOf(address _owner) external view returns (uint256);
}