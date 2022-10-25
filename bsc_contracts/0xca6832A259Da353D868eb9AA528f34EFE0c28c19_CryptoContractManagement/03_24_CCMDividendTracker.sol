// BNB dividend tracker of:
// ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄       ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄    ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄ 
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌     ▐░░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
// ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌   ▐░▐░▌      ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▐░▌ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌     ▐░▌
// ▐░▌          ▐░▌          ▐░▌▐░▌ ▐░▌▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌▐░▌    ▐░▌
// ▐░▌          ▐░▌          ▐░▌ ▐░▐░▌ ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌ ▐░▌   ▐░▌
// ▐░▌          ▐░▌          ▐░▌  ▐░▌  ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░░▌    ▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌
// ▐░▌          ▐░▌          ▐░▌   ▀   ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌   ▐░▌ ▐░▌
// ▐░▌          ▐░▌          ▐░▌       ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌    ▐░▌▐░▌
// ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌          ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▌ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌          ▐░▌     ▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
 // ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀            ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀    ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀ 
// Welcome to CryptoContractManagement.
// Join us on our journey of revolutionizing the fund generation mode of crypto tokens.
//
// Key features:
// - Sophisticated taxation model to allow tokens to gather funds without hurting the charts
// - Highly customizable infrastructure which gives all the power into the hands of the token developers
// - Novel approach to separate token funding from its financial ecosystem
//
// Socials:
// - Website: https://ccmtoken.tech
// - Github: https://github.com/orgs/crypto-contract-management/repositories
// - Telegram: https://t.me/CCMGlobal
// - Twitter: https://twitter.com/ccmtoken

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DividendPayingTokenInterface.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
abstract contract DividendPayingToken is ERC20, DividendPayingTokenInterface {
  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(string memory name, string memory symbol) ERC20(name, symbol){ }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  fallback() external payable {
    distributeDividends();
  }
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare += msg.value * magnitude / totalSupply();
      emit DividendsDistributed(msg.sender, msg.value);
    }
  }

  function _withdrawDividend(address owner) internal returns(uint amountWithdrawn) {
    amountWithdrawn = withdrawableDividendOf(owner);
    if (amountWithdrawn > 0) {
      withdrawnDividends[owner] += amountWithdrawn;
      emit DividendWithdrawn(owner, amountWithdrawn);
      payable(owner).transfer(amountWithdrawn);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() external {
    _withdrawDividend(msg.sender);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view returns(uint256) {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }

  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return toUint256Safe(toInt256Safe(magnifiedDividendPerShare * balanceOf(_owner))
      + magnifiedDividendCorrections[_owner]) / magnitude;
  }

  function _setBalance(address owner, uint newBalance) internal {
    uint currentBalance = balanceOf(owner);
    if(newBalance > currentBalance)
      _mint(owner, newBalance - currentBalance);
    else if(newBalance < currentBalance)
      _burn(owner, currentBalance - newBalance);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
    magnifiedDividendCorrections[account] -= toInt256Safe(magnifiedDividendPerShare * value);
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
    magnifiedDividendCorrections[account] += toInt256Safe(magnifiedDividendPerShare * value);
  }
}

contract CCMDividendTracker is DividendPayingToken, Ownable {

  uint128 public autoClaimAfter;
  uint128 private _lastProcessedReceiverIndex;
  uint public minTokensForDividend;
  mapping(address => bool) public excludedFromDividend;
  mapping(address => bool) public isReceiverRegistered;
  mapping(address => uint) public dividendReceiverIndex;
  mapping(address => uint) public lastClaimAt;
  address[] private dividendReceivers;

  constructor() DividendPayingToken("CCMDividenTracker", "CCMDT") {
    autoClaimAfter = 1 hours;
    minTokensForDividend = 100000 * 10**decimals();
  }

  // Forbid any transfers. We're the only ones setting token balances.
  function _transfer(address, address, uint) internal pure override {
    require(false);
  }

  event AutoClaimUpdated(uint128);
  /// @notice Defines the time interval for which people get their claims automatically.
  /// @param _autoClaimAfter Time in seconds for the auto claim interval.
  function setAutoClaimAfter(uint128 _autoClaimAfter) external onlyOwner {
    require(_autoClaimAfter >= 1 hours && _autoClaimAfter <= 4 hours);
    autoClaimAfter = _autoClaimAfter;
    emit AutoClaimUpdated(_autoClaimAfter);
  }
  event MinTokensForDividendsUpdated(uint, uint);
  /// @notice Defines the minimum amount of tokens a holder has to hold to get rewards.
  /// @param minTokens Tokens needed to gain rewards.
  function setMinTokensForDividends(uint minTokens) external onlyOwner {
    uint minTokensBefore = minTokensForDividend;
    minTokensForDividend = minTokens;
    emit MinTokensForDividendsUpdated(minTokensBefore, minTokens);
  }
  event ExcludedWalletFromDividend(address, bool);
  /// @notice Excludes a wallet from dividends (owner, token contract for example).
  /// @param owner Wallet to exclude.
  /// @param excludeFromDividend Should exclude? Yes or no.
  function setExcludedFromDividend(address owner, bool excludeFromDividend) external onlyOwner {
    require(excludedFromDividend[owner] != excludeFromDividend);
    excludedFromDividend[owner] = excludeFromDividend;
    // We always set the balance to 0 here because no matter what 
    // if that wallet gets token at one point in time they start 
    // getting rewards based upon a balance of 0 since, well - it's the start.
    _setBalance(owner, 0);
    emit ExcludedWalletFromDividend(owner, excludeFromDividend);
  }

  function _removeDividendReceiverByAddress(address owner) private {
    dividendReceivers[dividendReceiverIndex[owner]] = dividendReceivers[dividendReceivers.length - 1];
    dividendReceivers.pop();
  }
  /// @notice Sets a user balance of this reward contract.
  /// @notice Used to synchronize the token contract balance with this reward contract balance.
  /// @param owner Wallet to set the balance for.
  /// @param newBalance Balance to set.
  function setBalance(address owner, uint newBalance) external onlyOwner {
    if(excludedFromDividend[owner])
      return;

    if(newBalance >= minTokensForDividend){
      _setBalance(owner, newBalance);
      if(!isReceiverRegistered[owner]) {
        dividendReceiverIndex[owner] = dividendReceivers.length;
        isReceiverRegistered[owner] = true;
        dividendReceivers.push(owner);
      }
    } else {
      _setBalance(owner, 0);
      if(isReceiverRegistered[owner]) {
        isReceiverRegistered[owner] = false;
        _removeDividendReceiverByAddress(owner);
      }
    }
  }

  function _canAutoClaim(address wallet) private view returns(bool canAutoClaim) {
    canAutoClaim = block.timestamp - lastClaimAt[wallet] >= autoClaimAfter;
  }
  /// @notice Claims the dividend for an owner (used by the token contract).
  /// @param owner The owner of the dividend to claim.
  function claimDividend(address owner) external onlyOwner {
    _withdrawDividend(owner);
  }
  /// @notice Process accounts by auto claiming them if eligible. Depends on their `lastClaimAt`.
  /// @param gasAvailable The gas used to process accounts. The more gas we have => the more accounts are processed in a transaction.
  function processAccounts(uint gasAvailable) external {
    uint accountIterations = 0;
    uint128 lastProcessedIndex = _lastProcessedReceiverIndex;
    uint gasUsed = 0;
    uint gasBefore = gasleft();
    address[] memory walletsToProcess = dividendReceivers;
    uint128 walletsToProcessLen = uint128(walletsToProcess.length);

    while(accountIterations < walletsToProcessLen && gasUsed < gasAvailable){
      address currentWallet = walletsToProcess[lastProcessedIndex];
      if(_canAutoClaim(currentWallet)){
        lastClaimAt[currentWallet] = block.timestamp;
        _withdrawDividend(currentWallet);
      }
      unchecked {
        accountIterations++;
        lastProcessedIndex = (lastProcessedIndex + 1) % walletsToProcessLen;
        uint newGas = gasleft();
        gasUsed += (gasBefore - newGas);
        gasBefore = newGas;
      }
    }

    _lastProcessedReceiverIndex = lastProcessedIndex;
  }
}