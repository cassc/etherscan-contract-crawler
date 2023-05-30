// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract VaultCoreInterface {
    function VERSION() public pure virtual returns (uint8);

    function typeOfContract() public pure virtual returns (bytes32);

    function approveToken(uint256 _tokenId, address _tokenContractAddress)
        external
        virtual;
}