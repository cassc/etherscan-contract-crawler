// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@             /@@@@@@@@@/             @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@         *@@@@@@@@@@@@@@@@@@@@@@@,         @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@#        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@       @@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@
@@@@@@@@@@@@@       @@&@@@((*,,,, *(((((((*((((((@@@@@@@@@@@@       @@@@@@@@@@@@
@@@@@@@@@@@@      @,@@@@#           .                 @@@@@@@@@      @@@@@@@@@@@
@@@@@@@@@@@      @@@@&&@                                @@@@@@@@      @@@@@@@@@@
@@@@@@@@@@      @@@@@@@@%          %%%%%%%%%%%%%%       @@@@@@@@@      @@@@@@@@@
@@@@@@@@@@     /@@@@@@@(@/       #/%@@@@@@@@@@@@@       @@@@@@@@@      @@@@@@@@@
@@@@@@@@@.     @@@@@@@@&@*   .   #@@@@@@@@@@@@@@@       @@@@@@@@@@     &@@@@@@@@
@@@@@@@@@      @@@@@@@@@@&       #@@@@@@@@@@@@@@@       @@@@@@@@@@      @@@@@@@@
@@@@@@@@@.     @@@@@@@@&@%   .   #@@                    @@@@@@@@@@     &@@@@@@@@
@@@@@@@@@@     *@@@@@%@@@@       #@&@#      .          @@@@@@@@@@      @@@@@@@@@
@@@@@@@@@@      @@@@@@@@@@       #@@@@@@           [email protected]@@@@@@@@@@@@      @@@@@@@@@
@@@@@@@@@@@      @@@@@@@@@      .#@@@@@@@@         @@@@@@@@@@@@@      @@@@@@@@@@
@@@@@@@@@@@@      @@@@@@@@       #@@@@@@@@@@         @@@@@@@@@%      @@@@@@@@@@@
@@@@@@@@@@@@@       @@@@@@       #@@@@@@@@@@@@         @@@@@@       @@@@@@@@@@@@
@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@              (@@@@@@@(              @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,               (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
pragma solidity 0.8.13;

import "../Gen0.sol";

contract Gen0Freezable is Gen0 {
  /**
    @dev tokenId to freezing start time (0 = not frozen).
    */
  mapping(uint256 => uint256) private freezingStarted;

  /**
    @dev If false then freezing is blocked
     */
  bool public freezingOpen;

  /**
    @dev Cumulative per-token freezing, excluding the current period.
     */
  mapping(uint256 => uint256) private freezingTimeCompleted;

  modifier onlyOwnerOrContractOwner(uint256 tokenId) {
    require(
      ownerOf(tokenId) == _msgSender() || _msgSender() == owner(),
      "only owner"
    );
    _;
  }

  /**
    @dev Toggles the `freezingOpen` flag on or off
     */
  function setFreezing(bool open) external onlyOwner {
    freezingOpen = open;
  }

  /** ==================== Freezing ==================== **/
  /**
    @notice Changes the NFTs frozen status
    @dev Takes a list of id's to be toggled
     */
  function toggleFreezing(uint256[] calldata tokenIds) external {
    uint256 n = tokenIds.length;
    for (uint256 i = 0; i < n; ++i) {
      _toggleFreezing(tokenIds[i]);
    }
  }

  /**
    @notice Changes the frozen status.
    */
  function _toggleFreezing(uint256 tokenId)
    internal
    onlyOwnerOrContractOwner(tokenId)
  {
    uint256 start = freezingStarted[tokenId];
    if (start == 0) {
      require(freezingOpen, "Freezing not allowed");
      freezingStarted[tokenId] = block.timestamp;
      emit Frozen(tokenId);
    } else {
      freezingTimeCompleted[tokenId] += block.timestamp - start;
      freezingStarted[tokenId] = 0;
      emit UnFrozen(tokenId);
    }
  }

  function cryostatus(uint256 tokenId)
    external
    view
    returns (
      bool isFrozen,
      uint256 current,
      uint256 total
    )
  {
    uint256 start = freezingStarted[tokenId];
    if (start != 0) {
      isFrozen = true;
      current = block.timestamp - start;
    }
    total = current + freezingTimeCompleted[tokenId];
  }

  /**
    @dev Block transfers while frozen.
     */
  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    uint256 tokenId = startTokenId;
    for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
      require(
        freezingStarted[tokenId] == 0 || _msgSender() == ownerOf(tokenId),
        "Frozen or !owner"
      );
    }
  }

  /**
    @dev Emitted when an nft begins freezing.
     */
  event Frozen(uint256 indexed tokenId);

  /**
    @dev Emitted when an nft in unfrozen
     */
  event UnFrozen(uint256 indexed tokenId);
}