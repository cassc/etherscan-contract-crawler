// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import './libs/ProviderToken3.sol';
import "./interfaces/ITokenGate.sol";

contract DotNounsToken is ProviderToken3 {
  using Strings for uint256;
  ITokenGate public immutable tokenGate;
  address immutable public designer;

  constructor(
    ITokenGate _tokenGate,
    IAssetProvider _assetProvider,
    address _designer
  ) ProviderToken3(_assetProvider, "Dot Nouns", "DOTNOUNS") {
    tokenGate = _tokenGate;
    designer = _designer;
    description = "This is a part of Fully On-chain Generative Art project (https://fullyonchain.xyz/). All images are dymically generated on the blockchain.";
    mintPrice = 1e16; //0.01 ether, updatable
  }

  function tokenName(uint256 _tokenId) internal pure override returns(string memory) {
    return string(abi.encodePacked('Dot Nouns ', _tokenId.toString()));
  }

  function mint() public override virtual payable returns(uint256 tokenId) {
    require(nextTokenId < 2500, "Sold out"); // hard limit, regardless of updatable "mintLimit"
    require(msg.value >= mintPriceFor(msg.sender), 'Must send the mint price');
    require(balanceOf(msg.sender) < 3, "Too many tokens");

    // Special case for Nouns 245
    if (nextTokenId == 245) {
      tokenId = nextTokenId++; 
      _safeMint(owner(), tokenId);
    }
    tokenId = super.mint();

    uint royalty = msg.value / 5; // 20% to the designer
    address payable payableTo = payable(designer);
    payableTo.transfer(royalty);

    assetProvider.processPayout{value:msg.value - royalty}(tokenId); // 100% distribution to the asset provider
  }

  function mintLimit() public view override returns(uint256) {
    return assetProvider.totalSupply();
  }

  function mintPriceFor(address _wallet) public override view virtual returns(uint256) {
    if (balanceOf(_wallet) == 1) {
      return mintPrice * 2; // x2 for second
    } else if (balanceOf(_wallet) == 2) {
      return mintPrice * 4; // x4 for third
    }
    if (tokenGate.balanceOf(_wallet) > 0) {
      return mintPrice / 2; // 50% off
    }
    return mintPrice;
  }

  function _processRoyalty(uint _salesPrice, uint _tokenId) internal override returns(uint256 royalty) {
    royalty = _salesPrice * 50 / 1000; // 5.0%
    assetProvider.processPayout{value:royalty}(_tokenId);
  }
}