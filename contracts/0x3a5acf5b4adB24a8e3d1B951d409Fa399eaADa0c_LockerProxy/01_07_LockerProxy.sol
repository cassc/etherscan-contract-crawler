pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

interface IStaxStaking {
    function stakeFor(address _for, uint256 _amount) external;
}

/// @dev The stax liquidity token - eg xLP, xFXS.
interface IStaxLockerReceipt is IERC20 {
    function mint(address to, uint256 amount) external;
}

/// @dev interface of the curve stable swap.
interface IStableSwap {
    function coins(uint256 j) external view returns (address);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract LockerProxy is Ownable {
    using SafeERC20 for IStaxLockerReceipt;
    using SafeERC20 for IERC20;

    address public liquidityOps;
    IERC20 public inputToken; // eg TEMPLE/FRAX LP, FXS token
    IStaxLockerReceipt public staxReceiptToken; // eg xLP, xFXS token
    IStaxStaking public staking; // staking contract, eg to stake xLP, xFXS

    IStableSwap public curveStableSwap; // Curve pool for (xlp, lp) pair.

     // The order of curve pool tokens
    int128 public inputTokenIndex;
    int128 public staxReceiptTokenIndex;

    event Locked(address user, uint256 amountOut);
    event Bought(address user, uint256 amountOut);
    event LiquidityOpsSet(address liquidityOps);
    event TokenRecovered(address user, uint256 amount);

    constructor(
        address _liquidityOps,
        address _inputToken,
        address _staxReceiptToken,
        address _staking,
        address _curveStableSwap
    ) {
        liquidityOps = _liquidityOps;
        inputToken = IERC20(_inputToken);
        staxReceiptToken = IStaxLockerReceipt(_staxReceiptToken);
        staking = IStaxStaking(_staking);

        curveStableSwap = IStableSwap(_curveStableSwap);
        (staxReceiptTokenIndex, inputTokenIndex) = curveStableSwap.coins(0) == address(staxReceiptToken)
            ? (int128(0), int128(1))
            : (int128(1), int128(0));
    }

    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        require(_liquidityOps != address(0), "invalid address");
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
        require(_inputAmount <= inputToken.balanceOf(msg.sender), "not enough tokens");

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
        return curveStableSwap.get_dy(inputTokenIndex, staxReceiptTokenIndex, _liquidity);
    }

    /** 
      * @notice Purchase stax locker receipt tokens (eg xLP), by buying from the AMM.
      * @dev Use this instead of convert() if the receipt token is trading > 1:1 - eg you can get more xLP buying on the AMM 
      * @param _inputAmount How much of inputToken to lock (eg LP)
      * @param _stake If true, immediately stake the resulting staxReceiptToken (eg xLP)
      * @param _minAmmAmountOut The minimum amount we would expect to receive from the AMM
      */
    function buyFromAmm(uint256 _inputAmount, bool _stake, uint256 _minAmmAmountOut) external {
        require(_inputAmount <= inputToken.balanceOf(msg.sender), "not enough tokens");

        // Pull input tokens and give allowance for AMM to pull.
        inputToken.safeTransferFrom(msg.sender, address(this), _inputAmount);
        inputToken.safeIncreaseAllowance(address(curveStableSwap), _inputAmount);

        uint256 amountOut;
        if (_stake) {
            amountOut = curveStableSwap.exchange(inputTokenIndex, staxReceiptTokenIndex, _inputAmount, _minAmmAmountOut, address(this));
            staxReceiptToken.safeIncreaseAllowance(address(staking), amountOut);
            staking.stakeFor(msg.sender, amountOut);
        } else {
            amountOut = curveStableSwap.exchange(inputTokenIndex, staxReceiptTokenIndex, _inputAmount, _minAmmAmountOut, msg.sender);
        }

        emit Bought(msg.sender, amountOut);
    }

    // recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        _transferToken(IERC20(_token), _to, _amount);
        emit TokenRecovered(_to, _amount);
    }

    function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "not enough tokens");
        _token.safeTransfer(_to, _amount);
    }
}