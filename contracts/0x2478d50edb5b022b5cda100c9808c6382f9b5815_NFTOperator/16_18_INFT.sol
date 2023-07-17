// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { INFTRegistry } from "./INFTRegistry.sol";

interface INFT is IERC721 {
    function setRegistry(INFTRegistry registry) external;

    function setRegistryDisabled(bool registryDisabled) external;

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;

    function mint(uint256 tokenId, address receiver, string calldata tokenURI) external;

    function burn(uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
}