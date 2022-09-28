// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRoyaltyOracle {
    function royalties(
        IERC721 _tokenContract,
        uint256 _tokenId,
        uint32 _micros,
        uint64 _data
    ) external view returns (RoyaltyResult[] memory);
}

struct RoyaltyResult {
    address recipient;
    uint32 micros;
}