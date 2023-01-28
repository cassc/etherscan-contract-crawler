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

import "./IOndoPriceOracleV2.sol";
import "contracts/cash/external/openzeppelin/contracts/access/Ownable.sol";
import "contracts/lending/chainlink/AggregatorV3Interface.sol";

/// @notice Interface for generalizing different cToken oracles
interface CTokenOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

/// @notice Helper interface for standardizing comnmon calls to
///         fTokens and cTokens
interface CTokenLike {
  function underlying() external view returns (address);
}

/// @notice Helper interface for interacting with underlying assets
///         that are ERC20 compliant
interface IERC20Like {
  function decimals() external view returns (uint8);
}

/**
 * @title OndoPriceOracleV2
 * @author Ondo Finance
 * @notice This contract acts as a custom price oracle for the Flux lending
 *         market protocol. It allows for the owner to set the underlying price
 *         directly in contract storage, to set an fToken-to-cToken
 *         association for price retrieval using Compound's oracle, and
 *         to set an association between an fToken and a Chainlink
 *         oracle for price retrieval. It also allows the owner to
 *         set a price ceiling (a.k.a "cap") on an fToken's underlying asset.
 */
contract OndoPriceOracleV2 is IOndoPriceOracleV2, Ownable {
  /// @notice Initially set to contracts/lending/compound/uniswap/UniswapAnchoredView.sol
  CTokenOracle public cTokenOracle =
    CTokenOracle(0x50ce56A3239671Ab62f185704Caedf626352741e);

  /// @notice fToken to Oracle Type association
  mapping(address => OracleType) public fTokenToOracleType;

  /// @notice Contract storage for fToken's underlying asset prices
  mapping(address => uint256) public fTokenToUnderlyingPrice;

  /// @notice fToken to cToken associations for piggy backing off
  ///         of Compound's Oracle
  mapping(address => address) public fTokenToCToken;

  struct ChainlinkOracleInfo {
    AggregatorV3Interface oracle;
    uint256 scaleFactor;
    uint256 maxChainlinkOracleTimeDelay;
  }

  /// @notice fToken to Chainlink oracle association
  mapping(address => ChainlinkOracleInfo) public fTokenToChainlinkOracle;

  /// @notice Price cap for the underlying asset of an fToken. Optional.
  mapping(address => uint256) public fTokenToUnderlyingPriceCap;

  /**
   * @notice Retrieve the price of the provided fToken
   *         contract's underlying asset
   *
   * @param fToken fToken contract address
   *
   * @dev This function attempts to retrieve the price based on the associated
   *      `OracleType`. This can mean retrieving from Compound's oracle, a
   *      Chainlink oracle, or even a price set manually within contract
   *      storage. It will cap the price if a price cap is set in
   *      `fTokenToUnderlyingPriceCap`.
   * @dev Only supports oracle prices denominated in USD
   */
  function getUnderlyingPrice(
    address fToken
  ) external view override returns (uint256) {
    uint256 price;

    // Get price of fToken depending on OracleType
    OracleType oracleType = fTokenToOracleType[fToken];
    if (oracleType == OracleType.MANUAL) {
      // Get price stored in contract storage
      price = fTokenToUnderlyingPrice[fToken];
    } else if (oracleType == OracleType.COMPOUND) {
      // Get associated cToken and call Compound oracle
      address cTokenAddress = fTokenToCToken[fToken];
      price = cTokenOracle.getUnderlyingPrice(cTokenAddress);
    } else if (oracleType == OracleType.CHAINLINK) {
      // Get price from Chainlink oracle
      price = getChainlinkOraclePrice(fToken);
    } else {
      revert("Oracle type not supported");
    }

    // If price cap is set, take the min.
    if (fTokenToUnderlyingPriceCap[fToken] > 0) {
      price = _min(price, fTokenToUnderlyingPriceCap[fToken]);
    }

    return price;
  }

  /*//////////////////////////////////////////////////////////////
                   Price Cap & Oracle Type Setter
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the price cap for the provided fToken's underlying asset
   *
   * @param fToken fToken contract address
   */
  function setPriceCap(
    address fToken,
    uint256 value
  ) external override onlyOwner {
    uint256 oldPriceCap = fTokenToUnderlyingPriceCap[fToken];
    fTokenToUnderlyingPriceCap[fToken] = value;
    emit PriceCapSet(fToken, oldPriceCap, value);
  }

  /**
   * @notice Sets the oracle type for the provided fToken
   *
   * @param fToken     fToken contract address
   * @param oracleType Oracle Type of fToken
   */
  function setFTokenToOracleType(
    address fToken,
    OracleType oracleType
  ) external override onlyOwner {
    fTokenToOracleType[fToken] = oracleType;
    emit FTokenToOracleTypeSet(fToken, oracleType);
  }

  /*//////////////////////////////////////////////////////////////
                            Manual Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the price of an fToken contract's underlying asset
   *
   * @param fToken fToken contract address
   * @param price  New price of underlying asset
   */
  function setPrice(address fToken, uint256 price) external override onlyOwner {
    require(
      fTokenToOracleType[fToken] == OracleType.MANUAL,
      "OracleType must be Manual"
    );
    uint256 oldPrice = fTokenToUnderlyingPrice[fToken];
    fTokenToUnderlyingPrice[fToken] = price;
    emit UnderlyingPriceSet(fToken, oldPrice, price);
  }

  /*//////////////////////////////////////////////////////////////
                          Compound Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the external oracle address for Compound oracleType
   *
   * @param newOracle cToken oracle contract address
   */
  function setOracle(address newOracle) external override onlyOwner {
    address oldOracle = address(cTokenOracle);
    cTokenOracle = CTokenOracle(newOracle);
    emit CTokenOracleSet(oldOracle, newOracle);
  }

  /**
   * @notice Associates a custom fToken with an external cToken
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function setFTokenToCToken(
    address fToken,
    address cToken
  ) external override onlyOwner {
    address oldCToken = fTokenToCToken[fToken];
    _setFTokenToCToken(fToken, cToken);
    emit FTokenToCTokenSet(fToken, oldCToken, cToken);
  }

  /**
   * @notice Private implementation function for setting fToken
   *         to cToken implementation
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function _setFTokenToCToken(address fToken, address cToken) internal {
    require(
      fTokenToOracleType[fToken] == OracleType.COMPOUND,
      "OracleType must be Compound"
    );
    require(
      CTokenLike(fToken).underlying() == CTokenLike(cToken).underlying(),
      "cToken and fToken must have the same underlying asset"
    );
    fTokenToCToken[fToken] = cToken;
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
  ) external override onlyOwner {
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
  ) internal {
    require(
      fTokenToOracleType[fToken] == OracleType.CHAINLINK,
      "OracleType must be Chainlink"
    );
    address underlying = CTokenLike(fToken).underlying();
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
   * @dev This function is public for observability purposes only.
   */
  function getChainlinkOraclePrice(
    address fToken
  ) public view returns (uint256) {
    require(
      fTokenToOracleType[fToken] == OracleType.CHAINLINK,
      "fToken is not configured for Chainlink oracle"
    );
    ChainlinkOracleInfo storage chainlinkInfo = fTokenToChainlinkOracle[fToken];
    (
      uint80 roundId,
      int answer,
      ,
      uint updatedAt,
      uint80 answeredInRound
    ) = chainlinkInfo.oracle.latestRoundData();
    require(
      (answeredInRound >= roundId) &&
        (updatedAt >=
          block.timestamp - chainlinkInfo.maxChainlinkOracleTimeDelay),
      "Chainlink oracle price is stale"
    );
    require(answer >= 0, "Price cannot be negative");
    // Scale to decimals needed in Comptroller (18 decimal underlying -> 18 decimals; 6 decimal underlying -> 30 decimals)
    // Scales by same conversion factor as in Compound Oracle
    return uint256(answer) * chainlinkInfo.scaleFactor;
  }

  /*//////////////////////////////////////////////////////////////
                                Utils
  //////////////////////////////////////////////////////////////*/

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}