// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IChadInuVIPClub is IERC721 {
    function MintVIPCard(string memory usercode, string memory metadataURI)
        external
        payable
        returns (uint256);

    function MintVIPCardWithReferreral(
        string memory usercode,
        string memory referrerCode,
        string memory metadataURI
    ) external payable returns (uint256);

    function isCodeAvailable(string memory code) external view returns (bool);

    function addWhitelist(address account, bool value) external;

    function checkWhitelisted(address account) external view returns (bool);

    function getSubReferralLength(address account)
        external
        view
        returns (uint256);

    function getSubReferral(
        address account,
        uint16 startIndex,
        uint16 endIndex
    ) external view returns (string memory);

    function getIdOfUser(address account) external view returns (uint256);

    function getUsercode(address account) external view returns (string memory);

    function getMintPrice() external view returns (uint256);

    function getMintPriceWithRef() external view returns (uint256);

    function getSecondaryDevAddress() external view returns (address);

    function getReferreralDeadline() external view returns (uint256);
}