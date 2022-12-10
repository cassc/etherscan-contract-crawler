//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// LightLink 2022

contract LLPurchase is Ownable2Step {
  using SafeERC20 for IERC20;

  struct CurrencyInfo {
    bool active;
    address currency;
    uint16 decimals;
    uint16 rate;
    uint256 minimumPurchase;
  }

  // variables
  uint16 public constant ONE_RATE = 10_000;
  address public llCurrency;
  uint256 public totalSold;
  mapping(address => CurrencyInfo) public currencies;

  // events
  event Purchase(
    address indexed user,
    address indexed currency,
    CurrencyInfo currencyInfo,
    uint256 currencyAmount,
    uint256 llAmount
  );

  constructor() {}

  /** User */
  function purchase(address _currency, uint256 _currencyAmount) external {
    CurrencyInfo storage currency = currencies[_currency];

    require(currency.active, "Not active");
    require(_currencyAmount >= currency.minimumPurchase, "Minimum purchase");

    uint256 llDecimals = 10**18;
    uint256 llAmount = (_currencyAmount * ONE_RATE * llDecimals) / currency.rate;
    require(llAmount <= IERC20(llCurrency).balanceOf(address(this)), "Insufficient supply");

    uint256 currencyAmountWithDecimals = currency.minimumPurchase * (10**currency.decimals);
    IERC20(_currency).safeTransferFrom(msg.sender, address(this), currencyAmountWithDecimals);
    IERC20(llCurrency).safeTransfer(msg.sender, llAmount);

    totalSold += llAmount;

    emit Purchase(msg.sender, _currency, currencies[_currency], currencyAmountWithDecimals, llAmount);
  }

  /** Admin */
  // verified
  function setLLCurrency(address _address) external onlyOwner {
    llCurrency = _address;
  }

  // verified
  function setupCurrency(
    address _currency,
    uint16 _decimals,
    uint16 _rate,
    uint256 _minimumPurchase
  ) external onlyOwner {
    currencies[_currency] = CurrencyInfo(false, _currency, _decimals, _rate, _minimumPurchase);
  }

  // verified
  function toggleSaleActive(address _currency, bool _status) external onlyOwner {
    currencies[_currency].active = _status;
  }

  // verified
  function updateTokenDecimals(address _currency, uint16 _decimals) external onlyOwner {
    currencies[_currency].decimals = _decimals;
  }

  // verified
  function updateTokenRate(address _currency, uint16 _rate) external onlyOwner {
    currencies[_currency].rate = _rate;
  }

  // verified
  function updateTokenMinimumPurchase(address _currency, uint256 _minimumPurchase) external onlyOwner {
    currencies[_currency].minimumPurchase = _minimumPurchase;
  }

  // verified
  function withdrawERC20(address _currency, address _to) external onlyOwner {
    uint256 balance = IERC20(_currency).balanceOf(address(this));
    IERC20(_currency).safeTransfer(_to, balance);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Internal */
  function renounceOwnership() public virtual override onlyOwner {
    revert("Ownable: renounceOwnership function is disabled");
  }
}