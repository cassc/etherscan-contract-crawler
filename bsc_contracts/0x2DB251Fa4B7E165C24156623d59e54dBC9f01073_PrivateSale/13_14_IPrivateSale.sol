// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPrivateSale {
  enum SaleStatus {
    PAUSED,
    BUY,
    CLAIM,
    BONUS
  }

  event Buy(address indexed user, uint256 value);
  event Claim(address indexed user, uint256 value);
  event BonusApplied(address indexed user, uint256 value);

  struct Bonus {
    uint256 from;
    uint256 percent;
  }

  struct PrivateSaleArgs {
    IERC20Metadata token;
    IERC20Metadata usd;
    uint64 limit;
    uint64 rate;
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
    uint64 rate;
    uint64 unlockedPercent;
    uint256 minPayment;
    uint256 maxPayment;
    bool sigVerifierEnabled;
  }

  struct UserData {
    uint64 balance;
    uint64 maxBalance;
    bool bonusClaimed;
  }
}