// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {ISynthereumDeployer} from './interfaces/IDeployer.sol';
import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {ISynthereumRegistry} from './registries/interfaces/IRegistry.sol';
import {ISynthereumManager} from './interfaces/IManager.sol';
import {IDeploymentSignature} from './interfaces/IDeploymentSignature.sol';
import {IMigrationSignature} from './interfaces/IMigrationSignature.sol';
import {ISynthereumDeployment} from '../common/interfaces/IDeployment.sol';
import {
  IAccessControlEnumerable
} from '../../@openzeppelin/contracts/access/IAccessControlEnumerable.sol';
import {SynthereumInterfaces, FactoryInterfaces} from './Constants.sol';
import {
  SynthereumPoolMigrationFrom
} from '../synthereum-pool/common/migration/PoolMigrationFrom.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

contract SynthereumDeployer is
  ISynthereumDeployer,
  ReentrancyGuard,
  AccessControlEnumerable
{
  using Address for address;

  bytes32 private constant ADMIN_ROLE = 0x00;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 private constant MINTER_ROLE = keccak256('Minter');

  bytes32 private constant BURNER_ROLE = keccak256('Burner');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // State variables
  //----------------------------------------

  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------

  event PoolDeployed(uint8 indexed poolVersion, address indexed newPool);

  event PoolMigrated(
    address indexed migratedPool,
    uint8 indexed poolVersion,
    address indexed newPool
  );

  event SelfMintingDerivativeDeployed(
    uint8 indexed selfMintingDerivativeVersion,
    address indexed selfMintingDerivative
  );

  event FixedRateDeployed(
    uint8 indexed fixedRateVersion,
    address indexed fixedRate
  );

  event PoolRemoved(address pool);

  event SelfMintingDerivativeRemoved(address selfMintingDerivative);

  event FixedRateRemoved(address fixedRate);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumDeployer contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Maintainer roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Deploy a new pool
   * @param _poolVersion Version of the pool contract to create
   * @param _poolParamsData Input params of pool constructor
   * @return pool Pool contract deployed
   */
  function deployPool(uint8 _poolVersion, bytes calldata _poolParamsData)
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment pool)
  {
    pool = _deployPool(getFactoryVersioning(), _poolVersion, _poolParamsData);
    checkDeployment(pool, _poolVersion);
    setSyntheticTokenRoles(pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      _poolVersion,
      address(pool)
    );
    emit PoolDeployed(_poolVersion, address(pool));
  }

  /**
   * @notice Migrate storage of an existing pool to e new deployed one
   * @param _migrationPool Pool from which migrate storage
   * @param _poolVersion Version of the pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return pool Pool contract created with the storage of the migrated one
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _poolVersion,
    bytes calldata _migrationParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment pool)
  {
    ISynthereumDeployment oldPool;
    (oldPool, pool) = _migratePool(
      getFactoryVersioning(),
      _poolVersion,
      _migrationParamsData
    );
    require(
      address(_migrationPool) == address(oldPool),
      'Wrong migration pool'
    );
    checkDeployment(pool, _poolVersion);
    removeSyntheticTokenRoles(oldPool);
    setSyntheticTokenRoles(pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      _poolVersion,
      address(pool)
    );
    poolRegistry.unregister(
      oldPool.syntheticTokenSymbol(),
      oldPool.collateralToken(),
      oldPool.version(),
      address(oldPool)
    );
    emit PoolMigrated(address(_migrationPool), _poolVersion, address(pool));
    emit PoolRemoved(address(oldPool));
  }

  /**
   * @notice Remove from the registry an existing pool
   * @param _pool Pool to remove
   */
  function removePool(ISynthereumDeployment _pool)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    _checkMissingRoles(_pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    address pool = address(_pool);
    poolRegistry.unregister(
      _pool.syntheticTokenSymbol(),
      _pool.collateralToken(),
      _pool.version(),
      pool
    );
    emit PoolRemoved(pool);
  }

  /**
   * @notice Deploy a new self minting derivative contract
   * @param _selfMintingDerVersion Version of the self minting derivative contract
   * @param _selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deploySelfMintingDerivative(
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment selfMintingDerivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    selfMintingDerivative = _deploySelfMintingDerivative(
      factoryVersioning,
      _selfMintingDerVersion,
      _selfMintingDerParamsData
    );
    checkDeployment(selfMintingDerivative, _selfMintingDerVersion);
    address tokenCurrency = address(selfMintingDerivative.syntheticToken());
    modifySyntheticTokenRoles(
      tokenCurrency,
      address(selfMintingDerivative),
      true
    );
    ISynthereumRegistry selfMintingRegistry = getSelfMintingRegistry();
    selfMintingRegistry.register(
      selfMintingDerivative.syntheticTokenSymbol(),
      selfMintingDerivative.collateralToken(),
      _selfMintingDerVersion,
      address(selfMintingDerivative)
    );
    emit SelfMintingDerivativeDeployed(
      _selfMintingDerVersion,
      address(selfMintingDerivative)
    );
  }

  /**
   * @notice Remove from the registry an existing self-minting derivativ contract
   * @param _selfMintingDerivative Self-minting derivative to remove
   */
  function removeSelfMintingDerivative(
    ISynthereumDeployment _selfMintingDerivative
  ) external override onlyMaintainer nonReentrant {
    _checkMissingRoles(_selfMintingDerivative);
    ISynthereumRegistry selfMintingRegistry = getSelfMintingRegistry();
    address selfMintingDerivative = address(_selfMintingDerivative);
    selfMintingRegistry.unregister(
      _selfMintingDerivative.syntheticTokenSymbol(),
      _selfMintingDerivative.collateralToken(),
      _selfMintingDerivative.version(),
      selfMintingDerivative
    );
    emit SelfMintingDerivativeRemoved(selfMintingDerivative);
  }

  /**
   * @notice Deploy a fixed rate wrapper
   * @param _fixedRateVersion Version of the fixed rate wrapper contract
   * @param _fixedRateParamsData Input params of the fixed rate wrapper constructor
   * @return fixedRate FixedRate wrapper deployed
   */

  function deployFixedRate(
    uint8 _fixedRateVersion,
    bytes calldata _fixedRateParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment fixedRate)
  {
    fixedRate = _deployFixedRate(
      getFactoryVersioning(),
      _fixedRateVersion,
      _fixedRateParamsData
    );
    checkDeployment(fixedRate, _fixedRateVersion);
    setSyntheticTokenRoles(fixedRate);
    ISynthereumRegistry fixedRateRegistry = getFixedRateRegistry();
    fixedRateRegistry.register(
      fixedRate.syntheticTokenSymbol(),
      fixedRate.collateralToken(),
      _fixedRateVersion,
      address(fixedRate)
    );
    emit FixedRateDeployed(_fixedRateVersion, address(fixedRate));
  }

  /**
   * @notice Remove from the registry a fixed rate wrapper
   * @param _fixedRate Fixed-rate to remove
   */
  function removeFixedRate(ISynthereumDeployment _fixedRate)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    _checkMissingRoles(_fixedRate);
    ISynthereumRegistry fixedRateRegistry = getFixedRateRegistry();
    address fixedRate = address(_fixedRate);
    fixedRateRegistry.unregister(
      _fixedRate.syntheticTokenSymbol(),
      _fixedRate.collateralToken(),
      _fixedRate.version(),
      fixedRate
    );
    emit FixedRateRemoved(fixedRate);
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  /**
   * @notice Deploys a pool contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _poolVersion Version of pool contract to deploy
   * @param _poolParamsData Input parameters of constructor of the pool
   * @return pool Pool deployed
   */
  function _deployPool(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _poolVersion,
    bytes memory _poolParamsData
  ) internal returns (ISynthereumDeployment pool) {
    address poolFactory =
      _factoryVersioning.getFactoryVersion(
        FactoryInterfaces.PoolFactory,
        _poolVersion
      );
    bytes memory poolDeploymentResult =
      poolFactory.functionCall(
        abi.encodePacked(getDeploymentSignature(poolFactory), _poolParamsData),
        'Wrong pool deployment'
      );
    pool = ISynthereumDeployment(abi.decode(poolDeploymentResult, (address)));
  }

  /**
   * @notice Migrate a pool contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _poolVersion Version of pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return oldPool Pool from which the storage is migrated
   * @return newPool New pool created
   */
  function _migratePool(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _poolVersion,
    bytes memory _migrationParamsData
  )
    internal
    returns (ISynthereumDeployment oldPool, ISynthereumDeployment newPool)
  {
    address poolFactory =
      _factoryVersioning.getFactoryVersion(
        FactoryInterfaces.PoolFactory,
        _poolVersion
      );
    bytes memory poolDeploymentResult =
      poolFactory.functionCall(
        abi.encodePacked(
          getMigrationSignature(poolFactory),
          _migrationParamsData
        ),
        'Wrong pool migration'
      );
    (oldPool, newPool) = abi.decode(
      poolDeploymentResult,
      (ISynthereumDeployment, ISynthereumDeployment)
    );
  }

  /**
   * @notice Deploys a self minting derivative contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _selfMintingDerVersion Version of self minting derivate contract to deploy
   * @param _selfMintingDerParamsData Input parameters of constructor of self minting derivative
   * @return selfMintingDerivative Self minting derivative deployed
   */
  function _deploySelfMintingDerivative(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  ) internal returns (ISynthereumDeployment selfMintingDerivative) {
    address selfMintingDerFactory =
      _factoryVersioning.getFactoryVersion(
        FactoryInterfaces.SelfMintingFactory,
        _selfMintingDerVersion
      );
    bytes memory selfMintingDerDeploymentResult =
      selfMintingDerFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(selfMintingDerFactory),
          _selfMintingDerParamsData
        ),
        'Wrong self-minting derivative deployment'
      );
    selfMintingDerivative = ISynthereumDeployment(
      abi.decode(selfMintingDerDeploymentResult, (address))
    );
  }

  /**
   * @notice Deploys a fixed rate wrapper contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _fixedRateVersion Version of the fixed rate wrapper contract to deploy
   * @param _fixedRateParamsData Input parameters of constructor of the fixed rate wrapper
   * @return fixedRate Fixed rate wrapper deployed
   */

  function _deployFixedRate(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _fixedRateVersion,
    bytes memory _fixedRateParamsData
  ) internal returns (ISynthereumDeployment fixedRate) {
    address fixedRateFactory =
      _factoryVersioning.getFactoryVersion(
        FactoryInterfaces.FixedRateFactory,
        _fixedRateVersion
      );
    bytes memory fixedRateDeploymentResult =
      fixedRateFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(fixedRateFactory),
          _fixedRateParamsData
        ),
        'Wrong fixed rate deployment'
      );
    fixedRate = ISynthereumDeployment(
      abi.decode(fixedRateDeploymentResult, (address))
    );
  }

  /**
   * @notice Sets roles of the synthetic token contract to a pool or a fixed rate wrapper
   * @param _financialContract Pool or fixed rate wrapper contract
   */
  function setSyntheticTokenRoles(ISynthereumDeployment _financialContract)
    internal
  {
    address financialContract = address(_financialContract);
    IAccessControlEnumerable tokenCurrency =
      IAccessControlEnumerable(address(_financialContract.syntheticToken()));
    if (
      !tokenCurrency.hasRole(MINTER_ROLE, financialContract) ||
      !tokenCurrency.hasRole(BURNER_ROLE, financialContract)
    ) {
      modifySyntheticTokenRoles(
        address(tokenCurrency),
        financialContract,
        true
      );
    }
  }

  /**
   * @notice Remove roles of the synthetic token contract from a pool
   * @param _financialContract Pool contract
   */
  function removeSyntheticTokenRoles(ISynthereumDeployment _financialContract)
    internal
  {
    IAccessControlEnumerable tokenCurrency =
      IAccessControlEnumerable(address(_financialContract.syntheticToken()));
    modifySyntheticTokenRoles(
      address(tokenCurrency),
      address(_financialContract),
      false
    );
  }

  /**
   * @notice Grants minter and burner role of syntehtic token to derivative
   * @param _tokenCurrency Address of the token contract
   * @param _contractAddr Address of the pool or self-minting derivative
   * @param _isAdd True if adding roles, false if removing
   */
  function modifySyntheticTokenRoles(
    address _tokenCurrency,
    address _contractAddr,
    bool _isAdd
  ) internal {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](2);
    bytes32[] memory roles = new bytes32[](2);
    address[] memory accounts = new address[](2);
    contracts[0] = _tokenCurrency;
    contracts[1] = _tokenCurrency;
    roles[0] = MINTER_ROLE;
    roles[1] = BURNER_ROLE;
    accounts[0] = _contractAddr;
    accounts[1] = _contractAddr;
    _isAdd
      ? manager.grantSynthereumRole(contracts, roles, accounts)
      : manager.revokeSynthereumRole(contracts, roles, accounts);
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------

  /**
   * @notice Get factory versioning contract from the finder
   * @return factoryVersioning Factory versioning contract
   */
  function getFactoryVersioning()
    internal
    view
    returns (ISynthereumFactoryVersioning factoryVersioning)
  {
    factoryVersioning = ISynthereumFactoryVersioning(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FactoryVersioning
      )
    );
  }

  /**
   * @notice Get pool registry contract from the finder
   * @return poolRegistry Registry of pools
   */
  function getPoolRegistry()
    internal
    view
    returns (ISynthereumRegistry poolRegistry)
  {
    poolRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PoolRegistry
      )
    );
  }

  /**
   * @notice Get self minting registry contract from the finder
   * @return selfMintingRegistry Registry of self-minting derivatives
   */
  function getSelfMintingRegistry()
    internal
    view
    returns (ISynthereumRegistry selfMintingRegistry)
  {
    selfMintingRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.SelfMintingRegistry
      )
    );
  }

  /**
   * @notice Get fixed rate registry contract from the finder
   * @return fixedRateRegistry Registry of fixed rate contract
   */
  function getFixedRateRegistry()
    internal
    view
    returns (ISynthereumRegistry fixedRateRegistry)
  {
    fixedRateRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FixedRateRegistry
      )
    );
  }

  /**
   * @notice Get manager contract from the finder
   * @return manager Synthereum manager
   */
  function getManager() internal view returns (ISynthereumManager manager) {
    manager = ISynthereumManager(
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
    );
  }

  /**
   * @notice Get signature of function to deploy a contract
   * @param _factory Factory contract
   * @return signature Signature of deployment function of the factory
   */
  function getDeploymentSignature(address _factory)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IDeploymentSignature(_factory).deploymentSignature();
  }

  /**
   * @notice Get signature of function to migrate a pool
   * @param _factory Factory contract
   * @return signature Signature of migration function of the factory
   */
  function getMigrationSignature(address _factory)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IMigrationSignature(_factory).migrationSignature();
  }

  /**
   * @notice Check correct finder and version of the deployed pool or self-minting derivative
   * @param _financialContract Contract pool or self-minting derivative or fixed-rate to check
   * @param _version Pool or self-minting derivative version to check
   */
  function checkDeployment(
    ISynthereumDeployment _financialContract,
    uint8 _version
  ) internal view {
    require(
      _financialContract.synthereumFinder() == synthereumFinder,
      'Wrong finder in deployment'
    );
    require(
      _financialContract.version() == _version,
      'Wrong version in deployment'
    );
  }

  /**
   * @notice Check removing contract has not minter and burner roles of the synth tokens
   * @param _financialContract Contract pool or self-minting derivative or fixed-rate to check
   */
  function _checkMissingRoles(ISynthereumDeployment _financialContract)
    internal
    view
  {
    address financialContract = address(_financialContract);
    IAccessControlEnumerable tokenCurrency =
      IAccessControlEnumerable(address(_financialContract.syntheticToken()));
    require(
      !tokenCurrency.hasRole(MINTER_ROLE, financialContract),
      'Contract has minter role'
    );
    require(
      !tokenCurrency.hasRole(BURNER_ROLE, financialContract),
      'Contract has burner role'
    );
  }
}