// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-newone/utils/Create2.sol";
import "@openzeppelin/contracts-newone/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./IBridge.sol";
import "./ISyntERC20.sol";
import "./SyntERC20.sol";
import "../utils/Typecast.sol";
import "./RequestIdLib.sol";
import "../interfaces/ICurveProxy.sol";

contract Synthesis is Typecast, ContextUpgradeable, OwnableUpgradeable  {
    mapping(address => bytes32) public representationReal;
    mapping(bytes32 => address) public representationSynt;
    mapping(bytes32 => uint8) public tokenDecimals;
    bytes32[] private keys;
    mapping(bytes32 => TxState) public requests;
    mapping(bytes32 => SynthesizeState) public synthesizeStates;
    address public bridge;
    address public proxy;
    address public proxyV2;
    string public versionRecipient;
    uint256 public thisChainId;
    address public trustedForwarder;

    bytes public constant sighashUnsynthesize =
        abi.encodePacked(uint8(115), uint8(234), uint8(111), uint8(109), uint8(131), uint8(167), uint8(37), uint8(70));
    bytes public constant sighashEmergencyUnsynthesize =
        abi.encodePacked(uint8(102), uint8(107), uint8(151), uint8(50), uint8(141), uint8(172), uint8(244), uint8(63));

    enum UnsynthesizePubkeys {
        receiveSide,
        receiveSideData,
        oppositeBridge,
        oppositeBridgeData,
        txState,
        source,
        destination,
        realToken
    }

    enum RequestState {
        Default,
        Sent,
        Reverted
    }
    enum SynthesizeState {
        Default,
        Synthesized,
        RevertRequest
    }

    event BurnRequest(bytes32 indexed id, address indexed from, address indexed to, uint256 amount, address token);
    event RevertSynthesizeRequest(bytes32 indexed id, address indexed to);
    event SynthesizeCompleted(bytes32 indexed id, address indexed to, uint256 amount, address token);
    event SynthTransfer(
        bytes32 indexed id,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 realToken
    );
    event RevertBurnCompleted(bytes32 indexed id, address indexed to, uint256 amount, address token);
    event CreatedRepresentation(bytes32 indexed rtoken, address indexed stoken);

    function initializeFunc(address _bridge, address _trustedForwarder, uint256 _thisChainId) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        versionRecipient = "2.2.3";
        bridge = _bridge;
        trustedForwarder =_trustedForwarder;
        thisChainId = _thisChainId;
    }

    modifier onlyBridge() {
        require(bridge == msg.sender, "Synthesis: bridge only");
        _;
    }

    modifier onlyTrusted() {
        require(bridge == msg.sender || proxy == msg.sender || proxyV2 == msg.sender, "Synthesis: only trusted contract");
        _;
    }

    struct TxState {
        bytes32 from;
        bytes32 to;
        uint256 amount;
        bytes32 token;
        address stoken;
        RequestState state;
    }

    struct SynthParams {
        address receiveSide;
        address oppositeBridge;
        uint256 chainId;
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

    struct RepresentationParams {
        bytes32 rtoken;
        uint8 decimals;
        string name;
        string symbol;
        uint256 chainId;
        string chainSymbol;
    }

    /**
     * @dev Mints synthetic token. Can be called only by bridge after initiation on a second chain.
     * @param _txID transaction ID
     * @param _tokenReal real token address
     * @param _amount amount to mint
     * @param _to recipient address
     */
    function mintSyntheticToken(
        bytes32 _txID,
        address _tokenReal,
        uint256 _amount,
        address _to
    ) external onlyTrusted {
        require(
            synthesizeStates[_txID] == SynthesizeState.Default,
            "Synthesis: emergencyUnsynthesizedRequest called or tokens have been synthesized"
        );

        ISyntERC20(representationSynt[castToBytes32(_tokenReal)]).mint(_to, _amount);
        synthesizeStates[_txID] = SynthesizeState.Synthesized;

        emit SynthesizeCompleted(_txID, _to, _amount, _tokenReal);
    }

    function mintSyntheticTokenWithSwap(
        bytes32 _txID,
        address _tokenReal,
        uint256 _amount,
        address _curveProxyV2,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        uint256 coinIndex
    ) external onlyTrusted {
        require(
            synthesizeStates[_txID] == SynthesizeState.Default,
            "Synthesis: emergencyUnsynthesizedRequest called or tokens have been synthesized"
        );

        ISyntERC20(representationSynt[castToBytes32(_tokenReal)]).mint(_curveProxyV2, _amount);
        synthesizeStates[_txID] = SynthesizeState.Synthesized;

        emit SynthesizeCompleted(_txID, _curveProxyV2, _amount, _tokenReal);

        ICurveProxy.FeeParams memory feeParams = ICurveProxy.FeeParams(
            address(0),
            0,
            coinIndex
        );

        ICurveProxy(_curveProxyV2).tokenSwapWithMetaExchange(_exchangeParams, _params, _finalSynthParams, feeParams);
    }

    /**
     * @dev Transfers synthetic token to another chain.
     * @param _tokenSynth synth token address
     * @param _amount amount to transfer
     * @param _to recipient address
     * @param _from msg sender address
     * @param _synthParams synth transfer parameters
     */
    function synthTransfer(
        address _tokenSynth,
        uint256 _amount,
        address _from,
        address _to,
        SynthParams calldata _synthParams
    ) external {
        require(_tokenSynth != address(0), "Synthesis: synth address zero");
        bytes32 tokenReal = representationReal[_tokenSynth];
        require(tokenReal != 0, "Synthesis: real token not found");
        require(
            ISyntERC20(_tokenSynth).getChainId() != _synthParams.chainId,
            "Synthesis: can not synthesize in the intial chain"
        );
        ISyntERC20(_tokenSynth).burn(msg.sender, _amount);

        uint256 nonce = IBridge(bridge).getNonce(_from);
        bytes32 txID = RequestIdLib.prepareRqId(
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
            tokenReal,
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
        txState.stoken = _tokenSynth;
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthTransfer(txID, _from, _to, _amount, tokenReal);
    }

    /**
     * @dev Revert synthesize() operation, can be called several times.
     * @param _txID transaction ID
     * @param _receiveSide request recipient address
     * @param _oppositeBridge opposite bridge address
     * @param _chainId opposite chain ID
     * @param _v must be a valid part of the signature from tx owner
     * @param _r must be a valid part of the signature from tx owner
     * @param _s must be a valid part of the signature from tx owner
     */
    function emergencyUnsyntesizeRequest(
        bytes32 _txID,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(synthesizeStates[_txID] != SynthesizeState.Synthesized, "Synthesis: synthetic tokens already minted");
        synthesizeStates[_txID] = SynthesizeState.RevertRequest; // close
        bytes memory out = abi.encodeWithSelector(
            bytes4(keccak256(bytes("emergencyUnsynthesize(bytes32,address,uint8,bytes32,bytes32"))),
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

        emit RevertSynthesizeRequest(txID, msg.sender);
    }

    /**
     * @dev Burns given synthetic token and unlocks the original one in the destination chain.
     * @param _stoken transaction ID
     * @param _amount amount to burn
     * @param _to recipient address
     * @param _synthParams transfer parameters
     */
    function burnSyntheticToken(
        address _stoken,
        uint256 _amount,
        address _from,
        address _to,
        SynthParams calldata _synthParams
    ) external returns (bytes32 txID) {
        ISyntERC20(_stoken).burn(msg.sender, _amount);
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
            bytes4(keccak256(bytes("unsynthesize(bytes32,address,uint256,address)"))),
            txID,
            representationReal[_stoken],
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
        txState.stoken = _stoken;
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit BurnRequest(txID, _from, _to, _amount, _stoken);
    }

    function burnSyntheticTokenWithSwap(
        address _stoken,
        uint256 _amount,
        address _from,
        address _to,
        SynthParams calldata _synthParams,
        SynthParamsMetaSwap calldata _synthSwapParams,
        SynthParams calldata _finalSynthParams
    ) external returns (bytes32 txID) {
        ISyntERC20(_stoken).burn(msg.sender, _amount);
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
            bytes4(keccak256(bytes("unsynthesizeWithSwap(bytes32,address,uint256,address,(address,address,uint256,address,address,uint256,address,address,address,uint256,uint256,address,uint256),(address,address,uint256))"))),
            txID,
            representationReal[_stoken],
            _amount,
            _to,
            _synthSwapParams,
            _finalSynthParams
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
        txState.stoken = _stoken;
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit BurnRequest(txID, _from, _to, _amount, _stoken);
    }

    function burnSyntheticTokenWithMetaExchange(
        IPortal.SynthesizeParams calldata _tokenParams,
        ICurveProxy.tokenSwapWithMetaParams calldata _exchangeParams,
        ICurveProxy.MetaExchangeParams calldata _params,
        IPortal.SynthParams calldata _finalSynthParams,
        IPortal.SynthParams calldata _synthParams,
        ICurveProxy.FeeParams memory _feeParams
    ) external returns (bytes32 txID) {
        ISyntERC20(_tokenParams.token).burn(msg.sender, _tokenParams.amount);
        uint256 nonce = IBridge(bridge).getNonce(_tokenParams.from);
        txID = RequestIdLib.prepareRqId(
            castToBytes32(_synthParams.oppositeBridge),
            _synthParams.chainId,
            thisChainId,
            castToBytes32(_synthParams.receiveSide),
            castToBytes32(_tokenParams.from),
            nonce
        );

        IBridge(bridge).transmitRequestV2(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("unsynthesizeWithMetaExchange(bytes32,address,uint256,address,(address,uint256,address,uint256,uint256,address),(address,address,address,uint256,int128,int128,uint256,int128,uint256,address,address,address,address,uint256),(address,address,uint256),(address,uint256,uint256))"))),
                txID,
                representationReal[_tokenParams.token],
                _tokenParams.amount,
                _tokenParams.to,
                _exchangeParams,
                _params,
                _finalSynthParams,
                _feeParams
            ),
            _synthParams.receiveSide,
            _synthParams.oppositeBridge,
            _synthParams.chainId,
            txID,
            _tokenParams.from,
            nonce
        );
        TxState storage txState = requests[txID];
        txState.from = castToBytes32(_tokenParams.from);
        txState.to = castToBytes32(_tokenParams.to);
        txState.stoken = _tokenParams.token;
        txState.amount = _tokenParams.amount;
        txState.state = RequestState.Sent;

        emit BurnRequest(txID, _tokenParams.from, _tokenParams.to, _tokenParams.amount, _tokenParams.token);
    }

    /**
     * @dev Emergency unburn request. Can be called only by bridge after initiation on a second chain
     * @param _txID transaction ID to use unburn on
     */
    function emergencyUnburn(
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
                "emergencyUnburn(bytes32,address,uint8,bytes32,bytes32)"
            )
        );
        address txOwner = ECDSA.recover(ECDSA.toEthSignedMessageHash(emergencyStructHash), _v, _r, _s);
        require(txState.state == RequestState.Sent, "Synthesis: state not open or tx does not exist");
        require(txState.from == castToBytes32(txOwner), "Synthesis: invalid tx owner");
        txState.state = RequestState.Reverted; // close
        ISyntERC20(txState.stoken).mint(castToAddress(txState.from), txState.amount);

        emit RevertBurnCompleted(_txID, castToAddress(txState.from), txState.amount, txState.stoken);
    }

    /**
     * @dev Creates a representation with the given arguments.
     * @param _rtoken real token address
     * @param _name real token name
     * @param _decimals real token decimals number
     * @param _symbol real token symbol
     * @param _chainId real token chain id
     * @param _chainSymbol real token chain symbol
     */
    function createRepresentation(
        bytes32 _rtoken,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        uint256 _chainId,
        string memory _chainSymbol
    ) external onlyOwner {
        require(representationSynt[_rtoken] == address(0), "Synthesis: representation already exists");
        require(representationReal[castToAddress(_rtoken)] == 0, "Synthesis: representation already exists");
        address stoken = Create2.deploy(
            0,
            keccak256(abi.encodePacked(_rtoken)),
            abi.encodePacked(
                type(SyntERC20).creationCode,
                abi.encode(
                    string(abi.encodePacked("s", _name, "_", _chainSymbol)),
                    string(abi.encodePacked("s", _symbol, "_", _chainSymbol)),
                    _decimals,
                    _chainId,
                    _rtoken,
                    _chainSymbol
                )
            )
        );
        setRepresentation(_rtoken, stoken, _decimals);
        emit CreatedRepresentation(_rtoken, stoken);
    }

    function createRepresentationBatch(
        RepresentationParams[] calldata params
    ) external onlyOwner {
        for(uint256 i; i<params[i].rtoken.length; i++){
            require(representationSynt[params[i].rtoken] == address(0), "Synthesis: representation already exists");
            require(representationReal[castToAddress(params[i].rtoken)] == 0, "Synthesis: representation already exists");
            address stoken = Create2.deploy(
                0,
                keccak256(abi.encodePacked(params[i].rtoken)),
                abi.encodePacked(
                    type(SyntERC20).creationCode,
                    abi.encode(
                        string(abi.encodePacked("s", params[i].name, "_", params[i].chainSymbol)),
                        string(abi.encodePacked("s", params[i].symbol, "_", params[i].chainSymbol)),
                        params[i].decimals,
                        params[i].chainId,
                        params[i].rtoken,
                        params[i].chainSymbol
                    )
                )
            );
            setRepresentation(params[i].rtoken, stoken, params[i].decimals);
            emit CreatedRepresentation(params[i].rtoken, stoken);
        }
    }

    /**
     * @dev Creates a custom representation with the given arguments.
     * @param _rtoken real token address
     * @param _name real token name
     * @param _decimals real token decimals number
     * @param _symbol real token symbol
     * @param _chainId real token chain id
     * @param _chainSymbol real token chain symbol
     */
    function createCustomRepresentation(
        bytes32 _rtoken,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        uint256 _chainId,
        string memory _chainSymbol
    ) external onlyOwner {
        require(representationSynt[_rtoken] == address(0), "Synthesis: representation already exists");
        require(representationReal[castToAddress(_rtoken)] == 0, "Synthesis: representation already exists");
        address stoken = Create2.deploy(
            0,
            keccak256(abi.encodePacked(_rtoken)),
            abi.encodePacked(
                type(SyntERC20).creationCode,
                abi.encode(_name, _symbol, _decimals, _chainId, _rtoken, _chainSymbol)
            )
        );
        setRepresentation(_rtoken, stoken, _decimals);
        emit CreatedRepresentation(_rtoken, stoken);
    }

    /**
     * @dev Recreates a custom representation with the given arguments.
     * @param _rtoken real token address
     * @param _name real token name
     * @param _decimals real token decimals number
     * @param _symbol real token symbol
     * @param _chainId real token chain id
     * @param _chainSymbol real token chain symbol
     */
    function recreateCustomRepresentation(
        bytes32 _rtoken,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        uint256 _chainId,
        string memory _chainSymbol
    ) external onlyOwner {
        address stoken = Create2.deploy(
            0,
            keccak256(abi.encodePacked(_rtoken)),
            abi.encodePacked(
                type(SyntERC20).creationCode,
                abi.encode(_name, _symbol, _decimals, _chainId, _rtoken, _chainSymbol)
            )
        );
        setRepresentation(_rtoken, stoken, _decimals);
        emit CreatedRepresentation(_rtoken, stoken);
    }

    // TODO should be restricted in mainnets (use DAO)
    function changeBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    function setRepresentation(
        bytes32 _rtoken,
        address _stoken,
        uint8 _decimals
    ) internal {
        representationSynt[_rtoken] = _stoken;
        representationReal[_stoken] = _rtoken;
        tokenDecimals[_rtoken] = _decimals;
        keys.push(_rtoken);
    }

    /**
     * @dev Get token representation address
     * @param _rtoken real token address
     */
    function getRepresentation(bytes32 _rtoken) external view returns (address) {
        return representationSynt[_rtoken];
    }

    /**
     * @dev Get real token address
     * @param _stoken synthetic token address
     */
    function getRealTokenAddress(address _stoken) external view returns (bytes32) {
        return representationReal[_stoken];
    }

    /**
     * @dev Get token representation list
     */
    function getListRepresentation() external view returns (bytes32[] memory, address[] memory) {
        uint256 len = keys.length;
        address[] memory sToken = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            sToken[i] = representationSynt[keys[i]];
        }
        return (keys, sToken);
    }

    /**
     * @dev Set new CurveProxy address
     * @param _proxy new contract address
     */
    function setCurveProxy(address _proxy) external onlyOwner {
        proxy = _proxy;
    }

    /**
     * @dev Set new CurveProxyV2 address
     * @param _proxy new contract address
     */
    function setCurveProxyV2(address _proxy) external onlyOwner {
        proxyV2 = _proxy;
    }
}