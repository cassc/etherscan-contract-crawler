// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC721Holder} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import {ERC1155PresetMinterPauser} from '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import {ERC1155Holder, ERC1155Receiver} from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {ERC677ReceiverInterface} from '@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol';
import {VRFV2WrapperInterface} from '@chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';
import {ILootboxFactory} from './interfaces/ILootboxFactory.sol';
import {IVRFV2Wrapper, AggregatorV3Interface} from './interfaces/IVRFV2Wrapper.sol';

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

/// @title Lootbox View
/// @author ChainSafe Systems: Oleksii (Functionality) Sneakz (Natspec assistance)

type RewardInfo is uint248; // 8 bytes unitsAvailable | 23 bytes amountPerUnit
uint constant UNITS_OFFSET = 8 * 23;

contract LootboxView is ERC721Holder, ERC1155Holder, ERC1155PresetMinterPauser {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using Address for address payable;
  using SafeCast for uint;

  /*//////////////////////////////////////////////////////////////
                                STATE
  //////////////////////////////////////////////////////////////*/

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

  ILootboxFactory public immutable FACTORY;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  VRFV2WrapperInterface public immutable VRF_V2_WRAPPER;
  address public immutable LINK;
  uint private constant LINK_UNIT = 1e18;

  uint public unitsSupply; // Supply of units.
  uint public unitsRequested; // Amount of units requested for opening.
  uint public unitsMinted; // Boxed units.
  uint private price; // Native currency needed to buy a lootbox.
  bool public isEmergencyMode; // State of emergency.
  EnumerableSet.UintSet private lootboxTypes; // Types of lootboxes.
  EnumerableSet.AddressSet private suppliers; // Supplier addresses being used.
  EnumerableSet.AddressSet private allowedTokens; // Tokens allowed for rewards.
  EnumerableSet.AddressSet private inventory; // Tokens available for rewards.
  mapping(address => mapping(uint => uint)) private allocated; // Token => TokenId => Balance. ERC20 and fungible ERC1155 allocated for claiming.
  mapping(address => Reward) private rewards; // Info about reward tokens.
  mapping(address => mapping(address => AllocationInfo)) private allocationInfo; // Claimer => Token => Info.
  mapping(address => EnumerableSet.UintSet) private extraIds; // ERC1155 internal token ids ever touching the lootbox.

  /// @notice LINK price must be positive from an oracle
  error InvalidLinkPrice(int value);

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

  /// @notice The VRF request IDs and their corresponding parameters as well as the randomness when fulfilled
  mapping(uint256 => Request) private requests;

  /// @notice The VRF request IDs and their corresponding openers
  mapping(address => uint256) public openerRequests;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploys a new Lootbox contract with the given parameters.
  /// @param _link The ChainLink LINK token address.
  /// @param _vrfV2Wrapper The ChainLink VRFV2Wrapper contract address.
  /// @param _factory The LootboxFactory contract address.
  constructor(
    address _link,
    address _vrfV2Wrapper,
    address payable _factory
  ) ERC1155PresetMinterPauser('') {
    FACTORY = ILootboxFactory(_factory);
    LINK_ETH_FEED = IVRFV2Wrapper(_vrfV2Wrapper).LINK_ETH_FEED();
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
    LINK = _link;
  }

  /*//////////////////////////////////////////////////////////////
                           BUY FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @notice Gets the native currency price to buy a lootbox.
  function getPrice() external view returns(uint) {
    return price;
  }

  /*//////////////////////////////////////////////////////////////
                          GETTER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

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

  /// @notice Gets number of units that still could be requested for opening.
  /// @dev Returns 0 during emergency.
  /// @return uint number of units.
  function getAvailableSupply() external view returns (uint) {
    if (isEmergencyMode) {
      return 0;
    }
    return unitsSupply - unitsRequested;
  }

  /// @notice Gets lootbox types that have been minted for the contract.
  /// @return uint Array of lootbox types that have been minted.
  function getLootboxTypes() external view returns (uint[] memory) {
    return lootboxTypes.values();
  }

  /// @notice Gets allowed reward tokens for the contract.
  /// @return address Array of reward tokens addresses if they exist and are allowed.
  function getAllowedTokens() external view returns (address[] memory) {
    return allowedTokens.values();
  }

  /// @notice Gets allowed token reward types for the contract.
  /// @return result Array of token reward types in the same order as getAllowedTokens().
  function getAllowedTokenTypes() external view returns (RewardType[] memory result) {
    uint len = allowedTokens.length();
    result = new RewardType[](len);
    for (uint i = 0; i < len; ++i) {
      result[i] = rewards[allowedTokens.at(i)].rewardType;
    }
    return result;
  }

  /// @notice Gets authorized suppliers for the contract.
  /// @return address Array of addresses if they exist and are allowed to supply.
  function getSuppliers() external view returns (address[] memory) {
    return suppliers.values();
  }

  /// @notice Gets allowed tokens for the contract.
  /// @param _token The token being allowed.
  /// @return bool True if the token if it exists and is allowed.
  function tokenAllowed(address _token) public view returns (bool) {
    return allowedTokens.contains(_token);
  }

  /// @notice Gets allowed supply address for the contract.
  /// @param _from The address of the supplier.
  /// @return bool True if the address of the supplier exists and is allowed.
  function supplyAllowed(address _from) public view returns (bool) {
    return suppliers.contains(_from);
  }

  /// @notice Calculates the opening price of lootboxes.
  /// @param _gas The gas of the request price. Safe estimate is number of reward units multiplied by 100,000 plus 50,000.
  /// @param _gasPriceInWei The gas price for the opening transaction.
  /// @param _units The units being calculated.
  /// @return uint The VRF price after calculation with units and fees.
  function calculateOpenPrice(uint32 _gas, uint _gasPriceInWei, uint _units) external view returns (uint) {
    uint vrfPrice = VRF_V2_WRAPPER.estimateRequestPrice(_gas, _gasPriceInWei);
    uint linkPrice = _getLinkPrice();
    uint vrfPriceNative = vrfPrice * linkPrice / LINK_UNIT;
    uint feePerUnit = FACTORY.feePerUnit(address(this));
    return vrfPriceNative + (_units * feePerUnit);
  }

  /// @notice Returns the tokens and amounts per unit of the lootbox.
  /// @return result The list of rewards available for getting.
  /// @return leftoversResult The list of rewards that are not configured or has insufficient supply.
  function getInventory() external view returns (RewardView[] memory result, RewardView[] memory leftoversResult) {
    uint tokens = inventory.length();
    result = new RewardView[](tokens);
    for (uint i = 0; i < tokens; ++i) {
      address token = inventory.at(i);
      result[i].rewardToken = token;
      Reward storage reward = rewards[token];
      RewardType rewardType = reward.rewardType;
      result[i].rewardType = rewardType;
      result[i].units = units(reward.rewardInfo);
      result[i].amountPerUnit = amountPerUnit(reward.rewardInfo);
      if (rewardType == RewardType.ERC20) {
        result[i].balance = result[i].units * result[i].amountPerUnit;
      }
      uint ids = reward.ids.length();
      result[i].extra = new ExtraRewardInfo[](ids);
      for (uint j = 0; j < ids; ++j) {
        uint id = reward.ids.at(j);
        result[i].extra[j].id = id;
        if (rewardType == RewardType.ERC1155) {
          result[i].extra[j].units = units(reward.extraInfo[id]);
          result[i].extra[j].amountPerUnit = amountPerUnit(reward.extraInfo[id]);
          result[i].extra[j].balance = result[i].extra[j].units * result[i].extra[j].amountPerUnit;
        }
      }
    }
    if (isEmergencyMode) {
      return (result, leftoversResult);
    }

    tokens = allowedTokens.length();
    leftoversResult = new RewardView[](tokens);
    uint k = 0;
    for (uint i = 0; i < tokens; ++i) {
      address token = allowedTokens.at(i);
      leftoversResult[k].rewardToken = token;
      Reward storage reward = rewards[token];
      RewardType rewardType = reward.rewardType;
      leftoversResult[k].rewardType = rewardType;
      leftoversResult[k].amountPerUnit = amountPerUnit(reward.rewardInfo);
      if (rewardType == RewardType.ERC20 || rewardType == RewardType.UNSET) {
        leftoversResult[k].balance =
          tryBalanceOfThis(token) - allocated[token][0]
          - (units(reward.rewardInfo) * leftoversResult[k].amountPerUnit);
        if (leftoversResult[k].balance > 0) {
          ++k;
        }
        continue;
      }
      if (rewardType == RewardType.ERC721 || rewardType == RewardType.ERC1155NFT) {
        if (inventory.contains(token)) {
          continue;
        }
        EnumerableSet.UintSet storage tokenIds = reward.ids;
        uint ids = tokenIds.length();
        if (ids == 0) {
          continue;
        }
        leftoversResult[k].extra = new ExtraRewardInfo[](ids);
        for (uint j = 0; j < ids; ++j) {
          leftoversResult[k].extra[j].id = tokenIds.at(j);
        }
      } else {
        // Same as with ERC20, ERC1155 could have a particular asset ID simultaneously in the inventory and leftovers.
        EnumerableSet.UintSet storage extraTokenIds = extraIds[token];
        ExtraRewardInfo[] memory extra = new ExtraRewardInfo[](extraTokenIds.length());
        uint l = 0;
        for (uint j = 0; j < extraTokenIds.length(); ++j) {
          uint id = extraTokenIds.at(j);
          extra[l].id = id;
          extra[l].amountPerUnit = amountPerUnit(reward.extraInfo[id]);
          extra[l].balance = IERC1155(token).balanceOf(address(this), id) - allocated[token][id]
            - (units(reward.extraInfo[id]) * extra[l].amountPerUnit);
          if (extra[l].balance == 0) {
            continue;
          }
          ++l;
        }
        if (l == 0) {
          continue;
        }
        // Shrink the leftovers extra array to its actual size.
        assembly {
          mstore(extra, l)
        }
        leftoversResult[k].extra = extra;
      }

      ++k;
    }
    // Shrink the leftovers array to its actual size.
    assembly {
      mstore(leftoversResult, k)
    }
    return (result, leftoversResult);
  }

  /// @notice Returns whether the rewards for the given opener can be claimed.
  /// @param _opener The address of the user that opened the lootbox.
  /// @return bool True if claim is possible, otherwise false.
  function canClaimRewards(address _opener) public view returns (bool) {
    uint ids = allowedTokens.length();
    for (uint i = 0; i < ids; ++i) {
      address token = allowedTokens.at(i);
      RewardType rewardType = rewards[token].rewardType;
      if (rewardType == RewardType.ERC20) {
        if (allocationInfo[_opener][token].amount[0] > 0) {
          return true;
        }
      } else {
        if (allocationInfo[_opener][token].ids.length() > 0) {
          return true;
        }
      }
    }
    return false;
  }

  /// @notice Returns details of the lootbox open request.
  /// @notice If request is not empty but unitsToGet == 0, then user need to recoverBoxes().
  /// @param _opener The address of the user that opened the lootbox.
  /// @return request empty if there are no pending request.
  function getOpenerRequestDetails(address _opener) public view returns (Request memory request) {
    uint requestId = openerRequests[_opener];
    if (requestId == 0) {
      return request;
    }
    return requests[requestId];
  }

  /// @notice Gets the LINK token address.
  /// @return address The address of the LINK token.
  function getLink() external view returns (address) {
    return address(LINK);
  }

  /// @notice Gets the VRF wrapper for the contract.
  /// @return address The address of the VRF wrapper.
  function getVRFV2Wrapper() external view returns (address) {
    return address(VRF_V2_WRAPPER);
  }

  function getLinkPrice() external view returns (uint) {
    return _getLinkPrice();
  }

  /// @notice Checks the balance of an erc20 token.
  /// @param _token The token being checked.
  /// @return uint erc20 token balance, else 0 if not an erc20 token.
  function tryBalanceOfThis(address _token) internal view returns (uint) {
    try IERC20(_token).balanceOf(address(this)) returns(uint result) {
      return result;
    } catch {
      // not an ERC20 so has to transfer first.
      return 0;
    }
  }

  /// @notice Gets LINK price.
  /// @return uint The link price from wei converted to uint.
  function _getLinkPrice() internal view returns (uint) {
    int256 weiPerUnitLink;
    (, weiPerUnitLink, , , ) = LINK_ETH_FEED.latestRoundData();
    if (weiPerUnitLink <= 0) revert InvalidLinkPrice(weiPerUnitLink);
    return uint(weiPerUnitLink);
  }

  /// @notice Checks units by by reward information.
  /// @param _rewardInfo The reward information.
  /// @return RewardInfo Reward information as uint.
  function units(RewardInfo _rewardInfo) internal pure returns (uint) {
    return RewardInfo.unwrap(_rewardInfo) >> UNITS_OFFSET;
  }

  /// @notice Checks amount per unity by reward information.
  /// @param _rewardInfo The reward information.
  /// @return RewardInfo Reward information as uint.
  function amountPerUnit(RewardInfo _rewardInfo) internal pure returns (uint) {
    return uint184(RewardInfo.unwrap(_rewardInfo));
  }

  /// @notice Checks amount per unity by reward information.
  /// @param _units The reward information.
  /// @param _amountPerUnit The amount per unit.
  /// @return RewardInfo Reward information or amounts per unit.
  function toInfo(uint _units, uint _amountPerUnit) internal pure returns (RewardInfo) {
    return RewardInfo.wrap(uint248((_units << UNITS_OFFSET) | _amountPerUnit));
  }

  /// @notice Checks if reward information is empty.
  /// @param _rewardInfo The reaward information.
  /// @return RewardInfo Empty reward information.
  function isEmpty(RewardInfo _rewardInfo) internal pure returns (bool) {
    return RewardInfo.unwrap(_rewardInfo) == 0;
  }

  /// @notice Returns value bool.
  /// @param _value Boolean value.
  /// @return bool Opposite bool value.
  function _not(bool _value) internal pure returns (bool) {
    return !_value;
  }

  function supportsInterface(bytes4)
    public
    view
    virtual
    override(ERC1155Receiver, ERC1155PresetMinterPauser)
    returns (bool)
  {
    return false;
  }
}