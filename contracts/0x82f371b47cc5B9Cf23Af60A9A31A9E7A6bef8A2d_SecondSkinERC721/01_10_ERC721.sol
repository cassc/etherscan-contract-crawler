// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "https://github.com/nibbstack/erc721/src/contracts/tokens/nf-token-metadata.sol";
import "https://github.com/nibbstack/erc721/src/contracts/ownership/ownable.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract SecondSkinERC721 is
  NFTokenMetadata,
  Ownable
{

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor()
  {
    nftName = "ALTAVA Second Skin : Metamorphosis";
    nftSymbol = "ALTAVA";
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

  function burn(
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_tokenId);
  }

  function setTokenUri(
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._setTokenUri(_tokenId, _uri);
  }

}