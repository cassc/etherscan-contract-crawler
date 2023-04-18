// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title Paloceras NFT
 * @author Paloceras
 */
contract Paloceras is Ownable, ERC721A, ERC2981 {
  /// Base URI for NFT metadata
  string private baseURI_;

  /// Maximum supply of tokens that can be minted
  uint256 public maxSupply = 373;

  /**
   * @param name_ NFT collection name
   * @param symbol_ NFT collection symbol
   * @param baseURI__ NFT metadata base URI
   * @param _royaltiesAddress Royalties receiver address
   * @param _feeNumerator The denominator with which to interpret the fee
   */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI__,
    address _royaltiesAddress,
    uint96 _feeNumerator
  ) ERC721A(name_, symbol_) {
    _setDefaultRoyalty(_royaltiesAddress, _feeNumerator);
    baseURI_ = baseURI__;
  }

  /**
   * @notice Mint NFT
   *
   * @param to Address mint to
   * @param quantity How many NFTs to mint
   */
  function safeMint(address to, uint256 quantity) public onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
    _safeMint(to, quantity);
  }

  /**
   * @notice Get the base URI for NFT metadata
   *
   * @return NFT metadata base URI
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI_;
  }

  /**
   * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   *
   * @param tokenId Token identifier
   */
  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    string memory _tokenURI = super.tokenURI(tokenId);

    return string(abi.encodePacked(_tokenURI, ".json"));
  }

  /**
   * @notice Returns whether the NFT exists
   *
   * @param tokenId Token identifier
   */
  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /**
   * @notice Destroys the NFT
   *
   * @param tokenId Token identifier
   */
  function burn(uint256 tokenId) public {
    _burn(tokenId);
  }

  /**
   * @notice Returns if the NFT contract supports a specific interaction interface
   *
   * @param interfaceId Interface identifier
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC2981, ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}