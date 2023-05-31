//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {Owner} from "utils/Owner.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Errors} from "utils/Errors.sol";
import {IHarvestable} from "interfaces/IHarvestable.sol";
import {IMinter} from "interfaces/IMinter.sol";
import {IStaker} from "interfaces/IStaker.sol";
import {IFarmer} from "interfaces/IFarmer.sol";
import {IIncentivizedLocker} from "interfaces/IIncentivizedLocker.sol";
import "interfaces/external/incentives/IIncentivesDistributors.sol";

/**
 * @title Warlord Controller contract
 * @author Paladin
 * @notice Controller to harvest from Locker & Farmer and process the rewards for distribution
 */
contract WarController is ReentrancyGuard, Pausable, Owner {
  using SafeERC20 for IERC20;

  // Constants

  /**
   * @notice 1e18 scale
   */
  uint256 public constant UNIT = 1e18;
  /**
   * @notice Max BPS value (100%)
   */
  uint256 public constant MAX_BPS = 10_000;

  // Storage

  /**
   * @notice Address of the WAR token
   */
  address public immutable war;
  /**
   * @notice Address of the Minter contract
   */
  IMinter public minter;
  /**
   * @notice Address of the Staker contract
   */
  IStaker public staker;
  /**
   * @notice Address of the Swap manager
   */
  address public swapper;
  /**
   * @notice Address of the Incentives Claimer
   */
  address public incentivesClaimer;
  /**
   * @notice Ratio of fees taken on harvested rewards
   */
  uint256 public feeRatio = 500;
  /**
   * @notice Address to receive the fees
   */
  address public feeReceiver;
  /**
   * @notice List of Lockers contract
   */
  address[] public lockers;
  /**
   * @notice List of Farmers contract
   */
  address[] public farmers;

  /**
   * @notice Address of the Locker for a token
   */
  mapping(address => address) public tokenLockers;
  /**
   * @notice Address of the Farmer for a token
   */
  mapping(address => address) public tokenFarmers;
  /**
   * @notice Tokens set for pure distribution (and that does not have a Locker or a Farmer contract)
   */
  mapping(address => bool) public distributionTokens;
  /**
   * @notice Amounts of tokens available for swaps to WETH
   */
  mapping(address => uint256) public swapperAmounts;
  /**
   * @notice Contracts that the controller can harvest
   */
  mapping(address => bool) public harvestable;

  // Events

  /**
   * @notice Event emitted when tokens are pulled
   */
  event PullTokens(address indexed swapper, address indexed token, uint256 amount);
  /**
   * @notice Event emitted when the Minter address is set
   */
  event SetMinter(address oldMinter, address newMinter);
  /**
   * @notice Event emitted when the Staker address is set
   */
  event SetStaker(address oldStaker, address newStaker);
  /**
   * @notice Event emitted when the Swapper address is updated
   */
  event SetSwapper(address oldSwapper, address newSwapper);
  /**
   * @notice Event emitted when the Fee Receiver address is updated
   */
  event SetFeeReceiver(address oldFeeReceiver, address newFeeReceiver);
  /**
   * @notice Event emitted when the Incentives Claimer address is updated
   */
  event SetIncentivesClaimer(address oldIncentivesClaimer, address newIncentivesClaimer);
  /**
   * @notice Event emitted when the Fee Ratio is updated
   */
  event SetFeeRatio(uint256 oldFeeRatio, uint256 newFeeRatio);
  /**
   * @notice Event emitted when a Locker is set
   */
  event SetLocker(address indexed token, address locker);
  /**
   * @notice Event emitted when a Farmer is set
   */
  event SetFarmer(address indexed token, address famer);
  /**
   * @notice Event emitted when a token is set for distribution
   */
  event SetDistributionToken(address indexed token, bool distribution);
  /**
   * @notice Event emitted when a contract harvestability is updated
   */
  event SetHarvestable(address harvestable, bool enabled);

  // Modifiers

  /**
   * @notice Checks the caller is the Swapper address
   */
  modifier onlySwapper() {
    if (msg.sender != swapper) revert Errors.CallerNotAllowed();
    _;
  }

  /**
   * @notice Checks the address is the Incentives Claimer address
   */
  modifier onlyIncentivesClaimer() {
    if (msg.sender != incentivesClaimer) revert Errors.CallerNotAllowed();
    _;
  }

  // Constructor

  constructor(
    address _war,
    address _minter,
    address _staker,
    address _swapper,
    address _incentivesClaimer,
    address _feeReceiver
  ) {
    if (
      _war == address(0) || _minter == address(0) || _staker == address(0) || _swapper == address(0)
        || _incentivesClaimer == address(0) || _feeReceiver == address(0)
    ) revert Errors.ZeroAddress();

    war = _war;
    swapper = _swapper;
    minter = IMinter(_minter);
    staker = IStaker(_staker);
    incentivesClaimer = _incentivesClaimer;
    feeReceiver = _feeReceiver;
  }

  // State changing functions
  function _harvest(address target) internal {
    if (!harvestable[target]) revert Errors.HarvestNotAllowed();
    IHarvestable(target).harvest();
  }

  /**
   * @notice Harvests rewards from a given Harvestable contract
   * @param target Address of the contract to harvest from
   */
  function harvest(address target) external nonReentrant whenNotPaused {
    _harvest(target);
  }

  /**
   * @notice Harvests rewards from Harvestable contracts
   * @param targets List of contracts to harvest from
   */
  function harvestMultiple(address[] calldata targets) external nonReentrant whenNotPaused {
    uint256 length = targets.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      _harvest(targets[i]);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Harvest from all listed Harvestable contracts (Locker & Farmers)
   */
  function harvestAll() external nonReentrant whenNotPaused {
    address[] memory _lockers = lockers;
    address[] memory _farmers = farmers;
    uint256 lockersLength = _lockers.length;
    uint256 farmersLength = _farmers.length;

    // Harvest from all listed Lockers
    for (uint256 i; i < lockersLength;) {
      _harvest(_lockers[i]);

      unchecked {
        i++;
      }
    }

    // Harvest from all listed Farmers
    for (uint256 i; i < farmersLength;) {
      _harvest(_farmers[i]);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Processes a token held in this contract
   * @param token Address of the token to process
   */
  function process(address token) external nonReentrant whenNotPaused {
    _processReward(token);
  }

  /**
   * @notice Processes tokens held in this contract
   * @param tokens List of tokens to process
   */
  function processMultiple(address[] calldata tokens) external nonReentrant whenNotPaused {
    _processMultiple(tokens);
  }

  /**
   * @notice Harvests rewards from a given Harvestable contract & process the received rewards
   * @param target Address of the contract to harvest from
   */
  function harvestAndProcess(address target) external nonReentrant whenNotPaused {
    IHarvestable(target).harvest();

    _processMultiple(IHarvestable(target).rewardTokens());
  }

  /**
   * @notice Harvest from all listed Harvestable contracts (Locker & Farmers) & process the received rewards
   */
  function harvestAllAndProcessAll() external nonReentrant whenNotPaused {
    address[] memory _lockers = lockers;
    address[] memory _farmers = farmers;
    uint256 lockersLength = _lockers.length;
    uint256 farmersLength = _farmers.length;

    // Harvest & process for each Locker
    for (uint256 i; i < lockersLength;) {
      IHarvestable(_lockers[i]).harvest();

      _processMultiple(IHarvestable(_lockers[i]).rewardTokens());

      unchecked {
        i++;
      }
    }

    // Harvest & process for each Farmer
    for (uint256 i; i < farmersLength;) {
      IHarvestable(_farmers[i]).harvest();

      _processMultiple(IHarvestable(_farmers[i]).rewardTokens());

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Pulls a token to be swapped to WETH
   * @param token Address of the token to pull
   */
  function pullToken(address token) external nonReentrant whenNotPaused onlySwapper {
    _pullToken(token);
  }

  /**
   * @notice Pulls tokens to be swapped to WETH
   * @param tokens List of tokens to pull
   */
  function pullMultipleTokens(address[] calldata tokens) external nonReentrant whenNotPaused onlySwapper {
    uint256 length = tokens.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      _pullToken(tokens[i]);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Claims voting rewards from Quest for the given Locker
   * @param locker Address of the Locker having pending rewards
   * @param distributor Address of the contract distributing the rewards
   * @param claimParams Parameters to claim the rewards
   */
  function claimQuestRewards(address locker, address distributor, IQuestDistributor.ClaimParams[] calldata claimParams)
    external
    nonReentrant
    whenNotPaused
    onlyIncentivesClaimer
  {
    if (locker == address(0) || distributor == address(0)) revert Errors.ZeroAddress();

    uint256 length = claimParams.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      IIncentivizedLocker(locker).claimQuestRewards(
        distributor,
        claimParams[i].questID,
        claimParams[i].period,
        claimParams[i].index,
        locker,
        claimParams[i].amount,
        claimParams[i].merkleProof
      );

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Claims voting rewards for the given Locker from the Paladin Delegation address
   * @param locker Address of the Locker having pending rewards
   * @param distributor Address of the contract distributing the rewards
   * @param claimParams Parameters to claim the rewards
   */
  function claimDelegationRewards(
    address locker,
    address distributor,
    IDelegationDistributor.ClaimParams[] calldata claimParams
  ) external nonReentrant whenNotPaused onlyIncentivesClaimer {
    if (locker == address(0) || distributor == address(0)) revert Errors.ZeroAddress();

    uint256 length = claimParams.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      IIncentivizedLocker(locker).claimDelegationRewards(
        distributor,
        claimParams[i].token,
        claimParams[i].index,
        locker,
        claimParams[i].amount,
        claimParams[i].merkleProof
      );

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Claims voting rewards from Votium for the given Locker
   * @param locker Address of the Locker having pending rewards
   * @param distributor Address of the contract distributing the rewards
   * @param claimParams Parameters to claim the rewards
   */
  function claimVotiumRewards(address locker, address distributor, IVotiumDistributor.claimParam[] calldata claimParams)
    external
    nonReentrant
    whenNotPaused
    onlyIncentivesClaimer
  {
    if (locker == address(0) || distributor == address(0)) revert Errors.ZeroAddress();

    uint256 length = claimParams.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      IIncentivizedLocker(locker).claimVotiumRewards(
        distributor,
        claimParams[i].token,
        claimParams[i].index,
        locker,
        claimParams[i].amount,
        claimParams[i].merkleProof
      );

      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Claims voting rewards from HiddenHand for the given Locker
   * @param locker Address of the Locker having pending rewards
   * @param distributor Address of the contract distributing the rewards
   * @param claimParams Parameters to claim the rewards
   */
  function claimHiddenHandRewards(
    address locker,
    address distributor,
    IHiddenHandDistributor.Claim[] memory claimParams
  ) external nonReentrant whenNotPaused onlyIncentivesClaimer {
    if (locker == address(0) || distributor == address(0)) revert Errors.ZeroAddress();

    uint256 length = claimParams.length;
    if (length == 0) revert Errors.EmptyArray();

    for (uint256 i; i < length;) {
      IHiddenHandDistributor.Claim[] memory claim = new IHiddenHandDistributor.Claim[](1);
      claim[0] = claimParams[i];
      IIncentivizedLocker(locker).claimHiddenHandRewards(distributor, claim);

      unchecked {
        i++;
      }
    }
  }

  // Internal functions

  /**
   * @dev Processes a token based on their distribution/associated contract & take a fee on the amount processed
   * @param token Address of the token to process
   */
  function _processReward(address token) internal {
    // If the token address is the zero address, skip
    if (token == address(0)) return;

    // Load the token & get the amount to process
    IERC20 _token = IERC20(token);
    uint256 currentBalance = _token.balanceOf(address(this));

    // If the controller doesn't have any, skip
    if (currentBalance == 0) return;

    // Calculate the amount of fees to take
    uint256 feeAmount = (currentBalance * feeRatio) / MAX_BPS;
    uint256 processAmount = currentBalance - feeAmount;

    // Send the fees
    _sendFees(token, feeAmount);

    // Storing tokenFarmer to save on gas
    address tokenFarmer = tokenFarmers[token];

    if (tokenLockers[token] != address(0)) {
      // If the token is associated to a Locker:
      // 1 . Mint WAR with the token
      if (_token.allowance(address(this), address(minter)) != 0) _token.safeApprove(address(minter), 0);
      _token.safeIncreaseAllowance(address(minter), processAmount);
      minter.mint(token, processAmount);

      // 2 . Send the WAR to be distributed via the Staker
      IERC20 _war = IERC20(war);
      uint256 warBalance = _war.balanceOf(address(this));
      _war.safeTransfer(address(staker), warBalance);
      staker.queueRewards(war, warBalance);
    } else if (tokenFarmer != address(0)) {
      // If the token is associated to a Farmer:
      // Send the token in the Farmer
      if (_token.allowance(address(this), tokenFarmer) != 0) _token.safeApprove(tokenFarmer, 0);
      _token.safeIncreaseAllowance(tokenFarmer, processAmount);
      IFarmer(tokenFarmer).stake(token, processAmount);
    } else if (distributionTokens[token]) {
      // If the token is set for direct distribution:
      // Send the token to be distributed via the Staker
      _token.safeTransfer(address(staker), processAmount);
      staker.queueRewards(token, processAmount);
    } else {
      // Otherwise, set the token to be swapped for WETH by the Swapper
      swapperAmounts[token] += processAmount;
    }
  }

  /**
   * @dev Processes multiple tokens
   * @param tokens List of tokens to process
   */
  function _processMultiple(address[] memory tokens) internal {
    uint256 length = tokens.length;

    for (uint256 i; i < length;) {
      _processReward(tokens[i]);

      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Sends the given token to the Swapper
   * @param token Address of the token to send
   */
  function _pullToken(address token) internal {
    uint256 amount = swapperAmounts[token];
    swapperAmounts[token] = 0;

    IERC20(token).safeTransfer(swapper, amount);

    emit PullTokens(msg.sender, token, amount);
  }

  /**
   * @dev Sends the given amount of fees to the Fee Receiver
   * @param token Address of the token
   * @param amount Amount of fees to send
   */
  function _sendFees(address token, uint256 amount) internal {
    IERC20(token).safeTransfer(feeReceiver, amount);
  }

  // Admin functions

  /**
   * @notice Pause the contract
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Updates the Minter contract address
   * @param newMinter Address of the Minter
   */
  function setMinter(address newMinter) external onlyOwner {
    address oldMinter = address(minter);

    if (newMinter == address(0)) revert Errors.ZeroAddress();
    if (newMinter == oldMinter) revert Errors.AlreadySet();

    minter = IMinter(newMinter);

    emit SetMinter(oldMinter, newMinter);
  }

  /**
   * @notice Updates the Staker contract address
   * @param newStaker Address of the new Staker
   */
  function setStaker(address newStaker) external onlyOwner {
    if (newStaker == address(0)) revert Errors.ZeroAddress();
    if (newStaker == address(staker)) revert Errors.AlreadySet();

    address oldStaker = address(staker);
    staker = IStaker(newStaker);

    emit SetStaker(oldStaker, newStaker);
  }

  /**
   * @notice Updates the Swapper address
   * @param newSwapper Address of the new Swapper
   */
  function setSwapper(address newSwapper) external onlyOwner {
    if (newSwapper == address(0)) revert Errors.ZeroAddress();
    if (newSwapper == swapper) revert Errors.AlreadySet();

    address oldSwapper = swapper;
    swapper = newSwapper;

    emit SetSwapper(oldSwapper, newSwapper);
  }

  /**
   * @notice Updates the Incentives Claimer address
   * @param newIncentivesClaimer Address of the new Incentives Claimer
   */
  function setIncentivesClaimer(address newIncentivesClaimer) external onlyOwner {
    if (newIncentivesClaimer == address(0)) revert Errors.ZeroAddress();
    if (newIncentivesClaimer == incentivesClaimer) revert Errors.AlreadySet();

    address oldIncentivesClaimer = incentivesClaimer;
    incentivesClaimer = newIncentivesClaimer;

    emit SetIncentivesClaimer(oldIncentivesClaimer, newIncentivesClaimer);
  }

  /**
   * @notice Updates the Fee Receiver address
   * @param newFeeReceiver Address of the new Fee Receiver
   */
  function setFeeReceiver(address newFeeReceiver) external onlyOwner {
    if (newFeeReceiver == address(0)) revert Errors.ZeroAddress();
    if (newFeeReceiver == feeReceiver) revert Errors.AlreadySet();

    address oldFeeReceiver = feeReceiver;
    feeReceiver = newFeeReceiver;

    emit SetFeeReceiver(oldFeeReceiver, newFeeReceiver);
  }

  /**
   * @notice Updates the Fee ratio
   * @param newFeeRatio Value (BPS) of the new fee ratio
   */
  function setFeeRatio(uint256 newFeeRatio) external onlyOwner {
    if (newFeeRatio > 1000) revert Errors.InvalidFeeRatio();
    if (newFeeRatio == feeRatio) revert Errors.AlreadySet();

    uint256 oldFeeRatio = feeRatio;
    feeRatio = newFeeRatio;

    emit SetFeeRatio(oldFeeRatio, newFeeRatio);
  }

  /**
   * @notice Sets a Locker contract for a token
   * @param token Address of the token
   * @param locker Address of the Locker contract
   */
  function setLocker(address token, address locker) external onlyOwner {
    if (token == address(0) || locker == address(0)) revert Errors.ZeroAddress();
    if (tokenFarmers[token] != address(0)) revert Errors.ListedFarmer();

    if (tokenLockers[token] != address(0)) {
      // if the token has already been assigned to another locker
      // remove the old locker without leaving holes in the array
      address oldLocker = tokenLockers[token];
      // disable the previously harvestable locker
      harvestable[oldLocker] = false;
      address[] memory _lockers = lockers;
      uint256 length = _lockers.length;
      uint256 lastIndex = length - 1;
      for (uint256 i; i < length;) {
        if (_lockers[i] == oldLocker) {
          if (i != lastIndex) {
            lockers[i] = _lockers[lastIndex];
          }

          lockers.pop();

          break;
        }

        unchecked {
          ++i;
        }
      }
    }

    // append the new locker to the list
    lockers.push(locker);
    // link the token to the associated locker
    tokenLockers[token] = locker;
    // whitelist the locker so that the controller can harvest it
    harvestable[locker] = true;

    emit SetLocker(token, locker);
  }

  /**
   * @notice Sets a Farmer contract for a token
   * @param token Address of the token
   * @param farmer Address of the Farmer contract
   */
  function setFarmer(address token, address farmer) external onlyOwner {
    if (token == address(0) || farmer == address(0)) revert Errors.ZeroAddress();
    if (tokenLockers[token] != address(0)) revert Errors.ListedLocker();

    if (tokenFarmers[token] != address(0)) {
      // if the token has already been assigned to another farmer
      // remove the old farmer without leaving holes in the array
      address oldFarmer = tokenFarmers[token];
      // disable the previously harvestable farmer
      harvestable[oldFarmer] = false;
      address[] memory _farmers = farmers;
      uint256 length = _farmers.length;
      uint256 lastIndex = length - 1;
      for (uint256 i; i < length;) {
        if (_farmers[i] == oldFarmer) {
          if (i != lastIndex) {
            farmers[i] = _farmers[lastIndex];
          }

          farmers.pop();

          break;
        }

        unchecked {
          ++i;
        }
      }
    }
    // append the new farmer to the list
    farmers.push(farmer);
    // link the token to the associated farmer
    tokenFarmers[token] = farmer;
    // whitelist the farmer so that the controller can harvest it
    harvestable[farmer] = true;

    emit SetFarmer(token, farmer);
  }

  /**
   * @notice Sets a token for direct distribution
   * @param token Address of the token
   * @param distribution True if the token is for direct distribution
   */
  function setDistributionToken(address token, bool distribution) external onlyOwner {
    if (token == address(0)) revert Errors.ZeroAddress();
    if (tokenLockers[token] != address(0)) revert Errors.ListedLocker();
    if (tokenFarmers[token] != address(0)) revert Errors.ListedFarmer();

    distributionTokens[token] = distribution;

    emit SetDistributionToken(token, distribution);
  }

  /**
   * @notice Enable/disable the harvest function to be called on the token
   * @param target Address of the IHarvestable contract
   * @param enabled True if the contract should be harvested
   */
  function setHarvestableToken(address target, bool enabled) external onlyOwner {
    if (target == address(0)) revert Errors.ZeroAddress();

    harvestable[target] = enabled;

    emit SetHarvestable(target, enabled);
  }
}