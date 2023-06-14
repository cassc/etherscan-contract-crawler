/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./balancer-core/BPool.sol";
import "./interfaces/PowerIndexPoolInterface.sol";

contract PowerIndexPool is BPool {
  /// @notice The event emitted when a dynamic weight set to token
  event SetDynamicWeight(
    address indexed token,
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  );

  /// @notice The event emitted when weight per second bounds set
  event SetWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond);

  struct DynamicWeight {
    uint256 fromTimestamp;
    uint256 targetTimestamp;
    uint256 targetDenorm;
  }

  /// @dev Mapping for storing dynamic weights settings. fromDenorm stored in _records mapping as denorm variable
  mapping(address => DynamicWeight) private _dynamicWeights;

  /// @dev Min weight per second limit
  uint256 private _minWeightPerSecond;
  /// @dev Max weight per second limit
  uint256 private _maxWeightPerSecond;

  constructor(
    string memory name,
    string memory symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) public BPool(name, symbol) {
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;
  }

  /*** Controller Interface ***/

  /**
   * @notice Set weight per second bounds by controller
   * @param minWeightPerSecond Min weight per second
   * @param maxWeightPerSecond Max weight per second
   */
  function setWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond) public _logs_ _lock_ {
    _onlyController();
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;

    emit SetWeightPerSecondBounds(minWeightPerSecond, maxWeightPerSecond);
  }

  /**
   * @notice Set dynamic weight for token by controller
   * @param token Token for change settings
   * @param targetDenorm Target weight. fromDenorm will be fetch by current value of _getDenormWeight
   * @param fromTimestamp From timestamp of dynamic weight
   * @param targetTimestamp Target timestamp of dynamic weight
   */
  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) public _logs_ _lock_ {
    _onlyController();
    _requireTokenIsBound(token);

    require(fromTimestamp > block.timestamp, "CANT_SET_PAST_TIMESTAMP");
    require(targetTimestamp > fromTimestamp, "TIMESTAMP_INCORRECT_DELTA");
    require(targetDenorm >= MIN_WEIGHT && targetDenorm <= MAX_WEIGHT, "TARGET_WEIGHT_BOUNDS");

    uint256 fromDenorm = _getDenormWeight(token);
    uint256 weightPerSecond = _getWeightPerSecond(fromDenorm, targetDenorm, fromTimestamp, targetTimestamp);
    require(weightPerSecond <= _maxWeightPerSecond, "MAX_WEIGHT_PER_SECOND");
    require(weightPerSecond >= _minWeightPerSecond, "MIN_WEIGHT_PER_SECOND");

    _records[token].denorm = fromDenorm;

    _dynamicWeights[token] = DynamicWeight({
      fromTimestamp: fromTimestamp,
      targetTimestamp: targetTimestamp,
      targetDenorm: targetDenorm
    });

    uint256 denormSum = 0;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      denormSum = badd(denormSum, _dynamicWeights[_tokens[i]].targetDenorm);
    }

    require(denormSum <= MAX_TOTAL_WEIGHT, "MAX_TARGET_TOTAL_WEIGHT");

    emit SetDynamicWeight(token, fromDenorm, targetDenorm, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Bind and setDynamicWeight at the same time
   * @param token Token for bind
   * @param balance Initial balance
   * @param targetDenorm Target weight
   * @param fromTimestamp From timestamp of dynamic weight
   * @param targetTimestamp Target timestamp of dynamic weight
   */
  function bind(
    address token,
    uint256 balance,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  )
    external
    _logs_ // _lock_  Bind does not lock because it jumps to `rebind` and `setDynamicWeight`, which does
  {
    super.bind(token, balance, MIN_WEIGHT);

    setDynamicWeight(token, targetDenorm, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Override parent unbind function
   * @param token Token for unbind
   */
  function unbind(address token) public override {
    super.unbind(token);

    _dynamicWeights[token] = DynamicWeight(0, 0, 0);
  }

  /**
   * @notice Override parent bind function and disable.
   */
  function bind(
    address,
    uint256,
    uint256
  ) public override {
    revert("DISABLED"); // Only new bind function is allowed
  }

  /**
   * @notice Override parent rebind function. Allowed only for calling from bind function
   * @param token Token for rebind
   * @param balance Balance for rebind
   * @param denorm Weight for rebind
   */
  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override {
    require(denorm == MIN_WEIGHT && _dynamicWeights[token].fromTimestamp == 0, "ONLY_NEW_TOKENS_ALLOWED");
    super.rebind(token, balance, denorm);
  }

  /*** View Functions ***/

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    )
  {
    DynamicWeight storage dw = _dynamicWeights[token];
    return (dw.fromTimestamp, dw.targetTimestamp, _records[token].denorm, dw.targetDenorm);
  }

  function getWeightPerSecondBounds() external view returns (uint256 minWeightPerSecond, uint256 maxWeightPerSecond) {
    return (_minWeightPerSecond, _maxWeightPerSecond);
  }

  /*** Internal Functions ***/

  function _getDenormWeight(address token) internal view override returns (uint256) {
    DynamicWeight memory dw = _dynamicWeights[token];
    uint256 fromDenorm = _records[token].denorm;

    if (dw.fromTimestamp == 0 || dw.targetDenorm == fromDenorm || block.timestamp <= dw.fromTimestamp) {
      return fromDenorm;
    }
    if (block.timestamp >= dw.targetTimestamp) {
      return dw.targetDenorm;
    }

    uint256 weightPerSecond = _getWeightPerSecond(fromDenorm, dw.targetDenorm, dw.fromTimestamp, dw.targetTimestamp);
    uint256 deltaCurrentTime = bsub(block.timestamp, dw.fromTimestamp);
    if (dw.targetDenorm > fromDenorm) {
      return badd(fromDenorm, deltaCurrentTime * weightPerSecond);
    } else {
      return bsub(fromDenorm, deltaCurrentTime * weightPerSecond);
    }
  }

  function _getWeightPerSecond(
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) internal pure returns (uint256) {
    uint256 delta = targetDenorm > fromDenorm ? bsub(targetDenorm, fromDenorm) : bsub(fromDenorm, targetDenorm);
    return div(delta, bsub(targetTimestamp, fromTimestamp));
  }

  function _getTotalWeight() internal view override returns (uint256) {
    uint256 sum = 0;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      sum = badd(sum, _getDenormWeight(_tokens[i]));
    }
    return sum;
  }

  function _addTotalWeight(uint256 _amount) internal virtual override {
    // storage total weight don't change, it's calculated only by _getTotalWeight()
  }

  function _subTotalWeight(uint256 _amount) internal virtual override {
    // storage total weight don't change, it's calculated only by _getTotalWeight()
  }
}