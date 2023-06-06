// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IPublicMintByMetadrop.sol. Interface for metadrop public mint primary sale module
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Global/IConfigStructures.sol";
import "../IPrimarySaleModule.sol";

interface IPublicMintByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    STRUCTS and ENUMS
   * =====================================================================================================================
   */
  // Configuation options for this primary sale module.
  struct PublicMintConfig {
    uint256 phaseMaxSupply;
    uint256 phaseStart;
    uint256 phaseEnd;
    uint256 publicPrice;
    uint256 maxPublicQuantity;
  }

  /** ====================================================================================================================
   *                                                        ERRORS
   * =====================================================================================================================
   */
  // Error when the mint request exceeds the public mint allowance.
  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  );

  /** ====================================================================================================================
   *                                                       FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) publicMintStatus  View of public mint status
   * _____________________________________________________________________________________________________________________
   */
  /**
   *
   * @dev publicMintStatus: View of public mint status
   *
   */
  function publicMintStatus() external view returns (MintStatus);

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
  ) external payable;
}