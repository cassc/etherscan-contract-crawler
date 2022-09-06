pragma solidity 0.8.6;

/**
 * @title Jelly Pool V1.3:
 *
 *              ,,,,
 *            [email protected]@@@@@K
 *           [email protected]@@@@@@@P
 *            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
 *             "*NNM"                     [email protected]@@  [email protected]@@
 *                                        [email protected]@@  [email protected]@@
 *             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
 *            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
 *           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
 *           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
 *           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
 *           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
 *            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
 *            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
 *             "[email protected]@@@@@        "**""       '''   '''        @@@Y
 *    ,[email protected]@g    "[email protected]@@P                                     @@@Y
 *   @@@@@@@@p    [email protected]@'                                    @@@Y
 *   @@@@@@@@P    [email protected]                                    RNNY
 *   '[email protected]@@@@@     $P
 *       "[email protected]@@p"'
 *
 *
 */

/**
 * @author ProfWobble
 * @dev
 * - Pool Contract with Staking NFTs:
 *   - Mints NFTs on stake() which represent staked tokens
 *          and claimable rewards in the pool.
 *   - Supports Merkle proofs using the JellyList interface.
 *   - External rewarder logic for multiple pools.
 *   - NFT attributes onchain via the descriptor.
 *
 */

import "IJellyAccessControls.sol";
import "IJellyRewarder.sol";
import "IJellyPool.sol";
import "IJellyContract.sol";
import "IMerkleList.sol";
import "IDescriptor.sol";
import "ILiquidityGauge.sol";
import "IJellyDocuments.sol";
import "SafeERC20.sol";
import "BoringMath.sol";
import "JellyPoolNFT.sol";

interface IMinter {
    function mint(address) external;
    function setMinterApproval(address minter, bool approval) external;
}


