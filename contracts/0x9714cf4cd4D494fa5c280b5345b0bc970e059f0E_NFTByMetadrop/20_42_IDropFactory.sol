// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

pragma solidity 0.8.19;

import "../Global/IConfigStructures.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDropFactory is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event DefaultMetadropPrimaryShareBasisPointsSet(
    uint256 defaultPrimaryFeeBasisPoints
  );
  event DefaultMetadropRoyaltyBasisPointsSet(
    uint256 defaultMetadropRoyaltyBasisPoints
  );
  event PrimaryFeeOverrideByDropSet(string dropId, uint256 percentage);
  event RoyaltyBasisPointsOverrideByDropSet(
    string dropId,
    uint256 royaltyBasisPoints
  );
  event PlatformTreasurySet(address platformTreasury);
  event TemplateAdded(
    TemplateStatus status,
    uint256 templateNumber,
    uint256 loadedDate,
    address templateAddress,
    string templateDescription
  );
  event TemplateTerminated(uint16 templateNumber);
  event DropApproved(
    string indexed dropId,
    address indexed dropOwner,
    bytes32 dropHash
  );
  event DropDetailsDeleted(string indexed dropId);
  event DropExpiryInDaysSet(uint32 expiryInDays);
  event pauseCutOffInDaysSet(uint8 cutOffInDays);
  event SubmissionFeeETHUpdated(uint256 oldFee, uint256 newFee);
  event InitialInstanceOwnerSet(address initialInstanceOwner);
  event DropDeployed(
    string dropId,
    address nftInstance,
    address vestingInstance,
    PrimarySaleModuleInstance[],
    address royaltySplitterInstance
  );
  event vrfSubscriptionIdSet(uint64 vrfSubscriptionId_);
  event vrfKeyHashSet(bytes32 vrfKeyHash);
  event vrfCallbackGasLimitSet(uint32 vrfCallbackGasLimit);
  event vrfRequestConfirmationsSet(uint16 vrfRequestConfirmations);
  event vrfNumWordsSet(uint32 vrfNumWords);
  event metadropOracleAddressSet(address metadropOracleAddress);
  event messageValidityInSecondsSet(uint80 messageValidityInSeconds);

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error MetadropOnly();
  error ValueExceedsMaximum();
  error TemplateCannotBeAddressZero();
  error ProjectOwnerCannotBeAddressZero();
  error PlatformAdminCannotBeAddressZero();
  error ReviewAdminCannotBeAddressZero();
  error PlatformTreasuryCannotBeAddressZero();
  error InitialInstanceOwnerCannotBeAddressZero();
  error MetadropOracleCannotBeAddressZero();
  error VRFCoordinatorCannotBeAddressZero();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string memory dropId_
  ) external view returns (DropApproval memory dropDetails_);

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInSeconds  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInSeconds(
    uint80 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getDefaultMetadropPrimaryShareBasisPoints   Getter for the default platform primary fee basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return defaultMetadropPrimaryShareBasisPoints_   The metadrop primary share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDefaultMetadropPrimaryShareBasisPoints()
    external
    view
    returns (uint256 defaultMetadropPrimaryShareBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyBasisPoints   Getter for the metadrop royalty share in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyBasisPoints_   The metadrop royalty share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyBasisPoints()
    external
    view
    returns (uint256 metadropRoyaltyBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getPrimaryFeeOverrideByDrop    Getter for any drop specific primary fee override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                      The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                      If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryFeeOverrideByDrop_   The primary fee override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPrimaryFeeOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 primaryFeeOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyOverrideByDrop    Getter for any drop specific royalty basis points override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                               The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                               If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyOverrideByDrop_       Royalty basis points override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 metadropRoyaltyOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) getPauseCutOffInDays    Getter for the default pause cutoff period
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPauseCutOffInDays()
    external
    view
    returns (uint8 pauseCutOffInDays_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setpauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setpauseCutOffInDays(uint8 pauseCutOffInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the default
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setinitialInstanceOwner    Set the owner on all created instances
   *
   * The 'initial instance owner' is the address that will be set as the Owner
   * on all cloned instances of contracts created in this factory. Note that we the
   * contract instances are clones we do not call a constructor when an instance
   * is created, rather we set the owner on the call to initialise.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialInstanceOwner_    New owner address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setinitialInstanceOwner(address initialInstanceOwner_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDefaultMetadropPrimaryShareBasisPoints    Setter for the metadrop primary basis points fee
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropPrimaryShareBasisPoints_    New default meradrop primary share
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultMetadropPrimaryShareBasisPoints(
    uint32 defaultMetadropPrimaryShareBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyBasisPoints   Setter for the metadrop royalty percentate in
   *                                                basis points i.e. 100 = 1%
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropRoyaltyBasisPoints_      New default royalty basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyBasisPoints(
    uint32 defaultMetadropRoyaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPrimaryFeeOverrideByDrop   Setter for the metadrop primary percentage fee, in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_           The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param basisPoints_      The basis points override
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPrimaryFeeOverrideByDrop(
    string memory dropId_,
    uint256 basisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyOverrideByDrop   Setter to override royalty basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                  The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyBasisPoints_      Royalty basis points verride
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyOverrideByDrop(
    string memory dropId_,
    uint256 royaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(uint32 dropExpiryInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantPlatformAdmin  Allows the super user Default Admin to add an address to the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_              The address of the new platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantPlatformAdmin(address newPlatformAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantReviewAdmin  Allows the super user Default Admin to add an address to the review admin group.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newReviewAdmin_              The address of the new review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantReviewAdmin(address newReviewAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokePlatformAdmin  Allows the super user Default Admin to revoke from the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldPlatformAdmin_              The address of the old platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokePlatformAdmin(address oldPlatformAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeReviewAdmin  Allows the super user Default Admin to revoke an address to the review admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldReviewAdmin_              The address of the old review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokeReviewAdmin(address oldReviewAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferDefaultAdmin  Allows the super user Default Admin to transfer this right to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newDefaultAdmin_              The address of the new default admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferDefaultAdmin(address newDefaultAdmin_) external;

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external;

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string memory templateDescription_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(uint16 templateNumber_) external;

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(string memory dropId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string memory dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[3] memory collectionURIs_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external view returns (bool matches_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external pure returns (bytes32 configHash_);
}