// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IBandSaurus is IERC721 {
    event BandSaurusCreated(uint256 indexed tokenId);

    event BandSaurusBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function setMaxSupply(uint256 maxSupply) external;
}