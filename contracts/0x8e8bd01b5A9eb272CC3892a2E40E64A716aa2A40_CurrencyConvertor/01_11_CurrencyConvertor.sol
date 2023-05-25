/*

  Copyright 2021 dYdX Trading Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { I_ExchangeProxy } from "../interfaces/I_ExchangeProxy.sol";
import { I_StarkwareContract } from "../interfaces/I_StarkwareContracts.sol";

/**
 * @title CurrencyConvertor
 * @author dYdX
 *
 * @notice Contract for depositing to dYdX L2 in non-USDC tokens.
 */
contract CurrencyConvertor is
  ERC2771Context,
  Pausable,
  Ownable,
  ReentrancyGuard
{
  using SafeERC20 for IERC20;

  // ============ State Variables ============

  I_StarkwareContract public immutable STARKWARE_CONTRACT;

  IERC20 immutable USDC_ADDRESS;

  uint256 immutable USDC_ASSET_TYPE;

  address immutable ETH_PLACEHOLDER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // ============ Constructor ============

  constructor(
    I_StarkwareContract starkwareContractAddress,
    IERC20 usdcAddress,
    uint256 usdcAssetType,
    address trustedForwarder
  )
    ERC2771Context(trustedForwarder)
  {
    STARKWARE_CONTRACT = starkwareContractAddress;
    USDC_ADDRESS = usdcAddress;
    USDC_ASSET_TYPE = usdcAssetType;

    // Set the allowance to the highest possible value.
    usdcAddress.safeApprove(address(starkwareContractAddress), type(uint256).max);
  }

  // ============ Events ============

  event LogConvertedDeposit(
    address indexed sender,
    address tokenFrom,
    uint256 tokenFromAmount,
    uint256 usdcAmount
  );

  // ============ External Functions ============

  /**
    * @notice Pause this contract.
    */
  function pause()
    external
    onlyOwner
  {
     _pause();
  }

  /**
    * @notice Unpause this contract.
    */
  function unpause()
    external
    onlyOwner
  {
    _unpause();
  }

  /**
    * @notice Make a deposit to the Starkware Layer2.
    *
    * @param  depositAmount      The amount of USDC to deposit.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function deposit(
    uint256 depositAmount,
    uint256 starkKey,
    uint256 positionId,
    bytes calldata signature
  )
    external
    nonReentrant
    whenNotPaused
  {
    address sender = _msgSender();

    // Register address in Starkware Layer2.
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(sender, starkKey, signature);
    }

    // Deposit depositAmount of USDC to the L2 exchange account of the sender.
    USDC_ADDRESS.safeTransferFrom(
      sender,
      address(this),
      depositAmount
    );
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      depositAmount
    );
  }

  /**
    * @notice Make a deposit to the Starkware Layer2, after converting funds to USDC.
    *  Funds will be transferred from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  tokenFrom          The ERC20 token to convert from.
    * @param  tokenFromAmount    The amount of `tokenFrom` tokens to deposit.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchangeProxy      The exchangeProxy being used to swap the `tokenFrom` for USDC.
    * @param  exchangeProxyData  Trade parameters for the exchangeProxy.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 starkKey,
    uint256 positionId,
    I_ExchangeProxy exchangeProxy,
    bytes calldata exchangeProxyData,
    bytes calldata signature
  )
    external
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    address sender = _msgSender();

    // Register address in Starkware Layer2.
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(sender, starkKey, signature);
    }

    // Send `tokenFrom` to this contract.
    tokenFrom.safeTransferFrom(
      sender,
      address(exchangeProxy),
      tokenFromAmount
    );

    // Swap token.
    exchangeProxy.proxyExchange(exchangeProxyData);

    // Deposit full balance of USDC in CurrencyConvertor to the L2 exchange account of the sender.
    uint256 usdcBalance = USDC_ADDRESS.balanceOf(address(this));
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalance
    );

    // Log the result.
    emit LogConvertedDeposit(
      sender,
      address(tokenFrom),
      tokenFromAmount,
      usdcBalance
    );

    return usdcBalance;
  }

  /**
    * @notice Make a deposit to the Starkware Layer2, after converting funds to USDC.
    *  Ether will be transferred from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchangeProxy      The exchangeProxy being used to swap the `tokenFrom` for USDC.
    * @param  exchangeProxyData  Trade parameters for the exchangeProxy.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositEth(
    uint256 starkKey,
    uint256 positionId,
    I_ExchangeProxy exchangeProxy,
    bytes calldata exchangeProxyData,
    bytes calldata signature
  )
    external
    payable
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    address sender = _msgSender();

    // Register address in Starkware Layer2.
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(sender, starkKey, signature);
    }

    // Swap token.
    exchangeProxy.proxyExchange{ value: msg.value }(exchangeProxyData);

    // Deposit full balance of USDC in CurrencyConvertor to the L2 exchange account of the sender.
    uint256 usdcBalance = USDC_ADDRESS.balanceOf(address(this));
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalance
    );

    // Log the result.
    emit LogConvertedDeposit(
      sender,
      ETH_PLACEHOLDER_ADDRESS,
      msg.value,
      usdcBalance
    );

    return usdcBalance;
  }

  // ============ Internal Functions ============

  function _msgSender()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}