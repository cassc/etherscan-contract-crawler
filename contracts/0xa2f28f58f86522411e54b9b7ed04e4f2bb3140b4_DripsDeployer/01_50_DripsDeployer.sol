// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {AddressDriver} from "./AddressDriver.sol";
import {Caller} from "./Caller.sol";
import {Drips} from "./Drips.sol";
import {ImmutableSplitsDriver} from "./ImmutableSplitsDriver.sol";
import {Managed, ManagedProxy} from "./Managed.sol";
import {NFTDriver} from "./NFTDriver.sol";
import {OperatorInterface, RepoDriver} from "./RepoDriver.sol";
import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

struct Module {
    bytes32 salt;
    uint256 amount;
    bytes initCode;
}

contract DripsDeployer is Ownable2Step {
    // slither-disable-next-line naming-convention
    bytes32[] internal _moduleSalts;
    address public immutable initialOwner;

    function args() public view returns (bytes memory) {
        return abi.encode(initialOwner);
    }

    constructor(address initialOwner_) {
        // slither-disable-next-line missing-zero-check
        initialOwner = initialOwner_;
        _transferOwnership(initialOwner);
    }

    function deployModules(
        Module[] calldata modules1,
        Module[] calldata modules2,
        Module[] calldata modules3,
        Module[] calldata modules4
    ) public onlyOwner {
        _deployModules(modules1);
        _deployModules(modules2);
        _deployModules(modules3);
        _deployModules(modules4);
    }

    function _deployModules(Module[] calldata modules) internal {
        for (uint256 i = 0; i < modules.length; i++) {
            Module calldata module = modules[i];
            _moduleSalts.push(module.salt);
            // slither-disable-next-line reentrancy-eth,reentrancy-no-eth
            Create3Factory.deploy(module.amount, module.salt, module.initCode);
        }
    }

    function moduleSalts() public view returns (bytes32[] memory) {
        return _moduleSalts;
    }

    function moduleAddress(bytes32 salt) public view returns (address addr) {
        return Create3Factory.getDeployed(salt);
    }
}

abstract contract BaseModule {
    DripsDeployer public immutable dripsDeployer;
    bytes32 public immutable moduleSalt;

    constructor(DripsDeployer dripsDeployer_, bytes32 moduleSalt_) {
        dripsDeployer = dripsDeployer_;
        moduleSalt = moduleSalt_;
        require(address(this) == _moduleAddress(moduleSalt_), "Invalid module deployment salt");
    }

    function args() public view virtual returns (bytes memory);

    function _moduleAddress(bytes32 salt) internal view returns (address addr) {
        return dripsDeployer.moduleAddress(salt);
    }

    modifier onlyModule(bytes32 salt) {
        require(msg.sender == _moduleAddress(bytes32(salt)));
        _;
    }
}

abstract contract ContractDeployerModule is BaseModule {
    bytes32 public immutable salt = "deployment";

    function deployment() public view returns (address) {
        return Create3Factory.getDeployed(salt);
    }

    function deploymentArgs() public view virtual returns (bytes memory);

    function _deployContract(bytes memory creationCode) internal {
        Create3Factory.deploy(0, salt, abi.encodePacked(creationCode, deploymentArgs()));
    }
}

abstract contract ProxyDeployerModule is BaseModule {
    bytes32 public immutable proxySalt = "proxy";
    address public proxyAdmin;
    address public logic;

    function proxy() public view returns (address) {
        return Create3Factory.getDeployed(proxySalt);
    }

    function proxyArgs() public view returns (bytes memory) {
        return abi.encode(logic, proxyAdmin);
    }

    function logicArgs() public view virtual returns (bytes memory);

    // slither-disable-next-line reentrancy-benign
    function _deployProxy(address proxyAdmin_, bytes memory logicCreationCode) internal {
        // Deploy logic
        address logic_;
        bytes memory logicInitCode = abi.encodePacked(logicCreationCode, logicArgs());
        // slither-disable-next-line assembly
        assembly ("memory-safe") {
            logic_ := create(0, add(logicInitCode, 32), mload(logicInitCode))
        }
        require(logic_ != address(0), "Logic deployment failed");
        logic = logic_;
        // Deploy proxy
        proxyAdmin = proxyAdmin_;
        // slither-disable-next-line too-many-digits
        bytes memory proxyInitCode = abi.encodePacked(type(ManagedProxy).creationCode, proxyArgs());
        Create3Factory.deploy(0, proxySalt, proxyInitCode);
    }
}

