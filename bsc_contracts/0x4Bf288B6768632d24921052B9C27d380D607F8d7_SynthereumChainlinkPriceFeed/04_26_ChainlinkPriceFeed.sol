// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumRegistry
} from '../../core/registries/interfaces/IRegistry.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  ISynthereumChainlinkPriceFeed
} from './interfaces/IChainlinkPriceFeed.sol';
import {ITypology} from '../../common/interfaces/ITypology.sol';
import {
  AggregatorV3Interface
} from '../../../@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {
  AccessControlEnumerable
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

contract SynthereumChainlinkPriceFeed is
  ISynthereumChainlinkPriceFeed,
  AccessControlEnumerable
{
  using PreciseUnitMath for uint256;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  struct Pair {
    bool isSupported;
    Type priceType;
    AggregatorV3Interface aggregator;
    bytes32[] intermediatePairs;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  ISynthereumFinder public immutable synthereumFinder;
  mapping(bytes32 => Pair) public pairs;
  //----------------------------------------
  // Events
  //----------------------------------------

  event SetPair(
    bytes32 indexed priceIdentifier,
    Type kind,
    address aggregator,
    bytes32[] intermediatePairs
  );

  event RemovePair(bytes32 indexed priceIdentifier);

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumChainlinkPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

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

  modifier onlyPoolsOrSelfMinting() {
    if (msg.sender != tx.origin) {
      ISynthereumRegistry registry;
      try ITypology(msg.sender).typology() returns (
        string memory typologyString
      ) {
        bytes32 typology = keccak256(abi.encodePacked(typologyString));
        if (typology == keccak256(abi.encodePacked('POOL'))) {
          registry = ISynthereumRegistry(
            synthereumFinder.getImplementationAddress(
              SynthereumInterfaces.PoolRegistry
            )
          );
        } else if (typology == keccak256(abi.encodePacked('SELF-MINTING'))) {
          registry = ISynthereumRegistry(
            synthereumFinder.getImplementationAddress(
              SynthereumInterfaces.SelfMintingRegistry
            )
          );
        } else {
          revert('Typology not supported');
        }
      } catch {
        registry = ISynthereumRegistry(
          synthereumFinder.getImplementationAddress(
            SynthereumInterfaces.PoolRegistry
          )
        );
      }
      ISynthereumDeployment callingContract = ISynthereumDeployment(msg.sender);
      require(
        registry.isDeployed(
          callingContract.syntheticTokenSymbol(),
          callingContract.collateralToken(),
          callingContract.version(),
          msg.sender
        ),
        'Calling contract not registered'
      );
    }
    _;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  function setPair(
    Type _kind,
    bytes32 _priceIdentifier,
    address _aggregator,
    bytes32[] memory _intermediatePairs
  ) external override onlyMaintainer {
    if (_kind == Type.INVERSE || _kind == Type.STANDARD) {
      require(_aggregator != address(0), 'No aggregator set');
      require(
        _intermediatePairs.length == 0,
        'No intermediate pairs should be specified'
      );
    } else {
      require(_aggregator == address(0), 'Aggregator should not be set');
      require(_intermediatePairs.length > 0, 'No intermediate pairs set');
    }

    pairs[_priceIdentifier] = Pair(
      true,
      _kind,
      AggregatorV3Interface(_aggregator),
      _intermediatePairs
    );
    emit SetPair(_priceIdentifier, _kind, _aggregator, _intermediatePairs);
  }

  function removePair(bytes32 _priceIdentifier)
    external
    override
    onlyMaintainer
  {
    require(
      pairs[_priceIdentifier].isSupported,
      'Price identifier does not exist'
    );
    delete pairs[_priceIdentifier];
    emit RemovePair(_priceIdentifier);
  }

  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 _priceIdentifier)
    external
    view
    override
    onlyPoolsOrSelfMinting
    returns (uint256 price)
  {
    price = _getLatestPrice(_priceIdentifier);
  }

  /**
   * @notice Get last chainlink oracle price of a set of price identifiers
   * @param _priceIdentifiers Array of Price feed identifier
   * @return prices Oracle prices for the ids
   */
  function getLatestPrices(bytes32[] calldata _priceIdentifiers)
    external
    view
    override
    onlyPoolsOrSelfMinting
    returns (uint256[] memory prices)
  {
    prices = new uint256[](_priceIdentifiers.length);
    for (uint256 i = 0; i < _priceIdentifiers.length; i++) {
      prices[i] = _getLatestPrice(_priceIdentifiers[i]);
    }
  }

  /**
   * @notice Get chainlink oracle price in a given round for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return price Oracle price
   */
  function getRoundPrice(bytes32 _priceIdentifier, uint80 _roundId)
    external
    view
    override
    onlyPoolsOrSelfMinting
    returns (uint256 price)
  {
    Type priceType = pairs[_priceIdentifier].priceType;
    require(priceType != Type.COMPUTED, 'Computed price not supported');

    OracleData memory oracleData =
      _getOracleRoundData(_priceIdentifier, _roundId);
    price = _getScaledValue(oracleData.answer, oracleData.decimals);

    if (priceType == Type.INVERSE) {
      price = PreciseUnitMath.PRECISE_UNIT.div(price);
    }
  }

  /**
   * @notice Return if price identifier is supported
   * @param _priceIdentifier Price feed identifier
   * @return isSupported True if price is supported otherwise false
   */
  function isPriceSupported(bytes32 _priceIdentifier)
    external
    view
    override
    returns (bool isSupported)
  {
    isSupported = pairs[_priceIdentifier].isSupported;
  }

  //----------------------------------------
  // Public view functions
  //----------------------------------------

  /**
   * @notice Returns the address of aggregator if exists, otherwise it reverts
   * @param _priceIdentifier Price feed identifier
   * @return aggregator Aggregator associated with price identifier
   */
  function getAggregator(bytes32 _priceIdentifier)
    public
    view
    override
    returns (AggregatorV3Interface aggregator)
  {
    require(
      pairs[_priceIdentifier].isSupported,
      'Price identifier does not exist'
    );
    aggregator = pairs[_priceIdentifier].aggregator;
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------

  /**
   * @notice Calculate a computed price of a specific pair
   * @notice A computed price is obtained by combining prices from separate aggregators
   * @param _pair Struct identifying the pair of assets
   * @return price 18 decimals scaled price of the pair
   */
  function _getComputedPrice(Pair memory _pair)
    internal
    view
    returns (uint256 price)
  {
    bytes32[] memory intermediatePairs = _pair.intermediatePairs;

    price = 10**18;
    for (uint8 i = 0; i < intermediatePairs.length; i++) {
      uint256 intermediatePrice = _getLatestPrice(intermediatePairs[i]);
      price = price.mul(intermediatePrice);
    }
  }

  /**
   * @notice Calculate the inverse price of a given pair
   * @param _priceId Price feed identifier
   * @return price 18 decimals scaled price of the pair
   */
  function _getInversePrice(bytes32 _priceId)
    internal
    view
    returns (uint256 price)
  {
    OracleData memory oracleData = _getOracleLatestRoundData(_priceId);
    price = 10**36 / _getScaledValue(oracleData.answer, oracleData.decimals);
  }

  /**
   * @notice Retrieve from aggregator the price of a given pair
   * @param _priceId Price feed identifier
   * @return price 18 decimals scaled price of the pair
   */
  function _getStandardPrice(bytes32 _priceId)
    internal
    view
    returns (uint256 price)
  {
    OracleData memory oracleData = _getOracleLatestRoundData(_priceId);
    price = _getScaledValue(oracleData.answer, oracleData.decimals);
  }

  /**
   * @notice Get last chainlink oracle data for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @return oracleData Oracle data
   */
  function _getOracleLatestRoundData(bytes32 _priceIdentifier)
    internal
    view
    returns (OracleData memory oracleData)
  {
    AggregatorV3Interface aggregator = getAggregator(_priceIdentifier);
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    oracleData = OracleData(
      roundId,
      _convertPrice(answer),
      startedAt,
      updatedAt,
      answeredInRound,
      decimals
    );
  }

  /**
   * @notice Get chainlink oracle data in a given round for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return oracleData Oracle data
   */
  function _getOracleRoundData(bytes32 _priceIdentifier, uint80 _roundId)
    internal
    view
    returns (OracleData memory oracleData)
  {
    AggregatorV3Interface aggregator = getAggregator(_priceIdentifier);
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = aggregator.getRoundData(_roundId);
    uint8 decimals = aggregator.decimals();
    oracleData = OracleData(
      roundId,
      _convertPrice(answer),
      startedAt,
      updatedAt,
      answeredInRound,
      decimals
    );
  }

  //----------------------------------------
  // Internal pure functions
  //----------------------------------------
  function _getLatestPrice(bytes32 _priceIdentifier)
    internal
    view
    returns (uint256 price)
  {
    Pair memory pair = pairs[_priceIdentifier];

    if (pair.priceType == Type.STANDARD) {
      price = _getStandardPrice(_priceIdentifier);
    } else if (pair.priceType == Type.INVERSE) {
      price = _getInversePrice(_priceIdentifier);
    } else {
      price = _getComputedPrice(pair);
    }
  }

  /**
   * @notice Covert the price from int to uint and it reverts if negative
   * @param _uncovertedPrice Price before conversion
   * @return price Price after conversion
   */

  function _convertPrice(int256 _uncovertedPrice)
    internal
    pure
    returns (uint256 price)
  {
    require(_uncovertedPrice >= 0, 'Negative value');
    price = uint256(_uncovertedPrice);
  }

  /**
   * @notice Covert the price to a integer with 18 decimals
   * @param _unscaledPrice Price before conversion
   * @param _decimals Number of decimals of unconverted price
   * @return price Price after conversion
   */

  function _getScaledValue(uint256 _unscaledPrice, uint8 _decimals)
    internal
    pure
    returns (uint256 price)
  {
    price = _unscaledPrice * (10**(18 - _decimals));
  }
}