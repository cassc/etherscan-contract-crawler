// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time, max-states-count

// inheritance
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../../interface/installer/IBaseInstaller.sol";

// lib
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// deployable contracts
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract BaseInstaller is
    Initializable,
    AccessControlEnumerableUpgradeable,
    BaseRelayRecipient,
    IBaseInstaller
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // env types
    uint256 internal constant _ENVTYPE_GAMEFI_CORE = 0;
    uint256 internal constant _ENVTYPE_GAMEFI_SHOPS = 1;
    uint256 internal constant _ENVTYPE_GAMEFI_MARKETPLACE = 2;
    uint256 internal constant _ENVTYPE_GAMEFI_ROUTER = 3;
    uint256 internal constant _ENVTYPE_GAMEFI_MULTITRANSACTOR = 4;
    uint256 internal constant _ENVTYPE_GAMEFI_AVATARS = 10;
    uint256 internal constant _ENVTYPE_GAMEFI_BOXES = 11;

    address private _proxyAdmin;

    mapping(uint256 => Environment) private _environment;
    CountersUpgradeable.Counter private _totalEnvironments;

    mapping(uint256 => EnvInstance) private _instance;
    CountersUpgradeable.Counter private _totalInstances;

    mapping(string => EnumerableSetUpgradeable.UintSet) internal _envTags;

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    //
    // Constructor
    //

    // solhint-disable-next-line func-name-mixedcase
    function __BaseInstaller_init() internal onlyInitializing {
        __BaseInstaller_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BaseInstaller_init_unchained() internal onlyInitializing {
        _proxyAdmin = address(new ProxyAdmin());
    }

    //
    // General
    //

    function proxyAdmin() public view returns (address) {
        return _proxyAdmin;
    }

    //
    // Environments
    //

    function environmentDetails(uint256 environmentId) public view returns (Environment memory) {
        return _environment[environmentId];
    }

    function totalEnvironments() public view returns (uint256) {
        return _totalEnvironments.current();
    }

    function environmentOfTagByIndex(string memory tag, uint256 index) public view returns (uint256 environmentId) {
        return (_envTags[tag].at(index));
    }

    function totalEnvironmentsOfTag(string memory tag) public view returns (uint256) {
        return _envTags[tag].length();
    }

    //
    // Env instances
    //

    function instanceDetails(uint256 instanceId) public view returns (EnvInstance memory) {
        return _instance[instanceId];
    }

    function totalInstances() public view returns (uint256) {
        return _totalInstances.current();
    }

    //
    // GSN
    //

    function setTrustedForwarder(address newTrustedForwarder) external onlyAdmin {
        _setTrustedForwarder(newTrustedForwarder);
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    //
    // Internal methods
    //

    function _createEnv(string memory name, string memory tag)
        internal
        returns (Environment memory env, uint256 environmentId)
    {
        environmentId = _totalEnvironments.current();

        _environment[environmentId] = Environment({instances: new uint256[](0), environmentName: name});
        _envTags[tag].add(environmentId);

        _totalEnvironments.increment();

        emit CreateEnvironment({
            sender: _msgSender(),
            name: name,
            tag: tag,
            tagIndexed: tag,
            environmentId: environmentId,
            timestamp: block.timestamp
        });
    }

    function _createInstance(
        uint256 environmentId,
        uint256 instanceType,
        address implementation,
        bytes memory initializerData
    ) internal returns (EnvInstance memory inst, uint256 instanceId) {
        address instanceContract = _deployTransparentProxy(implementation, proxyAdmin(), initializerData);
        // TODO check interfaces

        inst = EnvInstance({
            environmentId: environmentId,
            instanceType: instanceType,
            instanceContract: instanceContract,
            instanceImplementation: implementation
        });
        instanceId = _totalInstances.current();
        _instance[instanceId] = inst;
        _environment[environmentId].instances.push(instanceId);

        _totalInstances.increment();

        emit CreateInstance({
            sender: _msgSender(),
            environmentId: environmentId,
            instanceType: instanceType,
            implementation: implementation,
            initializerData: initializerData,
            instanceId: instanceId,
            instanceContract: instanceContract,
            instanceProxyAdmin: proxyAdmin(),
            timestamp: block.timestamp
        });
    }

    function _updateInstance(uint256 instanceId, address newImplementation) internal returns (EnvInstance memory) {
        EnvInstance storage inst = _instance[instanceId];

        emit UpgradeInstance({
            sender: _msgSender(),
            environmentId: inst.environmentId,
            instanceId: instanceId,
            oldImplementation: inst.instanceImplementation,
            newImplementation: newImplementation,
            timestamp: block.timestamp
        });

        _upgradeTransparentProxy(inst.instanceContract, newImplementation, proxyAdmin());

        // TODO check interfaces
        inst.instanceImplementation = newImplementation;

        return inst;
    }

    function _deployTransparentProxy(
        address implementation,
        address admin,
        bytes memory data
    ) private returns (address proxyAddress) {
        proxyAddress = address(new TransparentUpgradeableProxy(implementation, admin, data));
    }

    function _upgradeTransparentProxy(
        address proxy,
        address newImplementation,
        address admin
    ) private {
        ProxyAdmin(admin).upgrade(TransparentUpgradeableProxy(payable(proxy)), newImplementation);
    }

    function _getRandomSalt() internal view returns (uint256) {
        return (
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        block.number,
                        block.gaslimit,
                        gasleft(),
                        msg.sender,
                        msg.data
                    )
                )
            )
        );
    }

    //
    // Storage gap
    //

    uint256[46] private __gap;
}