abstract contract DripsDependentModule is BaseModule {
    // slither-disable-next-line naming-convention
    bytes32 internal immutable _dripsModuleSalt = "Drips";

    function _dripsModule() internal view returns (DripsModule) {
        address module = _moduleAddress(_dripsModuleSalt);
        require(Address.isContract(module), "Drips module not deployed");
        return DripsModule(module);
    }
}

contract DripsModule is DripsDependentModule, ProxyDeployerModule {
    uint32 public immutable dripsCycleSecs;
    uint32 public immutable claimableDriverIds = 100;

    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer, dripsCycleSecs, proxyAdmin);
    }

    constructor(DripsDeployer dripsDeployer_, uint32 dripsCycleSecs_, address proxyAdmin_)
        BaseModule(dripsDeployer_, _dripsModuleSalt)
    {
        dripsCycleSecs = dripsCycleSecs_;
        // slither-disable-next-line too-many-digits
        _deployProxy(proxyAdmin_, type(Drips).creationCode);
        Drips drips_ = drips();
        for (uint256 i = 0; i < claimableDriverIds; i++) {
            // slither-disable-next-line calls-loop,unused-return
            drips_.registerDriver(address(this));
        }
    }

    function logicArgs() public view override returns (bytes memory) {
        return abi.encode(dripsCycleSecs);
    }

    function drips() public view returns (Drips) {
        return Drips(proxy());
    }

    function claimDriverId(bytes32 moduleSalt_, uint32 driverId, address driverAddr)
        public
        onlyModule(moduleSalt_)
    {
        drips().updateDriverAddress(driverId, driverAddr);
    }
}

abstract contract CallerDependentModule is BaseModule {
    // slither-disable-next-line naming-convention
    bytes32 internal immutable _callerModuleSalt = "Caller";

    function _callerModule() internal view returns (CallerModule) {
        address module = _moduleAddress(_callerModuleSalt);
        require(Address.isContract(module), "Caller module not deployed");
        return CallerModule(module);
    }
}

contract CallerModule is ContractDeployerModule, CallerDependentModule {
    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer);
    }

    constructor(DripsDeployer dripsDeployer_) BaseModule(dripsDeployer_, _callerModuleSalt) {
        // slither-disable-next-line too-many-digits
        _deployContract(type(Caller).creationCode);
    }

    function deploymentArgs() public pure override returns (bytes memory) {
        return abi.encode();
    }

    function caller() public view returns (Caller) {
        return Caller(deployment());
    }
}

abstract contract DriverModule is DripsDependentModule, ProxyDeployerModule {
    uint32 public immutable driverId;

    constructor(uint32 driverId_) {
        driverId = driverId_;
        _dripsModule().claimDriverId(moduleSalt, driverId, proxy());
    }
}

contract AddressDriverModule is CallerDependentModule, DriverModule(0) {
    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer, proxyAdmin);
    }

    constructor(DripsDeployer dripsDeployer_, address proxyAdmin_)
        BaseModule(dripsDeployer_, "AddressDriver")
    {
        // slither-disable-next-line too-many-digits
        _deployProxy(proxyAdmin_, type(AddressDriver).creationCode);
    }

    function logicArgs() public view override returns (bytes memory) {
        return abi.encode(_dripsModule().drips(), _callerModule().caller(), driverId);
    }

    function addressDriver() public view returns (AddressDriver) {
        return AddressDriver(proxy());
    }
}

contract NFTDriverModule is CallerDependentModule, DriverModule(1) {
    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer, proxyAdmin);
    }

    constructor(DripsDeployer dripsDeployer_, address proxyAdmin_)
        BaseModule(dripsDeployer_, "NFTDriver")
    {
        // slither-disable-next-line too-many-digits
        _deployProxy(proxyAdmin_, type(NFTDriver).creationCode);
    }

    function logicArgs() public view override returns (bytes memory) {
        return abi.encode(_dripsModule().drips(), _callerModule().caller(), driverId);
    }

    function nftDriver() public view returns (NFTDriver) {
        return NFTDriver(proxy());
    }
}

