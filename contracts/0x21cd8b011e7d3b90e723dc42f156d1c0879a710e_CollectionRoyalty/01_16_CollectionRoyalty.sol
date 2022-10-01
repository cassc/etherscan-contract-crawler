// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract CollectionRoyalty is ERC721Enumerable, ERC721Royalty, Ownable {
  using Strings for uint;

  mapping(uint => string) tokenIdToTokenURI;

  string public baseURI;
  uint public maxSupply; // 0 means no maxSupply

  constructor(string memory _name, string memory _symbol, uint _maxSupply) ERC721(_name, _symbol) {
    maxSupply = _maxSupply;
  }


  /**
   * @notice Set prefix of all tokenURI
   * @param _baseURI prefix of all tokenURI
   * @dev only owner can call this function
   */
  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  /**
   * @notice Mint a new NFT to the specified address
   * @param _to address to mint NFT
   * @param _tokenURI suffix for tokenURI
   */
  function mint(address _to, string memory _tokenURI) public onlyOwner {
    require(bytes(_tokenURI).length > 0, "Collection: tokenURI not valid");
    require(totalSupply() <= maxSupply || maxSupply == 0, "CollectionRoyalty: max supply reached");
    uint tokenID = totalSupply();
    _safeMint(_to, tokenID);
    tokenIdToTokenURI[tokenID] = _tokenURI;
  }

  /**
   * @notice Mint batch a new NFT to the list of specified address
   * @param _to list of address to mint NFT
   * @param _tokenURI list of suffix for tokenURI
   */
  function mintBatch(address _to, string memory _tokenURI, uint _amount) public onlyOwner {
    require(bytes(_tokenURI).length > 0, "Collection: tokenURI not valid");
    require(totalSupply() + _amount <= maxSupply || maxSupply == 0, "CollectionRoyalty: max supply reached");
    for ( uint i = 0; i < _amount; i++) {
      uint tokenID = totalSupply()+1;
      _safeMint(_to, tokenID, "");
      tokenIdToTokenURI[tokenID] = _tokenURI;
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   * @param _tokenID id of the token to retrieve
   * This function concatenates the base uri with the token uri set during mint
  */
  function tokenURI(uint _tokenID) public view virtual override returns (string memory) {
    require(_exists(_tokenID), "Collection: tokenID not exist");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdToTokenURI[_tokenID])) : "";
  }

  /**
   * @notice Returns the royalty denominator
   */
  function royaltyDenominator() external pure returns (uint) {
    return _feeDenominator();
  }

  // PRIVILEGED FUNCTIONS
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  // SOLIDITY OVERRIDES
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721) {
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721Royalty, ERC721) {
    ERC721Royalty._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty, ERC721Enumerable) returns (bool) {
    return ERC721Royalty.supportsInterface(interfaceId);
  }

}