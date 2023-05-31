// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// raribles royalty interface
interface IRaribleRoyalties {

    // emitted on mint
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    // addresses that should get the fee
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

    // fee basis points
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);

}