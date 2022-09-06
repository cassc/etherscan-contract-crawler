// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./openzeppelin/Ownable.sol";
import "./PriceOracle.sol";
import "./CErc20.sol";

contract SimplePriceOracle is PriceOracle, Ownable {
  mapping(address => uint) prices;
  event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

  function setDirectPrices(address[] calldata tokens, uint256[] calldata pricesToSet) external onlyOwner {
    require(tokens.length == pricesToSet.length, "tokens and prices must have the same length");
    for (uint i = 0; i < tokens.length; i ++) {
      setDirectPrice(tokens[i], pricesToSet[i]);
    }
  }

  function _getUnderlyingAddress(CToken cToken) private view returns (address) {
    address asset;
    if (compareStrings(cToken.symbol(), "dETH")) {
      asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    } else {
      asset = address(CErc20(address(cToken)).underlying());
    }
    return asset;
  }

  function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
    return prices[_getUnderlyingAddress(cToken)];
  }

  function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public onlyOwner {
    address asset = _getUnderlyingAddress(cToken);
    emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
    prices[asset] = underlyingPriceMantissa;
  }

  function setDirectPrice(address asset, uint price) public onlyOwner {
    emit PricePosted(asset, prices[asset], price, price);
    prices[asset] = price;
  }

  // v1 price oracle interface for use as backing of proxy
  function assetPrices(address asset) external view returns (uint) {
    return prices[asset];
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}