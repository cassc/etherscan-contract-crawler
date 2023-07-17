// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./interface/IERC721.sol";
import "./interface/IFactory.sol";

interface Dao {
    function getVotingStatus(address _user) external view returns (bool);
}

interface IUniswapV3PositionUtility{
    function getAstraAmount (uint256 _tokenID) external view returns (uint256);
}

contract MasterChefV2 is Initializable, Ownable2StepUpgradeable, IERC721ReceiverUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 maxStakingScore;
        uint256 maxMultiplier;
        uint256 lastDeposit;
        bool cooldown;
        uint256 cooldowntimestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of ASTRAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAstraPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAstraPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ASTRAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ASTRAs distribution occurs.
        uint256 accAstraPerShare; // Accumulated ASTRAs per share, times 1e12. See below.
        uint256 totalStaked;
        uint256 maxMultiplier; // Total Astra staked amount.
    }

    //staking info structure
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 vault;
        uint256 withdrawTime;
        uint256 tokenId;
        bool isERC721;
    }

    //Highest staked users
    struct HighestAstaStaker {
        uint256 deposited;
        address addr;
    }

    // The ASTRA TOKEN!
    IERC20Upgradeable public astra;
    // Dev address.
    address public governanceAddress;
    IUniswapV3PositionUtility public uniswapUtility;

    IERC721 public erc721Token;
    // Block number when bonus ASTRA period ends.
    uint256 public bonusEndBlock;
    // ASTRA tokens created per block.
    uint256 public astraPerBlock;
    uint256 public constant ZERO_MONTH_VAULT = 0;
    uint256 public constant SIX_MONTH_VAULT = 6;
    uint256 public constant NINE_MONTH_VAULT = 9;
    uint256 public constant TWELVE_MONTH_VAULT = 12;
    uint256 public constant AVG_STAKING_SCORE_CAL_TIME = 60;
    uint256 public constant MAX_STAKING_SCORE_CAL_TIME_SECONDS = 5184000;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant STAKING_SCORE_TIME_CONSTANT = 5184000;
    uint256 public constant VAULT_MULTIPLIER_FOR_STAKING_SCORE = 5;
    uint256 public constant MULTIPLIER_DECIMAL = 10000000000000;
    uint256 public constant SLASHING_FEES_CONSTANT = 90;
    uint256 public constant DEFAULT_POOL = 0;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when ASTRA rewards distribution starts.
    uint256 public startBlock;
    uint256 public totalRewards;
    uint256 public maxPerBlockReward;
    uint256 public constant coolDownPeriodTime = 1;
    uint256 public constant coolDownClaimTime = 1;

    mapping(uint256 => mapping(address => uint256)) private userStakeCounter;
    mapping(uint256 => mapping(address => mapping(uint256 => StakeInfo)))
        public userStakeInfo;
    mapping(uint256 => bool) public isValidVault;
    mapping(uint256 => uint256) public usersTotalStakedInVault;
    mapping(uint256 => uint256) public stakingVaultMultiplier;

    mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;
    mapping(address => bool) public isAllowedContract;

    mapping(address => uint256) public unClaimedReward;
    mapping(address => mapping(address => bool)) public lpTokensStatus;
    bool private isFirstDepositInitialized;

    mapping(uint256 => mapping(address => uint256)) public averageStakedTime;
    mapping(address => bool) public eligibleDistributionAddress;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AddPool(address indexed token0, address indexed token1);
    event DistributeReward(uint256 indexed rewardAmount);
    event RestakedReward(address _userAddress, uint256 indexed _amount);
    event ClaimedReward(address _userAddress, uint256 indexed _amount);
    event AddVault(uint256 indexed _vault, uint256 indexed _vaultMultiplier);
    event WhitelistDepositContract(address indexed _contractAddress, bool indexed _value);
    event SetGovernanceAddress(address indexed _governanceAddress);
    event SetUtilityContractAddress(IUniswapV3PositionUtility indexed _uniswapUtility);
    event Set(uint256 indexed _allocPoint, bool _withUpdate);
    event ReduceReward(uint256 indexed _rewardAmount, uint256 indexed _newPerBlockReward);

    /**
    @notice This function is used for initializing the contract with sort of parameter
    @param _astra : astra contract address
    @param _startBlock : start block number for starting rewars distribution
    @param _bonusEndBlock : end block number for ending reward distribution
    @param _totalRewards : Total ASTRA rewards
    @dev Description :
    This function is basically used to initialize the necessary things of chef contract and set the owner of the
    contract. This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function initialize(
        IERC20Upgradeable _astra,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _totalRewards
    ) external initializer {
        require(address(_astra) != address(0), "Zero Address");
        __Ownable2Step_init();
        astra = _astra;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        totalRewards = _totalRewards;
        maxPerBlockReward = totalRewards.div(bonusEndBlock.sub(startBlock));
        astraPerBlock = totalRewards.div(bonusEndBlock.sub(startBlock));
        isValidVault[ZERO_MONTH_VAULT] = true;
        isValidVault[SIX_MONTH_VAULT] = true;
        isValidVault[NINE_MONTH_VAULT] = true;
        isValidVault[TWELVE_MONTH_VAULT] = true;
        stakingVaultMultiplier[ZERO_MONTH_VAULT] = 10000000000000;
        stakingVaultMultiplier[SIX_MONTH_VAULT] = 11000000000000;
        stakingVaultMultiplier[NINE_MONTH_VAULT] = 13000000000000;
        stakingVaultMultiplier[TWELVE_MONTH_VAULT] = 18000000000000;
        add(100, _astra);
        // updateRewardRate(startBlock,1, 1, 0);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken
    ) internal {
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accAstraPerShare: 0,
                totalStaked: 0,
                maxMultiplier: MULTIPLIER_DECIMAL
            })
        );
    }

        // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addUniswapVersion3(
        IERC721 _erc721Token,
        address _token0,
        address _token1,
        uint24 fee,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_erc721Token) != address(0), "Zero Address");
        require(_token0 != address(0), "Zero Address");
        require(_token1 != address(0), "Zero Address");
        require(
            IUniswapV3Factory(_erc721Token.factory()).getPool(
                _token0,
                _token1,
                fee
            ) != address(0),
            "Pair not created"
        );

        erc721Token = _erc721Token;

        if (_withUpdate) {
            updatePool();
        }
        // Setting the lp token status true becuase pool is active.
        lpTokensStatus[_token0][_token1] = true;
        lpTokensStatus[_token1][_token0] = true;

        emit AddPool(_token0, _token1);
    }

    /**
    @notice Add vault month. Can only be called by the owner.
    @param _vault : value of month like 0, 3, 6, 9, 12
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function addVault(uint256 _vault, uint256 _vaultMultiplier) external onlyOwner {
        isValidVault[_vault] = true;
        stakingVaultMultiplier[_vault] = _vaultMultiplier;
        emit AddVault(_vault, _vaultMultiplier);
    }

    /**
    @notice Add contract address. Can only be called by the owner.
    @param _contractAddress : Contract address.
    @dev    Add contract address for external deposit.
    */
    function whitelistDepositContract(address _contractAddress, bool _value)
        external
        onlyOwner
    {
        isAllowedContract[_contractAddress] = _value;
        emit WhitelistDepositContract(_contractAddress, _value);
    }

    // Update dev address by the previous dev.
    function setGovernanceAddress(address _governanceAddress)
        external
        onlyOwner
    {
        governanceAddress = _governanceAddress;
        emit SetGovernanceAddress(_governanceAddress);
    }

    function setUtilityContractAddress(IUniswapV3PositionUtility _uniswapUtility) external onlyOwner{
        uniswapUtility = _uniswapUtility;
        emit SetUtilityContractAddress(_uniswapUtility);
    }

    // Update the given pool's ASTRA allocation point. Can only be called by the owner.
    function set(
        
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            updatePool();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[DEFAULT_POOL].allocPoint).add(
            _allocPoint
        );
        poolInfo[DEFAULT_POOL].allocPoint = _allocPoint;
        emit Set(_allocPoint, _withUpdate);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending ASTRAs on frontend.
    function pendingAstra( address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][_user];
        uint256 accAstraPerShare = pool.accAstraPerShare;
        uint256 lpSupply = pool.totalStaked;
        uint256 PoolEndBlock = block.number;
        uint256 userMultiplier;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                PoolEndBlock
            );
            uint256 astraReward = multiplier
                .mul(astraPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accAstraPerShare = accAstraPerShare.add(
                astraReward.mul(1e12).div(lpSupply)
            );
        }
        (, userMultiplier, ) = stakingScoreAndMultiplier(
            _user,
            user.amount
        );
        return
            unClaimedReward[_user]
                .add(
                    (
                        user.amount.mul(accAstraPerShare).div(1e12).sub(
                            user.rewardDebt
                        )
                    )
                )
                .mul(userMultiplier)
                .div(MULTIPLIER_DECIMAL);
    }

    function restakeAstraReward() public {
        updatePool();
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 userMaxMultiplier;
        uint256 claimableReward;
        uint256 slashedReward;
        uint256 newPoolMaxMultiplier;

        (, , userMaxMultiplier) = stakingScoreAndMultiplier(
            
            msg.sender,
            user.amount
        );

        claimableReward = unClaimedReward[msg.sender].add(
            (
                (
                    user.amount.mul(pool.accAstraPerShare).div(1e12).sub(
                        user.rewardDebt
                    )
                ).mul(userMaxMultiplier).div(MULTIPLIER_DECIMAL)
            )
        );

            updateUserDepositDetails(
                msg.sender,
                claimableReward,
                SIX_MONTH_VAULT,
                0,
                false
            );

            (, , userMaxMultiplier) = stakingScoreAndMultiplier(
                msg.sender,
                user.amount.add(claimableReward)
            );
            newPoolMaxMultiplier = user
                .amount
                .add(claimableReward)
                .mul(userMaxMultiplier)
                .add(pool.totalStaked.mul(pool.maxMultiplier))
                .sub(user.amount.mul(user.maxMultiplier))
                .div(pool.totalStaked.add(claimableReward));
            user.amount = user.amount.add(claimableReward);
            pool.totalStaked = pool.totalStaked.add(claimableReward);
            user.maxMultiplier = userMaxMultiplier;

            pool.maxMultiplier = newPoolMaxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        unClaimedReward[msg.sender] = 0;
        updateRewardRate(
            pool.lastRewardBlock,
            pool.maxMultiplier,
            slashedReward
        );
        emit RestakedReward(msg.sender, claimableReward);
        emit Deposit(msg.sender, DEFAULT_POOL, claimableReward);
    }

    function claimAstra() public {
        updatePool();
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 userMultiplier;
        uint256 userMaxMultiplier;
        uint256 slashedReward;
        uint256 claimableReward;
        uint256 slashingFees;

        (, userMultiplier, userMaxMultiplier) = stakingScoreAndMultiplier(
            msg.sender,
            user.amount
        );
        claimableReward = unClaimedReward[msg.sender].add(
            (
                user.amount.mul(pool.accAstraPerShare).div(1e12).sub(
                    user.rewardDebt
                )
            )
        );
        if (userMaxMultiplier > userMultiplier) {
            slashedReward = (
                claimableReward.mul(userMaxMultiplier).sub(
                    claimableReward.mul(userMultiplier)
                )
            ).div(MULTIPLIER_DECIMAL);
        }

        claimableReward = claimableReward
            .mul(userMaxMultiplier)
            .div(MULTIPLIER_DECIMAL)
            .sub(slashedReward);
        uint256 slashDays = block.timestamp.sub(averageStakedTime[DEFAULT_POOL][msg.sender]).div(
            SECONDS_IN_DAY
        );
        if (slashDays < 90) {
            slashingFees = claimableReward
                .mul(SLASHING_FEES_CONSTANT.sub(slashDays))
                .div(100);
        }
        slashedReward = slashedReward.add(slashingFees);
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        safeAstraTransfer(msg.sender, claimableReward.sub(slashingFees));
        updateRewardRate(
            pool.lastRewardBlock,
            pool.maxMultiplier,
            slashedReward
        );
        unClaimedReward[msg.sender] = 0;
        emit ClaimedReward(msg.sender, claimableReward.sub(slashingFees));
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool();
        }
    }

    function updateRewardRate(
        uint256 lastUpdatedBlock,
        uint256 newMaxMultiplier,
        uint256 slashedReward
    ) internal {
        uint256 _startBlock = lastUpdatedBlock >= bonusEndBlock
            ? bonusEndBlock
            : lastUpdatedBlock;
        uint256 blockLeft = bonusEndBlock.sub(_startBlock);
        if (blockLeft > 0) {
            if (!isFirstDepositInitialized) {
                maxPerBlockReward = totalRewards.div(blockLeft);
                isFirstDepositInitialized = true;
            } else {
                maxPerBlockReward = slashedReward
                    .add(maxPerBlockReward.mul(blockLeft))
                    .mul(MULTIPLIER_DECIMAL)
                    .div(blockLeft)
                    .div(MULTIPLIER_DECIMAL);
            }
            astraPerBlock = blockLeft
                .mul(maxPerBlockReward)
                .mul(MULTIPLIER_DECIMAL)
                .div(blockLeft)
                .div(newMaxMultiplier);
        }
    }

    function updateUserAverageSlashingFees( address _userAddress, uint256 previousDepositAmount, uint256 newDepositAmount, uint256 currentTimestamp) internal {
        if(averageStakedTime[DEFAULT_POOL][_userAddress] == 0){
            averageStakedTime[DEFAULT_POOL][_userAddress] = currentTimestamp;
        }else{
            uint256 previousDepositedWeight = averageStakedTime[DEFAULT_POOL][_userAddress].mul(previousDepositAmount);
            uint256 newDepositedWeight = newDepositAmount.mul(currentTimestamp);
            averageStakedTime[DEFAULT_POOL][_userAddress] = newDepositedWeight.add(previousDepositedWeight).div(previousDepositAmount.add(newDepositAmount));
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = PoolEndBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        uint256 astraReward = multiplier
            .mul(astraPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accAstraPerShare = pool.accAstraPerShare.add(
            astraReward.mul(1e12).div(lpSupply)
        );

        pool.lastRewardBlock = PoolEndBlock;
    }

    function calculateMultiplier(uint256 _stakingScore)
        public
        pure
        returns (uint256)
    {
        if (_stakingScore >= 100000 ether && _stakingScore < 300000 ether) {
            return 12000000000000;
        } else if (
            _stakingScore >= 300000 ether && _stakingScore < 800000 ether
        ) {
            return 13000000000000;
        } else if (_stakingScore >= 800000 ether) {
            return 17000000000000;
        } else {
            return 10000000000000;
        }
    }

    function stakingScoreAndMultiplier(
        
        address _userAddress,
        uint256 _stakedAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentStakingScore;
        uint256 currentMultiplier;
        uint256 vaultMultiplier;
        uint256 multiplierPerStake;
        uint256 maxMultiplier;
        for (uint256 i = 0; i < userStakeCounter[DEFAULT_POOL][_userAddress]; i++) {
            StakeInfo memory stakerDetails = userStakeInfo[DEFAULT_POOL][_userAddress][
                i
            ];
            if (
                stakerDetails.withdrawTime == 0 ||
                stakerDetails.withdrawTime == block.timestamp
            ) {
                uint256 stakeTime = block.timestamp.sub(
                    stakerDetails.timestamp
                );
                stakeTime = stakeTime >= STAKING_SCORE_TIME_CONSTANT
                    ? STAKING_SCORE_TIME_CONSTANT
                    : stakeTime;
                multiplierPerStake = multiplierPerStake.add(
                    stakerDetails.amount.mul(
                        stakingVaultMultiplier[stakerDetails.vault]
                    )
                );
                if (stakerDetails.vault == TWELVE_MONTH_VAULT) {
                    currentStakingScore = currentStakingScore.add(
                        stakerDetails.amount
                    );
                } else {
                    uint256 userStakedTime = block.timestamp.sub(
                        stakerDetails.timestamp
                    ) >= MAX_STAKING_SCORE_CAL_TIME_SECONDS
                        ? MAX_STAKING_SCORE_CAL_TIME_SECONDS
                        : block.timestamp.sub(stakerDetails.timestamp);
                    uint256 tempCalculatedStakingScore = (
                        stakerDetails.amount.mul(userStakedTime)
                    ).div(
                            AVG_STAKING_SCORE_CAL_TIME
                                .sub(
                                    stakerDetails.vault.mul(
                                        VAULT_MULTIPLIER_FOR_STAKING_SCORE
                                    )
                                )
                                .mul(SECONDS_IN_DAY)
                        );
                    uint256 finalStakingScoreForCurrentStake = tempCalculatedStakingScore >=
                            stakerDetails.amount
                            ? stakerDetails.amount
                            : tempCalculatedStakingScore;
                    currentStakingScore = currentStakingScore.add(
                        finalStakingScoreForCurrentStake
                    );
                }
            }
        }
        if (_stakedAmount == 0) {
            vaultMultiplier = MULTIPLIER_DECIMAL;
        } else {
            vaultMultiplier = multiplierPerStake.div(_stakedAmount);
        }
        currentMultiplier = vaultMultiplier
            .add(calculateMultiplier(currentStakingScore))
            .sub(MULTIPLIER_DECIMAL);
        maxMultiplier = vaultMultiplier
            .add(calculateMultiplier(_stakedAmount))
            .sub(MULTIPLIER_DECIMAL);
        return (currentStakingScore, currentMultiplier, maxMultiplier);
    }

    function updateUserDepositDetails(
        
        address _userAddress,
        uint256 _amount,
        uint256 _vault,
        uint256 __tokenId,
        bool _isERC721
    ) internal {
        uint256 userstakeid = userStakeCounter[DEFAULT_POOL][_userAddress];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = userStakeInfo[DEFAULT_POOL][_userAddress][
            userstakeid
        ];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.timestamp = block.timestamp;
        staker.vault = _vault;
        staker.withdrawTime = 0;
        staker.tokenId = __tokenId;
        staker.isERC721 = _isERC721;
        userStakeCounter[DEFAULT_POOL][_userAddress] = userStakeCounter[DEFAULT_POOL][
            _userAddress
        ].add(1);
    }

    function transferNFTandGetAmount(uint256 _tokenId) internal returns(uint256){
        uint256 _amount;
        address _token0;
        address _token1;

        (, , _token0, _token1, , , , , , , , ) = erc721Token.positions(
            _tokenId
        );

        require(lpTokensStatus[_token0][_token1], "LP token not added");
        require(lpTokensStatus[_token1][_token0], "LP token not added");
        _amount = uniswapUtility.getAstraAmount(_tokenId);
        erc721Token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _tokenId
        );

        return _amount;

    }

    function deposit(
        
        uint256 _amount,
        uint256 _vault,
        uint256 _tokenId,
        bool _isERC721
    ) external {
        if(_isERC721){
            _amount = transferNFTandGetAmount(_tokenId);
        }else{
            require(_amount > 0, "Amount should be greater than 0");
            poolInfo[DEFAULT_POOL].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
            );
        }
        _deposit( _amount, _vault, msg.sender, _tokenId, _isERC721);
    }

    // This function will be used by other contracts to deposit on user's behalf.
    function depositWithUserAddress(   
        uint256 _amount,
        uint256 _vault,
        address _userAddress
    ) external {
        require(isAllowedContract[msg.sender], "Invalid sender");
        require(_amount > 0, "Amount should be greater than 0");
        poolInfo[DEFAULT_POOL].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _deposit( _amount, _vault, _userAddress, 0, false);
    }

    // Deposit LP tokens to MasterChef for ASTRA allocation.
    function _deposit(
        
        uint256 _amount,
        uint256 _vault,
        address _userAddress,
        uint256 _tokenId,
        bool _isERC721
    ) internal {
        require(isValidVault[_vault], "Invalid vault");
        uint256 _stakingScore;
        uint256 _currentMultiplier;
        uint256 _maxMultiplier;

        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][_userAddress];
        updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accAstraPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            unClaimedReward[_userAddress] = unClaimedReward[_userAddress].add(
                pending
            );
        }
        uint256 updateStakedAmount = user.amount.add(_amount);
        uint256 newPoolMaxMultiplier;
        updateUserDepositDetails( _userAddress, _amount, _vault, _tokenId, _isERC721);

        (
            _stakingScore,
            _currentMultiplier,
            _maxMultiplier
        ) = stakingScoreAndMultiplier( _userAddress, updateStakedAmount);
        newPoolMaxMultiplier = updateStakedAmount
            .mul(_maxMultiplier)
            .add(pool.totalStaked.mul(pool.maxMultiplier))
            .sub(user.amount.mul(user.maxMultiplier))
            .div(pool.totalStaked.add(_amount));
        updateUserAverageSlashingFees( _userAddress, user.amount, _amount, block.timestamp);
        user.amount = updateStakedAmount;
        pool.totalStaked = pool.totalStaked.add(_amount);
        user.maxMultiplier = _maxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        pool.maxMultiplier = newPoolMaxMultiplier;
        user.lastDeposit = block.timestamp;
        updateRewardRate(pool.lastRewardBlock, pool.maxMultiplier, 0);
        addHighestStakedUser( user.amount, _userAddress);
        emit Deposit(_userAddress, DEFAULT_POOL, _amount);
    }

    function withdraw( bool _withStake) external {
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        //Instead of transferring to a standard staking vault, Astra tokens can be locked (meaning that staker forfeits the right to unstake them for a fixed period of time). There are following lockups vaults: 6,9 and 12 months.
        if (user.cooldown == false) {
            user.cooldown = true;
            user.cooldowntimestamp = block.timestamp;
            return;
        } else {
            
                require(
                    block.timestamp >=
                        user.cooldowntimestamp.add(
                            SECONDS_IN_DAY.mul(coolDownPeriodTime)
                        ),
                    "withdraw: cooldown period"
                );
                user.cooldown = false;
                // Calling withdraw function after all the validation like cooldown period, eligible amount etc.
                _withdraw( _withStake);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function _withdraw( bool _withStake) internal {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 _amount;
        uint256 _erc721Amount;
        (_amount, _erc721Amount) = checkEligibleAmount( msg.sender);
        require(user.amount >= _amount, "withdraw: not good");
        if (_withStake) {
            restakeAstraReward();
        } else {
            claimAstra();
        }

        uint256 _stakingScore;
        uint256 _currentMultiplier;
        uint256 _maxMultiplier;
        uint256 updateStakedAmount = user.amount.sub(_amount);
        uint256 newPoolMaxMultiplier;
        if (pool.totalStaked.sub(_amount) > 0) {
            (
                _stakingScore,
                _currentMultiplier,
                _maxMultiplier
            ) = stakingScoreAndMultiplier( msg.sender, updateStakedAmount);
            newPoolMaxMultiplier = updateStakedAmount
                .mul(_maxMultiplier)
                .add(pool.totalStaked.mul(pool.maxMultiplier))
                .sub(user.amount.mul(user.maxMultiplier))
                .div(pool.totalStaked.sub(_amount));
        } else {
            newPoolMaxMultiplier = MULTIPLIER_DECIMAL;
        }

        user.amount = updateStakedAmount;
        pool.totalStaked = pool.totalStaked.sub(_amount);
        user.maxMultiplier = _maxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        pool.maxMultiplier = newPoolMaxMultiplier;
        user.lastDeposit = block.timestamp;
        updateRewardRate(pool.lastRewardBlock, pool.maxMultiplier, 0);
        safeAstraTransfer(msg.sender, _amount.sub(_erc721Amount));
        removeHighestStakedUser( user.amount, msg.sender);
        emit Withdraw(msg.sender, DEFAULT_POOL, _amount);
    }

    /**
    @notice View the eligible amount which is able to withdraw.
    @param _user : user address
    @dev Description :
    View the eligible amount which needs to be withdrawn if user deposits amount in multiple vaults. This function
    definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function viewEligibleAmount( address _user)
        external
        view
        returns (uint256)
    {
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakeCounter[DEFAULT_POOL][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and calculate
        // the eligible amount which needs to be withdrawn
        for (uint256 i = 0; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = userStakeInfo[DEFAULT_POOL][_user][i];
            // Checking the deposit variable is true
            if (
                stkInfo.withdrawTime == 0 ||
                stkInfo.withdrawTime == block.timestamp
            ) {
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(SECONDS_IN_DAY)
                );
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                }
            }
        }
        return eligibleAmount;
    }

    /**
    @notice Check the eligible amount which is able to withdraw.
    @param _user : user address
    @dev Description :
    This function is like viewEligibleAmount just here we update the state of stakeInfo object. This function definition
    is marked "private" because this fuction is called only from inside the contract.
    */
    function checkEligibleAmount( address _user)
        private
        returns (uint256, uint256)
    {
        uint256 eligibleAmount = 0;
        uint256 _erc721Amount;
        uint256 totaldepositAmount;
        averageStakedTime[DEFAULT_POOL][_user] = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakeCounter[DEFAULT_POOL][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and
        // calculate the eligible amount which needs to be withdrawn and StakeInfo is getting updated in this function.
        // Means if amount is eligible then false value needs to be set in deposit varible.
        for (uint256 i = 0; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = userStakeInfo[DEFAULT_POOL][_user][i];
            // Checking the deposit variable is true
            if (
                stkInfo.withdrawTime == 0 ||
                stkInfo.withdrawTime == block.timestamp
            ) {
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(SECONDS_IN_DAY)
                );
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                    stkInfo.withdrawTime = block.timestamp;
                    if(stkInfo.isERC721){
                        _erc721Amount = _erc721Amount.add(stkInfo.amount);
                        erc721Token.safeTransferFrom(
                        address(this),
                        address(msg.sender),
                        stkInfo.tokenId
                    );
                    }
                } else {
                    updateUserAverageSlashingFees( _user, totaldepositAmount, stkInfo.amount, stkInfo.timestamp);
                    totaldepositAmount = totaldepositAmount.add(stkInfo.amount);
                }
            }
        }
        return (eligibleAmount,_erc721Amount);
    }

    /**
    @notice store Highest 100 staked users
    @param _amount : amount
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. After the first 90 days, DAO governors
    will be based on the staking score, without any limitations.
    */
    function addHighestStakedUser(
        
        uint256 _amount,
        address user
    ) private {
        uint256 i;
        // Getting the array of Highest staker as per pool id.
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[DEFAULT_POOL];
        //for loop to check if the staking address exist in array
        for (i = 0; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                higheststaker[i].deposited = _amount;
                // Called the function for sorting the array in ascending order.
                quickSort( 0, higheststaker.length - 1);
                return;
            }
        }

        if (higheststaker.length < 100) {
            // Here if length of highest staker is less than 100 than we just push the object into array.
            higheststaker.push(HighestAstaStaker(_amount, user));
        } else {
            // Otherwise we check the last staker amount in the array with new one.
            if (higheststaker[0].deposited < _amount) {
                // If the last staker deposited amount is less than new then we put the greater one in the array.
                higheststaker[0].deposited = _amount;
                higheststaker[0].addr = user;
            }
        }
        // Called the function for sorting the array in ascending order.
        quickSort( 0, higheststaker.length - 1);
    }

    /**
    @notice Astra staking track the Highest 100 staked users
    @param user : user address
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. 
    */
    function checkHighestStaker( address user)
        external
        view
        returns (bool)
    {
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[DEFAULT_POOL];
        uint256 i = 0;
        // Applied the loop to check the user in the highest staker list.
        for (i; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                // If user is exists in the list then we return true otherwise false.
                return true;
            }
        }
    }

    /**
    @notice Fetching the list of top astra stakers 
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function getStakerList()
        public
        view
        returns (HighestAstaStaker[] memory)
    {
        return highestStakerInPool[DEFAULT_POOL];
    }

    /**
    @notice Sorting the highes astra staker in pool
    @param left : left
    @param right : right
    @dev Description :
        It is used for sorting the highes astra staker in pool. This function definition is marked
        "internal" because this fuction is called only from inside the contract.
    */
    function quickSort(
        
        uint256 left,
        uint256 right
    ) internal {
        HighestAstaStaker[] storage arr = highestStakerInPool[DEFAULT_POOL];
        if (left >= right) return;
        uint256 divtwo = 2;
        uint256 p = arr[(left + right) / divtwo].deposited; // p = the pivot element
        uint256 i = left;
        uint256 j = right;
        while (i < j) {
            // HighestAstaStaker memory a;
            // HighestAstaStaker memory b;
            while (arr[i].deposited < p) ++i;
            while (arr[j].deposited > p) --j; // arr[j] > p means p still to the left, so j > 0
            if (arr[i].deposited > arr[j].deposited) {
                (arr[i].deposited, arr[j].deposited) = (
                    arr[j].deposited,
                    arr[i].deposited
                );
                (arr[i].addr, arr[j].addr) = (arr[j].addr, arr[i].addr);
            } else ++i;
        }
        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left) quickSort( left, j - 1); // j > left, so j > 0
        quickSort( j + 1, right);
    }

    /**
    @notice Remove highest staker from the staker array
    @param user : user address
    @dev Description :
    This function is basically called from the withdraw function and update the highest staker list. It is used to remove
    highest staker from the staker array. This function definition is marked "private" because this fuction is called only
    from inside the contract.
    */
    function removeHighestStakedUser(
        
        uint256 _amount,
        address user
    ) private {
        // Getting Highest staker list as per the pool id
        HighestAstaStaker[] storage highestStaker = highestStakerInPool[DEFAULT_POOL];
        // Applied this loop is just to find the staker
        for (uint256 i = 0; i < highestStaker.length; i++) {
            if (highestStaker[i].addr == user) {
                // Deleting the staker from the array.
                delete highestStaker[i];
                if (_amount > 0) {
                    // If amount is greater than 0 than we need to add this again in the hisghest staker list.
                    addHighestStakedUser( _amount, user);
                }
                return;
            }
        }
        quickSort( 0, highestStaker.length - 1);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw( uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, DEFAULT_POOL, _amount);
    }

    // Safe astra transfer function, just in case if rounding error causes pool to not have enough ASTRAs.
    function safeAstraTransfer(address _to, uint256 _amount) internal {
        uint256 astraBal = astra.balanceOf(address(this));
        if (_amount > astraBal) {
            astra.transfer(_to, astraBal);
        } else {
            astra.transfer(_to, _amount);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
    // Whitelist addresses to distribute the rewards.
    function whitelistDistributionAddress(address _distributorAddress, bool _value) external onlyOwner {
        require(_distributorAddress != address(0), "zero address");
        eligibleDistributionAddress[_distributorAddress] = _value;
    }

    function decreaseRewardRate(uint256 _amount) external {
        require(eligibleDistributionAddress[msg.sender], "Not eligible");
        // Sync current pool before updating the reward rate.
        updatePool();
        
        uint256 _startBlock = poolInfo[0].lastRewardBlock >= bonusEndBlock
            ? bonusEndBlock
            : poolInfo[0].lastRewardBlock;
        uint256 _totalBlocksLeft = bonusEndBlock.sub(_startBlock);
        require(_totalBlocksLeft > 0, "Distribution Closed");

        // Calculate total pending reward.
        uint256 _totalRewardsLeft = maxPerBlockReward.mul(_totalBlocksLeft);
        require(_totalRewardsLeft > _amount, "Not enough rewards");
        
        uint256 _decreasedPerBlockReward = _totalRewardsLeft
                        .sub(_amount)
                        .mul(MULTIPLIER_DECIMAL)
                        .div(_totalBlocksLeft)
                        .div(MULTIPLIER_DECIMAL);
        maxPerBlockReward = _decreasedPerBlockReward;
        astraPerBlock = _decreasedPerBlockReward
            .mul(MULTIPLIER_DECIMAL)
            .div(poolInfo[0].maxMultiplier);
        safeAstraTransfer(msg.sender, _amount);
        emit ReduceReward(_amount, maxPerBlockReward);
    }

    // Distribute additional rewards to stakers.
    function distributeAdditionalReward(uint256 _rewardAmount) external {
        require(eligibleDistributionAddress[msg.sender], "Not eligible");

        // Get amount that needs to be distributed.
        astra.safeTransferFrom(
            address(msg.sender),
            address(this),
            _rewardAmount
            );

        // Distribute rewards to astra staking pool.
        updatePool();
        uint256 _startBlock = poolInfo[0].lastRewardBlock >= bonusEndBlock
            ? bonusEndBlock
            : poolInfo[0].lastRewardBlock;
        uint256 blockLeft = bonusEndBlock.sub(_startBlock);
        require(blockLeft > 0, "Distribution Closed");

        if (!isFirstDepositInitialized) {
                totalRewards = totalRewards.add(_rewardAmount);
                maxPerBlockReward = totalRewards.div(blockLeft);
            } else {
                maxPerBlockReward = _rewardAmount
                    .add(maxPerBlockReward.mul(blockLeft))
                    .mul(MULTIPLIER_DECIMAL)
                    .div(blockLeft)
                    .div(MULTIPLIER_DECIMAL);
            }
        astraPerBlock = blockLeft
            .mul(maxPerBlockReward)
            .mul(MULTIPLIER_DECIMAL)
            .div(blockLeft)
            .div(poolInfo[0].maxMultiplier);
        emit DistributeReward(_rewardAmount);
    }
}