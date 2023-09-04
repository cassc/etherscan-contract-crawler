// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IReservable {
    function reserve() external returns (uint256);

    function mintReservation(address to, uint256 reservationId, string calldata _tokenURI, string calldata _symbol, bytes calldata authorization)
        external
        payable
        returns (uint256 tokenId);
}