// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IListMintByMetadrop.sol. Interface for metadrop list mint primary sale module
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Global/IConfigStructures.sol";

interface IListMintByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                  STRUCTS and ENUMS
   * =====================================================================================================================
   */
  // Enumerate the results from our allocation check.
  //   - invalidListType: the list type doesn't exist.
  //   - hasAllocation: congrats, you have an allocation on this list.
  //   - invalidProof: the data passed is not the right leaf on the tree.
  //   - allocationExhausted: you had an allocation, but you've minted it already.
  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  // Configuation options for this primary sale module.
  struct ListMintConfig {
    bytes32 allowlist;
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  /** ====================================================================================================================
   *                                                    EVENTS
   * =====================================================================================================================
   */

  // Event issued when the merkle root is set.
  event MerkleRootSet(bytes32 merkleRoot);

  /** ====================================================================================================================
   *                                                    ERRORS
   * =====================================================================================================================
   */
  // The provided proof is not valid with the provided arguments.
  error ProofInvalid();

  // Number of tokens requested for this mint exceeds the remaining allocation (taking the
  // original allocation from the list and deducting minted tokens).
  error RequestingMoreThanRemainingAllocation(
    uint256 previouslyMinted,
    uint256 requested,
    uint256 remainingAllocation
  );

  /** ====================================================================================================================
   *                                                   FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) listMintStatus  View of list mint status
   *
   * _____________________________________________________________________________________________________________________
   */
  function listMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) setList  Set the merkleroot
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoot_        The bytes32 merkle root to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setList(bytes32 merkleRoot_) external;

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
  ) external payable;

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
  ) external view returns (bool success, address allowanceAddress);

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
  ) external view returns (uint256 allocation, AllocationCheck statusCode);
}