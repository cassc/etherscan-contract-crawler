//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICozies {
    function mintForAddress(uint256 _mintAmount, address _receiver) external;

    function transferOwnership(address _owner) external;
}