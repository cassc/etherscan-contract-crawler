// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OriginNFT is ERC721, ERC721Enumerable, ERC2981, Pausable, Ownable, ERC721Burnable {
  using Counters for Counters.Counter;
  bool private _initialized;
  string private _name;
  string private _symbol;
  string private _baseURIOverride;
  // Optional mapping for token URIs
  mapping(uint256 => string) _tokenURIs;

  Counters.Counter private _tokenIdCounter;

  constructor(
    string memory initName,
    string memory initToken,
    string memory initBaseURI
  ) ERC721(initName, initToken) {
    _initialized = true;
    _name = initName;
    _symbol = initToken;
    _baseURIOverride = initBaseURI;
  }

  function init(
    string memory initName,
    string memory initToken,
    string memory initBaseURI,
    address _owner
  ) public {
    require(!_initialized, "Contract instance has already been initialized");
    _initialized = true;
    _name = initName;
    _symbol = initToken;
    _baseURIOverride = initBaseURI;
    _transferOwnership(_owner);
    unpause();
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseURIOverride = baseURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(tokenId, _tokenURI);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
    require(_exists(tokenId), "OriginNFT: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function safeMint(address to, string memory uri) public onlyOwner {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721) {
    super._burn(tokenId);
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    _requireMinted(tokenId);
    string memory _tokenURI = _tokenURIs[tokenId];

    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }

    return
      bytes(_baseURIOverride).length > 0
        ? string(abi.encodePacked(_baseURIOverride, Strings.toHexString(tokenId, 32)))
        : "";
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /* Royalties */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    super._setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev Removes default royalty information.
   */
  function deleteDefaultRoyalty() public onlyOwner {
    super._deleteDefaultRoyalty();
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    super._setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   */
  function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
    super._resetTokenRoyalty(tokenId);
  }
}