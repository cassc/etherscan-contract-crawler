// SPDX-License-Identifier: BUSL-1.1
//
// (c) Copyright 2023, Bad Pumpkin Inc. All Rights Reserved
//
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { IVault } from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import { Address } from "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol";
import { ReentrancyGuard } from "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ReentrancyGuard.sol";

import { ICronV1Relayer } from "../interfaces/ICronV1Relayer.sol";
import { ICronV1Pool } from "../interfaces/ICronV1Pool.sol";
import { ICronV1PoolFactory } from "../interfaces/ICronV1PoolFactory.sol";
import { Order } from "../interfaces/Structs.sol";

import { C } from "../miscellany/Constants.sol";
import { requireErrCode, CronErrors } from "../miscellany/Errors.sol";

/// @title CronFi Relayer / Periphery Contract
/// @author Zero Slippage (0slippage) & 0x70626a.eth, Based upon example Balancer relayer designs.
/// @notice A periphery contract for the CronFi V1 Time-Weighted Average Market Maker (TWAMM) pools built
///         upon Balancer Vault. While this contract's interface to the CronFi TWAMM pools increases gas use,
///         it provides reasonable safety checks on behalf of the user that the core contract does not. It is also
///         convenient for users within Etherscan, Gnosis Safe and other contract web interfaces, eliminating the need
///         for the construction of complex Solidity data types that are cumbersome in that environment.
///
///         For usage details, see the online CronFi documentation at https://docs.cronfi.com/.
///
///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
///                    this contract's address.
///
///
contract CronV1Relayer is ICronV1Relayer, ReentrancyGuard {
  using Address for address payable;
  using Address for address;

  IVault private immutable VAULT;
  address private immutable LIB_ADDR;
  ICronV1PoolFactory private immutable FACTORY;

  /// @notice Creates an instance of the CronFi Time-Weighted Average Market Maker (TWAMM) periphery relayer
  ///         contract.
  ///
  /// @dev IMPORTANT: This contract is not meant to be deployed directly by an EOA, but rather during construction
  ///                 of a library contract derived from `BaseRelayerLibrary`, which will provide its own address
  ///                 as this periphery relayer's library address, LIB_ADDR.
  ///
  /// @param _vault is the Balancer Vault instance this periphery relayer contract services.
  /// @param _libraryAddress is the address of the library contract this periphery relayer uses to interact
  ///                        with the Vault instance. Note as mentioned above in the "dev" note, the library contract
  ///                        is instantiated first and then constructs this contract with its address, _libraryAddress,
  ///                        as an argument.
  /// @param _factory is the CronFi factory contract instance.
  ///
  constructor(
    IVault _vault,
    address _libraryAddress,
    ICronV1PoolFactory _factory
  ) {
    VAULT = _vault;
    LIB_ADDR = _libraryAddress;
    FACTORY = _factory;
  }

  /// @notice Do not accept ETH transfers from anyone. The relayer and CronFi Time Weighted Average Market
  ///         Maker (TWAMM) pools do not work with raw ETH.
  ///
  ///         NOTE: Unlike other Balancer relayer examples, the refund ETH functionality has been removed to prevent
  ///               self-destruct attacks, causing transactions to revert, since CronFi TWAMM doesn't support
  ///               raw ETH.
  ///
  receive() external payable {
    requireErrCode(false, CronErrors.P_ETH_TRANSFER);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function swap(
    address _tokenIn,
    address _tokenOut,
    uint256 _poolType,
    uint256 _amountIn,
    uint256 _minTokenOut,
    address _recipient
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory swapResult) {
    bytes memory data = abi.encodeWithSignature(
      "swap(address,uint256,address,uint256,uint256,address,address)",
      _tokenIn,
      _amountIn,
      _tokenOut,
      _minTokenOut,
      _poolType,
      msg.sender,
      _recipient
    );
    swapResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function join(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _liquidityA,
    uint256 _liquidityB,
    uint256 _minLiquidityA,
    uint256 _minLiquidityB,
    address _recipient
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory joinResult) {
    bytes memory data = abi.encodeWithSignature(
      "join(address,address,uint256,uint256,uint256,uint256,uint256,address,address)",
      _tokenA,
      _tokenB,
      _poolType,
      _liquidityA,
      _liquidityB,
      _minLiquidityA,
      _minLiquidityB,
      msg.sender,
      _recipient
    );
    joinResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function exit(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _numLPTokens,
    uint256 _minAmountOutA,
    uint256 _minAmountOutB,
    address _recipient
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory exitResult) {
    bytes memory data = abi.encodeWithSignature(
      "exit(address,address,uint256,uint256,uint256,uint256,address,address)",
      _tokenA,
      _tokenB,
      _poolType,
      _numLPTokens,
      _minAmountOutA,
      _minAmountOutB,
      msg.sender,
      _recipient
    );
    exitResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function longTermSwap(
    address _tokenIn,
    address _tokenOut,
    uint256 _poolType,
    uint256 _amountIn,
    uint256 _intervals,
    address _delegate
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory longTermSwapResult, uint256 orderId) {
    requireErrCode(_tokenIn != C.NULL_ADDR, CronErrors.P_INVALID_TOKEN_IN_ADDRESS);
    requireErrCode(_tokenOut != C.NULL_ADDR, CronErrors.P_INVALID_TOKEN_OUT_ADDRESS);

    requireErrCode(_poolType < 3, CronErrors.P_INVALID_POOL_TYPE);
    address pool = FACTORY.getPool(_tokenIn, _tokenOut, _poolType);
    requireErrCode(pool != C.NULL_ADDR, CronErrors.P_NON_EXISTING_POOL);

    bytes32 poolId = ICronV1Pool(pool).POOL_ID();
    requireErrCode(poolId != "", CronErrors.P_INVALID_POOL_ADDRESS);

    orderId = ICronV1Pool(pool).getOrderIdCount();

    bytes memory data = abi.encodeWithSignature(
      "longTermSwap(address,address,uint256,uint256,uint256,address,address)",
      _tokenIn,
      _tokenOut,
      _poolType,
      _amountIn,
      _intervals,
      msg.sender,
      _delegate
    );
    longTermSwapResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function withdraw(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId,
    address _recipient
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory withdrawResult) {
    bytes memory data = abi.encodeWithSignature(
      "withdraw(address,address,uint256,uint256,address,address)",
      _tokenA,
      _tokenB,
      _poolType,
      _orderId,
      msg.sender,
      _recipient
    );
    withdrawResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function cancel(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId,
    address _recipient
  ) external override(ICronV1Relayer) nonReentrant returns (bytes memory cancelResult) {
    bytes memory data = abi.encodeWithSignature(
      "cancel(address,address,uint256,uint256,address,address)",
      _tokenA,
      _tokenB,
      _poolType,
      _orderId,
      msg.sender,
      _recipient
    );
    cancelResult = _delegateCallFn(data);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function getVault() external view override(ICronV1Relayer) returns (IVault) {
    return VAULT;
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function getLibrary() external view override(ICronV1Relayer) returns (address) {
    return LIB_ADDR;
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function getPoolAddress(
    address _tokenA,
    address _tokenB,
    uint256 _poolType
  ) external view override(ICronV1Relayer) returns (address pool) {
    pool = FACTORY.getPool(_tokenA, _tokenB, _poolType);
    requireErrCode(pool != C.NULL_ADDR, CronErrors.P_NON_EXISTING_POOL);
  }

  /// @notice see documentation in ICronV1Relayer.sol
  ///
  function getOrder(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId
  ) external view override(ICronV1Relayer) returns (address pool, Order memory order) {
    pool = FACTORY.getPool(_tokenA, _tokenB, _poolType);
    requireErrCode(pool != C.NULL_ADDR, CronErrors.P_NON_EXISTING_POOL);

    order = ICronV1Pool(pool).getOrder(_orderId);
  }

  /// @notice Performs delegate calls from provided encoded data on this periphery relayer's
  ///         library contract.
  /// @param _data is encoded delegate call data for functions of this periphery relayer's library
  ///              contract.
  /// @return result is the result of the delegate call.
  ///
  function _delegateCallFn(bytes memory _data) private returns (bytes memory result) {
    result = LIB_ADDR.functionDelegateCall(_data);
  }
}