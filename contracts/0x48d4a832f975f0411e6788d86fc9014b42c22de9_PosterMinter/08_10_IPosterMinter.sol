// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPosterMinter {
  error NotSigner();
  error NotEnoughEth();
  error CostMismatch();
  error PosterMintingClosed();
  error HashRepeated();
  error TransferFailed();
  error MissingShares();
  error CannotMintZeroAmount();
  error ZeroAddress();
  error ProofInvalid();
  error SignatureExpired();

  /**
   * @notice The information required to mint a poster.
   * @param tokenId The id of the token to mint.
   * @param amount The amount of the tokens to mint.
   * @param ownerMint Whether the owner is minting.
   * @param totalCost The total cost of the poster/posters being minted.
   * @param shares The shares for each fee recipient.
   * @param feeRecipients The addresses of the fee recipients.
   * @param buyer The address of the buyer.
   * @param nonce The nonce of the poster info.
   * @param expiry The expiry date of the poster info.
   */
  struct MintPosterInfo {
    uint256 tokenId;
    uint256 amount;
    bool ownerMint;
    uint256 totalCost;
    uint256[] shares;
    address[] feeRecipients;
    address buyer;
    uint256 nonce;
    uint256 expiry;
  }

  function mint(MintPosterInfo calldata mintPosterInfo, bytes calldata signature, address signer) external payable;

  function mintFirst(
    MintPosterInfo calldata mintPosterInfo,
    uint256 mintEndsAt,
    bytes calldata signature,
    address signer
  ) external payable;
}