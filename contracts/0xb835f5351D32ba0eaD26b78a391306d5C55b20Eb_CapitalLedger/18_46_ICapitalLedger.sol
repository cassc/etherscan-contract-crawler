// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

enum CapitalAssetType {
  INVALID,
  ERC721
}

interface ICapitalLedger {
  /**
   * @notice Emitted when a new capital erc721 deposit has been made
   * @param owner address owning the deposit
   * @param assetAddress address of the deposited ERC721
   * @param positionId id for the deposit
   * @param assetTokenId id of the token from the ERC721 `assetAddress`
   * @param usdcEquivalent usdc equivalent value at the time of deposit
   */
  event CapitalERC721Deposit(
    address indexed owner,
    address indexed assetAddress,
    uint256 positionId,
    uint256 assetTokenId,
    uint256 usdcEquivalent
  );

  /**
   * @notice Emitted when a new ERC721 capital withdrawal has been made
   * @param owner address owning the deposit
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event CapitalERC721Withdrawal(
    address indexed owner,
    uint256 positionId,
    address assetAddress,
    uint256 depositTimestamp
  );

  /**
   * @notice Emitted when an ERC721 capital asset has been harvested
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   */
  event CapitalERC721Harvest(uint256 indexed positionId, address assetAddress);

  /**
   * @notice Emitted when an ERC721 capital asset has been "kicked", which may cause the underlying
   *  usdc equivalent value to change.
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   * @param usdcEquivalent new usdc equivalent value of the position
   */
  event CapitalPositionAdjustment(
    uint256 indexed positionId,
    address assetAddress,
    uint256 usdcEquivalent
  );

  /// Thrown when called with an invalid asset type for the function. Valid
  /// types are defined under CapitalAssetType
  error InvalidAssetType(CapitalAssetType);

  /**
   * @notice Account for a deposit of `id` for the ERC721 asset at `assetAddress`.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param owner address that owns the position
   * @param assetAddress address of the ERC20 address
   * @param assetTokenId id of the ERC721 asset to add
   * @return id of the newly created position
   */
  function depositERC721(
    address owner,
    address assetAddress,
    uint256 assetTokenId
  ) external returns (uint256);

  /**
   * @notice Get the id of the ERC721 asset held by position `id`. Pair this with
   *  `assetAddressOf` to get the address & id of the nft.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param positionId id of the position
   * @return id of the underlying ERC721 asset
   */
  function erc721IdOf(uint256 positionId) external view returns (uint256);

  /**
   * @notice Completely withdraw a position
   * @param positionId id of the position
   */
  function withdraw(uint256 positionId) external;

  /**
   * @notice Harvests the associated rewards, interest, and other accrued assets
   *  associated with the asset token. For example, if given a PoolToken asset,
   *  this will collect the GFI rewards (if available), redeemable interest, and
   *  redeemable principal, and send that to the `owner`.
   * @param positionId id of the position
   */
  function harvest(uint256 positionId) external;

  /**
   * @notice Get the asset address of the position. Example: For an ERC721 position, this
   *  returns the address of that ERC721 contract.
   * @param positionId id of the position
   * @return asset address of the position
   */
  function assetAddressOf(uint256 positionId) external view returns (address);

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
   * @notice Get the number of capital positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

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
   * @return position id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get the USDC value of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @param owner address owning the positions
   * @return eligibleAmount USDC value of positions eligible for rewards
   * @return totalAmount total USDC value of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(
    address owner
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}