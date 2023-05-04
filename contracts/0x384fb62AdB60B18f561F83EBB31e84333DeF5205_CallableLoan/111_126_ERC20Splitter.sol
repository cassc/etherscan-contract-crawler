// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "openzeppelin-contracts-0-8-x/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-0-8-x/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-0-8-x/utils/Address.sol";

import {Context} from "../../../cake/Context.sol";
import {Base} from "../../../cake/Base.sol";
import {PausableUpgradeable} from "../../../cake/Pausable.sol";
import {IERC20Splitter} from "../../../interfaces/IERC20Splitter.sol";

using Address for address;
using SafeERC20 for IERC20;

interface IERC20SplitterReceiver {
  function onReceive(uint256 amount) external returns (bytes4 retval);
}

/// @title ERC20Splitter
/// @author landakram
/// @notice Splits the ERC20 balance of this contract amongst a list of payees.
///   Unlike similar splitter contracts, all shares of the balance are distributed
///   in a single `distribute` transaction. If a payee is a smart contract implementing
///   `IERC20SplitterReceiver`, then its `onReceive` handler function will be called
///   after it receives its share.
contract ERC20Splitter is IERC20Splitter, Base, PausableUpgradeable {
  error LengthMismatch();
  error InvalidReceiver();
  error IntraBlockDistribution();

  event Distributed(uint256 total);
  event PayeeAdded(address indexed payee, uint256 share);

  /// @notice The total number of shares in the splitter. A payee's proportion
  ///   of the split can be calculated as its share / totalShares.
  uint256 public totalShares;

  /// @notice A list of payees
  address[] public payees;

  /// @notice Payee shares
  mapping(address => uint256) public shares;

  /// @notice The ERC20 that is distributed to payees
  IERC20 public immutable erc20;

  /// @notice The block.timestamp when `distribute` was last called
  uint256 public lastDistributionAt;

  constructor(Context _context, IERC20 _erc20) Base(_context) {
    erc20 = _erc20;
  }

  function initialize() external initializer {
    __Pausable_init_unchained();
  }

  function pendingDistributionFor(address payee) external view returns (uint256) {
    return (erc20.balanceOf(address(this)) * shares[payee]) / totalShares;
  }

  /// @notice Distribute the current balance to payees. If a payee is a smart contract
  ///   implementing `IERC20SplitterReceiver`, then its `onReceive` handler function will
  ///   be called after it receives its share.
  function distribute() external whenNotPaused {
    if (lastDistributionAt == block.timestamp) revert IntraBlockDistribution();

    lastDistributionAt = block.timestamp;

    uint256 totalToDistribute = erc20.balanceOf(address(this));

    for (uint256 i = 0; i < payees.length; i++) {
      address payee = payees[i];
      uint256 share = shares[payee];

      // Due to integer division, this could result in some dust being left over in the
      // contract. This is acceptable as the dust will be included in the next distribution.
      uint256 owedToPayee = (totalToDistribute * share) / totalShares;
      if (owedToPayee > 0) {
        erc20.safeTransfer(payee, owedToPayee);
      }

      if (payee.isContract()) {
        // Call this even if there is nothing owed to payee. Some recipients may still need
        // to account for the event.
        triggerOnReceive(payee, owedToPayee);
      }
    }

    emit Distributed(totalToDistribute);
  }

  function triggerOnReceive(address payee, uint256 amount) internal {
    try IERC20SplitterReceiver(payee).onReceive(amount) returns (bytes4 retval) {
      if (retval != IERC20SplitterReceiver.onReceive.selector) revert InvalidReceiver();
    } catch (bytes memory reason) {
      // A zero-length reason means the payee does not implement IERC20SplitterReceiver.
      // In that case, just continue.
      if (reason.length > 0) {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /// @notice Replace all current payees with a new set of payees and shares
  /// @param _payees An array of addresses to receive distributions
  /// @param _shares An array of shares (ordered by `_payees`) to use for distributions
  function replacePayees(
    address[] calldata _payees,
    uint256[] calldata _shares
  ) external onlyAdmin {
    delete payees;
    _setUpPayees(_payees, _shares);
  }

  function _setUpPayees(address[] calldata _payees, uint256[] calldata _shares) internal {
    if (_payees.length != _shares.length) revert LengthMismatch();

    totalShares = 0;
    payees = _payees;

    for (uint256 i = 0; i < _shares.length; i++) {
      address payee = _payees[i];
      uint256 share = _shares[i];
      shares[payee] = share;
      totalShares += share;
      emit PayeeAdded({payee: payee, share: share});
    }
  }
}