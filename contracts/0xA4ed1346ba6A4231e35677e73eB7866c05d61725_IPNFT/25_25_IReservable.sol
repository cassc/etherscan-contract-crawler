// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IReservable {
    function reserve() external returns (uint256);
    function mintReservation(address to, uint256 reservationId, uint256 mintPassId, string memory tokenURI) external returns (uint256 tokenId);
}