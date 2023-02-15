// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ICarbonCreditNFT.sol";
import "./ISoulboundToken.sol";
import "../vendors/IWETH.sol";

/// @title Interface for the SalesManager Smart Contract
/// @author Github: Labrys-Group
/// @notice Utilised to correctly route a user's swap transaction, enforcing constraints on permitted swapTargets and balance changes of known tokens.
/// @dev Checks balance change of IMPTToken == sellAmount
/// @dev Checks balance change of USDC is more than zero
/// @dev Utilises the internal Solidity Library `LibIMPT`
interface ISalesManager {
  //################
  //#### STRUCTS ###

  /// @dev Struct to hold authorisation parameters
  /// @param requestId bytes24 representing the request identifier from the IMPT back-end
  /// @param expiry uint40 representing the request UNIX expiry time
  /// @param sellAmount uint256 representing the amount of tokens to be sold
  /// @param tokenId the tokenId the user is purchasing
  /// @param amount amount of tokenId's to purchase
  /// @param expiry uint40 representing the request UNIX expiry time
  /// @param signature bytes representing the user's signature
  struct AuthorisationParams {
    bytes24 requestId;
    uint40 expiry;
    uint256 sellAmount;
    uint256 tokenId;
    uint256 amount;
    bytes signature;
  }

  /// @dev Struct to hold swap parameters
  /// @param spender address of the spender
  /// @param swapTarget address of the swap target
  /// @param swapCallData data for the swap call
  struct SwapParams {
    address spender;
    address swapTarget;
    bytes swapCallData;
  }

  /// @dev Struct to hold constructor parameters
  /// @param IMPTAddress address of the IMPT token contract
  /// @param USDCAddress address of the USDC token contract
  /// @param WETHAddress address of the WETH token contract
  /// @param CarbonCreditNFTContract address of the CarbonCreditNFT contract
  /// @param IMPTTreasuryAddress address of the IMPT treasury contract
  /// @param AccessManager  address of the IMPT Access Manager
  /// @param SoulboundToken address of the soulbound token contract
  struct ConstructorParams {
    IERC20Upgradeable IMPTAddress;
    IERC20Upgradeable USDCAddress;
    IWETH WETHAddress;
    ICarbonCreditNFT CarbonCreditNFTContract;
    address IMPTTreasuryAddress;
    IAccessManager AccessManager;
    ISoulboundToken SoulboundToken;
  }

  /// @dev Struct to hold swap return data
  /// @param IMPTDelta uint256 representing the change in the IMPT balance
  /// @param USDCDelta uint256 representing the change in the USDC balance
  struct SwapReturnData {
    uint256 IMPTDelta;
    uint256 USDCDelta;
  }

  //################
  //#### EVENTS ####

  /// @dev Event emitted when purchase is completed
  /// @param _requestId bytes24 representing the request identifier
  /// @param _purchaseAmount uint256 representing the amount of tokens purchased
  event PurchaseCompleted(bytes24 _requestId, uint256 _purchaseAmount);

  /// @dev Event emitted when the platform token is changed
  /// @param _implementation address of the new platform token contract
  event PlatformTokenChanged(IERC20Upgradeable _implementation);

  /// @dev Event emitted when the USDC token is changed
  /// @param _implementation address of the new USDC token contract
  event USDCChanged(IERC20Upgradeable _implementation);

  /// @dev Event emitted when the WETH token is changed
  /// @param _implementation address of the new WETH token contract
  event WETHChanged(IWETH _implementation);

  /// @dev Event emitted when the IMPT treasury is changed
  /// @param _implementation address of the new IMPT treasury contract
  event IMPTTreasuryChanged(address _implementation);

  /// @dev Event emitted whenever the CarbonCreditNFT contract is changed
  /// @param _implementation The new implementation of the CarbonCreditNFTcontract
  event CarbonCreditNFTContractChanged(ICarbonCreditNFT _implementation);

  /// @dev Event emitted whenever the Soulbound Token contract is changed
  /// @param _implementation The new implementation of the Soulbound Token contract
  event SoulboundTokenContractChanged(ISoulboundToken _implementation);

  /// @dev Event emitted when a soulbound token has been minted
  /// @param _owner the owner of a brand new soulbound token!
  /// @param _tokenId the soulbound token ID
  event SoulboundTokenMinted(address _owner, uint256 _tokenId);

  //################
  //#### ERRORS ####

  /// @dev Thrown when a swapTarget attemts to be called that doesn't hold IMPT_APPROVED_DEX role
  error UnauthorisedSwapTarget();
  /// @dev Thrown when the low-level call to the swapTarget fails
  error ZeroXSwapFailed();
  /// @dev Thrown if SwapReturnData.USDCDelta isn't > 0
  error WrongBuyTokenChange();
  /// @dev Thrown if IMPTDelta != AuthorisationParams.sellAmount
  error WrongSellTokenChange();

