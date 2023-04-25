/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/lending/fluxOracles/IFluxOracle.sol";
import "contracts/cash/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/lending/rwaOracles/IRWAOracle.sol";
import "contracts/lending/chainlink/AggregatorV3Interface.sol";
import {IERC20Like, ICTokenLike} from "contracts/lending/HelperInterfaces.sol";

contract FluxOracle is IFluxOracle, AccessControlEnumerable {
  /// @notice fToken to Oracle Type association
  mapping(address => OracleType) public fTokenToOracleType;

  /// @notice fToken to hardcoded price association
  mapping(address => uint256) public fTokenToHardcodedPrice;

  /// @notice fToken to RWA Oracle association
  mapping(address => address) public fTokenToRWAOracle;

  /// @notice fToken to Chainlink oracle association
  mapping(address => ChainlinkOracleInfo) public fTokenToChainlinkOracle;

  struct ChainlinkOracleInfo {
    AggregatorV3Interface oracle;
    uint256 scaleFactor;
    uint256 maxChainlinkOracleTimeDelay;
  }

  /// @notice Roles
  // Role to set the hardcoded price of an fToken with a stableocoin underlying
  bytes32 public constant STABLECOIN_HARDCODE_SETTER_ROLE =
    keccak256("STABLECOIN_HARDCODE_SETTER_ROLE");
  // Role to set which IRWAPricer to use for an fToken with an RWA underlying
  bytes32 public constant TOKENIZED_RWA_SETTER_ROLE =
    keccak256("TOKENIZED_RWA_SETTER_ROLE");
  // Role to set the Chainlink price feed for an fToken
  bytes32 public constant CHAINLINK_ORACLE_SETTER_ROLE =
    keccak256("CHAINLINK_ORACLE_SETTER_ROLE");

  /**
   * @notice Consturctor
   *
   * @param admin Admin address
   */
  constructor(address admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(STABLECOIN_HARDCODE_SETTER_ROLE, admin);
    _grantRole(TOKENIZED_RWA_SETTER_ROLE, admin);
    _grantRole(CHAINLINK_ORACLE_SETTER_ROLE, admin);
  }

  /**
   * @notice Retrieve the price of the provided fToken
   *         contract's underlying asset
   *
   * @param fToken fToken contract address
   *
   * @dev This function attempts to retrieve the price based on the associated
   *      `OracleType`. This can mean retrieving from, a Chainlink Oracle, an
   *      RWA Pricer, or even a price set manually within contract
   *      storage.
   * @dev Only supports oracle prices denominated in USD in
   *      `36 - underlyingDecimals` decimals
   * @dev Can return 0 prices, it is up to the caller to handle this
   */
  function getUnderlyingPrice(
    address fToken
  ) external view override returns (uint256 price) {
    // Get price of fToken depending on OracleType
    OracleType oracleType = fTokenToOracleType[fToken];
    if (oracleType == OracleType.HARDCODED) {
      // Get price stored in contract storage
      price = fTokenToHardcodedPrice[fToken];
    } else if (oracleType == OracleType.TOKENIZED_RWA) {
      // Get price from RWA Pricer
      price = _getTokenizedRWAPrice(fToken);
    } else if (oracleType == OracleType.CHAINLINK) {
      // Get price from Chainlink oracle
      price = _getChainlinkOraclePrice(fToken);
    } else {
      revert FTokenNotSupported();
    }

    if (price == 0) {
      revert ZeroPrice();
    }

    return price;
  }

  /*//////////////////////////////////////////////////////////////
                         Oracle Type Setter
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the oracle type for the provided fToken
   *
   * @param fToken     fToken contract address
   * @param oracleType Oracle Type of fToken
   */
  function setFTokenToOracleType(
    address fToken,
    OracleType oracleType
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(ICTokenLike(fToken).isCToken());

    // Clear out previous fToken data
    OracleType oldOracleType = fTokenToOracleType[fToken];
    if (oldOracleType == OracleType.HARDCODED) {
      delete fTokenToHardcodedPrice[fToken];
    } else if (oldOracleType == OracleType.TOKENIZED_RWA) {
      delete fTokenToRWAOracle[fToken];
    } else if (oldOracleType == OracleType.CHAINLINK) {
      delete fTokenToChainlinkOracle[fToken];
    }

    fTokenToOracleType[fToken] = oracleType;
    emit FTokenToOracleTypeSet(fToken, oracleType);
  }

  /*//////////////////////////////////////////////////////////////
                        Hardcoded Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the price of an fToken contract's underlying asset
   *
   * @param fToken fToken contract address
   * @param price  New price of underlying asset
   */
  function setHardcodedPrice(
    address fToken,
    uint256 price
  ) external override onlyRole(STABLECOIN_HARDCODE_SETTER_ROLE) {
    if (fTokenToOracleType[fToken] != OracleType.HARDCODED) {
      revert InvalidOracleType(
        OracleType.HARDCODED,
        fTokenToOracleType[fToken]
      );
    }
    if (price == 0) {
      revert ZeroPrice();
    }
    uint256 oldPrice = fTokenToHardcodedPrice[fToken];
    fTokenToHardcodedPrice[fToken] = price;
    emit HardcodedPriceSet(fToken, oldPrice, price);
  }

  /*//////////////////////////////////////////////////////////////
                      Tokenized RWA Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Associates a custom fToken with an external cToken
   *
   * @param fToken    fToken contract address
   * @param rwaOracle Oracle for the fToken's underlying tokenized RWA
   */
  function setFTokenToRWAOracle(
    address fToken,
    address rwaOracle
  ) external override onlyRole(TOKENIZED_RWA_SETTER_ROLE) {
    if (fTokenToOracleType[fToken] != OracleType.TOKENIZED_RWA) {
      revert InvalidOracleType(
        OracleType.TOKENIZED_RWA,
        fTokenToOracleType[fToken]
      );
    }
    // Check that function is implemented and returns a valid price
    (uint256 price, ) = IRWAOracle(rwaOracle).getPriceData();
    if (price == 0) {
      revert InvalidRWAOracle();
    }

    address oldRwaOracle = fTokenToRWAOracle[fToken];
    fTokenToRWAOracle[fToken] = rwaOracle;
    emit FTokenToRWAOracleSet(fToken, oldRwaOracle, rwaOracle);
  }

  /**
   * @notice Gets the price of the fToken's underlying tokenized RWA
   *
   * @param fToken fToken contract address
   *
   * @dev This function will revert if the fToken is not of TOKENIZED_RWA type
   */
  function _getTokenizedRWAPrice(
    address fToken
  ) private view returns (uint256 price) {
    IRWAOracle rwaOracle = IRWAOracle(fTokenToRWAOracle[fToken]);
    (price, ) = rwaOracle.getPriceData();
  }

  /*//////////////////////////////////////////////////////////////
                          Chainlink Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Associates a custom fToken with a Chainlink oracle
   *
   * @param fToken                      fToken contract address
   * @param newChainlinkOracle          Chainlink oracle address
   * @param maxChainlinkOracleTimeDelay Max time delay in seconds for chainlink oracle
   *
   */
  function setFTokenToChainlinkOracle(
    address fToken,
    address newChainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) external override onlyRole(CHAINLINK_ORACLE_SETTER_ROLE) {
    address oldChainlinkOracle = address(
      fTokenToChainlinkOracle[fToken].oracle
    );
    _setFTokenToChainlinkOracle(
      fToken,
      newChainlinkOracle,
      maxChainlinkOracleTimeDelay
    );
    emit ChainlinkOracleSet(
      fToken,
      oldChainlinkOracle,
      newChainlinkOracle,
      maxChainlinkOracleTimeDelay
    );
  }

  /**
   * @notice Internal implementation function for setting fToken to
   *         chainlinkOracle implementation
   *
   * @param fToken                      fToken contract address
   * @param chainlinkOracle             Chainlink oracle address
   * @param maxChainlinkOracleTimeDelay Max time delay in seconds for chainlink oracle
   *
   */
  function _setFTokenToChainlinkOracle(
    address fToken,
    address chainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) private {
    if (fTokenToOracleType[fToken] != OracleType.CHAINLINK) {
      revert InvalidOracleType(
        OracleType.CHAINLINK,
        fTokenToOracleType[fToken]
      );
    }
    address underlying = ICTokenLike(fToken).underlying();
    fTokenToChainlinkOracle[fToken].scaleFactor = (10 **
      (36 -
        uint256(IERC20Like(underlying).decimals()) -
        uint256(AggregatorV3Interface(chainlinkOracle).decimals())));
    fTokenToChainlinkOracle[fToken].oracle = AggregatorV3Interface(
      chainlinkOracle
    );
    fTokenToChainlinkOracle[fToken]
      .maxChainlinkOracleTimeDelay = maxChainlinkOracleTimeDelay;
  }

  /**
   * @notice Retrieve price of fToken's underlying asset from a Chainlink
   *         oracle
   *
   * @param fToken fToken contract address
   *
   * @dev This function will revert if the fToken is not of CHAINLINK type
   */
  function _getChainlinkOraclePrice(
    address fToken
  ) private view returns (uint256 price) {
    ChainlinkOracleInfo storage chainlinkInfo = fTokenToChainlinkOracle[fToken];
    (
      uint80 roundId,
      int answer,
      ,
      uint updatedAt,
      uint80 answeredInRound
    ) = chainlinkInfo.oracle.latestRoundData();
    if (
      answer < 0 ||
      roundId < answeredInRound ||
      roundId == 0 ||
      updatedAt == 0 ||
      updatedAt > block.timestamp
    ) {
      revert CorruptedChainlinkResponse();
    }

    if (
      updatedAt < block.timestamp - chainlinkInfo.maxChainlinkOracleTimeDelay
    ) {
      revert ChainlinkOraclePriceStale();
    }

    // Scale to decimals needed in Comptroller (18 decimal underlying -> 18 decimals; 6 decimal underlying -> 30 decimals)
    // Scales by same conversion factor as in Compound Oracle
    price = uint256(answer) * chainlinkInfo.scaleFactor;
  }

  /*//////////////////////////////////////////////////////////////
                          Events & Errors
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Event for when a fToken to chainlink oracle association is set
   *
   * @param fToken     fToken address
   * @param oracleType New oracle association
   */
  event FTokenToOracleTypeSet(address indexed fToken, OracleType oracleType);

  /**
   * @dev Event for when a fToken's underlying asset's hardcoded price is set
   *
   * @param fToken   fToken address
   * @param oldPrice Underlying asset's old hardcoded price
   * @param newPrice Underlying asset's new hardcoded price
   */
  event HardcodedPriceSet(
    address indexed fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @dev Event for when a fToken is associated with an Tokenized RWA Oracle
   *
   * @param fToken       fToken address
   * @param oldRWAOracle Old RWA Oracle
   * @param newRWAOracle New RWA Oracle
   */
  event FTokenToRWAOracleSet(
    address indexed fToken,
    address oldRWAOracle,
    address newRWAOracle
  );

  /**
   * @dev Event for when chainlink Oracle is set
   *
   * @param fToken                      fToken address
   * @param oldOracle                   The old chainlink oracle
   * @param newOracle                   The new chainlink oracle
   * @param maxChainlinkOracleTimeDelay The max time delay for the chainlink oracle
   */
  event ChainlinkOracleSet(
    address indexed fToken,
    address oldOracle,
    address newOracle,
    uint256 maxChainlinkOracleTimeDelay
  );

  // Errors
  error FTokenNotSupported();
  error InvalidOracleType(
    OracleType expectedOracleType,
    OracleType actualOracleType
  );
  error InvalidRWAOracle();
  error ZeroPrice();
  error CorruptedChainlinkResponse();
  error ChainlinkOraclePriceStale();
}