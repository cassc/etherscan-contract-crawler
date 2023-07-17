// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {IPoolFactory} from './IPoolFactory.sol';
import {IPrime} from '../PrimeMembership/IPrime.sol';
import {Pool, IPool} from './Pool.sol';

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {BeaconProxy} from '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

import {NZAGuard} from '../utils/NZAGuard.sol';

/// @title Prime PoolFactory contract is responsible for creating new pools
contract PoolFactory is
  IPoolFactory,
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  NZAGuard
{
  /// @notice Prime contract address
  IPrime public prime;

  /// @notice Beacon address for pool proxy pattern
  address public poolBeacon;

  /// @notice Array of pool addresses
  address[] public pools;

  /// @notice Deposit window minimum duration
  uint256 internal minDepositWindow;

  /// @notice Minimum range between deposit window and maturity
  uint256 internal liquidityMinRange;

  /// @notice monthly pool maturity minimal value
  uint256 internal minMonthlyMaturity;

  /// @notice Emitted when prime contract address is changed
  event PrimeContractChanged(address oldAddress, address newAddress);

  /// @notice Emitted when pool beacon address is changed
  event PoolBeaconChanged(address oldAddress, address newAddress);

  /// @notice Emitted when a new pool is created
  event PoolCreated(
    address pool,
    address indexed borrower,
    bool isBulletLoan,
    address indexed asset,
    uint256 size,
    uint256 rateMantissa,
    uint256 tenor,
    uint256 depositWindow,
    uint256 spreadRate,
    uint256 originationRate,
    uint256 incrementPerRoll,
    uint256 penaltyRatePerYear
  );

  /// @notice Modifier to check if the caller is a prime member
  modifier onlyPrime() {
    _isPrimeMember(msg.sender);
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc IPoolFactory
  function __PoolFactory_init(
    address _prime,
    address _poolBeacon
  ) external override nonZeroAddress(_prime) nonZeroAddress(_poolBeacon) initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    prime = IPrime(_prime);
    poolBeacon = _poolBeacon;

    /// @dev deposit window should be greater than 1 hour
    minDepositWindow = 1 hours;

    /// @dev Tenor should be greater than 65 days for non bullet (monthly repayment) loans
    minMonthlyMaturity = 65 days;

    /// @dev Tenor should be greater than 50 hours and greater than deposit window
    liquidityMinRange = 49 hours;
  }

  struct PrimeRates {
    uint256 spreadRate;
    uint256 originationRate;
    uint256 incrementPerRoll;
    uint256 penaltyRatePerYear;
  }

  /// @inheritdoc IPoolFactory
  function createPool(
    IPool.PoolData calldata pooldata,
    bytes calldata members
  ) external override onlyPrime nonZeroAddress(pooldata.asset) nonZeroValue(pooldata.size) {
    require(pooldata.depositWindow >= minDepositWindow, 'UTR');
    require(pooldata.tenor >= pooldata.depositWindow + liquidityMinRange, 'DET');
    if (!pooldata.isBulletLoan) {
      require(pooldata.tenor >= minMonthlyMaturity, 'TTS');
    }
    require(prime.isAssetAvailable(pooldata.asset), 'AAI');

    /// @dev Fetches spread, origination rate and rolling increment from prime contract
    PrimeRates memory rates = PrimeRates(
      prime.spreadRate(),
      prime.originationRate(),
      prime.incrementPerRoll(),
      prime.penaltyRatePerYear()
    );

    /// @dev Creates a pool using beacon proxy pattern
    address pool = address(new BeaconProxy(poolBeacon, ''));

    /// @dev Initializes the pool according to the pool beacon pattern
    IPool(pool).__Pool_init(
      msg.sender,
      rates.spreadRate,
      rates.originationRate,
      rates.incrementPerRoll,
      rates.penaltyRatePerYear,
      pooldata,
      members
    );

    pools.push(pool);

    emit PoolCreated(
      pool,
      msg.sender,
      pooldata.isBulletLoan,
      pooldata.asset,
      pooldata.size,
      pooldata.rateMantissa,
      pooldata.tenor,
      pooldata.depositWindow,
      rates.spreadRate,
      rates.originationRate,
      rates.incrementPerRoll,
      rates.penaltyRatePerYear
    );
  }

  /// @notice Marks the pools as defaulted
  /// @dev Callable only by owner
  function defaultPools(address[] calldata _pools) external onlyOwner {
    uint256 length = _pools.length;
    for (uint256 i = 0; i < length; ++i) {
      IPool(_pools[i]).markPoolDefaulted();
    }
  }

  /// @notice Returns the pools array
  /// @return Array of pool addresses
  function getPools() external view returns (address[] memory) {
    return pools;
  }

  /// @notice Changes the prime contract address
  /// @dev Callable only by owner
  /// @param newAddress New prime contract address
  function setPrimeContract(
    address newAddress
  ) external nonZeroAddress(newAddress) nonSameAddress(newAddress, address(prime)) onlyOwner {
    address currentAddress = address(prime);

    prime = IPrime(newAddress);
    emit PrimeContractChanged(currentAddress, newAddress);
  }

  /// @notice Changes the pool beacon address
  /// @dev Callable only by owner
  /// @param _newPoolBeacon New pool beacon address
  function setPoolBeacon(
    address _newPoolBeacon
  ) external nonZeroAddress(_newPoolBeacon) nonSameAddress(_newPoolBeacon, poolBeacon) onlyOwner {
    address currentAddress = poolBeacon;
    poolBeacon = _newPoolBeacon;

    emit PoolBeaconChanged(currentAddress, _newPoolBeacon);
  }

  /// @notice Checks if the caller is a prime member
  /// @dev Internal function, reverts if the caller is not a prime member
  /// @param _member Member address
  function _isPrimeMember(address _member) internal view {
    require(prime.isMember(_member), 'NPM');
  }
}