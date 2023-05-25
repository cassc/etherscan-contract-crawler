// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import './interfaces/IStableSwapRouter.sol';
import './interfaces/IStableSwap.sol';
import './libraries/SmartRouterHelper.sol';
import './libraries/Constants.sol';

import './base/PeripheryPaymentsWithFeeExtended.sol';

/// @title Pancake Stable Swap Router
abstract contract StableSwapRouter is IStableSwapRouter, PeripheryPaymentsWithFeeExtended, Ownable, ReentrancyGuard {
    address public stableSwapFactory;
    address public stableSwapInfo;

    event SetStableSwap(address indexed factory, address indexed info);

    constructor(
        address _stableSwapFactory,
        address _stableSwapInfo
    ) {
        stableSwapFactory = _stableSwapFactory;
        stableSwapInfo = _stableSwapInfo;
    }

    /**
     * @notice Set Pancake Stable Swap Factory and Info
     * @dev Only callable by contract owner
     */
    function setStableSwap(
        address _factory,
        address _info
    ) external onlyOwner {
        require(_factory != address(0) && _info != address(0));

        stableSwapFactory = _factory;
        stableSwapInfo = _info;

        emit SetStableSwap(stableSwapFactory, stableSwapInfo);
    }

    /// `refundETH` should be called at very end of all swaps
    function _swap(
        address[] memory path,
        uint256[] memory flag
    ) private {
        require(path.length - 1 == flag.length);
        
        for (uint256 i; i < flag.length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (uint256 k, uint256 j, address swapContract) = SmartRouterHelper.getStableInfo(stableSwapFactory, input, output, flag[i]); 
            uint256 amountIn_ = IERC20(input).balanceOf(address(this));
            TransferHelper.safeApprove(input, swapContract, amountIn_);
            IStableSwap(swapContract).exchange(k, j, amountIn_, 0);
        }
    }

    /** 
     * @param flag token amount in a stable swap pool. 2 for 2pool, 3 for 3pool    
     */
    function exactInputStableSwap(
        address[] calldata path,
        uint256[] calldata flag,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external payable override nonReentrant returns (uint256 amountOut) {
        IERC20 srcToken = IERC20(path[0]);
        IERC20 dstToken = IERC20(path[path.length - 1]);

        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            amountIn = srcToken.balanceOf(address(this));
        }

        if (!hasAlreadyPaid) {
            pay(address(srcToken), msg.sender, address(this), amountIn);
        }

        _swap(path, flag);

        amountOut = dstToken.balanceOf(address(this));
        require(amountOut >= amountOutMin);

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        if (to != address(this)) pay(address(dstToken), address(this), to, amountOut);
    }

    /** 
     * @param flag token amount in a stable swap pool. 2 for 2pool, 3 for 3pool    
     */
    function exactOutputStableSwap(
        address[] calldata path,
        uint256[] calldata flag,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external payable override nonReentrant returns (uint256 amountIn) {
        amountIn = SmartRouterHelper.getStableAmountsIn(stableSwapFactory, stableSwapInfo, path, flag, amountOut)[0];
        require(amountIn <= amountInMax);

        pay(path[0], msg.sender, address(this), amountIn);

        _swap(path, flag);

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        if (to != address(this)) pay(path[path.length - 1], address(this), to, amountOut);    
    }
}