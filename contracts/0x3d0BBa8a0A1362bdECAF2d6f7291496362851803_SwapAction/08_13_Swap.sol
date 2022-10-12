pragma solidity ^0.8.15;

import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IERC20 } from "../../interfaces/tokens/IERC20.sol";
import { SafeMath } from "../../libs/SafeMath.sol";
import { SafeERC20 } from "../../libs/SafeERC20.sol";
import { ONE_INCH_AGGREGATOR } from "../../core/constants/Common.sol";
import { SwapData } from "../../core/types/Common.sol";

contract Swap {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public feeBeneficiaryAddress;
  uint256 public constant feeBase = 10000;
  mapping(uint256 => bool) public feeTiers;
  mapping(address => bool) public authorizedAddresses;
  ServiceRegistry internal immutable registry;

  error ReceivedLess(uint256 receiveAtLeast, uint256 received);
  error Unauthorized();
  error FeeTierDoesNotExist(uint256 fee);
  error FeeTierAlreadyExists(uint256 fee);
  error SwapFailed();

  constructor(
    address authorisedCaller,
    address feeBeneficiary,
    uint256 _initialFee,
    address _registry
  ) {
    authorizedAddresses[authorisedCaller] = true;
    authorizedAddresses[feeBeneficiary] = true;
    addFeeTier(_initialFee);
    feeBeneficiaryAddress = feeBeneficiary;
    registry = ServiceRegistry(_registry);
  }

  event AssetSwap(
    address indexed assetIn,
    address indexed assetOut,
    uint256 amountIn,
    uint256 amountOut
  );

  event FeePaid(address indexed beneficiary, uint256 amount, address token);
  event SlippageSaved(uint256 minimumPossible, uint256 actualAmount);
  event FeeTierAdded(uint256 fee);
  event FeeTierRemoved(uint256 fee);

  modifier onlyAuthorised() {
    if (!authorizedAddresses[msg.sender]) {
      revert Unauthorized();
    }
    _;
  }

  function addFeeTier(uint256 fee) public onlyAuthorised {
    if (feeTiers[fee]) {
      revert FeeTierAlreadyExists(fee);
    }
    feeTiers[fee] = true;
    emit FeeTierAdded(fee);
  }

  function removeFeeTier(uint256 fee) public onlyAuthorised {
    if (!feeTiers[fee]) {
      revert FeeTierDoesNotExist(fee);
    }
    feeTiers[fee] = false;
    emit FeeTierRemoved(fee);
  }

  function verifyFee(uint256 feeId) public view returns (bool valid) {
    valid = feeTiers[feeId];
  }

  function _swap(
    address fromAsset,
    address toAsset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) internal returns (uint256 balance) {

    IERC20(fromAsset).safeApprove(callee, amount);
    (bool success, ) = callee.call(withData);

    if (!success) {
      revert SwapFailed();
    }

    balance = IERC20(toAsset).balanceOf(address(this));

    emit SlippageSaved(receiveAtLeast, balance);

    if (balance < receiveAtLeast) {
      revert ReceivedLess(receiveAtLeast, balance);
    }
    emit SlippageSaved(receiveAtLeast, balance);
    emit AssetSwap(fromAsset, toAsset, amount, balance);
  }

  function _collectFee(
    address asset,
    uint256 fromAmount,
    uint256 fee
  ) internal returns (uint256 amount) {
    bool isFeeValid = verifyFee(fee);
    if (!isFeeValid) {
      revert FeeTierDoesNotExist(fee);
    }

    uint256 feeToTransfer = fromAmount.mul(fee).div(fee.add(feeBase));

    if (fee > 0) {
      IERC20(asset).safeTransfer(feeBeneficiaryAddress, feeToTransfer);
      emit FeePaid(feeBeneficiaryAddress, feeToTransfer, asset);
    }

    amount = fromAmount.sub(feeToTransfer);
  }

  function swapTokens(
    SwapData calldata swapData
  ) public returns (uint256) {
    IERC20(swapData.fromAsset).safeTransferFrom(msg.sender, address(this), swapData.amount);
    uint256 amountFrom = swapData.amount;

    if (swapData.collectFeeInFromToken) {
      amountFrom = _collectFee(swapData.fromAsset, swapData.amount, swapData.fee);
    }

    address oneInch = registry.getRegisteredService(ONE_INCH_AGGREGATOR);
    uint256 toTokenBalance = _swap(
      swapData.fromAsset,
      swapData.toAsset,
      amountFrom,
      swapData.receiveAtLeast,
      oneInch,
      swapData.withData
    );

    if (!swapData.collectFeeInFromToken) {
      toTokenBalance = _collectFee(swapData.toAsset, toTokenBalance, swapData.fee);
    }

    uint256 fromTokenBalance = IERC20(swapData.fromAsset).balanceOf(address(this));
    if (fromTokenBalance > 0) {
      IERC20(swapData.fromAsset).safeTransfer(msg.sender, fromTokenBalance);
    }

    IERC20(swapData.toAsset).safeTransfer(msg.sender, toTokenBalance);
    return toTokenBalance;
  }
}