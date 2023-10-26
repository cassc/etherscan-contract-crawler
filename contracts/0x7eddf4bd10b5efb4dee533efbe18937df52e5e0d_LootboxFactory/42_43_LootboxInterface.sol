// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155PresetMinterPauser} from '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import {ERC721Holder} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import {ERC1155Holder, ERC1155Receiver} from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ILootboxFactory} from './interfaces/ILootboxFactory.sol';
import {IVRFV2Wrapper, AggregatorV3Interface} from './interfaces/IVRFV2Wrapper.sol';
import {RewardInfo} from './Lootbox.sol';

//  $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$\ $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$$\ 
// $$  __$$\ $$ |  $$ |$$  __$$\ \_$$  _|$$$\  $$ |$$  __$$\ $$  __$$\ $$  _____|$$  _____|
// $$ /  \__|$$ |  $$ |$$ /  $$ |  $$ |  $$$$\ $$ |$$ /  \__|$$ /  $$ |$$ |      $$ |      
// $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |  $$ $$\$$ |\$$$$$$\  $$$$$$$$ |$$$$$\    $$$$$\    
// $$ |      $$  __$$ |$$  __$$ |  $$ |  $$ \$$$$ | \____$$\ $$  __$$ |$$  __|   $$  __|   
// $$ |  $$\ $$ |  $$ |$$ |  $$ |  $$ |  $$ |\$$$ |$$\   $$ |$$ |  $$ |$$ |      $$ |      
// \$$$$$$  |$$ |  $$ |$$ |  $$ |$$$$$$\ $$ | \$$ |\$$$$$$  |$$ |  $$ |$$ |      $$$$$$$$\ 
//  \______/ \__|  \__|\__|  \__|\______|\__|  \__| \______/ \__|  \__|\__|      \________|                                                                                                                                                                              
                                                                                        
// $$\       $$$$$$\   $$$$$$\ $$$$$$$$\ $$$$$$$\   $$$$$$\  $$\   $$\ $$$$$$$$\  $$$$$$\  
// $$ |     $$  __$$\ $$  __$$\\__$$  __|$$  __$$\ $$  __$$\ $$ |  $$ |$$  _____|$$  __$$\ 
// $$ |     $$ /  $$ |$$ /  $$ |  $$ |   $$ |  $$ |$$ /  $$ |\$$\ $$  |$$ |      $$ /  \__|
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$\ |$$ |  $$ | \$$$$  / $$$$$\    \$$$$$$\  
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$  __$$\ $$ |  $$ | $$  $$<  $$  __|    \____$$\ 
// $$ |     $$ |  $$ |$$ |  $$ |  $$ |   $$ |  $$ |$$ |  $$ |$$  /\$$\ $$ |      $$\   $$ |
// $$$$$$$$\ $$$$$$  | $$$$$$  |  $$ |   $$$$$$$  | $$$$$$  |$$ /  $$ |$$$$$$$$\ \$$$$$$  |
// \________|\______/  \______/   \__|   \_______/  \______/ \__|  \__|\________| \______/ 

/// @title Lootbox Interface to combine Lootbox implementation and View contracts.
/// @author ChainSafe Systems: Oleksii (Functionality) Sneakz (Natspec assistance)

