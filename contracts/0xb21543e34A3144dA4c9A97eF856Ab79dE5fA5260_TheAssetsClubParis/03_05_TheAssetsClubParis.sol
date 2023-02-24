// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TheAssetsClub at NFT Paris
 * @author Mathieu "Windyy" Bour
 * @notice This collection is only mintable at the NFT Paris event on February 24-25.
 * Our partner artist Mandril will draw the collection live in our booth.
 * Up to 150 tokens will be available for sale. If you buy a token from our OpenSea, you will be able to claim the real
 * art. See us at NFT Paris!
 */
contract TheAssetsClubParis is ERC721A, Ownable {
  /**
   * @notice The prefix of all the TheAssetsClubParis metadata.
   */
  string public baseURI;

  /**
   * @notice URI of the contract-level metadata.
   * Specified by OpenSea documentation (https://docs.opensea.io/docs/contract-level-metadata).
   */
  string public contractURI;

  constructor(string memory _baseURI, string memory _contractURI) ERC721A("TheAssetsClub at NFTParis", "TACP") {
    baseURI = _baseURI;
    contractURI = _contractURI;
    _transferOwnership(msg.sender);
  }

  /**
   * @notice Set the URI of the contract-level metadata.
   * @dev We keep this function as an escape hatch in case of a migration to another token metadata platform.
   * Requirements:
   * - Only owner can set the contract URI.
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    contractURI = newContractURI;
  }

  /**
   * @notice Change the base URI of the tokens URI.
   * @dev We keep this function as an escape hatch in case of a migration to another token metadata platform.
   * Requirements:
   * - Only owner can set base URI.
   */
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /**
   * @notice Metadata URI of the token {tokenId}.
   * @dev See {IERC721Metadata-tokenURI}.
   * Requirements:
   * - {tokenId} should exist (minted and not burned).
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  /**
   * @notice Mint multiple tokens.
   * @dev Requirements:
   * - Only owner can mint tokens.
   */
  function mint(uint256 quantity) external onlyOwner {
    _mint(msg.sender, quantity);
  }

  /**
   * @notice Burn multiple tokens.
   * @dev Requirements:
   * - Only owner can burn tokens.
   */
  function burn(uint256[] memory tokenIds) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(ownerOf(tokenIds[i]) == msg.sender, "TheAssetsClubParis: caller is not the token owner");
      _burn(tokenIds[i]);
    }
  }
}