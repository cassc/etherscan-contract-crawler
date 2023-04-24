// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IMetadataRenderer} from "./IMetadataRenderer.sol";

import {AddressMintDetails} from "../struct/AddressMintDetails.sol";
import {SaleDetails} from "../struct/SaleDetails.sol";

/// @notice Interface for HOLOGRAPH Drops contract
interface IHolographDropERC721 {
  // Access errors

  /// @notice Only admin can access this function
  error Access_OnlyAdmin();
  /// @notice Missing the given role or admin access
  error Access_MissingRoleOrAdmin(bytes32 role);
  /// @notice Withdraw is not allowed by this user
  error Access_WithdrawNotAllowed();
  /// @notice Cannot withdraw funds due to ETH send failure.
  error Withdraw_FundsSendFailure();
  /// @notice Mint fee send failure
  error MintFee_FundsSendFailure();

  /// @notice Call to external metadata renderer failed.
  error ExternalMetadataRenderer_CallFailed();

  /// @notice Thrown when the operator for the contract is not allowed
  /// @dev Used when strict enforcement of marketplaces for creator royalties is desired.
  error OperatorNotAllowed(address operator);

  /// @notice Thrown when there is no active market filter DAO address supported for the current chain
  /// @dev Used for enabling and disabling filter for the given chain.
  error MarketFilterDAOAddressNotSupportedForChain();

  /// @notice Used when the operator filter registry external call fails
  /// @dev Used for bubbling error up to clients.
  error RemoteOperatorFilterRegistryCallFailed();

  // Sale/Purchase errors
  /// @notice Sale is inactive
  error Sale_Inactive();
  /// @notice Presale is inactive
  error Presale_Inactive();
  /// @notice Presale merkle root is invalid
  error Presale_MerkleNotApproved();
  /// @notice Wrong price for purchase
  error Purchase_WrongPrice(uint256 correctPrice);
  /// @notice NFT sold out
  error Mint_SoldOut();
  /// @notice Too many purchase for address
  error Purchase_TooManyForAddress();
  /// @notice Too many presale for address
  error Presale_TooManyForAddress();

  // Admin errors
  /// @notice Royalty percentage too high
  error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
  /// @notice Invalid admin upgrade address
  error Admin_InvalidUpgradeAddress(address proposedAddress);
  /// @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
  error Admin_UnableToFinalizeNotOpenEdition();

  /// @notice Event emitted for mint fee payout
  /// @param mintFeeAmount amount of the mint fee
  /// @param mintFeeRecipient recipient of the mint fee
  /// @param success if the payout succeeded
  event MintFeePayout(uint256 mintFeeAmount, address mintFeeRecipient, bool success);

  /// @notice Event emitted for each sale
  /// @param to address sale was made to
  /// @param quantity quantity of the minted nfts
  /// @param pricePerToken price for each token
  /// @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
  event Sale(
    address indexed to,
    uint256 indexed quantity,
    uint256 indexed pricePerToken,
    uint256 firstPurchasedTokenId
  );

  /// @notice Sales configuration has been changed
  /// @dev To access new sales configuration, use getter function.
  /// @param changedBy Changed by user
  event SalesConfigChanged(address indexed changedBy);

  /// @notice Event emitted when the funds recipient is changed
  /// @param newAddress new address for the funds recipient
  /// @param changedBy address that the recipient is changed by
  event FundsRecipientChanged(address indexed newAddress, address indexed changedBy);

  /// @notice Event emitted when the funds are withdrawn from the minting contract
  /// @param withdrawnBy address that issued the withdraw
  /// @param withdrawnTo address that the funds were withdrawn to
  /// @param amount amount that was withdrawn
  /// @param feeRecipient user getting withdraw fee (if any)
  /// @param feeAmount amount of the fee getting sent (if any)
  event FundsWithdrawn(
    address indexed withdrawnBy,
    address indexed withdrawnTo,
    uint256 amount,
    address feeRecipient,
    uint256 feeAmount
  );

  /// @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
  /// @param sender address sending close mint
  /// @param numberOfMints number of mints the contract is finalized at
  event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

  /// @notice Event emitted when metadata renderer is updated.
  /// @param sender address of the updater
  /// @param renderer new metadata renderer address
  event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

  /// @notice Admin function to update the sales configuration settings
  /// @param publicSalePrice public sale price in ether
  /// @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
  /// @param publicSaleStart unix timestamp when the public sale starts
  /// @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
  /// @param presaleStart unix timestamp when the presale starts
  /// @param presaleEnd unix timestamp when the presale ends
  /// @param presaleMerkleRoot merkle root for the presale information
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    bytes32 presaleMerkleRoot
  ) external;

  /// @notice External purchase function (payable in eth)
  /// @param quantity to purchase
  /// @return first minted token ID
  function purchase(uint256 quantity) external payable returns (uint256);

  /// @notice External purchase presale function (takes a merkle proof and matches to root) (payable in eth)
  /// @param quantity to purchase
  /// @param maxQuantity can purchase (verified by merkle root)
  /// @param pricePerToken price per token allowed (verified by merkle root)
  /// @param merkleProof input for merkle proof leaf verified by merkle root
  /// @return first minted token ID
  function purchasePresale(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] memory merkleProof
  ) external payable returns (uint256);

  /// @notice Function to return the global sales details for the given drop
  function saleDetails() external view returns (SaleDetails memory);

  /// @notice Function to return the specific sales details for a given address
  /// @param minter address for minter to return mint information for
  function mintedPerAddress(address minter) external view returns (AddressMintDetails memory);

  /// @notice This is the opensea/public owner setting that can be set by the contract admin
  function owner() external view returns (address);

  /// @notice Update the metadata renderer
  /// @param newRenderer new address for renderer
  /// @param setupRenderer data to call to bootstrap data for the new renderer (optional)
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external;

  /// @notice This is an admin mint function to mint a quantity to a specific address
  /// @param to address to mint to
  /// @param quantity quantity to mint
  /// @return the id of the first minted NFT
  function adminMint(address to, uint256 quantity) external returns (uint256);

  /// @notice This is an admin mint function to mint a single nft each to a list of addresses
  /// @param to list of addresses to mint an NFT each to
  /// @return the id of the first minted NFT
  function adminMintAirdrop(address[] memory to) external returns (uint256);

  /// @dev Getter for admin role associated with the contract to handle metadata
  /// @return boolean if address is admin
  function isAdmin(address user) external view returns (bool);
}