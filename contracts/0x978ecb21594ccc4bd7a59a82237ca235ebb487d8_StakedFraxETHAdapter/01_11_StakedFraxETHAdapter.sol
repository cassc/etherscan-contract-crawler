// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IllegalArgument, Unauthorized } from "../../base/ErrorMessages.sol";
import { SafeERC20 } from "../../libraries/SafeERC20.sol";
import { MutexLock } from "../../base/MutexLock.sol";

import { IFraxMinter } from "../../interfaces/external/frax/IFraxMinter.sol";
import { IStakedFraxEth } from "../../interfaces/external/frax/IStakedFraxEth.sol";
import { IStableSwap2Pool } from "../../interfaces/external/curve/IStableSwap2Pool.sol";
import { ITokenAdapter } from "../../interfaces/ITokenAdapter.sol";
import { IWETH9 } from "../../interfaces/external/IWETH9.sol";

struct InitializationParams {
    address zeroliquid;
    address token;
    address minter;
    address parentToken;
    address underlyingToken;
    address curvePool;
    uint128 curvePoolEthIndex;
    uint128 curvePoolFrxEthIndex;
}

/// @title  StakedFraxETHAdapter
/// @author ZeroLiquid
contract StakedFraxETHAdapter is ITokenAdapter, MutexLock {
    string public constant override version = "1.0.0";

    address public immutable zeroliquid;
    address public immutable override token;
    address public immutable minter;
    address public immutable parentToken;
    address public immutable override underlyingToken;
    address public immutable curvePool;
    uint128 public immutable curvePoolEthIndex;
    uint128 public immutable curvePoolFrxEthIndex;

    constructor(InitializationParams memory params) {
        zeroliquid = params.zeroliquid;
        curvePool = params.curvePool;
        curvePoolEthIndex = params.curvePoolEthIndex;
        curvePoolFrxEthIndex = params.curvePoolFrxEthIndex;
        minter = params.minter;
        token = params.token;
        parentToken = params.parentToken;
        underlyingToken = params.underlyingToken;

        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (
            IStableSwap2Pool(params.curvePool).coins(params.curvePoolEthIndex)
                != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }

        // Verify and make sure that the provided frxETH matches the curve pool frxETH.
        if (IStableSwap2Pool(params.curvePool).coins(params.curvePoolFrxEthIndex) != params.parentToken) {
            revert IllegalArgument("Curve pool frxETH token mismatch");
        }
    }

    /// @dev Checks that the message sender is the zeroliquid that the adapter is bound to.
    modifier onlyZeroLiquid() {
        if (msg.sender != zeroliquid) {
            revert Unauthorized("Not ZeroLiquid");
        }
        _;
    }

    receive() external payable {
        if (msg.sender != underlyingToken && msg.sender != curvePool) {
            revert Unauthorized("Payments only permitted from WETH or curve pool");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view override returns (uint256) {
        return IStakedFraxEth(token).convertToAssets(1e18);
    }

    /// @inheritdoc ITokenAdapter
    function wrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        SafeERC20.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);

        // Unwrap the WETH into ETH.
        IWETH9(underlyingToken).withdraw(amount);

        // Mint frxEth.
        uint256 startingFraxEthBalance = IERC20(parentToken).balanceOf(address(this));
        IFraxMinter(minter).submit{ value: amount }();
        uint256 mintedFraxEth = IERC20(parentToken).balanceOf(address(this)) - startingFraxEthBalance;

        SafeERC20.safeApprove(parentToken, token, mintedFraxEth);
        return IStakedFraxEth(token).deposit(mintedFraxEth, recipient);
    }

    /// @inheritdoc ITokenAdapter
    function unwrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        // Withdraw frxEth from  sfrxEth.
        uint256 startingFraxEthBalance = IERC20(parentToken).balanceOf(address(this));
        IStakedFraxEth(token).withdraw(
            amount * this.price() / 10 ** SafeERC20.expectDecimals(token), address(this), address(this)
        );
        uint256 withdrawnFraxEth = IERC20(parentToken).balanceOf(address(this)) - startingFraxEthBalance;

        // Swap frxEth for eth in curve.
        SafeERC20.safeApprove(parentToken, curvePool, withdrawnFraxEth);
        uint256 received = IStableSwap2Pool(curvePool).exchange(
            int128(uint128(curvePoolFrxEthIndex)),
            int128(uint128(curvePoolEthIndex)),
            withdrawnFraxEth,
            0 // <- Slippage is handled upstream
        );

        // Wrap the ETH that we received from the exchange.
        IWETH9(underlyingToken).deposit{ value: received }();

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, received);

        return received;
    }
}