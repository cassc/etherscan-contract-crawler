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

import "contracts/rwaOracles/IRWAOracle.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/external/openzeppelin/contracts/security/Pausable.sol";

contract RWADynamicOracle is IRWAOracle, AccessControlEnumerable, Pausable {
  uint256 public constant DAY = 1 days;

  Range[] public ranges;

  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor(
    address admin,
    address setter,
    address pauser,
    uint256 firstRangeStart,
    uint256 firstRangeEnd,
    uint256 dailyIR,
    uint256 startPrice
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(PAUSER_ROLE, pauser);
    _grantRole(SETTER_ROLE, setter);

    if (firstRangeStart >= firstRangeEnd) revert InvalidRange();
    if (firstRangeStart > block.timestamp) revert InvalidRangeStart();

    uint256 trueStart = (startPrice * ONE) / dailyIR;
    ranges.push(Range(firstRangeStart, firstRangeEnd, dailyIR, trueStart));
  }

  /*//////////////////////////////////////////////////////////////
                         Public Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function which returns the daily price of USDY given the range previously set
   *
   * @return price      The current price of USDY, in 18 decimals
   * @return timestamp  The current timestamp of the call
   */
  function getPriceData()
    external
    view
    returns (uint256 price, uint256 timestamp)
  {
    price = getPrice();
    timestamp = block.timestamp;
  }

  /**
   * @notice Function which returns the daily price of USDY given the range previously set
   *
   * @return price The current price of USDY, in 18 decimals
   *
   * @dev The Ranges are not intended to be set more than 2 ranges in advance
   *      from the current range
   */
  function getPrice() public view whenNotPaused returns (uint256 price) {
    uint256 length = ranges.length;
    for (uint256 i = length; i > 0; --i) {
      Range storage range = ranges[i - 1];
      if (range.start <= block.timestamp) {
        if (range.end <= block.timestamp) {
          return derivePrice(range, range.end - 1);
        } else {
          return derivePrice(range, block.timestamp);
        }
      }
    }
  }

  /**
   * @notice External view function which will return the price of
   *         USDY at a given point in time.
   *
   * @param timestamp The unix timestamp at which you would like
   *                  the price for
   * @dev Notice that when no historical price exists this function
   *      will return `0`
   */
  function getPriceHistorical(
    uint256 timestamp
  ) external view returns (uint256 price) {
    uint256 length = ranges.length;
    for (uint256 i = length; i > 0; --i) {
      Range storage range = ranges[i - 1];
      if (range.start <= timestamp) {
        if (range.end <= timestamp) {
          return derivePrice(range, range.end - 1);
        } else {
          return derivePrice(range, timestamp);
        }
      }
    }
  }

  /**
   * @notice External helper function used to simulate the derivation of the prices returned
   *         from the oracle, given a range and a timestamp
   *
   * @dev If you are simulating the first range, you MUST set `startTime` and `rangeStartPrice`
   * @dev If you are simulating a range > 1st then `startTime` and `rangeStartPrice` values
   *      remain unused.
   *
   * @param blockTimeStamp  The unixTimestamp of the point in time you wish to simulate
   * @param dailyIR         The daily Interest Rate for the range to simulate
   * @param endTime         The end time for the range to simulate
   * @param startTime       The start time for the range to simulate
   * @param rangeStartPrice The start price for the range to simulate
   *
   */
  function simulateRange(
    uint256 blockTimeStamp,
    uint256 dailyIR,
    uint256 endTime,
    uint256 startTime,
    uint256 rangeStartPrice
  ) external view returns (uint256 price) {
    uint256 length = ranges.length;
    Range[] memory rangeList = new Range[](length + 1);
    for (uint256 i = 0; i < length; ++i) {
      rangeList[i] = ranges[i];
    }
    if (startTime == ranges[0].start) {
      uint256 trueStart = (rangeStartPrice * ONE) / dailyIR;
      rangeList[length] = Range(startTime, endTime, dailyIR, trueStart);
    } else {
      Range memory lastRange = ranges[ranges.length - 1];
      uint256 prevClosePrice = derivePrice(lastRange, lastRange.end - 1);
      rangeList[length] = Range(
        lastRange.end,
        endTime,
        dailyIR,
        prevClosePrice
      );
    }
    for (uint256 i = 0; i < length + 1; ++i) {
      Range memory range = rangeList[(length) - i];
      if (range.start <= blockTimeStamp) {
        if (range.end <= blockTimeStamp) {
          return derivePrice(range, range.end - 1);
        } else {
          return derivePrice(range, blockTimeStamp);
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                        Admin Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function that allows for an admin to set a given price range for USDY
   *
   * @param endTimestamp        The timestamp for the range to end
   * @param dailyInterestRate   The daily interest rate during said range
   */
  function setRange(
    uint256 endTimestamp,
    uint256 dailyInterestRate
  ) external onlyRole(SETTER_ROLE) {
    // Assert that dailyInterestRate is >= 1
    if (dailyInterestRate < ONE) revert InvalidInterestRate();

    Range memory lastRange = ranges[ranges.length - 1];

    // Check that the endTimestamp is greater than the last range's end time
    if (lastRange.end >= endTimestamp) revert InvalidRange();

    // Assert that the range is in whole units of days
    if ((endTimestamp - lastRange.end) % 1 days != 0) revert InvalidRange();

    uint256 prevClosePrice = derivePrice(lastRange, lastRange.end - 1);
    ranges.push(
      Range(lastRange.end, endTimestamp, dailyInterestRate, prevClosePrice)
    );
    emit RangeSet(
      ranges.length - 1,
      lastRange.end,
      endTimestamp,
      dailyInterestRate,
      prevClosePrice
    );
  }

  /**
   * @notice Function that allows for an admin to override a previously set range
   *
   * @param indexToModify           The index of the range that we want to change
   * @param newStart                The new start time for the updated range
   * @param newEnd                  The new end time for the updated range
   * @param newDailyIR              The new daily interest rate for the range to update
   * @param newPrevRangeClosePrice  The previous ranges close price
   *
   * @dev This function enforces that the range being overriden does not
   *      overlap with any other set ranges
   * @dev If closed ranges are updated, the result is a stale value for `prevRangeClosePrice`
   */
  function overrideRange(
    uint256 indexToModify,
    uint256 newStart,
    uint256 newEnd,
    uint256 newDailyIR,
    uint256 newPrevRangeClosePrice
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Check that the ranges start and end time are less than each other
    if (newStart >= newEnd) revert InvalidRange();

    uint256 rangeLength = ranges.length;
    // Case 1: The range being modified is the first range
    if (indexToModify == 0) {
      // If the length of ranges is greater than 1,
      // Ensure that the newEnd time is not greater than the start time of the next range
      if (rangeLength > 1 && newEnd > ranges[indexToModify + 1].start)
        revert InvalidRange();
    }
    // Case 2: The range being modified is the last range
    else if (indexToModify == rangeLength - 1) {
      // Ensure that the newStart time is not less than the end time of the previous range
      if (newStart < ranges[indexToModify - 1].end) revert InvalidRange();
    }
    // Case 3: The range being modified is between first and last range
    else {
      // Ensure that the newStart time is not less than the end time of the previous range
      if (newStart < ranges[indexToModify - 1].end) revert InvalidRange();
      // Ensure that the newEnd time is not greater than the start time of the next range
      if (newEnd > ranges[indexToModify + 1].start) revert InvalidRange();
    }

    // Update range
    if (indexToModify == 0) {
      uint256 trueStart = (newPrevRangeClosePrice * ONE) / newDailyIR;
      ranges[indexToModify] = Range(newStart, newEnd, newDailyIR, trueStart);
    } else {
      ranges[indexToModify] = Range(
        newStart,
        newEnd,
        newDailyIR,
        newPrevRangeClosePrice
      );
    }
    emit RangeOverriden(
      indexToModify,
      newStart,
      newEnd,
      newDailyIR,
      newPrevRangeClosePrice
    );
  }

  /**
   * @notice Function to pause the oracle
   */
  function pauseOracle() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Function to unpause the oracle
   */
  function unpauseOracle() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /*//////////////////////////////////////////////////////////////
                        Internal Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Internal helper function used to derive the price of USDY
   *
   * @param currentRange The current range to derive the price of USDY from
   * @param currentTime  The current unixTimestamp of the blockchain
   */
  function derivePrice(
    Range memory currentRange,
    uint256 currentTime
  ) internal pure returns (uint256 price) {
    uint256 elapsedDays = (currentTime - currentRange.start) / DAY;
    return
      roundUpTo8(
        _rmul(
          _rpow(currentRange.dailyInterestRate, elapsedDays + 1, ONE),
          currentRange.prevRangeClosePrice
        )
      );
  }

  /**
   * @notice internal function that will round derived price to the 8th decimal
   *         and will round 5 up
   *
   * @param value The value to round
   */
  function roundUpTo8(uint256 value) internal pure returns (uint256) {
    uint256 remainder = value % 1e10;
    if (remainder >= 0.5e10) {
      value += 1e10;
    }
    value -= remainder;
    return value;
  }

  /*//////////////////////////////////////////////////////////////
                    Structs, Events and Errors
  //////////////////////////////////////////////////////////////*/

  struct Range {
    uint256 start;
    uint256 end;
    uint256 dailyInterestRate;
    uint256 prevRangeClosePrice;
  }

  /**
   * @notice Event emitted when a range has been set
   *
   * @param start             The start time for the range
   * @param end               The end time for the range
   * @param dailyInterestRate The daily interest rate for the range
   */
  event RangeSet(
    uint256 indexed index,
    uint256 start,
    uint256 end,
    uint256 dailyInterestRate,
    uint256 prevRangeClosePrice
  );

  /**
   * @notice Event emitted when a previously set range is overriden
   *
   * @param index                  The index of the range being modified
   * @param newStart               The new start time for the modified range
   * @param newEnd                 The new end time for the modified range
   * @param newDailyInterestRate   The new dailyInterestRate for the modified range
   * @param newPrevRangeClosePrice The new prevRangeClosePrice for the modified range
   */
  event RangeOverriden(
    uint256 indexed index,
    uint256 newStart,
    uint256 newEnd,
    uint256 newDailyInterestRate,
    uint256 newPrevRangeClosePrice
  );

  error InvalidRangeStart();
  error InvalidRange();
  error InvalidInterestRate();

  /*//////////////////////////////////////////////////////////////
                Interest calculation helper functions
  //////////////////////////////////////////////////////////////*/

  // Copied from https://github.com/makerdao/dss/blob/master/src/jug.sol
  uint256 private constant ONE = 10 ** 27;

  function _rpow(
    uint256 x,
    uint256 n,
    uint256 base
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          z := base
        }
        default {
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          z := base
        }
        default {
          z := x
        }
        let half := div(base, 2) // for rounding.
        for {
          n := div(n, 2)
        } n {
          n := div(n, 2)
        } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) {
            revert(0, 0)
          }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) {
            revert(0, 0)
          }
          x := div(xxRound, base)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
              revert(0, 0)
            }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) {
              revert(0, 0)
            }
            z := div(zxRound, base)
          }
        }
      }
    }
  }

  function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = _mul(x, y) / ONE;
  }

  function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x);
  }
}