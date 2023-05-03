// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../ApeSwapZap.sol";
import "./lib/IMasterApeV2.sol";

abstract contract ApeSwapZapMasterApeV2 is ApeSwapZap {
    using SafeERC20 for IERC20;

    event ZapMasterApeV2(IERC20 inputToken, uint256 inputAmount, uint256 pid);
    event ZapMasterApeV2Native(uint256 inputAmount, uint256 pid);

    constructor() {}

    /// @notice Zap token into masterApeV2v2 style dual farm
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param masterApeV2 The MasterApeV2 contract
    /// @param pid MasterApeV2 Pid
    function zapMasterApeV2(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        IMasterApeV2 masterApeV2,
        uint256 pid
    ) external nonReentrant {
        IApePair pair = _validateMasterApeV2Zap(lpTokens, masterApeV2, pid);
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            false
        );

        uint256 balance = pair.balanceOf(address(this));
        pair.approve(address(masterApeV2), balance);
        masterApeV2.depositTo(pid, balance, msg.sender);
        pair.approve(address(masterApeV2), 0);
        emit ZapMasterApeV2(inputToken, inputAmount, pid);
    }

    /// @notice Zap native into masterApeV2V2 style dual farm
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param masterApeV2 The MasterApeV2 contract
    /// @param pid MasterApeV2 Pid
    function zapMasterApeV2Native(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        IMasterApeV2 masterApeV2,
        uint256 pid
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            true
        );

        IApePair pair = _validateMasterApeV2Zap(lpTokens, masterApeV2, pid);
        uint256 balance = pair.balanceOf(address(this));
        pair.approve(address(masterApeV2), balance);
        masterApeV2.depositTo(pid, balance, msg.sender);
        pair.approve(address(masterApeV2), 0);
        emit ZapMasterApeV2Native(msg.value, pid);
    }

    /** PRIVATE FUNCTIONs **/

    function _validateMasterApeV2Zap(
        address[] memory lpTokens,
        IMasterApeV2 masterApeV2,
        uint256 pid
    ) private view returns (IApePair pair) {
        (address lpToken, , , , , , ) = masterApeV2.getPoolInfo(pid);
        pair = IApePair(lpToken);
        require(
            (lpTokens[0] == pair.token0() && lpTokens[1] == pair.token1()) ||
                (lpTokens[1] == pair.token0() && lpTokens[0] == pair.token1()),
            "ApeSwapZapMasterApeV2: Wrong LP pair for MasterApeV2"
        );
    }
}