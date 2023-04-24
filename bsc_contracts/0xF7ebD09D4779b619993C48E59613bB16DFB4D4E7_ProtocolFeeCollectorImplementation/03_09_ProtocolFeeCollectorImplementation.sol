// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "../library/SafeERC20.sol";
import "./ProtocolFeeCollectorStorage.sol";
import "../utils/NameVersion.sol";

contract ProtocolFeeCollectorImplementation is
    ProtocolFeeCollectorStorage,
    NameVersion
{
    event BuyAndBurnDeri(uint256 bTokenAmount, uint256 deriAmount);

    using SafeERC20 for IERC20;

    address public immutable deri;

    address public immutable bToken;

    address public immutable burningDestination;

    address public immutable swapRouter;

    address public immutable rebate;

    constructor(
        address deri_,
        address bToken_,
        address burningDestination_,
        address swapRouter_,
        address rebate_
    ) NameVersion("ProtocolFeeCollectorImplementation", "3.0.1") {
        deri = deri_;
        bToken = bToken_;
        burningDestination = burningDestination_;
        swapRouter = swapRouter_;
        rebate = rebate_;
    }

    function approveSwapRouter() external _onlyAdmin_ {
        IERC20(bToken).safeApprove(swapRouter, type(uint256).max);
    }

    function buyAndBurnDeri(
        uint256 bTokenAmount,
        uint256 minDeriAmount
    ) external _onlyAdmin_ {
        require(
            IERC20(bToken).balanceOf(address(this)) >= bTokenAmount,
            "ProtocolFeeCollectorImplementation.buyAndBurnDeri: bTokenAmount exceeds balance"
        );

        address[] memory path = new address[](2);
        path[0] = bToken;
        path[1] = deri;

        uint256[] memory res = IUniswapV2Router02(swapRouter)
            .swapExactTokensForTokens(
                bTokenAmount,
                minDeriAmount,
                path,
                burningDestination,
                block.timestamp
            );

        emit BuyAndBurnDeri(bTokenAmount, res[1]);
    }

    function transferOut(address recepient, uint256 amount) external {
        require(msg.sender == rebate, "only rebate");
        require(
            IERC20(bToken).balanceOf(address(this)) >= amount,
            "Insufficient B0"
        );
        IERC20(bToken).transfer(recepient, amount);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}