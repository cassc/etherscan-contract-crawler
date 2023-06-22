// SPDX-License-Identifier: GPL-3.0

import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Motivator } from "src/incentives/Motivator.sol";
import {
  ModuleConfig,
  SLOT_INDEX_TOKEN_BALANCE,
  SLOT_INDEX_DELEGATE
} from "src/module/governance-pool/ModuleConfig.sol";
import { Wallet } from "src/wallet/Wallet.sol";
import { Validator } from "src/module/governance-pool/FactValidator.sol";
import { IReliquary } from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import { IDelegationRegistry } from "delegate-cash/IDelegationRegistry.sol";
import { IBatchProver } from "relic-sdk/packages/contracts/interfaces/IBatchProver.sol";
import { Fact, FactSignature } from "relic-sdk/packages/contracts/lib/Facts.sol";
import { Storage } from "relic-sdk/packages/contracts/lib/Storage.sol";
import { FactSigs } from "relic-sdk/packages/contracts/lib/FactSigs.sol";
import { PausableUpgradeable } from "openzeppelin-upgradeable/security/PausableUpgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { NounsDAOStorageV2 } from "nouns-contracts/governance/NounsDAOInterfaces.sol";

pragma solidity ^0.8.19;

/// Wrapper for NounsDAOStorageV2 functionality
interface NounsGovernanceV2 {
  function castRefundableVoteWithReason(uint256, uint8, string calldata) external;
  function proposals(uint256) external view returns (NounsDAOStorageV2.ProposalCondensed memory);
  function state(uint256) external view returns (uint256);
}

/// Wrapper for Nouns token governance functionality
interface NounsToken {
  function getPriorVotes(address, uint256) external view returns (uint96);
}

