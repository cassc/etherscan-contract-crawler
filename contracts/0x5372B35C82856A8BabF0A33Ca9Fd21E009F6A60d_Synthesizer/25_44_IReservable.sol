// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IReservable {
    function reserve() external returns (uint256);
    function mintReservation(address to, uint256 reservationId, uint256 mintPassId, string calldata tokenURI, string calldata symbol)
        external
        payable
        returns (uint256 tokenId);
}