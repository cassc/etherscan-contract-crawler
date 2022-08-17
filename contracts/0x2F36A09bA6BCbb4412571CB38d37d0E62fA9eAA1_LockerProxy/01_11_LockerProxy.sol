pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/temple-frax/LockerProxy.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/common/IMintableToken.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/IStaxLPStaking.sol";

import "../../../liquidity-pools/CurveStableSwap.sol";
import "../../../common/CommonEventsAndErrors.sol";

/// @notice Users lock (and optionally stake) LP into STAX.
/// @dev This is a one-way conversion of LP -> xLP, where exit liquidity (xLP->LP) is provided via a curve stable swap market.
/// This LP is locked in gauges to generate time and veFXS boosted yield for users who stake their xLP
contract LockerProxy is Ownable {
    using SafeERC20 for IMintableToken;
    using SafeERC20 for IERC20;
    using CurveStableSwap for CurveStableSwap.Data;

    /// @notice The STAX contract managing the deposited LP
    address public liquidityOps;

    /// @notice The staking token for deposits (ie LP)
    IERC20 public inputToken;

    /// @notice The staking receipt token (ie xLP)
    IMintableToken public staxReceiptToken;

    /// @notice The STAX staking contract
    IStaxLPStaking public staking;

    /// @notice Curve v1 Stable Swap (xLP:LP) is used as the pool for exit liquidity.
    CurveStableSwap.Data public curveStableSwap;

    event Locked(address user, uint256 amountOut);
    event Bought(address user, uint256 amountOut);
    event LiquidityOpsSet(address liquidityOps);

    constructor(
        address _liquidityOps,
        address _inputToken,
        address _staxReceiptToken,
        address _staking,
        address _curveStableSwap
    ) {
        liquidityOps = _liquidityOps;
        inputToken = IERC20(_inputToken);
        staxReceiptToken = IMintableToken(_staxReceiptToken);
        staking = IStaxLPStaking(_staking);

        ICurveStableSwap ccs = ICurveStableSwap(_curveStableSwap);
        curveStableSwap = CurveStableSwap.Data(ccs, IERC20(ccs.coins(0)), IERC20(ccs.coins(1)));
    }

    /// @notice Set the liquidity ops contract used to apply LP to gauges/exit liquidity pools
    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        if (_liquidityOps == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        liquidityOps = _liquidityOps;
        emit LiquidityOpsSet(_liquidityOps);
    }

    /** 
      * @notice Convert inputToken (eg LP) to staxReceiptToken (eg xLP), at 1:1
      * @dev This will mint staxReceiptToken (1:1)
      * @param _inputAmount How much of inputToken to lock (eg LP)
      * @param _stake If true, immediately stake the resulting staxReceiptToken (eg xLP)
      */
    function lock(uint256 _inputAmount, bool _stake) external {
        if (_inputAmount == 0) revert CommonEventsAndErrors.InvalidParam();

        // Avoid obscure error messages to the user if the token re-implemented transfer()
        uint256 bal = inputToken.balanceOf(msg.sender);
        if (_inputAmount > bal) revert CommonEventsAndErrors.InsufficientBalance(address(inputToken), _inputAmount, bal);

        inputToken.safeTransferFrom(msg.sender, liquidityOps, _inputAmount);

        if (_stake) {
            staxReceiptToken.mint(address(this), _inputAmount);
            staxReceiptToken.safeIncreaseAllowance(address(staking), _inputAmount);
            staking.stakeFor(msg.sender, _inputAmount);
        } else {
            staxReceiptToken.mint(msg.sender, _inputAmount);
        }

        emit Locked(msg.sender, _inputAmount);
    }
    
    /** 
      * @notice Get a quote to purchase staxReceiptToken (eg xLP) using inputToken (eg LP) via the AMM.
      * @dev This includes AMM fees + liquidity based slippage.
      * @param _liquidity The amount of inputToken (eg LP)
      * @return _staxReceiptAmount The expected amount of _staxReceiptAmount from the AMM
      */
    function buyFromAmmQuote(uint256 _liquidity) external view returns (uint256 _staxReceiptAmount) {
        return curveStableSwap.exchangeQuote(address(inputToken), _liquidity);
    }

    /** 
      * @notice Purchase stax locker receipt tokens (eg xLP), by buying from the AMM.
      * @dev Use this instead of convert() if the receipt token is trading > 1:1 - eg you can get more xLP buying on the AMM 
      * @param _inputAmount How much of inputToken to lock (eg LP)
      * @param _stake If true, immediately stake the resulting staxReceiptToken (eg xLP)
      * @param _minAmmAmountOut The minimum amount we would expect to receive from the AMM
      */
    function buyFromAmm(uint256 _inputAmount, bool _stake, uint256 _minAmmAmountOut) external {
        if (_inputAmount == 0) revert CommonEventsAndErrors.InvalidParam();

        // Avoid obscure error messages from the LP if it re-implemented transfer()
        uint256 balance = inputToken.balanceOf(msg.sender);
        if (balance < _inputAmount) revert CommonEventsAndErrors.InsufficientBalance(address(inputToken), _inputAmount, balance);

        // Pull input tokens from user.
        inputToken.safeTransferFrom(msg.sender, address(this), _inputAmount);

        uint256 amountOut;
        if (_stake) {
            amountOut = curveStableSwap.exchange(address(inputToken), _inputAmount, _minAmmAmountOut, address(this));
            staxReceiptToken.safeIncreaseAllowance(address(staking), amountOut);
            staking.stakeFor(msg.sender, amountOut);
        } else {
            amountOut = curveStableSwap.exchange(address(inputToken), _inputAmount, _minAmmAmountOut, msg.sender);
        }
        emit Bought(msg.sender, amountOut);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

}