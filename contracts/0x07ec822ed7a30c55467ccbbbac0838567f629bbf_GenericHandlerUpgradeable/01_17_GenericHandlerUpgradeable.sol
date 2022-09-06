// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/IGenericHandler.sol";
import "../interfaces/iRouterCrossTalk.sol";
import "../interfaces/iGBridge.sol";
import "../interfaces/IFeeManagerGeneric.sol";

/// @title Handles generic deposits and deposit executions.
/// @author Router Protocol
/// @notice This contract is intended to be used with the Bridge contract.
contract GenericHandlerUpgradeable is Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ----------------------------------------------------------------- //
    //                        DS Section Starts                          //
    // ----------------------------------------------------------------- //

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    iGBridge public bridge;

    iFeeManagerGeneric private feeManager;

    bytes32 private resourceID;

    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    mapping(uint8 => mapping(uint64 => ExecuteRecord)) private _executeRecords;

    struct ExecuteRecord {
        bool isExecuted;
        bool _status;
        bytes _callback;
    }

    struct DepositRecord {
        bytes32 _resourceID;
        uint8 _srcChainID;
        uint8 _destChainID;
        uint64 _nonce;
        address _srcAddress;
        address _destAddress;
        bytes4 _selector;
        bytes data;
        bytes32 hash;
        uint256 _gas;
        address _feeToken;
    }

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
    }

    mapping(uint8 => uint256) private defaultGas;
    mapping(uint8 => uint256) private defaultGasPrice;
    mapping(uint8 => mapping(uint64 => FeeRecord)) private _feeRecord;

    struct FeeRecord {
        uint8 _destChainID;
        uint64 _nonce;
        address _feeToken;
        uint256 _gasLimit;
        uint256 _gasPrice;
        uint256 _feeAmount;
    }

    uint8 private _chainId;

    event ReplayEvent(
        uint8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 widgetID
    );

    // ----------------------------------------------------------------- //
    //                        DS Section Ends                            //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Init Section Starts                        //
    // ----------------------------------------------------------------- //

    function __GenericHandlerUpgradeable_init(address _bridge, bytes32 _resourceID) internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _bridge);
        _setupRole(FEE_SETTER_ROLE, msg.sender);

        bridge = iGBridge(_bridge);
        resourceID = _resourceID;
    }

    function __GenericHandlerUpgradeable_init_unchained() internal initializer {}

    function initialize(address _bridge, bytes32 _resourceID) external initializer {
        __GenericHandlerUpgradeable_init(_bridge, _resourceID);
    }

    // ----------------------------------------------------------------- //
    //                        Init Section Ends                          //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Mapping Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Maps the two contracts on cross chain enviroment
    /// @param linker Linker object to be verified
    function MapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can map contracts"
        );
        crossTalk.Link{ gas: 57786 }(linker._chainID, linker._linkedContract);
    }

    /// @notice Function UnMaps the two contracts on cross chain enviroment
    /// @param linker Linker object to be verified

    function UnMapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can unmap contracts"
        );
        crossTalk.Unlink{ gas: 35035 }(linker._chainID);
    }

    // ----------------------------------------------------------------- //
    //                        Mapping Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Deposit Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fired to fetch chain ID from bridge
    /// @return chainId for this chain
    function fetch_chainID() external view returns (uint8) {
        return _chainId;
    }

    /// @notice Function fired to trigger Cross Chain Communication
    /// @param  _destChainID Destination ChainID
    /// @param  _data Data for the cross chain function.
    /// @param  _gasLimit Gas Limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    /// @param  _feeToken Fee Token for the transaction.
    function genericDeposit(
        uint8 _destChainID,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Router Generichandler : Destination Gas Not Set");
        require(defaultGasPrice[_destChainID] != 0, "Router Generichandler : Destination Gas Price Not Set");

        uint64 _nonce = bridge.genericDeposit(_destChainID, resourceID);
        iRouterCrossTalk crossTalk = iRouterCrossTalk(msg.sender);
        address destAddress = crossTalk.fetchLink(_destChainID);

        uint256 gasLimit = _gasLimit < defaultGas[_destChainID] ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = _gasPrice < defaultGasPrice[_destChainID] ? defaultGasPrice[_destChainID] : _gasPrice;

        bytes4 _selector = abi.decode(_data, (bytes4));

        _genericDeposit(_nonce, _destChainID, _selector, _data, gasLimit, gasPrice, _feeToken, destAddress);
        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @param  _nonce Nonce for the deposit.
    /// @param  _destChainID Destination ChainID.
    /// @param  _selector Selector for the cross chain function.
    /// @param  _data Data for the cross chain function.
    /// @param  _gasLimit Gas Limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    /// @param  _feeToken Fee Token for the transaction.
    /// @param  _destAddress Address of crosstalk on destination chain.
    function _genericDeposit(
        uint64 _nonce,
        uint8 _destChainID,
        bytes4 _selector,
        bytes calldata _data,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        address _destAddress
    ) internal {
        uint256 fees = deductFee(_destChainID, _feeToken, _gasLimit, _gasPrice, false);
        bytes32 hash = keccak256(abi.encode(_destChainID, _nonce));

        _depositRecords[_destChainID][_nonce] = DepositRecord(
            resourceID,
            _chainId,
            _destChainID,
            _nonce,
            msg.sender,
            _destAddress,
            _selector,
            _data,
            hash,
            _gasLimit,
            _feeToken
        );

        _feeRecord[_destChainID][_nonce] = FeeRecord(_destChainID, _nonce, _feeToken, _gasLimit, _gasPrice, fees);
    }

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayGenericDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external {
        require(defaultGas[_destChainID] != 0, "Router Generichandler : Destination Gas Not Set");
        require(defaultGasPrice[_destChainID] != 0, "Router Generichandler : Destination Gas Price Not Set");

        DepositRecord storage record = _depositRecords[_destChainID][_depositNonce];
        require(record._feeToken != address(0), "GenericHandler: Record not found");
        require(record._srcAddress == msg.sender, "GenericHandler: Unauthorized transaction");

        uint256 gasLimit = _gasLimit < defaultGas[_destChainID] ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = _gasPrice < defaultGasPrice[_destChainID] ? defaultGasPrice[_destChainID] : _gasPrice;

        uint256 fee = deductFee(_destChainID, record._feeToken, gasLimit, gasPrice, true);

        _feeRecord[_destChainID][_depositNonce]._gasLimit = gasLimit;
        _feeRecord[_destChainID][_depositNonce]._gasPrice = gasPrice;
        _feeRecord[_destChainID][_depositNonce]._feeAmount += fee;

        emit ReplayEvent(_destChainID, resourceID, record._nonce, 0);
    }

    /// @notice Function fetches deposit record
    /// @param  _ChainID CHainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return DepositRecord
    function fetchDepositRecord(uint8 _ChainID, uint64 _nonce) external view returns (DepositRecord memory) {
        return _depositRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches fee record
    /// @param  _ChainID Destination ChainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return feeRecord
    function fetchFeeRecord(uint8 _ChainID, uint64 _nonce) external view returns (FeeRecord memory) {
        return _feeRecord[_ChainID][_nonce];
    }

    /// @notice Function fetches execute record
    /// @param  _ChainID CHainID of the deposit
    /// @param  _nonce Nonce of the deposit
    /// @return ExecuteRecord
    function fetchExecuteRecord(uint8 _ChainID, uint64 _nonce) external view returns (ExecuteRecord memory) {
        return _executeRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches resourceId
    function fetchResourceID() external view returns (bytes32) {
        return resourceID;
    }

    // ----------------------------------------------------------------- //
    //                        Deposit Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Execute Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Executes a cross Chain Request on destination chain and can only be triggered by bridge
    /// @dev Can only be called by the bridge
    /// @param  _data Cross chain Data recived from relayer
    /// @return true
    function executeProposal(bytes calldata _data) external onlyRole(BRIDGE_ROLE) returns (bool) {
        DepositRecord memory depositData = decodeData(_data);
        require(
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted == false,
            "GenericHandler: Already executed"
        );
        if (!depositData._destAddress.isContract()) {
            _executeRecords[depositData._srcChainID][depositData._nonce]._callback = "";
            _executeRecords[depositData._srcChainID][depositData._nonce]._status = false;
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
            return true;
        }
        (bool success, bytes memory callback) = depositData._destAddress.call(
            abi.encodeWithSelector(
                0x06d07c59, // routerSync(uint8,address,bytes)
                depositData._srcChainID,
                depositData._srcAddress,
                depositData.data
            )
        );
        _executeRecords[depositData._srcChainID][depositData._nonce]._callback = callback;
        _executeRecords[depositData._srcChainID][depositData._nonce]._status = success;
        _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
        return true;
    }

    /// @notice Function Decodes the data element recived from bridge
    /// @param  _data Cross chain Data recived from relayer
    /// @return DepositRecord
    function decodeData(bytes calldata _data) internal pure returns (DepositRecord memory) {
        DepositRecord memory depositData;
        (
            depositData._srcChainID,
            depositData._nonce,
            depositData._srcAddress,
            depositData._destAddress,
            depositData.data
        ) = abi.decode(_data, (uint8, uint64, address, address, bytes));

        return depositData;
    }

    // ----------------------------------------------------------------- //
    //                        Execute Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches fee manager address
    /// @return feeManager
    function fetchFeeManager() external view returns (address) {
        return address(feeManager);
    }

    /// @notice Function sets fee manager address
    /// @dev can only be called by default admin address
    /// @param  _feeManager Address of the fee manager.
    function setFeeManager(address _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = iFeeManagerGeneric(_feeManager);
    }

    /**
        @notice Function Fetches the default Gas for a chain ID .
    **/
    function fetchDefaultGas(uint8 _chainID) external view returns (uint256) {
        return defaultGas[_chainID];
    }

    /**
        @notice Function Sets default gas fees for chain.
        @param _chainID ChainID of the .
        @param _defaultGas Default gas for a chainid.
    **/
    function setDefaultGas(uint8 _chainID, uint256 _defaultGas) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultGas[_chainID] = _defaultGas;
    }

    /**
        @notice Function Fetches the default Gas Price for a chain ID .
    **/
    function fetchDefaultGasPrice(uint8 _chainID) external view returns (uint256) {
        return defaultGasPrice[_chainID];
    }

    /**
        @notice Function Sets default gas price for chain.
        @param _chainID ChainID of the .
        @param _defaultGasPrice Default gas for a chainid.
    **/
    function setDefaultGasPrice(uint8 _chainID, uint256 _defaultGasPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultGasPrice[_chainID] = _defaultGasPrice;
    }

    /**
        @notice Function Sets chainId for chain.
        @param chainId ChainID of the .
    **/
    function setChainId(uint8 chainId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _chainId = chainId;
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

    /// @notice Calculates fees for a cross chain Call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas Price for the transaction.
    /// @return total fees
    function calculateFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        require(defaultGas[destinationChainID] != 0, "GenericHandler : Destination Gas Not Set");
        require(defaultGasPrice[destinationChainID] != 0, "GenericHandler : Destination Gas Price Not Set");

        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();
        uint256 _gasLimit = gasLimit < defaultGas[destinationChainID] ? defaultGas[destinationChainID] : gasLimit;
        uint256 _gasPrice = gasPrice < defaultGasPrice[destinationChainID]
            ? defaultGasPrice[destinationChainID]
            : gasPrice;

        (uint256 feeFactorX10e6, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            return bridgeFees + (feeFactorX10e6 * _gasPrice * _gasLimit) / (10**(decimalsToDivide + 6));
        }

        return (feeFactorX10e6 * _gasLimit * _gasPrice)/(10**6) + bridgeFees;
    }

    /// @notice Function deducts fees for a cross chain Call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas Price for the transaction.
    /// @param isReplay True if it is a replay tx.
    /// @return totalFees
    function deductFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice,
        bool isReplay
    ) internal returns (uint256) {
        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        (uint256 feeFactorX10e6, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        if (isReplay) {
            bridgeFees = 0;
        }

        IERC20Upgradeable token = IERC20Upgradeable(feeTokenAddress);
        uint256 fees;

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = bridgeFees + (feeFactorX10e6 * gasPrice * gasLimit) / (10**(decimalsToDivide + 6));
        } else {
            fees = (feeFactorX10e6 * gasLimit * gasPrice)/(10**6) + bridgeFees;
        }

        token.safeTransferFrom(msg.sender, address(feeManager), fees);
        return fees;
    }

    /// @notice Used to manually release ERC20 tokens from FeeManager.
    /// @dev Can only be called by default admin
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    /// @notice Function to set the bridge address
    /// @dev Can only be called by default admin
    /// @param _bridge Address of the bridge
    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = iGBridge(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Ends                       //
    // ----------------------------------------------------------------- //
}