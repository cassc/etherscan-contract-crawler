// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-newone/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./IBridge.sol";
import "../utils/Typecast.sol";
import "./RequestIdLib.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ICurveProxy.sol";
import "../interfaces/IPortal.sol";
import "../interfaces/IWhitelist.sol";

contract Portal is Typecast, ContextUpgradeable, OwnableUpgradeable {
    mapping(address => uint256) public balanceOf;
    string public versionRecipient;
    address public bridge;
    uint256 public thisChainId;
    address public whitelist;

    bytes public constant sighashMintSyntheticToken =
        abi.encodePacked(uint8(44), uint8(253), uint8(1), uint8(101), uint8(130), uint8(139), uint8(18), uint8(78));
    bytes public constant sighashEmergencyUnburn =
        abi.encodePacked(uint8(149), uint8(132), uint8(104), uint8(123), uint8(157), uint8(85), uint8(21), uint8(161));

    enum SynthesizePubkeys {
        to,
        receiveSide,
        receiveSideData,
        oppositeBridge,
        oppositeBridgeData,
        syntToken,
        syntTokenData,
        txState
    }

    enum RequestState {
        Default,
        Sent,
        Reverted
    }
    enum UnsynthesizeState {
        Default,
        Unsynthesized,
        RevertRequest
    }

    struct TxState {
        bytes32 from;
        bytes32 to;
        uint256 amount;
        bytes32 rtoken;
        RequestState state;
    }

    struct SynthParams {
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
    }

    struct PermitData {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        bool approveMax;
    }

    struct TokenInfo {
        uint8 tokenDecimals;
        bool isApproved;
    }

    struct SynthParamsMetaSwap {
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
        address swapReceiveSide;
        address swapOppositeBridge;
        uint256 swapChainId;
        address swappedToken;
        address path;
        address to;
        uint256 amountOutMin;
        uint256 deadline;
        address from;
        uint256 initialChainId;
    }

    struct MetaTokenParams {
        address token;
        uint256 amount;
        address from;
    }

    struct SynthesizeParams {
        address token;
        uint256 amount;
        address from;
        address to;
    }

    mapping(bytes32 => TxState) public requests;
    mapping(bytes32 => UnsynthesizeState) public unsynthesizeStates;
    mapping(bytes32 => TokenInfo) public tokenDecimalsData;

    event SynthesizeRequest(
        bytes32 indexed id,
        address indexed from,
        address indexed to,
        uint256 amount,
        address token
    );
    event SynthesizeRequestSolana(
        bytes32 indexed id,
        address indexed from,
        bytes32 indexed to,
        uint256 amount,
        address token
    );
    event RevertBurnRequest(bytes32 indexed id, address indexed to);
    event BurnCompleted(bytes32 indexed id, address indexed to, uint256 amount, address token);
    event RevertSynthesizeCompleted(bytes32 indexed id, address indexed to, uint256 amount, address token);
    event RepresentationRequest(address indexed rtoken);
    event ApprovedRepresentationRequest(bytes32 indexed rtoken);

    function initializeFunc(
        address _bridge,
        address _trustedForwarder,
        uint256 _thisChainId,
        address _whitelist
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        versionRecipient = "2.2.3";
        bridge = _bridge;
        thisChainId = _thisChainId;
        whitelist = _whitelist;
    }

    modifier onlyBridge() {
        require(bridge == msg.sender, "Portal: bridge only");
        _;
    }

    function registerNewBalance(address token, uint256 expectedAmount) internal {
        uint256 oldBalance = balanceOf[token];
        require(
            (IERC20(token).balanceOf(address(this)) - oldBalance) >= expectedAmount,
            "Portal: insufficient balance"
        );
        balanceOf[token] += expectedAmount;
    }

    /**
     * @dev Token synthesize request.
     * @param _token token address to synthesize
     * @param _amount amount to synthesize
     * @param _from msg sender address
     * @param _synthParams synth params
     */
    function synthesize(
        address _token,
        uint256 _amount,
        address _from,
        address _to,
        SynthParams calldata _synthParams
    ) external returns (bytes32 txID) {
        // require(IWhitelist(whitelist).tokenList(_token), "Token must be whitelisted");
        // require(tokenDecimalsData[castToBytes32(_token)].isApproved, "Portal: token must be verified");
        registerNewBalance(_token, _amount);

        uint256 nonce = IBridge(bridge).getNonce(_from);
        txID = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_from),
            nonce
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(keccak256(bytes("mintSyntheticToken(bytes32,address,uint256,address)"))),
            txID,
            _token,
            _amount,
            _to
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            txID,
            _from,
            nonce
        );
        TxState storage txState = requests[txID];
        txState.from = castToBytes32(_from);
        txState.to = castToBytes32(_to);
        txState.rtoken = castToBytes32(_token);
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequest(txID, _from, _to, _amount, _token);
    }

    function synthesizeWithTokenSwap(
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthesizeParams calldata _synthesizeTokenParams,
        IPortal.SynthParams calldata _synthParams,
        uint256 coinIndex
    ) external returns (bytes32 txID) {
        // require(IWhitelist(whitelist).tokenList(_synthesizeTokenParams.token), "Token must be whitelisted");

        if (_params.add != address(0)) {
            require(
                IWhitelist(whitelist).checkDestinationToken(_params.remove, _params.x),
                "Destination token must be whitelisted"
            );
        } else {
            require(
                IWhitelist(whitelist).checkDestinationToken(_params.exchange, _params.j),
                "Destination token must be whitelisted"
            );
        }

        require(
            tokenDecimalsData[castToBytes32(_synthesizeTokenParams.token)].isApproved,
            "Portal: token must be verified"
        );
        registerNewBalance(_synthesizeTokenParams.token, _synthesizeTokenParams.amount);

        uint256 nonce = IBridge(bridge).getNonce(_synthesizeTokenParams.from);
        txID = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_synthesizeTokenParams.from),
            nonce
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes(
                        "mintSyntheticTokenWithSwap(bytes32,address,uint256,address,(address,uint256,address,uint256,uint256,address),(address,address,address,uint256,int128,int128,uint256,int128,uint256,address,address,address,address,uint256),(address,address,uint256),uint256)"
                    )
                )
            ),
            txID,
            _synthesizeTokenParams.token,
            _synthesizeTokenParams.amount,
            _synthesizeTokenParams.to,
            _exchangeParams,
            _params,
            _finalSynthParams,
            coinIndex
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            txID,
            _synthesizeTokenParams.from,
            nonce
        );
        TxState storage txState = requests[txID];
        txState.from = castToBytes32(_synthesizeTokenParams.from);
        txState.to = castToBytes32(_synthesizeTokenParams.to);
        txState.rtoken = castToBytes32(_synthesizeTokenParams.token);
        txState.amount = _synthesizeTokenParams.amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequest(
            txID,
            _synthesizeTokenParams.from,
            _synthesizeTokenParams.to,
            _synthesizeTokenParams.amount,
            _synthesizeTokenParams.token
        );
    }

    function unsynthesizeWithMetaExchange(
        bytes32 _txID,
        address _token,
        uint256 _amount,
        address _curveV2,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _synthParams,
        ICurveProxy.FeeParams calldata _feeParams
    ) external onlyBridge {
        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: synthetic tokens emergencyUnburn");

        // require(IWhitelist(whitelist).tokenList(_token), "Token must be whitelisted");

        if (_params.add != address(0)) {
            require(
                IWhitelist(whitelist).checkDestinationToken(_params.remove, _params.x),
                "Destination token must be whitelisted"
            );
        } else {
            require(
                IWhitelist(whitelist).checkDestinationToken(_params.exchange, _params.j),
                "Destination token must be whitelisted"
            );
        }

        TransferHelper.safeTransfer(_token, _curveV2, _amount);
        balanceOf[_token] -= _amount;
        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _curveV2, _amount, _token);
        ICurveProxy(_curveV2).tokenSwapWithMetaExchange(_exchangeParams, _params, _synthParams, _feeParams);
    }

    /**
     * @dev Emergency unsynthesize request. Can be called only by bridge after initiation on a second chain.
     * @param _txID transaction ID to unsynth
     * @param _trustedEmergencyExecuter trusted function executer
     */
    function emergencyUnsynthesize(
        bytes32 _txID,
        address _trustedEmergencyExecuter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyBridge {
        TxState storage txState = requests[_txID];
        bytes32 emergencyStructHash = keccak256(
            abi.encodePacked(
                _txID,
                _trustedEmergencyExecuter,
                block.chainid,
                "emergencyUnsynthesize(bytes32,address,uint8,bytes32,bytes32)"
            )
        );
        address txOwner = ECDSA.recover(ECDSA.toEthSignedMessageHash(emergencyStructHash), _v, _r, _s);
        require(txState.state == RequestState.Sent, "Portal: state not open or tx does not exist");
        require(txState.from == castToBytes32(txOwner), "Portal: invalid tx owner");
        txState.state = RequestState.Reverted;
        TransferHelper.safeTransfer(castToAddress(txState.rtoken), castToAddress(txState.from), txState.amount);

        emit RevertSynthesizeCompleted(
            _txID,
            castToAddress(txState.from),
            txState.amount,
            castToAddress(txState.rtoken)
        );
    }

    /**
     * @dev Unsynthesize request. Can be called only by bridge after initiation on a second chain.
     * @param _txID transaction ID to unsynth
     * @param _token token address to unsynth
     * @param _amount amount to unsynth
     * @param _to recipient address
     */
    function unsynthesize(
        bytes32 _txID,
        address _token,
        uint256 _amount,
        address _to
    ) external onlyBridge {
        require(IWhitelist(whitelist).tokenList(_token), "Token must be whitelisted");

        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: synthetic tokens emergencyUnburn");
        TransferHelper.safeTransfer(_token, _to, _amount);
        balanceOf[_token] -= _amount;
        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _to, _amount, _token);
    }

    function unsynthesizeWithSwap(
        bytes32 _txID,
        address _token,
        uint256 _amount,
        address _curveV2,
        IPortal.SynthParamsMetaSwap memory _synthParams,
        IPortal.SynthParams memory _finalSynthParams
    ) external onlyBridge {
        require(IWhitelist(whitelist).tokenList(_token), "Token must be whitelisted");
        require(IWhitelist(whitelist).tokenList(_synthParams.path), "Token must be whitelisted");

        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: synthetic tokens emergencyUnburn");
        TransferHelper.safeTransfer(_token, _curveV2, _amount);
        balanceOf[_token] -= _amount;
        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _curveV2, _amount, _token);
        ICurveProxy(_curveV2).tokenSwap(_synthParams, _finalSynthParams, _amount);
    }

    /**
     * @dev Revert burnSyntheticToken() operation, can be called several times.
     * @param _txID transaction ID to unburn
     * @param _receiveSide receiver chain synthesis contract address
     * @param _oppositeBridge opposite bridge address
     * @param _chainId opposite chain ID
     */
    function emergencyUnburnRequest(
        bytes32 _txID,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(
            unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized,
            "Portal: real tokens already transferred"
        );
        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        bytes memory out = abi.encodeWithSelector(
            bytes4(keccak256(bytes("emergencyUnburn(bytes32,address,uint8,bytes32,bytes32)"))),
            _txID,
            msg.sender,
            _v,
            _r,
            _s
        );

        uint256 nonce = IBridge(bridge).getNonce(msg.sender);
        bytes32 txID = RequestIdLib.prepareRqId(
            castToBytes32(_oppositeBridge),
            _chainId,
            thisChainId,
            castToBytes32(_receiveSide),
            castToBytes32(msg.sender),
            nonce
        );
        IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainId, txID, msg.sender, nonce);
        emit RevertBurnRequest(txID, msg.sender);
    }

    function synthBatchAddLiquidity3PoolMintEUSD(
        address _from,
        SynthParams memory _synthParams,
        ICurveProxy.MetaMintEUSD memory _metaParams,
        ICurveProxy.TokenInput calldata tokenParams
    ) external {
        // require(IWhitelist(whitelist).tokenList(tokenParams.token), "Token must be whitelisted");

        bytes32 txId;
        uint256 generalNonce = IBridge(bridge).getNonce(_from);
        bytes32 generalTxId = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_from),
            generalNonce
        );

        txId = _synthesizeRequest(
            _from,
            tokenParams.token,
            tokenParams.amount,
            _metaParams.to,
            generalTxId,
            tokenParams.coinIndex
        );

        // encode call
        bytes memory out = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes(
                        "transitSynthBatchAddLiquidity3PoolMintEUSD((address,uint256,uint256,address,uint256,address),(address,uint256,uint256),bytes32)"
                    )
                )
            ),
            _metaParams,
            tokenParams,
            txId
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            generalTxId,
            _from,
            generalNonce
        );
    }

    function synthBatchMetaExchange(
        address _from,
        SynthParams memory _synthParams,
        ICurveProxy.MetaExchangeParams memory _metaParams,
        ICurveProxy.TokenInput calldata tokenParams
    ) external {
        // require(IWhitelist(whitelist).tokenList(tokenParams.token), "Token must be whitelisted");

        if (_metaParams.add != address(0)) {
            require(
                IWhitelist(whitelist).checkDestinationToken(_metaParams.remove, _metaParams.x),
                "Destination token must be whitelisted"
            );
        } else {
            require(
                IWhitelist(whitelist).checkDestinationToken(_metaParams.exchange, _metaParams.j),
                "Destination token must be whitelisted"
            );
        }
        bytes32 txId;
        uint256 generalNonce = IBridge(bridge).getNonce(_from);
        bytes32 generalTxId = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_from),
            generalNonce
        );

        txId = _synthesizeRequest(
            _from,
            tokenParams.token,
            tokenParams.amount,
            _metaParams.to,
            generalTxId,
            tokenParams.coinIndex
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes(
                        "transitSynthBatchMetaExchange((address,address,address,uint256,int128,int128,uint256,int128,uint256,address,address,address,address,uint256),(address,uint256,uint256),bytes32)"
                    )
                )
            ),
            _metaParams,
            tokenParams,
            txId
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            generalTxId,
            _from,
            generalNonce
        );
    }

    function synthBatchMetaExchangeWithSwap(
        ICurveProxy.TokenInput calldata _tokenParams,
        SynthParamsMetaSwap memory _synthParams,
        SynthParams memory _finalSynthParams,
        ICurveProxy.MetaExchangeParams memory _metaParams
    ) external {
        // require(IWhitelist(whitelist).tokenList(_tokenParams.token), "Token must be whitelisted");
        //require(IWhitelist(whitelist).tokenList(_synthParams.path), "Token must be whitelisted");
        if (_metaParams.add != address(0)) {
            require(
                IWhitelist(whitelist).checkDestinationToken(_metaParams.remove, _metaParams.x),
                "Destination token must be whitelisted"
            );
        } else {
            require(
                IWhitelist(whitelist).checkDestinationToken(_metaParams.exchange, _metaParams.j),
                "Destination token must be whitelisted"
            );
        }
        bytes32 txId;
        uint256 generalNonce = IBridge(bridge).getNonce(_synthParams.from);
        bytes32 generalTxId = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_synthParams.from),
            generalNonce
        );

        txId = _synthesizeRequest(
            _synthParams.from,
            _tokenParams.token,
            _tokenParams.amount,
            _metaParams.to,
            generalTxId,
            _tokenParams.coinIndex
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes(
                        "transitSynthBatchMetaExchangeWithSwap((address,address,address,uint256,int128,int128,uint256,int128,uint256,address,address,address,address,uint256),(address,uint256,uint256),bytes32,(address,address,uint256),(address,address,uint256,address,address,uint256,address,address,address,uint256,uint256,address,uint256))"
                    )
                )
            ),
            _metaParams,
            _tokenParams,
            txId,
            _finalSynthParams,
            _synthParams
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            generalTxId,
            _synthParams.from,
            generalNonce
        );
    }

    function tokenSwapRequest(
        SynthParamsMetaSwap memory _synthParams,
        SynthParams memory _finalSynthParams,
        uint256 amount
    ) external {
        uint256 generalNonce = IBridge(bridge).getNonce(_synthParams.from);
        bytes32 generalTxId = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.swapOppositeBridge),
            _synthParams.swapChainId,
            _synthParams.initialChainId,
            castToBytes32(_synthParams.swapReceiveSide),
            castToBytes32(_synthParams.from),
            generalNonce
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes(
                        "tokenSwap((address,address,uint256,address,address,uint256,address,address,address,uint256,uint256,address,uint256),(address,address,uint256),uint256)"
                    )
                )
            ),
            _synthParams,
            _finalSynthParams,
            amount
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synthParams.swapReceiveSide,
            _synthParams.swapOppositeBridge,
            _synthParams.swapChainId,
            generalTxId,
            _synthParams.from,
            generalNonce
        );
    }

    function _synthesizeRequest(
        address _from,
        address _token,
        uint256 _amount,
        address _to,
        bytes32 generalTxId,
        uint256 _coinIndex
    ) internal returns (bytes32 txId) {
        // require(IWhitelist(whitelist).tokenList(_token), "Token must be whitelisted");
        // require(tokenDecimalsData[castToBytes32(_token)].isApproved, "Portal: token must be verified");
        registerNewBalance(_token, _amount);
        txId = keccak256(abi.encodePacked(generalTxId, _coinIndex));
        TxState storage txState = requests[txId];
        txState.from = castToBytes32(_from);
        txState.to = castToBytes32(_to);
        txState.rtoken = castToBytes32(_token);
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequest(txId, _from, _to, _amount, _token);
    }

    // should be restricted in mainnets (test only)
    /**
     * @dev Changes bridge address
     * @param _bridge new bridge address
     */
    function changeBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    /**
     * @dev Creates token representation request
     * @param _rtoken real token address for representation
     */
    function createRepresentationRequest(address _rtoken) external {
        emit RepresentationRequest(_rtoken);
    }

    // implies manual verification point
    /**
     * @dev Manual representation request approve
     * @param _rtoken real token address
     * @param _decimals token decimals
     */
    function approveRepresentationRequest(bytes32 _rtoken, uint8 _decimals) external onlyOwner {
        tokenDecimalsData[_rtoken].tokenDecimals = _decimals;
        tokenDecimalsData[_rtoken].isApproved = true;

        emit ApprovedRepresentationRequest(_rtoken);
    }

    /**
     * @dev Set representation request approve state
     * @param _rtoken real token address
     * @param _decimals token decimals
     * @param _approve approval state
     */
    function approveRepresentationRequest(
        bytes32 _rtoken,
        uint8 _decimals,
        bool _approve
    ) external onlyOwner {
        tokenDecimalsData[_rtoken].tokenDecimals = _decimals;
        tokenDecimalsData[_rtoken].isApproved = _approve;

        emit ApprovedRepresentationRequest(_rtoken);
    }

    /**
     * @dev Returns token decimals
     * @param _rtoken token address
     */
    function tokenDecimals(bytes32 _rtoken) public view returns (uint8) {
        return tokenDecimalsData[_rtoken].tokenDecimals;
    }

    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }
}