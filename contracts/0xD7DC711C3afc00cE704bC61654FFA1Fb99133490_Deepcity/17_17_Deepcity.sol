//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract Deepcity is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  mapping(string => uint8) existingURIs;

  constructor() ERC721('Deepcity', 'DPC') {}

  /// @dev event that emits when the token is minted
  event Minted(uint256 tokenId, address tokenOwner, string tokenURI);

  /// @return baseURI
  function _baseURI() internal view virtual override returns (string memory) {
    return 'https://ipfs.io/ipfs/';
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  /// @dev Use to burn the token id or nft, which send it to a non-recoverable address
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
    super._burn(tokenId);
  }

  /**
  @dev Creates tokens of token type `id`, and assigns them to `to`(public address)
  @return id the nft or token id minted
   */
  function mintItem(
    address _to,
    string memory _tokenURI,
    uint96 _royaltyNumerator
  ) public returns (uint256) {
    require(existingURIs[_tokenURI] != 1, 'NFT already minted!');
    require(_royaltyNumerator <= 1000, 'Royalty numerator must be less than or equal to 10%');
    _tokenIds.increment();
    uint256 id = _tokenIds.current();
    existingURIs[_tokenURI] = 1;
    _mint(_to, id);
    _setTokenURI(id, _tokenURI);
    _setTokenRoyalty(id, _to, _royaltyNumerator);
    emit Minted(id, _to, _tokenURI);
    return id;
  }

  /// @return boolean if the uri exist or not
  function isContentOwned(string memory uri) public view returns (bool) {
    return existingURIs[uri] == 1;
  }

  function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  /// @return tokenURI of the individual token or nft
  function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(_tokenId);
  }
}