// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
Maturation Days – the number of days that must elapse after a deposit before an investor can unstake without penalty (e.g., 90 days) 
Starting Burn Rate – the initial burn rate, which will decrease over time until Maturation (defaults to 20%) 
Reward Rate – a multiplier applied to the staking amount, used to calculate the reward tokens due to an investor at Maturation 
*/

contract Staking is Ownable {
    address public immutable token; // Address of the token to be used for the stake
    uint256 public deploymentDate; // Date contract was deployed and activated
    uint256 public maturationPeriod; // The period of time (in seconds) that must elapse before an investor can unstake without penalty
    uint256 public maturationDate; // The date of maturation, after which investors can unstake without penalty
    uint32 public immutable stakingFeeRate; // A percentage of the staking amount that is charged as a fee
    uint32 public immutable startingBurnRate; // The initial burn rate percentage, which will decrease over time until maturation
    uint32 public immutable rewardRate; // The percentage of the staking amount due to an investor if they stake for the entire maturation period    uint32 public immutable stakingFeeRate; // A percentage of the staking amount that is charged as a fee

    uint32 constant PRECISION = 1000; // Precision for percentage calculations
    uint32 constant DAY = 86_400; // Seconds in a day

    event StakeDeposited(
        address indexed staker, // Address of the investor who deposited the stake
        uint256 stakeIndex, // Index of the stake that was deposited
        uint256 amount, // Net amount of stake tokens deposited after fees
        uint256 feesCharged // Fees charged
    );

    event StakeWithdrawn(
        address indexed staker, // Address of the investor who withdrew the stake
        uint256 stakeIndex, // Index of the stake that was withdrawn
        uint256 stakeWithdrawn, // Amount of stake tokens withdrawn
        uint256 stakeBurnt // Amount of stake tokens burnt
    );

    event StakeRefunded(
        address indexed staker, // Address of the investor who withdrew the stake
        uint256 stakeIndex, // Index of the stake that was withdrawn
        uint256 stakeRefunded // Amount of stake tokens refunded
    );

    event RewardClaimed(
        address indexed staker, // Address of the investor who claimed the reward
        uint256 stakeIndex, // Index of the stake for which rewards were claimed
        uint256 amount // Amount of reward tokens claimed
    );
    
    struct Stake {
        uint256 amount; // Amount staked
        uint256 reward; // Total reward due at maturation
        address staker; // Address that made the stake
        uint256 startDate; // Date the stake was made
        uint256 dateWithdrawn; // Date the stake was withdrawn (0 if not withdrawn)
        uint256 totalRewardClaimed; // Total reward claimed so far
        uint256 stakeBurnt; // Total amount burnt on premature withdrawal
        uint256 stakingFee; // Amount of staking fee paid
    }

    // Mapping of investor address to array of stakes. Each investor can have multiple stakes.
    mapping (address => Stake[]) internal stakes;
    
    // Array of all investor addresses
    address[] investors;

    /*
    * @notice Constructor
    * @param token Address of the token to be used for the stake
    * @param maturationDays Number of days that must elapse after a deposit before an investor can unstake without penalty
    * @param startingBurnRate The initial burn rate, which will decrease over time until maturation. Precision 1000 (e.g., 2% = 2_000, 100% = 100_000)
    * @param rewardRate A multiplier applied to the staking amount, used to calculate the reward tokens due to an investor at maturation. Precision 1000 (e.g., 2% = 2_000, 100% = 100_000)
    */
    constructor(
        address token_,
        uint32 maturationDays_,
        uint32 startingBurnRate_,
        uint32 rewardRate_,
        uint32 stakingFeeRate_
    ) {
        require(startingBurnRate_ <= PRECISION * 100, "Starting burn rate cannot be more than 100%");
        require(stakingFeeRate_ <= PRECISION * 100, "Staking fee rate cannot be more than 100%");
        require(maturationDays_ > 0, "Maturation days must be greater than 0");

        token = token_;

        // Maturation date is now + maturationDays
        maturationPeriod = maturationDays_ * DAY;
        deploymentDate = block.timestamp;
        maturationDate = deploymentDate + maturationPeriod;

        startingBurnRate = startingBurnRate_;
        rewardRate = rewardRate_;
        stakingFeeRate = stakingFeeRate_;
    }

    /*
    * @notice Get the caller's stake by index
    * @param index Index of the stake
    * @return Stake struct
    */
    function getStake(uint256 index) public view returns (Stake memory) {
        require(getInvestorStakeCount(msg.sender) > index, "Stake does not exist");
        Stake memory stake = stakes[address(msg.sender)][index];
        return stake;
    }

    /*
    * @notice Get the stake of an investor by index
    * @param investor Address of the investor
    * @param index Index of the stake
    * @return Stake struct
    */
    function getInvestorStake(address investor, uint256 index) public view returns (Stake memory) {
        Stake memory stake = stakes[investor][index];
        require(stake.startDate > 0, "Stake does not exist");
        return stake;
    }

    /*
    * @notice Get the number of stakes deposited by the caller
    * @return Number of stakes
    */
    function getStakeCount() public view returns (uint256) {
        return stakes[address(msg.sender)].length;
    }

    /*
    * @notice Get the number of stakes deposited by an investor
    * @param investor Address of the investor
    * @return Number of stakes
    */
    function getInvestorStakeCount(address investor) public view returns (uint256) {
        return stakes[investor].length;
    }

    /*
    * @notice Get the number of investors
    * @return Number of investors
    */
    function getInvestorCount() public view returns (uint256) {
        return investors.length;
    }

    /*
    * @notice Get an investor's address by index
    * @param index Index of the investor
    * @return Address of the investor
    */
    function getInvestor(uint256 index) public view returns (address) {
        return investors[index];
    }

    /*
    * @notice Deposit a stake. The stake will be added to the caller's stakes array. It will include a maturation date which is the current date + maturationDays
    * @param amount Amount to stake
    */
    function depositStake(uint256 amount) public {

        // If the maturation date has passed, revert
        require(maturationDate > block.timestamp, "Staking period has ended");

        // Check that amount is not zero
        require(amount > 0, "Amount must be greater than zero");

        // Deduct the staking fee
        uint256 fee = Math.mulDiv(amount, stakingFeeRate, PRECISION * 100, Math.Rounding.Zero);
        uint256 netStakeAmount = amount - fee;
     
        // Calculate reward
        // Time since deployment. The reward rate decreases linearly as this value increases
        uint256 timeToMaturation = maturationDate - block.timestamp;

        uint256 maxReward = Math.mulDiv(netStakeAmount, rewardRate, PRECISION * 100, Math.Rounding.Zero);
        uint256 reward = Math.mulDiv(maxReward, timeToMaturation, maturationPeriod, Math.Rounding.Zero);

        Stake memory stake = Stake(netStakeAmount, reward, address(msg.sender), block.timestamp, 0, 0, 0, fee);

        // Add the investor to the investors array if they are not already in it
        if (stakes[address(msg.sender)].length == 0) {
            investors.push(address(msg.sender));
        }
        // Add the new Stake to the stakes array
        stakes[address(msg.sender)].push(stake);

        // Transfer the amount from the staker to the contract
        IERC20(token).transferFrom(address(msg.sender), address(this), netStakeAmount);

        // Transfer the fee to the owner address
        IERC20(token).transferFrom(address(msg.sender), owner(), fee);

        // Emit the StakeDeposited event
        emit StakeDeposited(address(msg.sender), stakes[address(msg.sender)].length - 1, netStakeAmount, fee);
    }

    /*
    * @notice Calculate the amount of tokens that could be returned on a stake. This function does not change the state of the contract.
    * @param investor Address of the investor
    * @param index Index of the stake
    * @return Amount of reward that would be claimed if the investor called claimReward(index)
    */
    function previewInvestorClaimReward(address investor, uint256 index) public view returns (uint256) {
        // Get the stake 
        Stake memory stake = getInvestorStake(investor, index);

        uint256 rewardDueNow = 0;      
        uint256 maximumRewardablePeriod = maturationDate - stake.startDate;
        uint256 rewardablePeriod;

        // If the stake has been withdrawn, the rewardable period is:   
        // Time of stake deposit to time of withdrawal or maturation date, whichever is earlier
        if (stake.dateWithdrawn > 0) {
            rewardablePeriod = Math.min(stake.dateWithdrawn, maturationDate) - stake.startDate;     
        } 
        // If the stake has not been withdrawn, the rewardable period is:
        // Time of stake deposit to current time or maturation date, whichever is earlier
        else {
            rewardablePeriod = Math.min(block.timestamp, maturationDate) - stake.startDate;
        } 

        // Protect against division by 0 if the stake was withdrawn immediately
        if (rewardablePeriod == 0) {
            return 0;
        }
          
        // Calculate the reward due now, assuming no previous rewards have been claimed
        // Starts at 0 and increases linearly to the total reward amount over the maturation period     
        rewardDueNow = Math.mulDiv(stake.reward, rewardablePeriod, maximumRewardablePeriod, Math.Rounding.Zero);

        // Return the reward due now minus the reward already claimed
        return rewardDueNow - stake.totalRewardClaimed;
    }

    /*
    * @notice Withdraw all rewards due on a stake. This function will calculate the amount of reward tokens due to the caller and transfer them to the caller's address.
    * @param index Index of the stake
    */
    function claimReward(uint256 index) public {
        // Get the stake  
        uint256 rewardAmount = previewInvestorClaimReward(address(msg.sender), index);
        require(rewardAmount > 0, "No reward to claim");

        Stake storage stake = stakes[address(msg.sender)][index];
        stake.totalRewardClaimed += rewardAmount;
        IERC20(token).transfer(stake.staker, rewardAmount); 
        emit RewardClaimed(stake.staker, index, rewardAmount);
    }

    /*
    * @notice Calculate the amount of tokens that would be withdrawn and burned on a stake. This function does not change the state of the contract.
    * @param investor Address of the investor
    * @param index Index of the stake
    * @return Amounts of tokens that would be withdrawn and would be burned if the investor called withdrawStake(index)
    */
    function previewInvestorWithdrawStake(address investor, uint256 index) public view returns (uint256, uint256) {
        // Get the stake 
        Stake memory stake = getInvestorStake(investor, index);

        // Check that the stake has not already been withdrawn
        require(stake.dateWithdrawn == 0, "Stake has already been withdrawn");
     
        // Calculate the burn amount. Starting burn rate is 20% and decreases linearly to 0% at maturation
        uint256 burnAmount = 0;
        if (maturationDate > block.timestamp) {
            uint256 maxBurn = Math.mulDiv(stake.amount, startingBurnRate, PRECISION * 100, Math.Rounding.Zero);
            uint256 timeRemaining = maturationDate - block.timestamp;
            burnAmount = Math.mulDiv(maxBurn, timeRemaining, maturationPeriod, Math.Rounding.Zero);
        }
        // Calculate the amount to be withdrawn
        uint256 withdrawAmount = stake.amount - burnAmount;

        return (withdrawAmount, burnAmount);
    }

    /*
    * @notice Withdraw all tokens from a stake. Calculate the amount of tokens due to the caller and transfer them to the caller's address. It may also burn a percentage of the tokens, depending on how early the stake was withdrawn.
    * @param index Index of the stake
    */
    function withdrawStake(uint256 index) public {
        // Preview
        (uint256 withdrawAmount, uint256 burnAmount) = previewInvestorWithdrawStake(address(msg.sender), index);
        Stake storage stake = stakes[address(msg.sender)][index];

        // Burn the burn amount by sending it to address 1
        if (burnAmount > 0) {
            stake.stakeBurnt = burnAmount;
            IERC20(token).transfer(address(1), burnAmount);
        }
        stake.dateWithdrawn = block.timestamp;

        // Send the remaining amount to the staker
        IERC20(token).transfer(stake.staker, withdrawAmount);

        emit StakeWithdrawn(stake.staker, index, withdrawAmount, burnAmount);
    }

    function refundInvestorStake(address investor, uint256 index) public onlyOwner {
        // Get the stake 
        Stake memory stake = getInvestorStake(investor, index);

        // Check that the stake has not already been withdrawn
        require(stake.dateWithdrawn == 0, "Stake has already been withdrawn");

        // Refund the stake
        IERC20(token).transfer(stake.staker, stake.amount);

        // Mark the stake as withdrawn
        stake.dateWithdrawn = block.timestamp;

        emit StakeRefunded(stake.staker, index, stake.amount);
    }

    /*
    * @notice returns the number of seconds remaining until the maturation date
    * @return Number of seconds remaining until the maturation date
    */
    function getTimeRemaining() public view returns (uint256) {
        return maturationDate - block.timestamp;
    }
}