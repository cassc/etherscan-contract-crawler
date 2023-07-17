//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

error PreSaleHasNotStarted();
error PreSaleHasEnded();
error PublicSaleHasNotStarted();
error PublicSaleHasEnded();

contract SalesTimestamps is Ownable {
  uint256 public preSaleStartTimeInSeconds;
  uint256 public preSaleEndTimeInSeconds;
  uint256 public publicSaleStartTimeInSeconds;
  uint256 public publicSaleEndTimeInSeconds;

  function setPreSaleTime(
    uint256 _preSaleStartTimeInSeconds,
    uint256 _preSaleEndTimeInSeconds
  ) external onlyOwner {
    preSaleStartTimeInSeconds = _preSaleStartTimeInSeconds;
    preSaleEndTimeInSeconds = _preSaleEndTimeInSeconds;
  }

  function setPublicSaleTime(
    uint256 _publicSaleStartTimeInSeconds,
    uint256 _publicSaleEndTimeInSeconds
  ) external onlyOwner {
    publicSaleStartTimeInSeconds = _publicSaleStartTimeInSeconds;
    publicSaleEndTimeInSeconds = _publicSaleEndTimeInSeconds;
  }

  /**
   * @dev Throws if in invalid pre sale time.
   */
  modifier isInValidPreSalePeriod() {
    if (block.timestamp < preSaleStartTimeInSeconds)
      revert PreSaleHasNotStarted();
    if (block.timestamp > preSaleEndTimeInSeconds)
      revert PreSaleHasEnded();
    _;
  }
  /**
   * @dev Throws if in invalid public sale time.
   */
  modifier isInValidPublicSalePeriod() {
    if (block.timestamp < publicSaleStartTimeInSeconds)
      revert PublicSaleHasNotStarted();
    if (block.timestamp > publicSaleEndTimeInSeconds)
      revert PublicSaleHasEnded();
    _;
  }
}