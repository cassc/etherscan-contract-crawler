// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IExcessDollarsDistributor.sol";
import "./interfaces/IMetaPool.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./SushiSwapPool.sol";
import "./libs/ABDKMathQuad.sol";

/// @title An excess dollar distributor which sends dollars to treasury,
/// lp rewards and inflation rewards
contract ExcessDollarsDistributor is IExcessDollarsDistributor {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
    UbiquityAlgorithmicDollarManager public manager;
    uint256 private immutable _minAmountToDistribute = 100 ether;
    IUniswapV2Router02 private immutable _router =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiV2Router02

    /// @param _manager the address of the manager contract so we can fetch variables
    constructor(address _manager) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
    }

    function distributeDollars() external override {
        //the excess dollars which were sent to this contract by the coupon manager
        uint256 excessDollars = IERC20Ubiquity(manager.dollarTokenAddress())
            .balanceOf(address(this));
        if (excessDollars > _minAmountToDistribute) {
            address treasuryAddress = manager.treasuryAddress();

            // curve uAD-3CRV liquidity pool
            uint256 tenPercent = excessDollars
                .fromUInt()
                .div(uint256(10).fromUInt())
                .toUInt();
            uint256 fiftyPercent = excessDollars
                .fromUInt()
                .div(uint256(2).fromUInt())
                .toUInt();
            IERC20Ubiquity(manager.dollarTokenAddress()).safeTransfer(
                treasuryAddress,
                fiftyPercent
            );
            // convert uAD to uGOV-UAD LP on sushi and burn them
            _governanceBuyBackLPAndBurn(tenPercent);
            // convert remaining uAD to curve LP tokens
            // and transfer the curve LP tokens to the bonding contract
            _convertToCurveLPAndTransfer(
                excessDollars - fiftyPercent - tenPercent
            );
        }
    }

    // swap half amount to uGOV
    function _swapDollarsForGovernance(bytes16 amountIn)
        internal
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = manager.dollarTokenAddress();
        path[1] = manager.governanceTokenAddress();
        uint256[] memory amounts = _router.swapExactTokensForTokens(
            amountIn.toUInt(),
            0,
            path,
            address(this),
            block.timestamp + 100
        );

        return amounts[1];
    }

    // buy-back and burn uGOV
    function _governanceBuyBackLPAndBurn(uint256 amount) internal {
        bytes16 amountUAD = (amount.fromUInt()).div(uint256(2).fromUInt());

        // we need to approve sushi router
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            address(_router),
            0
        );
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            address(_router),
            amount
        );
        uint256 amountUGOV = _swapDollarsForGovernance(amountUAD);

        IERC20Ubiquity(manager.governanceTokenAddress()).safeApprove(
            address(_router),
            0
        );
        IERC20Ubiquity(manager.governanceTokenAddress()).safeApprove(
            address(_router),
            amountUGOV
        );

        // deposit liquidity and transfer to zero address (burn)
        _router.addLiquidity(
            manager.dollarTokenAddress(),
            manager.governanceTokenAddress(),
            amountUAD.toUInt(),
            amountUGOV,
            0,
            0,
            address(0),
            block.timestamp + 100
        );
    }

    // @dev convert to curve LP
    // @param amount to convert to curve LP by swapping to 3CRV
    //        and deposit the 3CRV as liquidity to get uAD-3CRV LP tokens
    //        the LP token are sent to the bonding contract
    function _convertToCurveLPAndTransfer(uint256 amount)
        internal
        returns (uint256)
    {
        // we need to approve  metaPool
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            manager.stableSwapMetaPoolAddress(),
            0
        );
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            manager.stableSwapMetaPoolAddress(),
            amount
        );

        // swap  amount of uAD => 3CRV
        uint256 amount3CRVReceived = IMetaPool(
            manager.stableSwapMetaPoolAddress()
        ).exchange(0, 1, amount, 0);

        // approve metapool to transfer our 3CRV
        IERC20(manager.curve3PoolTokenAddress()).safeApprove(
            manager.stableSwapMetaPoolAddress(),
            0
        );
        IERC20(manager.curve3PoolTokenAddress()).safeApprove(
            manager.stableSwapMetaPoolAddress(),
            amount3CRVReceived
        );

        // deposit liquidity
        uint256 res = IMetaPool(manager.stableSwapMetaPoolAddress())
            .add_liquidity(
                [0, amount3CRVReceived],
                0,
                manager.bondingContractAddress()
            );
        // update TWAP price
        return res;
    }
}