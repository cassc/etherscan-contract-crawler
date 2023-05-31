// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IThreeXBatchProcessing } from "../../interfaces/IThreeXBatchProcessing.sol";
import { BatchType, IAbstractBatchStorage } from "../../interfaces/IBatchStorage.sol";
import "../../../externals/interfaces/Curve3Pool.sol";
import "../../interfaces/IContractRegistry.sol";

/*
 * This Contract allows user to use and receive stablecoins directly when interacting with ThreeXBatchProcessing.
 * This contract takes DAI or USDT swaps them into USDC and deposits them or the other way around.
 */
contract ThreeXZapper {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IContractRegistry private contractRegistry;
  Curve3Pool private threePool;
  IERC20[3] public token; // [dai,usdc,usdt]

  /* ========== EVENTS ========== */

  event ZappedIntoBatch(uint256 outputAmount, address account);
  event ZappedOutOfBatch(
    bytes32 batchId,
    int128 stableCoinIndex,
    uint256 inputAmount,
    uint256 outputAmount,
    address account
  );
  event ClaimedIntoStable(
    bytes32 batchId,
    int128 stableCoinIndex,
    uint256 inputAmount,
    uint256 outputAmount,
    address account
  );

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    Curve3Pool _threePool,
    IERC20[3] memory _token
  ) {
    contractRegistry = _contractRegistry;
    threePool = _threePool;
    token = _token;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice zapIntoBatch allows a user to deposit into a mintBatch directly with DAI or USDT
   * @param _amount Input Amount
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   * @dev The amounts in _amounts must align with their index in the ThreePool
   */
  function zapIntoBatch(
    uint256 _amount,
    int128 _i,
    int128 _j,
    uint256 _min_amount // todo add instamint/redeem bool arg which calls batchMint()
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );

    token[uint256(uint128(_i))].safeTransferFrom(msg.sender, address(this), _amount);

    uint256 stableBalance = _swapStables(_i, _j, _amount);

    require(stableBalance >= _min_amount, "slippage too high");

    // Deposit USDC in current mint batch
    butterBatchProcessing.depositForMint(stableBalance, msg.sender);
    emit ZappedIntoBatch(stableBalance, msg.sender);
  }

  /**
   * @notice zapOutOfBatch allows a user to retrieve their not yet processed USDC and directly receive DAI or USDT
   * @param _batchId Defines which batch gets withdrawn from
   * @param _amountToWithdraw USDC amount that shall be withdrawn
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   */
  function zapOutOfBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    int128 _i,
    int128 _j,
    uint256 _min_amount
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );

    IAbstractBatchStorage batchStorage = butterBatchProcessing.batchStorage();

    require(batchStorage.getBatchType(_batchId) == BatchType.Mint, "!mint");

    uint256 withdrawnAmount = butterBatchProcessing.withdrawFromBatch(
      _batchId,
      _amountToWithdraw,
      msg.sender,
      address(this)
    );

    uint256 stableBalance = _swapStables(_i, _j, withdrawnAmount);

    require(stableBalance >= _min_amount, "slippage too high");

    token[uint256(uint128(_j))].safeTransfer(msg.sender, stableBalance);

    emit ZappedOutOfBatch(_batchId, _j, withdrawnAmount, stableBalance, msg.sender);
  }

  /**
   * @notice claimAndSwapToStable allows a user to claim their processed USDC from a redeemBatch and directly receive DAI or USDT
   * @param _batchId Defines which batch gets withdrawn from
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   */
  function claimAndSwapToStable(
    bytes32 _batchId,
    int128 _i,
    int128 _j,
    uint256 _min_amount
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );
    IAbstractBatchStorage batchStorage = butterBatchProcessing.batchStorage();

    require(batchStorage.getBatchType(_batchId) == BatchType.Redeem, "!redeem");

    uint256 inputAmount = butterBatchProcessing.claim(_batchId, msg.sender);
    uint256 stableBalance = _swapStables(_i, _j, inputAmount);

    require(stableBalance >= _min_amount, "slippage too high");

    token[uint256(uint128(_j))].safeTransfer(msg.sender, stableBalance);

    emit ClaimedIntoStable(_batchId, _j, inputAmount, stableBalance, msg.sender);
  }

  function _swapStables(
    int128 _fromIndex,
    int128 _toIndex,
    uint256 _inputAmount
  ) internal returns (uint256) {
    threePool.exchange(_fromIndex, _toIndex, _inputAmount, 0);
    return token[uint256(uint128(_toIndex))].balanceOf(address(this));
  }

  /**
   * @notice set idempotent approvals for threePool and butter batch processing
   */
  function setApprovals() external {
    for (uint256 i; i < token.length; i++) {
      token[i].safeApprove(address(threePool), 0);
      token[i].safeApprove(address(threePool), type(uint256).max);

      token[i].safeApprove(contractRegistry.getContract(keccak256("ThreeXBatchProcessing")), 0);
      token[i].safeApprove(contractRegistry.getContract(keccak256("ThreeXBatchProcessing")), type(uint256).max);
    }
  }
}