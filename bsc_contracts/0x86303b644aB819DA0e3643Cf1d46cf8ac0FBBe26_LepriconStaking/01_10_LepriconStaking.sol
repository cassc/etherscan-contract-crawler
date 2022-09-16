// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./library/DSMath.sol";

/**
 * @title Lepricon Staking Contract
 * @author @Pedrojok01
 */
contract LepriconStaking is DSMath, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /* Storage:
     ***********/

    IERC20 public token;
    address private admin; // = back-end address (yield payment + API)
    uint256 public totalTokenStaked;
    uint256 public total_noLock;
    uint256 public total_3months;
    uint256 public total_6months;
    uint256 public total_12months;

    /**
     * @notice Define the token that will be used for staking, and push once to stakeholders for index to work properly
     * @param _token the token that will be used for staking
     */
    constructor(IERC20 _token) {
        token = _token;
        admin = msg.sender;
        stakeholders.push();
    }

    /**
     * @notice Struct used to represent the way we store each stake;
     * A Stake contain the users address, the amount staked, the timeLock duration, and the unlock time;
     * @param since allow us to calculate the reward (reset to block.timestamp with each withdraw)
     * @param claimable is used to display the actual reward earned to user (see hasStake() function)
     */
    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 timeLock;
        uint256 unlockTime;
        uint256 claimable;
    }

    /// @notice Track the NFT status per stakeholders that has at least 1 active stake
    struct Boost {
        bool isBoost;
        address NftContractAddress;
        uint256 tokenId;
        uint256 boostValue;
        uint256 since;
    }

    /// @notice A Stakeholder is a staker that has at least 1 active stake
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    /// @notice Struct used to contain all stakes per address (user)
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    /// @notice Store all Stakes performed on the Contract per index, the index can be found using the stakes mapping
    Stakeholder[] private stakeholders;

    /// @notice Map all NFTboost status per stakehoder address
    mapping(address => Boost) public boost;

    /// @notice keep track of the INDEX for the stakers in the stakes array
    mapping(address => uint256) private stakes;

    /**
     * @notice The APR is based on a percent reward per day. Every staking day allow a user to earn some interest
     * The calculation is as follow:
     * APR% per day * numbers of days staked * amount staked
     */
    uint256 public APR_NOLOCK = wdiv(1370, 1e7); // = 5% APR == 0.05/year == 0.0001370/day
    uint256 private constant TIMELOCK_3MONTHS = 91 days;
    uint256 public APR_3MONTHS = wdiv(2129, 1e7); // = 7.77% APR == 0.0777/year == 0.0002129/day
    uint256 private constant TIMELOCK_6MONTHS = 182 days;
    uint256 public APR_6MONTHS = wdiv(3288, 1e7); // = 12% APR == 0.12/year == 0.0003288/day
    uint256 private constant TIMELOCK_12MONTHS = 364 days;
    uint256 public APR_12MONTHS = wdiv(5480, 1e7); // = 20% APR == 0.2/year == 0.0005480/day

    /* Events:
     ***********/

    /// @notice Triggered whenever a user stakes tokens
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 lockTime,
        uint256 unlockTime
    );

    /* Functions:
     **************/

    /**
     * @notice Allow a user to stake his tokens
     * @param _amount Amount of tokens that the user wish to stake
     * @param _timeLock Duration of staking (in months) chosen by user: 0 | 3 | 6 | 12 (will determines the APR)
     */
    function stake(uint256 _amount, uint256 _timeLock) external nonReentrant whenNotPaused {
        require(_amount < token.balanceOf(msg.sender), "Cannot stake more than you own");
        require(_amount <= token.allowance(msg.sender, address(this)), "Not authorized");
        token.safeTransferFrom(msg.sender, address(this), _amount); // Transfer tokens to staking contract
        _stake(_amount, _timeLock); // Handle the new stake
    }

    /**
     * @notice Calculate how much a user should be rewarded for his stakes
     */
    function calculateStakeReward(Stake memory _current_stake, uint256 _NftBoost) private view returns (uint256) {
        // Grab the APR based on lock duration
        uint256 reward = 0;
        if (_current_stake.timeLock == 0) {
            if (_NftBoost != 0) {
                if (boost[_current_stake.user].since > _current_stake.since) {
                    uint256 extraBoost = wdiv(_convertBoostPercent(_NftBoost), 1e7);
                    reward = APR_NOLOCK + extraBoost;
                    uint256 boostReward = wmul(
                        (((block.timestamp - boost[_current_stake.user].since) / 1 days) * _current_stake.amount),
                        reward
                    );
                    uint256 noBoostReward = wmul(
                        (((boost[_current_stake.user].since - _current_stake.since) / 1 days) * _current_stake.amount),
                        APR_NOLOCK
                    );
                    return boostReward + noBoostReward;
                } else {
                    uint256 extraBoost = wdiv(_convertBoostPercent(_NftBoost), 1e7);
                    reward = APR_NOLOCK + extraBoost;
                }
            } else {
                reward = APR_NOLOCK;
            }
        } else if (_current_stake.timeLock == TIMELOCK_3MONTHS) {
            reward = APR_3MONTHS;
        } else if (_current_stake.timeLock == TIMELOCK_6MONTHS) {
            reward = APR_6MONTHS;
        } else if (_current_stake.timeLock == TIMELOCK_12MONTHS) {
            reward = APR_12MONTHS;
        }
        // Calculation: numbers of days * amount staked * APR
        return wmul((((block.timestamp - _current_stake.since) / 1 days) * _current_stake.amount), reward);
    }

    /**
     * @notice Allow a staker to withdraw his stakes from his holder's account
     */
    function withdrawStake(uint256 amount, uint256 stake_index) external nonReentrant whenNotPaused {
        uint256 reward = _withdrawStake(amount, stake_index);
        // Return staked tokens to user
        token.safeTransfer(msg.sender, amount);
        // Pay earned reward to user
        token.safeTransferFrom(admin, msg.sender, reward);
    }

    /**
     * @notice Allow to check if a account has stakes and to return the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) external view returns (StakingSummary memory) {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Iterate through all stakes and grab the amount of each stake
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 NftBoost = boost[_staker].boostValue;
            uint256 availableReward = calculateStakeReward(summary.stakes[s], NftBoost);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    function setNftStatus(
        address _account,
        address _NftContractAddress,
        uint256 _tokenId,
        uint256 _NftBoost
    ) external {
        require(
            msg.sender == owner() || msg.sender == admin, // if set afterwards in case of transfer/sale
            "Not authorized"
        );
        require(_NftBoost <= 10, "Wrong boost amount"); // Prevent abuse if logic flaw
        // If never staked, initialized user first:
        if (stakes[_account] == 0) {
            _addStakeholder(_account);
        }
        _setNftStatus(_account, _NftContractAddress, _tokenId, _NftBoost);
    }

    function resetNftStatus(address _account) external {
        require(_account == msg.sender || msg.sender == admin, "Not authorized");
        _resetNftStatus(_account);
    }

    /* Restricted functions:
     ***********************/

    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Zero address");
        admin = _newAdmin;
    }

    function setToken(IERC20 _newToken) external onlyOwner {
        token = _newToken;
    }

    /**
     * @notice The following functions allow to change the APR per lock duration.
     * @param _newAPR_NOLOCK must be an int! It will be divided by 10,000,000 to get the %/day
     * i.e: 822 == 0.0000822% per day = 0.030003% per year = 3% APR
     */
    function setAPR_NOLOCK(uint256 _newAPR_NOLOCK) external onlyOwner {
        APR_NOLOCK = wdiv(_newAPR_NOLOCK, 1e7);
    }

    function setAPR_3MONTHS(uint256 _newAPR_3MONTHS) external onlyOwner {
        APR_3MONTHS = wdiv(_newAPR_3MONTHS, 1e7);
    }

    function setAPR_6MONTHS(uint256 _newAPR_6MONTHS) external onlyOwner {
        APR_6MONTHS = wdiv(_newAPR_6MONTHS, 1e7);
    }

    function setAPR_12MONTHS(uint256 _newAPR_12MONTHS) external onlyOwner {
        APR_12MONTHS = wdiv(_newAPR_12MONTHS, 1e7);
    }

    /* Private functions:
     *********************/

    /**
     * @notice Add a stakeholder to the "stakeholders" array
     */
    function _addStakeholder(address staker) private returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;

        // Initialize Boost status for new Stakeholder; default == No boost
        _resetNftStatus(staker);

        return userIndex;
    }

    /**
     * @notice Create a new stake from sender. Will remove the amount to stake from sender and store it in a container
     */
    function _stake(uint256 _amount, uint256 _timeLock) private {
        require(_amount > 0, "Cannot stake nothing");

        uint256 _lock = _getLockPeriod(_timeLock);
        _addAmountToPool(_amount, _timeLock);

        uint256 index = stakes[msg.sender];
        uint256 since = block.timestamp;
        uint256 unlockTime = since + _lock;
        // Check if the staker already has a staked index or if new user
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }
        totalTokenStaked = totalTokenStaked + _amount;

        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, since, _lock, unlockTime, index));

        emit Staked(msg.sender, _amount, index, since, _lock, unlockTime);
    }

    /**
     * @notice Takes in an amount and the index of the stake to withdraw from, and removes the tokens from that stake
     * The index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to transfer back to the acount (amount to withdraw + reward) and reset timer
     */
    function _withdrawStake(uint256 _amount, uint256 _index) private returns (uint256) {
        // Grab user_index which is used to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[_index];
        require(block.timestamp > current_stake.unlockTime, "Still under lock");
        require(current_stake.amount >= _amount, "Can't withdraw more than staked");

        // Calculate available Reward before modifying data
        uint256 NftBoost = boost[msg.sender].boostValue;
        uint256 reward = calculateStakeReward(current_stake, NftBoost);
        // Remove by subtracting the money unstaked
        current_stake.amount = current_stake.amount - _amount;
        // If emptied, remove it from the array of stakes
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[_index];
        } else {
            // If not empty, replace the value of the stake
            stakeholders[user_index].address_stakes[_index].amount = current_stake.amount;
            // Reset timer for reward calculation
            stakeholders[user_index].address_stakes[_index].since = block.timestamp;
        }
        if (current_stake.timeLock == 0) {
            total_noLock = total_noLock - _amount;
        } else if (current_stake.timeLock == 3) {
            total_3months = total_3months - _amount;
        } else if (current_stake.timeLock == 6) {
            total_6months = total_6months - _amount;
        } else if (current_stake.timeLock == 12) {
            total_12months = total_12months - _amount;
        }
        totalTokenStaked = totalTokenStaked - _amount;
        return reward;
    }

    function _setNftStatus(
        address _account,
        address _NftContractAddress,
        uint256 _tokenId,
        uint256 _NftBoost
    ) private {
        // add boost to stakeholder NFT status and keep track of start day (since)
        boost[_account].isBoost = true;
        boost[_account].NftContractAddress = _NftContractAddress;
        boost[_account].tokenId = _tokenId;
        boost[_account].boostValue = _NftBoost;
        boost[_account].since = block.timestamp;
    }

    function _resetNftStatus(address _account) private {
        boost[_account].isBoost = false;
        boost[_account].NftContractAddress = address(0);
        boost[_account].tokenId = 0;
        boost[_account].boostValue = 0;
        boost[_account].since = 0;
    }

    /* Utils:
     *******/

    function _getLockPeriod(uint256 _timeLock) private pure returns (uint256) {
        if (_timeLock == 0) {
            return 0;
        } else if (_timeLock == 3) {
            return TIMELOCK_3MONTHS;
        } else if (_timeLock == 6) {
            return TIMELOCK_6MONTHS;
        } else if (_timeLock == 12) {
            return TIMELOCK_12MONTHS;
        } else revert("Wrong _timeLock arg");
    }

    function _addAmountToPool(uint256 _amount, uint256 _timeLock) private {
        if (_timeLock == 0) {
            total_noLock = total_noLock + _amount;
        } else if (_timeLock == 3) {
            total_3months = total_3months + _amount;
        } else if (_timeLock == 6) {
            total_6months = total_6months + _amount;
        } else if (_timeLock == 12) {
            total_12months = total_12months + _amount;
        }
    }

    function _convertBoostPercent(uint256 _boost) private pure returns (uint256) {
        uint256 result = 0;
        if (_boost == 1)
            result = 274; // Rounded for simplicity, used as 0.0000274/day
        else if (_boost == 2) result = 548;
        else if (_boost == 3) result = 822;
        else if (_boost == 4) result = 1096;
        else if (_boost == 5) result = 1370;
        else if (_boost == 6) result = 1644;
        else if (_boost == 7) result = 1918;
        else if (_boost == 8) result = 2192;
        else if (_boost == 9) result = 2466;
        else if (_boost == 10) result = 2740;

        return result;
    }
}