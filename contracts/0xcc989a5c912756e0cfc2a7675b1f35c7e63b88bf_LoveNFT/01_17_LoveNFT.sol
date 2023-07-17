// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';

contract LoveNFT is ERC721, ERC721URIStorage, ERC721Burnable, ERC721Royalty, Ownable {
  uint256 private _currentIndex = 0;

  uint256 private _burnCounter = 0;

  uint96 private constant MAXIMUM_ROYALTY_FEE = 20;

  string private _contractURI;

  event RoyaltyUpdated(uint96 newValue, uint256 tokenId);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _contractUri,
    address _owner,
    uint96 _royaltyFee,
    address _royaltyRecipient
  ) ERC721(_name, _symbol) {
    require(_royaltyFee <= MAXIMUM_ROYALTY_FEE, 'cant more than 20 percent');
    _setDefaultRoyalty(_royaltyRecipient, _royaltyFee);
    transferOwnership(_owner);
    _contractURI = _contractUri;
  }

  function safeMint(address to, string memory uri) public onlyOwner {
    uint256 tokenId = _currentIndex;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    _currentIndex++;
  }

  // @dev - mint multiple tokens at once with an array of URIs
  function bulkMint(address to, string[] calldata URIs) public onlyOwner {
    require(URIs.length > 0, 'URIs length must be greater than 0');
    uint256 tokenId = _currentIndex;

    for (uint256 i = 0; i < URIs.length; i++) {
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, URIs[i]);
      tokenId++;
    }
    _currentIndex = tokenId;
  }

  function updateRoyaltyFee(uint96 _royaltyFee, uint256 _tokenId) external onlyOwner {
    require(_royaltyFee <= MAXIMUM_ROYALTY_FEE, 'invalid royalty fee');
    (address currentReceiver, uint256 currentFeeFraction) = royaltyInfo(_tokenId, uint256(_feeDenominator()));
    require(uint256(_royaltyFee) <= currentFeeFraction, 'new fee too high');
    _setTokenRoyalty(_tokenId, currentReceiver, _royaltyFee);

    emit RoyaltyUpdated(_royaltyFee, _tokenId);
  }

  function getRoyaltyFee(uint256 _tokenId) public view returns (uint256) {
    (, uint256 feeFraction) = royaltyInfo(_tokenId, uint256(_feeDenominator()));
    return feeFraction;
  }

  function totalSupply() public view returns (uint256) {
    return _currentIndex - _burnCounter;
  }

  function _feeDenominator() internal pure override(ERC2981) returns (uint96) {
    return 100;
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
    _burnCounter++;
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function tokenURIOpenSea(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(baseTokenURIOpenSea(), tokenURI(tokenId)));
  }

  function baseTokenURIOpenSea() public pure returns (string memory) {
    return 'https://opensea-creatures-api.herokuapp.com/api/creature/';
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}