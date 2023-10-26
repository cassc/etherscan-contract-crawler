// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

/** 
* @title NFAiGatewayInterface
* @notice Interface for the NFAiStakingLottery contract
* @dev Defines the methods and custom errors for the NFAiStakingLottery contract
*/
interface NFAiGatewayInterface {

    /**
    * @notice Custom Events
    */
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event WinnerDrawn(address indexed winner, uint256 amount);
    event RandomnessRequested(uint256 requestId);
    event RandomnessFulfilled(uint256 requestId, uint256 randomResult);
    event ParticipationConfirmed(address indexed user);
    event PrizeTokensDeposited(address indexed owner, uint256 amount);

    /**
    * @notice Custom Errors
    */
    error AbnormalRandomResult();
    error InsufficientEligibleParticipants();
    error TotalWeightInsuffiency();
    error ZeroAdrWinner();
    error ZeroAmount();
    error RequestRandomnessFailed();
    error NoRandomnessProvided();
    error UnmatchedRequest();
    error NotUser(address caller);
    error TransferFailed();

    /**
    * @notice Wrapper function for staking tokens
    * @param amount Amount of tokens to stake
    * @param user Address of the user
    */
    function stake(uint256 amount, address user) external;

    /**
    * @notice Wrapper function for unstaking tokens
    * @param user Address of the user
    */
    function unstake(address user) external;

    /**
    * @notice Wrapper function for drawing winners
    * @param _drawingStrategy The drawing strategy to use
    * @param _numberOfWinners The number of winners to draw
    */
    function draw(uint8 _drawingStrategy, uint256 _numberOfWinners) external;

    /** 
    * @notice Wrapper function for refreshing the staking time.
    * @param user Address of the user
    * @dev This function is used to refresh the staking time for the caller.
    */ 
    function confirmParticipation(address user) external;

    /**
    * @dev Set the minimum staking time.
    * @param _minutes Minimum staking time in minutes.
    */
    function setMinimumStakeTime(uint256 _minutes) external;

    /**
    * @param ethTO Address to send the ETH to.
    * @param ercTO Address to send the ERC to.
    * @param tokenAdr Address of the token to withdraw.
    * @dev Emergency function to withdraw stuck ETH/ERC.
    */
    function emergencyWithdraw(address ethTO, address ercTO, address tokenAdr) external;

    /**
    * @notice Get the stakers addresses
    * @return Array of addresses of all stakers
    */
    function getStakers() external view returns (address[] memory);

    /** 
    * @notice Get the staked amount for a specific user
    * @param user Address of the user
    * @return Amount of tokens staked by the user
    */ 
    function getStakerAmount(address user) external view returns (uint256);

    /**
    * @notice Get the staked time for a specific user
    * @param user Address of the user
    * @return Timestamp of the last stake
    */
    function getStakerTime(address user) external view returns (uint256);

    /** 
    * @notice Get the total staked amount
    * @return Total amount of tokens staked
    */
    function getTotalStaked() external view returns (uint256);

    /**
    * @notice Get the total eligible staked amount
    * @return Total amount of tokens staked by eligible users
    */
    function getTotalEligibleStaked() external view returns (uint256);

    /** 
    * @notice Get the last winner
    * @return Address of the last winner
    * @return Amount won by the last winner
    * @return Timestamp of the last winner
    */
    function getLastWinnerInfo() external view returns (address, uint256, uint256);

    /**
    * @notice Get the last winner amount
    * @return All addresses of all historical winners
    * @return All amounts won by all historical winners
    */
    function getAllWinnerInfo() external view returns (address[] memory, uint256[] memory);
    /**
    * @notice Get the minimum stake time to be eligible for the lottery
    * @return Minimum stake time in minutes
    */
    function getMinimumStakeTime() external view returns (uint256);

    /**
    * @notice Get the eligibility of all stakers
    * @return Returns a single entity back.
    */
    function getEligibility(address user) external view returns (bool);

    /**
    * @notice Get the odds of winning for a specific user
    * @param user Address of the user
    * @return Odds of winning for the user as a percentage multiplied by 10^4
    */
    function getUserOdds(address user) external view  returns (uint256);

    /**
    * @notice Get ERC20 Token Address Registered for Staking
    * @return Address registered for IERC20
    */
    function getRegisteredToken() external view returns (address);

    /**
    * @notice Set the initial values for the contract
    * @param _keyHash The key hash for the Chainlink VRF Coordinator
    * @param subscriptionId The subscription ID for the Chainlink VRF Coordinator
    * @param _callbackGasLimit The callback gas limit for the Chainlink VRF Coordinator
    * @param _minimumRequestConfirmations The minimum request confirmations for the Chainlink VRF Coordinator
    * @param _numWords The number of words for the Chainlink VRF Coordinator
    * @param _token Address of the token to use for staking
    */
    function setInitializingFactors(
        bytes32 _keyHash, 
        uint64 subscriptionId, 
        uint32 _callbackGasLimit, 
        uint16 _minimumRequestConfirmations, 
        uint32 _numWords, 
        address _token
    ) external;

   /**
    * @notice Allows the owner to deposit prize tokens.
    * @param amount Amount of tokens to deposit.
    */
    function depositPrizeTokens(uint256 amount) external;

    /**
    * @notice Get the prize pool amount
    * @return Amount in the prize pool
    */    
    function getPrizePool() external view returns (uint256);
}