// This module auctions off the collective voting power delegated to the highest
// bidder. Delegators can withdraw proceeds in proportion to their share of the
// pool for each prop once a vote has been cast and the voting period ends.
contract NounsPool is PausableUpgradeable, Motivator, GovernancePool, ModuleConfig {
  /// The name of this contract
  string public constant name = "Federation Nouns Governance Pool v0.1";

  /// The maximum uint256 value. Necessary to track this for overflow reasons
  /// fee switch as bps
  uint256 internal constant MAX_INT = type(uint256).max;

  /// The active bid on each proposal
  mapping(uint256 => Bid) internal bids;

  /// The delegators that have withdrawn proceeds from a bid
  mapping(uint256 => mapping(address => bool)) internal withdrawals;

  /// Do not leave implementation uninitialized
  constructor() {
    _disableInitializers();
  }

  /// Module initialization; Can only be called once
  function init(bytes calldata _data) external payable initializer {
    __Ownable_init();
    __Pausable_init();

    _cfg = _validateConfig(abi.decode(_data, (Config)));

    balanceSlotIdx = SLOT_INDEX_TOKEN_BALANCE;
    delegateSlotIdx = SLOT_INDEX_DELEGATE;

    if (msg.sender != _cfg.base) {
      _transferOwnership(_cfg.base);
    }
  }

  /// Submit a bid for a proposal vote
  function bid(uint256 _pId, uint256 _support) external payable {
    if (_support > 2) {
      revert BidInvalidSupport();
    }

    if (msg.value < _cfg.reservePrice) {
      revert BidReserveNotMet();
    }

    // we calc fee shares using bps; we need to ensure that
    // the bid amount can never overflow any of our math calcs
    if (msg.value >= MAX_INT / 10000) {
      revert BidMaxBidExceeded();
    }

    // only allow bidding on a prop if voting is active
    if (!_active(_pId)) {
      revert BidProposalNotActive();
    }

    Bid storage b = bids[_pId];
    if (b.executed) {
      revert BidVoteAlreadyCast();
    }

    address lastBidder = b.bidder;
    uint256 lastAmount = b.amount;
    if (msg.value < this.minBidAmount(_pId)) {
      revert BidTooLow();
    }

    // prevent a new auction from starting if the module is paused
    if (paused() && lastAmount == 0) {
      revert BidModulePaused();
    }

    // if we are in the cast window and have a winning bid, the auction has ended and the
    // vote can be cast. auctions are not extended so that we can always guarantee a vote
    // is cast before the external proposal voting period ends
    if (block.number + _cfg.castWindow > b.endBlock) {
      if (lastAmount >= _cfg.reservePrice) {
        revert BidAuctionEnded();
      }
    }

    b.amount = msg.value;
    b.bidder = msg.sender;
    b.support = _support;
    b.bidBlock = block.number;
    b.remainingAmount = b.amount;

    NounsDAOStorageV2.ProposalCondensed memory eProp =
      NounsGovernanceV2(_cfg.externalDAO).proposals(_pId);
    b.creationBlock = eProp.creationBlock;
    b.startBlock = eProp.startBlock;
    b.endBlock = eProp.endBlock;

    // request base lock so that this module cannot be disabled while a bid is active
    // requestLock works on a rolling basis so this module will always be allowed
    // to cast votes if it has an active bid
    Wallet(_cfg.base).requestLock((b.endBlock + 1) - block.number);

    // refund any previous bid on this prop
    if (lastBidder != address(0)) {
      SafeTransferLib.forceSafeTransferETH(lastBidder, lastAmount);
    }

    emit BidPlaced(_cfg.externalDAO, _pId, _support, b.amount, msg.sender);
  }

  /// Refunds a bid if a proposal is canceled, vetoed, or votes could not be cast
  function claimRefund(uint256 _pId) external {
    Bid storage b = bids[_pId];

    if (msg.sender != b.bidder) {
      revert ClaimOnlyBidder();
    }

    if (b.refunded) {
      revert ClaimAlreadyRefunded();
    }

    if (_refundable(_pId, b.executed)) {
      b.refunded = true;
      SafeTransferLib.forceSafeTransferETH(b.bidder, b.remainingAmount);
      emit RefundClaimed(_cfg.externalDAO, _pId, b.remainingAmount, msg.sender);
      return;
    }

    revert ClaimNotRefundable();
  }

  /// Casts a vote on an external proposal. A tip is awarded to the caller
  function castVote(uint256 _pId) external {
    Bid storage b = bids[_pId];
    if (b.amount == 0) {
      revert CastVoteBidDoesNotExist();
    }

    if (block.number + _cfg.castWindow < b.endBlock) {
      revert CastVoteNotInWindow();
    }

    // no atomic bid / casts
    if (block.number < b.bidBlock + _cfg.castWaitBlocks) {
      revert CastVoteMustWait();
    }

    if (b.executed) {
      revert CastVoteAlreadyCast();
    }

    b.executed = true;
    b.remainingVotes =
      NounsToken(_cfg.externalToken).getPriorVotes(_cfg.base, _voteSnapshotBlock(b, _pId));

    if (b.remainingVotes == 0) {
      revert CastVoteNoDelegations();
    }

    // cast vwr through base wallet, Nouns refunds gas
    bytes4 s = NounsGovernanceV2.castRefundableVoteWithReason.selector;
    bytes memory callData = abi.encodeWithSelector(s, _pId, uint8(b.support), _cfg.reason);
    Wallet(_cfg.base).execute(_cfg.externalDAO, 0, callData);

    // base tx refund covers validation checks performed in this fn before
    // votes were cast
    uint256 startGas = gasleft();
    emit VoteCast(_cfg.externalDAO, _pId, b.support, b.amount, b.bidder);

    // protocol fee switch
    uint256 fee;
    if (_cfg.feeBPS > 0) {
      fee = _bpsToUint(_cfg.feeBPS, b.amount);
      b.remainingAmount -= fee;
    }

    // deduct gas refund and tip from bid proceeds to incentivize casting of a vote
    // cap refund + tip by the bid amount so that we can never refund more than the
    // highest bid - any fees applied
    uint256 refund =
      _gasRefundWithTipAndCap(startGas, b.remainingAmount, _cfg.maxBaseFeeRefund, _cfg.tip);

    b.remainingAmount -= refund;

    if (fee > 0) {
      SafeTransferLib.forceSafeTransferETH(_cfg.feeRecipient, fee);
      emit ProtocolFeeApplied(_cfg.feeRecipient, fee);
    }

    SafeTransferLib.forceSafeTransferETH(tx.origin, refund);
    emit GasRefundWithTip(tx.origin, refund, _cfg.tip);
  }

  /// Withdraw proceeds from a proposal in proportion to voting weight delegated
  function withdraw(
    address _tokenOwner,
    address _prover,
    uint256[] calldata _pIds,
    uint256[] calldata _fee,
    bytes[] calldata _proofBatches
  ) external payable returns (uint256) {
    // verify prover version is a valid relic contract
    IReliquary reliq = IReliquary(_cfg.reliquary);
    IReliquary.ProverInfo memory p = reliq.provers(_prover);
    reliq.checkProver(p);
    if (_cfg.maxProverVersion != 0) {
      if (p.version > _cfg.maxProverVersion) {
        revert WithdrawMaxProverVersion();
      }
    }

    // to withdraw, sender must have permission set in the delegate cash registry
    // or they must be the owner of the Nouns delegated to the base wallet
    if (msg.sender != _tokenOwner) {
      IDelegationRegistry dr = IDelegationRegistry(_cfg.dcash);
      bool isDelegate = dr.checkDelegateForContract(msg.sender, _tokenOwner, address(this));
      if (!isDelegate) {
        revert WithdrawDelegateOrOwnerOnly();
      }
    }

    // calc the slot for the balance and delegate of the token owner to ensure that
    // proofs cannot be spoofed
    bytes32 balanceSlot = Storage.mapElemSlot(balanceSlotIdx, _addressToBytes32(_tokenOwner));

    bytes32 delegateSlot = Storage.mapElemSlot(delegateSlotIdx, _addressToBytes32(_tokenOwner));

    // how many props to loop over
    uint256 len = _pIds.length;

    // keep track of total amount to withdraw
    uint256 withdrawAmount;

    for (uint256 i = 0; i < len;) {
      Bid storage b = bids[_pIds[i]];
      if (b.amount == 0) {
        revert WithdrawBidNotOffered();
      }

      if (_refundable(_pIds[i], b.executed)) {
        revert WithdrawBidRefunded();
      }

      if (!b.executed) {
        revert WithdrawVoteNotCast();
      }

      if (withdrawals[_pIds[i]][_tokenOwner]) {
        revert WithdrawAlreadyClaimed();
      }

      // only allow withdrawals after the voting period has ended
      if (_active(_pIds[i])) {
        revert WithdrawPropIsActive();
      }

      // prevent multiple withdrawals from the same user on this prop
      withdrawals[_pIds[i]][_tokenOwner] = true;

      // validate that proofs are correctly formatted (for the correct slot, block, and token address)
      Fact[] memory facts =
        IBatchProver(_prover).proveBatch{ value: _fee[i] }(_proofBatches[i], false);

      Validator v = Validator(_cfg.factValidator);
      if (!v.validate(facts[0], balanceSlot, _voteSnapshotBlock(b, _pIds[i]), _cfg.externalToken)) {
        revert WithdrawInvalidProof("balanceOf");
      }

      if (!v.validate(facts[1], delegateSlot, _voteSnapshotBlock(b, _pIds[i]), _cfg.externalToken))
      {
        revert WithdrawInvalidProof("delegate");
      }

      bytes memory slotBalanceData = facts[0].data;
      uint256 nounsBalanceVal = Storage.parseUint256(slotBalanceData);
      if (nounsBalanceVal == 0) {
        revert WithdrawNoBalanceAtPropStart();
      }

      // ensure that the owner had delegated their Nouns to the base wallet when voting
      // started on this proposal
      bytes memory slotDelegateData = facts[1].data;
      address nounsDelegateVal = Storage.parseAddress(slotDelegateData);
      if (nounsDelegateVal != _cfg.base) {
        revert WithdrawNoTokensDelegated();
      }

      uint256 ownerShare = (nounsBalanceVal * b.remainingAmount) / b.remainingVotes;
      withdrawAmount += ownerShare;

      b.remainingVotes -= nounsBalanceVal;
      b.remainingAmount -= withdrawAmount;

      unchecked {
        ++i;
      }
    }

    if (withdrawAmount > 0) {
      SafeTransferLib.forceSafeTransferETH(_tokenOwner, withdrawAmount);
      emit Withdraw(_cfg.externalDAO, _tokenOwner, _pIds, withdrawAmount);
    }

    return withdrawAmount;
  }

  /// Locks the contract to prevent bidding on new proposals
  function pause() external onlyOwner {
    _pause();
  }

  /// Unlocks the contract to allow bidding
  function unpause() external onlyOwner {
    _unpause();
  }

  /// Returns the latest bid for the given proposal
  function getBid(uint256 _pId) external view returns (Bid memory) {
    return bids[_pId];
  }

  /// Returns whether an account has made a withdrawal for a proposal
  function withdrawn(uint256 _pId, address _account) external view returns (bool) {
    return withdrawals[_pId][_account];
  }

  /// Returns the next minimum bid amount for a proposal
  function minBidAmount(uint256 _pid) external view returns (uint256) {
    Bid memory b = bids[_pid];
    if (b.amount == 0) {
      return _cfg.reservePrice;
    }

    return b.amount + ((b.amount * _cfg.minBidIncrementPercentage) / 100);
  }

  /// Helper that calculates percent of number using bps
  function _bpsToUint(uint256 bps, uint256 number) internal pure returns (uint256) {
    require(number < MAX_INT / 10000);
    require(bps <= 10000);

    return (number * bps) / 10000;
  }

  /// Helper that converts type address to bytes32
  function _addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  /// Helper that determines if a bid is eligible for a refund
  /// Canceled or vetoed proposals are always refundable.
  function _refundable(uint256 _pId, bool _voteCast) internal view returns (bool) {
    uint256 state = NounsGovernanceV2(_cfg.externalDAO).state(_pId);

    // canceled
    if (state == 2) {
      return true;
    }

    // vetoed
    if (state == 8) {
      return true;
    }

    // pending, active, or updatable states should never be refundable since
    // voting is either in progress or has not started
    // 0 == Pending, 1 == Active, 10 == Updatable
    if (state == 0 || state == 1 || state == 10) {
      return false;
    }

    // if votes were not cast against the proposal, it is refundable
    return !_voteCast;
  }

  /// Helper that determines whether to use startBlock or creationBlock for voting
  /// on proposals. This ensures that the module is compatible with future
  /// expected Nouns governance updates
  function _voteSnapshotBlock(Bid memory _b, uint256 _pId) internal view returns (uint256) {
    // default to using creation block
    if (_cfg.useStartBlockFromPropId == 0) {
      return _b.creationBlock;
    }

    if (_pId >= _cfg.useStartBlockFromPropId) {
      return _b.startBlock;
    }

    return _b.creationBlock;
  }

  /// Helper that determines if a proposal voting period is active
  function _active(uint256 _pId) internal view returns (bool) {
    return NounsGovernanceV2(_cfg.externalDAO).state(_pId) == 1;
  }
}