// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './Library.sol';
import './interfaces/IAssets.sol';
import './interfaces/ITacticalGear.sol';
import './interfaces/IForgedGear.sol';
import './interfaces/ILibrary.sol';

import './opensea-enforcer/DefaultOperatorFilterer.sol';

contract ForgedGear is ERC721Enumerable, Ownable, DefaultOperatorFilterer {
  using SafeMath for uint256;

  mapping(uint256 => uint256) private tokenToForgedAt;

  // contract references
  IAssets private assets;
  ITacticalGear private tacticalGear;

  constructor(
    string memory name,
    string memory symbol,
    address assetsAddress,
    address tacticalGearAddress
  ) ERC721(name, symbol) {
    assets = IAssets(assetsAddress);
    tacticalGear = ITacticalGear(tacticalGearAddress);
  }

  function forge(address to, uint256 tokenId) external {
    require(msg.sender == address(tacticalGear), 'Should be called by Gear contract');
    tokenToForgedAt[tokenId] = block.timestamp;
    _safeMint(to, tokenId);
  }

  function getForgedAt(uint256 tokenId) external view returns (uint256) {
    require(msg.sender == address(tacticalGear), 'Should be called by Gear contract');
    return tokenToForgedAt[tokenId];
  }

  function getForgedGear(uint256 tokenId) external view returns (IForgedGear.ForgedGear memory) {
    require(_exists(tokenId), 'Token does not exist');

    string memory prefix = tacticalGear.getPrefix(tokenId);
    string memory name = tacticalGear.getItem(tokenId).name;
    string memory suffix = tacticalGear.getSuffix(tokenId);
    string memory category = tacticalGear.getItem(tokenId).category;

    return
      IForgedGear.ForgedGear({
        fullName: string(abi.encodePacked(prefix, ' ', name, ' ', suffix)),
        name: name,
        category: category,
        prefix: prefix,
        suffix: suffix,
        isForged: true,
        extra: tacticalGear.hasR0N1(tokenId) ? 'R0N1' : 'None'
      });
  }

  function getImage(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    return
      Library.getImage(
        ILibrary.ImageInput(
          assets.getAsset(tacticalGear.getItem(tokenId).name),
          assets.getAsset(
            string(abi.encodePacked(tacticalGear.getPrefix(tokenId), ' ', tacticalGear.getItem(tokenId).name))
          ),
          assets.getAsset(string(abi.encodePacked('R0N1 ', tacticalGear.getItem(tokenId).name))),
          true,
          tacticalGear.hasR0N1(tokenId)
        )
      );
  }

  function getCardImage(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    return
      Library.getCardImage(
        ILibrary.CardImageInput(
          tacticalGear.getItem(tokenId).name,
          tacticalGear.getPrefix(tokenId),
          tacticalGear.getSuffix(tokenId),
          assets.getAsset(tacticalGear.getItem(tokenId).name),
          assets.getAsset(
            string(abi.encodePacked(tacticalGear.getPrefix(tokenId), ' ', tacticalGear.getItem(tokenId).name))
          ),
          assets.getAsset(tacticalGear.getSuffix(tokenId)),
          assets.getAsset(string(abi.encodePacked('R0N1 ', tacticalGear.getItem(tokenId).name))),
          true,
          tacticalGear.hasR0N1(tokenId),
          assets.getAsset('card'),
          assets.getAsset('font')
        )
      );
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    return
      Library.getMetadata(
        tacticalGear.getItem(tokenId),
        tacticalGear.getSuffix(tokenId),
        tacticalGear.getPrefix(tokenId),
        true,
        tacticalGear.hasR0N1(tokenId),
        getCardImage(tokenId)
      );
  }

  // OpenSea Enforcer functions
  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}