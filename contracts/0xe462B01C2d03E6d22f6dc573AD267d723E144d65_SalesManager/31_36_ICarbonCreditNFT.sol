// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "./IMarketplace.sol";
import "./IAccessManager.sol";
import "./IInventory.sol";
import "./ISoulboundToken.sol";

/// @title ICarbonCreditNFT
/// @author Github: Labrys-Group
/// @dev This interface represents a carbon credit non-fungible token (NFT). It extends the IERC1155 interface to allow for the creation and management of carbon credits.
interface ICarbonCreditNFT is IERC1155Upgradeable {
  /// @dev The `TransferAuthorisationParams` struct holds the parameters required to authorisation a token transfer, this struct will be signed by a backend wallet. Only KYCed users can hold CarbonCreditNFT's and this authorisation ensures that the Backend has checked that the 'to' address belongs to a KYCed user
  /// @param expiry representing the request UNIX expiry time
  /// @param to The receiver of the transfer
  struct TransferAuthorisationParams {
    uint40 expiry;
    address to;
  }

  /// @dev The `ConstructorParams` struct holds the parameters that are required to be passed to the contract's constructor.
  /// @param superUser The address of the superuser of the contract.
  /// @param baseURI The base URI for the NFT contract
  struct ConstructorParams {
    address superUser;
    address platformAdmin;
    string baseURI;
    IAccessManager AccessManager;
    string name;
    string symbol;
  }

  //################
  //#### ERRORS ####
  //

  /// @dev The `MustBeMarketplaceContract` error is thrown if the contract being interacted with is not the marketplace contract
  error MustBeMarketplaceContract();

  /// @dev This error is thrown when calling the safeTransferFrom or safeBatchTransferFrom with the standard ERC1155 transfer parameters. This is disabled because we require a backend signature in order to transfer tokens, this requires disabling the base method and overloading it with a new one that includes the additional parameters
  error TransferMethodDisabled();

  //###################
  //#### FUNCTIONS ####
  /// @dev Returns the token uri for the provided token id
  /// @param _id The token id for which the URI is being retrieved.
  /// @return The token URI for the provided token id.
  function uri(uint256 _id) external view returns (string memory);

  /// @dev Allows user's with the IMPT_MINTER_ROLE to mint tokens. This function creates new tokens and assigns them to the specified address.
  /// @param _to The address to which the new tokens should be assigned.
  /// @param _id The token id for the new tokens being minted.
  /// @param _amount The number of tokens being minted.
  /// @param _data Optional data pass through incase we develop the token hooks later on
   /// @dev checks the inventory contract for available supply and updates accordingly after minting
  /// @dev This function is only callable when the contract is not paused
  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external;

  /// @dev Burns the NFT token and increments retire/burn counts for soulbound and inventory contracts, respectively
  /// @param _tokenId the Carbon Credit NFT token ID to burn
  /// @param _amount the amount of a given token ID to burn
  /// @dev This function is only callable when the contract is not paused
  function retire(uint256 _tokenId, uint256 _amount) external;

  /// @dev Allows user's with the IMPT_MINTER_ROLE to batch mint multiple token id's with varying amounts to a specified user. This function creates new tokens and assigns them to the specified address.
  /// @param _to The address to which the new tokens should be assigned.
  /// @param _ids An array of token id's for the new tokens being minted.
  /// @param _amounts An array of the number of tokens being minted for each corresponding token id in the ids array.
  /// @param _data Optional data pass through incase we develop the token hooks later on
  /// @dev checks the inventory contract for available supply and updates accordingly after minting
  /// @dev This function is only callable when the contract is not paused
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  /// @dev Allows user's to transfer their CarbonCreditNFT to a KYCed user. The TransferAuthorisationParams contains the destination to address and the backendSignature ensures that the backend has validated the address to be a KYCed user.
  /// @param _from The from address
  /// @param _id The tokenId to transfer
  /// @param _amount The amount of tokenId's to transfer
  /// @param _backendSignature The signed TransferAuthorisationParams by the backend
  /// @param _transferAuthParams The transfer parameters
  /// @dev This function is only callable when the contract is not paused
  function transferFromBackendAuth(
    address _from,
    uint256 _id,
    uint256 _amount,
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _backendSignature
  ) external;

