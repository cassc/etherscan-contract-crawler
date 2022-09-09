// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract CleDePeau is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;

  string public collectionTokenURI;
  address _operator;
  uint256 TOTAL_SUPPORT = 1001;

  event CollectionTokenURIUpdated(string oldURI, string newURI);
  event Mint(address indexed to, uint256 indexed tokenId);

  error TotalSupplyExceeded();
  error TransferDisabled();

  modifier onlyOperatorOrOwner() {
    require(
      _operator == msg.sender || msg.sender == owner(),
      'Only the operator or the owner can perform this action'
    );
    _;
  }

  modifier mintOnce(address account) {
    require(balanceOf(account) < 1, 'Minted once');
    _;
  }

  constructor(string memory _collectionTokenURI, address operator)
    ERC721('Cle de Peau Beaute  x VOGUE Hong Kong x KRISTA KIM', 'CPB40')
  {
    collectionTokenURI = _collectionTokenURI;
    _operator = operator;
  }

  function approve(address, uint256) public virtual override {
    revert TransferDisabled();
  }

  function transferFrom(
    address,
    address,
    uint256 /* address to, uint256 amount */
  ) public virtual override {
    revert TransferDisabled();
  }

  function mint(address account) external onlyOperatorOrOwner whenNotPaused mintOnce(account) {
    if (totalSupply() + 1 > TOTAL_SUPPORT) revert TotalSupplyExceeded();

    uint256 tokenId = totalSupply() + 1;

    _safeMint(account, tokenId);
  }

  function setCollectionTokenURI(string memory _collectionTokenURI)
    external
    onlyOwner
    whenNotPaused
  {
    emit CollectionTokenURIUpdated(collectionTokenURI, _collectionTokenURI);
    collectionTokenURI = _collectionTokenURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return collectionTokenURI;
  }

  function setOperator(address operator) external onlyOwner whenNotPaused {
    _operator = operator;
  }

  /**
   * @dev tokenURI overides the Openzeppelin's ERC721 implementation for tokenURI function
   * This function returns the URI from where we can extract the metadata for a given tokenId
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    return collectionTokenURI;
  }
}