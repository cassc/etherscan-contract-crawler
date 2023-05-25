// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TipjaToken is Ownable, ERC20 {
  uint256 public constant TOTAL_SUPPLY = 10 * (10 ** 12) * (10 ** 18); // Total 10 trillion TIPJA

  // Sniper bots and MEV protection
  mapping(address => bool) public blacklistedBots;

  // AMM
  mapping(address => bool) public ammPairs;

  // Exclude from fee and max transaction amount
  mapping(address => bool) public excludedFromFee;
  mapping(address => bool) public excludedFromMaxTransactionAmount;

  // Sell fees, only applied in limited mode, to prevent bots
  uint256 public sellFee = 50; // 50% sell fee

  // Max transaction amount, only applied in limited mode
  uint256 public maxTransactionAmount;

  // Flags
  bool public isTradingActive; // Set to true when trading is enabled
  bool public isLimited = true; // Set to false when it gets stable

  // Events
  event BlacklistedBot(address bot, bool isBlacklisted);
  event SetAmmPair(address pair, bool isPair);
  event TradingEnabled();
  event LimitationDisabled();
  event SellFeeUpdated(uint256 fee);
  event MaxTransactionAmountUpdated(uint256 amount);

  constructor() ERC20("Tipja", "TIPJA") {
    _mint(msg.sender, TOTAL_SUPPLY);
  }

  // Blacklist Sniper and MEV bots
  function blacklistBot(address _bot, bool _isBlacklisted) external onlyOwner {
    blacklistedBots[_bot] = _isBlacklisted;

    emit BlacklistedBot(_bot, _isBlacklisted);
  }

  // Enable trading, never can be disabled
  function enableTrading() external onlyOwner {
    isTradingActive = true;

    emit TradingEnabled();
  }

  // Disable limited mode when coin becomes stable, never can be enabled again
  function disableLimited() external onlyOwner {
    isLimited = false;

    emit LimitationDisabled();
  }

  // Set AMM pair
  function setAmmPair(address _pair, bool _isPair) external onlyOwner {
    ammPairs[_pair] = _isPair;

    emit SetAmmPair(_pair, _isPair);
  }

  // Set sell fee in percentage
  function setSellFee(uint256 _sellFee) external onlyOwner {
    require(_sellFee < 50, "Sell fee must be less than 50%");

    sellFee = _sellFee;

    emit SellFeeUpdated(_sellFee);
  }

  // Set max transaction amount
  function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
    maxTransactionAmount = _maxTransactionAmount;

    emit MaxTransactionAmountUpdated(_maxTransactionAmount);
  }

  // Exclude from fee
  function excludeFromFee(address _account, bool _excluded) external onlyOwner {
    excludedFromFee[_account] = _excluded;
  }

  // Exclude from max transaction
  function excludeFromMaxTransactionAmount(address _account, bool _excluded) external onlyOwner {
    excludedFromMaxTransactionAmount[_account] = _excluded;
  }

  // Override _transfer
  function _transfer(address from, address to, uint256 amount) internal override {
    require(!blacklistedBots[from] && !blacklistedBots[to], "Blacklisted address");

    // Non-owner can transfer tokens before trading starts
    if (from != owner() && to != owner()) {
      require(isTradingActive, "Trading is not started yet");
    }

    // Check limitation
    if (isLimited) {
      // Check max transaction amount
      if (ammPairs[from] && !excludedFromMaxTransactionAmount[to]) {
        // On buy
        require(amount <= maxTransactionAmount, "Max buy amount exceeded");
      } else if (ammPairs[to] && !excludedFromMaxTransactionAmount[from]) {
        // On sell
        require(amount <= maxTransactionAmount, "Max sell amount exceeded");
      }

      // Apply sell fee
      if (ammPairs[to] && !excludedFromFee[from]) {
        uint256 fee = amount * sellFee / 100;

        if (fee > 0) {
          super._transfer(from, address(this), fee);
          amount -= fee;
        }
      }
    }

    super._transfer(from, to, amount);
  }

  // Burn TIPJA
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}