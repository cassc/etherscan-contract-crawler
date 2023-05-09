// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "DEXBase.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract ParaSwapACLForBots is DEXBase {
    string public constant override NAME = "ParaSwapACLForBots";
    uint256 public constant override VERSION = 2;

    // For https://polygonscan.com/address/0xdef171fe48cf0115b1d80b88dc8eab59176fee57

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 constant DIRECTION_FLAG = 0x0000000000000000000000010000000000000000000000000000000000000000;

    address public WETH;

    address public UNISWAP_FACTORY;

    bytes32 public UNISWAP_INIT_CODE;

    address public ZEROV2_EXCHANGE;

    address public ZEROV4_EXCHANGE;

    // Internal functions.

    function getTokenAddress(address token) internal view returns (address) {
        return token == ETH_ADDRESS ? WETH : token;
    }

    function checkBeneficiary(address to) internal view {
        require(to == address(0) || to == safeAddress, "Invalid beneficiary");
    }

    // Setters.
    function setWETH(address weth) external onlySafe {
        WETH = weth;
    }

    function setFACTORY(address factory) external onlySafe {
        UNISWAP_FACTORY = factory;
    }

    function setINITCODE(bytes32 initCode) external onlySafe {
        UNISWAP_INIT_CODE = initCode;
    }

    function setZEROEXCHANGE(address v2exchange, address v4exchange) external onlySafe {
        ZEROV2_EXCHANGE = v2exchange;
        ZEROV4_EXCHANGE = v4exchange;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    // ACL functions.

    // https://polygonscan.com/address/0x2674a5e9FDDCD775B466C312441942bD5278E513#code
    function simpleSwap(SimpleData calldata data) external view {
        address inToken = getTokenAddress(data.fromToken);
        address outToken = getTokenAddress(data.toToken);
        swapInOutTokenCheck(inToken, outToken);
        checkBeneficiary(data.beneficiary);
    }

    function simpleBuy(SimpleData calldata data) external view {
        address inToken = getTokenAddress(data.fromToken);
        address outToken = getTokenAddress(data.toToken);
        swapInOutTokenCheck(inToken, outToken);
        checkBeneficiary(data.beneficiary);
    }

    // https://polygonscan.com/address/0x7719CC060A3348229DB764c9464B7738E4172e19#code
    function multiSwap(SellData calldata data) external view {
        address inToken = getTokenAddress(data.fromToken);
        address outToken = getTokenAddress(data.path[data.path.length - 1].to);
        swapInOutTokenCheck(inToken, outToken);
        checkBeneficiary(data.beneficiary);
    }

    function megaSwap(MegaSwapSellData calldata data) external view {
        address inToken = getTokenAddress(data.fromToken);
        MegaSwapPath[] memory path = data.path;
        address toToken = path[0].path[path[0].path.length - 1].to;
        address outToken = getTokenAddress(toToken);
        swapInOutTokenCheck(inToken, outToken);
        checkBeneficiary(data.beneficiary);
    }

    // https://polygonscan.com/address/0x90249ed4d69D70E709fFCd8beE2c5A566f65dADE#code
    function swapOnUniswap(uint256 amountIn, uint256 amountOutMin, address[] calldata path) external view {
        address inToken = getTokenAddress(path[0]);
        address outToken = getTokenAddress(path[path.length - 1]);
        swapInOutTokenCheck(inToken, outToken);
    }

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external view {
        // check factory,initCode
        require(factory == UNISWAP_FACTORY, "FACTORY not allowed");
        require(initCode == UNISWAP_INIT_CODE, "NIT_CODE not allowed");
        address inToken = getTokenAddress(path[0]);
        address outToken = getTokenAddress(path[path.length - 1]);
        swapInOutTokenCheck(inToken, outToken);
    }

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    ) external view {
        require(weth == WETH, "WETH not allowed");
        address inToken = getTokenAddress(tokenIn);
        uint256 lastPool = pools[pools.length - 1];
        address lastPair = address(uint160(lastPool));
        bool direction = lastPool & DIRECTION_FLAG == 0;
        address outToken = direction ? IUniswapV2Pair(lastPair).token1() : IUniswapV2Pair(lastPair).token0();
        swapInOutTokenCheck(inToken, outToken);
    }

    function swapOnZeroXv2(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    ) external view {
        require(exchange == ZEROV2_EXCHANGE, "ZEROV2_EXCHANGE not allowed");
        address inToken = getTokenAddress(fromToken);
        address outToken = getTokenAddress(toToken);
        swapInOutTokenCheck(inToken, outToken);
    }

    function swapOnZeroXv4(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    ) external view {
        require(exchange == ZEROV4_EXCHANGE, "ZEROV4_EXCHANGE not allowed");
        address inToken = getTokenAddress(fromToken);
        address outToken = getTokenAddress(toToken);
        swapInOutTokenCheck(inToken, outToken);
    }
}