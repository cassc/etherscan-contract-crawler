// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title INFTByMetadrop.sol. Interface for metadrop NFT standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Global/IConfigStructures.sol";

interface INFTByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event Revealed();
  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);
  event PositionProofSet(bytes32 positionProof);
  event MetadropMint(
    address indexed allowanceAddress,
    address indexed recipientAddress,
    address callerAddress,
    address primarySaleModuleAddress,
    uint256 unitPrice,
    uint256[] tokenIds
  );

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error TransferFailed();
  error AlreadyInitialised();
  error MetadataIsLocked();
  error InvalidTokenAllocationMethod();
  error InvalidAddress();
  error IncorrectConfirmationValue();
  error MintingIsClosedForever();
  error VRFAlreadySet();
  error PositionProofAlreadySet();
  error MetadropFactoryOnly();
  error InvalidRecipient();
  error PauseCutOffHasPassed();
  error AdditionalAddressesCannotBeAddedToRolesUseTransferToTransferRoleToAnotherAddress();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param owner_              The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                            platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_       The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_ The primary sale modules for this drop. These are the contract addresses that are
   *                            authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_          The drop specific configuration for this NFT. This is decoded and used to set
   *                            configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_  The address of the deployed royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param totalRoyaltyPercentage_  The total royalty percentage (project + metadrop) for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address owner_,
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    address royaltyPaymentSplitter_,
    uint96 totalRoyaltyPercentage_,
    string[3] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_);

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view returns (uint256 totalSupply_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() external view returns (uint256 totalUnminted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view returns (uint256 totalMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view returns (uint256 totalBurned_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferProjectOwner  Allows the current project owner to transfer this role to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_   New project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(address newProjectOwner_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferPlatformAdmin  Allows the current platform admin to transfer this role to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_   New platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferPlatformAdmin(address newPlatformAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param preRevealURI_   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param arweaveURI_     The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * @param ipfsURI_     The URI for IPFS
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(
    string calldata preRevealURI_,
    string calldata arweaveURI_,
    string calldata ipfsURI_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_   The confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(string calldata confirmation_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner OR platform admin to set minting
   *                                                          complete
   *
   * @notice Enter confirmation value of "MintingComplete" to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_  Confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    string calldata confirmation_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setUseArweave  Guards against either arweave or IPFS being no more
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param useArweave_   Boolean to indicate whether arweave should be used or not (true = use arweave, false = use IPFS)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setUseArweave(bool useArweave_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(address recipient_, uint96 fraction_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_   The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_        The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setStartPosition  Get the metadata start position for use on reveal of this collection
   * _____________________________________________________________________________________________________________________
   */
  function setStartPosition() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external;
}