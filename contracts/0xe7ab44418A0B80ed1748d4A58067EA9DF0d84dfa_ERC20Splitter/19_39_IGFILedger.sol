// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IGFILedger {
  struct Position {
    // Owner of the position
    address owner;
    // Index of the position in the ownership array
    uint256 ownedIndex;
    // Amount of GFI held in the position
    uint256 amount;
    // When the position was deposited
    uint256 depositTimestamp;
  }

  /**
   * @notice Emitted when a new GFI deposit has been made
   * @param owner address owning the deposit
   * @param positionId id for the deposit
   * @param amount how much GFI was deposited
   */
  event GFIDeposit(address indexed owner, uint256 indexed positionId, uint256 amount);

  /**
   * @notice Emitted when a new GFI withdrawal has been made. If the remaining amount is 0, the position has bee removed
   * @param owner address owning the withdrawn position
   * @param positionId id for the position
   * @param remainingAmount how much GFI is remaining in the position
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event GFIWithdrawal(
    address indexed owner,
    uint256 indexed positionId,
    uint256 withdrawnAmount,
    uint256 remainingAmount,
    uint256 depositTimestamp
  );

  /**
   * @notice Account for a new deposit by the owner.
   * @param owner address to account for the deposit
   * @param amount how much was deposited
   * @return how much was deposited
   */
  function deposit(address owner, uint256 amount) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @param amount how much to withdraw
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId, uint256 amount) external returns (uint256);

  /**
   * @notice Get the number of GFI positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

  /**
   * @notice Get the owner of a given position.
   * @param positionId id of the position
   * @return owner of the position
   */
  function ownerOf(uint256 positionId) external view returns (address);

  /**
   * @notice Total number of positions in the ledger
   * @return number of positions in the ledger
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns a position ID owned by `owner` at a given `index` of its position list
   * @param owner owner of the positions
   * @param index index of the owner's balance to get the position ID of
   * @return position id
   *
   * @dev use with {balanceOf} to enumerate all of `owner`'s positions
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a position ID at a given `index` of all the positions stored by the contract.
   * @param index index to get the position ID at
   * @return token id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get amount of GFI of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @return eligibleAmount GFI amount of positions eligible for rewards
   * @return totalAmount total GFI amount of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(address owner) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}