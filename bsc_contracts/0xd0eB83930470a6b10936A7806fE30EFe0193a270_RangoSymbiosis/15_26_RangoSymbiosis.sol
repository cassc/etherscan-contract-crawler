// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../interfaces/IWETH.sol";
import "../base/BaseProxyContract.sol";
import "../../interfaces/IRangoSymbiosis.sol";
import "../../interfaces/ISymbiosisMetaRouter.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/IRangoSymbiosis.sol";
import "../../interfaces/IUniswapV2.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";


/// @title The root contract that handles Rango's interaction with symbiosis
/// @author Rza
/// @dev This is deployed as a separate contract from RangoV1
contract RangoSymbiosis is IRangoSymbiosis, BaseInterchainContract {
    /// @notice The address of symbiosis meta router contract
    address symbiosisMetaRouter;
    /// @notice The address of symbiosis meta router gateway contract
    address symbiosisMetaRouterGateway;

    /// @notice Emits when the symbiosis contracts address is updated
    /// @param _oldMetaRouter The previous address for MetaRouter contract
    /// @param _oldMetaRouterGateway The previous address for MetaRouterGateway contract
    /// @param _newMetaRouter The updated address for MetaRouter contract
    /// @param _newMetaRouterGateway The updated address for MetaRouterGateway contract
    event SymbiosisAddressUpdated(
        address _oldMetaRouter,
        address _oldMetaRouterGateway,
        address indexed _newMetaRouter,
        address indexed _newMetaRouterGateway
    );

    /// @notice A series of events with different status value to help us track the progress of cross-chain swap
    /// @param token The token address in the current network that is being bridged
    /// @param outputAmount The latest observed amount in the path, aka: input amount for source and output amount on dest
    /// @param status The latest status of the overall flow
    /// @param source The source address that initiated the transaction
    /// @param destination The destination address that received the money, ZERO address if not sent to the end-user yet
    event SymbiosisSwapStatusUpdated(
        address token,
        uint256 outputAmount,
        OperationStatus status,
        address source,
        address destination
    );

    /// @notice The constructor of this contract that receives WETH address and initiates the settings
    /// @param _weth The address of WETH, WBNB, etc of the current network
    function initialize(address _weth, address _metaRouter, address _metaRouterGateway) public initializer {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.WETH = _weth;
        symbiosisMetaRouter = _metaRouter;
        symbiosisMetaRouterGateway = _metaRouterGateway;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Updates the address of symbiosis contract
    /// @param _metaRouter The new address of symbiosis MetaRouter contract
    /// @param _metaRouterGateway The new address of symbiosis MetaRouterGateway contract
    function updateSymbiosisAddress(address _metaRouter, address _metaRouterGateway) public onlyOwner {
        address oldMetaRouter = symbiosisMetaRouter;
        address oldMetaRouterGateway = symbiosisMetaRouterGateway;
        symbiosisMetaRouter = _metaRouter;
        symbiosisMetaRouterGateway = _metaRouterGateway;
        emit SymbiosisAddressUpdated(oldMetaRouter, oldMetaRouterGateway, _metaRouter, _metaRouterGateway);
    }

    /// @inheritdoc IRangoSymbiosis
    function messageReceive(
        uint256 _amount,
        address _token,
        Interchain.RangoInterChainMessage memory _receivedMessage
    ) external payable override whenNotPaused nonReentrant {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_token), msg.sender, address(this), _amount);
        (address receivedToken, uint dstAmount, OperationStatus status) = handleDestinationMessage(_token, _amount, _receivedMessage);

        emit SymbiosisSwapStatusUpdated(receivedToken, dstAmount, status, _receivedMessage.originalSender, _receivedMessage.recipient);
    }

    /// @inheritdoc IRangoSymbiosis
    function symbiosisBridge(
        address _token,
        uint256 _amount,
        SymbiosisBridgeRequest memory _request
    ) external payable override whenNotPaused nonReentrant {
        require(symbiosisMetaRouter != ETH, 'Symbiosis meta router address not set');
        require(symbiosisMetaRouterGateway != ETH, 'Symbiosis meta router gateway address not set');
        require(_token != ETH, 'Symbiosis contract handles only ERC20 tokens');

        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_token), msg.sender, address(this), _amount);
        approve(_token, symbiosisMetaRouterGateway, _amount);

        MetaRouteTransaction memory transactionData = _request.metaRouteTransaction;
        bytes memory otherSideCalldata;
        if (_request.bridgeType == SymbiosisBridgeType.META_BURN) {
            MetaBurnTransaction memory metaData = metaBurnData(_request);
            otherSideCalldata = abi.encodeWithSelector(0xe691a2aa, metaData); // metaBurn selector
        } else {
            MetaSynthesizeTransaction memory metaData = metaSynthesizeData(_request);
            otherSideCalldata = abi.encodeWithSelector(0xce654c17, metaData); // metaSynthesizeSelector
        }
        transactionData.otherSideCalldata = otherSideCalldata;
        transactionData.amount = _amount;

        ISymbiosisMetaRouter(symbiosisMetaRouter).metaRoute(transactionData);
    }

    function metaBurnData(
        SymbiosisBridgeRequest memory _request
    ) private pure returns (MetaBurnTransaction memory) {
        address finalReceiveSide;
        bytes memory finalCalldata;
        uint256 finalOffset;

        if (_request.hasFinalCall) {
            finalReceiveSide = _request.otherSideData.finalReceiveSide;
            finalCalldata = finalReceiveCalldata(_request);
            finalOffset = 36;
        } else {
            finalReceiveSide = ETH;
            finalCalldata = "";
            finalOffset = 0;
        }

        return MetaBurnTransaction(
            _request.otherSideData.stableBridgingFee,
            _request.otherSideData.amount,
            _request.userData.syntCaller,
            finalReceiveSide,
            _request.userData.token,
            finalCalldata,
            finalOffset,
            _request.otherSideData.chain2address,
            _request.userData.receiveSide,
            _request.bridgeData.oppositeBridge,
            _request.userData.revertableAddress,
            _request.bridgeData.chainID,
            _request.bridgeData.clientID
        );
    }

    function metaSynthesizeData(
        SymbiosisBridgeRequest memory _request
    ) private pure returns (MetaSynthesizeTransaction memory) {
        address finalReceiveSide;
        bytes memory finalCalldata;
        uint256 finalOffset;

        if (_request.hasFinalCall) {
            finalReceiveSide = _request.otherSideData.finalReceiveSide;
            finalCalldata = finalReceiveCalldata(_request);
            finalOffset = 36;
        } else {
            finalReceiveSide = ETH;
            finalCalldata = "";
            finalOffset = 0;
        }

        return MetaSynthesizeTransaction(
            _request.otherSideData.stableBridgingFee,
            _request.otherSideData.amount,
            _request.userData.token,
            _request.otherSideData.chain2address,
            _request.userData.receiveSide,
            _request.bridgeData.oppositeBridge,
            _request.userData.syntCaller,
            _request.bridgeData.chainID,
            _request.otherSideData.swapTokens,
            _request.swapData.poolAddress,
            _request.swapData.poolData,
            finalReceiveSide,
            finalCalldata,
            finalOffset,
            _request.userData.revertableAddress,
            _request.bridgeData.clientID
        );
    }

    function finalReceiveCalldata(
        SymbiosisBridgeRequest memory _request
    ) private pure returns (bytes memory finalCalldata){
        finalCalldata = abi.encodeWithSelector(
            0x06e39ced, // messageReceive selector
            _request.otherSideData.finalAmount,
            _request.otherSideData.finalToken,
            _request.imMessage
        );
    }
}