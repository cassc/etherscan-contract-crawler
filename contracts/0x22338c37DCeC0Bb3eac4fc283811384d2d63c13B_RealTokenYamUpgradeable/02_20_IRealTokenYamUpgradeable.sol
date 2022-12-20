// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IBridgeToken.sol";
import "./IComplianceRegistry.sol";

interface IRealTokenYamUpgradeable {
  enum TokenType {
    NOTWHITELISTEDTOKEN,
    REALTOKEN,
    ERC20WITHPERMIT,
    ERC20WITHOUTPERMIT
  }

  /**
   * @dev Emitted after an offer is updated
   * @param tokens the token addresses
   **/
  event TokenWhitelistWithTypeToggled(
    address[] indexed tokens,
    TokenType[] indexed types
  );

  /**
   * @dev Emitted after an offer is created
   * @param offerToken the token you want to sell
   * @param buyerToken the token you want to buy
   * @param offerId the Id of the offer
   * @param price the price in baseunits of the token you want to sell
   * @param amount the amount of tokens you want to sell
   **/
  event OfferCreated(
    address indexed offerToken,
    address indexed buyerToken,
    address seller,
    address buyer,
    uint256 indexed offerId,
    uint256 price,
    uint256 amount
  );

  /**
   * @dev Emitted after an offer is updated
   * @param offerId the Id of the offer
   * @param oldPrice the old price of the token
   * @param newPrice the new price of the token
   * @param oldAmount the old amount of tokens
   * @param newAmount the new amount of tokens
   **/
  event OfferUpdated(
    uint256 indexed offerId,
    uint256 oldPrice,
    uint256 indexed newPrice,
    uint256 oldAmount,
    uint256 indexed newAmount
  );

  /**
   * @dev Emitted after an offer is deleted
   * @param offerId the Id of the offer to be deleted
   **/
  event OfferDeleted(uint256 indexed offerId);

  /**
   * @dev Emitted after an offer is accepted
   * @param offerId The Id of the offer that was accepted
   * @param seller the address of the seller
   * @param buyer the address of the buyer
   * @param price the price in baseunits of the token
   * @param amount the amount of tokens that the buyer bought
   **/
  event OfferAccepted(
    uint256 indexed offerId,
    address indexed seller,
    address indexed buyer,
    address offerToken,
    address buyerToken,
    uint256 price,
    uint256 amount
  );

  /**
   * @dev Emitted after an offer is deleted
   * @param oldFee the old fee basic points
   * @param newFee the new fee basic points
   **/
  event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

  /**
   * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
   * @param offerToken The address of the token to be sold
   * @param buyerToken The address of the token to be bought
   * @param buyer The address of the allowed buyer (zero address means anyone can buy)
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   **/
  function createOffer(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Creates a new offer or updates an existing offer with permit (call this again with the changed price + offerId)
   * @param offerToken The address of the token to be sold
   * @param buyerToken The address of the token to be bought
   * @param buyer The address of the allowed buyer (zero address means anyone can buy)
   * @param price The price in base units of the token to be sold
   * @param amount The amount to be permitted
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function createOfferWithPermit(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Updates an existing offer (call this again with the changed price + offerId)
   * @param offerId The Id of the offer
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   **/
  function updateOffer(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Updates an existing offer (call this again with the changed price + offerId)
   * @param offerId The Id of the offer
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function updateOfferWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Deletes an existing offer, only the seller of the offer can do this
   * @param offerId The Id of the offer to be deleted
   **/
  function deleteOffer(uint256 offerId) external;

  /**
   * @notice Deletes an existing offer (for example in case tokens are frozen), only the admin can do this
   * @param offerId The Id of the offer to be deleted
   **/
  function deleteOfferByAdmin(uint256 offerId) external;

  /**
   * @notice Accepts an existing offer
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param offerId The Id of the offer
   * @param price The price in base units of the offer tokens
   * @param amount The amount of offer tokens
   **/
  function buy(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Accepts an existing offer with permit
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param offerId The Id of the offer
   * @param price The price in base units of the offer tokens
   * @param amount The amount of offer tokens
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function buyWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Returns the offer count
   * @return offerCount The offer count
   **/
  // return the total number of offers to loop through all offers
  // its the web frontends job to keep track of offers
  function getOfferCount() external view returns (uint256);

  /**
   * @notice Returns the offer count
   * @return offerCount The offer count
   **/
  function getTokenType(address token) external view returns (TokenType);

  /**
   * @notice Returns the token information: decimals, symbole, name
   * @param tokenAddress The address of the reference asset of the distribution
   * @return The decimals of the token
   * @return The symbol  of the token
   * @return The name of the token
   **/
  function tokenInfo(address tokenAddress)
    external
    view
    returns (
      uint256,
      string memory,
      string memory
    );

  /**
   * @notice Returns the offer information
   * @param offerId The offer Id
   * @return The offer token address
   * @return The buyer token address
   * @return The seller address
   * @return The buyer address
   * @return The price
   * @return The amount of the offer token
   **/
  function getInitialOffer(uint256 offerId)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    );

  /**
   * @notice Returns the offer information
   * @param offerId The offer Id
   * @return The offer token address
   * @return The buyer token address
   * @return The seller address
   * @return The buyer address
   * @return The price
   * @return The available balance
   **/
  function showOffer(uint256 offerId)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    );

  /**
   * @notice Returns price in buyertokens for the specified amount of offertokens
   * @param offerId The offer Id
   * @param amount The amount of offer tokens
   * @return The total amount to pay
   **/
  function pricePreview(uint256 offerId, uint256 amount)
    external
    view
    returns (uint256);

  /**
   * @notice Whitelist or unwhitelist a token
   * @param tokens The token addresses
   * @param types The token whitelist status, true for whitelisted and false for unwhitelisted
   **/
  function toggleWhitelistWithType(
    address[] calldata tokens,
    TokenType[] calldata types
  ) external;

  /**
   * @notice In case someone wrongfully directly sends erc20 to this contract address, the moderator can move them out
   * @param token The token address
   **/
  function saveLostTokens(address token) external;

  /**
   * @notice Admin sets the fee
   * @param fee The new fee basic points
   **/
  function setFee(uint256 fee) external;
}