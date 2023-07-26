// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


interface IAirDropable {

    error TooManyAddresses();

    function airdrop(uint256 editionId, address[] calldata recipients, uint24 quantityPerAddres) external;
}