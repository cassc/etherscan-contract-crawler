// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPrivateSale {
  enum SaleStatus {
    PAUSED,
    BUY,
    CLAIM
  }

  event Buy(address indexed user, uint256 received);
  event Claim(address indexed user, uint256 value);

  struct Bonus {
    uint256 from;
    uint256 percent;
  }

  struct PrivateSaleArgs {
    IERC20Metadata token;
    IERC20Metadata usd;
    uint64 limit;
    uint256 price;
    uint256 minPayment;
    uint256 maxPayment;
    Bonus[] bonuses;
  }

  struct SaleData {
    SaleStatus status;
    IERC20Metadata token;
    IERC20Metadata usd;
    uint64 locked;
    uint64 limit;
    uint256 price;
    uint64 unlockedPercent;
    uint256 minPayment;
    uint256 maxPayment;
    bool sigVerifierEnabled;
  }

  struct UserData {
    uint64 balance;
    uint64 maxBalance;
    uint128 paid;
  }

  struct BuyDataItem {
    uint256 usdValue;
    uint256 percent;
    uint256 price;
    uint256 tokenValue;
  }
}