  //###################
  //#### FUNCTIONS ####
  //

  /// @dev Fallback function to receive payments
  receive() external payable;

  /// @notice Function to purchase tokens with IMPT
  /// @param _authorisationParams AuthorisationParams struct representing the authorisation parameters
  /// @param _swapParams SwapParams struct representing the swap parameters
  /// @dev Checks balance change of IMPT token == sellAmount
  /// @dev Checks balance change of USDC is more than zero
  /// @dev Uses OpenZeppelin AccessControl to restrict approved Decentralised Exchanges
  /// @dev Uses OpenZeppelin AccessControl to restrict approved IMPT Admins for setter functions
  /// @dev Utilises the internal Solidity Library `LibIMPT`
  function purchaseWithIMPT(
    AuthorisationParams calldata _authorisationParams,
    SwapParams calldata _swapParams
  ) external;

  /// @notice Function to purchase tokens with IMPT but does not swap from IMPT => USDC
  /// @param _authorisationParams AuthorisationParams struct representing the authorisation parameters
  function purchaseWithIMPTWithoutSwap(
    AuthorisationParams calldata _authorisationParams
  ) external;

  /// @notice Function to purchase a soulbound token
  /// @param _authorisationParams AuthorisationParams struct representing the authorisation parameters
  function purchaseSoulboundToken(
    AuthorisationParams calldata _authorisationParams,
    string memory _imageURI
  ) external;

  /// @notice Function to add a swap target
  /// @param _implementation address of the swap target contract
  /// @dev Can only be called by an approved IMPT admin
  function addSwapTarget(address _implementation) external;

  /// @notice Function to remove a swap target
  /// @param _implementation address of the swap target contract
  /// @dev Can only be called by an approved IMPT admin
  function removeSwapTarget(address _implementation) external;

  //##########################
  //#### SETTER-FUNCTIONS ####

  /// @notice Function to set the platform token contract
  /// @param _implementation address of the new platform token contract
  /// @dev Can only be called by an approved IMPT admin
  function setPlatformToken(IERC20Upgradeable _implementation) external;

  /// @notice Function to set the USDC token contract
  /// @param _implementation address of the new USDC token contract
  /// @dev Can only be called by an approved IMPT admin
  function setUSDC(IERC20Upgradeable _implementation) external;

  /// @notice Function to set the WETH token contract
  /// @param _implementation address of the new WETH token contract
  /// @dev Can only be called by an approved IMPT admin
  function setWETH(IWETH _implementation) external;

  /// @notice Function to set the IMPT treasury contract
  /// @param _implementation address of the new IMPT treasury contract
  /// @dev Can only be called by an approved IMPT admin
  function setIMPTTreasury(address _implementation) external;

  /// @dev Function to set the CarbonCreditNFT contract
  /// @param _carbonCreditNFT The new implementation of the CarbonCreditNFT contract.
  function setCarbonCreditNFT(ICarbonCreditNFT _carbonCreditNFT) external;

  /// @dev Function to set the Soulbound Token contract
  /// @param _soulboundToken The new implementation of the Soulbound Token contract.
  function setSoulboundToken(ISoulboundToken _soulboundToken) external;

  /// @dev This function allows the platform admin to pause the contract.
  function pause() external;

  /// @dev This function allows the platform admin to unpause the contract.
  function unpause() external;

  //################################
  //#### AUTO-GENERATED GETTERS ####

  /// @notice Function to get the address of the carbon credit NFT contract
  /// @return implementation address of the carbon credit NFT contract
  function CarbonCreditNFTContract()
    external
    returns (ICarbonCreditNFT implementation);

  /// @notice Function to get the address of the soulbound token contract
  /// @return implementation address of the soulbound token contract
  function SoulboundToken() external returns (ISoulboundToken implementation);

  /// @notice Function to get the address of the current platform token contract
  /// @return implementation address of the current platform token contract
  function IMPTAddress() external returns (IERC20Upgradeable implementation);

  /// @notice Function to get the address of the current USDC token contract
  /// @return implementation address of the current USDC token contract
  function USDCAddress() external returns (IERC20Upgradeable implementation);

  /// @notice Function to get the address of the current WETH token contract
  /// @return implementation address of the current WETH token contract
  function WETHAddress() external returns (IWETH implementation);

  /// @notice Function to get the address of the current IMPT treasury contract
  /// @return implementation address of the current IMPT treasury contract
  function IMPTTreasuryAddress() external returns (address implementation);

  /// @notice Function to check if a request has been used
  /// @param _requestId bytes24 representing the request identifier
  /// @return used bool indicating whether the request has been used or not
  function usedRequests(bytes24 _requestId) external returns (bool used);

  /// @dev This function returns the address of the IMPT Access Manager contract
  function AccessManager() external returns (IAccessManager implementation);
}