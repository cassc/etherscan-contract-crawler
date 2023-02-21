// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../implementations/ERC20Singleton.sol";
import "../implementations/Governor.sol";
import "../implementations/StakingRewards.sol";
import "../implementations/DonationsRouter.sol";
import "../implementations/DaoResellQueue.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../vendors/IWETH.sol";

/// @title Earth Fund Clearing House V2
/// @author Sean Long
/// @notice Used as part of the Earth Fund ecosystem to manage purchase and resell of DAO tokens
interface IClearingHouseV2 {
  //################
  //#### STRUCTS ###

  /// @notice Used to track cause DAO information
  /// @param release Unix time of when DAO tokens are released
  /// @param maxSupply Maximum supply of the DAO. **This may be able to be removed**
  /// @param maxPerUser Max amount of token per user
  /// @param exchangeRate Buy in rate for the DAO token
  /// @param childDaoRegistry Used to check if DAO is registered (hard coded to true by setter)
  /// @param autoStaking If tokens should automatically be staked
  /// @param kycEnabled If KYC is enabled for this cause
  /// @param paused Is this cause paused
  struct CauseInformation {
    uint256 release;
    uint256 maxSupply;
    uint256 maxPerUser;
    uint256 exchangeRate;
    bool childDaoRegistry;
    bool autoStaking;
    bool kycEnabled;
    bool paused;
  }
  /// @notice Input data for swapping a token
  /// @param sellToken The token that is being sold (taken) through the swap
  /// @param buyToken The token that is being bought (given to caller) through swap
  /// @param buyAmount The amount of tokenm to buy
  /// @param sellAmount The amount of token to sell
  /// @param spender The address taht will be taking the funds from the calling account
  /// @param swapTarget The address to send the actual call to
  /// @param swapTxData The transaction data to send to the target
  struct SwapData {
    ERC20 sellToken;
    ERC20 buyToken;
    uint256 buyAmount;
    uint256 sellAmount;
    address spender;
    address payable swapTarget;
    bytes swapTxData;
  }

  struct BuyInTokenData {
    ERC20 tokenAddress;
    uint8 decimals;
  }

  //################
  //#### EVENTS ####

  /// @notice Emitted when a Child DAO is registered
  event ChildDaoRegistered(address childDaoToken);

  /// @notice Emitted when a Child DAO token is purchased
  event DaoTokenPurchased(uint256 amount, address buyer, bool autoStake);

  /// @notice Emitted when max supply is set for a Child Dao
  event MaxSupplySet(uint256 maxSupply, ERC20Singleton token);

  /// @notice Emitted when max swap (effectively max per user) is set for a Child Dao
  event MaxSwapSet(uint256 maxSwap, ERC20Singleton token);

  //################
  //#### ERRORS ####
  /// @dev Thrown if an address value is the zero address
  error CannotBeZeroAddress();

  /// @dev Thrown if block.timestamp is greater than expiry in provided message for DAO purchase
  error ApprovalExpired();

  /// @dev Thrown if: message sig already used, message hashes don't match, recoverd signer of message != owner()
  error InvalidSignature();

  /// @dev Thrown if cumulative withdrawals would exceed maxPerUser w/ KYC on OR transaction purchase amount would exceed maxPerUser w/ KYC off
  error UserAmountExceeded();

  /// @dev Thrown if the child DAO is not registered
  error ChildDaoNotRegistered();

  /// @dev Thrown if release of the Child DAO token hasn't started yet
  error ChildDaoReleaseNotStarted();

  /// @dev Thrown if an account that isn't the DAO owner tries to change DAO configuration
  error AccountNotDaoOwner();

  /// @dev Thrown if a swap through 0x fails
  error ZeroXSwapFailed();

  /// @dev Thrown if ETH transfer fails
  error EthTransferFailed();

  /// @dev Thrown if the token being swap to (bought) is not the platform buyInToken
  error WrongBuyToken();

  /// @dev Thrown if the sell token != WETH when swapping ETH to buyInTOken
  error WrongSellToken();

  /// @dev Thrown if pausable operations of a Child DAO token are called while paused
  error CausePaused();

  /// @dev Thrown if the provided swap target does not match the known target stored in state
  error WrongSwapTarget();

  /// @dev Thrown if registerChildDao is called by an account != governor stored in state
  error AccountNotGovernor();

  //###################
  //#### FUNCTIONS ####

  /// @notice Used to register a child DAO
  /// @dev Only callable by Governor. Reverts if paused
  /// @param _childDaoToken Address of the Child DAO token
  /// @param _autoStaking Auto-stasking enabled
  /// @param _kycEnabled KYC enabled
  /// @param _maxSupply Max supply for DAO token
  /// @param _maxSwap Max amount of DAO token per user or per transaction if KYC is disabled
  /// @param _release Unix time tokens should be released
  /// @param _exchangeRate Amount of buyInToken tokens => 1 DAO token
  function registerChildDao(
    ERC20Singleton _childDaoToken,
    bool _autoStaking,
    bool _kycEnabled,
    uint256 _maxSupply,
    uint256 _maxSwap,
    uint256 _release,
    uint256 _exchangeRate
  ) external;

