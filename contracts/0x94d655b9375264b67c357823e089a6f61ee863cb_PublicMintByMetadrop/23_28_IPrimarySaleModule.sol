// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IPrimarySaleModule.sol. Interface for base primary sale module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "../NFT/INFTByMetadrop.sol";
import "../ThirdParty/EPS/EPSDelegationRegister/IEPSDelegationRegister.sol";

interface IPrimarySaleModule is IConfigStructures {
  /** ====================================================================================================================
   *                                                       ERRORS
   * =====================================================================================================================
   */
  error AlreadyInitialised();
  error AddressAlreadySet();
  error ThisMintIsClosed();
  error IncorrectPayment();
  error InvalidOracleSignature();
  error QuantityExceedsPhaseRemainingSupply(
    uint256 requested,
    uint256 remaining
  );
  error ParametersDoNotMatchSignedMessage();
  error TransferFailed();
  error OracleSignatureHasExpired();
  error CannotSetToZeroAddress();

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Defined here and must be overriden in child contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialInstanceOwner_  The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                               platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_          The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vesting_               The vesting contract used for sales proceeds from this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_            The drop specific configuration for this module. This is decoded and used to set
   *                               configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_     The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_ The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimarySaleModule(
    address initialInstanceOwner_,
    address projectOwner_,
    address vesting_,
    bytes calldata configData_,
    uint256 pauseCutoffInDays_,
    address metadropOracleAddress_,
    uint80 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) setNFTAddress    Set the NFT contract for this drop
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftContract_           The deployed NFT contract
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setNFTAddress(address nftContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) phaseMintStatus    The status of the deployed primary sale module
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH      A withdraw function to allow ETH to be withdrawn to the vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             Theamount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawContractETHBalance      A withdraw function to allow  all ETH to be withdrawn to vesting.
   * _____________________________________________________________________________________________________________________
   */
  function withdrawContractETHBalance() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20     A withdraw function to allow ERC20s to be withdrawn to the vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_             The token to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ACCESS
   * @dev (function) transferProjectOwner    Allows the current project owner to transfer this role to another address,
   * therefore being the equivalent of 'transfer owner'
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_         The new project owner address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(address newProjectOwner_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ACCESS
   * @dev (function) transferPlatformAdmin    Allows the current platform admin to transfer this role to another address,
   * therefore being the equivalent of 'transfer owner'
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_         The new platform admin address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferPlatformAdmin(address newPlatformAdmin_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setMetadropOracleAddress   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_         The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setVestingContractAddress     Allow platform admin to update vesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingContract_         The new vesting contract address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVestingContractAddress(address vestingContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn off anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn ON anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOn() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn off EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn ON EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOn() external;
}