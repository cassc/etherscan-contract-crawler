// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import './libs/ProviderToken2.sol';
import "./interfaces/ITokenGate.sol";

contract AlphabetToken is ProviderToken2 {
  using Strings for uint256;
  ITokenGate immutable tokenGate;

  constructor(
    ITokenGate _tokenGate,
    IAssetProvider _assetProvider
  ) ProviderToken2(_assetProvider, "On-Chain Alphabet", "ALPHABET") {
    tokenGate = _tokenGate;
    description = "This is a part of Fully On-chain Generative Art project (https://fullyonchain.xyz/). All images are dymically generated on the blockchain.";
    mintPrice = 1e16; //0.01 ether, updatable
    mintLimit = 250; // initial limit, updatable with a hard limit of 2,500
  }

  function tokenName(uint256 _tokenId) internal pure override returns(string memory) {
    return string(abi.encodePacked('Alphabet ', _tokenId.toString()));
  }

  function mint() public override virtual payable returns(uint256 tokenId) {
    require(nextTokenId < 2500, "Sold out"); // hard limit, regardless of updatable "mintLimit"
    require(msg.value >= mintPriceFor(msg.sender), 'Must send the mint price');
    require(balanceOf(msg.sender) < 3, "Too many tokens");
    tokenId = super.mint();
    assetProvider.processPayout{value:msg.value}(tokenId); // 100% distribution to the asset provider
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