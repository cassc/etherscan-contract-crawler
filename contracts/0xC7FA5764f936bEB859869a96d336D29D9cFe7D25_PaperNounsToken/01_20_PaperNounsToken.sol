// SPDX-License-Identifier: MIT

/*
 * This is a pert of Fully On-chain Generative Art project.
 *
 * web: https://fullyonchain.xyz/
 * github: https://github.com/Cryptocoders-wtf/generative
 * discord: https://discord.gg/4JGURQujXK
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import './libs/ProviderToken4.sol';
import './interfaces/ITokenGate.sol';

contract PaperNounsToken is ProviderToken4 {
  using Strings for uint256;
  ITokenGate public immutable tokenGate;
  bool public locked = true;
  bool public limited = true;
  IERC721 public dotNouns;

  constructor(
    ITokenGate _tokenGate,
    IAssetProvider _assetProvider,
    IERC721 _dotNouns
  ) ProviderToken4(_assetProvider, 'Paper Nouns', 'PAPERNOUNS') {
    tokenGate = _tokenGate;
    description = 'This is a part of Fully On-chain Generative Art project (https://fullyonchain.xyz/). All images are dymically generated on the blockchain.';
    mintPrice = 1e16; //0.01 ether, updatable
    dotNouns = _dotNouns;
  }

  function setLock(bool _locked) external onlyOwner {
    locked = _locked;
  }

  function setLimited(bool _limited) external onlyOwner {
    limited = _limited;
  }

  // Disable any approve and transfer during the initial minting
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override(ERC721WithOperatorFilter, IERC721) {
    require(!locked, "The contract is locked during the initial minting.");
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public virtual override(ERC721WithOperatorFilter, IERC721) {
    require(!locked, "The contract is locked during the initial minting.");
    super.approve(operator, tokenId);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
    require(!locked, "The contract is locked during the initial minting.");
    return super._isApprovedOrOwner(spender, tokenId);
  }

  function tokenName(uint256 _tokenId) internal pure override returns (string memory) {
    return string(abi.encodePacked('Paper Nouns ', _tokenId.toString()));
  }

  function toBeGifted(uint256 _tokenId) public pure returns(bool) {
    uint256[33] memory list = [uint256(1), 245, 403, 405, 406, 407, 410, 415, 416, 417, 419, 422, 423, 434, 450, 452, 453,
454, 456, 460, 471, 474, 475, 479, 487, 490, 492, 497, 499, 505, 512, 519, 543];
    for (uint i = 0; i < list.length; i++) {
      if (list[i] == _tokenId) {
        return true;
      }
    }
    return false;
  }

  function mint() public payable virtual override returns (uint256 tokenId) {
    // require(nextTokenId < 2500, 'Sold out'); // hard limit, regardless of updatable "mintLimit"
    require(msg.value >= mintPriceFor(msg.sender), 'Must send the mint price');
    require(balanceOf(msg.sender) < 3, 'Too many tokens');

    tokenId = super.mint();

    // Special case for Nouns 245 and V2 dot Nouns
    while (toBeGifted(nextTokenId)) {
      uint256 extraTokenId = nextTokenId++;
      address dotNounsOwner = dotNouns.ownerOf(extraTokenId);
      if (dotNounsOwner != address(0)) {
        _safeMint(dotNounsOwner, extraTokenId);
      } else {
        break;
      }
    }

    assetProvider.processPayout{ value: msg.value }(tokenId); // 100% distribution to the asset provider
  }

  function mintLimit() public view override returns (uint256) {
    return assetProvider.totalSupply();
  }

  function mintPriceFor(address _wallet) public view virtual override returns (uint256) {
    uint256 wlCount = tokenGate.balanceOf(_wallet);
    uint256 balance = balanceOf(_wallet);
    // During the private sale
    if (limited) {
      if (balance == 0 && wlCount > 0) {
        return mintPrice / 2; // 50% off for WL holders (only one per wallet)
      }
      return mintPrice * 4; // 4x, otherwise
    }

    // Public sale
    if (balance == 0 || balance < wlCount) {
      return mintPrice; // standard price for public or WL holder (upto the limit)
    }

    return mintPrice * 2; // 200% more beyond the limit
  }

  function _processRoyalty(uint _salesPrice, uint _tokenId) internal override returns (uint256 royalty) {
    royalty = (_salesPrice * 50) / 1000; // 5.0%
    assetProvider.processPayout{ value: royalty }(_tokenId);
  }
}