contract ZenPool is IJellyPool, IJellyContract, JellyPoolNFT {
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public constant override TEMPLATE_TYPE = 3;
    bytes32 public constant override TEMPLATE_ID = keccak256("ZEN_POOL");
    uint256 public constant pointMultiplier = 10e12;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IJellyAccessControls public accessControls;
    IJellyRewarder public rewardsContract;
    ILiquidityGauge public liquidityGauge;
    IDescriptor public descriptor;
    IJellyDocuments public documents;
    /// @notice Balancer Minter.
    IMinter public bal_minter;

    /// @notice Token to stake.
    address public override poolToken;
    /// @notice Balancer Token.
    address public bal;
    address public owner;
    struct PoolSettings {
        bool tokensClaimable;
        bool useList;
        bool useListAmounts;
        bool initialised;
        bool gaugeDeposit;
        uint256 transferTimeout;
        /// @notice Address that manages approvals.
        address list;
    }
    PoolSettings public poolSettings;

    /// @notice Total tokens staked.
    uint256 public override stakedTokenTotal;

    struct RewardInfo {
        uint48 lastUpdateTime;
        uint208 rewardsPerTokenPoints;
    }

    /// @notice reward token address => rewardsPerTokenPoints
    mapping(address => RewardInfo) public poolRewards;

    address[] public rewardTokens;

    struct TokenRewards {
        uint128 rewardsEarned;
        uint128 rewardsReleased;
        uint48 lastUpdateTime;
        uint208 lastRewardPoints;
    }
    /// @notice Mapping from tokenId => rewards token => reward info.
    mapping(uint256 => mapping(address => TokenRewards)) public tokenRewards;

    struct TokenInfo {
        uint128 staked;
        uint48 lastUpdateTime;
    }
    /// @notice Mapping from tokenId => token info.
    mapping(uint256 => TokenInfo) public tokenInfo;

    struct UserPool {
        uint128 stakeLimit;
    }

    /// @notice user address => pool details
    mapping(address => UserPool) public userPool;

    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event TokensClaimable(bool status);
    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsContractSet(
        address indexed oldRewardsToken,
        address newRewardsToken
    );
    /**
     * @notice Event emmited when a user has staked LPs.
     * @param owner Address of the staker.
     * @param amount Amount staked in LP tokens.
     */
    event Staked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardsClaimed(address indexed user, uint256 reward);
    /**
     * @notice Event emitted when a user has unstaked LPs.
     * @param owner Address of the unstaker.
     * @param amount Amount unstaked in LP tokens.
     */
    event Unstaked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when user unstaked in emergency mode.
     * @param user Address of the user.
     * @param tokenId unstaked tokenId.
     */
    event EmergencyUnstake(address indexed user, uint256 tokenId);
    /**
     * @notice Event emitted when Balancer Gauge whitelist has changed 
     * @param previous Previous status.
     * @param status Current status.
     */
    event GaugeDepositSet(bool previous, bool status);

    event LiquidityGaugeSet(
        address indexed previousGauge,
        address indexed newGauge
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
    }

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }


    //--------------------------------------------------------
    // Pool Config
    //--------------------------------------------------------

    /**
     * @notice Admin can change rewards contract through this function.
     * @param _addr Address of the new rewards contract.
     */
    function setRewardsContract(address _addr) external override {
        require(accessControls.hasAdminRole(msg.sender));
        require(_addr != address(0));
        emit RewardsContractSet(address(rewardsContract), _addr);
        rewardsContract = IJellyRewarder(_addr);
        if (rewardTokens.length > 0 ) {
            for (uint256 i = 0; i < rewardTokens.length ; i++) {
                rewardTokens.pop();
            }
        }
        rewardTokens = rewardsContract.rewardTokens(address(this));
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external override {
        require(accessControls.hasAdminRole(msg.sender));
        emit TokensClaimable(_enabled);
        poolSettings.tokensClaimable = _enabled;
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setGaugeDeposit(bool _enabled) external {
        require(accessControls.hasAdminRole(msg.sender));
        emit GaugeDepositSet(poolSettings.gaugeDeposit, _enabled);
        poolSettings.gaugeDeposit = _enabled;
    }

    /**
     * @notice Admin can set the Balancer gauge contract.
     * @param _gauge Address of the LiquidityGauge contract.
     */
    function setLiquidityGauge(address _gauge) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_gauge != address(0));
        emit LiquidityGaugeSet(address(liquidityGauge), _gauge);
        OZIERC20(poolToken).safeApprove(_gauge, 0);
        OZIERC20(poolToken).safeApprove(_gauge, MAX_INT);
        liquidityGauge = ILiquidityGauge(_gauge);
    }

    /**
     * @notice Admin can set the balancer minter contract.
     * @param _bal_minter Address of the BalancerMinter contract.
     */
    function setBalancerMinter(address _bal_minter) external {
        require(accessControls.hasAdminRole(msg.sender));
        bal_minter = IMinter(_bal_minter);
    }

    /**
     * @notice Set rewards reciever for Liquidity gauge
     * @param _receiver Address of the recipient of rewards.
     */
    function setRewardsReceiver(address _receiver) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_receiver != address(0)); // dev: Address must be non zero
        liquidityGauge.set_rewards_receiver(_receiver);

    }

    /**
     * @notice Set approval for Balancer Minter
     * @param _minter Address allowed to mint for this pool
     */
    function setMinterApproval(address _minter, bool _approval) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_minter != address(0)); // dev: Address must be non zero
        bal_minter.setMinterApproval(_minter, _approval);
    }


    /**
     * @notice Getter function for tokens claimable.
     */
    function tokensClaimable() external view override returns (bool) {
        return poolSettings.tokensClaimable;
    }

    //--------------------------------------------------------
    // Jelly Pool NFTs
    //--------------------------------------------------------

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the admin.
     */
    function setDescriptor(address _descriptor) external {
        require(accessControls.hasAdminRole(msg.sender));
        descriptor = IDescriptor(_descriptor);
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTokenDetails(string memory _name, string memory _symbol)
        external
    {
        require(accessControls.hasAdminRole(msg.sender));
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setNFTAdmin(address _owner) external {
        require(accessControls.hasAdminRole(msg.sender));
        address oldOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(oldOwner, _owner);
    }

    /**
     * @notice Add a delay between updating staked position and a token transfer.
     * @dev Only callable by the admin.
     */
    function setTransferTimeout(uint256 _timeout) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_timeout < block.timestamp);
        poolSettings.transferTimeout = _timeout;
    }

    function getOwnerTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = _ownedTokens[_owner][i];
        }
        return tokenIds;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Non-existent token");
        return descriptor.tokenURI(_tokenId);
    }


    //--------------------------------------------------------
    // Verify
    //--------------------------------------------------------

    /**
     * @notice Whitelisted staking
     * @param _merkleRoot List identifier.
     * @param _index User index.
     * @param _user User address.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.
     */
    function verify(
        bytes32 _merkleRoot,
        uint256 _index,
        address _user,
        uint256 _stakeLimit,
        bytes32[] calldata _data
    ) public nonreentrant {
        UserPool storage _userPool = userPool[_user];
        require(_stakeLimit > 0, "Limit must be > 0");

        if (_stakeLimit > uint256(_userPool.stakeLimit)) {
            uint256 merkleAmount = IMerkleList(poolSettings.list)
                .tokensClaimable(
                    _merkleRoot,
                    _index,
                    _user,
                    _stakeLimit,
                    _data
                );
            require(merkleAmount > 0, "Incorrect merkle proof");
            _userPool.stakeLimit = BoringMath.to128(merkleAmount);
        }
    }

    /**
     * @notice Function for verifying whitelist, staking and minting a Staking NFT
     * @param _amount Number of tokens in merkle proof.
     * @param _merkleRoot Merkle root.
     * @param _index Merkle index.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.

     */
    function verifyAndStake(
        uint256 _amount,
        bytes32 _merkleRoot,
        uint256 _index,
        uint256 _stakeLimit,
        bytes32[] calldata _data
    ) external {
        verify(_merkleRoot, _index, msg.sender, _stakeLimit, _data);
        _stake(msg.sender, _amount);
    }

    //--------------------------------------------------------
    // Stake
    //--------------------------------------------------------

    /**
     * @notice Deposits tokens into the JellyPool and mints a Staking NFT
     * @param _amount Number of tokens deposited into the pool.
     */
    function stake(uint256 _amount) external nonreentrant {
        _stake(msg.sender, _amount);
    }

    /**
     * @notice Internal staking function called by both verifyAndStake() and stake().
     * @param _user Stakers address.
     * @param _amount Number of tokens to deposit.
     */
    function _stake(address _user, uint256 _amount) internal {
        require(_amount > 0, "Amount must be > 0");

        /// @dev If a whitelist is set, this checks user balance.
        if (poolSettings.useList) {
            if (poolSettings.useListAmounts) {
                require(_amount < userPool[_user].stakeLimit);
            } else {
                require(userPool[_user].stakeLimit > 0);
            }
        }

        /// @dev Mints a Staking NFT if the user doesnt already have one.
        if (balanceOf(_user) == 0) {
            // Mints new Staking NFT
            uint256 _tokenId = _safeMint(_user);
            // Sets initial rewards points
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                if (tokenRewards[_tokenId][rewardToken].lastRewardPoints == 0) {
                    tokenRewards[_tokenId][rewardToken]
                        .lastRewardPoints = poolRewards[rewardToken]
                        .rewardsPerTokenPoints;
                }
            }
        }
        /// We always add balance to the users first token.
        uint256 tokenId = _ownedTokens[_user][0];

        /// Updates internal accounting and stakes tokens
        snapshot(tokenId);
        tokenInfo[tokenId] = TokenInfo(
            tokenInfo[tokenId].staked + BoringMath.to128(_amount),
            BoringMath.to48(block.timestamp)
        );
        stakedTokenTotal += BoringMath.to128(_amount);
        OZIERC20(poolToken).safeTransferFrom(
            address(_user),
            address(this),
            _amount
        );

        if (poolSettings.gaugeDeposit) {
            liquidityGauge.deposit(_amount, address(this));
        }

        emit Staked(_user, _amount);
    }

    /**
     * @notice Returns the number of tokens staked for a tokenID.
     * @param _tokenId TokenID to be checked.
     */
    function stakedBalance(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        return tokenInfo[_tokenId].staked;
    }

    //--------------------------------------------------------
    // Rewards
    //--------------------------------------------------------

    /// @dev Updates the rewards accounting onchain for a specific tokenID.
    function snapshot(uint256 _tokenId) public {
        require(_exists(_tokenId), "Non-existent token");
        IJellyRewarder rewarder = rewardsContract;
        rewarder.updateRewards();
        uint256 sTotal = stakedTokenTotal;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            RewardInfo storage rInfo = poolRewards[rewardTokens[i]];
            /// Get total pool rewards from rewarder
            uint208 currentRewardPoints;
            if (sTotal == 0) {
                currentRewardPoints = rInfo.rewardsPerTokenPoints;
            } else {
                uint256 currentRewards = rewarder.poolRewards(
                    address(this),
                    rewardToken,
                    uint256(rInfo.lastUpdateTime),
                    block.timestamp
                );

                /// Convert to reward points
                currentRewardPoints =
                    rInfo.rewardsPerTokenPoints +
                    BoringMath.to208(
                        (currentRewards * 1e18 * pointMultiplier) / sTotal
                    );
            }
            /// Update reward info
            rInfo.rewardsPerTokenPoints = currentRewardPoints;
            rInfo.lastUpdateTime = BoringMath.to48(block.timestamp);

            _updateTokenRewards(_tokenId, rewardToken, currentRewardPoints);
        }
    }
    
    /// @dev Updates the TokenRewards accounting for a specific tokenID.
    function _updateTokenRewards(
        uint256 _tokenId,
        address _rewardToken,
        uint208 currentRewardPoints
    ) internal {
        TokenRewards storage _tokenRewards = tokenRewards[_tokenId][
            _rewardToken
        ];
        // update token rewards
        _tokenRewards.rewardsEarned += BoringMath.to128(
            (tokenInfo[_tokenId].staked *
                uint256(currentRewardPoints - _tokenRewards.lastRewardPoints)) /
                1e18 /
                pointMultiplier
        );
        // Update token details
        _tokenRewards.lastUpdateTime = BoringMath.to48(block.timestamp);
        _tokenRewards.lastRewardPoints = currentRewardPoints;
    }

    //--------------------------------------------------------
    // Claim
    //--------------------------------------------------------

    /**
     * @notice Claim rewards for all Staking NFTS owned by the sender.
     */
    function claim() external {
        require(poolSettings.tokensClaimable == true, "Not yet claimable");
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                snapshot(tokenIds[i]);
            }
            for (uint256 j = 0; j < rewardTokens.length; j++) {
                _claimRewards(tokenIds, rewardTokens[j], msg.sender);
            }
        }
    }

    /**
     * @notice Claiming rewards on behalf of a token ID.
     * @param _tokenId Token ID.
     */
    function fancyClaim(uint256 _tokenId) public {
        claimRewards(_tokenId, rewardTokens);
    }

    /**
     * @notice Claiming rewards for user for specific rewards.
     * @param _tokenId Token ID.
     */
    function claimRewards(uint256 _tokenId, address[] memory _rewardTokens)
        public 
    {
        require(poolSettings.tokensClaimable == true, "Not yet claimable");
        snapshot(_tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        address recipient = ownerOf(_tokenId);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _claimRewards(tokenIds, _rewardTokens[i], recipient);
        }
    }

    /**
     * @notice Claiming rewards for user.
     * @param _tokenIds Array of Token IDs.
     */
    function _claimRewards(
        uint256[] memory _tokenIds,
        address _rewardToken,
        address _recipient
    ) internal returns(uint256) {
        uint256 payableAmount;
        uint128 rewards;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            TokenRewards storage _tokenRewards = tokenRewards[_tokenIds[i]][
                _rewardToken
            ];
            rewards =
                _tokenRewards.rewardsEarned -
                _tokenRewards.rewardsReleased;
            payableAmount += uint256(rewards);
            _tokenRewards.rewardsReleased += rewards;
        }

        OZIERC20(_rewardToken).safeTransfer(_recipient, payableAmount);
        emit RewardsClaimed(_recipient, payableAmount);
        return payableAmount;
    }

    //--------------------------------------------------------
    // Unstake
    //--------------------------------------------------------
    /**
     * @notice Function for unstaking exact amount of tokens, claims all rewards.
     * @param _amount amount of tokens to unstake.
     */

    function unstake(uint256 _amount) external nonreentrant {
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);
        uint256 unstakeAmount;
        require(tokenIds.length > 0, "Nothing to unstake");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_amount > 0) {
                unstakeAmount = tokenInfo[tokenIds[i]].staked;
                if (unstakeAmount > _amount) {
                    unstakeAmount = _amount;
                }
                _amount = _amount - unstakeAmount;
                fancyClaim(tokenIds[i]);
                _unstake(msg.sender, tokenIds[i], unstakeAmount);
            }
        }
    }

    /**
     * @notice Function for unstaking exact amount of tokens, for a specific NFT token id.
     * @param _tokenId TokenID to be unstaked
     * @param _amount amount of tokens to unstake.
     */
    function unstakeToken(uint256 _tokenId, uint256 _amount) external nonreentrant {
        require(ownerOf(_tokenId) == msg.sender, "Must own tokenId");
        fancyClaim(_tokenId);
        _unstake(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Function that executes the unstaking.
     * @param _user Stakers address.
     * @param _tokenId TokenID to unstake.
     * @param _amount amount of tokens to unstake.
     */
    function _unstake(
        address _user,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        tokenInfo[_tokenId] = TokenInfo(
            tokenInfo[_tokenId].staked - BoringMath.to128(_amount),
            BoringMath.to48(block.timestamp)
        );
        stakedTokenTotal -= BoringMath.to128(_amount);

        if (tokenInfo[_tokenId].staked == 0) {
            delete tokenInfo[_tokenId];
            _burn(_tokenId);
        }

        uint256 tokenBal = OZIERC20(poolToken).balanceOf(address(this));
        if (tokenBal < _amount) {
            uint256 gaugeBal = balanceOfGauge();
            if (gaugeBal >= _amount - tokenBal) {
                liquidityGauge.withdraw(_amount - tokenBal);
            } else if (gaugeBal > 0 ) { 
                liquidityGauge.withdraw(gaugeBal);
                _amount = tokenBal + gaugeBal;
            } else { 
                _amount = tokenBal;
            }
        }
        OZIERC20(poolToken).safeTransfer(address(_user), _amount);
        emit Unstaked(_user, _amount);
    }

    /**
     * @notice Unstake without rewards. EMERGENCY ONLY.
     * @param _tokenId TokenID to unstake.
     */
    function emergencyUnstake(uint256 _tokenId) external  nonreentrant {
        require(ownerOf(_tokenId) == msg.sender, "Must own tokenId");
        _unstake(msg.sender, _tokenId, tokenInfo[_tokenId].staked);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }


    //--------------------------------------------------------
    // Balancer Gauge
    //--------------------------------------------------------
    /**
     * @notice Total mount of staked tokens in the Balancer Gauge
     */
    function balanceOfGauge() public view returns (uint256) {
        return liquidityGauge.balanceOf(address(this));
    }

    /**
     * @notice Claim BAL from Balancer
     * @param _vault Address of the recipient of rewards.
     * @dev Claim BAL for LP token staking from the BAL minter contract
     */
    function claimBal(address _vault) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_vault != address(0)); // dev: Address must be non zero
        uint256 balance = 0;

        try bal_minter.mint(address(liquidityGauge)){
            balance = OZIERC20(bal).balanceOf(address(this));
            OZIERC20(bal).safeTransfer(_vault, balance);
        }catch{}

        return balance;
    }

    /**
     * @notice  Withdraw tokens from a gauge to pool save gas on unstake
     * @dev     Only callable by the admin 
     * @param _amount  Amount of tokens to remove from gauge
     */
    function withdrawGauge(uint _amount) external returns(bool){
        require(
            accessControls.hasAdminRole(msg.sender) ,
            "Sender must be admin"
        );
        liquidityGauge.withdraw(_amount);
        return true;
    }


    /**
     * @notice  Deposits tokens from a gauge to pool save user gas on stake
     * @dev     Only callable by the admin 
     * @param _amount  Amount of tokens to remove from gauge
     */
    function depositGauge(uint _amount) external returns(bool){
        require(
            accessControls.hasAdminRole(msg.sender) ,
            "Sender must be admin"
        );
        liquidityGauge.deposit(_amount, address(this));
        return true;
    }


    //--------------------------------------------------------
    // List
    //--------------------------------------------------------
    /**
     * @notice Address used for whitelist if activated
     */
    function list() external view returns (address) {
        return poolSettings.list;
    }

    function setList(address _list) external {
        require(accessControls.hasAdminRole(msg.sender));
        if (_list != address(0)) {
            poolSettings.list = _list;
        }
    }

    function enableList(bool _useList, bool _useListAmounts) public {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.useList = _useList;
        poolSettings.useListAmounts = _useListAmounts;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------
    /**
     * @notice Set the global document store.
     * @dev Only callable by the admin.
     */
    function setDocumentController(address _documents) external {
        require(accessControls.hasAdminRole(msg.sender));
        documents = IJellyDocuments(_documents);
    }
    /**
     * @notice Set the documents in the global store.
     * @dev Only callable by the admin and operator.
     * @param _name Document key.
     * @param _data Document value. Leave blank to remove document
     */
    function setDocument(string calldata _name, string calldata _data)
        external
    {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender));
        if (bytes(_data).length > 0) {
            documents.setDocument(address(this), _name, _data);
        } else {
            documents.removeDocument(address(this), _name);
        }
    }

    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.
     * @param _bal_minter address of Balancer Minter contract.

     */
    function initJellyPool(address _poolToken, address _accessControls, address _bal, address _bal_minter) public {
        require(!poolSettings.initialised);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        bal_minter = IMinter(_bal_minter);
        bal = _bal;
        _entered_state = 1;

        poolSettings.initialised = true;
    }

    function init(bytes calldata _data) external payable override {}

    function initContract(bytes calldata _data) external override {
        (address _poolToken, address _accessControls,  address _bal, address _bal_minter) = abi.decode(
            _data,
            (address, address, address, address)
        );

        initJellyPool(_poolToken, _accessControls, _bal, _bal_minter);
    }
}