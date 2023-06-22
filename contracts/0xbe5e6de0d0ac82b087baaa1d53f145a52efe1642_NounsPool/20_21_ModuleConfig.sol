// SPDX-License-Identifier: GPL-3.0

import { OwnableUpgradeable } from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { IDelegationRegistry } from "delegate-cash/IDelegationRegistry.sol";
import { IBatchProver } from "relic-sdk/packages/contracts/interfaces/IBatchProver.sol";
import { IReliquary } from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Wallet } from "src/wallet/Wallet.sol";

pragma solidity ^0.8.19;

// The storage slot index of the mapping containing Nouns token balance
bytes32 constant SLOT_INDEX_TOKEN_BALANCE = bytes32(uint256(4));

// The storage slot index of the mapping containing Nouns delegate addresses
bytes32 constant SLOT_INDEX_DELEGATE = bytes32(uint256(11));

abstract contract ModuleConfig is OwnableUpgradeable {
  /// Emitted when storage slots are updated
  event SlotsUpdated(bytes32 balanceSlot, bytes32 delegateSlot);

  /// Emitted when the config is updated
  event ConfigChanged();

  /// Returns if a lock is active for this module
  error ConfigModuleHasActiveLock();

  /// Config is the structure of cfg for a Governance Pool module
  struct Config {
    /// The base wallet address for this module
    address base;
    /// The address of the DAO we are casting votes against
    address externalDAO;
    /// The address of the token used for voting in the external DAO
    address externalToken;
    /// feeRecipient is the address that receives any configured protocol fee
    address feeRecipient;
    /// The minimum bid accepted to cast a vote
    uint256 reservePrice;
    /// castWaitBlocks prevents any votes from being cast until this time in blocks has passed
    uint256 castWaitBlocks;
    /// The minimum percent difference between the last bid placed for a
    /// proposal vote and the current one
    uint256 minBidIncrementPercentage;
    /// The window in blocks when a vote can be cast
    uint256 castWindow;
    /// The default tip configured for casting a vote
    uint256 tip;
    /// feeBPS as parts per 10_000, i.e. 10% = 1000
    uint256 feeBPS;
    /// The maximum amount of base fee that can be refunded when casting a vote
    uint256 maxBaseFeeRefund;
    /// max relic batch prover version; if 0 any prover version is accepted
    uint256 maxProverVersion;
    /// relic reliquary address
    address reliquary;
    /// delegate cash registry address
    address dcash;
    /// fact validator address
    address factValidator;
    /// in preparation for Nouns governance v2->v3 we need to know
    /// handle switching vote snapshots to a proposal's start block
    uint256 useStartBlockFromPropId;
    /// configurable vote reason
    string reason;
  }

  /// The storage slot index containing nouns token balance mappings
  bytes32 public balanceSlotIdx = SLOT_INDEX_TOKEN_BALANCE;

  /// The storage slot index containing nouns delegate mappings
  bytes32 public delegateSlotIdx = SLOT_INDEX_DELEGATE;

  /// The config of this module
  Config internal _cfg;

  modifier isNotLocked() {
    _isNotLocked();
    _;
  }

  /// Reverts if the module has an open lock
  function _isNotLocked() internal view virtual {
    if (Wallet(_cfg.base).hasActiveLock()) {
      revert ConfigModuleHasActiveLock();
    }
  }

  /// Management function to get this contracts config
  function getConfig() external view returns (Config memory) {
    return _cfg;
  }

  /// Management function to update the config post initialization
  function setConfig(Config memory _config) external onlyOwner isNotLocked {
    // fees cannot be updated after initialization
    _config.feeBPS = _cfg.feeBPS;
    _config.feeRecipient = _cfg.feeRecipient;

    _cfg = _validateConfig(_config);
    emit ConfigChanged();
  }

  function setTipAndRefund(uint256 _tip, uint256 _maxBaseFeeRefund) external onlyOwner isNotLocked {
    _cfg.tip = _tip;
    _cfg.maxBaseFeeRefund = _maxBaseFeeRefund;
    emit ConfigChanged();
  }

  /// Management function to set token storage slots for proof verification
  function setSlots(uint256 balanceSlot, uint256 delegateSlot) external onlyOwner isNotLocked {
    balanceSlotIdx = bytes32(balanceSlot);
    delegateSlotIdx = bytes32(delegateSlot);
    emit SlotsUpdated(balanceSlotIdx, delegateSlotIdx);
  }

  /// Management function to update dependency addresses
  function setAddresses(address _reliquary, address _delegateCash, address _factValidator)
    external
    onlyOwner
    isNotLocked
  {
    require(_reliquary != address(0), "invalid reliquary addr");
    require(_delegateCash != address(0), "invalid delegate cash registry addr");
    require(_factValidator != address(0), "invalid fact validator addr");

    _cfg.reliquary = _reliquary;
    _cfg.dcash = _delegateCash;
    _cfg.factValidator = _factValidator;
    emit ConfigChanged();
  }

  /// Management function to set a max required prover version
  /// Protects the pool in the event that relic is compromised
  function setMaxProverVersion(uint256 _version) external onlyOwner {
    _cfg.maxProverVersion = _version;
    emit ConfigChanged();
  }

  /// Management function to set the prop id for when we should start using
  /// proposal start blocks for voting snapshots
  function setUseStartBlockFromPropId(uint256 _pId) external onlyOwner {
    _cfg.useStartBlockFromPropId = _pId;
    emit ConfigChanged();
  }

  /// Management function to set vote reason
  function setReason(string calldata _reason) external onlyOwner {
    _cfg.reason = _reason;
    emit ConfigChanged();
  }

  /// Management function to reduce fees
  function setFeeBPS(uint256 _feeBPS) external onlyOwner {
    require(_feeBPS < _cfg.feeBPS, "fee cannot be increased");
    _cfg.feeBPS = _feeBPS;
    emit ConfigChanged();
  }

  /// Management function to update auction reserve price
  function setReservePrice(uint256 _reservePrice) external onlyOwner {
    require(_reservePrice > 0, "reserve cannot be 0");
    _cfg.reservePrice = _reservePrice;
    emit ConfigChanged();
  }

  /// Management function to update castWindow
  function setCastWindow(uint256 _castWindow) external onlyOwner {
    require(_castWindow > 0, "cast window 0");
    _cfg.castWindow = _castWindow;
    emit ConfigChanged();
  }

  /// Validates that the config is set properly and sets default values if necessary
  function _validateConfig(Config memory _config) internal pure returns (Config memory) {
    if (_config.castWindow == 0) {
      revert GovernancePool.InitCastWindowNotSet();
    }

    if (_config.externalDAO == address(0)) {
      revert GovernancePool.InitExternalDAONotSet();
    }

    if (_config.externalToken == address(0)) {
      revert GovernancePool.InitExternalTokenNotSet();
    }

    if (_config.feeBPS > 0 && _config.feeRecipient == address(0)) {
      revert GovernancePool.InitFeeRecipientNotSet();
    }

    if (_config.base == address(0)) {
      revert GovernancePool.InitBaseWalletNotSet();
    }

    // default reserve price
    if (_config.reservePrice == 0) {
      _config.reservePrice = 1 wei;
    }

    // default cast wait blocks 5 ~= 1 minute
    if (_config.castWaitBlocks == 0) {
      _config.castWaitBlocks = 5;
    }

    return _config;
  }
}