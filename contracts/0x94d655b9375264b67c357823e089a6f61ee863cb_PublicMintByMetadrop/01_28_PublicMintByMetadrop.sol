// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title PublicMintByMetadrop.sol. This contract is the public mint primary sale contract
 * from the metadrop deployment platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPublicMintByMetadrop.sol";
import "../PrimarySaleModule.sol";

/**
 *
 * @dev Inheritance details:
 *      PrimarySaleModule             Platform-wide primary sale module features
 *      IPublicMintByMetadrop         Specfic interface for this primary sale module
 *
 *
 */

contract PublicMintByMetadrop is PrimarySaleModule, IPublicMintByMetadrop {
  // Mint price for the public mint.
  uint128 public publicMintPrice;

  // Max allowance per address for public mint
  uint16 public maxPublicMintPerAddress;

  // Track publicMint minting allocations:
  mapping(address => uint256) public publicMintAllocationMinted;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  constructor(address epsRegister_) PrimarySaleModule(epsRegister_) {}

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Load configuration into storage for a new instance.
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
  ) public override {
    // Decode the config:
    PublicMintConfig memory publicMintConfig = abi.decode(
      configData_,
      (PublicMintConfig)
    );

    // Set the public mint price:
    publicMintPrice = uint128(publicMintConfig.publicPrice);

    // Set max mints per address
    maxPublicMintPerAddress = uint16(publicMintConfig.maxPublicQuantity);

    // Set this phases max supply
    phaseMaxSupply = uint32(publicMintConfig.phaseMaxSupply);

    _initialisePrimarySaleModuleBase(
      initialInstanceOwner_,
      projectOwner_,
      vesting_,
      pauseCutoffInDays_,
      publicMintConfig.phaseStart,
      publicMintConfig.phaseEnd,
      publicMintConfig.phaseMaxSupply,
      metadropOracleAddress_,
      messageValidityInSeconds_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) publicMintStatus  View of public mint status
   * _____________________________________________________________________________________________________________________
   */
  function publicMintStatus() external view returns (MintStatus) {
    return phaseMintStatus();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) publicMint  Public minting of tokens according to set config.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_      The timestamp of the signed message
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be checked as part of
   *                               antibot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageSignature_      The signed message from the backend oracle signer for validation as part of anti-bot
   *                               protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function publicMint(
    uint256 quantityToMint_,
    address recipient_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_,
    bytes calldata messageSignature_
  ) external payable {
    if (msg.value != (publicMintPrice * quantityToMint_))
      revert IncorrectPayment();

    // Get previous mint count and check that this quantity will not exceed the allowance.
    uint256 publicMintsForAddress;

    // If msg.sender and tx.origin are NOT the same get the largest number of mints for either
    if (msg.sender != tx.origin) {
      uint256 senderMinted = publicMintAllocationMinted[msg.sender];
      uint256 originMinted = publicMintAllocationMinted[tx.origin];
      if (senderMinted > originMinted) {
        publicMintsForAddress = senderMinted;
      } else {
        publicMintsForAddress = originMinted;
      }
    } else {
      publicMintsForAddress = publicMintAllocationMinted[msg.sender];
    }

    if (maxPublicMintPerAddress != 0) {
      if ((publicMintsForAddress + quantityToMint_) > maxPublicMintPerAddress) {
        revert MaxPublicMintAllowanceExceeded({
          requested: quantityToMint_,
          alreadyMinted: publicMintsForAddress,
          maxAllowance: maxPublicMintPerAddress
        });
      }

      publicMintAllocationMinted[msg.sender] += quantityToMint_;

      if (msg.sender != tx.origin) {
        publicMintAllocationMinted[tx.origin] += quantityToMint_;
      }
    }

    _mint(
      msg.sender,
      recipient_,
      msg.sender,
      quantityToMint_,
      publicMintPrice,
      messageTimeStamp_,
      messageHash_,
      messageSignature_
    );
  }
}