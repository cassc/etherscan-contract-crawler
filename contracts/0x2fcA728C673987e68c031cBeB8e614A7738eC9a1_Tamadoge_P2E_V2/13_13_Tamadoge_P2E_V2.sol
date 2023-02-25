// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


interface IERC20Burnable is IERC20Upgradeable {
    function burn(uint256 amount) external;
}


contract Tamadoge_P2E_V2 is 
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    
    /// @dev Tamadoge Token Address
    IERC20Burnable public tamaToken;

    /// @dev Total tama burned till now by this contract and sent to burnWallet.
    uint256 public totalTamaBurned;

    /// @dev Total tama staked in this contract by users.
    uint256 public totalStakedAmountInContract;

    /// @dev Current amount of tama available in contract out of total staked by users.
    uint256 public currentStakedAmountAvailableInContract;

    /// @dev Tama Per Arcade Credit bought to send to reward pool.
    uint256 public tamaPerCreditToSendToRewardPool;

    /**
     * Percentage of tama to
     * - Send to staking reward pool
     * - To burn
     * From the tama left after sending (tamaPerCreditToSendToRewardPool * creditsBought) to p2eRewardPoolBalance.
     */
    uint256 public tamaPercentageToSendToStakingRewardPool;
    uint256 public tamaPercentageToBurn;

    /// @dev Balance of P2E Reward Pool used to distribute rewards to game winners from leaderboard.
    uint256 public p2eRewardPoolBalance;

    /// @dev Balance of Staking Reward pool, used to buy arcade credits for users staking tama.
    uint256 public stakingRewardsPoolBalance;

    /// @dev Total available plans for buying arcade credits with tama (active + inactive)
    uint256 public arcadeCreditBuyPlansAvailable;

    /// @dev Total available plans for staking tama (active + inactive)
    uint256 public tamaStakePlansAvailable;


    struct ArcadeCreditBuyPlan {
        uint256 arcadeCredits;
        uint256 tamaRequired;
        bool isActive;
    }

    struct TamaStakePlan {
        uint256 stakeDurationInSeconds;
        bool isActive;
    }

    struct TamaStake {
        uint256 stakedAmount;
        uint256 stakeTime;
        uint256 tamaStakePlanId;
    }

    struct UserStakes {
        uint256 totalStakes;
        uint256 totalAmountStaked;
        mapping(uint256 => TamaStake) tamaStakes;
    }

    // Mapping arcade credit buy plan id => plan struct
    mapping(uint256 => ArcadeCreditBuyPlan) public arcadeCreditBuyPlans;

    // Mapping tama stake plan id => plan struct
    mapping(uint256 => TamaStakePlan) public tamaStakePlans;

    // Mapping address to UserStakes struct
    mapping(address => UserStakes) private stakes;

    // Map gameIds to IPFS result hash
    mapping(uint256 => string) public gameResults;

    // Storage variables for EIP-712 signatures.
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TAMA_REWARD_CLAIM_TYPEHASH = keccak256("TamaRewardClaim(address receiver,uint256 tamaAmount,uint256 claimNumber)");

    struct TamaRewardClaim {
        address receiver;
        uint256 tamaAmount;
        uint256 claimNumber;
    }

    mapping(bytes => bool) private isSignatureUsed;
    // Mapping addresses to the total no of times they have claimed tama rewards.
    mapping(address => uint256) public totalTamaClaims;

    // Tama Burn wallet address.
    address public burnWallet;
    

    // Event for users buying arcade credits with tama.
    event ArcadeCreditsBought(
        address indexed by,
        uint256 indexed arcadeCreditBuyPlan,
        uint256 arcadeCreditsBought,
        uint256 tamaPaid,
        uint256 timestamp
    );
    
    // Event for arcade credits bought from stakingRewardsPoolBalance by owner/admin.
    event ArcadeCreditsBoughtFromStakingRewardsPool(
        address indexed by, 
        uint256 indexed totalArcadeCreditsBought, 
        uint256 indexed totalTamaRequired, 
        uint256 tamaPercentageToBurn, 
        uint256 tamaPercentageToSendToStakingRewardPool,
        uint256 tamaAddedToP2eRewardPool,
        uint256 tamaBurned,
        uint256 stakingRewardsPoolBalance,
        uint256 timestamp
    );

    // Events for users staking/unstaking tama tokens in contract for receiving arcade credits.
    event TamaStaked(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeId,
        uint256 amount,
        uint256 timestamp,
        uint256 unlockTime
    );
    
    event TamaUnstakedBatch(
        address indexed by,
        uint256[] stakeIds,
        uint256 totalUnstakedTamaAmount,
        uint256 timestamp
    );
    
    // Events for owner/admin withdrawing user-deposited tama from contract or depositing it back.
    event TamaTokensWithdrawnFromUserStakes(
        address indexed by,
        uint256 amount,
        uint256 timestamp
    );

    event TamaTokensDepositedToUserStakes(
        address indexed by,
        uint256 amount,
        uint256 timestamp
    );

    // Events for activating, deactivating, updating an existing ArcadeCreditBuyPlan and for adding a new one.
    event ActivatedArcadeCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event DeactivatedArcadeCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event UpdatedArcadeCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 arcadeCredits,
        uint256 tamaRequired,
        uint256 timestamp
    );

    event AddedNewArcadeCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 arcadeCredits,
        uint256 tamaRequired,
        bool isActivated,
        uint256 timestamp
    );

    // Events for activating, deactivating, updating an existing TamaStakePlan and for adding a new one.
    event ActivatedTamaStakePlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event DeactivatedTamaStakePlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event UpdatedTamaStakePlan(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeDurationInSeconds,
        uint256 timestamp
    );

    event AddedNewTamaStakePlan(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeDurationInSeconds,
        bool isActivated,
        uint256 timestamp
    );

    // Event for tama payouts from p2e reward pool balance.
    event TamaPayoutFromP2eRewardPool(
        address indexed by,
        address[] addresses,
        uint256[] amounts,
        uint256 p2eRewardPoolBalanceLeft,
        uint256 timestamp
    );

    // Event for publishing game results on IPFS.
    event GameResultPublished(
        address indexed by,
        uint256 indexed gameId,
        string result,
        uint256 timestamp
    );

    event UpdatedTamaPerCreditToRewardPool (
        address indexed by,
        uint256 tamaPerCreditToSendToRewardPool,
        uint256 timestamp
    );

    event UpdatedTamaDistributionPercentages(
        address indexed by,
        uint256 tamaPercentageToBurn,
        uint256 tamaPercentageToSendToStakingRewardPool,
        uint256 timestamp
    );

    event TamaRewardClaimed(
        address indexed by,
        uint256 amount,
        uint256 claimNumber,
        bytes signature,
        uint256 timestamp
    );

    event UpdatedBurnWallet(
        address indexed by,
        address newBurnWallet,
        uint256 timestamp
    );

    event P2eRewardPoolBalanceIncreased(
        address indexed by,
        uint256 tamaAdded,
        uint256 p2eRewardPoolBalance,
        uint256 timestamp
    );


    /// @dev msg.sender must be contract owner or have DEFAULT_ADMIN_ROLE.
    modifier onlyAdminOrOwner() {
        require(
            msg.sender == owner() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin/owner."
        );
        _;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract.
     * @param _tamaToken Address of the deployed tama token contract.
     * @param _adminWallet Address of the account to be given the DEFAULT_ADMIN_ROLE.
     * @param _tamaPerCreditToSendToRewardPool Amount to tama to be sent to P2E reward pool on each arcade credit bought.
     * @param _tamaPercentageToSendToStakingRewardPool Percentage of tama to be sent to Staking reward pool from tama left after its sent to p2eRewardPool.
     * @param _tamaPercentageToBurn Percentage of tama to be burned from tama left after its sent to p2eRewardPool.
     * @param _arcadeCreditBuyPlans Arcade Credit Buy Plans with which contract is to be initialized.
     * @param _tamaStakePlans Tama Stake Plans with which contract is to be initialized.
     */
    function initialize(
        address _tamaToken,
        address _adminWallet,
        uint256 _tamaPerCreditToSendToRewardPool,
        uint256 _tamaPercentageToSendToStakingRewardPool,
        uint256 _tamaPercentageToBurn,
        ArcadeCreditBuyPlan[] memory _arcadeCreditBuyPlans,
        TamaStakePlan[] memory _tamaStakePlans
    ) external initializer {
        require(
            _tamaToken != address(0) && _adminWallet != address(0),
            "Null address."
        );
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );

        __AccessControl_init();
        __Ownable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        tamaToken = IERC20Burnable(_tamaToken);

        tamaPerCreditToSendToRewardPool = _tamaPerCreditToSendToRewardPool;
        tamaPercentageToSendToStakingRewardPool = _tamaPercentageToSendToStakingRewardPool;
        tamaPercentageToBurn = _tamaPercentageToBurn;

        addNewArcadeCreditBuyPlans(_arcadeCreditBuyPlans);
        addNewTamaStakePlans(_tamaStakePlans);
    }


    /**
     * @notice Creates the EIP-712 domain separator.
     * @param _name Domain name
     * @param _version Domain version
     * @param _reinitializeVersion Re-Initialization version number.
     */
    function createEip712Domain(
        string memory _name,
        string memory _version,
        uint8 _reinitializeVersion
    ) external onlyAdminOrOwner reinitializer(_reinitializeVersion) {
        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes(_version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }


    /**
     * @notice Function for owner/admin to add tama directly to the p2e Reward Pool.
     * @param _tamaAmount Amount of tama to add to the p2e reward pool.
     */
    function increaseP2eRewardPoolBalance(uint256 _tamaAmount) external onlyAdminOrOwner {
        p2eRewardPoolBalance += _tamaAmount;
        require(
            tamaToken.transferFrom(msg.sender, address(this), _tamaAmount),
            "Error while transferring tama!"
        );

        emit P2eRewardPoolBalanceIncreased(
            msg.sender,
            _tamaAmount, 
            p2eRewardPoolBalance,
            block.timestamp
        );
    }


    /**
     * @notice Function to buy arcade credits with tamadoge tokens.
     * @dev Needs tama allowance from buyer.
     * @param _planId Id of the available arcade credit buy plan that user wants to buy arcade credits with.
     */
    function buyArcadeCredits(uint256 _planId) external {
        // Plan must be valid.
        require(
            _planId != 0 && _planId <= arcadeCreditBuyPlansAvailable,
            "Invalid plan id."
        );

        // Retrieve arcade buy plan details for given id.
        ArcadeCreditBuyPlan memory plan = arcadeCreditBuyPlans[_planId];

        // Plan must be active.
        require(plan.isActive, "Plan inactive.");

        // This contract should have sufficient tama allowance from msg.sender.
        require(
            tamaToken.allowance(msg.sender, address(this)) >= plan.tamaRequired,
            "Insufficient tama allowance."
        );
        
        // Calculate tama to be sent to p2eRewardPool.
        uint256 tamaToSendToP2EPool = tamaPerCreditToSendToRewardPool * plan.arcadeCredits;

        // Calculate the value of tama tokens to be burned.
        uint256 tamaToBurn = ((plan.tamaRequired - tamaToSendToP2EPool) * tamaPercentageToBurn) / 10000;

        // Increment value of total tama burned by contract.
        totalTamaBurned += tamaToBurn;

        // Increment Staking Reward Pool balance by percentage set.
        stakingRewardsPoolBalance += (plan.tamaRequired - tamaToSendToP2EPool - tamaToBurn);
        
        // Increment p2eRewardPoolBalance.
        p2eRewardPoolBalance += tamaToSendToP2EPool;

        // Emit ArcadeCreditsBought event.
        emit ArcadeCreditsBought(
            msg.sender,
            _planId,
            plan.arcadeCredits,
            plan.tamaRequired,
            block.timestamp
        );

        // Transfer tama from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), plan.tamaRequired),
            "Error in transferring tama."
        );

        // Send tama tokens to the burnWallet.
        require(
            tamaToken.transfer(burnWallet, tamaToBurn),
            "Error in transferring tama to burnWallet."
        );
    }


    /**
     * @notice Function for admin/owner to buy arcade credits from stakingRewardsPoolBalance for users who have staked tama in this contract.
     * @param _totalArcadeCreditsToBuy Total amount of arcade credits to be bought.
     * @param _totalTamaRequired Total amount of tama required for buying these arcade credits. Should be >= (tamaPerCreditToSendToRewardPool * _totalArcadeCreditsToBuy).
     * @param _tamaPercentageToBurn Percentage of tama tokens to send to burnWallet.
     * @param _tamaPercentageToSendToStakingRewardPool Percentage of tama to be sent/kept back in the stakingRewardsPool.
     */
    function buyArcadeCreditsFromStakingRewardPool(
        uint256 _totalArcadeCreditsToBuy,
        uint256 _totalTamaRequired,
        uint256 _tamaPercentageToBurn,
        uint256 _tamaPercentageToSendToStakingRewardPool
    ) external onlyAdminOrOwner {

        require(
            _totalArcadeCreditsToBuy * tamaPerCreditToSendToRewardPool <= _totalTamaRequired,
            "_totalArcadeCreditsToBuy * tamaPerCreditToSendToRewardPool is greater than _totalTamaRequired"
        );
        require(
            _totalTamaRequired <= stakingRewardsPoolBalance,
            "Insufficient tama in stakingRewardsPoolBalance"
        );
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );
        
        // Calculate tama to be sent to p2eRewardPool.
        uint256 tamaToSendToP2EPool = tamaPerCreditToSendToRewardPool * _totalArcadeCreditsToBuy;

        // Calculate the value of tama tokens to be burned.
        uint256 tamaToBurn = ((_totalTamaRequired - tamaToSendToP2EPool) * _tamaPercentageToBurn) / 10000;

        // Increment value of total tama burned by contract.
        totalTamaBurned += tamaToBurn;

        // Decrement the stakingRewardsPoolBalance.
        stakingRewardsPoolBalance -= (tamaToSendToP2EPool + tamaToBurn);

        // Increment p2eRewardPoolBalance.
        p2eRewardPoolBalance += tamaToSendToP2EPool;

        // Emit ArcadeCreditsBoughtFromStakingRewardsPool event.
        emit ArcadeCreditsBoughtFromStakingRewardsPool(
            msg.sender, 
            _totalArcadeCreditsToBuy, 
            _totalTamaRequired, 
            _tamaPercentageToBurn, 
            _tamaPercentageToSendToStakingRewardPool, 
            tamaToSendToP2EPool, 
            tamaToBurn, 
            stakingRewardsPoolBalance, 
            block.timestamp
        );

        // Send tama tokens to the burnWallet.
        require(
            tamaToken.transfer(burnWallet, tamaToBurn),
            "Error in transferring tama to burnWallet."
        );
    }


    /**
     * @notice Function for user to lock tama tokens for fixed period of time to get arcade credits as reward.
     * @param _planId Id of the stake plan to use for locking tama tokens.
     * @param _amountToStake Amount of tama tokens to lock/stake.
     */
    function stakeTama(uint256 _planId, uint256 _amountToStake) external {
        // Stake amount must be greater than zero.
        require(_amountToStake > 0, "Stake amount must be greater than zero.");

        // PLan must be valid.
        require(_planId != 0 && _planId <= tamaStakePlansAvailable , "Invalid plan id.");

        // Plan must be active.
        require(tamaStakePlans[_planId].isActive, "Plan inactive.");

        // This contract should have sufficient tama allowance from msg.sender.
        require(
            tamaToken.allowance(msg.sender, address(this)) >= _amountToStake,
            "Insufficient tama allowance."
        );

        // Update storage variables for user's stakes.
        UserStakes storage userStake = stakes[msg.sender];
        userStake.totalStakes += 1;
        userStake.totalAmountStaked += _amountToStake;

        userStake.tamaStakes[userStake.totalStakes] = TamaStake(
            _amountToStake,
            block.timestamp,
            _planId
        );

        // Update storage values of totalStakedAmountInContract and currentStakedAmountAvailableInContract.
        totalStakedAmountInContract += _amountToStake;
        currentStakedAmountAvailableInContract += _amountToStake;

        // Emit the TamaStaked event.
        emit TamaStaked(
            msg.sender,
            _planId,
            userStake.totalStakes,
            _amountToStake,
            block.timestamp,
            block.timestamp + tamaStakePlans[_planId].stakeDurationInSeconds
        );

        // Transfer tama from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), _amountToStake),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Batch function for unlocking/ unstaking tama tokens with the given stake ids.
     * @param _stakeIds An array of stake ids to be unstaked.
     */
    function batchUnstakeTama(uint256[] memory _stakeIds) external {
        // Read stake from storage.
        UserStakes storage userStakes = stakes[msg.sender];
        uint256 totalTamaUnstaked = 0;

        for(uint256 i=0; i<_stakeIds.length; i++) {

            uint256 _stakeId = _stakeIds[i];
            TamaStake memory userTamaStake = userStakes.tamaStakes[_stakeId];

            // Check if id given is valid. 
            require(_stakeId <= userStakes.totalStakes, "Invalid id.");

            // If amount = 0, then tokens are unstaked already.
            require(userTamaStake.stakedAmount != 0, "Already unstaked.");

            // Check if the stake with given id can be unstaked.
            require(
                (userTamaStake.stakeTime + tamaStakePlans[userTamaStake.tamaStakePlanId].stakeDurationInSeconds) < block.timestamp,
                "Unlock time not reached."
            );

            // Delete stake struct info for this id in the mapping/ set values to 0.
            userStakes.tamaStakes[_stakeId].stakedAmount = 0;
            userStakes.tamaStakes[_stakeId].stakeTime = 0;
            userStakes.tamaStakes[_stakeId].tamaStakePlanId = 0;

            // Increment totalTamaUnstaked.
            totalTamaUnstaked += userTamaStake.stakedAmount;
        }
        
        // Check if currentStakedAmountAvailableInContract >= total amount being unstaked.
        require(
            currentStakedAmountAvailableInContract >= totalTamaUnstaked,
            "Insufficent staked balance in contract."
        );
        
        // Update totalAmountStaked for user.
        userStakes.totalAmountStaked -= totalTamaUnstaked;

        // Update totalStakedAmountInContract and currentStakedAmountAvailableInContract for this contract.
        totalStakedAmountInContract -= totalTamaUnstaked;
        currentStakedAmountAvailableInContract -= totalTamaUnstaked;

        // Emit the TamaUnstaked event.
        emit TamaUnstakedBatch(
            msg.sender,
            _stakeIds,
            totalTamaUnstaked,
            block.timestamp
        );

        // Transfer the tama tokens to msg.sender.
        require(
            tamaToken.transfer(msg.sender, totalTamaUnstaked),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Function for contract owner to withdraw tama from user stakes.
     * @dev Owner cannot withdraw more than currentStakedAmountAvailableInContract, even if contract has more tama.
     * @param _tokenAmount Amount of tama tokens to withdraw.
     */
    function withdrawTamaTokensFromUserStakes(uint256 _tokenAmount) external onlyOwner {
        // currentStakedAmountAvailableInContract must be equal/greater than amount being withdrawn.
        require(
            currentStakedAmountAvailableInContract >= _tokenAmount,
            "Insufficient staked balance."
        );

        // Decrement currentStakedAmountAvailableInContract storage variable value.
        currentStakedAmountAvailableInContract -= _tokenAmount;

        // Emit the event.
        emit TamaTokensWithdrawnFromUserStakes(
            msg.sender,
            _tokenAmount,
            block.timestamp
        );

        // Transfer tama tokens to msg.sender
        require(
            tamaToken.transfer(msg.sender, _tokenAmount),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Function for contract owner to deposit back tama that was withdrawn from user stakes.
     * @dev Increases value of currentStakedAmountAvailableInContract by _tokenAmount, if resultant value <= totalStakedAmountInContract.
     * @param _tokenAmount Amount to tama tokens to deposit back.
     */
    function depositTamaTokensBackToUserStakes(uint256 _tokenAmount) external onlyOwner {
        // currentStakedAmountAvailableInContract + _tokenAmount should be <= totalStakedAmountInContract
        require(
            currentStakedAmountAvailableInContract + _tokenAmount <= totalStakedAmountInContract,
            "Excessive deposit amount"
        );

        // Increment currentStakedAmountAvailableInContract storage variable value.
        currentStakedAmountAvailableInContract += _tokenAmount;

        // Emit the event.
        emit TamaTokensDepositedToUserStakes(
            msg.sender,
            _tokenAmount,
            block.timestamp
        );

        // Transfer tama tokens from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), _tokenAmount),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Batch function for owner/admin to activate multiple arcade credit buy plans at once.
     * @param _planIds An array of plan ids to be activated.
     */
    function batchActivateArcadeCreditBuyPlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {

            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= arcadeCreditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Activate the plan id.
            arcadeCreditBuyPlans[planId].isActive = true;
        }

        emit ActivatedArcadeCreditBuyPlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Batch function for owner/admin to deactivate multiple arcade credit buy plans at once.
     * @param _planIds An array of plan ids to be deactivated.
     */
    function batchDeactivateArcadeCreditBuyPlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {

            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= arcadeCreditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Deactivate the plan id.
            arcadeCreditBuyPlans[planId].isActive = false;
        }

        emit DeactivatedArcadeCreditBuyPlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to update an existing arcade credit buy plan.
     * @param _planId Id of the arcade credit buy plan to be updated.
     * @param _arcadeCredits New value of arcade credits for this plan.
     * @param _tamaRequired New value of tama required for this plan.
     */
    function updateArcadeCreditBuyPlan(uint256 _planId, uint256 _arcadeCredits, uint256 _tamaRequired) external onlyAdminOrOwner {
        // _planId should be valid.
        require(
            _planId != 0 && _planId <= arcadeCreditBuyPlansAvailable,
            "Invalid plan id."
        );
        
        // _arcadeCredits and _tamaRequired values must be greater than 0.
        require(_arcadeCredits > 0 && _tamaRequired > 0, "Cannot be zero.");
        
        // _tamaRequired should be >= (_arcadeCredits * tamaPerCreditToSendToRewardPool)
        require(
            _arcadeCredits * tamaPerCreditToSendToRewardPool <= _tamaRequired,
            "arcadeCredits * tamaPerCredit is greater than tama required."
        );
        // Read the plan from storage.
        ArcadeCreditBuyPlan storage plan = arcadeCreditBuyPlans[_planId];

        // Update the plan.
        plan.arcadeCredits = _arcadeCredits;
        plan.tamaRequired = _tamaRequired;

        emit UpdatedArcadeCreditBuyPlan(
            msg.sender,
            _planId,
            _arcadeCredits,
            _tamaRequired,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to add new arcade credit buy plans.
     * @param _arcadeCreditBuyPlans New arcade credit buy plans to be added.
     */
    function addNewArcadeCreditBuyPlans(ArcadeCreditBuyPlan[] memory _arcadeCreditBuyPlans)
        public
        onlyAdminOrOwner
    {
        uint256 tamaPerCredit = tamaPerCreditToSendToRewardPool;
        uint256 totalPlans = arcadeCreditBuyPlansAvailable;

        for(uint256 i=0; i<_arcadeCreditBuyPlans.length; i++) {
            require(
                _arcadeCreditBuyPlans[i].arcadeCredits > 0,
                "Arcade credits for plan cannot be 0."
            );
            require(
                _arcadeCreditBuyPlans[i].tamaRequired > 0,
                "Tama required for plan cannot be 0."
            );
            require(
                _arcadeCreditBuyPlans[i].arcadeCredits * tamaPerCredit <= _arcadeCreditBuyPlans[i].tamaRequired,
                "arcadeCredits * tamaPerCredit is greater than tama required."
            );

            // Increment local variable for total plans count, and store the new plan in storage.
            totalPlans += 1;
            arcadeCreditBuyPlans[totalPlans] = _arcadeCreditBuyPlans[i];

            emit AddedNewArcadeCreditBuyPlan(
                msg.sender,
                totalPlans,
                _arcadeCreditBuyPlans[i].arcadeCredits,
                _arcadeCreditBuyPlans[i].tamaRequired,
                _arcadeCreditBuyPlans[i].isActive,
                block.timestamp
            );
        }

        // Set arcadeCreditBuyPlansAvailable equal to totalPlans.
        arcadeCreditBuyPlansAvailable = totalPlans;
    }


    /**
     * @notice Batch function for owner/admin to activate multiple tama stake plans at once.
     * @param _planIds An array of plan ids to be activated.
     */
    function batchActivateTamaStakePlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {
            
            uint256 planId = _planIds[i];
            // planId should be valid.
            require(
                planId != 0 && planId <= tamaStakePlansAvailable,
                "Invalid plan id."
            );

            // Activate the plan id.
            tamaStakePlans[planId].isActive = true;
        }

        emit ActivatedTamaStakePlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Batch function for owner/admin to deactivate multiple tama stake plans at once.
     * @param _planIds An array of plan ids to be deactivated.
     */
    function batchDeactivateTamaStakePlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {
            
            uint256 planId = _planIds[i];
            // planId should be valid.
            require(
                planId != 0 && planId <= tamaStakePlansAvailable,
                "Invalid plan id."
            );

            // Deactivate the plan id.
            tamaStakePlans[planId].isActive = false;
        }

        emit DeactivatedTamaStakePlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to update an existing tama stake plan.
     * @param _planId Id of the tama stake plan to be updated.
     * @param _stakeDurationInSeconds New value of time for which tokens will be staked/locked for this plan.
     */
    function updateTamaStakePlan(uint256 _planId, uint256 _stakeDurationInSeconds) external onlyAdminOrOwner {
        // _planId should be valid.
        require(
            _planId != 0 && _planId <= tamaStakePlansAvailable,
            "Invalid plan id."
        );

        // _stakeDurationInSeconds must be greater than 0.
        require(_stakeDurationInSeconds > 0, "Stake duration cannot be zero.");

        // Update the plan.
        tamaStakePlans[_planId].stakeDurationInSeconds = _stakeDurationInSeconds;

        emit UpdatedTamaStakePlan(
            msg.sender,
            _planId,
            _stakeDurationInSeconds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to add new tama stake plans.
     * @param _tamaStakePlans New tama stake plans to be added.
     */
    function addNewTamaStakePlans(TamaStakePlan[] memory _tamaStakePlans) public onlyAdminOrOwner {
        uint256 totalPlans = tamaStakePlansAvailable;

        for(uint256 i=0; i<_tamaStakePlans.length; i++) {
            require(
                _tamaStakePlans[i].stakeDurationInSeconds > 0,
                "Stake duration cannot be 0."
            );
            totalPlans += 1;
            tamaStakePlans[totalPlans] = _tamaStakePlans[i];
            emit AddedNewTamaStakePlan(
                msg.sender,
                totalPlans,
                _tamaStakePlans[i].stakeDurationInSeconds,
                _tamaStakePlans[i].isActive,
                block.timestamp
            );
        }
        // Set the value of tamaStakePlansAvailable equal to totalPlans.
        tamaStakePlansAvailable = totalPlans;
    }


    /**
     * @notice Function for owner/admin to payout tama tokens to leaderboard winners from p2eRewardPoolBalance.
     * @dev p2eRewardPoolBalance must have sufficient tama to carry out all transfers.
     * @param _addresses An array of addresses to be given the tama payout.
     * @param _amounts An array of tama token amounts to be given as payout to respective address from _addresses array.
     */
    function payoutTama(address[] memory _addresses, uint256[] memory _amounts) external onlyAdminOrOwner {
        require(_addresses.length == _amounts.length, "Array length mismatch.");
        uint256 totalTamaPaid;

        for(uint i=0; i<_addresses.length; i++) {
            totalTamaPaid += _amounts[i];
            require(
                tamaToken.transfer(_addresses[i], _amounts[i]),
                "Error while transferring tama."
            );
        }

        require(
            totalTamaPaid <= p2eRewardPoolBalance,
            "Insufficient tama in p2eRewardPoolBalance"
        );

        // Decrement p2e reward pool balance.
        p2eRewardPoolBalance -= totalTamaPaid;

        emit TamaPayoutFromP2eRewardPool(
            msg.sender,
            _addresses,
            _amounts,
            p2eRewardPoolBalance,
            block.timestamp
        );
    }


    /**
     * @notice Function to claim tama tokens from p2eRewardPool with admin signature.
     */
    function claimTamaRewards(TamaRewardClaim memory _data, bytes memory _signature) external {
        require(
            !isSignatureUsed[_signature],
            "Already claimed!"
        );
        require(
            msg.sender == _data.receiver,
            "Not the receiver!"
        );
        require(
            _data.claimNumber == ++totalTamaClaims[_data.receiver],
            "Invalid claim number!"
        );
        require(
            p2eRewardPoolBalance >= _data.tamaAmount,
            "Insufficient p2e reward pool balance!"
        );
        require(
            _verifySignature(_data, _signature),
            "Invalid signature!"
        );

        isSignatureUsed[_signature] = true;
        p2eRewardPoolBalance -= _data.tamaAmount;
        require(
            tamaToken.transfer(msg.sender, _data.tamaAmount),
            "Error while transferring tama."
        );

        emit TamaRewardClaimed(
            msg.sender,
            _data.tamaAmount,
            _data.claimNumber,
            _signature,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to change the tama per credit to be sent to p2e reward pool when arcade credits are bought.
     * @param _tamaPerCreditToSendToRewardPool New value for tamaPerCreditToSendToRewardPool, cannot be zero.
     */
    function updateTamaPerCreditToSendToRewardPool(uint256 _tamaPerCreditToSendToRewardPool) external onlyAdminOrOwner {
        require(
            _tamaPerCreditToSendToRewardPool != 0,
            "Cannot be zero."
        );
        tamaPerCreditToSendToRewardPool = _tamaPerCreditToSendToRewardPool;
        emit UpdatedTamaPerCreditToRewardPool(
            msg.sender,
            _tamaPerCreditToSendToRewardPool,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to change the tama token distribution percentages when arcade credits are bought.
     */
    function updateTamaDistributionPercentages(
        uint256 _tamaPercentageToSendToStakingRewardPool,
        uint256 _tamaPercentageToBurn
    ) external onlyAdminOrOwner {
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );
        tamaPercentageToSendToStakingRewardPool = _tamaPercentageToSendToStakingRewardPool;
        tamaPercentageToBurn = _tamaPercentageToBurn;

        emit UpdatedTamaDistributionPercentages(
            msg.sender,
            _tamaPercentageToBurn,
            _tamaPercentageToSendToStakingRewardPool,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to update the burn wallet address.
     * @param _burnWallet Address to be the new burnWallet.
     */
    function updateBurnWallet(address _burnWallet) external onlyOwner {
        require(
            _burnWallet != address(0),
            "Zero address provided!"
        );

        burnWallet = _burnWallet;
        emit UpdatedBurnWallet(
            msg.sender,
            _burnWallet,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to publish the IPFS result hash onchain for a gameId.
     * @param _gameId Id of the game for which result is being published.
     * @param _result String with IPFS result hash of the game.
     */
    function publishIpfsResult(uint256 _gameId, string memory _result) external onlyAdminOrOwner {
        // Result should not be declared already for this id.
        require(
            bytes(gameResults[_gameId]).length == 0,
            "Result already declared for this game id."
        );

        // Result string passed should not be empty.
        require(
            bytes(_result).length != 0,
            "Empty string."
        );

        // Store the result in gameResults mapping.
        gameResults[_gameId] = _result;

        emit GameResultPublished(
            msg.sender,
            _gameId,
            _result,
            block.timestamp
        );
    }


    /**
     * @notice Function to get total amount of tama currently staked in contract by an address.
     * @param _address Address for which to get the amount of tama staked.
     */
    function getTotalTamaStaked(address _address) external view returns(uint256) {
        return stakes[_address].totalAmountStaked;
    }


    /**
     * @notice Function to get total no of tama stakes ever done by an address in this contract.
     * @param _address Address for which to get the number of tama stakes done..
     */
    function getTotalStakes(address _address) external view returns(uint256) {
        return stakes[_address].totalStakes;
    }


    /**
     * @notice Function to get info of a particular stake id for an address.
     * @param _address Address of user for whom to get the stake info.
     * @param _stakeId Id of the stake whose info to get.
     */
    function getStake(address _address, uint256 _stakeId) external view returns(TamaStake memory) {
        return stakes[_address].tamaStakes[_stakeId];
    }


    /**
     * @notice Function to get info of all stakes for an address.
     * @param _address Address for which to get stake info.
     */
    function getAllStakes(address _address) external view returns(TamaStake[] memory) {
        UserStakes storage userStakesInfo = stakes[_address];

        uint256 totalUserStakes = userStakesInfo.totalStakes;
        TamaStake[] memory allStakes = new TamaStake[](totalUserStakes);

        for(uint256 i=0; i<userStakesInfo.totalStakes; i++) {
            allStakes[i] = userStakesInfo.tamaStakes[i+1];
        }

        return allStakes;
    }


    /**
     * @notice Function to get the total no of active stakes for an address.
     * @param _address Address for whom to get the total active stakes.
     */
    function getTotalActiveStakes(address _address) public view returns(uint256) {
        UserStakes storage userStakesInfo = stakes[_address];
        uint256 totalUserStakes = userStakesInfo.totalStakes;

        uint256 totalActiveStakes = 0;
        for(uint256 i=1; i<=totalUserStakes; i++) {
            if (
                userStakesInfo.tamaStakes[i].stakeTime + 
                    tamaStakePlans[userStakesInfo.tamaStakes[i].tamaStakePlanId].stakeDurationInSeconds >
                        block.timestamp
            ) {
                totalActiveStakes += 1;
            }
        }
        return totalActiveStakes;
    }


    /**
     * @notice Function to get info about the active tama stakes for an address.
     * @param _address Address of user for whom to return the all active stakes.
     */
    function getAllActiveStakes(address _address) external view returns(TamaStake[] memory) {
        uint256 totalActiveStakes = getTotalActiveStakes(_address);

        UserStakes storage userStakesInfo = stakes[_address];
        TamaStake[] memory activeStakes = new TamaStake[](totalActiveStakes);
        uint256 index = 0;

        for(uint256 i=1; i<=userStakesInfo.totalStakes; i++) {
            if(
                userStakesInfo.tamaStakes[i].stakeTime +
                    tamaStakePlans[userStakesInfo.tamaStakes[i].tamaStakePlanId].stakeDurationInSeconds >
                        block.timestamp
            ) {
                activeStakes[index] = userStakesInfo.tamaStakes[i];
                index += 1;
            }
        }

        return activeStakes;
    }


    /**
     * @notice Returns details of all the arcade credit buy plans available.
     */
    function getAllArcadeCreditBuyPlans() external view returns(ArcadeCreditBuyPlan[] memory) {
        uint256 totalPlans = arcadeCreditBuyPlansAvailable;
        ArcadeCreditBuyPlan[] memory plans = new ArcadeCreditBuyPlan[](totalPlans);

        for(uint256 i=0; i<totalPlans; i++) {
            plans[i] = arcadeCreditBuyPlans[i+1];
        }
        return plans;
    }


    /**
     * @notice Returns details of all the tama stake plans available.
     */
    function getAllTamaStakePlans() external view returns(TamaStakePlan[] memory) {
        uint256 totalPlans = tamaStakePlansAvailable;
        TamaStakePlan[] memory plans = new TamaStakePlan[](totalPlans);

        for(uint256 i=0; i<totalPlans; i++) {
            plans[i] = tamaStakePlans[i+1];
        }
        return plans;
    }


    // ----------------------------EIP-712 functions.------------------------------------------------------------------
    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }


    /**
     * @dev Verifies the given signature. Signer should have DEFAULT_ADMIN_ROLE.
     * @param _data Tuple for TamaRewardClaim struct input.
     * @param _signature The signature to verify.
     * @return Boolean, true if signature is valid & signer has DEFAULT_ADMIN_ROLE, otherwise false.
     */
    function _verifySignature(TamaRewardClaim memory _data, bytes memory _signature) private view returns(bool) {
        bytes32 digest = _getDigest(_data);
        address signer = _getSigner(digest, _signature);

        // Check if signer has DEFAULT_ADMIN_ROLE.
        return hasRole(DEFAULT_ADMIN_ROLE, signer);
    }

    function _getDigest(TamaRewardClaim memory _data) private view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(
                _TAMA_REWARD_CLAIM_TYPEHASH,
                _data.receiver,
                _data.tamaAmount,
                _data.claimNumber
            ))
        );
    }

    function _getSigner(bytes32 _digest, bytes memory _signature) private pure returns(address) {
        return ECDSAUpgradeable.recover(_digest, _signature);
    }

}