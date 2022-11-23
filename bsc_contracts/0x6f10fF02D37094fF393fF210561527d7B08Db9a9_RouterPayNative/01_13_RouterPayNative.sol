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

contract RouterPayNative is EIP712, Ownable {
    using Counters for Counters.Counter;

    address _curveProxy;
    address _curveProxyV2;
    address _portal;
    address _synthesis;

    bytes32 public constant _SYNTHESIZE_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("synthesizeRequest"));
    bytes32 public constant _UNSYNTHESIZE_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("unsynthesizeRequest"));
    bytes32 public constant _SYNTH_TRANSFER_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("synthTransferRequest"));

    bytes32 public constant _SYNTH_BATCH_MINT_EUSD_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("synthBatchAddLiquidity3PoolMintEUSDRequest"));

    bytes32 public constant _SYNTH_BATCH_META_EXCHANGE_SWAP_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("synthBatchMetaExchangeWithSwapRequestWithPermit"));
        

    bytes32 public constant _SYNTH_BATCH_META_EXCHANGE_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("synthBatchMetaExchangeRequest"));

    bytes32 public constant _LOCAL_META_EXCHANGE_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("metaExchangeRequestVia3pool"));

    bytes32 public constant _REDEEM_EUSD_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("redeemEusdRequest"));

    bytes32 public constant _TOKEN_SWAP_META_EXCHANGE_REQUEST_SIGNATURE_HASH =
        keccak256(abi.encodePacked("tokenSwapWithMetaExchangeRequestPayNative"));
    
    bytes32 public constant _UNSYNTHESIZE_WITH_META_EXCHANGE_REQUEST = 
        keccak256(abi.encodePacked("unsynthesizeWithMetaExchangeRequest"));

    bytes32 public constant _MINT_EUSD_REQUEST = 
        keccak256(abi.encodePacked("mintEusdRequestVia3pool"));
    
    bytes32 public constant _TOKEN_SWAP_HASH =
        keccak256(abi.encodePacked("tokenSwap"));

    bytes32 public constant _REMOVE_LIQUIDITY_HASH =
        keccak256(abi.encodePacked("removeLiquidity"));

    mapping(address => bool) public _trustedWorker;
    mapping(address => Counters.Counter) private _nonces;

    event CrosschainPaymentEvent(address indexed userFrom, address indexed worker, uint256 executionPrice);

    struct DelegatedCallReceipt {
        uint256 executionPrice;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

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

    function setTrustedWorker(address worker) public onlyOwner {
        _trustedWorker[worker] = true;
    }

    function removeTrustedWorker(address worker) public onlyOwner {
        _trustedWorker[worker] = false;
    }

    function _checkWorkerSignature(
        uint256 chainIdTo,
        bytes32 executionHash,
        DelegatedCallReceipt calldata receipt
    ) internal returns (address worker) {
        uint256 nonce = _useNonce(msg.sender);
        bytes32 workerStructHash = keccak256(
            abi.encodePacked(
                keccak256(
                    "DelegatedCallWorkerPermit(address from,uint256 chainIdTo,uint256 executionPrice,bytes32 executionHash,uint256 nonce,uint256 deadline)"
                ),
                msg.sender,
                chainIdTo,
                receipt.executionPrice,
                executionHash,
                nonce,
                receipt.deadline
            )
        );

        bytes32 workerHash = ECDSA.toEthSignedMessageHash(_hashTypedDataV4(workerStructHash));
        worker = ECDSA.recover(workerHash, receipt.v, receipt.r, receipt.s);

        require(block.timestamp <= receipt.deadline, "Router: deadline");
        require(_trustedWorker[worker], "Router: invalid signature from worker");
    }

    function _proceedFees(uint256 executionPrice, address worker) internal {
        // worker fee
        require(msg.value >= executionPrice, "Router: invalid amount");
        (bool sent, ) = worker.call{ value: msg.value }("");
        require(sent, "Router: failed to send Ether");

        emit CrosschainPaymentEvent(msg.sender, worker, executionPrice);
    }

    //==============================PORTAL==============================
    /**
     * @dev Token synthesize request to another EVM chain via native payment.
     * @param token token address to synthesize
     * @param amount amount to synthesize
     * @param to amount recipient address
     * @param synthParams crosschain parameters
     * @param receipt delegated call receipt from worker
     */
    function synthesizeRequestPayNative(
        address token,
        uint256 amount,
        address to,
        IPortal.SynthParams calldata synthParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTHESIZE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _portal, amount);
        IPortal(_portal).synthesize(token, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Token synthesize request with permit to another EVM chain via native payment.
     * @param token token address to synthesize
     * @param amount amount to synthesize
     * @param to amount recipient address
     * @param synthParams crosschain parameters
     * @param permitData permit data
     * @param receipt delegated call receipt from worker
     */
    function synthesizeRequestWithPermitPayNative(
        address token,
        uint256 amount,
        address to,
        IPortal.SynthParams calldata synthParams,
        IPortal.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTHESIZE_REQUEST_SIGNATURE_HASH, receipt);
        IERC20WithPermit(token).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );

        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _portal, amount);
        IPortal(_portal).synthesize(token, amount, msg.sender, to, synthParams);
    }

    //==============================SYNTHESIS==============================
    /**
     * @dev Synthetic token transfer request to another EVM chain via native payment.
     * @param tokenSynth synth token address
     * @param amount amount to transfer
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param receipt delegated call receipt from worker
     */
    function synthTransferRequestPayNative(
        address tokenSynth,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_TRANSFER_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenSynth), msg.sender, address(this), amount);
        ISynthesis(_synthesis).synthTransfer(tokenSynth, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Synthetic token transfer request with permit to another EVM chain via native payment.
     * @param tokenSynth synth token address
     * @param amount amount to transfer
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param permitData permit data
     * @param receipt delegated call receipt from worker
     */
    function synthTransferRequestWithPermitPayNative(
        address tokenSynth,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_TRANSFER_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        IERC20WithPermit(tokenSynth).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenSynth), msg.sender, address(this), amount);
        ISynthesis(_synthesis).synthTransfer(tokenSynth, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Unsynthesize request to another EVM chain via native payment.
     * @param tokenSynth synthetic token address for unsynthesize
     * @param amount amount to unsynth
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param receipt delegated call receipt from worker
     */
    function unsynthesizeRequestPayNative(
        address tokenSynth,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _UNSYNTHESIZE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenSynth), msg.sender, address(this), amount);
        ISynthesis(_synthesis).burnSyntheticToken(tokenSynth, amount, msg.sender, to, synthParams);
    }

    /**
     * @dev Unsynthesize request to another EVM chain via native payment.
     * @param tokenSynth synthetic token address for unsynthesize
     * @param amount amount to unsynth
     * @param to recipient address
     * @param synthParams crosschain parameters
     * @param permitData permit data
     * @param receipt delegated call receipt from worker
     */
    function unsynthesizeRequestWithPermitPayNative(
        address tokenSynth,
        uint256 amount,
        address to,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _UNSYNTHESIZE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        IERC20WithPermit(tokenSynth).permit(
            msg.sender,
            address(this),
            permitData.approveMax ? uint256(2**256 - 1) : amount,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
        SafeERC20.safeTransferFrom(IERC20(tokenSynth), msg.sender, address(this), amount);
        ISynthesis(_synthesis).burnSyntheticToken(tokenSynth, amount, msg.sender, to, synthParams);
    }

    function unsynthesizeWithMetaExchangePayNative(
        IPortal.SynthesizeParams calldata _tokenParams,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParams calldata _synthParams,
        DelegatedCallReceipt calldata receipt,
        uint256 _coinIndex
    ) external payable {
        address worker = _checkWorkerSignature(_synthParams.chainId, _UNSYNTHESIZE_WITH_META_EXCHANGE_REQUEST, receipt);
        _proceedFees(receipt.executionPrice, worker);
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            _coinIndex
        );
        SafeERC20.safeTransferFrom(IERC20(_tokenParams.token), msg.sender, address(this), _tokenParams.amount);
        ISynthesis(_synthesis).burnSyntheticTokenWithMetaExchange(_tokenParams, _exchangeParams, _params, _finalSynthParams, _synthParams, feeParams);
    }

    function unsynthesizeWithMetaExchangeWithPermitPayNative(
        IPortal.SynthesizeParams calldata _tokenParams,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParams calldata _synthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt,
        uint256 _coinIndex
    ) external payable {
        address worker = _checkWorkerSignature(_synthParams.chainId, _UNSYNTHESIZE_WITH_META_EXCHANGE_REQUEST, receipt);
        _proceedFees(receipt.executionPrice, worker);
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            _coinIndex
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
    
/////////////////////////////
    function synthBatchAddLiquidity3PoolMintEUSDRequestPayNative(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaMintEUSD memory metaParams,
        DelegatedCallReceipt calldata receipt,
        ICurveProxy.TokenInput calldata tokenParams
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_MINT_EUSD_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);
        IPortal(_portal).synthBatchAddLiquidity3PoolMintEUSD(
            from,
            synthParams,
            metaParams,
            tokenParams
        );
    }

    function synthBatchMetaExchangeRequestPayNative(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        DelegatedCallReceipt calldata receipt,
        ICurveProxy.TokenInput calldata tokenParams
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);
        IPortal(_portal).synthBatchMetaExchange(from, synthParams, metaParams, tokenParams);
    }

    function synthBatchAddLiquidity3PoolMintEUSDRequestWithPermitPayNative(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaMintEUSD memory metaParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt,
        ICurveProxy.TokenInput calldata tokenParams
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_MINT_EUSD_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

    function synthBatchMetaExchangeRequestWithPermitPayNative(
        address from,
        IPortal.SynthParams memory synthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt,
        ICurveProxy.TokenInput calldata tokenParams
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

     function synthBatchMetaExchangeWithSwapRequestWithPermitPayNative(
        ICurveProxy.TokenInput calldata tokenParams,
        IPortal.SynthParamsMetaSwap memory synthParams,
        IPortal.SynthParams memory finalSynthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable{
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_META_EXCHANGE_SWAP_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

    function synthBatchMetaExchangeWithSwapRequestPayNative(
        ICurveProxy.TokenInput calldata tokenParams,
        IPortal.SynthParamsMetaSwap memory synthParams,
        IPortal.SynthParams memory finalSynthParams,
        ICurveProxy.MetaExchangeParams memory metaParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _SYNTH_BATCH_META_EXCHANGE_SWAP_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);

        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _portal, tokenParams.amount);

        IPortal(_portal).synthBatchMetaExchangeWithSwap(tokenParams, synthParams, finalSynthParams, metaParams);
    }
    
    /**
     * @dev Direct local meta exchange request (hub chain execution only).
     * @param params meta exchange params
     */
    function metaExchangeRequestVia3poolPayNative(
        ICurveProxy.MetaExchangeParams calldata params,
        ICurveProxy.TokenInput calldata tokenParams,
        DelegatedCallReceipt calldata receipt
    ) external payable{
        address worker = _checkWorkerSignature(params.chainId, _LOCAL_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);
        ICurveProxy(_curveProxy).metaExchange(params, tokenParams);
    }

    function metaExchangeRequestVia3poolWithPermitPayNative(
        ICurveProxy.MetaExchangeParams calldata params,
        ICurveProxy.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams,
        DelegatedCallReceipt calldata receipt
    ) external payable{
        address worker = _checkWorkerSignature(params.chainId, _LOCAL_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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
    
    function mintEusdRequestVia3poolPayNative(
        ICurveProxy.MetaMintEUSD calldata params,
        ICurveProxy.TokenInput calldata tokenParams,
        uint256 chainId,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(chainId, _MINT_EUSD_REQUEST, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenParams.token), msg.sender, _curveProxy, tokenParams.amount);
        ICurveProxy(_curveProxy).addLiquidity3PoolMintEUSD(params, tokenParams);
    }

    function mintEusdRequestVia3poolWithPermitPayNative(
        ICurveProxy.MetaMintEUSD calldata params,
        ICurveProxy.PermitData calldata permitData,
        ICurveProxy.TokenInput calldata tokenParams,
        uint256 chainId,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(chainId, _MINT_EUSD_REQUEST, receipt);
        _proceedFees(receipt.executionPrice, worker);
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
     * @dev Direct local EUSD redeem request with unsynth operation (hub chain execution only).
     * @param params meta redeem EUSD params
     * @param payToken pay token
     * @param receiveSide recipient address for unsynth operation
     * @param oppositeBridge opposite bridge contract address
     * @param chainId opposite chain ID
     */
    function redeemEusdRequestPayNative(
        ICurveProxy.MetaRedeemEUSD calldata params,
        address payToken,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(chainId, _REDEEM_EUSD_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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
    function redeemEusdRequestWithPermitPayNative(
        ICurveProxy.MetaRedeemEUSD calldata params,
        ICurveProxy.PermitData calldata permit,
        address payToken,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(chainId, _REDEEM_EUSD_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

    function tokenSwapWithMetaExchangeRequestPayNative(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        DelegatedCallReceipt calldata receipt,
        uint256 _coinIndex
    ) external payable {
        address worker = _checkWorkerSignature(_synthParams.chainId, _TOKEN_SWAP_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            _coinIndex
        );
        SafeERC20.safeTransferFrom(IERC20(_exchangeParams.tokenToSwap), msg.sender, _curveProxyV2, _exchangeParams.amountToSwap);
        ICurveProxy(_curveProxyV2).tokenSwapWithMetaExchange(_exchangeParams, _params, _synthParams, feeParams);
    }

    function tokenSwapWithMetaExchangeRequestWithPermitPayNative(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt,
        uint256 _coinIndex
    ) external payable {
        address worker = _checkWorkerSignature(_synthParams.chainId, _TOKEN_SWAP_META_EXCHANGE_REQUEST_SIGNATURE_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            _coinIndex
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

    function tokenSwapPayNative(
        address tokenToSwap,
        address to,
        uint256 amountOutMin,
        address tokenToReceive,
        uint256 deadline,
        address from,
        uint256 amount,
        IPortal.SynthParams calldata finalSynthParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(finalSynthParams.chainId, _TOKEN_SWAP_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(tokenToSwap), msg.sender, _curveProxyV2, amount);
        ICurveProxy(_curveProxyV2).tokenSwapLite(tokenToSwap, to, amountOutMin, tokenToReceive, deadline, from, amount, 0, address(0), finalSynthParams);
    }

    function tokenSwapWithPermitPayNative(
        address tokenToSwap,
        address to,
        uint256 amountOutMin,
        address tokenToReceive,
        uint256 deadline,
        address from,
        uint256 amount,
        IPortal.SynthParams calldata finalSynthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(finalSynthParams.chainId, _TOKEN_SWAP_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

    function removeLiquidityPayNative(
        address remove,
        int128 x,
        uint256 expectedMinAmount,
        address to,
        address token,
        uint256 amount,
        ISynthesis.SynthParams calldata synthParams,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _REMOVE_LIQUIDITY_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, _curveProxy, amount);
        ICurveProxy(_curveProxy).removeLiquidity(remove, x, expectedMinAmount, to, synthParams);
    }

    function removeLiquidityWithPermitPayNative(
        address remove,
        int128 x,
        uint256 expectedMinAmount,
        address to,
        address token,
        uint256 amount,
        ISynthesis.SynthParams calldata synthParams,
        ISynthesis.PermitData calldata permitData,
        DelegatedCallReceipt calldata receipt
    ) external payable {
        address worker = _checkWorkerSignature(synthParams.chainId, _REMOVE_LIQUIDITY_HASH, receipt);
        _proceedFees(receipt.executionPrice, worker);
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

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function _useNonce(address owner) internal returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}