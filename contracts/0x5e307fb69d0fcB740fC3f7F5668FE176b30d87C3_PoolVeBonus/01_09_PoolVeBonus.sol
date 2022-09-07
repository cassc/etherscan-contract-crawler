pragma solidity 0.8.6;

import "IJellyContract.sol";
import "IJellyAccessControls.sol";
// import "IERC20.sol";

import "IJellyPool.sol";
import "SafeERC20.sol";



interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

}

interface IVeToken {
    function create_lock_for(uint _value, uint _lock_duration, address _to) external returns (uint);
}

// interface IJellyPoolHelper {
//     function unclaimedRewards(address _pool, address _rewardToken, uint256 _tokenId) external view returns(uint256);
//     function getTokenRewardsClaimed(address _pool, address _rewardToken, uint256 _tokenId) external view returns(uint256 rewardsClaimed);
// }

struct TokenRewards {
    uint128 rewardsEarned;
    uint128 rewardsReleased;
    uint48 lastUpdateTime;
    uint208 lastRewardPoints;
}

interface IJellyPoolWrapper {
    function tokenRewards(uint256 _tokenId, address _rewardToken) external view returns (TokenRewards memory);
    function fancyClaim(uint256 _tokenId) external;
    function getOwnerTokens(address _owner) external view returns (uint256[] memory);
}


