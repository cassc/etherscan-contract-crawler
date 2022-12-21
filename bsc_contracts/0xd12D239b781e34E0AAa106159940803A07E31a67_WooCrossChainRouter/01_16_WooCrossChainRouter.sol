// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./interfaces/IWooRouterV2.sol";
import "./interfaces/IWETH.sol";

import "./interfaces/Stargate/IStargateRouter.sol";
import "./interfaces/Stargate/IStargateReceiver.sol";

import "./libraries/TransferHelper.sol";

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @title Woo Router implementation.
/// @notice Router for stateless execution of swaps against Woo private pool.
/// Ref links:
/// chain id: https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
/// poold id: https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
contract WooCrossChainRouter is IStargateReceiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event WooCrossSwapOnSrcChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address fromToken,
        uint256 fromAmount,
        uint256 minQuoteAmount,
        uint256 realQuoteAmount
    );

    event WooCrossSwapOnDstChain(
        uint256 indexed refId,
        address indexed sender,
        address indexed to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        address realToToken,
        uint256 minToAmount,
        uint256 realToAmount
    );

    address constant ETH_PLACEHOLDER_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IStargateRouter public stargateRouter;
    IWooRouterV2 public wooRouter;
    address public quoteToken;
    address public WETH;
    uint256 public bridgeSlippage; // 1 in 10000th: default 1%
    uint256 public dstGasForSwapCall;
    uint256 public dstGasForNoSwapCall;

    mapping(uint16 => address) public wooCrossRouters; // dstChainId => woo router
    mapping(uint16 => uint256) public quotePoolIds; // chainId => woofi_quote_token_pool_id
    mapping(uint16 => address) public wooppQuoteTokens; // dstChainId => wooPP quote token

    receive() external payable {}

    constructor(
        address _weth,
        address _wooRouter,
        address _stargateRouter
    ) {
        WETH = _weth;
        wooRouter = IWooRouterV2(_wooRouter);
        quoteToken = wooRouter.wooPool().quoteToken();
        stargateRouter = IStargateRouter(_stargateRouter);

        bridgeSlippage = 100;

        dstGasForSwapCall = 360000;
        dstGasForNoSwapCall = 80000;

        // usdc: 1, usdt: 2, busd: 5
        quotePoolIds[101] = 1; // ethereum: usdc
        quotePoolIds[102] = 2; // BSC: usdt
        quotePoolIds[106] = 1; // Avalanche: usdc
        quotePoolIds[109] = 1; // Polygon: usdc
        quotePoolIds[110] = 1; // Arbitrum: usdc
        quotePoolIds[111] = 1; // Optimism: usdc
        quotePoolIds[112] = 1; // Fantom: usdc

        wooppQuoteTokens[101] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // ETH_main: usdc
        wooppQuoteTokens[102] = address(0x55d398326f99059fF775485246999027B3197955); // bsc_wooPP: usdt
        wooppQuoteTokens[106] = address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E); // avax_wooPP: usdc
        wooppQuoteTokens[109] = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // Polygon: usdc
        wooppQuoteTokens[110] = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); // Arbitrum: usdc
        wooppQuoteTokens[111] = address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607); // Optimism: usdc
        wooppQuoteTokens[112] = address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // ftm_wooPP: usdc
    }

    function setWooppQuoteTokens(uint16 _chainId, address _token) public onlyOwner {
        wooppQuoteTokens[_chainId] = _token;
    }

    /*
    https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
        - Chain ID : Chain -
        1: Ether
        2: BSC (BNB Chain)
        6: Avalanche
        9: Polygon
        10: Arbitrum
        11: Optimism
        12: Fantom
    */
    function setWooCrossChainRouter(uint16 _chainId, address _wooCrossRouter) external onlyOwner {
        require(_wooCrossRouter != address(0), "WooCrossChainRouter: !wooCrossRouter");
        wooCrossRouters[_chainId] = _wooCrossRouter;
    }

    function setStargateRouter(address _stargateRouter) external onlyOwner {
        require(_stargateRouter != address(0), "WooCrossChainRouter: !stargateRouter");
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function setWooRouter(address _wooRouter) external onlyOwner {
        wooRouter = IWooRouterV2(_wooRouter);
    }

    function setBridgeSlippage(uint256 _bridgeSlippage) external onlyOwner {
        require(_bridgeSlippage <= 10000, "WooCrossChainRouter: !_bridgeSlippage");
        bridgeSlippage = _bridgeSlippage;
    }

    function setDstGasForSwapCall(uint256 _dstGasForSwapCall) external onlyOwner {
        dstGasForSwapCall = _dstGasForSwapCall;
    }

    function setDstGasForNoSwapCall(uint256 _dstGasForNoSwapCall) external onlyOwner {
        dstGasForNoSwapCall = _dstGasForNoSwapCall;
    }

    function setQuotePoolId(uint16 _chainId, uint256 _quotePoolId) external onlyOwner {
        quotePoolIds[_chainId] = _quotePoolId;
    }

    function crossSwap(
        uint256 refId_,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 srcMinQuoteAmount,
        uint256 dstMinToAmount,
        uint16 srcChainId,
        uint16 dstChainId,
        address payable to
    ) external payable {
        require(fromToken != address(0), "WooCrossChainRouter: !fromToken");
        require(toToken != address(0), "WooCrossChainRouter: !toToken");
        require(to != address(0), "WooCrossChainRouter: !to");

        uint256 gasValue = msg.value;
        uint256 refId = refId_; // NOTE: to avoid stack too deep issue

        // Step 1: transfer
        {
            bool isFromETH = fromToken == ETH_PLACEHOLDER_ADDR;
            fromToken = isFromETH ? WETH : fromToken;
            if (isFromETH) {
                require(fromAmount <= msg.value, "WooCrossChainRouter: !fromAmount");
                IWETH(WETH).deposit{value: fromAmount}();
                gasValue -= fromAmount;
            } else {
                TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
            }
        }

        // Step 2: local transfer
        uint256 bridgeAmount;
        if (fromToken != quoteToken) {
            TransferHelper.safeApprove(fromToken, address(wooRouter), fromAmount);
            bridgeAmount = wooRouter.swap(
                fromToken,
                quoteToken,
                fromAmount,
                srcMinQuoteAmount,
                payable(address(this)),
                to
            );
        } else {
            bridgeAmount = fromAmount;
        }

        // Step 3: send to stargate
        require(bridgeAmount <= IERC20(quoteToken).balanceOf(address(this)), "!bridgeAmount");
        TransferHelper.safeApprove(quoteToken, address(stargateRouter), bridgeAmount);

        require(to != address(0), "WooCrossChainRouter: to_ZERO_ADDR"); // NOTE: double check it
        {
            bytes memory payloadData;
            payloadData = abi.encode(
                toToken, // to token
                refId, // reference id
                dstMinToAmount, // minToAmount on destination chain
                to // to address
            );

            bytes memory dstWooCrossRouter = abi.encodePacked(wooCrossRouters[dstChainId]);
            uint256 minBridgeAmount = (bridgeAmount * (uint256(10000) - bridgeSlippage)) / 10000;
            uint256 dstGas = (toToken == wooppQuoteTokens[dstChainId]) ? dstGasForNoSwapCall : dstGasForSwapCall;

            stargateRouter.swap{value: gasValue}(
                dstChainId, // dst chain id
                quotePoolIds[srcChainId], // quote token's pool id on dst chain
                quotePoolIds[dstChainId], // quote token's pool id on src chain
                payable(msg.sender), // rebate address
                bridgeAmount, // swap amount on src chain
                minBridgeAmount, // min received amount on dst chain
                IStargateRouter.lzTxObj(dstGas, 0, "0x"), // config: dstGas, dstNativeToken, dstNativeTokenToAddress
                dstWooCrossRouter, // smart contract to call on dst chain
                payloadData // payload to piggyback
            );
        }

        emit WooCrossSwapOnSrcChain(refId, msg.sender, to, fromToken, fromAmount, srcMinQuoteAmount, bridgeAmount);
    }

    function quoteLayerZeroFee(
        uint16 dstChainId,
        address toToken,
        uint256 refId,
        uint256 dstMinToAmount,
        address to
    ) external view returns (uint256, uint256) {
        bytes memory toAddress = abi.encodePacked(to);
        bytes memory payloadData = abi.encode(
            toToken, // to token
            refId, // reference id
            dstMinToAmount, // minToAmount on destination chain
            to // to address
        );
        uint256 dstGas = (toToken == wooppQuoteTokens[dstChainId]) ? dstGasForNoSwapCall : dstGasForSwapCall;
        return
            stargateRouter.quoteLayerZeroFee(
                dstChainId,
                1, // https://stargateprotocol.gitbook.io/stargate/developers/function-types
                toAddress,
                payloadData,
                IStargateRouter.lzTxObj(dstGas, 0, "0x")
            );
    }

    function sgReceive(
        uint16, /*_chainId*/
        bytes memory, /*_srcAddress*/
        uint256, /*_nonce*/
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        require(msg.sender == address(stargateRouter), "WooCrossChainRouter: INVALID_CALLER");

        (address toToken, uint256 refId, uint256 minToAmount, address to) = abi.decode(
            payload,
            (address, uint256, uint256, address)
        );

        if (wooRouter.wooPool().quoteToken() != _token) {
            // NOTE: The bridged token is not WooPP's quote token.
            // So Cannot do the swap; just return it to users.
            TransferHelper.safeTransfer(_token, to, amountLD);
            emit WooCrossSwapOnDstChain(
                refId,
                msg.sender,
                to,
                _token,
                amountLD,
                toToken,
                _token,
                minToAmount,
                amountLD
            );
            return;
        }

        uint256 quoteAmount = amountLD;

        if (toToken == ETH_PLACEHOLDER_ADDR) {
            // quoteToken -> WETH -> ETH
            TransferHelper.safeApprove(_token, address(wooRouter), quoteAmount);
            try wooRouter.swap(_token, WETH, quoteAmount, minToAmount, payable(address(this)), to) returns (
                uint256 realToAmount
            ) {
                IWETH(WETH).withdraw(realToAmount);
                TransferHelper.safeTransferETH(to, realToAmount);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    _token,
                    amountLD,
                    toToken,
                    ETH_PLACEHOLDER_ADDR,
                    minToAmount,
                    realToAmount
                );
            } catch {
                // transfer _token/amountLD to msg.sender because the swap failed for some reason.
                // this is not the ideal scenario, but the contract needs to deliver them eth or USDC.
                TransferHelper.safeTransfer(_token, to, amountLD);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    _token,
                    amountLD,
                    toToken,
                    _token,
                    minToAmount,
                    amountLD
                );
            }
        } else {
            if (_token == toToken) {
                // Stargate bridged token == toToken: NO swap is needed!
                TransferHelper.safeTransfer(toToken, to, amountLD);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msg.sender,
                    to,
                    _token,
                    amountLD,
                    toToken,
                    toToken,
                    minToAmount,
                    amountLD
                );
            } else {
                // swap to the ERC20 token
                TransferHelper.safeApprove(_token, address(wooRouter), quoteAmount);
                try wooRouter.swap(_token, toToken, quoteAmount, minToAmount, payable(to), to) returns (
                    uint256 realToAmount
                ) {
                    emit WooCrossSwapOnDstChain(
                        refId,
                        msg.sender,
                        to,
                        _token,
                        amountLD,
                        toToken,
                        toToken,
                        minToAmount,
                        realToAmount
                    );
                } catch {
                    TransferHelper.safeTransfer(_token, to, amountLD);
                    emit WooCrossSwapOnDstChain(
                        refId,
                        msg.sender,
                        to,
                        _token,
                        amountLD,
                        toToken,
                        _token,
                        minToAmount,
                        amountLD
                    );
                }
            }
        }
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        if (stuckToken == ETH_PLACEHOLDER_ADDR) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }
}