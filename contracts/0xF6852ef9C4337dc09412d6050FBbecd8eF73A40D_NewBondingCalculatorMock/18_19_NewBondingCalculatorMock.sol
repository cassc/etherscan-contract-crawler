// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/IBondCalculator.sol";

import "../Libraries/SafeMath.sol";
import "../Libraries/SafeCast.sol";

import "../Types/TheopetraAccessControlled.sol";

contract NewBondingCalculatorMock is IBondCalculator, TheopetraAccessControlled {
    using SafeCast for *;

    address public immutable theo;
    uint256 public performanceTokenAmount;
    address public weth;
    address public usdc;
    address public immutable founderVesting;
    address public immutable performanceToken;
    uint256 public timePerformanceTokenLastUpdated;
    uint8 private constant DECIMALS = 9;

    constructor(
        address _theo,
        address _authority,
        address _performanceToken,
        address _founderVesting
    ) TheopetraAccessControlled(ITheopetraAuthority(_authority)) {
        theo = _theo;
        performanceToken = _performanceToken;
        founderVesting = _founderVesting;
    }

    /**
     * @dev when tokenIn is theo, valuation is being used for the Treasury (`tokenPerformanceUpdate`) or for Founder Vesting (in `getFdvFactor`)
     *      when tokenIn is WETH or USDC (aka, a 'quote token'), valuation is being used for the Bond Depository (`marketPrice`)
     *      If tokenIn is WETH (or USDC), the method returns the number of THEO expected per `_amount` of WETH (or USDC)
     *      where the number of THEO per quote token is calculated based on the following mock dollar prices:
     *      2000 dollars per WETH
     *      1 dollar per USDC
     *      0.01 dollars per THEO
     *      THEO per WETH is 2000 / 0.01 (i.e., 200000)
     *      THEO per USDC is 1 / 0.01 (i.e. 100)
     *      THEO is 9 decimals, WETH is 18 decimals, USDC is 6 decimals
     *
     *      If tokenIn is THEO, the method will return the performanceTokenAmount, where performanceTokenAmount should have a value with
     *      the correct number of decimals expected for the performance token; for example, USDC would have 6 decimals
     */
    function valuation(address tokenIn, uint256 _amount) external view override returns (uint256) {
        if (tokenIn == theo) {
            if (msg.sender == founderVesting) {
                uint8 performanceTokenDecimals = IERC20Metadata(performanceToken).decimals();
                return scaleAmountOut(performanceTokenAmount, performanceTokenDecimals);
            }
            return performanceTokenAmount;
        } else if (tokenIn == weth) {
            return (_amount * (200000 * 10**9)) / 10**18;
        } else if (tokenIn == usdc) {
            return (_amount * (100 * 10**9)) / 10**6;
        }
    }

    /**
     * @dev The value for performanceTokenAmount should be set with the number of decimals expected for the specific
     *      performance token, as desired; for example, if the performance token is expected to be USDC, performanceTokenAmount should use 6 decimals
     */
    function setPerformanceTokenAmount(uint256 _amount) public onlyGovernor {
        performanceTokenAmount = _amount;
    }

    function setWethAddress(address _weth) public onlyGovernor {
        weth = _weth;
    }

    function setUsdcAddress(address _usdc) public onlyGovernor {
        usdc = _usdc;
    }

    /**
     * @param _percentageChange   the percentage by which the performance token should be updated
     * @dev                 use to update the Token ROI (deltaTokenPrice) by the specified percentage
     */
    function updatePerformanceTokenAmount(int256 _percentageChange) public onlyGovernor {
        performanceTokenAmount = ((performanceTokenAmount).toInt256() +
            (((performanceTokenAmount).toInt256() * _percentageChange) / 100)).toUint256();
        timePerformanceTokenLastUpdated = block.timestamp;
    }

    /**
     * @notice For calls to `valuation` from the Founder Vesting contract, scale the amountOut (performanceToken per THEO) to be in THEO decimals (9)
     * @param _amountOut        performanceToken amount (per THEO) from Uniswap TWAP, with performanceToken decimals
     * @param _performanceTokenDecimals    decimals used for the performance token
     */
    function scaleAmountOut(uint256 _amountOut, uint8 _performanceTokenDecimals) internal pure returns (uint256) {
        if (_performanceTokenDecimals < DECIMALS) {
            return _amountOut * 10**uint256(DECIMALS - _performanceTokenDecimals);
        } else if (_performanceTokenDecimals > DECIMALS) {
            return _amountOut / 10**uint256(_performanceTokenDecimals - DECIMALS);
        }
        return _amountOut;
    }
}