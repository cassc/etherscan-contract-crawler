// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract Leverager {
  using SafeMath for uint256;

  uint256 public constant BORROW_RATIO_DECIMALS = 4;
  ILendingPool public immutable lendingPool;

  constructor(address _lendingPool) {
    lendingPool = ILendingPool(_lendingPool);
  }

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
    return lendingPool.getConfiguration(asset);
  }

  /**
   * @dev Returns variable debt token address of asset
   * @param asset The address of the underlying asset of the reserve
   * @return varaiableDebtToken address of the asset
   **/
  function getVDebtToken(address asset) public view returns (address) {
    DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
    return reserveData.variableDebtTokenAddress;
  }

  /**
   * @dev Returns loan to value
   * @param asset The address of the underlying asset of the reserve
   * @return ltv of the asset
   **/
  function ltv(address asset) public view returns (uint256) {
    DataTypes.ReserveConfigurationMap memory conf = lendingPool.getConfiguration(asset);
    return conf.data % (2 ** 16);
  }

  /**
   * @dev Loop the deposit and borrow of an asset
   * @param asset for loop
   * @param amount for the initial deposit
   * @param interestRateMode stable or variable borrow mode
   * @param borrowRatio Ratio of tokens to borrow
   * @param loopCount Repeat count for loop
   **/
  function loop(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint256 borrowRatio,
    uint256 loopCount
  ) external {
    uint16 referralCode = 0;
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    IERC20(asset).approve(address(lendingPool), type(uint256).max);
    lendingPool.deposit(asset, amount, msg.sender, referralCode);
    for (uint256 i = 0; i < loopCount; i += 1) {
      amount = amount.mul(borrowRatio).div(10 ** BORROW_RATIO_DECIMALS);
      lendingPool.borrow(asset, amount, interestRateMode, referralCode, msg.sender);
      lendingPool.deposit(asset, amount, msg.sender, referralCode);
    }
  }
}