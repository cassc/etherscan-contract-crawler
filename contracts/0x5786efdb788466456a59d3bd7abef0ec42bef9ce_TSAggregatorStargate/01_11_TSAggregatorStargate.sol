// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IThorchainRouter} from "./interfaces/IThorchainRouter.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

contract TSAggregatorStargate is TSAggregator {
    error NotAConfiguredToken();

    using SafeTransferLib for address;

    struct TokenConfig {
        uint256 chainId;
        address token;
        address router;
        address[] path;
    }

    IStargateRouter public stargate;
    IUniswapRouterV2 public router;
    IERC20 public bridgeToken;
    IOracle public ethOracle;
    uint256 public slippage = 100;
    uint256 public sourcePoolId = 1;
    mapping(uint256 => uint256) public chainTargetPoolId;
    mapping(uint256 => address) public chainTargetContract;
    mapping(uint256 => TokenConfig) public tokens;

    event SetTokenConfig(uint256 indexed id, uint256 chainId, address token, address router, address[] path);
    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(address _stargate, address _router, address _bridgeToken, address _ethOracle)
        TSAggregator(address(0))
    {
        stargate = IStargateRouter(_stargate);
        router = IUniswapRouterV2(_router);
        bridgeToken = IERC20(_bridgeToken);
        ethOracle = IOracle(_ethOracle);
        chainTargetPoolId[102] = 2; // BNB (USDT)
        chainTargetPoolId[106] = 1; // Avalanche
        chainTargetPoolId[109] = 1; // Polygon
        chainTargetPoolId[110] = 1; // Arbitrum
        chainTargetPoolId[111] = 1; // Optimism
        chainTargetPoolId[112] = 1; // Fantom
    }

    function setSlippage(uint256 _slippage) external isOwner {
        slippage = _slippage;
    }

    function setChainTargetContract(uint256 chainId, address targetContract) external isOwner {
        chainTargetContract[chainId] = targetContract;
    }

    function setChainTargetPoolId(uint256 chainId, uint256 poolId) external isOwner {
        chainTargetPoolId[chainId] = poolId;
    }

    function setTokenConfig(uint256 id, uint256 chainId, address token, address router, address[] calldata path) external isOwner {
        tokens[id] = TokenConfig({chainId: chainId, token: token, router: router, path: path});
        emit SetTokenConfig(id, chainId, token, router, path);
    }

    function sgReceive(uint16, bytes memory, uint256, address bridgeToken, uint256 bridgeAmount, bytes memory payload)
        external
    {
        require(msg.sender == address(stargate), "!stargate");
        (address tcRouter, address vault, string memory memo, address from, uint256 deadline) =
            abi.decode(payload, (address, address, string, address, uint256));
        uint256 price = uint256(ethOracle.latestAnswer()) * 1e18 / ethOracle.decimals();
        uint256 minAmtOut = _slip(bridgeAmount) * (10 ** IERC20(bridgeToken).decimals()) / price;
        IERC20(bridgeToken).approve(address(router), bridgeAmount);
        address[] memory path = new address[](2);
        path[0] = bridgeToken;
        path[1] = router.WETH();
        try router.swapExactTokensForETH(bridgeAmount, minAmtOut, path, address(this), deadline) {
            uint256 out = address(this).balance;
            uint256 outMinusFee = skimFee(out);
            IThorchainRouter(tcRouter).depositWithExpiry{value: outMinusFee}(
                payable(vault), address(0), outMinusFee, memo, deadline
            );
            emit SwapIn(msg.sender, bridgeToken, bridgeAmount, out, out - outMinusFee, vault, memo);
        } catch {
            IERC20(bridgeToken).transfer(from, bridgeAmount);
        }
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        TokenConfig memory tokenConfig = tokens[amountOutMin % 1000];
        if (tokenConfig.token == address(0)) revert NotAConfiguredToken();
        bytes memory data = abi.encode(tokenConfig.token, tokenConfig.router, tokenConfig.path, to, amountOutMin);

        address targetContract = chainTargetContract[tokenConfig.chainId];
        uint256 amount = skimFee(msg.value);
        (uint256 fee,) = stargate.quoteLayerZeroFee(
            uint16(tokenConfig.chainId), uint8(1), abi.encodePacked(targetContract), data, txObj
        );

        {
            uint256 price = uint256(ethOracle.latestAnswer()) * 1e18 / ethOracle.decimals();
            uint256 minAmtOut = _slip(amount - fee) * (10 ** bridgeToken.decimals()) / price;
            address[] memory path = new address[](2);
            path[0] = address(router.WETH());
            path[1] = address(bridgeToken);
            router.swapExactETHForTokens{value: amount - fee}(minAmtOut, path, address(this), type(uint256).max);
        }

        uint256 tokenAmount = bridgeToken.balanceOf(address(this));
        bridgeToken.approve(address(stargate), tokenAmount);
        stargate.swap{value: fee}(
            uint16(tokenConfig.chainId),
            sourcePoolId,
            chainTargetPoolId[tokenConfig.chainId],
            payable(to),
            tokenAmount,
            _slip(tokenAmount),
            txObj,
            abi.encodePacked(targetContract),
            data
        );

        emit SwapOut(to, token, msg.value, msg.value - amount);
    }

    function _slip(uint256 amount) internal view returns (uint256) {
        return amount * (10000 - slippage) / 10000;
    }
}