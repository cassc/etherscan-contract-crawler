// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DefiiWithParams} from "../DefiiWithParams.sol";

contract CompoundV2LeverageDaiUsdc is DefiiWithParams {
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ICErc20 constant cDAI = ICErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ICErc20 constant cUSDC =
        ICErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IComptroller constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPool constant daiUsdcPool =
        IPool(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168);

    function encodeParams(uint8 loopCount, uint8 ltv)
        external
        pure
        returns (bytes memory encodedParams)
    {
        require(ltv < 100, "LTV must be in range [0, 100]");
        encodedParams = abi.encode(loopCount, ltv);
    }

    function hasAllocation() external view override returns (bool) {
        return cDAI.balanceOf(address(this)) > 0;
    }

    function _enterWithParams(bytes memory params) internal override {
        IPriceOracle oracle = comptroller.oracle();

        (uint8 loopCount, uint8 ltv) = abi.decode(params, (uint8, uint8));

        USDC.approve(address(router), type(uint256).max);
        DAI.approve(address(cDAI), type(uint256).max);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDAI);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        uint256 daiPrice = oracle.getUnderlyingPrice(address(cDAI));
        uint256 usdcPrice = oracle.getUnderlyingPrice(address(cUSDC));

        uint256 daiBalance;
        uint256 usdcBalance;
        for (uint8 i = 0; i < loopCount; i++) {
            daiBalance = DAI.balanceOf(address(this));
            cDAI.mint(daiBalance);
            cUSDC.borrow((((daiBalance * daiPrice) / usdcPrice) * ltv) / 100);
            usdcBalance = USDC.balanceOf(address(this));

            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(DAI),
                    fee: 100,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: usdcBalance,
                    amountOutMinimum: (usdcBalance * 999) / 1000, // slippage 0.1 %
                    sqrtPriceLimitX96: 0
                })
            );
        }
        cDAI.mint(DAI.balanceOf(address(this)));

        USDC.approve(address(router), 0);
        DAI.approve(address(cDAI), 0);
    }

    function _exit() internal override call {
        uint256 borrowedUsdc = cUSDC.borrowBalanceCurrent(address(this));
        daiUsdcPool.swap(
            address(this),
            true,
            -int256(borrowedUsdc),
            4295128739 + 1, // MIN_SQRT_RATIO + 1
            bytes("")
        );
        cDAI.redeem(cDAI.balanceOf(address(this)));

        _claimCompAndConvertToUsdc();
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) external callback {
        require(msg.sender == address(daiUsdcPool));

        // Should obtain DAI, should return USDC
        require(amount0 > 0, "Wrong amount of DAI");
        require(amount1 < 0, "Wrong admount of USDC");

        uint256 repaymentAmount = uint256(-amount1);
        USDC.approve(address(cUSDC), repaymentAmount);
        cUSDC.repayBorrow(repaymentAmount);

        cDAI.redeemUnderlying(uint256(amount0));
        DAI.transfer(address(daiUsdcPool), uint256(amount0));
    }

    function _harvest() internal override {
        _claimCompAndConvertToUsdc();
        _withdrawFunds();
    }

    function _claimCompAndConvertToUsdc() internal {
        comptroller.claimComp(address(this));
        uint256 compBalance = COMP.balanceOf(address(this));
        if (compBalance == 0) {
            return;
        }

        COMP.approve(address(router), compBalance);
        router.exactInput(
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(
                    COMP,
                    uint24(10000),
                    WETH,
                    uint24(500),
                    USDC
                ),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: compBalance,
                amountOutMinimum: 0
            })
        );
    }

    function _withdrawFunds() internal override {
        withdrawERC20(DAI);
        withdrawERC20(USDC);
    }

    bool readyForCallback = false;

    modifier call() {
        readyForCallback = true;
        _;
        readyForCallback = false;
    }
    modifier callback() {
        require(readyForCallback, "Call first");
        _;
    }
}

interface ICErc20 is IERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}

interface IComptroller {
    function oracle() external view returns (IPriceOracle);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function claimComp(address holder) external;
}

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params)
        external
        returns (uint256 amountOut);
}

interface IPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}