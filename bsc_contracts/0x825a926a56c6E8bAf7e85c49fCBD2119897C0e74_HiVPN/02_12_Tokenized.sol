// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

import "./IAggregator.sol";
import "./ITokenized.sol";
import "./Secured.sol";
import "./IERC20.sol";

abstract contract Tokenized is ITokenized, Secured {
  mapping(address => address) public priceFeeds;
  address[] public tokenList;

  // Internal functions ----------------------------------------------------------
  function _tokenDetails(
    address token
  ) internal view returns (uint256 price, uint256 decimals) {
    price = tokenPrice(token);
    decimals = _tokenDecimals(token);
  }

  function _tokenSymbol(address token) internal view returns (string memory) {
    if (token == address(0)) return "BNB";
    return IERC20(token).symbol();
  }

  function _tokenDecimals(address token) internal view returns (uint256) {
    if (token == address(0)) return 18;
    return IERC20(token).decimals();
  }

  // View functions ------------------------------------------------------------
  function feedExists(address token) public view returns (bool) {
    return priceFeeds[token] != address(0);
  }

  function feedPrice(address feed) public view override returns (uint256) {
    (, int256 price, , , ) = IAggregator(feed).latestRoundData();
    return uint256(price);
  }

  function tokenPrice(address token) public view override returns (uint256) {
    return feedPrice(priceFeeds[token]);
  }

  function allTokens() external view override returns (address[] memory) {
    return tokenList;
  }

  function allPriceFeeds() external view override returns (address[] memory) {
    address[] memory feeds = new address[](tokenList.length);
    for (uint256 i = 0; i < tokenList.length; i++) {
      address token = tokenList[i];
      if (feedExists(token)) feeds[i] = priceFeeds[token];
    }
    return feeds;
  }

  function allTokensDetails()
    external
    view
    override
    returns (
      address[] memory addresses,
      string[] memory symbols,
      uint256[] memory decimals,
      uint256[] memory prices
    )
  {
    symbols = new string[](tokenList.length);
    decimals = new uint256[](tokenList.length);
    prices = new uint256[](tokenList.length);
    addresses = new address[](tokenList.length);
    for (uint256 i = 0; i < tokenList.length; i++) {
      address token = tokenList[i];
      prices[i] = tokenPrice(token);
      symbols[i] = _tokenSymbol(token);
      decimals[i] = _tokenDecimals(token);
      addresses[i] = token;
    }
  }

  function userTokenBalance(
    address user,
    address token
  ) public view override returns (uint256) {
    if (token == address(0)) return user.balance;
    return IERC20(token).balanceOf(user);
  }

  function userTokenAllowance(
    address user,
    address token
  ) public view override returns (uint256) {
    if (token == address(0)) return 1e25;
    return IERC20(token).allowance(user, address(this));
  }

  function userTokensDetails(
    address user
  )
    external
    view
    override
    returns (
      string[] memory symbols,
      uint256[] memory balances,
      uint256[] memory allowances
    )
  {
    symbols = new string[](tokenList.length);
    balances = new uint256[](tokenList.length);
    allowances = new uint256[](tokenList.length);
    for (uint256 i = 0; i < tokenList.length; i++) {
      address token = tokenList[i];
      symbols[i] = _tokenSymbol(token);
      balances[i] = userTokenBalance(user, token);
      allowances[i] = userTokenAllowance(user, token);
    }
  }

  // Modify functions ------------------------------------------------------------
  function setPriceFeeds(address token, address feed) public onlyOwner {
    if (!feedExists(token)) tokenList.push(token);

    priceFeeds[token] = feed;
  }

  function batchSetPriceFeeds(
    address[] memory tokens,
    address[] memory feeds
  ) public onlyOwner {
    require(tokens.length == feeds.length, "LNG");
    for (uint256 i = 0; i < tokens.length; i++) {
      setPriceFeeds(tokens[i], feeds[i]);
    }
  }

  function batchRemovePriceFeeds(address[] memory tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      delete priceFeeds[tokens[i]];
    }
    cleanTokenList();
  }

  function cleanTokenList() public onlyOwner {
    for (uint256 i = 0; i < tokenList.length; i++) {
      if (!feedExists(tokenList[i])) {
        tokenList[i] = tokenList[tokenList.length - 1];
        tokenList.pop();
      }
    }
  }

  // Transfer functions --------------------------------------------------------
  function withdrawToken(address token, uint256 value) external onlyOwner {
    IERC20(token).transfer(owner, value);
  }

  function withdrawBnb(uint256 value) external onlyOwner {
    payable(owner).transfer(value);
  }
}