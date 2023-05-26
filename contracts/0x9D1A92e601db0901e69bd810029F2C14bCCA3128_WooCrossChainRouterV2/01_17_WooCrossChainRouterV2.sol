// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

// OpenZeppelin Contracts
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ICommonOFT, IOFTWithFee} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/IOFTWithFee.sol";

// Local Contracts
import {IWETH} from "./interfaces/IWETH.sol";
import {IWooCrossChainRouterV2} from "./interfaces/IWooCrossChainRouterV2.sol";
import {IWooRouterV2} from "./interfaces/IWooRouterV2.sol";
import {IStargateEthVault} from "./interfaces/Stargate/IStargateEthVault.sol";
import {IStargateRouter} from "./interfaces/Stargate/IStargateRouter.sol";
import {ILzApp} from "./interfaces/LayerZero/ILzApp.sol";

import {TransferHelper} from "./libraries/TransferHelper.sol";

/// @title WOOFi cross chain router implementation.
/// @notice Router for stateless execution of cross chain swap against WOOFi private pool.
/// @custom:stargate-contracts https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
contract WooCrossChainRouterV2 is IWooCrossChainRouterV2, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ----- Constants ----- */

    address public constant ETH_PLACEHOLDER_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ----- Variables ----- */

    IWooRouterV2 public wooRouter;
    IStargateRouter public stargateRouter;

    address public immutable weth;
    uint256 public bridgeSlippage; // 1 in 10000th: default 1%
    uint256 public dstGasForSwapCall;
    uint256 public dstGasForNoSwapCall;

    uint16 public sgChainIdLocal; // Stargate chainId on local chain

    mapping(uint16 => address) public wooCrossChainRouters; // chainId => WooCrossChainRouter address
    mapping(uint16 => address) public sgETHs; // chainId => SGETH token address
    mapping(uint16 => mapping(address => uint256)) public sgPoolIds; // chainId => token address => Stargate poolId

    mapping(address => address) public tokenToOFTs; // token address(sgChainIdLocal) => OFT address

    EnumerableSet.AddressSet private directBridgeTokens;

    receive() external payable {}

    constructor(
        address _weth,
        address _wooRouter,
        address _stargateRouter,
        uint16 _sgChainIdLocal
    ) {
        wooRouter = IWooRouterV2(_wooRouter);
        stargateRouter = IStargateRouter(_stargateRouter);

        weth = _weth;
        bridgeSlippage = 100;
        dstGasForSwapCall = 360000;
        dstGasForNoSwapCall = 80000;

        sgChainIdLocal = _sgChainIdLocal;

        _initSgETHs();
        _initSgPoolIds();
        _initTokenToOFTs(_sgChainIdLocal);
    }

    /* ----- Functions ----- */

    function crossSwap(
        uint256 refId,
        address payable to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external payable nonReentrant {
        require(srcInfos.fromToken != address(0), "WooCrossChainRouterV2: !srcInfos.fromToken");
        require(
            dstInfos.toToken != address(0) && dstInfos.toToken != sgETHs[dstInfos.chainId],
            "WooCrossChainRouterV2: !dstInfos.toToken"
        );
        require(to != address(0), "WooCrossChainRouterV2: !to");

        uint256 msgValue = msg.value;
        uint256 bridgeAmount;

        {
            // Step 1: transfer
            if (srcInfos.fromToken == ETH_PLACEHOLDER_ADDR) {
                require(srcInfos.fromAmount <= msgValue, "WooCrossChainRouterV2: !srcInfos.fromAmount");
                srcInfos.fromToken = weth;
                IWETH(weth).deposit{value: srcInfos.fromAmount}();
                msgValue -= srcInfos.fromAmount;
            } else {
                TransferHelper.safeTransferFrom(srcInfos.fromToken, msg.sender, address(this), srcInfos.fromAmount);
            }

            // Step 2: local swap by WooRouter or not
            // 1.WOO is directBridgeToken, path(always) WOO(Arbitrum) => WOO(BSC)
            // 2.WOO not the directBridgeToken, path(maybe): WOO(Arbitrum) -> USDC(Arbitrum) => BUSD(BSC) -> WOO(BSC)
            // 3.Ethereum no WOOFi liquidity, tokens(WOO, ETH, USDC) always will be bridged directly without swap
            if (!directBridgeTokens.contains(srcInfos.fromToken) && srcInfos.fromToken != srcInfos.bridgeToken) {
                TransferHelper.safeApprove(srcInfos.fromToken, address(wooRouter), srcInfos.fromAmount);
                bridgeAmount = wooRouter.swap(
                    srcInfos.fromToken,
                    srcInfos.bridgeToken,
                    srcInfos.fromAmount,
                    srcInfos.minBridgeAmount,
                    payable(address(this)),
                    to
                );
            } else {
                require(
                    srcInfos.fromAmount == srcInfos.minBridgeAmount,
                    "WooCrossChainRouterV2: !srcInfos.minBridgeAmount"
                );
                bridgeAmount = srcInfos.fromAmount;
            }

            require(
                bridgeAmount <= IERC20(srcInfos.bridgeToken).balanceOf(address(this)),
                "WooCrossChainRouterV2: !bridgeAmount"
            );
        }

        // Step 3: cross chain swap by [OFT / StargateRouter]
        address oft = tokenToOFTs[srcInfos.bridgeToken];
        if (oft != address(0)) {
            _bridgeByOFT(refId, to, msgValue, bridgeAmount, IOFTWithFee(oft), srcInfos, dstInfos);
        } else {
            _bridgeByStargate(refId, to, msgValue, bridgeAmount, srcInfos, dstInfos);
        }

        emit WooCrossSwapOnSrcChain(
            refId,
            _msgSender(),
            to,
            srcInfos.fromToken,
            srcInfos.fromAmount,
            srcInfos.minBridgeAmount,
            bridgeAmount
        );
    }

    function onOFTReceived(
        uint16 srcChainId,
        bytes memory, // srcAddress
        uint64, // nonce
        bytes32 from,
        uint256 amountLD,
        bytes memory payload
    ) external {
        require(_isLegitOFT(_msgSender()), "WooCrossChainRouterV2: INVALID_CALLER");
        require(
            wooCrossChainRouters[srcChainId] == address(uint160(uint256(from))),
            "WooCrossChainRouterV2: INVALID_FROM"
        );

        // _msgSender() should be OFT address if requires above are passed
        address bridgedToken = IOFTWithFee(_msgSender()).token();

        // make sure the same order to abi.encode when decode payload
        (uint256 refId, address to, address toToken, uint256 minToAmount) = abi.decode(
            payload,
            (uint256, address, address, uint256)
        );

        _handleERC20Received(refId, to, toToken, bridgedToken, amountLD, minToAmount);
    }

    function sgReceive(
        uint16, // srcChainId
        bytes memory, // srcAddress
        uint256, // nonce
        address bridgedToken,
        uint256 amountLD,
        bytes memory payload
    ) external {
        require(msg.sender == address(stargateRouter), "WooCrossChainRouterV2: INVALID_CALLER");

        // make sure the same order to abi.encode when decode payload
        (uint256 refId, address to, address toToken, uint256 minToAmount) = abi.decode(
            payload,
            (uint256, address, address, uint256)
        );

        // toToken won't be SGETH, and bridgedToken won't be ETH_PLACEHOLDER_ADDR
        if (bridgedToken == sgETHs[sgChainIdLocal]) {
            // bridgedToken is SGETH, received native token
            _handleNativeReceived(refId, to, toToken, amountLD, minToAmount);
        } else {
            // bridgedToken is not SGETH, received ERC20 token
            _handleERC20Received(refId, to, toToken, bridgedToken, amountLD, minToAmount);
        }
    }

    function quoteLayerZeroFee(
        uint256 refId,
        address to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) external view returns (uint256, uint256) {
        bytes memory payload = abi.encode(refId, to, dstInfos.toToken, dstInfos.minToAmount);

        address oft = tokenToOFTs[srcInfos.bridgeToken];
        if (oft != address(0)) {
            // bridge via OFT if it's OFT
            uint256 dstGasForCall = _getDstGasForCall(dstInfos);
            bytes memory adapterParams = _getAdapterParams(to, oft, dstGasForCall, dstInfos);

            bool useZro = false;
            bytes32 dstWooCrossChainRouter = bytes32(uint256(uint160(wooCrossChainRouters[dstInfos.chainId])));

            return
                IOFTWithFee(oft).estimateSendAndCallFee(
                    dstInfos.chainId,
                    dstWooCrossChainRouter,
                    srcInfos.minBridgeAmount,
                    payload,
                    uint64(dstGasForCall),
                    useZro,
                    adapterParams
                );
        } else {
            // otherwise bridge via Stargate
            IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);

            return
                stargateRouter.quoteLayerZeroFee(
                    dstInfos.chainId,
                    1, // https://stargateprotocol.gitbook.io/stargate/developers/function-types
                    obj.dstNativeAddr,
                    payload,
                    obj
                );
        }
    }

    function allDirectBridgeTokens() external view returns (address[] memory) {
        uint256 length = directBridgeTokens.length();
        address[] memory tokens = new address[](length);
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tokens[i] = directBridgeTokens.at(i);
            }
        }
        return tokens;
    }

    function allDirectBridgeTokensLength() external view returns (uint256) {
        return directBridgeTokens.length();
    }

    function _initSgETHs() internal {
        // Ethereum
        sgETHs[101] = 0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c;
        // Arbitrum
        sgETHs[110] = 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0;
        // Optimism
        sgETHs[111] = 0xb69c8CBCD90A39D8D3d3ccf0a3E968511C3856A0;
    }

    function _initSgPoolIds() internal {
        // poolId > 0 means able to be bridge token
        // Ethereum
        sgPoolIds[101][0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 1; // USDC
        sgPoolIds[101][0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 13; // WETH
        sgPoolIds[101][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // BNB Chain
        sgPoolIds[102][0x55d398326f99059fF775485246999027B3197955] = 2; // USDT
        sgPoolIds[102][0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = 5; // BUSD
        sgPoolIds[102][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // Avalanche
        sgPoolIds[106][0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E] = 1; // USDC
        sgPoolIds[106][0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7] = 2; // USDT
        sgPoolIds[106][0xaBC9547B534519fF73921b1FBA6E672b5f58D083] = 20; // WOO
        // Polygon
        sgPoolIds[109][0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 1; // USDC
        sgPoolIds[109][0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = 2; // USDT
        sgPoolIds[109][0x1B815d120B3eF02039Ee11dC2d33DE7aA4a8C603] = 20; // WOO
        // Arbitrum
        sgPoolIds[110][0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 1; // USDC
        sgPoolIds[110][0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 2; // USDT
        sgPoolIds[110][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 13; // WETH
        sgPoolIds[110][0xcAFcD85D8ca7Ad1e1C6F82F651fA15E33AEfD07b] = 20; // WOO
        // Optimism
        sgPoolIds[111][0x7F5c764cBc14f9669B88837ca1490cCa17c31607] = 1; // USDC
        sgPoolIds[111][0x4200000000000000000000000000000000000006] = 13; // WETH
        sgPoolIds[111][0x871f2F2ff935FD1eD867842FF2a7bfD051A5E527] = 20; // WOO
        // Fantom
        sgPoolIds[112][0x04068DA6C83AFCFA0e13ba15A6696662335D5B75] = 1; // USDC
        sgPoolIds[112][0x6626c47c00F1D87902fc13EECfaC3ed06D5E8D8a] = 20; // WOO
    }

    function _initTokenToOFTs(uint16 _sgChainIdLocal) internal {
        address btcbOFT = 0x2297aEbD383787A160DD0d9F71508148769342E3; // BTCbOFT && BTCbProxyOFT

        if (_sgChainIdLocal == 106) {
            // BTC.b(ERC20) on Avalanche address
            tokenToOFTs[0x152b9d0FdC40C096757F570A51E494bd4b943E50] = btcbOFT;
        }
        tokenToOFTs[btcbOFT] = btcbOFT;
    }

    function _getDstGasForCall(DstInfos memory dstInfos) internal view returns (uint256) {
        return (dstInfos.toToken == dstInfos.bridgeToken) ? dstGasForNoSwapCall : dstGasForSwapCall;
    }

    function _getAdapterParams(
        address to,
        address oft,
        uint256 dstGasForCall,
        DstInfos memory dstInfos
    ) internal view returns (bytes memory) {
        // OFT src logic: require(providedGasLimit >= minGasLimit)
        // uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + dstGasForCall;
        // _type: 0(send), 1(send_and_call)
        uint256 providedGasLimit = ILzApp(oft).minDstGasLookup(dstInfos.chainId, 1) + dstGasForCall;

        // https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters#airdrop
        return
            abi.encodePacked(
                uint16(2), // version: 2 is able to airdrop native token on destination but 1 is not
                providedGasLimit, // gasAmount: destination transaction gas for LayerZero to delivers
                dstInfos.airdropNativeAmount, // nativeForDst: airdrop native token amount
                to // addressOnDst: address to receive airdrop native token on destination
            );
    }

    function _getLzTxObj(address to, DstInfos memory dstInfos) internal view returns (IStargateRouter.lzTxObj memory) {
        uint256 dstGasForCall = _getDstGasForCall(dstInfos);

        return IStargateRouter.lzTxObj(dstGasForCall, dstInfos.airdropNativeAmount, abi.encodePacked(to));
    }

    function _isLegitOFT(address caller) internal view returns (bool) {
        return tokenToOFTs[caller] != address(0);
    }

    function _bridgeByOFT(
        uint256 refId,
        address payable to,
        uint256 msgValue,
        uint256 bridgeAmount,
        IOFTWithFee oft,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) internal {
        {
            address token = oft.token();
            require(token == srcInfos.bridgeToken, "WooCrossChainRouterV2: !token");
            if (token != address(oft)) {
                // oft.token() != address(oft) means is a ProxyOFT
                // for example: BTC.b on Avalanche is ERC20, need BTCbProxyOFT to lock up BTC.b
                TransferHelper.safeApprove(srcInfos.bridgeToken, address(oft), bridgeAmount);
            }
        }

        // OFT src logic: require(_removeDust(bridgeAmount) >= minAmount)
        uint256 minAmount = (bridgeAmount * (10000 - bridgeSlippage)) / 10000;

        bytes memory payload = abi.encode(refId, to, dstInfos.toToken, dstInfos.minToAmount);

        uint256 dstGasForCall = _getDstGasForCall(dstInfos);
        ICommonOFT.LzCallParams memory callParams;
        {
            bytes memory adapterParams = _getAdapterParams(to, address(oft), dstGasForCall, dstInfos);
            callParams = ICommonOFT.LzCallParams(
                payable(msg.sender), // refundAddress
                address(0), // zroPaymentAddress
                adapterParams //adapterParams
            );
        }

        bytes32 dstWooCrossChainRouter = bytes32(uint256(uint160(wooCrossChainRouters[dstInfos.chainId])));

        oft.sendAndCall{value: msgValue}(
            address(this),
            dstInfos.chainId,
            dstWooCrossChainRouter,
            bridgeAmount,
            minAmount,
            payload,
            uint64(dstGasForCall),
            callParams
        );
    }

    function _bridgeByStargate(
        uint256 refId,
        address payable to,
        uint256 msgValue,
        uint256 bridgeAmount,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos
    ) internal {
        uint256 srcPoolId = sgPoolIds[sgChainIdLocal][srcInfos.bridgeToken];
        require(srcPoolId > 0, "WooCrossChainRouterV2: !srcInfos.bridgeToken");

        uint256 dstPoolId = sgPoolIds[dstInfos.chainId][dstInfos.bridgeToken];
        require(dstPoolId > 0, "WooCrossChainRouterV2: !dstInfos.bridgeToken");

        bytes memory payload = abi.encode(refId, to, dstInfos.toToken, dstInfos.minToAmount);

        uint256 dstMinBridgeAmount = (bridgeAmount * (10000 - bridgeSlippage)) / 10000;
        bytes memory dstWooCrossChainRouter = abi.encodePacked(wooCrossChainRouters[dstInfos.chainId]);

        IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);

        if (srcInfos.bridgeToken == weth) {
            IWETH(weth).withdraw(bridgeAmount);
            address sgETH = sgETHs[sgChainIdLocal];
            IStargateEthVault(sgETH).deposit{value: bridgeAmount}(); // logic from Stargate RouterETH.sol
            TransferHelper.safeApprove(sgETH, address(stargateRouter), bridgeAmount);
        } else {
            TransferHelper.safeApprove(srcInfos.bridgeToken, address(stargateRouter), bridgeAmount);
        }

        stargateRouter.swap{value: msgValue}(
            dstInfos.chainId, // dst chain id
            srcPoolId, // bridge token's pool id on src chain
            dstPoolId, // bridge token's pool id on dst chain
            payable(_msgSender()), // rebate address
            bridgeAmount, // swap amount on src chain
            dstMinBridgeAmount, // min received amount on dst chain
            obj, // config: dstGasForCall, dstAirdropNativeAmount, dstReceiveAirdropNativeTokenAddr
            dstWooCrossChainRouter, // smart contract to call on dst chain
            payload // payload to piggyback
        );
    }

    function _handleNativeReceived(
        uint256 refId,
        address to,
        address toToken,
        uint256 bridgedAmount,
        uint256 minToAmount
    ) internal {
        address msgSender = _msgSender();

        if (toToken == ETH_PLACEHOLDER_ADDR) {
            TransferHelper.safeTransferETH(to, bridgedAmount);
            emit WooCrossSwapOnDstChain(
                refId,
                msgSender,
                to,
                weth,
                bridgedAmount,
                toToken,
                ETH_PLACEHOLDER_ADDR,
                minToAmount,
                bridgedAmount
            );
        } else {
            try
                wooRouter.swap{value: bridgedAmount}(
                    ETH_PLACEHOLDER_ADDR,
                    toToken,
                    bridgedAmount,
                    minToAmount,
                    payable(to),
                    to
                )
            returns (uint256 realToAmount) {
                emit WooCrossSwapOnDstChain(
                    refId,
                    msgSender,
                    to,
                    weth,
                    bridgedAmount,
                    toToken,
                    toToken,
                    minToAmount,
                    realToAmount
                );
            } catch {
                TransferHelper.safeTransferETH(to, bridgedAmount);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msgSender,
                    to,
                    weth,
                    bridgedAmount,
                    toToken,
                    ETH_PLACEHOLDER_ADDR,
                    minToAmount,
                    bridgedAmount
                );
            }
        }
    }

    function _handleERC20Received(
        uint256 refId,
        address to,
        address toToken,
        address bridgedToken,
        uint256 bridgedAmount,
        uint256 minToAmount
    ) internal {
        address msgSender = _msgSender();

        if (toToken == bridgedToken) {
            TransferHelper.safeTransfer(bridgedToken, to, bridgedAmount);
            emit WooCrossSwapOnDstChain(
                refId,
                msgSender,
                to,
                bridgedToken,
                bridgedAmount,
                toToken,
                toToken,
                minToAmount,
                bridgedAmount
            );
        } else {
            TransferHelper.safeApprove(bridgedToken, address(wooRouter), bridgedAmount);
            try wooRouter.swap(bridgedToken, toToken, bridgedAmount, minToAmount, payable(to), to) returns (
                uint256 realToAmount
            ) {
                emit WooCrossSwapOnDstChain(
                    refId,
                    msgSender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    toToken,
                    minToAmount,
                    realToAmount
                );
            } catch {
                TransferHelper.safeTransfer(bridgedToken, to, bridgedAmount);
                emit WooCrossSwapOnDstChain(
                    refId,
                    msgSender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    bridgedToken,
                    minToAmount,
                    bridgedAmount
                );
            }
        }
    }

    /* ----- Owner & Admin Functions ----- */

    function setWooRouter(address _wooRouter) external onlyOwner {
        require(_wooRouter != address(0), "WooCrossChainRouterV2: !_wooRouter");
        wooRouter = IWooRouterV2(_wooRouter);
    }

    function setStargateRouter(address _stargateRouter) external onlyOwner {
        require(_stargateRouter != address(0), "WooCrossChainRouterV2: !_stargateRouter");
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function setBridgeSlippage(uint256 _bridgeSlippage) external onlyOwner {
        require(_bridgeSlippage <= 10000, "WooCrossChainRouterV2: !_bridgeSlippage");
        bridgeSlippage = _bridgeSlippage;
    }

    function setDstGasForSwapCall(uint256 _dstGasForSwapCall) external onlyOwner {
        dstGasForSwapCall = _dstGasForSwapCall;
    }

    function setDstGasForNoSwapCall(uint256 _dstGasForNoSwapCall) external onlyOwner {
        dstGasForNoSwapCall = _dstGasForNoSwapCall;
    }

    function setSgChainIdLocal(uint16 _sgChainIdLocal) external onlyOwner {
        sgChainIdLocal = _sgChainIdLocal;
    }

    function setWooCrossChainRouter(uint16 chainId, address wooCrossChainRouter) external onlyOwner {
        require(wooCrossChainRouter != address(0), "WooCrossChainRouterV2: !wooCrossChainRouter");
        wooCrossChainRouters[chainId] = wooCrossChainRouter;
    }

    function setSgETH(uint16 chainId, address token) external onlyOwner {
        require(token != address(0), "WooCrossChainRouterV2: !token");
        sgETHs[chainId] = token;
    }

    function setSgPoolId(
        uint16 chainId,
        address token,
        uint256 poolId
    ) external onlyOwner {
        sgPoolIds[chainId][token] = poolId;
    }

    function setTokenToOFT(address token, address oft) external onlyOwner {
        tokenToOFTs[token] = oft;
    }

    function addDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.add(token);
        require(success, "WooCrossChainRouterV2: token exist");
    }

    function removeDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.remove(token);
        require(success, "WooCrossChainRouterV2: token not exist");
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