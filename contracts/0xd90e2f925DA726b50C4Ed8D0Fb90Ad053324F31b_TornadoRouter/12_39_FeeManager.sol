// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { UniswapV3OracleHelper } from "../libraries/UniswapV3OracleHelper.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { EnsResolve } from "torn-token/contracts/ENS.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "tornado-anonymity-mining/contracts/interfaces/ITornadoInstance.sol";
import "./InstanceRegistry.sol";

/// @dev contract which calculates the fee for each pool
contract FeeManager is EnsResolve {
  using SafeMath for uint256;

  uint256 public constant PROTOCOL_FEE_DIVIDER = 10000;
  address public immutable torn;
  address public immutable governance;
  InstanceRegistry public immutable registry;

  uint24 public uniswapTornPoolSwappingFee;
  uint32 public uniswapTimePeriod;

  uint24 public updateFeeTimeLimit;

  mapping(ITornadoInstance => uint160) public instanceFee;
  mapping(ITornadoInstance => uint256) public instanceFeeUpdated;

  event FeeUpdated(address indexed instance, uint256 newFee);
  event UniswapTornPoolSwappingFeeChanged(uint24 newFee);

  modifier onlyGovernance() {
    require(msg.sender == governance);
    _;
  }

  struct Deviation {
    address instance;
    int256 deviation; // in 10**-1 percents, so it can be like -2.3% if the price of TORN declined
  }

  constructor(
    address _torn,
    address _governance,
    bytes32 _registry
  ) public {
    torn = _torn;
    governance = _governance;
    registry = InstanceRegistry(resolve(_registry));
  }

  /**
   * @notice This function should update the fees of each pool
   */
  function updateAllFees() external {
    updateFees(registry.getAllInstanceAddresses());
  }

  /**
   * @notice This function should update the fees for tornado instances
   *         (here called pools)
   * @param _instances pool addresses to update fees for
   * */
  function updateFees(ITornadoInstance[] memory _instances) public {
    for (uint256 i = 0; i < _instances.length; i++) {
      updateFee(_instances[i]);
    }
  }

  /**
   * @notice This function should update the fee of a specific pool
   * @param _instance address of the pool to update fees for
   */
  function updateFee(ITornadoInstance _instance) public {
    uint160 newFee = calculatePoolFee(_instance);
    instanceFee[_instance] = newFee;
    instanceFeeUpdated[_instance] = now;
    emit FeeUpdated(address(_instance), newFee);
  }

  /**
   * @notice This function should return the fee of a specific pool and update it if the time has come
   * @param _instance address of the pool to get fees for
   */
  function instanceFeeWithUpdate(ITornadoInstance _instance) public returns (uint160) {
    if (now - instanceFeeUpdated[_instance] > updateFeeTimeLimit) {
      updateFee(_instance);
    }
    return instanceFee[_instance];
  }

  /**
   * @notice function to update a single fee entry
   * @param _instance instance for which to update data
   * @return newFee the new fee pool
   */
  function calculatePoolFee(ITornadoInstance _instance) public view returns (uint160) {
    (bool isERC20, IERC20 token, , uint24 uniswapPoolSwappingFee, uint32 protocolFeePercentage) = registry.instances(_instance);
    if (protocolFeePercentage == 0) {
      return 0;
    }

    token = token == IERC20(0) && !isERC20 ? IERC20(UniswapV3OracleHelper.WETH) : token; // for eth instances
    uint256 tokenPriceRatio = UniswapV3OracleHelper.getPriceRatioOfTokens(
      [torn, address(token)],
      [uniswapTornPoolSwappingFee, uniswapPoolSwappingFee],
      uniswapTimePeriod
    );
    // prettier-ignore
    return
      uint160(
        _instance
        .denomination()
        .mul(UniswapV3OracleHelper.RATIO_DIVIDER)
        .div(tokenPriceRatio)
        .mul(uint256(protocolFeePercentage))
        .div(PROTOCOL_FEE_DIVIDER)
      );
  }

  /**
   * @notice function to update the uniswap fee
   * @param _uniswapTornPoolSwappingFee new uniswap fee
   */
  function setUniswapTornPoolSwappingFee(uint24 _uniswapTornPoolSwappingFee) public onlyGovernance {
    uniswapTornPoolSwappingFee = _uniswapTornPoolSwappingFee;
    emit UniswapTornPoolSwappingFeeChanged(uniswapTornPoolSwappingFee);
  }

  /**
   * @notice This function should allow governance to set a new period for twap measurement
   * @param newPeriod the new period to use
   * */
  function setPeriodForTWAPOracle(uint32 newPeriod) external onlyGovernance {
    uniswapTimePeriod = newPeriod;
  }

  /**
   * @notice This function should allow governance to set a new update fee time limit for instance fee updating
   * @param newLimit the new time limit to use
   * */
  function setUpdateFeeTimeLimit(uint24 newLimit) external onlyGovernance {
    updateFeeTimeLimit = newLimit;
  }

  /**
   * @notice returns fees deviations for each instance, so it can be easily seen what instance requires an update
   */
  function feeDeviations() public view returns (Deviation[] memory results) {
    ITornadoInstance[] memory instances = registry.getAllInstanceAddresses();
    results = new Deviation[](instances.length);

    for (uint256 i = 0; i < instances.length; i++) {
      uint256 marketFee = calculatePoolFee(instances[i]);
      int256 deviation;
      if (marketFee != 0) {
        deviation = int256((instanceFee[instances[i]] * 1000) / marketFee) - 1000;
      }

      results[i] = Deviation({ instance: address(instances[i]), deviation: deviation });
    }
  }
}