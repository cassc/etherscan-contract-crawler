// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

// Valid targets
// BNB 102 2 (USDT)
// Avalanche 106 1
// Polygon 109 1
// Arbitrum 110 1
// Optimisim 111 1
// Fantom 112 1

contract TSAggregatorStargate is TSAggregator {
    using SafeTransferLib for address;

    IStargateRouter public stargate;
    IUniswapRouterV2 public router;
    IWETH9 public weth;
    IERC20 public bridgeToken;
    IOracle public ethOracle;
    address public targetContract;
    uint256 public sourcePoolId = 1;
    uint256 public targetPoolId = 1;
    uint16 public targetChainId = 109;

    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(
        address _ttp,
        address _stargate,
        address _router,
        address _bridgeToken,
        address _ethOracle,
        address _targetContract
    ) TSAggregator(_ttp) {
        stargate = IStargateRouter(_stargate);
        router = IUniswapRouterV2(_router);
        weth = IWETH9(router.WETH());
        bridgeToken = IERC20(_bridgeToken);
        ethOracle = IOracle(_ethOracle);
        targetContract = _targetContract;
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        bytes memory data = abi.encode(token, to, amountOutMin);
        uint256 amount = skimFee(msg.value);
        (uint256 fee,) =
            stargate.quoteLayerZeroFee(targetChainId, uint8(1), abi.encodePacked(targetContract), data, txObj);

        {
            uint256 price = uint256(ethOracle.latestAnswer()) * 1e18 / ethOracle.decimals();
            uint256 minAmtOut = ((amount - fee) * 99 / 100) * (10 ** bridgeToken.decimals()) / price;
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(bridgeToken);
            router.swapExactETHForTokens{value: amount - fee}(minAmtOut, path, address(this), type(uint256).max);
        }

        uint256 tokenAmount = bridgeToken.balanceOf(address(this));
        bridgeToken.approve(address(stargate), tokenAmount);
        stargate.swap{value: fee}(
            targetChainId,
            sourcePoolId,
            targetPoolId,
            payable(to),
            tokenAmount,
            tokenAmount * 99 / 100,
            txObj,
            abi.encodePacked(targetContract),
            data
        );

        emit SwapOut(to, token, msg.value, msg.value - amount);
    }
}