contract ImmutableSplitsDriverModule is DriverModule(2) {
    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer, proxyAdmin);
    }

    constructor(DripsDeployer dripsDeployer_, address proxyAdmin_)
        BaseModule(dripsDeployer_, "ImmutableSplitsDriver")
    {
        // slither-disable-next-line too-many-digits
        _deployProxy(proxyAdmin_, type(ImmutableSplitsDriver).creationCode);
    }

    function logicArgs() public view override returns (bytes memory) {
        return abi.encode(_dripsModule().drips(), driverId);
    }

    function immutableSplitsDriver() public view returns (ImmutableSplitsDriver) {
        return ImmutableSplitsDriver(proxy());
    }
}

contract RepoDriverModule is CallerDependentModule, DriverModule(3) {
    OperatorInterface public immutable operator;
    bytes32 public immutable jobId;
    uint96 public immutable defaultFee;

    function args() public view override returns (bytes memory) {
        return abi.encode(dripsDeployer, proxyAdmin, operator, jobId, defaultFee);
    }

    constructor(
        DripsDeployer dripsDeployer_,
        address proxyAdmin_,
        OperatorInterface operator_,
        bytes32 jobId_,
        uint96 defaultFee_
    ) BaseModule(dripsDeployer_, "RepoDriver") {
        operator = operator_;
        jobId = jobId_;
        defaultFee = defaultFee_;
        // slither-disable-next-line too-many-digits
        _deployProxy(proxyAdmin_, type(RepoDriver).creationCode);
        repoDriver().initializeAnyApiOperator(operator, jobId, defaultFee);
    }

    function logicArgs() public view override returns (bytes memory) {
        return abi.encode(_dripsModule().drips(), _callerModule().caller(), driverId);
    }

    function repoDriver() public view returns (RepoDriver) {
        return RepoDriver(proxy());
    }
}

/// @notice Deploys contracts using CREATE3.
/// Each deployer has its own namespace for deployed addresses.
library Create3Factory {
    /// @notice The CREATE3 factory address.
    /// It's always the same, see `deploy_create3_factory` in the deployment script.
    ICreate3Factory private constant _CREATE3_FACTORY =
        ICreate3Factory(0x6aA3D87e99286946161dCA02B97C5806fC5eD46F);

    /// @notice Deploys a contract using CREATE3.
    /// @param amount The amount to pass into the deployed contract's constructor.
    /// @param salt The deployer-specific salt for determining the deployed contract's address.
    /// @param creationCode The creation code of the contract to deploy.
    function deploy(uint256 amount, bytes32 salt, bytes memory creationCode) internal {
        // slither-disable-next-line unused-return
        _CREATE3_FACTORY.deploy{value: amount}(salt, creationCode);
    }

    /// @notice Predicts the address of a contract deployed by this contract.
    /// @param salt The deployer-specific salt for determining the deployed contract's address.
    /// @return deployed The address of the contract that will be deployed.
    function getDeployed(bytes32 salt) internal view returns (address deployed) {
        return _CREATE3_FACTORY.getDeployed(address(this), salt);
    }
}

/// @title Factory for deploying contracts to deterministic addresses via CREATE3.
/// @author zefram.eth, taken from https://github.com/ZeframLou/create3-factory.
/// @notice Enables deploying contracts using CREATE3.
/// Each deployer (`msg.sender`) has its own namespace for deployed addresses.
interface ICreate3Factory {
    /// @notice Deploys a contract using CREATE3.
    /// @dev The provided salt is hashed together with msg.sender to generate the final salt.
    /// @param salt The deployer-specific salt for determining the deployed contract's address.
    /// @param creationCode The creation code of the contract to deploy.
    /// @return deployed The address of the deployed contract.
    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        returns (address deployed);

    /// @notice Predicts the address of a deployed contract.
    /// @dev The provided salt is hashed together
    /// with the deployer address to generate the final salt.
    /// @param deployer The deployer account that will call `deploy()`.
    /// @param salt The deployer-specific salt for determining the deployed contract's address.
    /// @return deployed The address of the contract that will be deployed.
    function getDeployed(address deployer, bytes32 salt) external view returns (address deployed);
}