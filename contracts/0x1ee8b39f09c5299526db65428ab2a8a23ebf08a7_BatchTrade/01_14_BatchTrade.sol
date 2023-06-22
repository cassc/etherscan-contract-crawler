/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental "ABIEncoderV2";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IExchangeAdapter.sol";
import "./adapter/ZeroExExchangeAdapter.sol";

import "./ExchangeAdapterRegistry.sol";

/**
 * @title BatchTrade
 * @author 31Third
 *
 * Provides batch trading functionality
 */
contract BatchTrade is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  /*** ### Structs ### ***/

  // prettier-ignore
  struct Trade {
    string exchangeName;            // Name of the exchange the trade should be executed
    address from;                   // Address of the token to sell
    uint256 fromAmount;             // Amount of the token to sell
    address to;                     // Address of the token that will be received
    uint256 minToReceiveBeforeFees; // Minimal amount to receive
    bytes data;                     // Arbitrary call data which is sent to the exchange
    bytes signature;                // Signature to verify received trade data
  }

  // prettier-ignore
  struct BatchTradeConfig {
    bool checkFeelessWallets; // Determines if a check for feeless trading should be performed
    bool revertOnError;       // If true, batch trade reverts on error, otherwise execution just stops
  }

  /*** ### Events ### ***/

  event BatchTradeDeployed(
    address exchangeAdapterRegistry,
    address feeRecipient,
    uint16 feeBasisPoints,
    uint16 maxFeeBasisPoints,
    address tradeSigner
  );

  event FeeRecipientUpdated(
    address oldFeeRecipient,
    address newFeeRecipient
  );

  event FeeBasisPointsUpdated(
    uint16 oldFeeBasisPoints,
    uint16 newFeeBasisPoints
  );

  event MaxBasisPointsReduced(
    uint16 oldMaxBasisPoints,
    uint16 newMaxBasisPoints
  );

  event FeelessWalletAdded(
    address indexed addedWallet
  );

  event FeelessWalletRemoved(
    address indexed removedWallet
  );

  event TradeExecuted(
    address indexed trader,
    address indexed from,
    uint256 fromAmount,
    address indexed to,
    uint256 receivedAmount
  );

  event TradeFailedReason(
    address indexed trader,
    address indexed from,
    address indexed to,
    bytes reason
  );

  event FeesPayedOut(
    address indexed feeRecipient,
    address indexed feeToken,
    uint256 amount
  );

  /*** ### Custom Errors ### ***/

  error InvalidAddress(string paramName, address passedAddress);
  error MaxFeeExceeded(uint256 fee, uint256 maxFee);
  error RenounceOwnershipDisabled();
  error NewValueEqualsOld(string paramName);
  error ReducedMaxFeeTooSmall(uint256 maxFee, uint256 fee);
  error FeelessWalletAlreadySet();
  error FeelessWalletNotSet();
  error InvalidSignature(Trade trade);
  error FromEqualsTo(Trade trade);
  error ZeroAmountTrade(Trade trade);
  error MinToReceiveBeforeFeesZero(Trade trade);
  error TradeFailed(Trade trade, uint256 index);
  error ReturnEthFailed();
  error ReceiveEthFeeFailed();
  error NotEnoughClaimed(Trade trade, uint256 expected, uint256 received);
  error IncorrectSellAmount(Trade trade, uint256 expected, uint256 sold);
  error NotEnoughReceived(Trade trade, uint256 minExpected, uint256 received);
  error SoldDespiteTradeFailed(Trade trade);
  error ResetAllowanceFailed();

  /*** ### State Variables ### ***/

  address private constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  ExchangeAdapterRegistry public immutable exchangeAdapterRegistry;
  address public feeRecipient;
  uint16 public feeBasisPoints;
  uint16 public maxFeeBasisPoints;
  mapping(address => bool) public feelessWallets;
  address public tradeSigner;

  /*** ### Modifiers ### ***/

  /*** ### Constructor ### ***/

  constructor(
    ExchangeAdapterRegistry _exchangeAdapterRegistry,
    address _feeRecipient,
    uint16 _feeBasisPoints,
    uint16 _maxFeeBasisPoints,
    address _tradeSigner
  ) {
    if (address(_exchangeAdapterRegistry) == address(0)) {
      revert InvalidAddress("_exchangeAdapterRegistry", address(_exchangeAdapterRegistry));
    }
    if (address(_feeRecipient) == address(0)) {
      revert InvalidAddress("_feeRecipient", _feeRecipient);
    }
    if (_feeBasisPoints > _maxFeeBasisPoints) {
      revert MaxFeeExceeded(_feeBasisPoints, _maxFeeBasisPoints);
    }
    if (address(_tradeSigner) == address(0)) {
      revert InvalidAddress("_tradeSigner", _tradeSigner);
    }

    exchangeAdapterRegistry = _exchangeAdapterRegistry;
    feeRecipient = _feeRecipient;
    feeBasisPoints = _feeBasisPoints;
    maxFeeBasisPoints = _maxFeeBasisPoints;
    tradeSigner = _tradeSigner;

    emit BatchTradeDeployed(
      address(_exchangeAdapterRegistry),
      _feeRecipient,
      _feeBasisPoints,
      _maxFeeBasisPoints,
      _tradeSigner
    );
  }

  /*** ### External Functions ### ***/

  receive() external payable {}

  /**
   * ONLY OWNER: Override renounceOwnership to disable it
   */
  function renounceOwnership() public override view onlyOwner {
    revert RenounceOwnershipDisabled();
  }

  /**
   * ONLY OWNER: Activates BatchTrade.
   */
  function activate() external onlyOwner {
    _unpause();
  }

  /**
   * ONLY OWNER: Deactivates BatchTrade.
   */
  function deactivate() external onlyOwner {
    _pause();
  }

  /**
   * ONLY OWNER: Updates fee recipient.
   *
   * @param _newFeeRecipient New fee recipient
   */
  function updateFeeRecipient(address _newFeeRecipient) external onlyOwner {
    if (address(_newFeeRecipient) == address(0)) {
      revert InvalidAddress("_newFeeRecipient", _newFeeRecipient);
    }
    if (_newFeeRecipient == feeRecipient) {
      revert NewValueEqualsOld("_newFeeRecipient");
    }

    address oldFeeRecipient = feeRecipient;
    feeRecipient = _newFeeRecipient;
    emit FeeRecipientUpdated(oldFeeRecipient, _newFeeRecipient);
  }

  /**
   * ONLY OWNER: Updates basis points (Must be less than or equal max).
   *
   * @param _newFeeBasisPoints New basis points
   */
  function updateBasisPoints(uint16 _newFeeBasisPoints) external onlyOwner {
    if (_newFeeBasisPoints > maxFeeBasisPoints) {
      revert MaxFeeExceeded(_newFeeBasisPoints, maxFeeBasisPoints);
    }
    if (_newFeeBasisPoints == feeBasisPoints) {
      revert NewValueEqualsOld("_newFeeBasisPoints");
    }

    uint16 oldFeeBasisPoints = feeBasisPoints;
    feeBasisPoints = _newFeeBasisPoints;
    emit FeeBasisPointsUpdated(oldFeeBasisPoints, _newFeeBasisPoints);
  }

  /**
   * ONLY OWNER: Reduces max basis points (Must be less than max and bigger or equal current fee basis points).
   *
   * @param _newMaxFeeBasisPoints New max basis points
   */
  function reduceMaxBasisPoints(uint16 _newMaxFeeBasisPoints) external onlyOwner {
    if (_newMaxFeeBasisPoints >= maxFeeBasisPoints) {
      revert MaxFeeExceeded(_newMaxFeeBasisPoints, maxFeeBasisPoints);
    }
    if (_newMaxFeeBasisPoints < feeBasisPoints) {
      revert ReducedMaxFeeTooSmall(_newMaxFeeBasisPoints, feeBasisPoints);
    }

    uint16 oldMaxFeeBasisPoints = maxFeeBasisPoints;
    maxFeeBasisPoints = _newMaxFeeBasisPoints;
    emit MaxBasisPointsReduced(oldMaxFeeBasisPoints, _newMaxFeeBasisPoints);
  }

  /**
   * ONLY OWNER: Adds wallet that is eligible for feeless batch trading.
   *
   * @param _feelessWallet Wallet address to add
   */
  function addFeelessWallet(address _feelessWallet) public onlyOwner {
    if (address(_feelessWallet) == address(0)) {
      revert InvalidAddress("_feelessWallet", _feelessWallet);
    }
    if (feelessWallets[_feelessWallet]) {
      revert FeelessWalletAlreadySet();
    }

    feelessWallets[_feelessWallet] = true;
    emit FeelessWalletAdded(_feelessWallet);
  }

  /**
   * ONLY OWNER: Adds wallets that are eligible for feeless batch trading.
   *
   * @param _feelessWallets Wallet addresses to add
   */
  function addFeelessWallets(address[] calldata _feelessWallets) external onlyOwner {
    for (uint256 i = 0; i < _feelessWallets.length; i++) {
      addFeelessWallet(_feelessWallets[i]);
    }
  }

  /**
   * ONLY OWNER: Removes wallet that is eligible for feeless batch trading.
   *
   * @param _feelessWallet Wallet address to remove
   */
  function removeFeelessWallet(address _feelessWallet) public onlyOwner {
    if (address(_feelessWallet) == address(0)) {
      revert InvalidAddress("_feelessWallet", _feelessWallet);
    }
    if (!feelessWallets[_feelessWallet]) {
      revert FeelessWalletNotSet();
    }

    feelessWallets[_feelessWallet] = false;
    emit FeelessWalletRemoved(_feelessWallet);
  }

  /**
   * ONLY OWNER: Removes wallets that are eligible for feeless batch trading.
   *
   * @param _feelessWallets Wallet addresses to remove
   */
  function removeFeelessWallets(address[] calldata _feelessWallets) external onlyOwner {
    for (uint256 i = 0; i < _feelessWallets.length; i++) {
      removeFeelessWallet(_feelessWallets[i]);
    }
  }

  /**
   * ONLY OWNER: Updates trade signer.
   * (No event is emitted on purpose)
   *
   * @param _newTradeSigner New trade signer
   */
  function updateTradeSigner(address _newTradeSigner) external onlyOwner {
    if (address(_newTradeSigner) == address(0)) {
      revert InvalidAddress("_newTradeSigner", _newTradeSigner);
    }
    if (_newTradeSigner == tradeSigner) {
      revert NewValueEqualsOld("_newTradeSigner");
    }

    tradeSigner = _newTradeSigner;
  }

  /**
   * WHEN NOT PAUSED, NON REENTRANT: Executes a batch of trades on supported DEXs.
   * If trades fail events will be emitted. Based on the passed batchTradeConfig either the whole batch trade will
   * be reverted or the execution stops at the first failing trade.
   *
   * @param _trades           Struct with information for trades
   * @param _batchTradeConfig Struct that holds batch trade configs
   */
  function batchTrade(
    Trade[] calldata _trades,
    BatchTradeConfig memory _batchTradeConfig
  ) external payable whenNotPaused nonReentrant {
    uint256 value = msg.value;

    for (uint256 i = 0; i < _trades.length; i++) {
      (bool success, uint256 returnValue) = _executeTrade(
        _trades[i],
        value,
        _batchTradeConfig.checkFeelessWallets
      );
      if (success) {
        if (_trades[i].from == ETH_ADDRESS) {
          value -= _trades[i].fromAmount;
        }
        if (_trades[i].to == ETH_ADDRESS) {
          value += returnValue;
        }
      } else {
        // also revert if first trade
        if (_batchTradeConfig.revertOnError || i == 0) {
          revert TradeFailed(_trades[i], i);
        }
        _returnClaimedOnError(_trades[i]);
        break; // break loop and return senders eth
      }
    }

    if (value > 0) {
      bool success = false;
      (success, ) = msg.sender.call{value: value}("");
      if (!success) {
        revert ReturnEthFailed();
      }
    }
  }

  /**
   * Sends accrued fees to fee recipient.
   * (Also supports inflationary and yield generating tokens.)
   *
   * @param _feeTokensToReceive Addresses of the tokens that should be sent to the fee recipient
   */
  function receiveFees(address[] calldata _feeTokensToReceive) external {
    for (uint256 i = 0; i < _feeTokensToReceive.length; i++) {
      uint256 feeAmount = _getBalance(_feeTokensToReceive[i]);

      // if no fees of this specific token are collected jump over this address and proceed with next
      if (feeAmount > 0) {
        if (_feeTokensToReceive[i] != ETH_ADDRESS) {
          IERC20(_feeTokensToReceive[i]).safeTransfer(
            feeRecipient,
            feeAmount
          );
        } else {
          bool success = false;
          // arbitrary-send-eth can be disabled here since feeRecipient can just be set by the owner of the contract
          // slither-disable-next-line arbitrary-send-eth
          (success, ) = feeRecipient.call{value: feeAmount}("");
          if (!success) {
            revert ReceiveEthFeeFailed();
          }
        }
        emit FeesPayedOut(feeRecipient, _feeTokensToReceive[i], feeAmount);
      }
    }
  }

  /*** ### Private Functions ### ***/

  /**
   * Executes a single trade. This process is splitted up in the following steps:
   *  * Get exchange adapter
   *  * Validate and verify trade data
   *  * Get send token from sender
   *  * Invoke trade against DEX
   *  * Claim fees
   *  * Return received tokens to sender
   */
  function _executeTrade(
    Trade memory _trade,
    uint256 _value,
    bool _checkFeelessWallets
  ) private returns (bool success, uint256 returnAmount) {
    IExchangeAdapter exchangeAdapter = IExchangeAdapter(
      _getAndValidateAdapter(_trade.exchangeName)
    );

    _preTradeCheck(_trade, exchangeAdapter.getSpender());

    // prettier-ignore
    (
      address targetExchange,
      uint256 callValue,
      bytes memory data
    ) = _getTradeData(
      exchangeAdapter,
      _trade,
      _trade.from == ETH_ADDRESS ? _value : 0
    );

    _claimAndApproveFromToken(exchangeAdapter, _trade);
    (bool callExchangeSuccess, uint256 receivedAmount) = _callExchange(
      targetExchange,
      callValue,
      data,
      _trade
    );

    success = callExchangeSuccess;
    if (success) {
      uint256 feeAmount = _handleFees(
        receivedAmount,
        _checkFeelessWallets
      );
      returnAmount = receivedAmount - feeAmount;
      _returnToken(_trade, returnAmount);
    } else {
      _resetAllowance(exchangeAdapter, _trade);

      returnAmount = 0;
    }
  }

  /**
   * Validate pre trade data.
   * Check if trade data was signed by a valid account
   * Check if from address != to address
   * Check if fromAmount > 0
   * Check if minToReceiveBeforeFees > 0
   */
  function _preTradeCheck(Trade memory _trade, address spender) private view {
    bytes32 hash = keccak256(abi.encodePacked(spender, _trade.from, _trade.fromAmount, _trade.to, _trade.minToReceiveBeforeFees, _trade.data));
    address recoveredAddress = hash.toEthSignedMessageHash().recover(_trade.signature);
    if (recoveredAddress != tradeSigner) {
      revert InvalidSignature(_trade);
    }

    if (_trade.from == _trade.to) {
      revert FromEqualsTo(_trade);
    }

    if (_trade.fromAmount == 0) {
      revert ZeroAmountTrade(_trade);
    }

    if (_trade.minToReceiveBeforeFees == 0) {
      revert MinToReceiveBeforeFeesZero(_trade);
    }
  }

  /**
   * Gets the adapter with the passed in name. Validates that the address is not empty
   */
  function _getAndValidateAdapter(
    string memory _adapterName
  ) private view returns (address) {
    address adapter = exchangeAdapterRegistry.getAdapter(_adapterName);

    if (address(adapter) == address(0)) {
      revert InvalidAddress("adapter", adapter);
    }
    return adapter;
  }

  /**
   * Get trade data (exchange address, trade value, calldata).
   */
  function _getTradeData(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade,
    uint256 _value
  ) private view returns (address, uint256, bytes memory) {
    return
    _exchangeAdapter.getTradeCalldata(
      _trade.from,
      _trade.fromAmount,
      _trade.to,
      _trade.minToReceiveBeforeFees,
      address(this), // taker has to be this, otherwise DEXs like UniswapV3 might send funds directly back to taker
      _value,
      _trade.data
    );
  }

  /**
   * Get from tokens from sender and approve it to exchange/spender.
   */
  function _claimAndApproveFromToken(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade
  ) private {
    if (_trade.from != ETH_ADDRESS) {
      uint256 fromBalanceBefore = _getBalance(_trade.from);
      IERC20(_trade.from).safeTransferFrom(
        msg.sender,
        address(this),
        _trade.fromAmount
      );
      uint256 fromBalanceAfter = _getBalance(_trade.from);
      if (fromBalanceAfter < fromBalanceBefore + _trade.fromAmount) {
        revert NotEnoughClaimed(_trade, _trade.fromAmount, fromBalanceAfter - fromBalanceBefore);
      }

      IERC20(_trade.from).safeIncreaseAllowance(
        _exchangeAdapter.getSpender(),
        _trade.fromAmount
      );
    }
  }

  /**
   * Call arbitrary function on target exchange with calldata and value
   */
  function _callExchange(
    address _target,
    uint256 _value,
    bytes memory _data,
    Trade memory _trade
  ) private returns (bool success, uint256 receivedAmount) {
    uint256 fromBalanceBeforeTrade = _getBalance(_trade.from);
    uint256 toBalanceBeforeTrade = _getBalance(_trade.to);

    (bool targetSuccess, bytes memory result) = _target.call{value: _value}(
      _data
    );

    success = targetSuccess;
    if (success) {
      uint256 fromBalanceAfterTrade = _getBalance(_trade.from);
      if (fromBalanceAfterTrade != fromBalanceBeforeTrade - _trade.fromAmount) {
        revert IncorrectSellAmount(_trade, _trade.fromAmount, fromBalanceBeforeTrade - fromBalanceAfterTrade);
      }

      uint256 toBalanceAfterTrade = _getBalance(_trade.to);
      if (toBalanceAfterTrade < toBalanceBeforeTrade + _trade.minToReceiveBeforeFees) {
        revert NotEnoughReceived(_trade, _trade.minToReceiveBeforeFees, toBalanceAfterTrade - toBalanceBeforeTrade);
      }

      receivedAmount = toBalanceAfterTrade - toBalanceBeforeTrade;

      emit TradeExecuted(
        msg.sender,
        _trade.from,
        _trade.fromAmount,
        _trade.to,
        receivedAmount
      );
    } else {
      uint256 fromBalanceAfterTrade = _getBalance(_trade.from);
      if (fromBalanceAfterTrade != fromBalanceBeforeTrade) {
        revert SoldDespiteTradeFailed(_trade);
      }

      receivedAmount = 0;
      emit TradeFailedReason(msg.sender, _trade.from, _trade.to, result);
    }
  }

  function _getBalance(address token) private view returns (uint256) {
    if (token != ETH_ADDRESS) {
      return IERC20(token).balanceOf(address(this));
    } else {
      return address(this).balance;
    }
  }

  /**
   * Calculate fees based on basis points.
   * If _checkFeelessWallets is true and the sender wallet is eligible for feeless trading 0 is returned.
   */
  function _handleFees(
    uint256 _receivedAmount,
    bool _checkFeelessWallets // saves about 3.000 gas units per calculation
  ) private view returns (uint256 feeAmount) {
    if (_checkFeelessWallets && feelessWallets[msg.sender]) {
      return 0;
    }

    feeAmount = (_receivedAmount * feeBasisPoints) / 10000;
  }

  /**
   * Return received token to sender.
   */
  function _returnToken(
    Trade memory _trade,
    uint256 _amount
  ) private {
    if (_trade.to != ETH_ADDRESS && _amount > 0) {
      IERC20(_trade.to).safeTransfer(msg.sender, _amount);
    }
  }

  /**
   * Reset allowance of spender to 0.
   */
  function _resetAllowance(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade
  ) private {
    if (_trade.from != ETH_ADDRESS) {
      bool success = IERC20(_trade.from).approve(_exchangeAdapter.getSpender(), 0);
      if (!success) {
        revert ResetAllowanceFailed();
      }
    }
  }

  /**
   * If a trade failed this function is called to return the from tokens to the sender.
   */
  function _returnClaimedOnError(Trade memory _trade) private {
    if (_trade.from != ETH_ADDRESS) {
      IERC20(_trade.from).safeTransfer(
        msg.sender,
        _trade.fromAmount
      );
    }
  }
}