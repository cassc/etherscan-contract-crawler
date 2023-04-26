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
import "contracts/lending/chainlink/AggregatorV3Interface.sol";
import "contracts/lending/rwaOracles/IRWAOracleExternalComparisonCheck.sol";
import "contracts/cash/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract RWAOracleExternalComparisonCheck is
  IRWAOracleExternalComparisonCheck,
  AccessControlEnumerable
{
  /// @notice Helper struct for storing SHV data from Chainlink
  struct ChainlinkRoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }

  // Price of RWA token (OUSG, OSTB, OHYG, etc.)
  int256 public rwaPrice;

  // Timestamp in which the RWA token price was last set
  uint256 public priceTimestamp;

  // The associated Chainlink price update associated with the stored
  // `rwaPrice`
  ChainlinkRoundData public lastSetRound;

  // Chainlink oracle whose tracked instrument is used to constrain price updates.
  AggregatorV3Interface public immutable chainlinkOracle;

  // Description of oracle set in Constructor
  string public description;

  // How recent a Chainlink update needs to be in order to be associated to
  // a RWA price change.
  uint256 public constant MAX_CL_WINDOW = 25 hours;

  // Helper constant that allows us to specify basis points in calculations
  int256 public constant BPS_DENOMINATOR = 10_000;

  // Amount of bps that the RWA price can differ from the SHV change. For
  // example, if SHV changes by 1% in between RWA price updates,
  // RWA token can change between .26% and 1.74%
  uint256 public constant MAX_CHANGE_DIFF_BPS = 74;

  // Max amount of bps that RWA price in a single price update.
  uint256 public constant MAX_ABSOLUTE_DIFF_BPS = 200;

  // Minimum time between price updates
  uint256 public constant MIN_PRICE_UPDATE_WINDOW = 23 hours;

  /// @notice How many decimals `rwaPrice` is represented in
  /// @dev UNUSED AND UNENFORCED - This is present only for operational
  ///      clarity.
  uint256 public constant decimals = 18;

  // Role that can set RWA price
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

  /**
   * @notice constructor
   *
   * @param _initialPrice     The initial RWA price
   * @param _chainlinkOracle Chainlink oracle to compare differences with
   * @param _description     Human readable description
   * @param _admin           admin which holds the DEFAULT_ADMIN_ROLE
   * @param _setter          setter address which holds the role to set rwa price
   */
  constructor(
    int256 _initialPrice,
    address _chainlinkOracle,
    string memory _description,
    address _admin,
    address _setter
  ) {
    if (_admin == address(0) || _setter == address(0)) {
      revert InvalidAddress();
    }
    chainlinkOracle = AggregatorV3Interface(_chainlinkOracle);
    // Revert if Chainlink oracle is not reporting 8 decimals
    if (chainlinkOracle.decimals() != 8) {
      revert CorruptedChainlinkResponse();
    }

    ChainlinkRoundData memory round = _getLatestChainlinkRoundData();
    if (block.timestamp > round.updatedAt + MAX_CL_WINDOW) {
      revert ChainlinkOraclePriceStale();
    }

    description = _description;
    rwaPrice = _initialPrice;
    priceTimestamp = block.timestamp;
    lastSetRound = round;

    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(SETTER_ROLE, _setter);
  }

  /**
   * @notice Retrieve the last set RWA price data
   *
   * @dev `price` is in 18 decimals, `timestamp` is unix seconds since epoch
   */
  function getPriceData()
    external
    view
    override
    returns (uint256 price, uint256 timestamp)
  {
    price = uint256(rwaPrice);
    timestamp = priceTimestamp;
  }

  /**
   * @notice Sets the price of RWA if all the following criteria are met:
   *  - It is able to pull a consistent and recent Chainlink price that is
   *    different than the last used Chainlink round
   *  - The price wasn't updated too recently (`MIN_PRICE_UPDATE_WINDOW`
   *    seconds)
   *  - The change in RWA price is < MAX_ABSOLUTE_DIFF_BPS
   *  - The change in RWA price has not deviated `MAX_CHANGE_DIFF_BPS` more
   *    than the change in the Chainlink price.
   * If the change in Chainlink price is larger than `MAX_ABSOLUTE_DIFF_BPS +
   * MAX_CHANGE_DIFF_BPS` it is deemed malfunctioning and ignored.
   *
   * @param newPrice The new price of some RWA token (In `decimals` decimals)
   *
   * @dev The decimal representation is not enforced yet must be respected by
   *      the caller of this function and deployer of this contract
   */
  function setPrice(int256 newPrice) external override onlyRole(SETTER_ROLE) {
    // RWA price must be greater than zero
    if (newPrice <= 0) {
      revert InvalidRWAPrice();
    }

    ChainlinkRoundData memory round = _getLatestChainlinkRoundData();
    // Chainlink price update must be recent
    if (block.timestamp > round.updatedAt + MAX_CL_WINDOW) {
      revert ChainlinkOraclePriceStale();
    }

    // Chainlink price update must not be comparing the same rounds against
    // eachother
    if (round.roundId == lastSetRound.roundId) {
      revert ChainlinkRoundNotUpdated();
    }

    // Ensure at least `MIN_PRICE_UPDATE_WINDOW` seconds have passed since
    // last RWA price update
    if (block.timestamp < priceTimestamp + MIN_PRICE_UPDATE_WINDOW) {
      revert PriceUpdateWindowViolation();
    }

    int256 rwaPriceChangeBps = _getPriceChangeBps(rwaPrice, newPrice);
    // Never allow a price change that violates the max absolute change
    // threshold.
    if (_abs_unsigned(rwaPriceChangeBps) > MAX_ABSOLUTE_DIFF_BPS) {
      revert AbsoluteDifferenceConstraintViolated();
    }

    int256 chainlinkPriceChangeBps = _getPriceChangeBps(
      lastSetRound.answer,
      round.answer
    );

    if (
      _abs_unsigned(chainlinkPriceChangeBps) <=
      MAX_ABSOLUTE_DIFF_BPS + MAX_CHANGE_DIFF_BPS
    ) {
      // Chainlink price change is sane, so we compare rwa price changes
      // against the Chainlink price changes.
      uint256 changeDifferenceBps = _abs_unsigned(
        rwaPriceChangeBps - chainlinkPriceChangeBps
      );

      if (changeDifferenceBps > MAX_CHANGE_DIFF_BPS) {
        revert DeltaDifferenceConstraintViolation();
      }
    } else {
      emit ChainlinkPriceIgnored(
        lastSetRound.answer,
        lastSetRound.roundId,
        round.answer,
        round.roundId
      );
    }

    emit RWAExternalComparisonCheckPriceSet(
      lastSetRound.answer,
      lastSetRound.roundId,
      round.answer,
      round.roundId,
      rwaPrice,
      newPrice
    );

    rwaPrice = newPrice;
    priceTimestamp = block.timestamp;
    lastSetRound = round;
  }

  /**
   * @notice Retrieve latest Chainlink data
   *
   * @dev Reverts if any corruption is detected in Chainlink response
   */
  function _getLatestChainlinkRoundData()
    private
    view
    returns (ChainlinkRoundData memory round)
  {
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = chainlinkOracle.latestRoundData();
    if (
      answer < 0 ||
      roundId != answeredInRound ||
      roundId == 0 ||
      updatedAt == 0 ||
      updatedAt > block.timestamp
    ) {
      revert CorruptedChainlinkResponse();
    }
    round = ChainlinkRoundData(
      roundId,
      answer,
      startedAt,
      updatedAt,
      answeredInRound
    );
  }

  /**
   * @notice Compute the price change in basis point
   *
   * @param previousPrice Previous price
   * @param newPrice      New price
   *
   * @dev The price change can be negative.
   */
  function _getPriceChangeBps(
    int256 previousPrice,
    int256 newPrice
  ) private pure returns (int256 changeBps) {
    int256 change = newPrice - previousPrice;
    changeBps = (change * BPS_DENOMINATOR) / previousPrice;
  }

  /**
   * @notice returns the absolute value of the input.
   *
   * @param x the number to return absolute value of.
   */
  function _abs_unsigned(int256 x) private pure returns (uint256) {
    return x >= 0 ? uint256(x) : uint256(-x);
  }
}