  /// @dev Allows user's to transfer multiple CarbonCreditNFT's to a KYCed user. The TransferAuthorisationParams contains the destination to address and the backendSignature ensures that the backend has validated the address to be a KYCed user.
  /// @param _from The from address
  /// @param _ids The id's to transfer
  /// @param _amounts Equivalent length array containing the amount of each tokenId to transfer
  /// @param _backendSignature The signed TransferAuthorisationParams by the backend
  /// @param _transferAuthParams The transfer parameters
  /// @dev This function is only callable when the contract is not paused
  function batchTransferFromBackendAuth(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _backendSignature
  ) external;

  //################
  //#### EVENTS ####

  /// @dev The `MarketplaceContractChanged` event is emitted whenever the contract's associated marketplace contract is changed.
  /// @param _implementation The new implementation of the marketplace contract.
  event MarketplaceContractChanged(IMarketplace _implementation);

  /// @dev The `InventoryContractChanged` event is emitted whenever the contract's associated inventory contract is changed.
  /// @param _implementation The new implementation of the inventory contract.
  event InventoryContractChanged(IInventory _implementation);

  /// @dev The `SoulboundContractChanged` event is emitted whenever the contract's associated soulbound token contract is changed.
  /// @param _implementation The new implementation of the soulbound contract.
  event SoulboundContractChanged(ISoulboundToken _implementation);

  /// @dev The `BaseURIUpdated` event is emitted whenever the contract's baseUri is updated
  /// @param _baseUri The new baseUri to set
  event BaseUriUpdated(string _baseUri);

  //##########################
  //#### SETTER-FUNCTIONS ####

  /// @dev The `setBaseUri` function sets the baseURI for the contract, the provided baseUri is concatted with the address of the contract so that the uri for tokens is: `${baseUri}/${address(this)}/${tokenId}`
  /// @param _baseUri The new base uri for the contract
  function setBaseUri(string calldata _baseUri) external;

  /// @dev The `setMarketplaceContract` function sets the marketplace contract
  /// @param _marketplaceContract The new implementation of the marketplace contract.
  function setMarketplaceContract(IMarketplace _marketplaceContract) external;

  /// @dev The `setInventoryContract` function sets the inventory contract
  /// @param _inventoryContract The new implementation of the inventory contract.
  function setInventoryContract(IInventory _inventoryContract) external;

  /// @dev The `setSoulboundContract` function sets the soulbound token contract
  /// @param _soulboundContract The new implementation of the soulbound token contract.
  function setSoulboundContract(ISoulboundToken _soulboundContract) external;

  /// @dev This function allows the platform admin to pause the contract.
  function pause() external;

  /// @dev This function allows the platform admin to unpause the contract.
  function unpause() external;

  //################################
  //#### AUTO-GENERATED GETTERS ####
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /// @dev The `MarketplaceContract` function returns the address of the contract's associated marketplace contract.
  ///@return implementation The address of the contract's associated marketplace contract.
  function MarketplaceContract()
    external
    view
    returns (IMarketplace implementation);

  /// @dev This function returns the address of the IMPT Access Manager contract
  ///@return implementation The address of the contract's associated AccessManager contract.
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);

  /// @dev The `InventoryContract` function returns the address of the contract's associated inventory contract.
  ///@return implementation The address of the contract's associated inventory contract.
  function InventoryContract()
    external
    view
    returns (IInventory implementation);

  /// @dev The `SoulboundContract` function returns the address of the contract's associated inventory contract.
  ///@return implementation The address of the contract's associated inventory contract.
  function SoulboundContract()
    external
    view
    returns (ISoulboundToken implementation);
}