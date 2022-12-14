// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Errors.sol";
import "./IPrivateSale.sol";

contract PrivateSale is Ownable, IPrivateSale {
  using SafeCast for uint256;
  using SafeERC20 for IERC20Metadata;
  using Strings for address;

  // ========================================
  // State variables
  // ========================================

  SaleData internal _sale;
  Bonus[] internal _bonuses;
  mapping(address => UserData) internal _users;
  mapping(address => bool) internal _whitelist;
  mapping(address => uint256) internal _tips;

  // ========================================
  // Constructor
  // ========================================

  constructor(PrivateSaleArgs memory args) {
    _sale = SaleData({
      status: SaleStatus.BUY,
      locked: 0,
      unlockedPercent: 0,
      sigVerifierEnabled: true,
      token: args.token,
      usd: args.usd,
      limit: args.limit,
      rate: args.rate,
      minPayment: args.minPayment,
      maxPayment: args.maxPayment
    });

    _copyBonusesToStorage(args.bonuses);
  }

  // ========================================
  // Main methods
  // ========================================

  // Transfers USD from user and adds locked tokens in contract state
  function buy(
    bytes32 hash,
    bytes calldata sig,
    uint256 usdValue
  ) external onlyWhen(SaleStatus.BUY) {
    uint256 value = _validateBuyOrder(hash, sig, usdValue);

    _sale.usd.safeTransferFrom(msg.sender, address(this), usdValue);

    _updateStorageAfterBuy(value);

    emit Buy(msg.sender, value);
  }

  // Transfers part of tokens to user
  function claim() external onlyWhenOneOf(SaleStatus.CLAIM, SaleStatus.BONUS) {
    uint256 value = _validateClaimOrder();

    _sale.token.safeTransfer(msg.sender, value);

    _updateStorageAfterClaim(value);

    emit Claim(msg.sender, value);
  }

  // Transfers bonus to user if applied
  function claimBonus() external onlyWhen(SaleStatus.BONUS) {
    uint256 value = _validateClaimBonusOrder();

    _sale.token.safeTransfer(msg.sender, value);

    _updateStorageAfterClaimBonus();

    emit BonusApplied(msg.sender, value);
  }

  // ========================================
  // Owner methods
  // ========================================

  // Add signer address to whitelist
  function addToWhitelist(address[] calldata list) external onlyOwner {
    _addToWhitelist(list);
  }

  // Remove signer address from whitelist
  function removeFromWhitelist(address[] calldata list) external onlyOwner {
    _removeFromWhitelist(list);
  }

  // Allow owner to change tokens limit
  function setLimit(uint64 limit) external onlyOwner {
    _sale.limit = limit;
  }

  // IMPORTANT change only buy => claim => bonus
  // Set paused at any moment
  function setStatus(SaleStatus status) external onlyOwner {
    _sale.status = status;
  }

  // Allow owner to change min/max payment limits
  function setPaymentLimits(uint256 min, uint256 max) external onlyOwner {
    _sale.minPayment = min;
    _sale.maxPayment = max;
  }

  // Can be used to disable Signature verification
  function setSigVerifierEnabled(bool enabled) external onlyOwner {
    _sale.sigVerifierEnabled = enabled;
  }

  // Set unlocked percent value
  function setUnlockedPercent(uint64 unlockedPercent) external onlyOwner {
    _sale.unlockedPercent = unlockedPercent;
  }

  // Add bonuses
  function addBonuses(Bonus[] calldata bonuses) external onlyOwner {
    _copyBonusesToStorage(bonuses);
  }

  // Remove bonuses by their indices
  function removeBonuses(uint256[] calldata indices) external onlyOwner {
    _removeBonusesFromStorage(indices);
  }

  // IMPORTANT
  // Contract logic will break if token balance is lower than locked value + bonuses
  function transferToken(address token, address to, uint256 value) external onlyOwner {
    IERC20Metadata(token).safeTransfer(to, value);
  }

  // Transfer only to known EOA address, use reentrancy guard otherwise
  function transfer(address payable to, uint256 value) external onlyOwner {
    Address.sendValue(to, value);
  }

  // Allow owner to set tip percent for signer
  function setTip(uint256 value, address addr) external onlyOwner {
    _tips[addr] = value;
  }

  // Allow owner to send ETH to contract
  function fund() external payable onlyOwner {}

  // ========================================
  // Views
  // ========================================

  // Returns user data by address
  function users(address addr) external view returns (UserData memory) {
    return _users[addr];
  }

  // Returns list of bonuses
  function getBonuses() external view returns (Bonus[] memory) {
    return _bonuses;
  }

  // Return true if signer is whitelisted
  function isWhitelisted(address addr) external view returns (bool) { 
    return _whitelist[addr];
  }

  // Returns sale data
  function saleData() external view returns (SaleData memory) {
    return _sale;
  }

  // Returns how many more tokens users can buy
  function availableTokens() external view returns (uint256) {
    return _availableTokens();
  }

  // Returns how many percent of tip is assigned to signer
  function getTip(address addr) external view returns (uint256) {
    return _tips[addr];
  }

  // Returns how many tokens user is able or will be able to receive as bonus
  function getBonusForUser(address addr) external view returns (uint256) {
    return _getBonusForUser(_users[addr]);
  }

  // Returns how many tokens user can currently claim
  function availableToClaim(address addr) external view returns (uint256) {
    if (_sale.status == SaleStatus.PAUSED || _sale.status == SaleStatus.BUY) return 0; 

    UserData memory user = _users[addr];

    return _availableToClaim(_sale.unlockedPercent, user.balance, user.maxBalance);
  }

  // ========================================
  // Internals
  // ========================================

  // Validate and calculate amount of tokens to lock
  function _validateBuyOrder(
    bytes32 hash,
    bytes calldata sig,
    uint256 usdValue
  ) internal view returns (uint256) {
    address signer = _verifySignature(hash, sig);

    if (usdValue < _sale.minPayment) revert PaymentTooLow();
    if (usdValue > _sale.maxPayment) revert PaymentTooHigh();

    uint256 tokenValue = _calculateTokenValue(usdValue, _sale.rate, _sale.usd.decimals());
  
    if (tokenValue == 0) revert TokenZeroValue();

    uint256 withTip = _applyTip(tokenValue, signer);

    if (_availableTokens() < withTip) revert NoAvailableTokens();

    return withTip;
  }

  // Validate and calculate amount of tokens to unlock
  function _validateClaimOrder() internal view returns (uint256) {
    UserData memory user = _users[msg.sender];
    if (user.balance == 0) revert ZeroLockedValue();

    uint256 value = _availableToClaim(_sale.unlockedPercent, user.balance, user.maxBalance);
    if (value == 0) revert NothingTooClaim();

    return value;
  }

  // Validate and calculate value of bonus to give
  function _validateClaimBonusOrder() internal view returns (uint256) {
    UserData memory user = _users[msg.sender];

    if (user.maxBalance == 0) revert NoBalanceExists();
    if (user.balance != 0) revert LockedTokensNotWithdrawn();
    if (user.bonusClaimed) revert BonusAlreadyClaimed();

    uint256 bonus = _getBonusForUser(user);
    if (bonus == 0) revert NoBonusApplied();

    return bonus;
  }

  // Update contract state after buying tokens
  function _updateStorageAfterBuy(uint256 value) internal {
    UserData memory current = _users[msg.sender];

    uint64 downcasted = value.toUint64();

    current.balance += downcasted;
    current.maxBalance += downcasted;

    _sale.locked += downcasted;
    _users[msg.sender] = current;
  }

  // Update contract state after claiming tokens
  function _updateStorageAfterClaim(uint256 value) internal {
    uint64 downcasted = value.toUint64();

    _sale.locked -= downcasted;
    _users[msg.sender].balance -= downcasted;
  }

  // Update contract state after claiming bonus
  function _updateStorageAfterClaimBonus() internal {
    _users[msg.sender].bonusClaimed = true;
  }

  // How many tokens should user receive in bonus stage
  function _getBonusForUser(UserData memory user) internal view returns (uint256) {
    uint256 paid = _calculateUsdValue(user.maxBalance, _sale.rate, _sale.usd.decimals());
    uint256 bonusPercent = _matchBonus(paid);
    return _calculateBonus(user.maxBalance, bonusPercent);
  }
  
  // Returns how many tokens will user receive for given amount of usd
  function _calculateTokenValue(uint256 usdValue, uint256 rate, uint8 usdDecimals) internal pure returns (uint256) {
    return usdValue * rate / 10 ** usdDecimals;
  }

  // Returns how many usd user paid for tokens
  function _calculateUsdValue(uint256 tokenValue, uint256 rate, uint8 usdDecimals) internal pure returns (uint256) {
    return tokenValue * 10 ** usdDecimals / rate;
  }

  // Returns how many tokens contract can currently sell
  function _availableTokens() internal view returns (uint256) {
    SaleData memory sale = _sale;

    if (sale.locked > sale.limit) return 0;

    return sale.limit - sale.locked;
  }

  // Add tip to total value (max 50%)
  function _applyTip(uint256 baseValue, address user) internal view returns (uint256) {
    uint256 tip = _tips[user];

    if (tip > 5000) return baseValue * 3 / 2;

    return baseValue + baseValue * tip / 10000;
  }

  // Returns how many tokens user can currently claim
  function _availableToClaim(uint256 percent, uint256 balance, uint256 maxBalance) internal pure returns (uint256) {
    if (balance > maxBalance) return 0;
    if (percent == 0) return 0;
    if (percent >= 100) return balance;

    uint256 maxTotal = (maxBalance * percent) / 100;
    uint256 diff = maxBalance - balance;

    if (maxTotal < diff) return 0;

    return maxTotal - diff;
  }

  // Returns percent value of bonus to apply to user
  function _matchBonus(uint256 paid) internal view returns (uint256) {
    uint256 highest = 0;

    for (uint256 i = 0; i < _bonuses.length;) {
      Bonus memory bonus = _bonuses[i];

      if (paid >= bonus.from && bonus.percent > highest) {
        highest = bonus.percent;
      }

      unchecked { i++; }
    }

    return highest;
  }

  // How many tokens should be returned at bonus stage given specific percent
  function _calculateBonus(uint256 bought, uint256 percent) internal pure returns (uint256) {
    return bought * percent / 100;
  }

  // Called on contract init or when bonuses are added
  function _copyBonusesToStorage(Bonus[] memory bonuses) internal {
    for (uint256 i = 0; i < bonuses.length;) {
      _bonuses.push(bonuses[i]);
      unchecked { i++; }
    }
  }

  // Called when bonuses are removed
  function _removeBonusesFromStorage(uint256[] calldata indices) internal {
    for (uint256 i = 0; i < indices.length;) {
      delete _bonuses[indices[i]];
      unchecked { i++; }
    }
  }

  // Verify that message was signed correctly by whitelisted address
  function _verifySignature(bytes32 hash, bytes calldata sig) internal view returns (address) {
    if (!_sale.sigVerifierEnabled) return address(0);

    (address recovered, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, sig);
    if (err != ECDSA.RecoverError.NoError) revert InvalidSignature();
    if (recovered == msg.sender) revert RecoveredMsgSender();

    bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(msg.sender.toHexString()));
    if (messageHash != hash) revert InvalidMessageHash();

    if (!_whitelist[recovered]) revert SignerNotWhitelisted();

    return recovered;
  }

  // Whitelist signer address
  function _addToWhitelist(address[] calldata list) internal {
    for (uint256 i = 0; i < list.length;) {
      _whitelist[list[i]] = true;
      unchecked { i++; }
    }
  }

  // Blacklist signer address
  function _removeFromWhitelist(address[] calldata list) internal {
    for (uint256 i = 0; i < list.length;) {
      _whitelist[list[i]] = false;
      unchecked { i++; }
    }
  }

  // ========================================
  // Modifiers
  // ========================================

  // Allow to continue only if status matches current sale status
  modifier onlyWhen(SaleStatus status) {
    if (_sale.status != status) revert InvalidSaleStatus();
    _;
  }

  // Allow to continue if any of 2 statuses matches current sale status
  modifier onlyWhenOneOf(SaleStatus option1, SaleStatus option2) {
    SaleStatus current = _sale.status;

    if (current != option1 && current != option2) revert InvalidSaleStatus();
    _;
  }
}