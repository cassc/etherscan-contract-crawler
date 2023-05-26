// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseTicket {
    function burn(
        uint256 tokenId,
        address _account,
        uint256 _numberofTickets
    ) external;

    function mintFreeTicket(uint256 _mintAmount) external;

    function mintPremiumTicket(uint256 _mintAmount) external payable;
}