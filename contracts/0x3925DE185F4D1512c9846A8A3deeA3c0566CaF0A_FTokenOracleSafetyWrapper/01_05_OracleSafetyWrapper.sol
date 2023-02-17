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

import "contracts/cash/external/openzeppelin/contracts/access/Ownable.sol";
import "contracts/cash/interfaces/IMulticall.sol";
import "./IOndoPriceOracleV2.sol";

/// @notice Helper interface for checking fTokens.
interface CTokenInterface {
  function isCToken() external returns (bool);
}

/**
 * @title FTokenOracleSafetyWrapper
 * @author Ondo Finance
 * @notice This contract is a safety wrapper to prevent errors in when
 *         inputting fToken underlying price into a price oracle.
 *         This contract enforces that the price doesn't change more than
 *         `priceDeltaTolerances[fToken]` in a single transaction.
 *
 * @dev Usage could be the following batched transactions:
 *      1. `ondoPriceOracle.transferOwnership(<this contract>)
 *      2. FTokenOracleSafetyWrapper(<this contract>).setPriceSafe(<new price>)
 *      3. FTokenOracleSafetyWrapper(<this contract>).relinquishOracleOwnershipToOwner()
 */
contract FTokenOracleSafetyWrapper is Ownable, IMulticall {
  // Price oracle being wrapped
  IOndoPriceOracleV2 public constant ondoPriceOracle =
    IOndoPriceOracleV2(0xBa9B10f90B0ef26711373A0D8B6e7741866a7ef2);

  // Helper constant for basis point calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // Storage for fToken -> last price delta tolerance in bps
  mapping(address => uint256) public priceDeltaTolerances;

  /**
   * @notice Event emitted when price delta tolerance is set
   *
   * @param oldTolerance Old price tolerance
   * @param newTolerance New price tolerance
   */
  event DeltaPriceToleranceSet(uint256 oldTolerance, uint256 newTolerance);

  /**
   * @notice Event emitted when price safety check passess
   *
   * @param fToken   fToken whose underlying price was set
   * @param oldPrice Old price
   * @param newPrice New price
   */
  event PriceSafetyCheckPassed(
    address fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @notice Sets the delta tolerance that constrains price changes
   *         within a single function call.
   *
   * @param fToken       fToken address, whose underlying asset we set the
   *                     delta tolerance for
   * @param toleranceBPS Delta tolerance in BPS
   */
  function setDeltaPriceTolerances(
    address fToken,
    uint256 toleranceBPS
  ) external onlyOwner {
    require(CTokenInterface(fToken).isCToken(), "Incompatible fToken");
    require(toleranceBPS <= BPS_DENOMINATOR, "tolerance can not exceed 100%");
    uint256 oldTolerance = priceDeltaTolerances[fToken];
    priceDeltaTolerances[fToken] = toleranceBPS;
    emit DeltaPriceToleranceSet(oldTolerance, toleranceBPS);
  }

  /**
   * @notice Set an fToken's underlying price within `ondoPriceOracle`'s
   *         after performing safety checks.
   * @param fToken           fToken whose underlying's price is being set
   * @param price            New price for `fToken`'s underlying asset
   * @param ignoreDeltaCheck Whether or not to bypass the check if the
   *                         fToken's underlying asset price is set to 0
   *
   * @dev For the very first price setting of a specific fToken's underlying
   *      asset `ignoreDeltaCheck` should be set to true as to not compare
   *      against an uninitialized price.
   */
  function setPriceSafe(
    address fToken,
    uint256 price,
    bool ignoreDeltaCheck
  ) external onlyOwner {
    require(priceDeltaTolerances[fToken] > 0, "Delta tolerance not set");
    uint256 lastPrice = ondoPriceOracle.getUnderlyingPrice(fToken);
    uint256 priceDelta = _abs(price, lastPrice);
    if (!(lastPrice == 0 && ignoreDeltaCheck)) {
      uint256 maxToleratedPriceDelta = (lastPrice *
        priceDeltaTolerances[fToken]) / BPS_DENOMINATOR;
      require(
        priceDelta <= maxToleratedPriceDelta,
        "Price exceeds delta tolerance"
      );
    }
    ondoPriceOracle.setPrice(fToken, price);
    emit PriceSafetyCheckPassed(fToken, lastPrice, price);
  }

  /// @notice Set `ondoPriceOracle`'s owner to the owner of this contract.
  function relinquishOracleOwnershipToOwner() external onlyOwner {
    Ownable(address(ondoPriceOracle)).transferOwnership(owner());
  }

  /// @notice gets the absolute value of the difference between a and b
  function _abs(uint256 a, uint256 b) private pure returns (uint256 diff) {
    if (a > b) {
      diff = a - b;
    } else {
      diff = b - a;
    }
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  ) external payable override onlyOwner returns (bytes[] memory results) {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
  }
}