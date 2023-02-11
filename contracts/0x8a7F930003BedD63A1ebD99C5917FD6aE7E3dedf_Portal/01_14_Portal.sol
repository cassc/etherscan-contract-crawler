// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/IBridge.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../utils/RelayRecipientUpgradeable.sol";
import "./interfaces/IWrapper.sol";
import "./metarouter/interfaces/IMetaRouter.sol";

/**
 * @title A contract that synthesizes tokens
 * @notice In order to create a synthetic representation on another network, the user must call synthesize function here
 * @dev All function calls are currently implemented without side effects
 */
contract Portal is RelayRecipientUpgradeable {
    /// ** PUBLIC states **

    address public wrapper;
    address public bridge;
    uint256 public requestCount;
    bool public paused;
    mapping(bytes32 => TxState) public requests;
    mapping(bytes32 => UnsynthesizeState) public unsynthesizeStates;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public tokenThreshold;
    mapping(address => bool) public tokenWhitelist;

    IMetaRouter public metaRouter;

    /// ** STRUCTS **

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
        address recipient;
        address chain2address;
        uint256 amount;
        address rtoken;
        RequestState state;
    }

    struct SynthesizeWithPermitTransaction {
        uint256 stableBridgingFee;
        bytes approvalData;
        address token;
        uint256 amount;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address revertableAddress;
        uint256 chainID;
        bytes32 clientID;
    }

    /// ** EVENTS **

    event SynthesizeRequest(
        bytes32 id,
        address indexed from,
        uint256 indexed chainID,
        address indexed revertableAddress,
        address to,
        uint256 amount,
        address token
    );

    event RevertBurnRequest(bytes32 indexed id, address indexed to);

    event ClientIdLog(bytes32 requestId, bytes32 indexed clientId);

    event MetaRevertRequest(bytes32 indexed id, address indexed to);

    event BurnCompleted(
        bytes32 indexed id,
        address indexed to,
        uint256 amount,
        uint256 bridgingFee,
        address token
    );

    event RevertSynthesizeCompleted(
        bytes32 indexed id,
        address indexed to,
        uint256 amount,
        uint256 bridgingFee,
        address token
    );

    event Paused(address account);

    event Unpaused(address account);

    event SetWhitelistToken(address token, bool activate);

    event SetTokenThreshold(address token, uint256 threshold);

    event SetMetaRouter(address metaRouter);

    /// ** MODIFIERs **

    modifier onlyBridge() {
        require(bridge == msg.sender, "Symb: caller is not the bridge");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Symb: paused");
        _;
    }

    /// ** INITIALIZER **

    /**
     * init
     */
    function initialize(
        address _bridge,
        address _trustedForwarder,
        address _wrapper,
        address _whitelistedToken,
        IMetaRouter _metaRouter
    ) public virtual initializer {
        __RelayRecipient_init(_trustedForwarder);
        bridge = _bridge;
        wrapper = _wrapper;
        metaRouter = _metaRouter;

        if (_whitelistedToken != address(0)) {
            tokenWhitelist[_whitelistedToken] = true;
        }
    }

    /// ** EXTERNAL PURE functions **

    /**
     * @notice Returns version
     */
    function versionRecipient() external pure returns (string memory) {
        return "2.0.1";
    }

    // ** EXTERNAL functions **

    /**
     * @notice Sends synthesize request
     * @dev Token -> sToken on a second chain
     * @param _stableBridgingFee Bridging fee on another network
     * @param _token The address of the token that the user wants to synthesize
     * @param _amount Number of tokens to synthesize
     * @param _chain2address The address to which the user wants to receive the synth asset on another network
     * @param _receiveSide Synthesis address on another network
     * @param _oppositeBridge Bridge address on another network
     * @param _revertableAddress An address on another network that allows the user to revert a stuck request
     * @param _chainID Chain id of the network where synthesization will take place
     */
    function synthesize(
        uint256 _stableBridgingFee,
        address _token,
        uint256 _amount,
        address _chain2address,
        address _receiveSide,
        address _oppositeBridge,
        address _revertableAddress,
        uint256 _chainID,
        bytes32 _clientID
    ) external whenNotPaused returns (bytes32) {
        require(tokenWhitelist[_token], "Symb: unauthorized token");
        require(_amount >= tokenThreshold[_token], "Symb: amount under threshold");
        TransferHelper.safeTransferFrom(
            _token,
            _msgSender(),
            address(this),
            _amount
        );

        return
        sendSynthesizeRequest(
            _stableBridgingFee,
            _token,
            _amount,
            _chain2address,
            _receiveSide,
            _oppositeBridge,
            _revertableAddress,
            _chainID,
            _clientID
        );
    }

    /**
     * @notice Sends metaSynthesizeOffchain request
     * @dev Token -> sToken on a second chain -> final token on a second chain
     * @param _metaSynthesizeTransaction metaSynthesize offchain transaction data
     */
    function metaSynthesize(
        MetaRouteStructs.MetaSynthesizeTransaction
        memory _metaSynthesizeTransaction
    ) external whenNotPaused returns (bytes32) {
        require(tokenWhitelist[_metaSynthesizeTransaction.rtoken], "Symb: unauthorized token");
        require(_metaSynthesizeTransaction.amount >= tokenThreshold[_metaSynthesizeTransaction.rtoken],
            "Symb: amount under threshold");

        TransferHelper.safeTransferFrom(
            _metaSynthesizeTransaction.rtoken,
            _msgSender(),
            address(this),
            _metaSynthesizeTransaction.amount
        );

        return sendMetaSynthesizeRequest(_metaSynthesizeTransaction);
    }

    /**
     * @notice Native -> sToken on a second chain
     * @param _stableBridgingFee Bridging fee on another network
     * @param _chain2address The address to which the user wants to receive the synth asset on another network
     * @param _receiveSide Synthesis address on another network
     * @param _oppositeBridge Bridge address on another network
     * @param _chainID Chain id of the network where synthesization will take place
     */
    function synthesizeNative(
        uint256 _stableBridgingFee,
        address _chain2address,
        address _receiveSide,
        address _oppositeBridge,
        address _revertableAddress,
        uint256 _chainID,
        bytes32 _clientID
    ) external payable whenNotPaused returns (bytes32) {
        require(tokenWhitelist[wrapper], "Symb: unauthorized token");
        require(msg.value >= tokenThreshold[wrapper], "Symb: amount under threshold");

        IWrapper(wrapper).deposit{value : msg.value}();

        return
        sendSynthesizeRequest(
            _stableBridgingFee,
            wrapper,
            msg.value,
            _chain2address,
            _receiveSide,
            _oppositeBridge,
            _revertableAddress,
            _chainID,
            _clientID
        );
    }

    /**
     * @notice Token -> sToken on a second chain withPermit
     * @param _syntWithPermitTx SynthesizeWithPermit offchain transaction data
     */
    function synthesizeWithPermit(
        SynthesizeWithPermitTransaction memory _syntWithPermitTx
    ) external whenNotPaused returns (bytes32) {
        require(tokenWhitelist[_syntWithPermitTx.token], "Symb: unauthorized token");
        require(_syntWithPermitTx.amount >= tokenThreshold[_syntWithPermitTx.token], "Symb: amount under threshold");
        {
            (
            address owner,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
            ) = abi.decode(
                _syntWithPermitTx.approvalData,
                (address, uint256, uint256, uint8, bytes32, bytes32)
            );
            IERC20Permit(_syntWithPermitTx.token).permit(
                owner,
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }

        TransferHelper.safeTransferFrom(
            _syntWithPermitTx.token,
            _msgSender(),
            address(this),
            _syntWithPermitTx.amount
        );

        return
        sendSynthesizeRequest(
            _syntWithPermitTx.stableBridgingFee,
            _syntWithPermitTx.token,
            _syntWithPermitTx.amount,
            _syntWithPermitTx.chain2address,
            _syntWithPermitTx.receiveSide,
            _syntWithPermitTx.oppositeBridge,
            _syntWithPermitTx.revertableAddress,
            _syntWithPermitTx.chainID,
            _syntWithPermitTx.clientID
        );
    }

    /**
     * @notice Emergency unsynthesize
     * @dev Can called only by bridge after initiation on a second chain
     * @dev If a transaction arrives at the synthesization chain with an already completed revert synthesize contract will fail this transaction,
     * since the state was changed during the call to the desynthesis request
     * @param _stableBridgingFee Bridging fee
     * @param _externalID the synthesize transaction that was received from the event when it was originally called synthesize on the Portal contract
     */
    function revertSynthesize(uint256 _stableBridgingFee, bytes32 _externalID) external onlyBridge whenNotPaused {
        TxState storage txState = requests[_externalID];
        require(
            txState.state == RequestState.Sent,
            "Symb: state not open or tx does not exist"
        );
        txState.state = RequestState.Reverted;
        // close
        balanceOf[txState.rtoken] = balanceOf[txState.rtoken] - txState.amount;

        TransferHelper.safeTransfer(
            txState.rtoken,
            txState.recipient,
            txState.amount - _stableBridgingFee
        );

        TransferHelper.safeTransfer(
            txState.rtoken,
            bridge,
            _stableBridgingFee
        );

        emit RevertSynthesizeCompleted(
            _externalID,
            txState.recipient,
            txState.amount - _stableBridgingFee, 
            _stableBridgingFee,
            txState.rtoken
        );
    }

    /**
     * @notice Revert synthesize
     * @dev After revertSynthesizeRequest in Synthesis this method is called
     * @param _stableBridgingFee Bridging fee
     * @param _externalID the burn transaction that was received from the event when it was originally called burn on the Synthesis contract
     * @param _token The address of the token to unsynthesize
     * @param _amount Number of tokens to unsynthesize
     * @param _to The address to receive tokens
     */
    function unsynthesize(
        uint256 _stableBridgingFee,
        bytes32 _externalID,
        address _token,
        uint256 _amount,
        address _to
    ) external onlyBridge whenNotPaused {
        require(
            unsynthesizeStates[_externalID] == UnsynthesizeState.Default,
            "Symb: synthetic tokens emergencyUnburn"
        );
        balanceOf[_token] = balanceOf[_token] - _amount;
        unsynthesizeStates[_externalID] = UnsynthesizeState.Unsynthesized;
        TransferHelper.safeTransfer(_token, _to, _amount - _stableBridgingFee);
        TransferHelper.safeTransfer(_token, bridge, _stableBridgingFee);
        emit BurnCompleted(_externalID, _to, _amount - _stableBridgingFee, _stableBridgingFee, _token);
    }

    /**
     * @notice Unsynthesize and final call on second chain
     * @dev Token -> sToken on a first chain -> final token on a second chain
     * @param _stableBridgingFee Number of tokens to send to bridge (fee)
     * @param _externalID the metaBurn transaction that was received from the event when it was originally called metaBurn on the Synthesis contract
     * @param _to The address to receive tokens
     * @param _amount Number of tokens to unsynthesize
     * @param _rToken The address of the token to unsynthesize
     * @param _finalReceiveSide router for final call
     * @param _finalCalldata encoded call of a final function
     * @param _finalOffset offset to patch _amount to _finalCalldata
     */
    function metaUnsynthesize(
        uint256 _stableBridgingFee,
        bytes32 _externalID,
        address _to,
        uint256 _amount,
        address _rToken,
        address _finalReceiveSide,
        bytes memory _finalCalldata,
        uint256 _finalOffset
    ) external onlyBridge whenNotPaused {
        require(
            unsynthesizeStates[_externalID] == UnsynthesizeState.Default,
            "Symb: synthetic tokens emergencyUnburn"
        );

        balanceOf[_rToken] = balanceOf[_rToken] - _amount;
        unsynthesizeStates[_externalID] = UnsynthesizeState.Unsynthesized;
        TransferHelper.safeTransfer(_rToken, bridge, _stableBridgingFee);
        _amount = _amount - _stableBridgingFee;

        if (_finalCalldata.length == 0) {
            TransferHelper.safeTransfer(_rToken, _to, _amount);
            emit BurnCompleted(_externalID, address(this), _amount, _stableBridgingFee, _rToken);
            return;
        }

        // transfer ERC20 tokens to MetaRouter
        TransferHelper.safeTransfer(
            _rToken,
            address(metaRouter),
            _amount
        );

        // metaRouter call
        metaRouter.externalCall(_rToken, _amount, _finalReceiveSide, _finalCalldata, _finalOffset);

        emit BurnCompleted(_externalID, address(this), _amount, _stableBridgingFee, _rToken);
    }

    /**
     * @notice Revert burnSyntheticToken() operation
     * @dev Can called only by bridge after initiation on a second chain
     * @dev Further, this transaction also enters the relay network and is called on the other side under the method "revertBurn"
     * @param _stableBridgingFee Bridging fee on another network
     * @param _internalID the synthesize transaction that was received from the event when it was originally called burn on the Synthesize contract
     * @param _receiveSide Synthesis address on another network
     * @param _oppositeBridge Bridge address on another network
     * @param _chainId Chain id of the network
     */
    function revertBurnRequest(
        uint256 _stableBridgingFee,
        bytes32 _internalID,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId,
        bytes32 _clientID
    ) external whenNotPaused {
        bytes32 externalID = keccak256(abi.encodePacked(_internalID, address(this), _msgSender(), block.chainid));

        require(
            unsynthesizeStates[externalID] != UnsynthesizeState.Unsynthesized,
            "Symb: Real tokens already transfered"
        );
        unsynthesizeStates[externalID] = UnsynthesizeState.RevertRequest;

        {
            bytes memory out = abi.encodeWithSelector(
                bytes4(keccak256(bytes("revertBurn(uint256,bytes32)"))),
                _stableBridgingFee,
                externalID
            );
            IBridge(bridge).transmitRequestV2(
                out,
                _receiveSide,
                _oppositeBridge,
                _chainId
            );
        }

        emit RevertBurnRequest(_internalID, _msgSender());
        emit ClientIdLog(_internalID, _clientID);
    }

     function metaRevertRequest(
        MetaRouteStructs.MetaRevertTransaction memory _metaRevertTransaction
    ) external whenNotPaused {
         if (_metaRevertTransaction.swapCalldata.length != 0){
            bytes32 externalID = keccak256(abi.encodePacked(_metaRevertTransaction.internalID, address(this), _msgSender(), block.chainid));

            require(
                unsynthesizeStates[externalID] != UnsynthesizeState.Unsynthesized,
                "Symb: Real tokens already transfered"
            );

            unsynthesizeStates[externalID] = UnsynthesizeState.RevertRequest;

            {
                bytes memory out = abi.encodeWithSelector(
                    bytes4(keccak256(bytes("revertMetaBurn(uint256,bytes32,address,bytes,address,address,bytes)"))),
                        _metaRevertTransaction.stableBridgingFee,
                        externalID,
                        _metaRevertTransaction.router,
                        _metaRevertTransaction.swapCalldata,
                        _metaRevertTransaction.sourceChainSynthesis,
                        _metaRevertTransaction.burnToken,
                        _metaRevertTransaction.burnCalldata
                );

                IBridge(bridge).transmitRequestV2(
                    out,
                    _metaRevertTransaction.receiveSide,
                    _metaRevertTransaction.managerChainBridge,
                    _metaRevertTransaction.managerChainId
                );
                emit RevertBurnRequest(_metaRevertTransaction.internalID, _msgSender());
                emit ClientIdLog(_metaRevertTransaction.internalID, _metaRevertTransaction.clientID);
            }
         } else {
             if (_metaRevertTransaction.burnCalldata.length != 0){
                 bytes32 externalID = keccak256(abi.encodePacked(_metaRevertTransaction.internalID, address(this), _msgSender(), block.chainid));

                 require(
                     unsynthesizeStates[externalID] != UnsynthesizeState.Unsynthesized,
                     "Symb: Real tokens already transfered"
                 );

                 unsynthesizeStates[externalID] = UnsynthesizeState.RevertRequest;

                 bytes memory out = abi.encodeWithSelector(
                     bytes4(keccak256(bytes("revertBurnAndBurn(uint256,bytes32,address,address,uint256,address)"))),
                        _metaRevertTransaction.stableBridgingFee,
                         externalID,
                         address(this),
                        _metaRevertTransaction.sourceChainBridge,
                        block.chainid,
                        _msgSender()
                 );

                 IBridge(bridge).transmitRequestV2(
                     out,
                     _metaRevertTransaction.sourceChainSynthesis,
                     _metaRevertTransaction.managerChainBridge,
                     _metaRevertTransaction.managerChainId
                 );
                 emit RevertBurnRequest(_metaRevertTransaction.internalID, _msgSender());
                 emit ClientIdLog(_metaRevertTransaction.internalID, _metaRevertTransaction.clientID);
             } else {
                 bytes memory out = abi.encodeWithSelector(
                     bytes4(keccak256(bytes("revertSynthesizeRequestByBridge(uint256,bytes32,address,address,uint256,address,bytes32)"))),
                        _metaRevertTransaction.stableBridgingFee,
                        _metaRevertTransaction.internalID,
                        _metaRevertTransaction.receiveSide,
                        _metaRevertTransaction.sourceChainBridge,
                        block.chainid,
                        _msgSender(),
                        _metaRevertTransaction.clientID
                 );

                 IBridge(bridge).transmitRequestV2(
                     out,
                     _metaRevertTransaction.sourceChainSynthesis,
                     _metaRevertTransaction.managerChainBridge,
                     _metaRevertTransaction.managerChainId
                 );
             }
         }
         emit MetaRevertRequest(_metaRevertTransaction.internalID, _msgSender());
    }

    // ** ONLYOWNER functions **

    /**
     * @notice Set paused flag to true
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice Set paused flag to false
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @notice Sets token to tokenWhitelist
     * @param _token Address of token to add to whitelist
     * @param _activate true - add to whitelist, false - remove from whitelist
     */
    function setWhitelistToken(address _token, bool _activate) external onlyOwner {
        tokenWhitelist[_token] = _activate;
        emit SetWhitelistToken(_token, _activate);
    }

    /**
     * @notice Sets minimal price for token
     * @param _token Address of token to set threshold
     * @param _threshold threshold to set
     */
    function setTokenThreshold(address _token, uint256 _threshold) external onlyOwner {
        tokenThreshold[_token] = _threshold;
        emit SetTokenThreshold(_token, _threshold);
    }

    /**
     * @notice Sets MetaRouter address
     * @param _metaRouter Address of metaRouter
     */
    function setMetaRouter(IMetaRouter _metaRouter) external onlyOwner {
        require(address(_metaRouter) != address(0), "Symb: metaRouter cannot be zero address");
        metaRouter = _metaRouter;
        emit SetMetaRouter(address(_metaRouter));
    }

    /// ** INTERNAL functions **

    /**
     * @dev Sends synthesize request
     * @dev Internal function used in synthesize, synthesizeNative, synthesizeWithPermit
     */
    function sendSynthesizeRequest(
        uint256 _stableBridgingFee,
        address _token,
        uint256 _amount,
        address _chain2address,
        address _receiveSide,
        address _oppositeBridge,
        address _revertableAddress,
        uint256 _chainID,
        bytes32 _clientID
    ) internal returns (bytes32 internalID) {
        balanceOf[_token] = balanceOf[_token] + _amount;

        if (_revertableAddress == address(0)) {
            _revertableAddress = _chain2address;
        }

        internalID = keccak256(abi.encodePacked(this, requestCount, block.chainid));
        {
            bytes32 externalID = keccak256(abi.encodePacked(internalID, _receiveSide, _revertableAddress, _chainID));

            {
                bytes memory out = abi.encodeWithSelector(
                    bytes4(
                        keccak256(
                            bytes(
                                "mintSyntheticToken(uint256,bytes32,address,uint256,uint256,address)"
                            )
                        )
                    ),
                    _stableBridgingFee,
                    externalID,
                    _token,
                    block.chainid,
                    _amount,
                    _chain2address
                );

                requests[externalID] = TxState({
                recipient : _msgSender(),
                chain2address : _chain2address,
                rtoken : _token,
                amount : _amount,
                state : RequestState.Sent
                });

                requestCount++;
                IBridge(bridge).transmitRequestV2(
                    out,
                    _receiveSide,
                    _oppositeBridge,
                    _chainID
                );
            }
        }

        emit SynthesizeRequest(
            internalID,
            _msgSender(),
            _chainID,
            _revertableAddress,
            _chain2address,
            _amount,
            _token
        );
        emit ClientIdLog(internalID, _clientID);
    }

    /**
     * @dev Sends metaSynthesizeOffchain request
     * @dev Internal function used in metaSynthesizeOffchain
     */
    function sendMetaSynthesizeRequest(
        MetaRouteStructs.MetaSynthesizeTransaction
        memory _metaSynthesizeTransaction
    ) internal returns (bytes32 internalID) {
        balanceOf[_metaSynthesizeTransaction.rtoken] =
        balanceOf[_metaSynthesizeTransaction.rtoken] +
        _metaSynthesizeTransaction.amount;

        if (_metaSynthesizeTransaction.revertableAddress == address(0)) {
            _metaSynthesizeTransaction.revertableAddress = _metaSynthesizeTransaction.chain2address;
        }

        internalID = keccak256(abi.encodePacked(this, requestCount, block.chainid));
        bytes32 externalID = keccak256(
            abi.encodePacked(internalID, _metaSynthesizeTransaction.receiveSide, _metaSynthesizeTransaction.revertableAddress, _metaSynthesizeTransaction.chainID)
        );

        MetaRouteStructs.MetaMintTransaction
        memory _metaMintTransaction = MetaRouteStructs.MetaMintTransaction(
            _metaSynthesizeTransaction.stableBridgingFee,
            _metaSynthesizeTransaction.amount,
            externalID,
            _metaSynthesizeTransaction.rtoken,
            block.chainid,
            _metaSynthesizeTransaction.chain2address,
            _metaSynthesizeTransaction.swapTokens,
            _metaSynthesizeTransaction.secondDexRouter,
            _metaSynthesizeTransaction.secondSwapCalldata,
            _metaSynthesizeTransaction.finalReceiveSide,
            _metaSynthesizeTransaction.finalCalldata,
            _metaSynthesizeTransaction.finalOffset
        );

        {
            bytes memory out = abi.encodeWithSignature(
            "metaMintSyntheticToken((uint256,uint256,bytes32,address,uint256,address,address[],"
            "address,bytes,address,bytes,uint256))",
            _metaMintTransaction
            );

            requests[externalID] = TxState({
            recipient : _metaSynthesizeTransaction.syntCaller,
            chain2address : _metaSynthesizeTransaction.chain2address,
            rtoken : _metaSynthesizeTransaction.rtoken,
            amount : _metaSynthesizeTransaction.amount,
            state : RequestState.Sent
            });

            requestCount++;
            IBridge(bridge).transmitRequestV2(
                out,
                _metaSynthesizeTransaction.receiveSide,
                _metaSynthesizeTransaction.oppositeBridge,
                _metaSynthesizeTransaction.chainID
            );
        }

        emit SynthesizeRequest(
            internalID,
            _metaSynthesizeTransaction.syntCaller,
            _metaSynthesizeTransaction.chainID,
            _metaSynthesizeTransaction.revertableAddress,
            _metaSynthesizeTransaction.chain2address,
            _metaSynthesizeTransaction.amount,
            _metaSynthesizeTransaction.rtoken
        );
        emit ClientIdLog(internalID, _metaSynthesizeTransaction.clientID);
    }
}