  /// @notice Used to purchase DAO token of a cause
  /// @dev Reverts if paused
  /// @param _childDaoToken Address of the DAO token to buy
  /// @param _amount Amount of token to buy
  /// @param _KYCId KYC ID generated by the back-end
  /// @param _expiry Expiry of the signature
  /// @param _signature Signature of the above parameters
  function purchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes memory _KYCId,
    uint256 _expiry,
    bytes memory _signature
  ) external;

  /// @notice Used to complete a 0x swap of any token to the platform buy in token and then use the swapped funds to purhcase DAO tokens
  /// @dev If the swap results in some sell tokens being left over these will be returned to the calling account
  /// @dev If the swap results in extra buy tokens these will be returned to the calling account
  /// @dev Must be called with 0x protocal quote info relevant to the swap being completed
  /// @param _childDaoToken Address of the DAO token to buy
  /// @param _amount Amount of token to buy
  /// @param _KYCId KYC ID generated by the back-end
  /// @param _expiry Expiry of the signature
  /// @param _signature Signature of the above parameters
  /// @param _swapData Swap data - see SwapData struct for further details
  function swapAndPurchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature,
    SwapData calldata _swapData
  ) external;

  /// @notice Used to complete a 0x swap of ETH to platform buy in token. This is achieved by wrapping and unwrapping ETH on the way in/out
  /// @dev If the swap results in left over ETH this will be unwrapped and returned to the calling account
  /// @dev If the swap results in extra buy tokens these will be returned to the calling account
  /// @param _childDaoToken Address of the DAO token to buy
  /// @param _amount Amount of token to buy
  /// @param _KYCId KYC ID generated by the back-end
  /// @param _expiry Expiry of the signature
  /// @param _signature Signature of the above parameters
  /// @param _swapData Swap data - see SwapData struct for further details
  function swapETHAndPurchaseToken(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes calldata _KYCId,
    uint256 _expiry,
    bytes memory _signature,
    SwapData calldata _swapData
  ) external payable;

  /// @notice Enable / disable auto-staking
  /// @dev Only callable by the cause owner
  /// @param _childDaoToken Address of the Child DAO token to change
  /// @param _state What to set it to
  function setAutoStake(ERC20Singleton _childDaoToken, bool _state) external;

  /// @notice Enable KYC for a cause
  /// @dev Only callable by the cause owner. Cannot be disabled
  /// @param _childDaoToken Address of the Child DAO token to change
  function enableKyc(ERC20Singleton _childDaoToken) external;

  /// @notice Set max amount of DAO token per user
  /// @dev Only callable by the cause owner
  /// @param _childDaoToken Address of the Child DAO token to change
  /// @param _max Maxmimum amount of tokens per user
  function setMaxPerUser(ERC20Singleton _childDaoToken, uint256 _max) external;

  /// @notice Set exchange rate (amount of token a user needs to swap per DAO token)
  /// @dev Only callable by the cause owner
  /// @param _childDaoToken Address of the Child DAO token to change
  /// @param _rate Exchange rate
  function setExchangeRate(ERC20Singleton _childDaoToken, uint256 _rate)
    external;

  /// @notice Pause a specific cause
  /// @dev Only callable by the cause owner
  /// @param _childDaoToken The address of the DAO token for the cause
  function pauseCause(ERC20Singleton _childDaoToken) external;

  /// @notice Unpause a specific cause
  /// @dev Only callable by the cause owner
  /// @param _childDaoToken The address of the DAO token for the cause
  function unpauseCause(ERC20Singleton _childDaoToken) external;

  /// @notice Set the donations router contract
  /// @dev Only callable by platform owner
  /// @param _implementation Contract address
  function setDonationsRouter(DonationsRouter _implementation) external;

  /// @notice Set the token the platform uses for DAO token buy in
  /// @dev Only callable by platform owner
  /// @param _implementation Contract address
  function setBuyInToken(ERC20 _implementation) external;

  /// @notice Set the staking contract
  /// @dev Only callable by platform owner
  /// @param _implementation Contract address
  function setStakingRewards(StakingRewards _implementation) external;

  /// @notice Pause the contract
  /// @dev Only callable by platform owner
  function pause() external;

  /// @notice Unpause the contract
  /// @dev Only callable by platform owner
  function unpause() external;

  /// @notice Set the 0x swap target
  /// @dev Used to prevent a user from having this contract execute calls on arbitrary contracts
  /// @param _implementation New address for the 0x exchange proxy contract
  function setSwapTarget(address _implementation) external;

  /// @notice Set the address of the governor contract
  /// @dev Only callable by platform owner
  /// @param _implementation Address of the governor implementation
  function setGovernor(address _implementation) external;

  /// @notice Sets the authenticated signer for kyc signature generation.
  /// @param _newSigner the new signer address
  function setAuthenticatedKYCSigner(address _newSigner) external;

  //################################
  //#### AUTO-GENERATED GETTERS ####

  function causeInformation(ERC20Singleton _causeToken)
    external
    view
    returns (
      uint256 release,
      uint256 maxSupply,
      uint256 maxPerUser,
      uint256 exchangeRate,
      bool childDaoRegistry,
      bool autoStaking,
      bool kycEnabled,
      bool paused
    );

  function withdrawnAmount(uint256 _causeId, bytes calldata _kycId)
    external
    view
    returns (uint256 amount);

  function donationsRouter()
    external
    view
    returns (DonationsRouter implementation);

  function staking() external view returns (StakingRewards implementation);

  function buyInToken()
    external
    view
    returns (ERC20 tokenAddress, uint8 decimals);

  function WETH() external view returns (IWETH implementaiton);

  function usedSignatures(bytes32 _message) external returns (bool used);

  function zeroXSwapTarget() external view returns (address _implementation);

  function governor() external view returns (address _implementation);
}