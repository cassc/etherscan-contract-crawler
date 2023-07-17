// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IRegistry } from './interfaces/IRegistry.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TargetGasReserve } from './crosschain/TargetGasReserve.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title ActionExecutorRegistry
 * @notice The contract for action settings
 */
contract ActionExecutorRegistry is SystemVersionId, TargetGasReserve, BalanceManagement, IRegistry {
    /**
     * @dev Registered cross-chain gateway addresses by type
     */
    mapping(uint256 /*gatewayType*/ => address /*gatewayAddress*/) public gatewayMap;

    /**
     * @dev Registered cross-chain gateway types
     */
    uint256[] public gatewayTypeList;

    /**
     * @dev Registered cross-chain gateway type indices
     */
    mapping(uint256 /*gatewayType*/ => DataStructures.OptionalValue /*gatewayTypeIndex*/)
        public gatewayTypeIndexMap;

    /**
     * @dev Registered cross-chain gateway flags by address
     */
    mapping(address /*account*/ => bool /*isGateway*/) public isGatewayAddress;

    /**
     * @dev Registered swap router addresses by type
     */
    mapping(uint256 /*routerType*/ => address /*routerAddress*/) public routerMap;

    /**
     * @dev Registered swap router types
     */
    uint256[] public routerTypeList;

    /**
     * @dev Registered swap router type indices
     */
    mapping(uint256 /*routerType*/ => DataStructures.OptionalValue /*routerTypeIndex*/)
        public routerTypeIndexMap;

    /**
     * @dev Registered swap router transfer addresses by router type
     */
    mapping(uint256 /*routerType*/ => address /*routerTransferAddress*/) public routerTransferMap;

    /**
     * @dev Registered vault addresses by type
     */
    mapping(uint256 /*vaultType*/ => address /*vaultAddress*/) public vaultMap;

    /**
     * @dev Registered vault types
     */
    uint256[] public vaultTypeList;

    /**
     * @dev Registered vault-type indices
     */
    mapping(uint256 /*vaultType*/ => DataStructures.OptionalValue /*vaultTypeIndex*/)
        public vaultTypeIndexMap;

    /**
     * @dev Registered non-default decimal values by vault type
     */
    mapping(uint256 /*vaultType*/ => mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*vaultDecimals*/))
        public vaultDecimalsTable;

    /**
     * @dev Chain IDs of registered vault decimal values
     */
    uint256[] public vaultDecimalsChainIdList;

    /**
     * @dev Chain ID indices of registered vault decimal values
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*chainIdIndex*/)
        public vaultDecimalsChainIdIndexMap;

    /**
     * @dev The system fee value (cross-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFee;

    /**
     * @dev The system fee value (single-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFeeLocal;

    /**
     * @dev The address of the cross-chain action fee collector
     */
    address public feeCollector;

    /**
     * @dev The address of the single-chain action fee collector
     */
    address public feeCollectorLocal;

    /**
     * @dev The list of accounts that can perform actions without fees and amount restrictions
     */
    address[] public whitelist;

    /**
     * @dev The whitelist account indices
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*whitelistIndex*/)
        public whitelistIndexMap;

    /**
     * @dev The minimum cross-chain swap amount in USD, with decimals = 18
     */
    uint256 public swapAmountMin = 0;

    /**
     * @dev The maximum cross-chain swap amount in USD, with decimals = 18. Is type(uint256).max for unlimited amount
     */
    uint256 public swapAmountMax = Constants.INFINITY;

    uint256 private constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;
    uint256 private constant SYSTEM_FEE_LIMIT = 10_000; // Maximum system fee in milli-percent = 10%
    uint256 private constant SYSTEM_FEE_INITIAL = 100; // Initial system fee in milli-percent = 0.1%

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is added or updated
     * @param gatewayType The type of the registered cross-chain gateway
     * @param gatewayAddress The address of the registered cross-chain gateway contract
     */
    event SetGateway(uint256 indexed gatewayType, address indexed gatewayAddress);

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is removed
     * @param gatewayType The type of the removed cross-chain gateway
     */
    event RemoveGateway(uint256 indexed gatewayType);

    /**
     * @notice Emitted when a registered vault contract address is added or updated
     * @param vaultType The type of the registered vault
     * @param vaultAddress The address of the registered vault contract
     */
    event SetVault(uint256 indexed vaultType, address indexed vaultAddress);

    /**
     * @notice Emitted when a registered vault contract address is removed
     * @param vaultType The type of the removed vault
     */
    event RemoveVault(uint256 indexed vaultType);

    /**
     * @notice Emitted when vault decimal values are set
     * @param vaultType The type of the vault
     * @param decimalsData The vault decimal values
     */
    event SetVaultDecimals(uint256 indexed vaultType, DataStructures.KeyToValue[] decimalsData);

    /**
     * @notice Emitted when vault decimal values are unset
     * @param vaultType The type of the vault
     */
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    /**
     * @notice Emitted when a registered swap router contract address is added or updated
     * @param routerType The type of the registered swap router
     * @param routerAddress The address of the registered swap router contract
     */
    event SetRouter(uint256 indexed routerType, address indexed routerAddress);

    /**
     * @notice Emitted when a registered swap router contract address is removed
     * @param routerType The type of the removed swap router
     */
    event RemoveRouter(uint256 indexed routerType);

    /**
     * @notice Emitted when a registered swap router transfer contract address is set
     * @param routerType The type of the swap router
     * @param routerTransfer The address of the swap router transfer contract
     */
    event SetRouterTransfer(uint256 indexed routerType, address indexed routerTransfer);

    /**
     * @notice Emitted when the system fee value (cross-chain swaps) is set
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFee(uint256 systemFee);

    /**
     * @notice Emitted when the system fee value (single-chain swaps) is set
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFeeLocal(uint256 systemFeeLocal);

    /**
     * @notice Emitted when the address of the cross-chain action fee collector is set
     * @param feeCollector The address of the cross-chain action fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    /**
     * @notice Emitted when the address of the single-chain action fee collector is set
     * @param feeCollector The address of the single-chain action fee collector
     */
    event SetFeeCollectorLocal(address indexed feeCollector);

    /**
     * @notice Emitted when the whitelist is updated
     * @param whitelistAddress The added or removed account address
     * @param value The flag of account inclusion
     */
    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    /**
     * @notice Emitted when the minimum cross-chain swap amount is set
     * @param value The minimum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMin(uint256 value);

    /**
     * @notice Emitted when the maximum cross-chain swap amount is set
     * @dev Is type(uint256).max for unlimited amount
     * @param value The maximum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMax(uint256 value);

    /**
     * @notice Emitted when the specified cross-chain gateway address is duplicate
     */
    error DuplicateGatewayAddressError();

    /**
     * @notice Emitted when the requested cross-chain gateway type is not set
     */
    error GatewayNotSetError();

    /**
     * @notice Emitted when the requested swap router type is not set
     */
    error RouterNotSetError();

    /**
     * @notice Emitted when the specified swap amount maximum is less than the current minimum
     */
    error SwapAmountMaxLessThanMinError();

    /**
     * @notice Emitted when the specified swap amount minimum is greater than the current maximum
     */
    error SwapAmountMinGreaterThanMaxError();

    /**
     * @notice Emitted when the specified system fee percentage value is greater than the allowed maximum
     */
    error SystemFeeValueError();

    /**
     * @notice Emitted when the requested vault type is not set
     */
    error VaultNotSetError();

    /**
     * @notice Deploys the ActionExecutorRegistry contract
     * @param _gateways Initial values of cross-chain gateway types and addresses
     * @param _feeCollector The initial address of the cross-chain action fee collector
     * @param _feeCollectorLocal The initial address of the single-chain action fee collector
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        DataStructures.KeyToAddressValue[] memory _gateways,
        address _feeCollector,
        address _feeCollectorLocal,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        for (uint256 index; index < _gateways.length; index++) {
            DataStructures.KeyToAddressValue memory item = _gateways[index];

            _setGateway(item.key, item.value);
        }

        _setSystemFee(SYSTEM_FEE_INITIAL);
        _setSystemFeeLocal(SYSTEM_FEE_INITIAL);

        _setFeeCollector(_feeCollector);
        _setFeeCollectorLocal(_feeCollectorLocal);

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Adds or updates a registered cross-chain gateway contract address
     * @param _gatewayType The type of the registered cross-chain gateway
     * @param _gatewayAddress The address of the registered cross-chain gateway contract
     */
    function setGateway(uint256 _gatewayType, address _gatewayAddress) external onlyManager {
        _setGateway(_gatewayType, _gatewayAddress);
    }

    /**
     * @notice Removes a registered cross-chain gateway contract address
     * @param _gatewayType The type of the removed cross-chain gateway
     */
    function removeGateway(uint256 _gatewayType) external onlyManager {
        address gatewayAddress = gatewayMap[_gatewayType];

        if (gatewayAddress == address(0)) {
            revert GatewayNotSetError();
        }

        DataStructures.combinedMapRemove(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType
        );

        delete isGatewayAddress[gatewayAddress];

        emit RemoveGateway(_gatewayType);
    }

    /**
     * @notice Adds or updates registered swap router contract addresses
     * @param _routers Types and addresses of swap routers
     */
    function setRouters(DataStructures.KeyToAddressValue[] calldata _routers) external onlyManager {
        for (uint256 index; index < _routers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _routers[index];

            _setRouter(item.key, item.value);
        }
    }

    /**
     * @notice Removes registered swap router contract addresses
     * @param _routerTypes Types of swap routers
     */
    function removeRouters(uint256[] calldata _routerTypes) external onlyManager {
        for (uint256 index; index < _routerTypes.length; index++) {
            uint256 routerType = _routerTypes[index];

            _removeRouter(routerType);
        }
    }

    /**
     * @notice Adds or updates a registered swap router transfer contract address
     * @dev Zero address can be used to remove a router transfer contract
     * @param _routerType The type of the swap router
     * @param _routerTransfer The address of the swap router transfer contract
     */
    function setRouterTransfer(uint256 _routerType, address _routerTransfer) external onlyManager {
        if (routerMap[_routerType] == address(0)) {
            revert RouterNotSetError();
        }

        AddressHelper.requireContractOrZeroAddress(_routerTransfer);

        routerTransferMap[_routerType] = _routerTransfer;

        emit SetRouterTransfer(_routerType, _routerTransfer);
    }

    /**
     * @notice Adds or updates a registered vault contract address
     * @param _vaultType The type of the registered vault
     * @param _vaultAddress The address of the registered vault contract
     */
    function setVault(uint256 _vaultType, address _vaultAddress) external onlyManager {
        AddressHelper.requireContract(_vaultAddress);

        DataStructures.combinedMapSet(
            vaultMap,
            vaultTypeList,
            vaultTypeIndexMap,
            _vaultType,
            _vaultAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetVault(_vaultType, _vaultAddress);
    }

    /**
     * @notice Removes a registered vault contract address
     * @param _vaultType The type of the registered vault
     */
    function removeVault(uint256 _vaultType) external onlyManager {
        DataStructures.combinedMapRemove(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType);

        // - - - Vault decimals table cleanup - - -

        delete vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        uint256 chainIdListLength = vaultDecimalsChainIdList.length;

        for (uint256 index; index < chainIdListLength; index++) {
            uint256 chainId = vaultDecimalsChainIdList[index];

            delete vaultDecimalsTable[_vaultType][chainId];
        }

        // - - -

        emit RemoveVault(_vaultType);
    }

    /**
     * @notice Sets vault decimal values
     * @param _vaultType The type of the vault
     * @param _decimalsData The vault decimal values
     */
    function setVaultDecimals(
        uint256 _vaultType,
        DataStructures.KeyToValue[] calldata _decimalsData
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _decimalsData.length; index++) {
            DataStructures.KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                DataStructures.uniqueListAdd(
                    vaultDecimalsChainIdList,
                    vaultDecimalsChainIdIndexMap,
                    chainId,
                    Constants.LIST_SIZE_LIMIT_DEFAULT
                );
            }

            vaultDecimalsTable[_vaultType][chainId] = DataStructures.OptionalValue(
                true,
                decimalsDataItem.value
            );
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    /**
     * @notice Unsets vault decimal values
     * @param _vaultType The type of the vault
     * @param _chainIds Chain IDs of registered vault decimal values
     */
    function unsetVaultDecimals(
        uint256 _vaultType,
        uint256[] calldata _chainIds
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
    }

    /**
     * @notice Sets the system fee value (cross-chain swaps)
     * @param _systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFee(uint256 _systemFee) external onlyManager {
        _setSystemFee(_systemFee);
    }

    /**
     * @notice Sets the system fee value (single-chain swaps)
     * @param _systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFeeLocal(uint256 _systemFeeLocal) external onlyManager {
        _setSystemFeeLocal(_systemFeeLocal);
    }

    /**
     * @notice Sets the address of the cross-chain action fee collector
     * @param _feeCollector The address of the cross-chain action fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Sets the address of the single-chain action fee collector
     * @param _feeCollector The address of the single-chain action fee collector
     */
    function setFeeCollectorLocal(address _feeCollector) external onlyManager {
        _setFeeCollectorLocal(_feeCollector);
    }

    /**
     * @notice Updates the whitelist
     * @param _whitelistAddress The added or removed account address
     * @param _value The flag of account inclusion
     */
    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        DataStructures.uniqueAddressListUpdate(
            whitelist,
            whitelistIndexMap,
            _whitelistAddress,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetWhitelist(_whitelistAddress, _value);
    }

    /**
     * @notice Sets the minimum cross-chain swap amount
     * @param _value The minimum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMin(uint256 _value) external onlyManager {
        if (_value > swapAmountMax) {
            revert SwapAmountMinGreaterThanMaxError();
        }

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    /**
     * @notice Sets the maximum cross-chain swap amount
     * @dev Use type(uint256).max value for unlimited amount
     * @param _value The maximum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMax(uint256 _value) external onlyManager {
        if (_value < swapAmountMin) {
            revert SwapAmountMaxLessThanMinError();
        }

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            LocalSettings({
                router: router,
                routerTransfer: routerTransfer,
                systemFeeLocal: systemFeeLocal,
                feeCollectorLocal: feeCollectorLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            SourceSettings({
                gateway: gatewayMap[_gatewayType],
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                sourceVaultDecimals: vaultDecimals(_vaultType, block.chainid),
                targetVaultDecimals: vaultDecimals(_vaultType, _targetChainId),
                systemFee: systemFee,
                feeCollector: feeCollector,
                isWhitelist: isWhitelist(_caller),
                swapAmountMin: swapAmountMin,
                swapAmountMax: swapAmountMax
            });
    }

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            TargetSettings({
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                gasReserve: targetGasReserve
            });
    }

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory) {
        return VariableBalanceRepaymentSettings({ vault: vaultMap[_vaultType] });
    }

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory) {
        return MessageFeeEstimateSettings({ gateway: gatewayMap[_gatewayType] });
    }

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory) {
        return
            LocalAmountCalculationSettings({
                systemFeeLocal: systemFeeLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory) {
        return
            VaultAmountCalculationSettings({
                fromDecimals: vaultDecimals(_vaultType, _fromChainId),
                toDecimals: vaultDecimals(_vaultType, _toChainId),
                systemFee: systemFee,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == Constants.INFINITY) {
            min = 0;
            max = Constants.INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min = (swapAmountMin == 0)
                ? 0
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMin
                );

            max = (swapAmountMax == Constants.INFINITY)
                ? Constants.INFINITY
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMax
                );
        }
    }

    /**
     * @notice Getter of registered cross-chain gateway type count
     * @return Registered cross-chain gateway type count
     */
    function gatewayTypeCount() external view returns (uint256) {
        return gatewayTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered cross-chain gateway types
     * @return The complete list of registered cross-chain gateway types
     */
    function fullGatewayTypeList() external view returns (uint256[] memory) {
        return gatewayTypeList;
    }

    /**
     * @notice Getter of registered swap router type count
     * @return Registered swap router type count
     */
    function routerTypeCount() external view returns (uint256) {
        return routerTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered swap router types
     * @return The complete list of registered swap router types
     */
    function fullRouterTypeList() external view returns (uint256[] memory) {
        return routerTypeList;
    }

    /**
     * @notice Getter of registered vault type count
     * @return Registered vault type count
     */
    function vaultTypeCount() external view returns (uint256) {
        return vaultTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault types
     * @return The complete list of registered vault types
     */
    function fullVaultTypeList() external view returns (uint256[] memory) {
        return vaultTypeList;
    }

    /**
     * @notice Getter of registered vault decimals chain ID count
     * @return Registered vault decimals chain ID count
     */
    function vaultDecimalsChainIdCount() external view returns (uint256) {
        return vaultDecimalsChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault decimals chain IDs
     * @return The complete list of registered vault decimals chain IDs
     */
    function fullVaultDecimalsChainIdList() external view returns (uint256[] memory) {
        return vaultDecimalsChainIdList;
    }

    /**
     * @notice Getter of registered whitelist entry count
     * @return Registered whitelist entry count
     */
    function whitelistCount() external view returns (uint256) {
        return whitelist.length;
    }

    /**
     * @notice Getter of the full whitelist content
     * @return Full whitelist content
     */
    function fullWhitelist() external view returns (address[] memory) {
        return whitelist;
    }

    /**
     * @notice Getter of a whitelist flag
     * @param _account The account address
     * @return The whitelist flag
     */
    function isWhitelist(address _account) public view returns (bool) {
        return whitelistIndexMap[_account].isSet;
    }

    /**
     * @notice Getter of vault decimals value
     * @param _vaultType The type of the vault
     * @param _chainId The vault chain ID
     * @return Vault decimals value
     */
    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][
            _chainId
        ];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        DataStructures.OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][
            VAULT_DECIMALS_CHAIN_ID_WILDCARD
        ];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return Constants.DECIMALS_DEFAULT;
    }

    function _setGateway(uint256 _gatewayType, address _gatewayAddress) private {
        address previousGatewayAddress = gatewayMap[_gatewayType];

        if (_gatewayAddress != previousGatewayAddress) {
            if (isGatewayAddress[_gatewayAddress]) {
                revert DuplicateGatewayAddressError(); // The address is set for another gateway type
            }

            AddressHelper.requireContract(_gatewayAddress);

            DataStructures.combinedMapSet(
                gatewayMap,
                gatewayTypeList,
                gatewayTypeIndexMap,
                _gatewayType,
                _gatewayAddress,
                Constants.LIST_SIZE_LIMIT_DEFAULT
            );

            if (previousGatewayAddress != address(0)) {
                delete isGatewayAddress[previousGatewayAddress];
            }

            isGatewayAddress[_gatewayAddress] = true;
        }

        emit SetGateway(_gatewayType, _gatewayAddress);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        AddressHelper.requireContract(_routerAddress);

        DataStructures.combinedMapSet(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType,
            _routerAddress,
            Constants.LIST_SIZE_LIMIT_ROUTERS
        );

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        DataStructures.combinedMapRemove(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType
        );

        delete routerTransferMap[_routerType];

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        if (_systemFee > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setSystemFeeLocal(uint256 _systemFeeLocal) private {
        if (_systemFeeLocal > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFeeLocal = _systemFeeLocal;

        emit SetSystemFeeLocal(_systemFeeLocal);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _setFeeCollectorLocal(address _feeCollector) private {
        feeCollectorLocal = _feeCollector;

        emit SetFeeCollectorLocal(_feeCollector);
    }

    function _routerAddresses(
        uint256 _routerType
    ) private view returns (address router, address routerTransfer) {
        router = routerMap[_routerType];
        routerTransfer = routerTransferMap[_routerType];

        if (routerTransfer == address(0)) {
            routerTransfer = router;
        }
    }
}