// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICarbonCreditNFT.sol";
import "../interfaces/IAccessManager.sol";

/// @title Interface for the IMarketplace Smart Contract
/// @author Github: Labrys-Group
interface IMarketplace {
  //################
  //#### STRUCTS ###

  /// @dev This struct represents the parameters required to construct a marketplace contract.
  /// @param superUser The address of the superuser of the contract
  /// @param platformAdmin The address of the platform admin of the contract
  /// @param CarbonCreditNFT The address of the carbon credit NFT contract
  /// @param IMPTAddress The address of the IMPT ERC20 contract
  /// @param IMPTTreasuryAddress The address of the IMPT treasury contract
  struct ConstructorParams {
    ICarbonCreditNFT CarbonCreditNFT;
    IERC20 IMPTAddress;
    address IMPTTreasuryAddress;
    IAccessManager AccessManager;
  }

  /// @dev This struct represents a sale order for carbon credits
  /// @param saleOrderId The unique identifier for this sale order, this will be invalidated within the method to ensure no double-spends
  /// @param tokenId The token ID of the carbon credit being sold
  /// @param amount The amount of carbon credits being sold
  /// @param salePrice The price at which the carbon credits are being sold
  /// @param expiry The expiration timestamp for this sale order
  /// @param seller The address of the seller
  struct SaleOrder {
    bytes24 saleOrderId;
    uint256 tokenId;
    uint256 amount;
    uint256 salePrice;
    uint40 expiry;
    address seller;
  }

  /// @dev This struct contains the authorisation parameters for a sale request, this will be provided along with a SaleOrder. This struct will be signed by the backend, as it will check if the 'to' address is KYCed and the expiry will ensure the request cannot live too long
  /// @param expiry This authorisation expiry will be a short duration ~5 mins and allows users to delist their tokens or change the sell order without risking another user saving the sellerSignature to be executed later on
  /// @param to The address that will receive the purchased tokens
  struct AuthorisationParams {
    uint40 expiry;
    address to;
  }

  //####################################
  //#### ERRORS #######################
  //####################################

  /// @dev This error is thrown when a sale order has expired.
  error SaleOrderExpired();

  /// @dev This error is thrown when the seller does not have sufficient carbon credits to fulfill the sale.
  error InsufficientSellerCarbonCreditBalance();

  /// @dev This error is thrown when the buyer does not have sufficient balance of IMPT to fulfill the purchase.
  error InsufficientTokenBalance();

  /// @dev This error is thrown when a sale order with the same ID has already been used.
  error SaleOrderIdUsed();

  /// @dev This error is thrown when a user is trying to use AuthorisationParams where the to address doesn't match the msg.sender
  error InvalidBuyer();

  //####################################
  //#### EVENTS #######################
  //####################################

  /// @dev This event is emitted when a carbon credit sale is completed.
  /// @param _saleOrderId The unique identifier for the sale order.
  /// @param _tokenId The token ID of the carbon credit being sold.
  /// @param _amount The amount of carbon credits being sold.
  /// @param _salePrice The price at which the carbon credits were sold.
  /// @param _seller The address of the seller.
  /// @param _buyer The address of the buyer.
  event CarbonCreditSaleCompleted(
    bytes24 _saleOrderId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _salePrice,
    address indexed _seller,
    address indexed _buyer
  );

  /// @dev This event is emitted when the royalty percentage changes.
  /// @param _royaltyPercentage The new royalty percentage.
  event RoyaltyPercentageChanged(uint256 _royaltyPercentage);

  //####################################
  //#### SETTER-FUNCTIONS #############
  //####################################

  /// @dev This function allows the platform admin to set the address of the IMPT treasury contract.
  /// @param _implementation The address of the IMPT treasury contract.
  function setIMPTTreasury(address _implementation) external;

  /// @dev This function allows the platform admin to set the royalty percentage.
  /// @param _royaltyPercentage The new royalty percentage.
  function setRoyaltyPercentage(uint256 _royaltyPercentage) external;

  /// @dev This function allows the platform admin to pause the contract.
  function pause() external;

  /// @dev This function allows the platform admin to unpause the contract.
  function unpause() external;

  //####################################
  //#### AUTO-GENERATED GETTERS #######
  //####################################

  /// @dev This function returns the address of the IMPT ERC20 contract.
  /// @return _implementation The address of the IMPT ERC20 contract.
  function IMPTAddress() external returns (IERC20 _implementation);

  /// @dev This function returns the address of the carbon credit NFT contract.
  /// @return _implementation The address of the carbon credit NFT contract.
  function CarbonCreditNFT() external returns (ICarbonCreditNFT _implementation);

  /// @dev This function returns the address of the IMPT treasury contract.
  /// @return _implementation The address of the IMPT treasury contract.
  function IMPTTreasuryAddress() external returns (address _implementation);

  /// @dev This function returns whether the specified sale order ID has been used.
  /// @param _saleOrderId The sale order ID to check.
  /// @return used True if the sale order ID has been used, false otherwise.
  function usedSaleOrderIds(bytes24 _saleOrderId) external returns (bool used);

  /// @dev This function returns the address of the IMPT Access Manager contract
  function AccessManager() external returns (IAccessManager implementation);

  /// @dev This method executes the provided sale order, charging the seller their sale amount and transferring the msg.sender the tokens. It also takes a royalty percentage from the sale and transfers it to the IMPT treasury. This method also ensures that the _authorisationParams.to == msg.sender
  /// @param _authorisationParams The authorisation parameters from the backend
  /// @param _authorisationSignature The signed saleOrder + authorisationParams
  /// @param _saleOrder The sale order details
  /// @param _sellerOrderSignature The seller's signature
  function purchaseToken(
    AuthorisationParams calldata _authorisationParams,
    bytes calldata _authorisationSignature,
    SaleOrder calldata _saleOrder,
    bytes calldata _sellerOrderSignature
  ) external;
}