// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IPosters} from "../interfaces/internal/IPosters.sol";
import {IPosterInfo} from "../interfaces/internal/IPosterInfo.sol";
import {IPosterMinter} from "../interfaces/internal/IPosterMinter.sol";
import {IRoleAuthority} from "../interfaces/internal/IRoleAuthority.sol";

/**
 * @title PosterMinter contract.
 * @notice The contract that mints Deca Posters.
 * @author j6i, 0x-jj
 */
contract PosterMinter is IPosterMinter, ReentrancyGuard {
  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the RoleAuthority used to determine whether an address has some admin role.
   */
  IRoleAuthority public immutable roleAuthority;

  /**
   * @notice The address of the Posters contract.
   */
  IPosters public immutable posters;

  /**
   * @notice The address of the PosterInfo contract.
   */
  IPosterInfo public immutable posterInfo;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _roleAuthority, address _posters, address _posterInfo) {
    if (_roleAuthority == address(0) || _posters == address(0) || _posterInfo == address(0)) revert ZeroAddress();

    roleAuthority = IRoleAuthority(_roleAuthority);
    posters = IPosters(_posters);
    posterInfo = IPosterInfo(_posterInfo);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The mint function that sets up the custom mint period. Setting the mint period is idempotent.
   * @param mintPosterInfo The information required to mint a poster.
   * @param mintEndsAt When the mint ends.
   * @param signature The signature of the mint info.
   * @param signer The signer of the mint info.
   */
  function mintFirst(
    MintPosterInfo calldata mintPosterInfo,
    uint256 mintEndsAt,
    bytes calldata signature,
    address signer
  ) external payable nonReentrant {
    // Check arguments and signature validity then store poster info
    {
      bytes32 computedHash = _hashWithMintPeriod(mintPosterInfo, mintEndsAt);
      // Ensure the arguments are valid
      _verifyArguments(
        computedHash,
        mintPosterInfo.expiry,
        mintPosterInfo.amount,
        mintPosterInfo.totalCost,
        mintPosterInfo.feeRecipients.length,
        mintPosterInfo.shares.length,
        signer
      );
      // Ensure the signature is valid
      if (!_verifySignature(computedHash, signature, signer)) revert ProofInvalid();
      // Store poster info in posterInfo
      posterInfo.setPosterInfoWithMintPeriod(
        computedHash,
        mintPosterInfo.tokenId,
        mintPosterInfo.ownerMint,
        mintEndsAt
      );
      // Ensure the poster mint period has not elapsed
      if (!posterInfo.isMintActive(mintPosterInfo.tokenId)) revert PosterMintingClosed();
    }

    // Perform mint and fee split
    {
      // Send ETH to recipients
      _splitFee(
        mintPosterInfo.totalCost,
        mintPosterInfo.shares,
        mintPosterInfo.feeRecipients,
        mintPosterInfo.ownerMint
      );
      // Mint poster to buyer
      posters.mint(mintPosterInfo.buyer, mintPosterInfo.tokenId, mintPosterInfo.amount);
    }
  }

  /**
   * @notice The mint function for posters.
   * @param mintPosterInfo The information required to mint a poster.
   * @param signature The signature of the mint info.
   * @param signer The signer of the mint info.
   */
  function mint(
    MintPosterInfo calldata mintPosterInfo,
    bytes calldata signature,
    address signer
  ) external payable nonReentrant {
    // Check arguments and signature validity then store poster info
    {
      bytes32 computedHash = _hash(mintPosterInfo);
      // Ensure the arguments are valid
      _verifyArguments(
        computedHash,
        mintPosterInfo.expiry,
        mintPosterInfo.amount,
        mintPosterInfo.totalCost,
        mintPosterInfo.feeRecipients.length,
        mintPosterInfo.shares.length,
        signer
      );
      // Ensure the signature is valid
      if (!_verifySignature(computedHash, signature, signer)) revert ProofInvalid();

      // Store poster info in posterInfo
      posterInfo.setPosterInfo(computedHash, mintPosterInfo.tokenId, mintPosterInfo.ownerMint);

      // Ensure the poster mint period has not elapsed
      if (!posterInfo.isMintActive(mintPosterInfo.tokenId)) revert PosterMintingClosed();
    }

    // Perform mint and fee split
    {
      // Send ETH to recipients
      _splitFee(
        mintPosterInfo.totalCost,
        mintPosterInfo.shares,
        mintPosterInfo.feeRecipients,
        mintPosterInfo.ownerMint
      );
      // Mint poster to buyer
      posters.mint(mintPosterInfo.buyer, mintPosterInfo.tokenId, mintPosterInfo.amount);
    }
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Used to split the fee between the fee recipients.
   * @param totalCost The total cost of the mint.
   * @param shares The shares for each fee recipient.
   * @param feeRecipients The addresses of the fee recipients.
   * @param ownerMint Whether the owner is minting.
   */
  function _splitFee(
    uint256 totalCost,
    uint256[] calldata shares,
    address[] calldata feeRecipients,
    bool ownerMint
  ) internal {
    // Send ETH to recipients
    if (!ownerMint) {
      uint256 total = 0;
      uint256 i = 0;
      while (i < feeRecipients.length) {
        total += shares[i];
        (bool suceeded, ) = feeRecipients[i].call{value: shares[i]}("");
        if (!suceeded) revert TransferFailed();
        unchecked {
          i++;
        }
      }
      // Ensure total shares is equal to totalCost
      if (total != totalCost) revert CostMismatch();
    }
    // Return excess ETH
    uint256 excess = msg.value - totalCost;
    if (excess > 0) {
      (bool successfullyReturned, ) = msg.sender.call{value: excess}("");
      if (!successfullyReturned) revert TransferFailed();
    }
  }

  /**
   * @notice Used to verify the arguments passed to the mint functions.
   * @param computedHash The computed hash of the mint info.
   * @param expiry The expiry of the mint info signature.
   * @param amount The amount of posters to mint.
   * @param totalCost The total cost of the mint.
   * @param feeRecipientsLength The length of the fee recipients array.
   * @param sharesLength The length of the shares array.
   * @param signer The signer of the mint info.
   */
  function _verifyArguments(
    bytes32 computedHash,
    uint256 expiry,
    uint256 amount,
    uint256 totalCost,
    uint256 feeRecipientsLength,
    uint256 sharesLength,
    address signer
  ) internal view {
    // Ensure signature is not expired
    if (expiry < block.timestamp) {
      revert SignatureExpired();
    }
    // Ensure the amount is greater than 0
    if (amount == 0) {
      revert CannotMintZeroAmount();
    }
    // Ensure enough ETH is received
    if (totalCost > msg.value) {
      revert NotEnoughEth();
    }
    // Ensure the signer has the correct role
    if (!roleAuthority.isPosterSigner(signer)) {
      revert NotSigner();
    }
    // Confirm shares and fee recipients are valid
    if (feeRecipientsLength != sharesLength || feeRecipientsLength == 0) {
      revert MissingShares();
    }
    // Ensure signature has not already been used
    if (posterInfo.isPosterHashUsed(computedHash)) revert HashRepeated();
  }

  /**
   * @notice Used to compute the digest, and verify the signature.
   * @param messageHash The hash of the message.
   * @param signature The signature of the message.
   * @param signer The signer of the message.
   */
  function _verifySignature(
    bytes32 messageHash,
    bytes calldata signature,
    address signer
  ) internal pure returns (bool) {
    return signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);
  }

  /**
   * @notice Used to compute the hash of the mint info for the first time.
   * @param mintPosterInfo The information required to mint a poster.
   * @param mintEndsAt The custom mint period of the poster.
   */
  function _hashWithMintPeriod(
    MintPosterInfo calldata mintPosterInfo,
    uint256 mintEndsAt
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          mintPosterInfo.tokenId,
          mintEndsAt,
          mintPosterInfo.amount,
          mintPosterInfo.ownerMint,
          mintPosterInfo.totalCost,
          mintPosterInfo.shares,
          mintPosterInfo.feeRecipients,
          mintPosterInfo.buyer,
          mintPosterInfo.nonce,
          mintPosterInfo.expiry
        )
      );
  }

  /**
   * @notice Used to compute the hash of the mint info.
   * @param mintPosterInfo The information required to mint a poster.
   */
  function _hash(MintPosterInfo calldata mintPosterInfo) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          mintPosterInfo.tokenId,
          mintPosterInfo.amount,
          mintPosterInfo.ownerMint,
          mintPosterInfo.totalCost,
          mintPosterInfo.shares,
          mintPosterInfo.feeRecipients,
          mintPosterInfo.buyer,
          mintPosterInfo.nonce,
          mintPosterInfo.expiry
        )
      );
  }
}