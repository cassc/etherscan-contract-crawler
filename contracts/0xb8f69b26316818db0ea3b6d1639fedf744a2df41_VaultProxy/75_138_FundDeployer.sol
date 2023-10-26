// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../../../persistent/utils/IMigrationHookHandler.sol";
import "../fund/comptroller/IComptroller.sol";
import "../fund/comptroller/ComptrollerProxy.sol";
import "../fund/vault/IVault.sol";
import "./IFundDeployer.sol";

/// @title FundDeployer Contract
/// @author Enzyme Council <[email protected]>
/// @notice The top-level contract of the release.
/// It primarily coordinates fund deployment and fund migration, but
/// it is also deferred to for contract access control and for allowed calls
/// that can be made with a fund's VaultProxy as the msg.sender.
contract FundDeployer is IFundDeployer, IMigrationHookHandler {
    event ComptrollerLibSet(address comptrollerLib);

    event ComptrollerProxyDeployed(
        address indexed creator,
        address comptrollerProxy,
        address indexed denominationAsset,
        uint256 sharesActionTimelock,
        bytes feeManagerConfigData,
        bytes policyManagerConfigData,
        bool indexed forMigration
    );

    event NewFundCreated(
        address indexed creator,
        address comptrollerProxy,
        address vaultProxy,
        address indexed fundOwner,
        string fundName,
        address indexed denominationAsset,
        uint256 sharesActionTimelock,
        bytes feeManagerConfigData,
        bytes policyManagerConfigData
    );

    event ReleaseStatusSet(ReleaseStatus indexed prevStatus, ReleaseStatus indexed nextStatus);

    event VaultCallDeregistered(address indexed contractAddress, bytes4 selector);

    event VaultCallRegistered(address indexed contractAddress, bytes4 selector);

    // Constants
    address private immutable CREATOR;
    address private immutable DISPATCHER;
    address private immutable VAULT_LIB;

    // Pseudo-constants (can only be set once)
    address private comptrollerLib;

    // Storage
    ReleaseStatus private releaseStatus;
    mapping(address => mapping(bytes4 => bool)) private contractToSelectorToIsRegisteredVaultCall;
    mapping(address => address) private pendingComptrollerProxyToCreator;

    modifier onlyLiveRelease() {
        require(releaseStatus == ReleaseStatus.Live, "Release is not Live");
        _;
    }

    modifier onlyMigrator(address _vaultProxy) {
        require(
            IVault(_vaultProxy).canMigrate(msg.sender),
            "Only a permissioned migrator can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "Only the contract owner can call this function");
        _;
    }

    modifier onlyPendingComptrollerProxyCreator(address _comptrollerProxy) {
        require(
            msg.sender == pendingComptrollerProxyToCreator[_comptrollerProxy],
            "Only the ComptrollerProxy creator can call this function"
        );
        _;
    }

    constructor(
        address _dispatcher,
        address _vaultLib,
        address[] memory _vaultCallContracts,
        bytes4[] memory _vaultCallSelectors
    ) public {
        if (_vaultCallContracts.length > 0) {
            __registerVaultCalls(_vaultCallContracts, _vaultCallSelectors);
        }
        CREATOR = msg.sender;
        DISPATCHER = _dispatcher;
        VAULT_LIB = _vaultLib;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets the comptrollerLib
    /// @param _comptrollerLib The ComptrollerLib contract address
    /// @dev Can only be set once
    function setComptrollerLib(address _comptrollerLib) external onlyOwner {
        require(
            comptrollerLib == address(0),
            "setComptrollerLib: This value can only be set once"
        );

        comptrollerLib = _comptrollerLib;

        emit ComptrollerLibSet(_comptrollerLib);
    }

    /// @notice Sets the status of the protocol to a new state
    /// @param _nextStatus The next status state to set
    function setReleaseStatus(ReleaseStatus _nextStatus) external {
        require(
            msg.sender == IDispatcher(DISPATCHER).getOwner(),
            "setReleaseStatus: Only the Dispatcher owner can call this function"
        );
        require(
            _nextStatus != ReleaseStatus.PreLaunch,
            "setReleaseStatus: Cannot return to PreLaunch status"
        );
        require(
            comptrollerLib != address(0),
            "setReleaseStatus: Can only set the release status when comptrollerLib is set"
        );

        ReleaseStatus prevStatus = releaseStatus;
        require(_nextStatus != prevStatus, "setReleaseStatus: _nextStatus is the current status");

        releaseStatus = _nextStatus;

        emit ReleaseStatusSet(prevStatus, _nextStatus);
    }

    /// @notice Gets the current owner of the contract
    /// @return owner_ The contract owner address
    /// @dev Dynamically gets the owner based on the Protocol status. The owner is initially the
    /// contract's deployer, for convenience in setting up configuration.
    /// Ownership is claimed when the owner of the Dispatcher contract (the Enzyme Council)
    /// sets the releaseStatus to `Live`.
    function getOwner() public view override returns (address owner_) {
        if (releaseStatus == ReleaseStatus.PreLaunch) {
            return CREATOR;
        }

        return IDispatcher(DISPATCHER).getOwner();
    }

    ///////////////////
    // FUND CREATION //
    ///////////////////

    /// @notice Creates a fully-configured ComptrollerProxy, to which a fund from a previous
    /// release can migrate in a subsequent step
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createMigratedFundConfig(
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external onlyLiveRelease returns (address comptrollerProxy_) {
        comptrollerProxy_ = __deployComptrollerProxy(
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            true
        );

        pendingComptrollerProxyToCreator[comptrollerProxy_] = msg.sender;

        return comptrollerProxy_;
    }

    /// @notice Creates a new fund
    /// @param _fundOwner The address of the owner for the fund
    /// @param _fundName The name of the fund
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createNewFund(
        address _fundOwner,
        string calldata _fundName,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external onlyLiveRelease returns (address comptrollerProxy_, address vaultProxy_) {
        return
            __createNewFund(
                _fundOwner,
                _fundName,
                _denominationAsset,
                _sharesActionTimelock,
                _feeManagerConfigData,
                _policyManagerConfigData
            );
    }

    /// @dev Helper to avoid the stack-too-deep error during createNewFund
    function __createNewFund(
        address _fundOwner,
        string memory _fundName,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData
    ) private returns (address comptrollerProxy_, address vaultProxy_) {
        require(_fundOwner != address(0), "__createNewFund: _owner cannot be empty");

        comptrollerProxy_ = __deployComptrollerProxy(
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            false
        );

        vaultProxy_ = IDispatcher(DISPATCHER).deployVaultProxy(
            VAULT_LIB,
            _fundOwner,
            comptrollerProxy_,
            _fundName
        );

        IComptroller(comptrollerProxy_).activate(vaultProxy_, false);

        emit NewFundCreated(
            msg.sender,
            comptrollerProxy_,
            vaultProxy_,
            _fundOwner,
            _fundName,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        return (comptrollerProxy_, vaultProxy_);
    }

    /// @dev Helper function to deploy a configured ComptrollerProxy
    function __deployComptrollerProxy(
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData,
        bool _forMigration
    ) private returns (address comptrollerProxy_) {
        require(
            _denominationAsset != address(0),
            "__deployComptrollerProxy: _denominationAsset cannot be empty"
        );

        bytes memory constructData = abi.encodeWithSelector(
            IComptroller.init.selector,
            _denominationAsset,
            _sharesActionTimelock
        );
        comptrollerProxy_ = address(new ComptrollerProxy(constructData, comptrollerLib));

        if (_feeManagerConfigData.length > 0 || _policyManagerConfigData.length > 0) {
            IComptroller(comptrollerProxy_).configureExtensions(
                _feeManagerConfigData,
                _policyManagerConfigData
            );
        }

        emit ComptrollerProxyDeployed(
            msg.sender,
            comptrollerProxy_,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            _forMigration
        );

        return comptrollerProxy_;
    }

    //////////////////
    // MIGRATION IN //
    //////////////////

    /// @notice Cancels fund migration
    /// @param _vaultProxy The VaultProxy for which to cancel migration
    function cancelMigration(address _vaultProxy) external {
        __cancelMigration(_vaultProxy, false);
    }

    /// @notice Cancels fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to cancel migration
    function cancelMigrationEmergency(address _vaultProxy) external {
        __cancelMigration(_vaultProxy, true);
    }

    /// @notice Executes fund migration
    /// @param _vaultProxy The VaultProxy for which to execute the migration
    function executeMigration(address _vaultProxy) external {
        __executeMigration(_vaultProxy, false);
    }

    /// @notice Executes fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to execute the migration
    function executeMigrationEmergency(address _vaultProxy) external {
        __executeMigration(_vaultProxy, true);
    }

    /// @dev Unimplemented
    function invokeMigrationInCancelHook(
        address,
        address,
        address,
        address
    ) external virtual override {
        return;
    }

    /// @notice Signal a fund migration
    /// @param _vaultProxy The VaultProxy for which to signal the migration
    /// @param _comptrollerProxy The ComptrollerProxy for which to signal the migration
    function signalMigration(address _vaultProxy, address _comptrollerProxy) external {
        __signalMigration(_vaultProxy, _comptrollerProxy, false);
    }

    /// @notice Signal a fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to signal the migration
    /// @param _comptrollerProxy The ComptrollerProxy for which to signal the migration
    function signalMigrationEmergency(address _vaultProxy, address _comptrollerProxy) external {
        __signalMigration(_vaultProxy, _comptrollerProxy, true);
    }

    /// @dev Helper to cancel a migration
    function __cancelMigration(address _vaultProxy, bool _bypassFailure)
        private
        onlyLiveRelease
        onlyMigrator(_vaultProxy)
    {
        IDispatcher(DISPATCHER).cancelMigration(_vaultProxy, _bypassFailure);
    }

    /// @dev Helper to execute a migration
    function __executeMigration(address _vaultProxy, bool _bypassFailure)
        private
        onlyLiveRelease
        onlyMigrator(_vaultProxy)
    {
        IDispatcher dispatcherContract = IDispatcher(DISPATCHER);

        (, address comptrollerProxy, , ) = dispatcherContract
            .getMigrationRequestDetailsForVaultProxy(_vaultProxy);

        dispatcherContract.executeMigration(_vaultProxy, _bypassFailure);

        IComptroller(comptrollerProxy).activate(_vaultProxy, true);

        delete pendingComptrollerProxyToCreator[comptrollerProxy];
    }

    /// @dev Helper to signal a migration
    function __signalMigration(
        address _vaultProxy,
        address _comptrollerProxy,
        bool _bypassFailure
    )
        private
        onlyLiveRelease
        onlyPendingComptrollerProxyCreator(_comptrollerProxy)
        onlyMigrator(_vaultProxy)
    {
        IDispatcher(DISPATCHER).signalMigration(
            _vaultProxy,
            _comptrollerProxy,
            VAULT_LIB,
            _bypassFailure
        );
    }

    ///////////////////
    // MIGRATION OUT //
    ///////////////////

    /// @notice Allows "hooking into" specific moments in the migration pipeline
    /// to execute arbitrary logic during a migration out of this release
    /// @param _vaultProxy The VaultProxy being migrated
    function invokeMigrationOutHook(
        MigrationOutHook _hook,
        address _vaultProxy,
        address,
        address,
        address
    ) external override {
        if (_hook != MigrationOutHook.PreMigrate) {
            return;
        }

        require(
            msg.sender == DISPATCHER,
            "postMigrateOriginHook: Only Dispatcher can call this function"
        );

        // Must use PreMigrate hook to get the ComptrollerProxy from the VaultProxy
        address comptrollerProxy = IVault(_vaultProxy).getAccessor();

        // Wind down fund and destroy its config
        IComptroller(comptrollerProxy).destruct();
    }

    //////////////
    // REGISTRY //
    //////////////

    /// @notice De-registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to de-register
    /// @param _selectors The selectors of the calls to de-register
    function deregisterVaultCalls(address[] calldata _contracts, bytes4[] calldata _selectors)
        external
        onlyOwner
    {
        require(_contracts.length > 0, "deregisterVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length,
            "deregisterVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                isRegisteredVaultCall(_contracts[i], _selectors[i]),
                "deregisterVaultCalls: Call not registered"
            );

            contractToSelectorToIsRegisteredVaultCall[_contracts[i]][_selectors[i]] = false;

            emit VaultCallDeregistered(_contracts[i], _selectors[i]);
        }
    }

    /// @notice Registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to register
    /// @param _selectors The selectors of the calls to register
    function registerVaultCalls(address[] calldata _contracts, bytes4[] calldata _selectors)
        external
        onlyOwner
    {
        require(_contracts.length > 0, "registerVaultCalls: Empty _contracts");

        __registerVaultCalls(_contracts, _selectors);
    }

    /// @dev Helper to register allowed vault calls
    function __registerVaultCalls(address[] memory _contracts, bytes4[] memory _selectors)
        private
    {
        require(
            _contracts.length == _selectors.length,
            "__registerVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                !isRegisteredVaultCall(_contracts[i], _selectors[i]),
                "__registerVaultCalls: Call already registered"
            );

            contractToSelectorToIsRegisteredVaultCall[_contracts[i]][_selectors[i]] = true;

            emit VaultCallRegistered(_contracts[i], _selectors[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `comptrollerLib` variable value
    /// @return comptrollerLib_ The `comptrollerLib` variable value
    function getComptrollerLib() external view returns (address comptrollerLib_) {
        return comptrollerLib;
    }

    /// @notice Gets the `CREATOR` variable value
    /// @return creator_ The `CREATOR` variable value
    function getCreator() external view returns (address creator_) {
        return CREATOR;
    }

    /// @notice Gets the `DISPATCHER` variable value
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the creator of a pending ComptrollerProxy
    /// @return pendingComptrollerProxyCreator_ The pending ComptrollerProxy creator
    function getPendingComptrollerProxyCreator(address _comptrollerProxy)
        external
        view
        returns (address pendingComptrollerProxyCreator_)
    {
        return pendingComptrollerProxyToCreator[_comptrollerProxy];
    }

    /// @notice Gets the `releaseStatus` variable value
    /// @return status_ The `releaseStatus` variable value
    function getReleaseStatus() external view override returns (ReleaseStatus status_) {
        return releaseStatus;
    }

    /// @notice Gets the `VAULT_LIB` variable value
    /// @return vaultLib_ The `VAULT_LIB` variable value
    function getVaultLib() external view returns (address vaultLib_) {
        return VAULT_LIB;
    }

    /// @notice Checks if a contract call is registered
    /// @param _contract The contract of the call to check
    /// @param _selector The selector of the call to check
    /// @return isRegistered_ True if the call is registered
    function isRegisteredVaultCall(address _contract, bytes4 _selector)
        public
        view
        override
        returns (bool isRegistered_)
    {
        return contractToSelectorToIsRegisteredVaultCall[_contract][_selector];
    }
}