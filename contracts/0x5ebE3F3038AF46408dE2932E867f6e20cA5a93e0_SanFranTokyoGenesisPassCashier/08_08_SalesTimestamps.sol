//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
error PhaseOneAllowlistMintHasNotStarted();
error PhaseTwoAllowlistMintHasNotStarted();
error PublicMintHasNotStarted();
error PhaseOneAllowlistMintHasEnded();
error PhaseTwoAllowlistMintHasEnded();
error PublicMintHasEnded();

contract SalesTimestamps is Ownable {
  uint256 public phaseOneAllowlistMintStartTimeInSeconds;
  uint256 public phaseTwoAllowlistMintStartTimeInSeconds;
  uint256 public publicMintStartTimeInSeconds;
  uint256 public phaseOneAllowlistMintEndTimeInSeconds;
  uint256 public phaseTwoAllowlistMintEndTimeInSeconds;
  uint256 public publicMintEndTimeInSeconds;

  function setPhaseOneAllowlistMintTime(
    uint256 _startTimeInSeconds,
    uint256 _endTimeInSeconds
  ) external onlyOwner {
    phaseOneAllowlistMintStartTimeInSeconds = _startTimeInSeconds;
    phaseOneAllowlistMintEndTimeInSeconds = _endTimeInSeconds;
  }

  function setPhaseTwoAllowlistMintTime(
    uint256 _startTimeInSeconds,
    uint256 _endTimeInSeconds
  ) external onlyOwner {
    phaseTwoAllowlistMintStartTimeInSeconds = _startTimeInSeconds;
    phaseTwoAllowlistMintEndTimeInSeconds = _endTimeInSeconds;
  }

  function setPublicMintTime(
    uint256 _startTimeInSeconds,
    uint256 _endTimeInSeconds
  ) external onlyOwner {
    publicMintStartTimeInSeconds = _startTimeInSeconds;
    publicMintEndTimeInSeconds = _endTimeInSeconds;
  }

  /**
   * @dev Throws if in invalid phase 1 allowlist time.
   */
  modifier requiresValidPhaseOneAllowlistMintTime() {
    if (block.timestamp < phaseOneAllowlistMintStartTimeInSeconds)
      revert PhaseOneAllowlistMintHasNotStarted();
    if (block.timestamp > phaseOneAllowlistMintEndTimeInSeconds)
      revert PhaseOneAllowlistMintHasEnded();
    _;
  }

  /**
   * @dev Throws if in invalid phase 2 allowlist time.
   */
  modifier requiresValidPhaseTwoAllowlistMintTime() {
    if (block.timestamp < phaseTwoAllowlistMintStartTimeInSeconds)
      revert PhaseTwoAllowlistMintHasNotStarted();
    if (block.timestamp > phaseTwoAllowlistMintEndTimeInSeconds)
      revert PhaseTwoAllowlistMintHasEnded();
    _;
  }

  /**
   * @dev Throws if in invalid public sale time.
   */
  modifier requiresValidPublicMintTime() {
    if (block.timestamp < publicMintStartTimeInSeconds)
      revert PublicMintHasNotStarted();
    if (block.timestamp > publicMintEndTimeInSeconds)
      revert PublicMintHasEnded();
    _;
  }
}