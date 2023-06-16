// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";
import "../PriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LengthFoundryAppraiser is BaseFoundryAppraiser {
  event CriteriaCreated(
    uint256 id,
    uint256[] prices,
    IERC20 priceToken,
    IERC20 payToken
  );
  event PricesSet(uint256 id, uint256[] prices);
  event OwnershipTransferred(uint256 id, address newOwner);

  struct Criterion {
    address owner;
    uint256[] prices;
    IERC20 priceToken;
    IERC20 payToken;
  }

  FoundryPriceOracle public priceOracle;
  Criterion[] public criteria;
  address public nativeToken;

  constructor(FoundryPriceOracle _priceOracle) {
    priceOracle = _priceOracle;
    nativeToken = address(_priceOracle.nativeToken());
  }

  function createCriteria(
    uint256[] memory prices,
    IERC20 priceToken,
    IERC20 payToken
  ) external returns (uint256) {
    criteria.push(Criterion(msg.sender, prices, priceToken, payToken));
    uint256 newId = criteria.length - 1;

    // Emit the event
    emit CriteriaCreated(newId, prices, priceToken, payToken);

    return newId;
  }

  function setPrices(uint256 id, uint256[] memory prices) external {
    require(id < criteria.length, "Criteria does not exist.");
    require(criteria[id].owner == msg.sender, "Not the criteria owner.");

    criteria[id].prices = prices;

    emit PricesSet(id, prices);
  }

  function getPrices(uint256 id) external view returns (uint256[] memory) {
    require(id < criteria.length, "Criteria does not exist.");
    return criteria[id].prices;
  }

  function getPrice(uint256 id, string memory label)
    public
    view
    returns (uint256)
  {
    require(id < criteria.length, "Criteria does not exist.");
    uint256[] memory prices = criteria[id].prices;
    uint256 chars = bytes(label).length;
    uint256 max = prices.length;

    if (max == 0) {
      return 0;
    }

    return prices[chars >= max ? 0 : max - chars];
  }

  function appraise(uint256 id, string memory label)
    external
    view
    override
    returns (uint256, IERC20)
  {
    uint256 price = getPrice(id, label);

    address priceToken = address(criteria[id].priceToken);
    address payToken = address(criteria[id].payToken);

    if (priceToken == payToken) {
      return (
        price,
        IERC20(priceToken == nativeToken ? address(0) : priceToken)
      );
    }

    uint256 pay = priceOracle.convert(uint128(price), priceToken, payToken);
    return (pay, IERC20(payToken == nativeToken ? address(0) : payToken));
  }

  function transferOwnership(uint256 id, address newOwner) external {
    require(id < criteria.length, "Criteria does not exist.");
    require(criteria[id].owner == msg.sender, "Not the criteria owner.");

    criteria[id].owner = newOwner;

    emit OwnershipTransferred(id, newOwner);
  }
}