// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "../implementations/CarbonCreditNFT.sol";
import "./IAccessManager.sol";

interface IInventory {
  struct InventoryConstructorParams {
    address stableWallet;
    CarbonCreditNFT nftContract;
    IAccessManager AccessManager;
  }

  /// @dev stores the starge details for a particular token ID
  struct TokenDetails {
    uint256 totalSupply;
    uint256 tokensMinted;
    uint256 imptBurnCount;
  }

  //####################################
  //#### ERRORS #######################
  //####################################
  /// @dev reverts if the function is called by an unauthorized address
  error UnauthorizedCall();

  /// @dev reverts function if updating totals will result in negatives (to be used where functions might panic instead)
  error TotalMismatch();

  /// @dev reverts function if amount is less than 0
  error AmountMustBeMoreThanZero();

  /// @dev reverts a function if there is not enough total supply for a given token
  error NotEnoughSupply();

  //###################################
  //#### EVENTS #######################
  //###################################
  /// @dev emits when the burn count has been updated
  /// @param _tokenId the id of the token whose burn count has been updated
  /// @param _amount the number of tokens burned
  event BurnCountUpdated(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the burn count has been sent to Thallo
  /// @param _tokenId the id of the token whose burn count has been sent
  /// @param _amount the number of tokens sent to be burned by Thallo
  event BurnSent(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the burn count has been confirmed by Thallo
  /// @param _tokenId the id of the token whose burn count is confirmed
  /// @param _amount the amount of tokens confirmed burned by Thallo
  event BurnConfirmed(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the total supply has been sent by Thallo
  /// @param _tokenId the id of the token whose supply has been updated
  /// @param _newSupply the updated total supply of the token
  event TotalSupplyUpdated(uint256 indexed _tokenId, uint256 _newSupply);

  /// @dev emits when the stable wallet has been updated
  /// @param _newStableWallet the address of the new stable walelt
  event UpdateWallet(address _newStableWallet);

  //####################################
  //#### FUNCTIONS #####################
  //####################################
  /// @dev updates the total supply of a given token ID, as given by Thallo
  /// @param _tokenId the Carbon Credit NFT's token ID (ERC-1155)
  /// @param _amount the amount that the total will be set to
  function updateTotalSupply(uint256 _tokenId, uint256 _amount) external;

  /// @dev updates the total supply of a given token ID, as given by Thallo
  /// @param _tokenIds an array of the Carbon Credit NFT's token IDs (ERC-1155)
  /// @param _amounts an array of the amounts that the total will be set to
  function updateBulkTotalSupply(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) external;

  /// @dev returns the total supply of a given token ID
  /// @param _tokenIds an array of the Carbon Credit NFT's token IDs (ERC-1155)
  function getAllTokenDetails(
    uint256[] memory _tokenIds
  ) external view returns (TokenDetails[] memory);

  /// @dev updates the IMPT burn count when a carbon NFT is retired
  /// @param _tokenId the token ID for update burn counts for
  /// @param _amount the amount to increment the burn count by
  function incrementBurnCount(uint256 _tokenId, uint256 _amount) external;

  /// @dev this function calls the confirm burn counts and update total supply functions in a single transaction
  /// @param _tokenId the Carbon Credit NFT token ID
  /// @param _newTotalSupply the amount to which to total supply will be set
  /// @param _confirmedBurned the amount that Thallo has confirmed burned on their end
  function confirmAndUpdate(
    uint256 _tokenId,
    uint256 _newTotalSupply,
    uint256 _confirmedBurned
  ) external;

  function bulkConfirmAndUpdate(
    uint256[] memory _tokenIds,
    uint256[] memory _newTotalSupplies,
    uint256[] memory _confirmedBurns
  ) external;

  /// @dev Updates total when Thallo confirms the number of tokens burned to IMPT
  /// @param _tokenId the Carbon Credit NFT's token ID (ERC-1155)
  /// @param _amount the amount of tokens Thallo has burned
  function confirmBurnCounts(uint256 _tokenId, uint256 _amount) external;

  /// @dev Updates totals in bulk when Thallo confirms the number of tokens burned to IMPT
  /// @param _tokenIds the Carbon Credit NFT's token IDs (ERC-1155)
  /// @param _amounts the amounts of tokens Thallo has burned
  function bulkConfirmBurnCounts(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) external;

  /// @dev The wallet that is able to sign contracts on behalf of IMPT
  /// @param _stableWallet the wallet address
  function setStableWallet(address _stableWallet) external;

  /// @dev The wallet that is able to sign contracts on behalf of IMPT
  /// @param _nftContract the address of the carbon credit NFT
  function setNftContract(CarbonCreditNFT _nftContract) external;

  /// @dev decrements the total supply, to be called whenever carbon credit tokens are minted
  /// @param _tokenId the id of the token id that needs to be decremented
  /// @param _amount the amount by which to decrement the total supply
  function updateTotalMinted(uint256 _tokenId, uint256 _amount) external;

  //####################################
  //#### GETTERS #######################
  //####################################
  /// @dev The stable wallet is an admin-controlled wallet
  function stableWallet() external returns (address);

  /// @dev The nftContract is the Carbon Credit NFT
  function nftContract() external returns (CarbonCreditNFT);

  /// @dev This function returns the address of the IMPT Access Manager contract
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);
}