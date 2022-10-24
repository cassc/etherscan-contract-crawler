// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import './libs/ProviderToken.sol';
import "./interfaces/ITokenGate.sol";

contract BitcoinToken is ProviderToken {
  using Strings for uint256;
  ITokenGate immutable tokenGate;

  constructor(
    ITokenGate _tokenGate,
    IAssetProvider _assetProvider,
    IProxyRegistry _proxyRegistry
  ) ProviderToken(_assetProvider, _proxyRegistry, "On-Chain Bitcoin Art", "BITCOIN") {
    tokenGate = _tokenGate;
    description = "This is a part of Fully On-chain Generative Art project (https://fullyonchain.xyz/). All images are dymically generated on the blockchain.";
    mintPrice = 1e16; //0.01 ether, updatable
    mintLimit = 250; // initial limit, updatable with a hard limit of 1,000
  }

  function tokenName(uint256 _tokenId) internal pure override returns(string memory) {
    return string(abi.encodePacked('Bitcoin ', _tokenId.toString()));
  }

  function mint() public override virtual payable returns(uint256 tokenId) {
    require(nextTokenId < 1000, "Sold out"); // hard limit, regardless of updatable "mintLimit"
    require(msg.value >= mintPriceFor(msg.sender), 'Must send the mint price');
    tokenId = super.mint();
    assetProvider.processPayout{value:msg.value}(tokenId); // 100% distribution to the asset provider
  }

  function mintPriceFor(address _wallet) public override view virtual returns(uint256) {
    if (balanceOf(_wallet) < 1 && tokenGate.balanceOf(_wallet) > 0) {
      return mintPrice / 2; // 50% off only for the first one
    }
    return mintPrice;
  }
}