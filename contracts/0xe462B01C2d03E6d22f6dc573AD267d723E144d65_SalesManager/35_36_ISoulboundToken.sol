// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/ICarbonCreditNFT.sol";
import "../interfaces/IAccessManager.sol";

/// @dev Interface for a soulbound token which is non-transferrable and closely follows the 721 standard.
/// @dev It also manages the token types and formatting of metadata responses
interface ISoulboundToken is IERC165 {
  //################
  //#### STRUCTS ####
  /// @dev The `ConstructorParams` struct holds the parameters that are required to be passed to the contract's constructor.
  /// @param name_ The token name
  /// @param symbol_ The token symbol
  /// @param description_ The description of the token
  /// @param _carbonCreditContract The address of the carbon credit contract (must match interface specs)
  /// @param adminAddress The address that will be assigned to the role IMPT_ADMIN
  struct ConstructorParams {
    string name_;
    string symbol_;
    string description_;
    ICarbonCreditNFT _carbonCreditContract;
    IAccessManager AccessManager;
  }

  /// @dev The required fields for each tokenType. Each tokenType exists in the CarbonCreditNFT contract as a subcollection
  /// @param displayName Unique display name for the token type
  /// @param tokenId The id of the TokenType in the CarbonCreditNFT contract
  struct TokenType {
    string displayName;
    uint256 tokenId;
  }

  //################
  //#### EVENTS ####
  /// @dev This emits ONLY when token `_tokenId` is minted from the zero address and is used to conform closely to ERC721 standards
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /// @dev Emits when the Carbon Credit contract has been updated
  event CarbonNftContractUpdated(ICarbonCreditNFT _newAddress);

  /// @dev Emits when the user's retire count for a given token ID is updated
  event RetireCountUpdated(address _owner, uint256 _tokenId, uint256 _amount);

  /// @dev Emits when a new token type is added
  event TokenTypeAdded(ISoulboundToken.TokenType _tokenType);

  /// @dev Emits when a new token type is removed
  event TokenTypeRemoved(uint256 _tokenId);

  //################
  //#### ERRORS ####
  /// @dev UnauthorizedCall throws an error if a call is made from an address without the correct role
  error UnauthorizedCall();

  /// @dev HasToken error is thrown if the target wallet for minting already has a token
  error HasToken();

  /// @dev TokenIdNotFound throws when passing a token ID into a function that does not exist
  error TokenIdNotFound();

  /// @dev NoTokenTypes throws if there have not been any token types added before trying to remove token types
  error NoTokenTypes();

  //##########################
  //#### CUSTOM FUNCTIONS ####
  /// @notice mints a new soulbound token
  /// @param _to the address to send the token to
  /// @param _imageURI the image URI for the token, to be included in the metadata
  function mint(address _to, string calldata _imageURI) external;

  /// @notice Increments the user's burned token count to be displayed in soulbound token metadata
  /// @param _user Address of the user whos burned count needs to be updated
  /// @param _tokenId The soulbound token ID owned by the user above
  /// @param _amount The amount by which to increase the user burned count
  function incrementRetireCount(
    address _user,
    uint256 _tokenId,
    uint256 _amount
  ) external;

  /// @notice returns all the current token types
  function getAllTokenTypes()
    external
    view
    returns (ISoulboundToken.TokenType[] memory);

  /// @notice adds a new token type
  /// @param _tokenType the data to add to the end of the token types array
  function addTokenType(TokenType calldata _tokenType) external;

  /// @notice removes token type from the array. If the token is not at the end of the array, the element at the end of the array is moved to the deleted item's position
  /// @param _tokenId the token ID of the token type, as from the CarbonCreditNFT
  function removeTokenType(uint256 _tokenId) external;

  /// @notice updates the carbon credit contract implementation
  /// @param _carbonCreditContract the new implementation of the carbon credit NFT
  function setCarbonCreditContract(
    ICarbonCreditNFT _carbonCreditContract
  ) external;

  /// @dev returns the current count of the token IDs (in other words, the next token ID to be minted)
  function getCurrentTokenId() external view returns (uint256);

  //###########################
  //#### ERC-721 FUNCTIONS ####
  /// @notice Returns the total amount of tokens for the provided user, can only ever be 0 or 1
  /// @param _owner An address for whom to query the balance
  /// @return The number of tokens owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Find the owner of a token
  /// @dev tokens assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for a token
  /// @return The address of the owner of the token
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice The name of the Account Bound Token contract
  function name() external view returns (string memory);

  /// @notice The symbol of the Account Bound Token contract
  function symbol() external view returns (string memory);

  /// @notice The symbol of the Account Bound Token contract
  function description() external view returns (string memory);

  /// @notice TokenURI contains metadata for the individual token as base64 encoded JSON object
  /// @param _tokenId The token to retrieve a metadata URI for
  function tokenURI(uint256 _tokenId) external view returns (string memory);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  /// @dev This function returns the address of the IMPT Access Manager contract
  ///@return implementation The address of the contract's associated AccessManager contract.
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);

  /// @dev returns the current implementatino of the Carbon Credit NFT contract
  function carbonCreditContract() external view returns (ICarbonCreditNFT);

  /// @dev returns the number of tokens of a particular token ID that a user has burned
  /// @param owner the user's address
  /// @param tokenId the token ID for which to return the burn counts
  function usersBurnedCounts(
    address owner,
    uint256 tokenId
  ) external view returns (uint256);
}