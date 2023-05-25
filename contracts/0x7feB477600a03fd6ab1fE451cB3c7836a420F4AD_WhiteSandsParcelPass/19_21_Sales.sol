// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Sales {
  struct PreSale {
    uint64 _start;
    uint64 _end;
  }

  function setDetails(
    PreSale storage sale,
    uint64 preSaleStart,
    uint64 preSaleLength
  ) internal {
    sale._start = preSaleStart;
    sale._end = preSaleStart + preSaleLength;
  }

  //  /// Returns the number of free passes claimed by a given wallet.
  //  function claimed(address addr) external view returns (uint256) {
  //    return LibAppStorage.appStorage().claimedByAddress[addr];
  //  }
  //
  //  /// Returns the number of free passes claimed by a given wallet.
  //  function presaleClaimed(address addr) external view returns (uint16, uint16) {
  //    LibAppStorage.Presale memory presale = LibAppStorage.appStorage().presaleByAddress[addr];
  //    return (presale.free, presale.paid);
  //  }
  //
  //  /// Returns the number of free passes claimed by the caller.
  //  function claimedByMe() external view returns (uint256) {
  //    return LibAppStorage.appStorage().claimedByAddress[msg.sender];
  //  }

  function getStartTime(PreSale memory sale) internal pure returns (uint64) {
    return sale._start;
  }

  function getEndTime(PreSale memory sale) internal pure returns (uint64) {
    return sale._end;
  }

  function setSaleDuration(PreSale storage sale, uint64 duration) internal {
    sale._end = sale._start + duration;
  }

  function reset(PreSale storage sale) internal {
    sale._start = 0;
    sale._end = 0;
  }

  function hasStarted(PreSale memory sale) internal view returns (bool) {
    return block.timestamp >= sale._start;
  }

  function hasFinished(PreSale memory sale) internal view returns (bool) {
    return block.timestamp > sale._end;
  }

  function isActive(PreSale memory sale) internal view returns (bool) {
    return hasStarted(sale) && !hasFinished(sale);
  }
}