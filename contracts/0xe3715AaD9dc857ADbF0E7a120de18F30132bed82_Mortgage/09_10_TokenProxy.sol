// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Vault.sol';
import '../interfaces/ITokenProxy.sol';
import '../interfaces/ICToken.sol';

contract TokenProxy is Vault, ITokenProxy {
  address admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  // Enter Markets
  function enterMarkets(address comptroller, address[] calldata cTokens) external override returns(uint256[] memory) {
    return IComptroller(comptroller).enterMarkets(cTokens);
  }

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external override onlyOwner {
    ICEther(cToken).borrow(amount);
    payable(admin).transfer(amount);
  }

  // Claim NFT
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external override onlyOwner {
    uint256 amount = redeemTokenIndexes.length;
    uint256[] memory tokenIds = new uint256[](amount);

    ICERC721 supplyCToken = ICERC721(cToken);
    address _this = address(this);
    for (uint256 i = 0; i < amount; i++) {
      tokenIds[i] = supplyCToken.userTokens(_this, redeemTokenIndexes[i]);
    }

    supplyCToken.redeems(redeemTokenIndexes);

    IUnderlying underlying = IUnderlying(supplyCToken.underlying());
    for (uint256 i = 0; i < amount; i++) {
      underlying.transferFrom(_this, to, tokenIds[i]);
    }
  }

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external override onlyOwner {
    ICERC721 supplyCToken = ICERC721(cToken);
    for (uint256 i = 0; i < amount; i++) {
      supplyCToken.transfer(to, 0);
    }
  }
}