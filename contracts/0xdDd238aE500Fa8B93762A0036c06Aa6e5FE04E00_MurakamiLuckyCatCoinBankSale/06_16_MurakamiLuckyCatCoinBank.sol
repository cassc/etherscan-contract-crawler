// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title: Murakami Lucky Cat Coin Bank
/// @author: niftykit.com

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MurakamiLuckyCatCoinBank is ERC721A, ERC2981, AccessControl, Ownable {
  string private _tokenBaseURI;

  address private _cAddress;

  mapping(uint256 => bool) private _processedChunks;

  constructor(address royalty_, uint96 royaltyFee_)
    ERC721A('Murakami Lucky Cat Coin Bank', 'Cat Coin Bank')
  {
    _setDefaultRoyalty(royalty_, royaltyFee_);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function setBaseURI(string memory newBaseURI)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _tokenBaseURI = newBaseURI;
  }

  function setCAddress(address newCAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _cAddress = newCAddress;
  }

  function airdrop(
    address[] calldata recipients,
    uint256[] calldata numberOfTokens,
    uint256 chunkNumber
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      numberOfTokens.length == recipients.length,
      'Invalid number of tokens'
    );
    require(!_processedChunks[chunkNumber], 'Chunk already processed');
    require(balanceOf(recipients[0]) == 0, 'Recipient already has tokens');

    uint256 length = recipients.length;
    for (uint256 i = 0; i < length; i++) {
      _mint(recipients[i], numberOfTokens[i]);
    }

    _processedChunks[chunkNumber] = true;
  }

  function mint(address to, uint256 quantity) external onlyOwner {
    _mint(to, quantity);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    external
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function burn(uint256 tokenId) external {
    require(_msgSender() == _cAddress, 'Invalid address');

    _burn(tokenId);
  }

  function chunkProcessed(uint256 chunkNumber) external view returns (bool) {
    return _processedChunks[chunkNumber];
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }
}