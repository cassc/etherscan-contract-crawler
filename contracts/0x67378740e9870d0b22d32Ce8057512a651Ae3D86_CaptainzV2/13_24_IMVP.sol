// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMVP {
    function isCaptainzBoosting(uint256 tokenId) external view returns (bool);
    function removeCaptainz(uint256 captainzTokenId) external;
}