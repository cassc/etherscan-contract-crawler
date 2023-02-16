// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/IUpdateable.sol";
import "./math/FixedPoint.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library UpdateableLib {
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  function _average(
    IUpdateable.Updateable memory updateable,
    uint32 startBlock
  ) internal view returns (uint256 average) {
    uint32 cutoffBlock = uint256(block.number).toUint32();
    average = updateable.current;
    if (
      startBlock < updateable.lastUpdate && updateable.lastUpdate <= cutoffBlock
    ) {
      average =
        (updateable.current *
          (cutoffBlock - updateable.lastUpdate) +
          updateable.uptoLastUpdate *
          (updateable.lastUpdate - startBlock)) /
        (cutoffBlock - startBlock);
    }
  }

  function _updateByDelta(
    IUpdateable.Updateable memory position,
    int256 delta
  ) internal view returns (IUpdateable.Updateable memory) {
    uint256 _total = int256(position.current.add(delta)).toUint256();
    return _updateByTotal(position, _total);
  }

  function _updateByTotal(
    IUpdateable.Updateable memory position,
    uint256 _total
  ) internal view returns (IUpdateable.Updateable memory) {
    uint32 lastUpdate = position.lastUpdate;
    uint32 currentBlock = uint256(block.number).toUint32();

    if (lastUpdate == 0) {
      position.initialUpdate = currentBlock - 1;
      position.uptoLastUpdate = _total;
    } else {
      position.uptoLastUpdate =
        (position.current *
          (currentBlock - lastUpdate) +
          position.uptoLastUpdate *
          (lastUpdate - position.initialUpdate)) /
        (currentBlock - position.initialUpdate);
    }

    position.lastUpdate = currentBlock;
    position.current = _total;

    return position;
  }
}