// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IWBase } from "./IWBase.sol";
import { VERIFICATION_BYPASS, Transaction, ShieldRequest, ShieldCiphertext, CommitmentPreimage, TokenData, TokenType } from "../logic/Globals.sol";
import { RailgunSmartWallet } from "../logic/RailgunSmartWallet.sol";

/**
 * @title Relay Adapt
 * @author Railgun Contributors
 * @notice Multicall adapt contract for Railgun with relayer support
 */

contract RelayAdapt {
  using SafeERC20 for IERC20;

  // Set to true if contract is executing
  bool private isExecuting = false;

  struct Call {
    address to;
    bytes data;
    uint256 value;
  }

  struct ActionData {
    bytes31 random; // Random value (shouldn't be reused if resubmitting the same transaction
    // through another relayer or resubmitting on failed transaction - i.e. the same
    // nullifier:random combination should never be reused)
    bool requireSuccess; // If the transaction should require success on all sub calls
    uint256 minGasLimit; // Minimum gas that should be supplied to this transaction
    Call[] calls; // Array of calls to execute during transaction
  }

  struct TokenTransfer {
    TokenData token;
    address to;
    uint256 value; // 0 to send entire balance
  }

  // Custom errors
  error CallFailed(uint256 callIndex, bytes revertReason);

  // Events
  event CallError(uint256 callIndex, bytes revertReason);

  // External contract addresses
  RailgunSmartWallet public railgun;
  IWBase public wBase;

  /**
   * @notice only allows self calls to these contracts if contract is executing
   */
  modifier onlySelfIfExecuting() {
    require(
      !isExecuting || msg.sender == address(this),
      "RelayAdapt: External call to onlySelf function"
    );
    isExecuting = true;
    _;
    isExecuting = false;
  }

  /**
   * @notice Sets Railgun contract and wBase address
   */
  constructor(RailgunSmartWallet _railgun, IWBase _wBase) {
    railgun = _railgun;
    wBase = _wBase;
  }

  /**
   * @notice Executes a batch of Railgun shields
   * @param _shieldRequests - Tokens to shield
   */
  function shield(ShieldRequest[] calldata _shieldRequests) external onlySelfIfExecuting {
    // Loop through each token specified for shield and shield requested balance

    uint256 numValidTokens = 0;
    uint120[] memory values = new uint120[](_shieldRequests.length);

    for (uint256 i = 0; i < _shieldRequests.length; i += 1) {
      if (_shieldRequests[i].preimage.token.tokenType == TokenType.ERC20) {
        // ERC20
        IERC20 token = IERC20(_shieldRequests[i].preimage.token.tokenAddress);

        if (_shieldRequests[i].preimage.value == 0) {
          // If balance is 0 then shield the entire token balance
          // Set values to balance of this contract, capped at
          // type(uint120).max to fit Railgun's note max value
          values[i] = uint120(token.balanceOf(address(this)));
        } else {
          values[i] = _shieldRequests[i].preimage.value;
        }

        // Approve the balance for shield
        // Set to 0 first for the following reasons:
        // https://github.com/Uniswap/interface/issues/1034
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        token.safeApprove(address(railgun), 0);
        token.safeApprove(address(railgun), values[i]);

        // Increment number of valid tokens if we have a balance to deposit
        if (values[i] > 0) {
          numValidTokens += 1;
        }
      } else if (_shieldRequests[i].preimage.token.tokenType == TokenType.ERC721) {
        // ERC721 token
        IERC721 token = IERC721(_shieldRequests[i].preimage.token.tokenAddress);

        // Approve NFT for shield
        token.approve(address(railgun), _shieldRequests[i].preimage.token.tokenSubID);

        // Set value to 1
        values[i] = 1;

        // Increment number of valid tokens
        numValidTokens += 1;
      } else {
        // ERC1155 token
        revert("RelayAdapt: ERC1155 not yet supported");
      }
    }

    // Noop if all tokens requested to shield are 0 balance
    if (numValidTokens == 0) {
      return;
    }

    // Filter commitmentPreImages for != 0 (remove 0 balance tokens).

    // Initialize filtered array for length valid tokens
    ShieldRequest[] memory filteredShieldRequests = new ShieldRequest[](numValidTokens);
    uint256 filteredIndex = 0;

    // Loop through shields and push non-0 values to filtered array
    for (uint256 i = 0; i < _shieldRequests.length; i += 1) {
      if (values[i] != 0) {
        // Push to filtered array
        filteredShieldRequests[filteredIndex] = _shieldRequests[i];

        // Set value to adjusted value (if adjusted)
        filteredShieldRequests[filteredIndex].preimage.value = values[i];

        // Increment index of filtered arrays
        filteredIndex += 1;
      }
    }

    // Shield to railgun
    railgun.shield(filteredShieldRequests);
  }

  /**
   * @notice Sends tokens to particular address
   * @param _transfers - tokens to send (0x0 - ERC20 is base)
   */
  function transfer(TokenTransfer[] calldata _transfers) external onlySelfIfExecuting {
    for (uint256 i = 0; i < _transfers.length; i += 1) {
      if (
        _transfers[i].token.tokenType == TokenType.ERC20 &&
        _transfers[i].token.tokenAddress == address(0)
      ) {
        // BASE
        // Fetch balance
        uint256 amount = _transfers[i].value == 0 ? address(this).balance : _transfers[i].value;

        // Transfer base tokens
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _transfers[i].to.call{ value: amount }("");

        // Check transfer succeeded
        require(success, "RelayAdapt: ETH transfer failed");
      } else if (_transfers[i].token.tokenType == TokenType.ERC20) {
        // ERC20
        IERC20 token = IERC20(_transfers[i].token.tokenAddress);

        // Fetch balance
        uint256 amount = _transfers[i].value == 0
          ? token.balanceOf(address(this))
          : _transfers[i].value;

        // Transfer token
        token.safeTransfer(_transfers[i].to, amount);
      } else if (_transfers[i].token.tokenType == TokenType.ERC721) {
        // ERC721 token
        IERC721 token = IERC721(_transfers[i].token.tokenAddress);

        // Transfer token
        token.transferFrom(address(this), _transfers[i].to, _transfers[i].token.tokenSubID);
      } else {
        // ERC1155 token
        revert("RelayAdapt: ERC1155 not yet supported");
      }
    }
  }

  /**
   * @notice Wraps base tokens in contract
   * @param _amount - amount to wrap (0 = wrap all)
   */
  function wrapBase(uint256 _amount) external onlySelfIfExecuting {
    // Fetch balance
    uint256 balance = _amount == 0 ? address(this).balance : _amount;

    // Wrap
    wBase.deposit{ value: balance }();
  }

  /**
   * @notice Unwraps wrapped base tokens in contract
   * @param _amount - amount to unwrap (0 = unwrap all)
   */
  function unwrapBase(uint256 _amount) external onlySelfIfExecuting {
    // Fetch balance
    uint256 balance = _amount == 0 ? wBase.balanceOf(address(this)) : _amount;

    // Unwrap
    wBase.withdraw(balance);
  }

  /**
   * @notice Executes multicall batch
   * @param _requireSuccess - Whether transaction should throw on call failure
   * @param _calls - multicall array
   */
  function _multicall(bool _requireSuccess, Call[] calldata _calls) internal {
    // Loop through each call
    for (uint256 i = 0; i < _calls.length; i += 1) {
      // Retrieve call
      Call calldata call = _calls[i];

      // Execute call
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returned) = call.to.call{ value: call.value }(call.data);

      if (success) {
        continue;
      }

      bool isInternalCall = call.to == address(this);
      bool requireSuccess = _requireSuccess || isInternalCall;

      // If requireSuccess is true, throw on failure
      if (requireSuccess) {
        revert CallFailed(i, returned);
      } else {
        emit CallError(i, returned);
      }
    }
  }

  /**
   * @notice Executes multicall batch
   * @param _requireSuccess - Whether transaction should throw on call failure
   * @param _calls - multicall array
   */
  function multicall(bool _requireSuccess, Call[] calldata _calls) external payable onlySelfIfExecuting {
    _multicall(_requireSuccess, _calls);
  }

  /**
   * @notice Get adapt params value for a given set of transactions
   * and action data
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _actionData - Actions to take in transaction
   */
  function getAdaptParams(Transaction[] calldata _transactions, ActionData calldata _actionData)
    public
    pure
    returns (bytes32)
  {
    // Get 2D array of nullifiers of transaction
    bytes32[][] memory nullifiers = new bytes32[][](_transactions.length);

    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      nullifiers[transactionIter] = _transactions[transactionIter].nullifiers;
    }

    // Return keccak hash of parameters
    return keccak256(abi.encode(nullifiers, _transactions.length, _actionData));
  }

  /**
   * @notice Executes a batch of Railgun transactions followed by a multicall
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _actionData - Actions to take in transaction
   */
  function relay(Transaction[] calldata _transactions, ActionData calldata _actionData)
    external
    payable
    onlySelfIfExecuting
  {
    // ~55000 gas needs to be added above the minGasLimit value as this amount will be
    // consumed by the time we reach this check
    require(gasleft() > _actionData.minGasLimit, "RelayAdapt: Not enough gas supplied");

    // Get expected adapt parameters
    bytes32 expectedAdaptParameters = getAdaptParams(_transactions, _actionData);

    // Loop through each transaction and ensure adapt parameters match
    for (uint256 i = 0; i < _transactions.length; i += 1) {
      require(
        _transactions[i].boundParams.adaptParams == expectedAdaptParameters ||
          // solhint-disable-next-line avoid-tx-origin
          tx.origin == VERIFICATION_BYPASS,
        "RelayAdapt: AdaptID Parameters Mismatch"
      );
    }

    // Execute railgun transactions
    railgun.transact(_transactions);

    // Execute multicall
    _multicall(_actionData.requireSuccess, _actionData.calls);

    // To execute a multicall and shield or send the resulting tokens, encode a call to the relevant function on this
    // contract at the end of your calls array.
  }

  // Allow wBase contract unwrapping to pay us
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}