contract PoolVeBonus is IJellyContract {    
    
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template type and id for the factory.
    uint256 public constant override TEMPLATE_TYPE = 9;
    bytes32 public constant override TEMPLATE_ID = keccak256("POOL_VE_BONUS");
    uint256 private constant PERCENTAGE_PRECISION = 10000;
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 public constant pointMultiplier = 10e12;

    /// @notice Address that manages approvals.
    IJellyAccessControls public accessControls;

    /// @notice Reward token address.
    address public poolToken;

    /// @notice Is the pool enabled?
    mapping(address => bool) public poolEnabled;

    /// @notice ve contract for locking tokens.
    address public veToken;
    /// @notice JellyVault is where fees are sent.
    address private jellyVault;
    /// @notice The fee percentage out of 10000 (100.00%)
    uint256 private feePercentage;
    /// @notice Current total rewards paid.
    uint256 public rewardsPaid;
    /// @notice Total tokens to be distributed.
    uint256 public totalTokens;

    /// @notice Mapping of Pool -> TokenID -> amount of tokens locked. 
    mapping(address => mapping(uint256 => uint256)) public rewardsLocked;


    uint256 public lockDuration;
    uint256 public bonusPercentage;
    /// @notice Whether contract has been initialised or not.
    bool private initialised;


    /**
     * @notice Event emitted when reward tokens have been added to the pool.
     * @param amount Number of tokens added.
     * @param fees Amount of fees.
     */
    event RewardsAdded(uint256 amount, uint256 fees);
    /**
     * @notice Event emitted for Jelly admin updates.
     * @param vault Address of the new vault address.
     * @param fee New fee percentage.
     */
    event JellyUpdated(address vault, uint256 fee);
    /**
     * @notice Event emitted for when tokens are recovered.
     * @param token ERC20 token address.
     * @param amount Token amount in wei.
     */
    event Recovered(address token, uint256 amount);

    //--------------------------------------------------------
    // Setters
    //--------------------------------------------------------

    /// @dev Setter functions for setting lock duration
    function setLockDuration(uint256 _lockDuration) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setLockDuration: Sender must be admin"
        );
        lockDuration = _lockDuration;
    }


    /// @dev Setter functions for enabling pool contracts
    function setPoolEnabled(address _pool, bool _enabled) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setPoolEnabled: Sender must be admin"
        );
        poolEnabled[_pool] = _enabled;
    }

    //--------------------------------------------------------
    // Rewards
    //--------------------------------------------------------


    /// @dev Setter functions for contract config
    function setBonusPercentage(uint256 _bonusPercentage) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setBonusPercentage: Sender must be admin"
        );
        // PW: Removed this require, as no reason not to have +2x bonus
        // require(_bonusPercentage < PERCENTAGE_PRECISION); // dev: feePercentage greater than 10000 (100.00%)
        bonusPercentage = _bonusPercentage;
    }

    /**
     * @notice Add more tokens to the JellyDrop contract.
     * @param _rewardAmount Amount of tokens to add, in wei. (18 decimal place format)
     */
    function addRewards(uint256 _rewardAmount) public {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender), "addRewards: Sender must be admin/operator");
        OZIERC20(poolToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
        uint256 tokensAdded = _rewardAmount * PERCENTAGE_PRECISION  / (feePercentage + PERCENTAGE_PRECISION);
        uint256 jellyFee =  _rewardAmount * feePercentage / (feePercentage + PERCENTAGE_PRECISION);
        totalTokens += tokensAdded ;

        OZIERC20(poolToken).safeTransfer(jellyVault, jellyFee);
        emit RewardsAdded(_rewardAmount, jellyFee);
    }


    /**
     * @notice Jelly vault can update new vault and fee.
     * @param _vault New vault address.
     * @param _fee Fee percentage of tokens distributed.
     */
    function updateJelly(address _vault, uint256 _fee) external  {
        require(jellyVault == msg.sender); // dev: updateJelly: Sender must be JellyVault
        require(_vault != address(0)); // dev: Address must be non zero
        require(_fee < PERCENTAGE_PRECISION); // dev: feePercentage greater than 10000 (100.00%)

        jellyVault = _vault;
        feePercentage = _fee;
        emit JellyUpdated(_vault, _fee);
    }

    //--------------------------------------------------------
    // Bonus
    //--------------------------------------------------------
    /**
     * @notice Claims rewards from pool and locked in ve with bonus rewards.
     */
    function claimAndLock(address _pool) external returns (uint) {
        require(poolEnabled[_pool] == true, "Incorrect pool");
        IJellyPoolWrapper tokenPool = IJellyPoolWrapper(_pool);
        uint256[] memory tokenIds = tokenPool.getOwnerTokens(msg.sender);
        uint256 amountClaimed = 0;

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 amountBefore = getTokenRewardsClaimed(address(tokenPool), poolToken, tokenIds[i]);
                tokenPool.fancyClaim(tokenIds[i]);
                uint256 amountAfter = getTokenRewardsClaimed(address(tokenPool), poolToken, tokenIds[i]);
                amountClaimed += amountAfter - amountBefore;
                rewardsLocked[_pool][tokenIds[i]] += amountAfter - amountBefore;
                require(rewardsLocked[_pool][tokenIds[i]] <= amountAfter, "Locking more tokens than has been earnt.");
            }
        }   

        return _lockAmount(msg.sender, amountClaimed);

    }

    /**
     * @notice Claims rewards from specific tokenID and locked in ve with bonus rewards.
     * @param _tokenId Pool tokenID which has the unclaimed rewards.
     */
    function claimAndLockByTokenId(address _pool, uint _tokenId) external returns (uint) {
        require(poolEnabled[_pool] == true, "Incorrect pool");
        require(IERC721(_pool).ownerOf(_tokenId) == msg.sender, "Must own tokenId");

        uint256 amountBefore = getTokenRewardsClaimed(_pool, poolToken, _tokenId);
        IJellyPoolWrapper(_pool).fancyClaim(_tokenId);
        uint256 amountAfter = getTokenRewardsClaimed(_pool, poolToken, _tokenId);
        uint256 amountClaimed = amountAfter - amountBefore;
        rewardsLocked[_pool][_tokenId] += amountClaimed;
        require(rewardsLocked[_pool][_tokenId] <= amountAfter, "Locking more tokens than has been earnt.");

        return _lockAmount(msg.sender, amountClaimed);

    }


    function lockByTokenId(address _pool, uint _tokenId, uint256 _amount) public returns (uint) {
        require(poolEnabled[_pool] == true, "Incorrect pool");
        require(IERC721(_pool).ownerOf(_tokenId) == msg.sender, "Must own tokenId");
        require(_amount > 0);

        uint256 rewardsClaimed = getTokenRewardsClaimed(_pool, poolToken, _tokenId);
        rewardsLocked[_pool][_tokenId] += _amount;
        require(rewardsLocked[_pool][_tokenId] <= rewardsClaimed, "Locking more tokens than has been earnt.");

        return _lockAmount(msg.sender, _amount);
    }


    function _lockAmount(address _user, uint256 _amount) internal returns (uint) {
        require(_amount > 0);
        uint256 bonusAmount = _amount * bonusPercentage /  PERCENTAGE_PRECISION;

        rewardsPaid +=  bonusAmount;
        require(rewardsPaid <= totalTokens, "Amount claimed exceeds total tokens");

        OZIERC20(poolToken).safeTransferFrom(
            address(_user),
            address(this),
            _amount
        );

        return IVeToken(veToken).create_lock_for(_amount + bonusAmount, lockDuration, msg.sender);
    }


    function getTokenRewardsClaimed(address _pool, address _rewardToken, uint256 _tokenId) public view returns(uint256 rewardsClaimed) {
        IJellyPoolWrapper tokenPool = IJellyPoolWrapper(_pool);
        TokenRewards memory tRewards = tokenPool.tokenRewards(_tokenId, _rewardToken);
        rewardsClaimed = uint256(tRewards.rewardsReleased);
        
    }

    //--------------------------------------------------------
    // Admin Reclaim
    //--------------------------------------------------------

    /**
     * @notice Admin can end token distribution and reclaim tokens.
     * @notice Also allows for the recovery of incorrect ERC20 tokens sent to contract
     * @param _vault Address where the reclaimed tokens will be sent.
     */
    function adminReclaimTokens(
        address _tokenAddress,
        address _vault, 
        uint256 _tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "recoverERC20: Sender must be admin"
        );
        require(_vault != address(0)); // dev: Address must be non zero
        require(_tokenAmount > 0); // dev: Amount of tokens must be greater than zero

        OZIERC20(_tokenAddress).safeTransfer(_vault, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }



    //--------------------------------------------------------
    // Factory Init
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _accessControls Access controls interface.
     * @param _poolAddress Address of the pool contract.
     * @param _veToken Address of the ve contract.
     * @param _jellyVault The Jelly vault address.
     * @param _jellyFee Fee percentage for added tokens. To 2dp (10000 = 100.00%)
     */
    function initVeBonus(
        address _accessControls,
        address _poolAddress,
        address _veToken,
        address _jellyVault,
        uint256 _jellyFee
    ) public 
    {
        require(!initialised, "Already initialised");

        require(_accessControls != address(0), "Access controls not set");
        require(_poolAddress != address(0), "Pool address not set");
        require(_jellyVault != address(0), "jellyVault not set");
        require(_veToken != address(0), "veToken not set");

        require(_jellyFee < PERCENTAGE_PRECISION , "feePercentage greater than 10000 (100.00%)");
        poolEnabled[_poolAddress] = true;
        veToken = _veToken;
        poolToken = IJellyPool(_veToken).poolToken();
        require(poolToken != address(0), "poolToken not set in JellyPool");

        // PW: Check that the reward token is what is staked in veToken
        // Or not, maybe the reward tokens can be different

        OZIERC20(poolToken).safeApprove(_veToken, 0);
        OZIERC20(poolToken).safeApprove(_veToken, MAX_INT);

        accessControls = IJellyAccessControls(_accessControls);
        jellyVault = _jellyVault;
        feePercentage = _jellyFee;
        lockDuration = 60*60*24*365;
        initialised = true;
    }

    /** 
     * @dev Used by the Jelly Factory. 
     */
    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) external override {
        (
        address _accessControls,
        address _poolAddress,
        address _veToken,
        address _jellyVault,
        uint256 _jellyFee
        ) = abi.decode(_data, (address, address, address, address, uint256));

        initVeBonus(
                        _accessControls,
                        _poolAddress,
                        _veToken,
                        _jellyVault,
                        _jellyFee
                    );
    }

}