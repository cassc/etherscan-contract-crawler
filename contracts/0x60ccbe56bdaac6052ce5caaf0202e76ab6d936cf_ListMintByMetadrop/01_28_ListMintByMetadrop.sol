// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title ListMintByMetadrop.sol. This contract is the listmint primary sale contract
 * from the metadrop deployment platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IListMintByMetadrop.sol";
import "../PrimarySaleModule.sol";

/**
 *
 * @dev Inheritance details:
 *      PrimarySaleModule             Platform-wide primary sale module features
 *      IListMintByMetadrop           Specfic interface for this primary sale module
 *
 *
 */

contract ListMintByMetadrop is PrimarySaleModule, IListMintByMetadrop {
  // The merkleroot for the allowlist
  bytes32 public listMerkleRoot;

  // Track list minting allocations:
  mapping(address => uint256) public listAllocationMinted;

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
    ListMintConfig memory listMintConfig = abi.decode(
      configData_,
      (ListMintConfig)
    );

    listMerkleRoot = listMintConfig.allowlist;

    _initialisePrimarySaleModuleBase(
      initialInstanceOwner_,
      projectOwner_,
      vesting_,
      pauseCutoffInDays_,
      listMintConfig.start,
      listMintConfig.end,
      listMintConfig.phaseMaxSupply,
      metadropOracleAddress_,
      messageValidityInSeconds_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) listMintStatus  View of list mint status
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function listMintStatus() external view returns (MintStatus status) {
    return phaseMintStatus();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) setList  Set the merkleroot
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoot_        The bytes32 merkle root to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setList(bytes32 merkleRoot_) external onlyPlatformAdmin {
    listMerkleRoot = merkleRoot_;

    emit MerkleRootSet(merkleRoot_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) listMint  Mint using the list
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              Position of the entry in the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
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
  function listMint(
    uint256 position_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    bytes32[] calldata proof_,
    address recipient_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_,
    bytes calldata messageSignature_
  ) external payable {
    address addressWithAllowance = _merkleProofCheckForCaller(
      position_,
      quantityEligible_,
      proof_,
      unitPrice_,
      (msg.value == (unitPrice_ * quantityToMint_))
    );

    // See if this address has already minted its full allocation:
    if (
      (listAllocationMinted[addressWithAllowance] + quantityToMint_) >
      quantityEligible_
    )
      revert RequestingMoreThanRemainingAllocation({
        previouslyMinted: listAllocationMinted[addressWithAllowance],
        requested: quantityToMint_,
        remainingAllocation: quantityEligible_ -
          listAllocationMinted[addressWithAllowance]
      });

    listAllocationMinted[addressWithAllowance] += quantityToMint_;

    _mint(
      msg.sender,
      recipient_,
      addressWithAllowance,
      quantityToMint_,
      unitPrice_,
      messageTimeStamp_,
      messageHash_,
      messageSignature_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _merkleProofCheckForCaller  Check the merkle root for the current msg.sender
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param paymentValid_          If the passed payment is valid
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _merkleProofCheckForCaller(
    uint256 position_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 unitPrice_,
    bool paymentValid_
  ) internal view returns (address addressWithAllowance_) {
    (bool proofIsValid, address addressWithAllowance) = merkleListValid(
      msg.sender,
      position_,
      quantityEligible_,
      proof_,
      unitPrice_,
      paymentValid_
    );

    if (!proofIsValid) {
      revert ProofInvalid();
    }

    return (addressWithAllowance);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) merkleListValid  Eligibility check for the merkleroot controlled minting. This can be called from
   * front-end (for example to control screen components that indicate if the connected address is eligible) as well as
   * from within the contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param addressToCheck_        The address we are checking
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              The position of the item in the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param paymentValid_          If the payment is valid
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function merkleListValid(
    address addressToCheck_,
    uint256 position_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 unitPrice_,
    bool paymentValid_
  ) public view returns (bool success, address allowanceAddress) {
    if (!paymentValid_) revert IncorrectPayment();

    // check the calling address first:
    bytes32 leaf = _getListHash(
      addressToCheck_,
      position_,
      quantityEligible_,
      unitPrice_
    );

    if (MerkleProof.verify(proof_, listMerkleRoot, leaf)) {
      return (true, addressToCheck_);
    }

    if (useEPS) {
      address[] memory allAddresses = epsRegister.getAddresses(
        addressToCheck_,
        address(this),
        2,
        true,
        false
      );

      // At EPS the first address (if any) is the calling address. No
      // need to check this again, but check any delegated cold addresses:
      for (uint256 i = 1; i < allAddresses.length; ) {
        leaf = _getListHash(
          allAddresses[i],
          position_,
          quantityEligible_,
          unitPrice_
        );

        if (MerkleProof.verify(proof_, listMerkleRoot, leaf)) {
          return (true, allAddresses[i]);
        }
        unchecked {
          i++;
        }
      }
    }

    // If we reach here the proof check has failed:
    return (false, addressToCheck_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _getListHash  Get the hash of the args for the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param minter_                The address being minted for.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              The position of the item in the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantity_              The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _getListHash(
    address minter_,
    uint256 position_,
    uint256 quantity_,
    uint256 unitPrice_
  ) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(minter_, position_, quantity_, unitPrice_));
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) checkAllocation   Eligibility check for all lists. Will return a count of remaining allocation
   * (if any) and a status code.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              Position of the entry in the list
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param addressToCheck_        The address we are checking for an allocation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function checkAllocation(
    uint256 position_,
    uint256 quantityEligible_,
    uint256 unitPrice_,
    bytes32[] calldata proof_,
    address addressToCheck_
  ) external view returns (uint256 allocation, AllocationCheck statusCode) {
    (bool proofIsValid, address addressWithAllowance) = merkleListValid(
      addressToCheck_,
      position_,
      quantityEligible_,
      proof_,
      unitPrice_,
      true
    );

    if (!proofIsValid) {
      return (0, AllocationCheck.invalidProof);
    } else {
      allocation =
        quantityEligible_ -
        listAllocationMinted[addressWithAllowance];
      if (allocation > 0) {
        return (allocation, AllocationCheck.hasAllocation);
      } else {
        return (allocation, AllocationCheck.allocationExhausted);
      }
    }
  }
}