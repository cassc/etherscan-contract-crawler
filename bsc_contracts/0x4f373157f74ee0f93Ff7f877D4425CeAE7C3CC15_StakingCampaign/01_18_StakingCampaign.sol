// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./Jimizz.sol";
import "./EmergencyDrainable.sol";

/**
 * @title Jimizz Staking Campaign
 *
 * Jimizz Staking campaign contract
 */
contract StakingCampaign is Context, Ownable, ReentrancyGuard, EmergencyDrainable {
  using SafeERC20 for Jimizz;


  // ==== Structs ==== //

  /**
   * @notice
   * This struct is used to represent a stake
   * It contains the address of the user, the amount staked and a timestamp,
   * which is when the stake will end, 0 if there is no lockup time.
   */
  struct Stake {
    address user;
    uint256 amount;
    uint256 startedOn;
    uint256 endsOn;
  }

  /**
   * @notice
   * This struct represents a staker that has active stakes
   */
  struct Stakeholder {
    address user;
    Stake[] stakes;
  }

  /**
   * @notice
   * This struct is used to represent a summary of a stake in getStakes getter
   */
  struct StakeSummary {
    uint256 amount;
    uint256 rewards;
    uint256 startedOn;
    uint256 endsOn;
  }


  // ==== State ==== //

  /**
   * @notice Jimizz BEP20
   */
  Jimizz private immutable jimizz;

  /**
   * @notice Rewards percentage
   */
  uint16 public immutable rewardsPercentage;

  /**
   * @notice Lockup time
   */
  uint256 public immutable lockupTime;

  /**
   * @dev Array used to store all stakers
   */
  Stakeholder[] private stakeholders;

  /**
   * @dev Total of required amount to refund all stakes
   */
  uint private requiredBalance;

  /**
   * @dev
   * Map used to keep track of the index of stakers
   * We store the indexes in a mapping to avoid iterating the whole stakeholders array
   * in order to save gas
   */
  mapping(address => uint256) private stakeIndexes;


  // ==== Events ==== //

  /**
   * @notice Event emitted when owner drain funds
   */
  event StakedFor(address recipient, uint256 amount);


  // ==== Constructor ==== //

  /**
   * @dev constructor
   * @param _jimizz The address of Jimizz BEP20
   * @param _rewardsPercentage The percentage of rewards the staker will get at the end
   * @param _lockupTime The lockup time
   */
  constructor(
    address _jimizz,
    uint16 _rewardsPercentage,
    uint256 _lockupTime
  )
    EmergencyDrainable(_jimizz)
  {
    require(
      _jimizz != address(0),
      "Jimizz address is not valid"
    );
    jimizz = Jimizz(_jimizz);

    require(
      _rewardsPercentage > 0,
      "Rewards percentage must be greater than 0"
    );
    rewardsPercentage = _rewardsPercentage;

    lockupTime = _lockupTime;

    // Avoid index 0 to prevent index-1 bug
    stakeholders.push();
  }


  // ==== Public methods ==== //

  /**
   * @notice This method is used to stake tokens
   * @param _amount The amount to stake
   */
  function stake(uint256 _amount)
    external
  {
    _stake(_msgSender(), _amount);
  }

  /**
   * @notice This method is used to withdraw all released staked tokens
   */
  function withdraw()
    public
    nonReentrant
  {
    // Check if the user has stakes
    (bool isStaker, ) = hasStake(_msgSender());
    require(
      isStaker,
      "You don't have any stake yet"
    );

    // Get total released amount among every stakes
    uint totalReleased;
    uint index = stakeIndexes[_msgSender()];

    uint i;
    do {
      if (
        stakeholders[index].stakes[i].endsOn <= block.timestamp &&
        stakeholders[index].stakes[i].amount > 0 // Just a double check
      ) {
        // Track released amount
        totalReleased = totalReleased + stakeholders[index].stakes[i].amount;

        // Replace current stake with the last one to remove it
        stakeholders[index].stakes[i] = stakeholders[index].stakes[
          stakeholders[index].stakes.length - 1
        ];

        // Reduce array size
        stakeholders[index].stakes.pop();

        // Note: We do not increment i to ensure that the swapped stake
        // is evaluated during the next iteration
      } else {
        i++;
      }
    } while (i < stakeholders[index].stakes.length);

    require(
      totalReleased > 0,
      "Nothing to withdraw yet"
    );

    // Calculate rewards
    uint rewards = totalReleased * rewardsPercentage / 10000;

    // Transfer total released + rewards
    uint total = totalReleased + rewards;
    jimizz.safeTransfer(
      stakeholders[index].user,
      total
    );

    if (requiredBalance > total) {
      requiredBalance -= total;
    } else {
      requiredBalance = 0;
    }
  }

  /**
   * @dev This method is used to stake tokens for an other beneficiary
   * @param _staker The address of the staker
   * @param _amount The amount to stake
   */
  function stakeFor(address _staker, uint256 _amount)
    external
  {
    _stake(_staker, _amount);
    emit StakedFor(_staker, _amount);
  }


  // ==== Views ==== //

  /**
   * @notice Tells if _staker has stakes and returns total amount
   * @param _staker The address of the staker
   */
  function hasStake(
    address _staker
  )
    public
    view
    returns (bool, uint256)
  {
    uint256 total;
    for (uint i = 0; i < stakeholders[stakeIndexes[_staker]].stakes.length; i++) {
      total = total + stakeholders[stakeIndexes[_staker]].stakes[i].amount;
    }

    return (total > 0, total);
  }

  /**
   * @notice Get all your current stakes
   */
  function getStakes()
    external
    view
    returns (StakeSummary[] memory)
  {
    uint index = stakeIndexes[_msgSender()];
    uint size = stakeholders[index].stakes.length;
    require(
      size > 0,
      "You don't have any stakes"
    );

    StakeSummary[] memory summary = new StakeSummary[](size);
    for (uint i = 0; i < size; i++) {
      Stake storage currentStake = stakeholders[index].stakes[i];

      summary[i] = StakeSummary(
        currentStake.amount,
        _calculateReward(currentStake),
        currentStake.startedOn,
        currentStake.endsOn
      );
    }

    return summary;
  }

  /**
   * @notice Get available amount of rewards left in the campaign
   */
  function getAvailableRewards()
    public
    view
    returns (uint availableRewards)
  {
    availableRewards = 0;
    uint balance = jimizz.balanceOf(address(this));
    if (balance > requiredBalance) {
      availableRewards = balance - requiredBalance;
    }
  }


  // ==== Restricted methods ==== //

  /**
   * @notice Allows to recover ERC20 funds, except for Jimizz tokens
   */
  function drainERC20(address erc20Address)
    public
    override
    onlyOwner
  {
    if (erc20Address != address(jimizz)) {
      super.drainERC20(erc20Address);
    } else {
      uint remaining = getAvailableRewards();
      jimizz.safeTransfer(drainRecipient, remaining);
      emit DrainedERC20(remaining);
    }
  }


  // ==== Private methods ==== //

  /**
   * @dev Internal method used by stake methods
   * @param _staker The address of the staker
   * @param _amount The amount to stake
   */
  function _stake(
    address _staker,
    uint256 _amount
  )
    private
  {
    require(
      _amount > 0,
      "You need to stake more than 0"
    );

    // Check that the contract has enough tokens to cover the rewards
    uint rewards = _amount * rewardsPercentage / 10000;
    require(
      getAvailableRewards() >= rewards,
      "Campaign does not have enough tokens to allow this amount"
    );

    // Check transfer
    require(
      jimizz.transferFrom(_msgSender(), address(this), _amount),
      "Transfer failed"
    );
    requiredBalance += _amount + rewards;

    uint256 index = stakeIndexes[_staker];
    if (index == 0) {
      index = _addStakeholder(_staker);
    }

    stakeholders[index].stakes.push(
      Stake(
        _staker,
        _amount,
        block.timestamp,
        block.timestamp + lockupTime
      )
    );
  }

  /**
   * @dev Add a new staker and keep track of their index
   * @param _staker The address of the staker
   */
  function _addStakeholder(
    address _staker
  )
    private
    returns (uint256)
  {
    stakeholders.push();
    uint256 index = stakeholders.length - 1;
    stakeholders[index].user = _staker;
    stakeIndexes[_staker] = index;
    return index;
  }

  /**
   * @dev Calculate current reward for a given stake
   * @param s Stake
   */
  function _calculateReward(
    Stake storage s
  )
    private
    view
    returns (uint256)
  {
    uint elapsed = block.timestamp - s.startedOn;
    uint totalTime = s.endsOn - s.startedOn;
    if (elapsed > totalTime) {
      elapsed = totalTime;
    }
    return uint(rewardsPercentage) * s.amount * elapsed / totalTime / 10000;
  }
}