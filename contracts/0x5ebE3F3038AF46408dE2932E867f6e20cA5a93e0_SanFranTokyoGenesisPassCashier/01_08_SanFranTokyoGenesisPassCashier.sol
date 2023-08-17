//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SalesTimestamps.sol";
import "@klktn/allowlist.eth/contracts/EIP712Allowlisting.sol";

interface ISFT721 {
  function mint(address to, uint256 amount) external;

  function numberMinted(address owner) external view returns (uint256);
}

// Custom Errors
error ReachedMintLimitPerWallet();

/**
 * @dev Mint Schedule
 * 0: Treasury & Dev mint 100 tokens, maximum 100 tokens for this phase
 *    Note that this is done in the treasuryMint function in CoreMinter
 * 1: Guaranteed allowlist mint, maximum 1900 tokens for this phase
 * 2: FCFS allowlist mint, maximum 100 + remaining mint limit from previous phases if there is any left
 * 3: Public mint until mint-out
 *
 * During all phases, the mint limit per wallet is 1.
 */

contract SanFranTokyoGenesisPassCashier is EIP712Allowlisting, SalesTimestamps {
  // Custom Events
  event CashierPhaseOneAllowlistMint(address indexed recipient);
  event CashierPhaseTwoAllowlistMint(address indexed recipient);
  event CashierPublicMint(address indexed recipient);

  ISFT721 public immutable erc721Contract;

  constructor(address _erc721ContractAddress) EIP712Allowlisting() {
    erc721Contract = ISFT721(_erc721ContractAddress);
  }

  function _mintERC721() internal {
    erc721Contract.mint(msg.sender, 1);
  }

  /**
   * @dev Phase 1 Allowlist mint
   */
  function mintPhaseOneAllowlist(
    bytes calldata signature
  )
    external
    requiresValidPhaseOneAllowlistMintTime
    requiresAllowlist(signature, "SanFranTokyoGenesisPass", "1")
    enforceMintLimitPerWallet
  {
    _mintERC721();
    emit CashierPhaseOneAllowlistMint(msg.sender);
  }

  /**
   * @dev Phase 2 (FCFS) Allowlist mint
   */
  function mintPhaseTwoAllowlist(
    bytes calldata signature
  )
    external
    requiresValidPhaseTwoAllowlistMintTime
    requiresAllowlist(signature, "SanFranTokyoGenesisPass", "2")
    enforceMintLimitPerWallet
  {
    _mintERC721();
    emit CashierPhaseTwoAllowlistMint(msg.sender);
  }

  /**
   * @dev Public mint
   */
  function mintPublic()
    external
    requiresValidPublicMintTime
    enforceMintLimitPerWallet
  {
    _mintERC721();
    emit CashierPublicMint(msg.sender);
  }

  /**
   * @dev Throws if user has already minted 1 or more tokens
   * or the transaction will result in user having more than 1 tokens
   * after this transaction
   */
  modifier enforceMintLimitPerWallet() {
    if (erc721Contract.numberMinted(msg.sender) >= 1)
      revert ReachedMintLimitPerWallet();
    _;
  }

  function validateSignature(
    bytes calldata signature,
    string calldata phase,
    address recipient
  ) public view returns (bool) {
    return
      isSignatureValid(signature, "SanFranTokyoGenesisPass", phase, recipient);
  }
}