abstract contract LootboxInterface is VRFV2WrapperConsumerBase, ERC721Holder, ERC1155Holder, ERC1155PresetMinterPauser {
  enum RewardType {
    UNSET,
    ERC20,
    ERC721,
    ERC1155,
    ERC1155NFT
  }

  struct Reward {
    RewardType rewardType;
    RewardInfo rewardInfo;
    EnumerableSet.UintSet ids; // only 721 and 1155
    mapping(uint => RewardInfo) extraInfo; // only for 1155
  }

  struct AllocationInfo {
    EnumerableSet.UintSet ids;
    mapping(uint => uint) amount; // id 0 for ERC20
  }

  ILootboxFactory public FACTORY;
  AggregatorV3Interface public LINK_ETH_FEED;

  uint public unitsSupply; // Supply of units.
  uint public unitsRequested; // Amount of units requested for opening.
  uint public unitsMinted; // Boxed units.
  bool public isEmergencyMode; // State of emergency.

  /*//////////////////////////////////////////////////////////////
                             VRF RELATED
  //////////////////////////////////////////////////////////////*/

  /// @notice The VRF request struct
  struct Request {
    address opener;
    uint96 unitsToGet;
    uint[] lootIds;
    uint[] lootAmounts;
  }

  /// @notice The VRF request IDs and their corresponding openers
  mapping(address => uint256) public openerRequests;

  struct ExtraRewardInfo {
    uint id;
    uint units;
    uint amountPerUnit;
    uint balance;
  }

  struct RewardView {
    address rewardToken;
    RewardType rewardType;
    uint units;
    uint amountPerUnit;
    uint balance;
    ExtraRewardInfo[] extra;
  }

  /*//////////////////////////////////////////////////////////////
                                EVENTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Emitted when a lootbox is openning is requested
  /// @param opener The address of the user that requested the open
  /// @param unitsToGet The amount of lootbox units to receive
  /// @param requestId The ID of the VRF request
  event OpenRequested(address opener, uint256 unitsToGet, uint256 requestId);

  /// @notice Emitted when a randomness request is fulfilled and the lootbox rewards can be claimed
  /// @param requestId The ID of the VRF request
  /// @param randomness The random number that was generated
  event OpenRequestFulfilled(uint256 requestId, uint256 randomness);

  /// @notice Emitted when a randomness request ran out of gas and now must be recovered
  /// @param requestId The ID of the VRF request
  event OpenRequestFailed(uint256 requestId, bytes reason);

  event SupplierAdded(address supplier);

  event SupplierRemoved(address supplier);

  /// @notice Emitted when a new reward token gets whitelisted for supply
  event TokenAdded(address token);

  /// @notice Emitted when a reward token amount per unit changes
  /// @param newSupply The new supply of reward units available
  event AmountPerUnitSet(address token, uint tokenId, uint amountPerUnit, uint newSupply);

  /// @notice Emitted when the lootbox rewards are claimed
  /// @param opener The address of the user that received the rewards
  /// @param token The rewarded token contract address
  /// @param tokenId The internal tokenId for ERC721 and ERC1155
  /// @param amount The amount of claimed tokens
  event RewardsClaimed(address opener, address token, uint tokenId, uint amount);

  /// @notice Emitted when the lootbox rewards are allocated
  /// @param opener The address of the user that received the allocation
  /// @param token The rewarded token contract address
  /// @param tokenId The internal tokenId for ERC721 and ERC1155
  /// @param amount The amount of allocated tokens
  event Allocated(address opener, address token, uint tokenId, uint amount);

  /// @notice Emitted when the lootboxes gets recovered from a failed open request
  /// @param opener The address of the user that received the allocation
  /// @param requestId The ID of the VRF request
  event BoxesRecovered(address opener, uint requestId);

  /// @notice Emitted when the contract stops operation and assets being withdrawn by the admin
  /// @param caller The address of the admin who initiated the emergency
  event EmergencyModeEnabled(address caller);

  /// @notice Emitted when an admin withdraws assets in case of emergency
  /// @param token The token contract address
  /// @param tokenType The type of asset of token contract
  /// @param to The address that received the withdrawn assets
  /// @param ids The internal tokenIds for ERC721 and ERC1155
  /// @param amounts The amounts of withdrawn tokens/ids
  event EmergencyWithdrawal(address token, RewardType tokenType, address to, uint[] ids, uint[] amounts);

  /// @notice Emitted when an admin withdraws ERC20 or native currency
  /// @param token The token contract address or zero for native currency
  /// @param to The address that received the withdrawn assets
  /// @param amount The amount withdrawn
  event Withdraw(address token, address to, uint amount);

  /// @notice Emitted when an admin sets purchase price
  /// @param newPrice The amount of native currency to pay to buy a lootbox, or 0 if disabled
  event PriceUpdated(uint newPrice);

  /// @notice Emitted when user buys lootboxes
  /// @param buyer The address of the user that purchased lootboxes
  /// @param amount The amount of id 1 lootboxes sold
  /// @param payment The amount of native currency user paid
  event Sold(address buyer, uint amount, uint payment);

  /*//////////////////////////////////////////////////////////////
                                ERRORS
  //////////////////////////////////////////////////////////////*/

  /// @notice There are no tokens to put in the lootbox
  error NoTokens();

  /// @notice The tokens array length does not match the perUnitAmounts array length
  error InvalidLength();

  /// @notice Supplying 1155NFT with amount > 1
  error InvalidTokenAmount();

  /// @notice The amount to open is zero
  error ZeroAmount();

  /// @notice Token not allowed as reward
  error TokenDenied(address token);

  /// @notice Deposits only allowed from whitelisted addresses
  error SupplyDenied(address from);

  /// @notice The amount to open exceeds the supply
  error SupplyExceeded(uint256 supply, uint256 unitsToGet);

  /// @notice The new supply amount is less than already requested to open
  error InsufficientSupply(uint256 supply, uint256 requested);

  /// @notice Has to finish the open request first
  error PendingOpenRequest(uint256 requestId);

  /// @notice Has to open some lootboxes first
  error NothingToClaim();

  /// @notice Reward type is immutable
  error ModifiedRewardType(RewardType oldType, RewardType newType);

  /// @notice Only LINK could be sent with an ERC677 call
  error AcceptingOnlyLINK();

  /// @notice Not enough pay for a VRF request
  error InsufficientPayment();

  /// @notice Not enough pay for a lootbox opening fee
  error InsufficientFee();

  /// @notice There should be a failed VRF request for recovery
  error NothingToRecover();

  /// @notice LINK price must be positive from an oracle
  error InvalidLinkPrice(int value);

  /// @notice Zero value ERC1155 supplies are not alloved
  error ZeroSupply(address token, uint id);

  /// @notice Function could only be called by this contract itself
  error OnlyThis();

  /// @notice Unexpected reward type for current logic
  error UnexpectedRewardType(RewardType rewardType);

  /// @notice Units should fit in 64 bits
  error UnitsOverflow(uint value);

  /// @notice Amount per unit should fit in 184 bits
  error AmountPerUnitOverflow(uint value);

  /// @notice Token id was already present in the inventory with units set to 0
  error DepositStateCorruption(address token, uint tokenId);

  /// @notice Token was already present in the inventory with units set to 0
  error InventoryStateCorruption(address token);

  /// @notice Not enough gas is provided for opening
  error InsufficientGas();

  /// @notice Lootbox id represents the number of rewrad units it will produce, so it should be > 0 and < 256
  error InvalidLootboxType();

  /// @notice The request is either already failed/fulfilled or was never created
  error InvalidRequestAllocation(uint requestId);

  /// @notice Requested operation is not supported in current version
  error Unsupported();

  /// @notice Token is allowed as reward and cannot be withdrawn
  error RewardWithdrawalDenied(address token);

  /// @notice Contrat was put into emergency mode and stopped operations
  error EndOfService();

  /// @notice View function reverted without reason
  error ViewCallFailed();

  /// @notice Purchase price is unexpectedly high or zero
  error UnexpectedPrice(uint currentPrice);

  /// @notice Caller does not have required role
  error AccessDenied(bytes32 role);

  /// @notice Sets the URI for the contract.
  /// @param _baseURI The base URI being used.
  function setURI(string memory _baseURI) external virtual;

  /// @notice Adds loot suppliers.
  /// @param _suppliers An array of loot suppliers being added.
  function addSuppliers(address[] calldata _suppliers) external virtual;

  /// @notice Removes contract suppliers.
  /// @param _suppliers An array of suppliers being removed.
  function removeSuppliers(address[] calldata _suppliers) external virtual;

  /// @notice Adds tokens for lootbox usage.
  /// @param _tokens An array of tokens being added.
  function addTokens(address[] calldata _tokens) external virtual;

  /// @notice Sets the how much of a token you get per lootbox.
  /// @dev Stops working during the emergency.
  /// @param _tokens An array of tokens being added.
  /// @param _ids An array of ids being added.
  /// @param _amountsPerUnit An array of amounts being added.
  function setAmountsPerUnit(address[] calldata _tokens, uint[] calldata _ids, uint[] calldata _amountsPerUnit) external virtual;

  function emergencyWithdraw(address _token, RewardType _type, address _to, uint[] calldata _ids, uint[] calldata _amounts) external virtual;

  /// @notice Requests a lootbox openning paying with native currency
  /// @param _gas Gas limit for allocation
  /// @param _lootIds Lootbox ids to open
  /// @param _lootAmounts Lootbox amounts to open
  function open(uint32 _gas, uint[] calldata _lootIds, uint[] calldata _lootAmounts) external payable virtual;

  /// @notice Claims the rewards for the lootbox openning.
  /// @dev The user must have some rewards allocated.
  /// @param _opener The address of the user that has an allocation after opening.
  function claimRewards(address _opener) external virtual;


  /*//////////////////////////////////////////////////////////////
                           BUY FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @notice Sets the native currency price to buy a lootbox.
  /// @notice Set to 0 to prevent sales.
  /// @param _newPrice An amount of native currency user needs to pay to get a single lootbox.
  function setPrice(uint _newPrice) external virtual;

  /// @notice Gets the native currency price to buy a lootbox.
  function getPrice() external view virtual returns(uint);

  /// @notice Mints requested amount of lootboxes for the caller assuming valid payment.
  /// @notice Remainder is sent back to the caller.
  /// @param _amount An amount lootboxes to mint.
  /// @param _maxPrice A maximum price the caller is willing to pay per lootbox.
  function buy(uint _amount, uint _maxPrice) external payable virtual;

  /// @notice Used to recover lootboxes for an address.
  /// @param _opener The address that opened the boxes.
  function recoverBoxes(address _opener) external virtual;

  /// @notice Picks the rewards using the given randomness as a seed.
  /// @param _requestId The amount of lootbox units the user is opening.
  /// @param _randomness The random number used to pick the rewards.
  function _allocateRewards(uint256 _requestId, uint256 _randomness) external virtual;

  /*//////////////////////////////////////////////////////////////
                          GETTER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function viewCall() external virtual;

  /// @notice Transfer the contract balance to the owner.
  /// @dev Allowed for rewards tokens cannot be withdrawn.
  /// @param _token The token contract address or zero for native currency.
  /// @param _to The receiver address or zero for caller address.
  /// @param _amount The amount of token to withdraw or zero for full amount.
  function withdraw(address _token, address payable _to, uint _amount) external virtual;

  function mintToMany(address[] calldata _tos, uint[] calldata _lootboxTypes, uint[] calldata _amounts) external virtual;

  /// @notice Gets number of units that still could be requested for opening.
  /// @dev Returns 0 during emergency.
  /// @return uint number of units.
  function getAvailableSupply() external virtual view returns (uint);

  /// @notice Gets lootbox types that have been minted for the contract.
  /// @return uint Array of lootbox types that have been minted.
  function getLootboxTypes() external virtual view returns (uint[] memory);

  /// @notice Gets allowed reward tokens for the contract.
  /// @return address Array of reward tokens addresses if they exist and are allowed.
  function getAllowedTokens() external virtual view returns (address[] memory);

  /// @notice Gets allowed token reward types for the contract.
  /// @return result Array of token reward types in the same order as getAllowedTokens().
  function getAllowedTokenTypes() external virtual view returns (RewardType[] memory result);

  /// @notice Gets authorized suppliers for the contract.
  /// @return address Array of addresses if they exist and are allowed to supply.
  function getSuppliers() external virtual view returns (address[] memory);

  /// @notice Gets allowed tokens for the contract.
  /// @param _token The token being allowed.
  /// @return bool True if the token if it exists and is allowed.
  function tokenAllowed(address _token) external virtual view returns (bool);

  /// @notice Gets allowed supply address for the contract.
  /// @param _from The address of the supplier.
  /// @return bool True if the address of the supplier exists and is allowed.
  function supplyAllowed(address _from) external virtual view returns (bool);

  /// @notice Calculates the opening price of lootboxes.
  /// @param _gas The gas of the request price.
  /// @param _gasPriceInWei The gas price for the opening transaction.
  /// @param _units The units being calculated.
  /// @return uint The VRF price after calculation with units and fees.
  function calculateOpenPrice(uint32 _gas, uint _gasPriceInWei, uint _units) external virtual view returns (uint);

  /// @notice Returns the tokens and amounts per unit of the lootbox.
  /// @return result The list of rewards available for getting.
  /// @return leftoversResult The list of rewards that are not configured or has insufficient supply.
  function getInventory() external virtual view returns (RewardView[] memory result, RewardView[] memory leftoversResult);

  /// @notice Returns whether the rewards for the given opener can be claimed.
  /// @param _opener The address of the user that opened the lootbox.
  /// @return bool True if claim is possible, otherwise false.
  function canClaimRewards(address _opener) public view virtual returns (bool);

  /// @notice Returns details of the lootbox open request.
  /// @notice If request is not empty but unitsToGet == 0, then user need to recoverBoxes().
  /// @param _opener The address of the user that opened the lootbox.
  /// @return request empty if there are no pending request.
  function getOpenerRequestDetails(address _opener) external virtual view returns (Request memory request);

  /// @notice Gets the LINK token address.
  /// @return address The address of the LINK token.
  function getLink() external view virtual returns (address);

  /// @notice Gets the VRF wrapper for the contract.
  /// @return address The address of the VRF wrapper.
  function getVRFV2Wrapper() external view virtual returns (address);

  function getLinkPrice() external view virtual returns (uint);

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Receiver, ERC1155PresetMinterPauser)
    returns (bool)
  {
    return ERC1155Receiver.supportsInterface(interfaceId) ||
      ERC1155PresetMinterPauser.supportsInterface(interfaceId);
  }
}