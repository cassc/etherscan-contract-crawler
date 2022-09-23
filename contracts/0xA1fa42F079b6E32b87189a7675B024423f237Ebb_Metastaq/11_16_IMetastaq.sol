// SPDX-License-Identifier: MIT
// Metastaq Contracts v1.0.0
// Creator: Metastaq
pragma solidity ^0.8.4;

/**
 * @dev Interface of Metastaq.
 */
interface IMetastaq {
  /**
   * The caller must Provide required ETH value.
   */
  error InsufficientPayment();

  /**
   * The caller is not alowed to call this fucntion
   */
  error NotAllowedToCall();

  /**
   * The Caller is Contract. will not allow Contract and multi sig wallet in air drop
   */
  error ContractNotAllowedToMint();

  /**
   * Cannot query the balance for the zero address.
   */
  error InvalidPaymentType();

  /**
   *  AllowList Sale Not started yet
   */
  error AllowListMintNotStarted();

  /**
   *  AllowList Sale is Ended
   */
  error AllowListMintEnded();

  /**
   * The Caller is not Eligible For AllowList Mint.
   */
  error NotInAllowList();

  /**
   * The Caller is tring to Mint too much Tokens.
   */
  error ExceedsAllowListLimit();

  /**
   * The Caller has reached Max minting limit
   */
  error ExceedsMaxMintLimit();

  /**
   * The Total supply of Token is mined.
   */
  error ExceedsSupply();

  /**
   * The Public sale is not begun yet.
   */
  error PublicSaleNotStarted();

  /**
   * The Dev Mint Tokens limit reached
   */
  error ExceedsDevMintLimit();

  /**
   * The token does not exist.
   */
  error NotMultipleOfMaxBatchSize();

  /**
   * The Length of Address and token array not matched
   */
  error ArraysLengthNotMatched();

  /**
   * The Address Provided in Contract.
   */
  error ContractAddressNotAllowed();

  /**
   * @dev Emitted when address `to`  has minted quantity `quantity` token. during allowList mint
   */
  event AllowListMint(address indexed to, uint256 quantity);

  /**
   * @dev Emitted when address `to`  has minted quantity `quantity` token. during public sale.
   */
  event PublicSaleMint(address indexed to, uint256 qunatity, uint96 price);

  /**
   * @dev Emitted when address `to`  has minted quantity `quantity` token from Dev tokens.
   */
  event DevMint(address indexed to, uint256 quantity);

  /**
   * @dev Emitted when Allow list is updated.
   */
  event WhiteListUpdated();
  /**
   * @dev Emitted when  royaltyReceiver `royaltyReceiver` ,royaltyInBips `royaltyInBips`  Info is updated.
   */
  event RoyaltyInfoUpdated(
    address indexed royaltyReceiver,
    uint96 royaltyInBips
  );
}
