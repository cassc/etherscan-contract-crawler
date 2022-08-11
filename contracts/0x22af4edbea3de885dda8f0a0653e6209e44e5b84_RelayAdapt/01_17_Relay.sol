// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IWBase } from "./IWBase.sol";
import { RailgunLogic, Transaction, CommitmentPreimage, TokenData, TokenType } from "../../logic/RailgunLogic.sol";

/**
 * @title Relay Adapt
 * @author Railgun Contributors
 * @notice Multicall adapt contract for Railgun with relayer support
 */

contract RelayAdapt {
  using SafeERC20 for IERC20;

  // Snark bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
  // Use 0x000000000000000000000000000000000000dEaD as an alternative
  address constant public VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

  struct Call {
    address to;
    bytes data;
    uint256 value;
  }

  struct Result {
    bool success;
    string returnData;
  }

  event CallResult(Result[] callResults);

  // External contract addresses
  RailgunLogic public railgun;
  IWBase public wbase;

  /**
   * @notice only allows self calls to these contracts
   */
  modifier onlySelf() {
    require(msg.sender == address(this), "RelayAdapt: External call to onlySelf function");
    _;
  }

  /**
   * @notice Sets Railgun contract and wbase address
   */
  constructor(RailgunLogic _railgun, IWBase _wbase) {
    railgun = _railgun;
    wbase = _wbase;
  }

  /**
   * @notice Gets adapt params for Railgun batch
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _additionalData - Additional data
   * @return adapt params
   */
  function getAdaptParams(
    Transaction[] calldata _transactions,
    bytes memory _additionalData
  ) public pure returns (bytes32) {
    uint256[] memory firstNullifiers = new uint256[](_transactions.length);

    for (uint256 i = 0; i < _transactions.length; i++) {
      // Only need first nullifier
      firstNullifiers[i] = _transactions[i].nullifiers[0];
    }

    return keccak256(
      abi.encode(
        firstNullifiers,
        _transactions.length,
        _additionalData
      )
    );
  }

  /**
   * @notice Executes a batch of Railgun transactions
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _additionalData - Additional data
   * Should be random value if called directly
   * If called via multicall sub-call this can be extracted and submitted standalone
   * Be aware of the dangers of this before doing so!
   */
  function railgunBatch(
    Transaction[] calldata _transactions,
    bytes memory _additionalData
  ) public {
    bytes32 expectedAdaptParameters = getAdaptParams(_transactions, _additionalData);

    // Loop through each transaction and ensure adaptID parameters match
    for(uint256 i = 0; i < _transactions.length; i++) {
      require(
        _transactions[i].boundParams.adaptParams == expectedAdaptParameters
        // solhint-disable-next-line avoid-tx-origin
        || tx.origin == VERIFICATION_BYPASS,
        "GeneralAdapt: AdaptID Parameters Mismatch"
      );
    }

    // Execute railgun transactions
    railgun.transact(_transactions);
  }

  /**
   * @notice Executes a batch of Railgun deposits
   * @param _deposits - Tokens to deposit
   * @param _encryptedRandom - Encrypted random value for deposits
   * @param _npk - note public key to deposit to
   */
  function deposit(
    TokenData[] calldata _deposits,
    uint256[2] calldata _encryptedRandom,
    uint256 _npk
  ) external onlySelf {
    // Loop through each token specified for deposit and deposit our total balance
    // Due to a quirk with the USDT token contract this will fail if it's approval is
    // non-0 (https://github.com/Uniswap/interface/issues/1034), to ensure that your
    // transaction always succeeds when dealing with USDT/similar tokens make sure the last
    // call in your calls is a call to the token contract with an approval of 0
    CommitmentPreimage[] memory commitmentPreimages = new CommitmentPreimage[](_deposits.length);
    uint256 numValidTokens = 0;

    for (uint256 i = 0; i < _deposits.length; i++) {
      if (_deposits[i].tokenType == TokenType.ERC20) {
        IERC20 token = IERC20(_deposits[i].tokenAddress);

        // Fetch balance
        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
          numValidTokens += 1;

          // Approve the balance for deposit
          token.safeApprove(
            address(railgun),
            balance
          );

          // Push to deposits arrays
          commitmentPreimages[i] = CommitmentPreimage({
            npk: _npk,
            value: uint120(balance),
            token: _deposits[i]
          });
        }
      } else if (_deposits[i].tokenType == TokenType.ERC721) {
        // ERC721 token
        revert("GeneralAdapt: ERC721 not yet supported");
      } else if (_deposits[i].tokenType == TokenType.ERC1155) {
        // ERC1155 token
        revert("GeneralAdapt: ERC1155 not yet supported");
      } else {
        // Invalid token type, revert
        revert("GeneralAdapt: Unknown token type");
      }
    }

    if (numValidTokens == 0) {
      return;
    }

    // Filter commitmentPreImages for != 0 (remove 0 balance tokens).
    CommitmentPreimage[] memory filteredCommitmentPreimages = new CommitmentPreimage[](numValidTokens);
    uint256[2][] memory filteredEncryptedRandom = new uint256[2][](numValidTokens);

    uint256 filterIndex = 0;
    for (uint256 i = 0; i < numValidTokens; i++) {
      while (commitmentPreimages[filterIndex].value == 0) {
        filterIndex += 1;
      }
      filteredCommitmentPreimages[i] = commitmentPreimages[filterIndex];
      filteredEncryptedRandom[i] = _encryptedRandom;
      filterIndex += 1;
    }

    // Deposit back to Railgun
    railgun.generateDeposit(filteredCommitmentPreimages, filteredEncryptedRandom);
  }

  /**
   * @notice Sends tokens to particular address
   * @param _tokens - tokens to send (0x0 - ERC20 is eth)
   * @param _to - ETH address to send to
   */
   function send(
    TokenData[] calldata _tokens,
    address _to
  ) external onlySelf {
    // Loop through each token specified for deposit and deposit our total balance
    // Due to a quirk with the USDT token contract this will fail if it's approval is
    // non-0 (https://github.com/Uniswap/interface/issues/1034), to ensure that your
    // transaction always succeeds when dealing with USDT/similar tokens make sure the last
    // call in your calls is a call to the token contract with an approval of 0
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i].tokenType == TokenType.ERC20) {
        // ERC20 token
        IERC20 token = IERC20(_tokens[i].tokenAddress);

        if (address(token) == address(0x0)) {
          // Fetch ETH balance
          uint256 balance = address(this).balance;

          if (balance > 0) {
            // Send ETH
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent,) = _to.call{value: balance}("");
            require(sent, "Failed to send Ether");
          }
        } else {
          // Fetch balance
          uint256 balance = token.balanceOf(address(this));

          if (balance > 0) {
            // Send all to address
            token.safeTransfer(_to, balance);
          }
        }
      } else if (_tokens[i].tokenType == TokenType.ERC721) {
        // ERC721 token
        revert("RailgunLogic: ERC721 not yet supported");
      } else if (_tokens[i].tokenType == TokenType.ERC1155) {
        // ERC1155 token
        revert("RailgunLogic: ERC1155 not yet supported");
      } else {
        // Invalid token type, revert
        revert("RailgunLogic: Unknown token type");
      }
    }
  }

  /**
   * @notice Wraps all base tokens in contract
   */
  function wrapAllBase() external onlySelf {
    // Fetch ETH balance
    uint256 balance = address(this).balance;

    // Wrap
    wbase.deposit{value: balance}();
  }

  /**
   * @notice Unwraps all wrapped base tokens in contract
   */
  function unwrapAllBase() external onlySelf {
    // Fetch ETH balance
    uint256 balance = wbase.balanceOf(address(this));

    // Unwrap
    wbase.withdraw(balance);
  }

  /**
   * @notice Executes multicall batch
   * @param _requireSuccess - Whether transaction should throw on call failure
   * @param _calls - multicall array
   */
  function multicall(
    bool _requireSuccess,
    Call[] calldata _calls
  ) internal {
    // Initialize returnData array
    Result[] memory returnData = new Result[](_calls.length);

    // Loop through each call
    for(uint256 i = 0; i < _calls.length; i++) {
      // Retrieve call
      Call calldata call = _calls[i];

      // Execute call
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory ret) = call.to.call{value: call.value, gas: gasleft()}(call.data);

      // Add call result to returnData
      returnData[i] = Result(success, string(ret));

      if (success) {
        continue;
      }

      bool isInternalCall = call.to == address(this);
      bool requireSuccess = _requireSuccess || isInternalCall;

      // If requireSuccess is true, throw on failure
      if (requireSuccess) {
        emit CallResult(returnData);
        revert(string.concat("GeneralAdapt Call Failed:", string(ret)));
      }
    }

    emit CallResult(returnData);
  }

  /**
   * @notice Convenience function to get the adapt params value for a given set of transactions
   * and calls
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _random - Random value (shouldn't be reused if resubmitting the same transaction
   * through another relayer or resubmitting on failed transaction - the same nullifier:random
   * should never be reused)
   * @param _minGas - minimum amount of gas to be supplied to transaction
   * @param _requireSuccess - Whether transaction should throw on multicall failure
   * @param _calls - multicall
   */
  function getRelayAdaptParams(
    Transaction[] calldata _transactions,
    uint256 _random,
    bool _requireSuccess,
    uint256 _minGas,
    Call[] calldata _calls
  ) external pure returns (bytes32) {
    // Convenience function to get the expected adaptID parameters value for global
    bytes memory additionalData = abi.encode(
      _random,
      _requireSuccess,
      _minGas,
      _calls
    );

    // Return adapt params value
    return getAdaptParams(_transactions, additionalData);
  }

  /**
   * @notice Executes a batch of Railgun transactions followed by a multicall
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _random - Random value (shouldn't be reused if resubmitting the same transaction
   * through another relayer or resubmitting on failed transaction - the same nullifier:random
   * should never be reused)
   * @param _requireSuccess - Whether transaction should throw on multicall failure
   * @param _minGas - minimum amount of gas to be supplied to transaction
   * @param _calls - multicall
   */
  function relay(
    Transaction[] calldata _transactions,
    uint256 _random,
    bool _requireSuccess,
    uint256 _minGas,
    Call[] calldata _calls
  ) external payable {
    require(gasleft() > _minGas, "Not enough gas supplied");

    if (_transactions.length > 0) {
      // Calculate additionalData parameter for adaptID parameters
      bytes memory additionalData = abi.encode(
        _random,
        _requireSuccess,
        _minGas,
        _calls
      );

      // Executes railgun batch
      railgunBatch(_transactions, additionalData);
    }

    // Execute multicalls
    multicall(_requireSuccess, _calls);

    // To execute a multicall and deposit or send the resulting tokens, encode a call to the relevant function on this
    // contract at the end of your calls array.
  }

  // Allow WBASE contract unwrapping to pay us
  // solhint-disable-next-line avoid-tx-origin no-empty-blocks
  receive() external payable {}
}