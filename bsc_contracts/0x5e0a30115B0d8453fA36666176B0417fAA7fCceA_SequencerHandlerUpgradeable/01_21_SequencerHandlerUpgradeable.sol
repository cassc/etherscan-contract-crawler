// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/ISequencerHandler.sol";
import "../interfaces/iRouterCrossTalk.sol";
import "../interfaces/iGBridge.sol";
import "../interfaces/IFeeManagerGeneric.sol";
import "../interfaces/IDepositExecute.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERCHandler.sol";

/// @title Handles Sequencer deposits and deposit executions.
/// @author Router Protocol
/// @notice This contract is intended to be used with the Bridge contract.
contract SequencerHandlerUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ISequencerHandler
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ----------------------------------------------------------------- //
    //                        DS Section Starts                          //
    // ----------------------------------------------------------------- //

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant resourceID = 0x2222222222222222222222222222222222222222222222222222222222222222;

    iGBridge private bridge;
    iFeeManagerGeneric private feeManager;
    uint8 private _chainid;

    // destinationChainId => depositNonce => DepositRecord
    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    // destinationChainId => depositNonce => ExecuteRecord
    mapping(uint8 => mapping(uint64 => ExecuteRecord)) private _executeRecords;

    // destinationChainId => true if unsupported and false if supported
    mapping(uint8 => bool) private _unsupportedChains;

    // destinationChainId => defaultGasLimit
    mapping(uint8 => uint256) private defaultGas;

    // destinationChainId => defaultGasPrice
    mapping(uint8 => uint256) private defaultGasPrice;

    struct ExecuteRecord {
        bool isExecuted;
        bool _status;
        bytes _callback;
    }

    struct DepositRecord {
        uint8 _srcChainID;
        uint8 _destChainID;
        uint64 _nonce;
        address _srcAddress;
        address _destAddress;
        bytes _genericData;
        bytes _ercData;
        uint256 _gasLimit;
        uint256 _gasPrice;
        address _feeToken;
        uint256 _fees;
        bool _isTransferFirst;
    }

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
    }

    event ReplayEvent(
        uint8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 widgetID
    );

    modifier notUnsupportedChain(uint8 chainID) {
        require(!isChainUnsupported(chainID), "Unsupported chain");
        _;
    }

    // ----------------------------------------------------------------- //
    //                        DS Section Ends                            //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Init Section Starts                        //
    // ----------------------------------------------------------------- //

    function __SequencerHandlerUpgradeable_init(address _bridge) internal initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _bridge);
        _setupRole(FEE_SETTER_ROLE, msg.sender);

        bridge = iGBridge(_bridge);
        _chainid = bridge.fetch_chainID();
    }

    function __SequencerHandlerUpgradeable_init_unchained() internal initializer {}

    function initialize(address _bridge) external initializer {
        __SequencerHandlerUpgradeable_init(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                        Init Section Ends                          //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Mapping Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Maps the two contracts on cross chain enviroment.
    /// @dev Use this function to map your contracts across chains.
    /// @param linker RouterLinker object to be verified.
    function MapContract(RouterLinker calldata linker) external virtual {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(msg.sender == crossTalk.fetchLinkSetter(), "Only Link Setter");
        crossTalk.Link(linker._chainID, linker._linkedContract);
    }

    /// @notice Function UnMaps the two contracts on cross chain enviroment.
    /// @dev Use this function to unmap your contracts across chains.
    /// @param linker RouterLinker object to be verified.
    function UnMapContract(RouterLinker calldata linker) external virtual {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(msg.sender == crossTalk.fetchLinkSetter(), "Only Link Setter");
        crossTalk.Unlink(linker._chainID);
    }

    // ----------------------------------------------------------------- //
    //                        Mapping Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Deposit Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Fetches if a chain is unsupported.
    /// @dev Some chains may be unsupported from time to time due to unforseen circumstances.
    /// @param _destChainId chainId for the destination chain defined by Router Protocol.
    /// @return Returns true if chain is unsupported and false if supported.
    function isChainUnsupported(uint8 _destChainId) public view returns (bool) {
        return _unsupportedChains[_destChainId];
    }

    /// @notice Used to set/unset a chain as unsupported chain.
    /// @dev Some chains may be unsupported from time to time due to unforseen circumstances.
    /// @param _destChainId chainId for the destination chain defined by Router Protocol.
    /// @param _shouldUnsupport True to unsupport a chain and false to remove from unsupported chains.
    function unsupportChain(uint8 _destChainId, bool _shouldUnsupport) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unsupportedChains[_destChainId] = _shouldUnsupport;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithERC(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);

        // Handle ERC20
        _depositERC(_erc20, _swapData, _nonce);
        //Handle ERC20

        _depositRecords[_destChainID][_nonce]._ercData = abi.encode(_erc20, _swapData);
        _depositRecords[_destChainID][_nonce]._isTransferFirst = _isTransferFirst;

        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithETH(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external payable virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);

        // Handle ERC20
        _depositETH(_erc20, _swapData, msg.value, _nonce);
        //Handle ERC20

        _depositRecords[_destChainID][_nonce]._ercData = abi.encode(_erc20, _swapData);
        _depositRecords[_destChainID][_nonce]._isTransferFirst = _isTransferFirst;

        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    function genericDeposit(
        uint8 _destChainID,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);
        return _nonce;
    }

    /// @notice Function for generic deposit.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _genericData data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @return _nonce for the generic transaction.
    function _genericDeposit(
        uint8 _destChainID,
        bytes memory _genericData,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) internal virtual returns (uint64) {
        uint64 _nonce = bridge.genericDeposit(_destChainID, resourceID);
        iRouterCrossTalk crossTalk = iRouterCrossTalk(msg.sender);
        address destAddress = crossTalk.fetchLink(_destChainID);

        uint256 gasLimit = defaultGas[_destChainID] > _gasLimit ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = defaultGasPrice[_destChainID] > _gasPrice ? defaultGasPrice[_destChainID] : _gasPrice;

        uint256 fees = deductFee(_destChainID, _feeToken, gasLimit, gasPrice);

        _depositRecords[_destChainID][_nonce] = DepositRecord(
            _chainid,
            _destChainID,
            _nonce,
            msg.sender,
            destAddress,
            _genericData,
            bytes("dummy_data"),
            gasLimit,
            gasPrice,
            _feeToken,
            fees,
            false
        );
        return _nonce;
    }

    /// @notice Function for erc20 deposit.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    function _depositERC(
        bytes memory _erc20,
        bytes calldata _swapData,
        uint64 _nonce
    ) internal virtual {
        (
            uint8 destinationChainID,
            bytes32 _resourceID,
            uint256[] memory flags,
            address[] memory path,
            bytes[] memory dataTx,
            address feeTokenAddress
        ) = abi.decode(_erc20, (uint8, bytes32, uint256[], address[], bytes[], address));

        require(!isChainUnsupported(destinationChainID), "Unsupported chain");

        IDepositExecute.SwapInfo memory swapDetails = this.unpackDepositData(_swapData);

        swapDetails.depositer = msg.sender;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.feeTokenAddress = feeTokenAddress;
        swapDetails.dataTx = dataTx;
        swapDetails.depositNonce = _nonce;

        swapDetails.handler = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        require(swapDetails.handler != address(0), "rid not mapped to handler");

        IDepositExecute depositHandler = IDepositExecute(swapDetails.handler);
        depositHandler.deposit(_resourceID, destinationChainID, swapDetails.depositNonce, swapDetails);
    }

    function _depositETH(
        bytes memory _data,
        bytes calldata ercdata,
        uint256 amount,
        uint64 nonce
    ) internal virtual {
        (, bytes32 _resourceID) = abi.decode(_data, (uint8, bytes32));
        address depositHandlerAddress = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        IERCHandler depositHandler = IERCHandler(depositHandlerAddress);
        address weth = depositHandler._WETH();

        IWETH(weth).deposit{ value: amount }();
        require(IWETH(weth).transfer(msg.sender, amount));

        _depositERC(_data, ercdata, nonce);
    }

    /// @notice Function used to unpack the deposit data for erc20 swap details.
    /// @param data swap data to be unpacked.
    /// @return depositData swap details.
    function unpackDepositData(bytes calldata data)
        external
        view
        virtual
        returns (IDepositExecute.SwapInfo memory depositData)
    {
        IDepositExecute.SwapInfo memory swapDetails;
        uint256 isDestNative;

        (
            swapDetails.srcTokenAmount,
            swapDetails.srcStableTokenAmount,
            swapDetails.destStableTokenAmount,
            swapDetails.destTokenAmount,
            isDestNative,
            swapDetails.lenRecipientAddress,
            swapDetails.lenSrcTokenAddress,
            swapDetails.lenDestTokenAddress
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        //Note: to avoid stack too deep error, we are decoding it again.
        (, , , , , , , , swapDetails.widgetID) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        swapDetails.isDestNative = isDestNative == 0 ? false : true;
        swapDetails.index = 288; // 32 * 6 -> 9
        bytes memory recipient = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenRecipientAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenRecipientAddress;
        bytes memory srcToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenSrcTokenAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenSrcTokenAddress;
        bytes memory destStableToken = bytes(
            data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]
        );
        swapDetails.index = swapDetails.index + swapDetails.lenDestTokenAddress;
        bytes memory destToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]);

        bytes20 srcTokenAddress;
        bytes20 destStableTokenAddress;
        bytes20 destTokenAddress;
        bytes20 recipientAddress;
        assembly {
            srcTokenAddress := mload(add(srcToken, 0x20))
            destStableTokenAddress := mload(add(destStableToken, 0x20))
            destTokenAddress := mload(add(destToken, 0x20))
            recipientAddress := mload(add(recipient, 0x20))
        }
        swapDetails.srcTokenAddress = srcTokenAddress;
        swapDetails.destStableTokenAddress = address(destStableTokenAddress);
        swapDetails.destTokenAddress = destTokenAddress;
        swapDetails.recipient = address(recipientAddress);

        return swapDetails;
    }

    /// @notice Function fetches deposit record.
    /// @param _ChainID Destination chainID of the deposit defined by Router Protocol
    /// @param  _nonce Nonce of the deposit
    /// @return Deposit Record for the chainId and nonce data
    function fetchDepositRecord(uint8 _ChainID, uint64 _nonce) external view returns (DepositRecord memory) {
        return _depositRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches execute record.
    /// @param _ChainID Destination chainID of the deposit defined by Router Protocol
    /// @param  _nonce Nonce of the deposit
    /// @return Execute Record for the chainId and nonce data
    function fetchExecuteRecord(uint8 _ChainID, uint64 _nonce) external view returns (ExecuteRecord memory) {
        return _executeRecords[_ChainID][_nonce];
    }

    // ----------------------------------------------------------------- //
    //                        Deposit Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Execute Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Executes a cross chain request on destination chain.
    /// @dev Can only be triggered by bridge.
    /// @param  _data Cross chain data received from relayer consisting of the deposit record.
    function executeProposal(bytes calldata _data)
        external
        virtual
        override
        onlyRole(BRIDGE_ROLE)
        nonReentrant
        returns (bool)
    {
        DepositRecord memory depositData = decodeData(_data);
        ExecuteRecord memory executeRecords = _executeRecords[depositData._srcChainID][depositData._nonce];

        require(executeRecords.isExecuted == false, "Already executed");
        if (!depositData._destAddress.isContract()) {
            executeRecords._callback = "";
            executeRecords._status = false;
            executeRecords.isExecuted = true;
            _executeRecords[depositData._srcChainID][depositData._nonce] = executeRecords;
            return true;
        }

        if (
            keccak256(depositData._ercData) == keccak256(bytes("dummy_data")) &&
            (depositData._ercData).length == (bytes("dummy_data")).length
        ) {
            // passing 0 for settlement token and amount as we don't know it yet
            executeGeneric(depositData, address(0), 0);
        } else if (depositData._isTransferFirst) {
            (address settlementToken, uint256 returnAmount) = executeErc(depositData);
            executeGeneric(depositData, settlementToken, returnAmount);
        } else {
            // passing 0 for settlement token and amount as we don't know it yet
            executeGeneric(depositData,address(0), 0);
            executeErc(depositData);
        }

        return true;
    }

    /// @notice Function Executes a cross chain request on destination chain for generic transaction.
    /// @dev Can only be triggered by bridge.
    /// @param depositData deposit data for the transaction.
    /// @param settlementToken address of the settlement token.
    /// @param returnAmount amount of settlement token paid to the recipient.
    function executeGeneric(DepositRecord memory depositData, address settlementToken, uint256 returnAmount) internal virtual {
        ExecuteRecord memory executeRecords = _executeRecords[depositData._srcChainID][depositData._nonce];
        (bool success, bytes memory callback) = depositData._destAddress.call(
            abi.encodeWithSelector(
                0xa620f64f, // routerSync(uint8,address,bytes,address,amount)
                depositData._srcChainID,
                depositData._srcAddress,
                depositData._genericData,
                settlementToken,
                returnAmount
            )
        );
        executeRecords._status = success;
        executeRecords._callback = callback;
        executeRecords.isExecuted = true;
        _executeRecords[depositData._srcChainID][depositData._nonce] = executeRecords;
    }
    

    /// @notice Function Executes a cross chain request on destination chain for erc20 transaction.
    /// @dev Can only be triggered by bridge.
    /// @param depositData deposit data for the transaction.
    function executeErc(DepositRecord memory depositData) internal virtual returns(address, uint256){
        (bytes memory _erc20, bytes memory _swapData) = abi.decode(depositData._ercData, (bytes, bytes));

        (, bytes32 _resourceID, uint256[] memory flags, address[] memory path, bytes[] memory dataTx, ) = abi.decode(
            _erc20,
            (uint8, bytes32, uint256[], address[], bytes[], address)
        );

        IDepositExecute.SwapInfo memory swapDetails = this.unpackDepositData(_swapData);

        address settlementToken;
        swapDetails.dataTx = dataTx;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.index = depositData._srcChainID;
        swapDetails.depositNonce = depositData._nonce;

        address depositHandlerAddress = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        IDepositExecute depositHandler = IDepositExecute(depositHandlerAddress);
        (settlementToken, swapDetails.returnAmount) = depositHandler.executeProposal(swapDetails, _resourceID);
        return (settlementToken, swapDetails.returnAmount);
    }

    /// @notice Used to decode the deposit data received from bridge.
    /// @param _data Cross chain deposit data received from relayer.
    /// @return depositData is returned
    function decodeData(bytes calldata _data) internal pure virtual returns (DepositRecord memory) {
        DepositRecord memory depositData;
        (
            depositData._srcChainID,
            depositData._nonce,
            depositData._srcAddress,
            depositData._destAddress,
            depositData._genericData,
            depositData._ercData,
            depositData._isTransferFirst
        ) = abi.decode(_data, (uint8, uint64, address, address, bytes, bytes, bool));

        return depositData;
    }

    // ----------------------------------------------------------------- //
    //                        Execute Section Ends                       //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches the chainID.
    /// @return chainId
    function fetch_chainID() external view override returns (uint8) {
        return _chainid;
    }

    /// @notice Function fetches the bridge address.
    /// @return bridge address
    function fetchBridge() external view returns (address) {
        return address(bridge);
    }

    /// @notice Function sets the bridge address.
    /// @dev Can only be called by the default admin
    /// @param _bridge Address of the bridge contract.
    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = iGBridge(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches the fee manager address.
    /// @return feeManager address
    function fetchFeeManager() external view returns (address) {
        return address(feeManager);
    }

    /// @notice Function Sets the fee manager address.
    /// @dev Can only be called by the default admin
    /// @param _feeManager Address of the fee manager contract.
    function setFeeManager(address _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = iFeeManagerGeneric(_feeManager);
    }

    /// @notice Function Fetches the default Gas for a destination chain.
    /// @param _chainID chainId of the destination chain.
    /// @return defaultGasLimit
    function fetchDefaultGas(uint8 _chainID) external view returns (uint256) {
        return defaultGas[_chainID];
    }

    /// @notice Function Fetches the default gas price for a destination chain.
    /// @param _chainID chainId of the destination chain.
    /// @return defaultGasPrice
    function fetchDefaultGasPrice(uint8 _chainID) external view returns (uint256) {
        return defaultGasPrice[_chainID];
    }

    /// @notice Function Sets default gas fees for destination chain.
    /// @param _chainID ChainID of the destination chain.
    /// @param _defaultGas Default gas limit for a destination chain.
    function setDefaultGas(uint8[] memory _chainID, uint256[] memory _defaultGas) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_chainID.length == _defaultGas.length, "Array length mismatch");
        for (uint256 i = 0; i < _chainID.length; i++) {
            defaultGas[_chainID[i]] = _defaultGas[i];
        }
    }

    /// @notice Function Sets default gas fees for destination chain.
    /// @param _chainID ChainID of the destination chain.
    /// @param _defaultGasPrice Default gas price for a destination chain.
    function setDefaultGasPrice(uint8[] memory _chainID, uint256[] memory _defaultGasPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_chainID.length == _defaultGasPrice.length, "Array length mismatch");
        for (uint256 i = 0; i < _chainID.length; i++) {
            defaultGasPrice[_chainID[i]] = _defaultGasPrice[i];
        }
    }

    /// @notice Calculates fees for a cross chain call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas price required for cross chain call.
    /// @return totalFees
    function calculateFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        (uint256 feeFactor, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        uint256 _gasLimit = gasLimit < defaultGas[destinationChainID] ? defaultGas[destinationChainID] : gasLimit;
        uint256 _gasPrice = gasPrice < defaultGasPrice[destinationChainID]
            ? defaultGasPrice[destinationChainID]
            : gasPrice;

        uint256 fees;

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = bridgeFees + ((feeFactor * _gasPrice * _gasLimit) / (10**decimalsToDivide));
            return fees;
        }

        fees = bridgeFees + (feeFactor * _gasLimit * _gasPrice);
        return fees;
    }

    /// @notice Function used to deduct fee for generic deposit.
    /// @param destinationChainID chainId of the destination chain defined by Router Protocol.
    /// @param feeTokenAddress fee token for payment of fees.
    /// @param gasLimit gas limit for the call.
    /// @param gasPrice gas price for the call.
    /// @return totalFee for generic deposit.
    function deductFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) internal virtual returns (uint256) {
        (uint256 feeFactor, ) = feeManager.getFee(destinationChainID, feeTokenAddress);

        uint256 fees;
        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = (feeFactor * gasPrice * gasLimit) / (10**decimalsToDivide);
        } else {
            fees = feeFactor * gasLimit * gasPrice;
        }

        IERC20Upgradeable(feeTokenAddress).safeTransferFrom(msg.sender, address(feeManager), fees);
        return fees;
    }

    /**
        @notice Function to replay a transaction which was stuck due to underpricing of gas.
        @param  _destChainID Destination ChainID
        @param  _depositNonce Nonce for the transaction.
        @param  _gasLimit Gas limit allowed for the transaction.
        @param  _gasPrice Gas Price for the transaction.
    **/
    function replayDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external override {
        DepositRecord storage record = _depositRecords[_destChainID][_depositNonce];
        uint256 preGasPrice = record._gasPrice;
        uint256 preGasLimit = record._gasLimit;

        require(record._srcAddress == msg.sender, "Unauthorized transaction");

        require(preGasLimit <= _gasLimit, "Gas Limit >= previous GasLimit");

        require(preGasPrice < _gasPrice, "Gas Price > previous Price");

        uint256 fees = deductFee(_destChainID, record._feeToken, _gasLimit, _gasPrice);
        emit ReplayEvent(_destChainID, resourceID, record._nonce, 0);

        record._gasLimit = _gasLimit;
        record._gasPrice = _gasPrice;
        record._fees += fees;
    }

    /// @notice Function Sets the fee for a fee token on to feemanager
    /// @dev Can only be called by fee setter.
    /// @param destinationChainID ID of the destination chain.
    /// @param feeTokenAddress Address of fee token.
    /// @param feeFactor FeeFactor for the cross chain call.
    /// @param bridgeFee Base Fee for bridge.
    /// @param accepted Bool value for enabling and disabling feetoken.
    function setFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external onlyRole(FEE_SETTER_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, feeFactor, bridgeFee, accepted);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Section Ends                       //
    // ----------------------------------------------------------------- //
}