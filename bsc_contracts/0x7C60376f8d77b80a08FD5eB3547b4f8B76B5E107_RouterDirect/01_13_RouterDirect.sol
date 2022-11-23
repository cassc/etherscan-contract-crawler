// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/access/Ownable.sol";
import "@openzeppelin/contracts-newone/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-newone/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-newone/utils/Counters.sol";
import "../utils/draft-EIP-712.sol";
import "../interfaces/ICurveProxy.sol";
import "../interfaces/IPortal.sol";
import "../interfaces/ISynthesis.sol";
import "../interfaces/IERC20WithPermit.sol";

contract RouterDirect is EIP712, Ownable {
    using Counters for Counters.Counter;

    address _curveProxy;
    address _curveProxyV2;
    address _portal;
    address _synthesis;
    mapping(address => bool) public whiteList;

    constructor(
        address portal,
        address synthesis,
        address curveProxy,
        address curveProxyV2,
        uint256 chainID
    ) EIP712("EYWA", "1", chainID) {
        require(portal != address(0), "Router: portal zero address");
        require(synthesis != address(0), "Router: synthesis zero address");
        require(curveProxy != address(0), "Router: curveProxy zero address");
        _portal = portal;
        _synthesis = synthesis;
        _curveProxy = curveProxy;
        _curveProxyV2 = curveProxyV2;
    }

    modifier onlyTrusted() {
        require(whiteList[msg.sender], "RouterDirect: only trusted");
        _;
    }

    function addTrustedAddress(address trusted) public onlyOwner {
        whiteList[trusted] = true;
    }

    function removeTrustedAddress(address trusted) public onlyOwner {
        whiteList[trusted] = false;
    }

    //.........................DIRECT-METHODS...........................
    //=============================PORTAL===============================
    /**
     * @dev Direct token synthesize request.
     * @param token token address to synthesize
     * @param amount amount to synthesize
     * @param synthParams crosschain parameters
     */
    function tokenSynthesizeRequest(
        address token,
        uint256 amount,
        address to,
        IPortal.SynthParams calldata synthParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _portal, amount);
        IPortal(_portal).synthesize(token, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Direct token synthesize request with permit.
     * @param token token address to synthesize
     * @param amount amount to synthesize
     * @param synthParams crosschain parameters
     * @param permitData permit data
     */
    function tokenSynthesizeRequestWithPermit(
        address token,
        uint256 amount,
        address to,
        IPortal.SynthParams calldata synthParams,
        IPortal.PermitData calldata permitData
    ) external onlyTrusted {
        IERC20WithPermit(token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _portal, amount);
        IPortal(_portal).synthesize(token, amount, msg.sender, to, synthParams);
    }

    function tokenSynthesizeWithSwapRequest(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthesizeParams calldata _synthesizeTokenParams,
        IPortal.SynthParams calldata _synthParams,
        uint256 _coinIndex
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(_synthesizeTokenParams.token), msg.sender, _portal, _synthesizeTokenParams.amount);
        IPortal(_portal).synthesizeWithTokenSwap(_exchangeParams, _params, _finalSynthParams, _synthesizeTokenParams, _synthParams, _coinIndex);
    }

    function tokenSynthesizeWithSwapRequestWithPermit(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthesizeParams calldata _synthesizeTokenParams,
        IPortal.SynthParams calldata _synthParams,
        IPortal.PermitData calldata permitData,
        uint256 _coinIndex
    ) external onlyTrusted {
        IERC20WithPermit(_synthesizeTokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : _synthesizeTokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(_synthesizeTokenParams.token), msg.sender, _portal, _synthesizeTokenParams.amount);
        IPortal(_portal).synthesizeWithTokenSwap(_exchangeParams, _params, _finalSynthParams, _synthesizeTokenParams, _synthParams, _coinIndex);
    }

    function synthBatchAddLiquidity3PoolMintEUSDRequest(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaMintEUSD memory metaParams,
        ICurveProxy.TokenInput memory tokenParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchAddLiquidity3PoolMintEUSD(
            from,
            synthParams,
            metaParams,
            tokenParams
        );
    }

    function synthBatchMetaExchangeRequest(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchMetaExchange(from, synthParams, metaParams, tokenParams);
    }

    function synthBatchAddLiquidity3PoolMintEUSDRequestWithPermit(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaMintEUSD memory metaParams,
        ISynthesis.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        IERC20WithPermit(tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchAddLiquidity3PoolMintEUSD(
            from,
            synthParams,
            metaParams,
            tokenParams
        );
    }

    function synthBatchMetaExchangeWithSwapRequest(
        ICurveProxy.TokenInput calldata tokenParams,
        IPortal.SynthParamsMetaSwap memory synthParams,
        IPortal.SynthParams memory finalSynthParams,
        ICurveProxy.MetaExchangeParams memory metaParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchMetaExchangeWithSwap(tokenParams, synthParams, finalSynthParams, metaParams);
    }

    function synthBatchMetaExchangeWithSwapRequestWithPermit(
        ICurveProxy.TokenInput calldata tokenParams,
        IPortal.SynthParamsMetaSwap memory synthParams,
        IPortal.SynthParams memory finalSynthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        ISynthesis.PermitData calldata permitData
    ) external onlyTrusted {
        IERC20WithPermit(tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchMetaExchangeWithSwap(tokenParams, synthParams, finalSynthParams, metaParams);
    }

    function synthBatchMetaExchangeRequestWithPermit(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        ISynthesis.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        IERC20WithPermit(tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchMetaExchange(from, synthParams, metaParams, tokenParams);
    }

    /**
     * @dev Direct revert burnSyntheticToken() operation, can be called several times.
     * @param txID transaction ID to unburn
     * @param receiveSide receiver contract address
     * @param oppositeBridge opposite bridge address
     * @param chainId opposite chain ID
     * @param v must be a valid part of the signature from tx owner
     * @param r must be a valid part of the signature from tx owner
     * @param s must be a valid part of the signature from tx owner
     */
    function emergencyUnburnRequest(
        bytes32 txID,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyTrusted {
        IPortal(_portal).emergencyUnburnRequest(txID, receiveSide, oppositeBridge, chainId, v, r, s);
    }

    //==============================CURVE-PROXY==============================
    /**
     * @dev Direct local mint EUSD request (hub chain execution only).
     * @param params MetaMintEUSD params
     */
    function mintEusdRequestVia3pool(
        ICurveProxy.MetaMintEUSD calldata params,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);

        ICurveProxy(_curveProxy).addLiquidity3PoolMintEUSD(params, tokenParams);
    }

    function mintEusdRequestVia3poolWithPermit(
        ICurveProxy.MetaMintEUSD calldata params,
        ICurveProxy.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        IERC20WithPermit(tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);

        ICurveProxy(_curveProxy).addLiquidity3PoolMintEUSD(params, tokenParams);
    }

    /**
     * @dev Direct local meta exchange request (hub chain execution only).
     * @param params meta exchange params
     */
    function metaExchangeRequestVia3pool(
        ICurveProxy.MetaExchangeParams calldata params,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);

        ICurveProxy(_curveProxy).metaExchange(params, tokenParams);
    }

    function metaExchangeRequestVia3poolWithPermit(
        ICurveProxy.MetaExchangeParams calldata params,
        ICurveProxy.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams
    ) external onlyTrusted {
        IERC20WithPermit(tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);
        ICurveProxy(_curveProxy).metaExchange(params, tokenParams);
    }

    /**
     * @dev Direct local EUSD redeem request with unsynth operation (hub chain execution only).
     * @param params meta redeem EUSD params
     * @param payToken pay token
     * @param receiveSide recipient address for unsynth operation
     * @param oppositeBridge opposite bridge contract address
     * @param chainId opposite chain ID
     */
    function redeemEusdRequest(
        ICurveProxy.MetaRedeemEUSD calldata params,
        address payToken,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(payToken), msg.sender, _curveProxy, params.tokenAmountH);
        ICurveProxy(_curveProxy).redeemEUSD(params, receiveSide, oppositeBridge, chainId);
    }

     /**
     * @dev Direct local EUSD redeem request with unsynth operation (hub chain execution only) with permit.
     * @param params meta redeem EUSD params
     * @param permit permit params
     * @param payToken pay token
     * @param receiveSide recipient address for unsynth operation
     * @param oppositeBridge opposite bridge contract address
     * @param chainId opposite chain ID
     */
    function redeemEusdRequestWithPermit(
        ICurveProxy.MetaRedeemEUSD calldata params,
        ICurveProxy.PermitData calldata permit,
        address payToken,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    ) external onlyTrusted {
        IERC20WithPermit(payToken).permit(
            msg.sender,
            address(this),
            permit.approveMax ? uint256(2**256 - 1) : params.tokenAmountH,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        SafeERC20.safeTransferFrom(IERC20(payToken), msg.sender, _curveProxy, params.tokenAmountH);
        ICurveProxy(_curveProxy).redeemEUSD(params, receiveSide, oppositeBridge, chainId);
    }

    function tokenSwapWithMetaExchangeRequest(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        uint256 coinIndex
    ) external onlyTrusted {
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            coinIndex
        );
        SafeERC20.safeTransferFrom(IERC20(_exchangeParams.tokenToSwap), msg.sender, _curveProxyV2, _exchangeParams.amountToSwap);
        ICurveProxy(_curveProxyV2).tokenSwapWithMetaExchange(_exchangeParams, _params, _synthParams, feeParams);
    }

    function tokenSwapWithMetaExchangeRequestWithPermit(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        ISynthesis.PermitData calldata permitData,
        uint256 coinIndex
    ) external onlyTrusted {
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            coinIndex
        );
        IERC20WithPermit(_exchangeParams.tokenToSwap).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : _exchangeParams.amountToSwap,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(_exchangeParams.tokenToSwap), msg.sender, _curveProxyV2, _exchangeParams.amountToSwap);
        ICurveProxy(_curveProxyV2).tokenSwapWithMetaExchange(_exchangeParams, _params, _synthParams, feeParams);
    }

    function tokenSwap(
        address tokenToSwap,
        address to,
        uint256 amountOutMin,
        address tokenToReceive,
        uint256 deadline,
        address from,
        uint256 amount,
        IPortal.SynthParams calldata finalSynthParams
    ) external {
        SafeERC20.safeTransferFrom(IERC20(tokenToSwap), msg.sender, _curveProxyV2, amount);
        ICurveProxy(_curveProxyV2).tokenSwapLite(tokenToSwap, to, amountOutMin, tokenToReceive, deadline, from, amount, 0, address(0), finalSynthParams);
    }

    function tokenSwapWithPermit(
        address tokenToSwap,
        address to,
        uint256 amountOutMin,
        address tokenToReceive,
        uint256 deadline,
        address from,
        uint256 amount,
        IPortal.SynthParams calldata finalSynthParams,
        ISynthesis.PermitData calldata permitData
    ) external {
        IERC20WithPermit(tokenToSwap).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenToSwap), msg.sender, _curveProxyV2, amount);
        ICurveProxy(_curveProxyV2).tokenSwapLite(tokenToSwap, to, amountOutMin, tokenToReceive, deadline, from, amount, 0, address(0), finalSynthParams);
    }

    function removeLiquidity(
        address remove,
        int128 x,
        uint256 expectedMinAmount,
        address to,
        address token,
        uint256 amount,
        ISynthesis.SynthParams calldata synthParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _curveProxy, amount);
        ICurveProxy(_curveProxy).removeLiquidity(remove, x, expectedMinAmount, to, synthParams);
    }

    function removeLiquidityWithPermit(
        address remove,
        int128 x,
        uint256 expectedMinAmount,
        address to,
        address token,
        uint256 amount,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData
    ) external onlyTrusted {
        IERC20WithPermit(token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _curveProxy, amount);
        ICurveProxy(_curveProxy).removeLiquidity(remove, x, expectedMinAmount, to, synthParams);
    }

    //==============================SYNTHESIS==============================
    /**
     * @dev Direct synthetic token transfer request to another chain.
     * @param stoken synth token address
     * @param amount amount to transfer
     * @param to recipient address
     * @param synthParams crosschain parameters
     */
    function synthTransferRequest(
        address stoken,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(stoken), msg.sender, address(this), amount);
        ISynthesis(_synthesis).synthTransfer(stoken, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Direct synthetic token transfer request with permit.
     * @param stoken synth token address
     * @param amount amount to transfer
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param permitData permit data
     */
    function synthTransferRequestWithPermit(
        address stoken,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData
    ) external onlyTrusted {
        IERC20WithPermit(stoken).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(stoken), msg.sender, address(this), amount);
        ISynthesis(_synthesis).synthTransfer(stoken, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Direct unsynthesize request.
     * @param stoken synthetic token address for unsynthesize
     * @param amount amount to unsynth
     * @param to recipient address
     * @param synthParams crosschain parameters
     */
    function unsynthesizeRequest(
        address stoken,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams
    ) external onlyTrusted {
        SafeERC20.safeTransferFrom(IERC20(stoken), msg.sender, address(this), amount);
        ISynthesis(_synthesis).burnSyntheticToken(stoken, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Direct unsynthesize request with permit.
     * @param stoken synthetic token address for unsynthesize
     * @param amount amount to unsynth
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param permitData permit data
     */
    function unsynthesizeRequestWithPermit(
        address stoken,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData
    ) external onlyTrusted {
        IERC20WithPermit(stoken).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(stoken), msg.sender, address(this), amount);
        ISynthesis(_synthesis).burnSyntheticToken(stoken, amount, msg.sender, to, synthParams);
    }

    function unsynthesizeWithMetaExchangeRequest(
        IPortal.SynthesizeParams calldata _tokenParams,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParams calldata _synthParams,
        uint256 coinIndex
    ) external onlyTrusted {
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            coinIndex
        );
        SafeERC20.safeTransferFrom(IERC20(_tokenParams.token), msg.sender, address(this), _tokenParams.amount);
        ISynthesis(_synthesis).burnSyntheticTokenWithMetaExchange(_tokenParams, _exchangeParams, _params, _finalSynthParams, _synthParams, feeParams);
    }

    function unsynthesizeWithMetaExchangeRequestWithPermit(
        IPortal.SynthesizeParams calldata _tokenParams,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParams calldata _synthParams,
        ISynthesis.PermitData calldata permitData,
        uint256 coinIndex
    ) external onlyTrusted {
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            coinIndex
        );
        IERC20WithPermit(_tokenParams.token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : _tokenParams.amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(_tokenParams.token), msg.sender, address(this), _tokenParams.amount);
        ISynthesis(_synthesis).burnSyntheticTokenWithMetaExchange(_tokenParams, _exchangeParams, _params, _finalSynthParams, _synthParams, feeParams);
    }


    /**
     * @dev Direct emergency unsynthesize request.
     * @param txID synthesize transaction ID
     * @param receiveSide request recipient address
     * @param oppositeBridge opposite bridge address
     * @param chainId opposite chain ID
     * @param v must be a valid part of the signature from tx owner
     * @param r must be a valid part of the signature from tx owner
     * @param s must be a valid part of the signature from tx owner
     */
    function emergencyUnsyntesizeRequest(
        bytes32 txID,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyTrusted {
        ISynthesis(_synthesis).emergencyUnsyntesizeRequest(txID, receiveSide, oppositeBridge, chainId, v, r, s);
    }

}