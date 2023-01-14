// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./interface/IERC721.sol";
import "./interface/IFactory.sol";

interface Chef {
    function ASTRPoolId() external view returns (uint256);

    function stakeASTRReward(
        address _currUserAddr,
        uint256 _pid,
        uint256 _amount
    ) external;

    function getRewardMultiplier(uint256 _pid, address _user)
        external
        view
        returns (uint256);
    
    function totalPools()
        external
        pure
        returns (uint256);
}

contract LmPoolV3 is
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        bool cooldown;
        uint256 timestamp;
        uint256 totalUserBaseMul;
        uint256 totalReward;
        uint256 cooldowntimestamp;
        uint256 preBlockReward;
        uint256 totalClaimedReward;
        uint256 claimedToday;
        uint256 claimedTimestamp;
    }

    struct PoolInfo {
        IERC721 lpToken; // Address of LP token contract.
        address token0;
        address token1;
        uint256 lastRewardBlock; // Last block number that ASTRs distribution occurs.
        uint256 totalBaseMultiplier; // Total rm count of all user
        uint256 totalAmount; // Total amount for Pool
    }

    // The ASTR TOKEN!
    address public ASTR;
    // Chef contract address
    address public chefaddr;
    // Block number when bonus ASTR period ends.
    uint256 public bonusEndBlock;
    // ASTR tokens created per block.
    uint256 public ASTRPerBlock;
    // Bonus muliplier for early ASTR makers.
    uint256 public constant BONUS_MULTIPLIER = 1; //no Bonus
    // Pool lptokens info
    mapping(address => mapping(address => bool)) public lpTokensStatus;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when ASTR mining starts.
    uint256 public startBlock;
    // The vault list
    mapping(uint256 => bool) public vaultList;

    // Total users in pool
    uint256 public totalUsersPool;

    //staking info structure
    struct StakeInfo {
        uint256 amount;
        uint256 totalAmount;
        uint256 timestamp;
        uint256 vault;
        bool deposit;
        uint256 tokenId;
    }

    //stake in mapping
    mapping(uint256 => mapping(address => uint256)) private userStakingTrack;
    mapping(uint256 => mapping(address => mapping(uint256 => StakeInfo)))
        public stakeInfo;
    //staking variables
    uint256 private constant dayseconds = 86400;
    mapping(uint256 => address[]) public userAddressesInPool;
    enum RewardType {
        INDIVIDUAL,
        FLAT,
        TVL_ADJUSTED
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositStateUpdate(
        address indexed user,
        uint256 indexed pid,
        bool state,
        uint256 depositID
    );
    event AddPool(address indexed token0, address indexed token1);
    event WithdrawReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        bool stake
    );

    /**
    @notice This function is used for initializing the contract with sort of parameter
    @param _astr : astra contract address
    @param _ASTRPerBlock : ASTR rewards per block
    @param _startBlock : start block number for starting rewars distribution
    @param _bonusEndBlock : end block number for ending reward distribution
    @dev Description :
    This function is basically used to initialize the necessary things of lm pool contract and set the owner of the
    contract. This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function initialize(
        address _astr,
        uint256 _ASTRPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external initializer {
        require(_astr != address(0), "Zero Address");
        __Ownable_init();
        ASTR = _astr;
        ASTRPerBlock = _ASTRPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        totalUsersPool = 99;
    }

    /**
    @notice Fetching the count of pools are already created
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
    @notice Update the maximum users supported in a pool.
    @param _totalUsersPool : new maximum number of users supported in a pool.
    @dev    This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function updateMaximumUsersPool(uint256 _totalUsersPool)
        external
        onlyOwner
    {
        totalUsersPool = _totalUsersPool;
    }

    /**
    @notice Add a new lp to the pool. Can only be called by the owner.
    @param _erc721Token : iToken or astra contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function add(
        IERC721 _erc721Token,
        address _token0,
        address _token1,
        uint24 fee
    ) external onlyOwner {
        require(address(_erc721Token) != address(0), "Zero Address");
        require(Chef(chefaddr).totalPools() > poolInfo.length, "Maximum pool limit reached");
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
        // Here if the current block number is greater than start block then the lastRewardBlock will be current block
        // otherwise it will the same as start block.
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        // Pushing the pool info object after setting the all neccessary values.
        poolInfo.push(
            PoolInfo({
                lpToken: _erc721Token,
                token0: _token0,
                token1: _token1,
                lastRewardBlock: lastRewardBlock,
                totalBaseMultiplier: 0,
                totalAmount: 0
            })
        );
        // Setting the lp token status true becuase pool is active.
        lpTokensStatus[_token0][_token1] = true;
        lpTokensStatus[_token1][_token0] = true;
        emit AddPool(_token0, _token1);
    }

    /**
    @notice Add voult month. Can only be called by the owner.
    @param val : value of month like 0, 3, 6, 9, 12
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function addVault(uint256 val) external onlyOwner {
        vaultList[val] = true;
    }

    /**
    @notice Set chef address. Can only be called by the owner.
    @param _chefaddr : chef contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setChefAddress(address _chefaddr) external onlyOwner {
        require(_chefaddr != address(0), "Zero Address");
        chefaddr = _chefaddr;
    }

    /**
    @notice Return reward multiplier over the given _from to _to block.
    @param _from : from block number
    @param _to : to block number
    @dev Description :
    This function is just used for getting the diffrence betweem start and end block for block reward calculation.
    This function definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /**
    @notice Reward Multiplier from staked amount
    @param _user : user account address
    @dev Description :
    Depending on users’ staking scores and whether they’ve decided to move Astra tokens to one of the
    lockups vaults, users will get up to 2.5x higher rewards and voting power
    */
    function getRewardMultiplier(address _user) public view returns (uint256) {
        return
            Chef(chefaddr).getRewardMultiplier(
                Chef(chefaddr).ASTRPoolId(),
                _user
            );
    }

    /**
    @notice Deposit LP tokens to MasterChef for ASTR allocation.
    @param _pid : pool id
    @param _tokenId : Token to be deposited
    @param vault : vault months
    @dev Description :
    Deposit/Stake the amount by user. On chef contract user can stake iToken and astra token for getting the ASTRA rewards.
    This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function deposit(
        uint256 _pid,
        uint256 _tokenId,
        uint256 vault
    ) external {
        require(false, "Disabled");
        require(vaultList[vault] == true, "no vault");
        PoolInfo storage pool = poolInfo[_pid];
        updateBlockReward(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        addUserAddress(_pid);
        uint256 _amount;
        address _token0;
        address _token1;

        (, , _token0, _token1, , , , _amount, , , , ) = pool.lpToken.positions(
            _tokenId
        );
        require(lpTokensStatus[_token0][_token1], "LP token not added");
        require(
            (_token0 == pool.token0 && _token1 == pool.token1) ||
                (_token0 == pool.token1 && _token1 == pool.token0),
            "LP token wrong pool Id"
        );
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _tokenId
            );
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        // Updating staking score structure after staking the tokens
        userStakingTrack[_pid][msg.sender] = userStakingTrack[_pid][msg.sender]
            .add(1);
        // Set the id of user staking info.
        uint256 userstakeid = userStakingTrack[_pid][msg.sender];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = stakeInfo[_pid][msg.sender][userstakeid];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.totalAmount = user.amount;
        staker.timestamp = block.timestamp;
        staker.vault = vault;
        staker.deposit = true;
        staker.tokenId = _tokenId;

        //user timestamp
        user.timestamp = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
    @notice Withdraw the staked/deposited amount from the pool.
    @param _pid : pool id
    @param _withStake : withdraw the amount with or without stake.
   @dev Description :
    Withdraw the staked/deposited amount and astra reward from lm pool contract. This function definition is marked"external"
    because this fuction is called only from outside the contract.
    */
    function withdraw(uint256 _pid, bool _withStake) external {
        require(false, "Disabled");
        UserInfo storage user = userInfo[_pid][msg.sender];
        //Instead of transferring to a standard staking vault, Astra tokens can be locked (meaning that staker forfeits the right to unstake them for a fixed period of time). There are following lockups vaults: 6,9 and 12 months.
        if (user.cooldown == false) {
            user.cooldown = true;
            user.cooldowntimestamp = block.timestamp;
            return;
        } else {
            // Stakers willing to withdraw tokens from the staking pool will need to go through 7 days
            // of cool-down period. After 7 days, if the user fails to confirm the unstake transaction in the 24h time window, the cooldown period will be reset.
            if (
                block.timestamp > user.cooldowntimestamp.add(dayseconds.mul(8))
            ) {
                user.cooldown = true;
                user.cooldowntimestamp = block.timestamp;
                return;
            } else {
                require(user.cooldown == true, "withdraw: cooldown status");
                require(
                    block.timestamp >=
                        user.cooldowntimestamp.add(dayseconds.mul(7)),
                    "withdraw: cooldown period"
                );
                // Calling withdraw function after all the validation like cooldown period, eligible amount etc.
                _withdraw(_pid, _withStake);
            }
        }
    }

    /**
    @notice Withdraw the staked/deposited amount from the pool.
    @param _pid : pool id
    @param _withStake : withdraw the amount with or without stake.
    @dev Description :
    Withdraw the staked/deposited amount and astra reward. This function definition is marked "private" because
    this fuction is called only from inside the contract.
    */
    function _withdraw(uint256 _pid, bool _withStake) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Calling withdrawASTRReward for claiming the ASTRA reward with or without staking it.
        withdrawASTRReward(_pid, _withStake);
        // Calling the function to check the eligible amount and update accordingly
        uint256 _amount = checkEligibleAmount(_pid, msg.sender, true);
        user.amount = user.amount.sub(_amount);
        pool.totalAmount = pool.totalAmount.sub(_amount);
        // pool.lpToken.safeTransferFrom(address(this),address(msg.sender), _amount);
        //update user cooldown status
        user.cooldown = false;
        user.cooldowntimestamp = 0;
        user.totalUserBaseMul = 0;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
    @notice View the eligible amount which is able to withdraw.
    @param _pid : pool id
    @param _user : user address
    @dev Description :
    View the eligible amount which needs to be withdrawn if user deposits amount in multiple vaults. This function
    definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function viewEligibleAmount(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakingTrack[_pid][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and calculate
        // the eligible amount which needs to be withdrawn
        for (uint256 i = 1; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = stakeInfo[_pid][_user][i];
            // Checking the deposit variable is true
            if (stkInfo.deposit == true) {
                uint256 mintsec = 86400;
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(mintsec)
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
    @param _pid : pool id
    @param _user : user address
    @param _withUpdate : with update
    @dev Description :
    This function is like viewEligibleAmount just here we update the state of stakeInfo object. This function definition
    is marked "private" because this fuction is called only from inside the contract.
    */
    function checkEligibleAmount(
        uint256 _pid,
        address _user,
        bool _withUpdate
    ) private returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakingTrack[_pid][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and
        // calculate the eligible amount which needs to be withdrawn and StakeInfo is getting updated in this function.
        // Means if amount is eligible then false value needs to be set in deposit varible.
        for (uint256 i = 1; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = stakeInfo[_pid][_user][i];
            // Checking the deposit variable is true
            if (stkInfo.deposit == true) {
                uint256 mintsec = 86400;
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(mintsec)
                );
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                    pool.lpToken.safeTransferFrom(
                        address(this),
                        address(msg.sender),
                        stkInfo.tokenId
                    );
                    if (_withUpdate) {
                        stkInfo.deposit = false;
                        emit DepositStateUpdate(msg.sender, _pid, false, i);
                    }
                }
            }
        }
        return eligibleAmount;
    }

    /**
    @notice Safe ASTR transfer function, just in case if rounding error causes pool to not have enough ASTRs.
    @param _to : recipient address
    @param _amount : amount
    @dev Description :
    Transfer ASTR Tokens from Lm Pool address to the recipient. This function definition is marked "internal"
    because this fuction is called only from inside the contract.
    */
    function safeASTRTransfer(address _to, uint256 _amount) internal {
        uint256 ASTRBal = IERC20Upgradeable(ASTR).balanceOf(address(this));
        require(
            !(_amount > ASTRBal),
            "Insufficient amount on lm pool contract"
        );
        IERC20Upgradeable(ASTR).safeTransfer(_to, _amount);
    }

    /**
    @notice Manage the all user address wrt to lm contract pool.
    @param _pid : pool id
    @dev Description :
    Manage the all user address wrt to lm contract pool. It stores all the user address in a map where key is
    pool id and value is array of user address. It is basically used for calculating the every user reward share.
    */
    function addUserAddress(uint256 _pid) private {
        address[] storage adds = userAddressesInPool[_pid];
        if (userStakingTrack[_pid][msg.sender] == 0) {
            require(
                adds.length < totalUsersPool,
                "Pool maximum number limit reached"
            );
            adds.push(msg.sender);
        }
    }

    /**
    @notice Distribute Individual, Flat and TVL adjusted reward
    @param _pid : LM pool id
    @param _type : reward type 
    @param _amount : amount which needs to be distributed
    @dev Requirements:
        Reward type should not except 0, 1, 2.
        0 - INDIVIDUAL Reward
        1 - FLAT Reward
        2 - TVL ADJUSTED Reward
    */
    function distributeReward(
        uint256 _pid,
        RewardType _type,
        uint256 _amount
    ) external onlyOwner {
        require(false, "Disabled");
        if (_type == RewardType.INDIVIDUAL) {
            distributeIndividualReward(_pid, _amount);
        } else if (_type == RewardType.FLAT) {
            distributeFlatReward(_amount);
        } else if (_type == RewardType.TVL_ADJUSTED) {
            distributeTvlAdjustedReward(_amount);
        }
    }

    /**
    @notice Distribute Individual reward to user
    @param _pid : LM pool id
    @param _amount : amount which needs to be distributed
    @dev Description :
    In individual reward, all base value is calculated in a single LM pool and calculate the
    share for every user by dividing pool base multiplier with user base mulitiplier.
    UBM1 = stakedAmount * rewardMultiplier.
    PBM = UBM1+UBM2
    share % for single S1 = UBM1*100/PBM
    reward amount = S1*amount/100
    */
    function distributeIndividualReward(uint256 _pid, uint256 _amount) private {
        uint256 poolBaseMul = 0;
        address[] memory adds = userAddressesInPool[_pid];
        // Applied this loop for updating the user base multiplier for each user and adding all base multiplier for a
        // single pool and updating the poolBaseMul local variable.
        // User base multiplier  = stakedAmount * rewardMultiplier.
        // poolBaseMultiplier = sum of all user base multiplier in the same pool.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 mul = getRewardMultiplier(adds[i]);
            user.totalUserBaseMul = user.amount.mul(mul);
            poolBaseMul = poolBaseMul.add(user.totalUserBaseMul);
        }
        // Applied this loop for calculating the reward share percentage for each user and update the totalReward variable
        // with actual distributed reward.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 sharePercentage = user.totalUserBaseMul.mul(10000).div(
                poolBaseMul
            );
            user.totalReward = user.totalReward.add(
                (_amount.mul(sharePercentage)).div(10000)
            );
        }
    }

    /**
    @notice Distribute Flat reward to user
    @param _amount : amount which needs to be distributed
    @dev Description :
    In Flat reward distribution, here base value is calculated for all pools and calculate the share for each user from
    each pool.
    allPBM = UBM1+UBM2
    share % for single S1 = UBM1*100/allPBM
    reward amount = S1*amount/100
    */
    function distributeFlatReward(uint256 _amount) private {
        uint256 allPoolBaseMul = 0;
        // Applied the loop on all pool array for getting the all users address list.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            address[] memory adds = userAddressesInPool[pid];
            // Applied this loop to update user base multiplier and and add all pool base multiplier by adding all user
            // base multiplier and updating that allPoolBaseMul variable.
            for (uint256 i = 0; i < adds.length; i++) {
                UserInfo storage user = userInfo[pid][adds[i]];
                uint256 mul = getRewardMultiplier(adds[i]);
                user.totalUserBaseMul = user.amount.mul(mul);
                allPoolBaseMul = allPoolBaseMul.add(user.totalUserBaseMul);
            }
        }

        // Applied the loop on all pool array for getting the all users address list.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            address[] memory adds = userAddressesInPool[pid];
            // Applied this loop for calculating the reward share percentage for each user and update the totalReward
            // variable with actual distributed reward.
            for (uint256 i = 0; i < adds.length; i++) {
                UserInfo storage user = userInfo[pid][adds[i]];
                uint256 sharePercentage = user.totalUserBaseMul.mul(10000).div(
                    allPoolBaseMul
                );
                user.totalReward = user.totalReward.add(
                    (_amount.mul(sharePercentage)).div(10000)
                );
            }
        }
    }

    /**
    @notice Distribute TVL adjusted reward to user
    @param _amount : amount which needs to be distributed
    @dev Description :
        In TVL reward, First it needs to calculate the reward share for each on the basis of 
        total value locked of each pool.
        totTvl = TVL1+TVL2
        reward share = TVL1*100/totTvl
        user reward will happen like individual reward after calculating the reward share.
    */
    function distributeTvlAdjustedReward(uint256 _amount) private {
        uint256 totalTvl = 0;
        // Applied the loop for calculating the TVL(total value locked) and updating that in totalTvl variable.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 tvl = pool.totalAmount;
            totalTvl = totalTvl.add(tvl);
        }
        // Applied the loop for calculating the reward share for each pool and the distribute the share with all users.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 tvl = pool.totalAmount;
            uint256 poolRewardShare = tvl.mul(10000).div(totalTvl);
            uint256 reward = (_amount.mul(poolRewardShare)).div(10000);
            // After getting the pool reward share then it will same as individual reward.
            distributeIndividualReward(pid, reward);
        }
    }

    /**
    @notice Update the block reward for a single user, all have the access for this function.
    @param _pid : pool id
    @dev Description :
        It calculates the total block reward with defined astr per block and the distribution will be
        calculated with current user reward multiplier, total user mulplier and total pool multiplier.
        PBM = UBM1+UBM2
        share % for single S1 = UBM1*100/PBM
        reward amount = S1*amount/100
    */
    function updateBlockReward(uint256 _pid) public {
        require(false, "Disabled");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        // Here we are checking the balance of chef contract in behalf of itokens/astra token.
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            // If it is 0 the we just update the last Reward block value in pool and return without doing anything.
            pool.lastRewardBlock = PoolEndBlock;
            return;
        }
        // multiplier would be the diffirence between last reward block and end block.
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        // block reward would be multiplication of multiplier and astra per block value.
        uint256 blockReward = multiplier.mul(ASTRPerBlock);
        UserInfo storage currentUser = userInfo[_pid][msg.sender];
        uint256 totalPoolBaseMul = 0;
        // Getting the user list of pool.
        address[] memory adds = userAddressesInPool[_pid];
        // Applied the for upadating the pool base multiplier and get the reward mulplier for each user.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            if (user.amount > 0) {
                uint256 mul = getRewardMultiplier(adds[i]);
                if (msg.sender != adds[i]) {
                    user.preBlockReward = user.preBlockReward.add(blockReward);
                }
                totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
            }
        }
        // Called the fuction to update the total raward with shared block reward for the current user.
        updateCurBlockReward(currentUser, blockReward, totalPoolBaseMul);
        pool.lastRewardBlock = PoolEndBlock;
    }

    /**
    @notice Update the current block reward for a single user.
    @param currentUser : current user info obj
    @param blockReward : block reward
    @param totalPoolBaseMul : total base multiplier
    @dev Description :
        It calculates the total block reward with defined astr per block and the distribution will be
        calculated with current user reward multiplier, total user mulplier and total pool multiplier.
        PBM = UBM1+UBM2
        share % for single S1 = UBM1*100/PBM
        reward amount = S1*amount/100
        This function definition is marked "private" because this fuction is called only from inside the contract.

    */
    function updateCurBlockReward(
        UserInfo storage currentUser,
        uint256 blockReward,
        uint256 totalPoolBaseMul
    ) private {
        uint256 userBaseMul = currentUser.amount.mul(
            getRewardMultiplier(msg.sender)
        );
        uint256 totalBlockReward = blockReward.add(currentUser.preBlockReward);
        // Calculating the shared percentage for reward.
        uint256 sharePercentage = userBaseMul.mul(10000).div(totalPoolBaseMul);
        currentUser.totalReward = currentUser.totalReward.add(
            (totalBlockReward.mul(sharePercentage)).div(10000)
        );
        currentUser.preBlockReward = 0;
    }

    /**
    @notice View the total user reward in the particular pool.
    @param _pid : pool id
    */
    function viewRewardInfo(uint256 _pid, address _userAddress)
        external
        view
        returns (uint256)
    {
        UserInfo memory currentUser = userInfo[_pid][_userAddress];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 totalReward = currentUser.totalReward;
        // Here we are checking the balance of chef contract in behalf of itokens/astra token.
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            // If it is 0 the we just update the last Reward block value in pool and return total reward of user.
            pool.lastRewardBlock = block.number;
            return totalReward;
        }

        if (block.number <= pool.lastRewardBlock) {
            return totalReward;
        }

        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        // multiplier would be the diffirence between last reward block and end block.
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        // block reward would be multiplication of multiplier and astra per block value.
        uint256 blockReward = multiplier.mul(ASTRPerBlock);

        uint256 totalPoolBaseMul = 0;
        // Getting the user list of pool.
        address[] memory adds = userAddressesInPool[_pid];
        // Applied the loop for updating  totalPoolBaseMul and get the reward mulplier for each user.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 mul = getRewardMultiplier(adds[i]);
            totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
        }
        uint256 userBaseMul = currentUser.amount.mul(
            getRewardMultiplier(_userAddress)
        );
        uint256 totalBlockReward = blockReward.add(currentUser.preBlockReward);
        // Calculting the share percentage for the currenct user.
        uint256 sharePercentage = userBaseMul.mul(10000).div(totalPoolBaseMul);
        return
            currentUser.totalReward.add(
                (totalBlockReward.mul(sharePercentage)).div(10000)
            );
    }

    function distributeExitFeeShare(uint256 _amount) external onlyOwner {
        require(false, "Disabled");
        require(_amount > 0, "Amount should not be zero");
        distributeIndividualReward(Chef(chefaddr).ASTRPoolId(), _amount);
    }

    /**
    @notice Claim ASTR reward by user
    @param _pid : pool id
    @param _withStake : with or without stake
    @dev Description :
        Here User can claim the claimable ASTR reward. There is two option for claiming the reward with
        or without staking the ASTR token. If user wants to claim 100% then he needs to stake the ASTR
        to ASTR pool. Otherwise some ASTR amount would be deducted as a fee.
    */
    function withdrawASTRReward(uint256 _pid, bool _withStake)
        public
    {
        require(false, "Disabled");
        // Update the block reward for the current user.
        updateBlockReward(_pid);
        UserInfo storage currentUser = userInfo[_pid][msg.sender];
        if (_withStake) {
            // If user choses to withdraw the ASTRA with staking it in to astra.
            uint256 _amount = currentUser.totalReward;
            // Called this function for staking the ASTRA rewards in astra pool.
            stakeASTRReward(Chef(chefaddr).ASTRPoolId(), _amount);
            updateClaimedReward(currentUser, _amount);
            emit WithdrawReward(msg.sender, _pid, _amount, true);
        } else {
            // Else we will slash some fee and send the amount to user account.
            uint256 dayInSecond = 86400;
            uint256 dayCount = (block.timestamp.sub(currentUser.timestamp)).div(
                dayInSecond
            );
            if (dayCount >= 90) {
                dayCount = 90;
            }
            // Called this function for slashing fee from reward if claim is happend with in 90 days.
            slashExitFee(currentUser, _pid, dayCount);
        }
        // Updating the total reward to 0 in UserInfo object.
        currentUser.totalReward = 0;
    }

    /**
    @notice Staking the ASTR reward in ASTR pool.
    @param _pid : pool id
    @param _amount : amount for staking
    @dev Description :
        This function is called from withdrawASTRReward If user choose to stake the 100% reward. In this function
        the amount will be staked in ASTR pool.
    */
    function stakeASTRReward(uint256 _pid, uint256 _amount) private {
        Chef(chefaddr).stakeASTRReward(msg.sender, _pid, _amount);
    }

    /**
    @notice Send the ASTR reward to user account
    @param _pid : pool id
    @param currentUser : current user address
    @param dayCount : day on which user wants to withdraw reward
    @dev Description :
        This function is called from withdrawASTRReward If user choose to withdraw the reward amount. In this function
        the amount will be sent to user account after deducting applicable fee.
        leftDayCount = 90 - days
        fee  = totalReward*leftDayCount/100
        claimableReward = totalReward-fee
    */
    function slashExitFee(
        UserInfo storage currentUser,
        uint256 _pid,
        uint256 dayCount
    ) private {
        uint256 totalReward = currentUser.totalReward;
        uint256 sfr = uint256(90).sub(dayCount);
        // Here fee is calculated on the basis of how days is left in 90 days.
        uint256 fee = totalReward.mul(sfr).div(100);
        // Claimable reward is calculated by substracting the fee from total reward.
        uint256 claimableReward = totalReward.sub(fee);
        if (claimableReward > 0) {
            safeASTRTransfer(msg.sender, claimableReward);
            emit WithdrawReward(msg.sender, _pid, claimableReward, false);
            currentUser.totalReward = 0;
        }
        // Deducted fee would be distribute as reward to the same pool user as individual reward
        // with reward multiplier logic.
        distributeIndividualReward(_pid, fee);
        updateClaimedReward(currentUser, claimableReward);
    }

    /**
    @notice This function is used to updated total claimed and claimed in one day rewards.
    @param currentUser : current user address
    @param _amount : amount is to be claimed
    @dev Description :
    This function is called from withdrawASTRReward function for manegaing the total claimed amount and cliamed amount 
    in one day. This function definition is marked "private" because this fuction is called only from inside the contract.
    */
    function updateClaimedReward(UserInfo storage currentUser, uint256 _amount)
        private
    {
        // Adding the amount in total claimed reward.
        currentUser.totalClaimedReward = currentUser.totalClaimedReward.add(
            _amount
        );
        // Calculating the difference between the current and last claimed day.
        uint256 day = block.timestamp.sub(currentUser.claimedTimestamp).div(
            dayseconds
        );
        if (day == 0) {
            // If day is 0 then user is claiming the reward on the current day.
            currentUser.claimedToday = currentUser.claimedToday.add(_amount);
        } else {
            // Otherwise we update the today date in claimed timestamp and amount in claimed amount.
            currentUser.claimedToday = _amount;
            uint256 todayDaySeconds = block.timestamp % dayseconds;
            currentUser.claimedTimestamp = block.timestamp.sub(todayDaySeconds);
        }
    }

    /**
    @notice This function is used view the today's claimed reward.
    @param _pid : pool id
    @dev Description :
    This function is used for getting the today's claimed reward. This function definition is marked "private" because
    this fuction is called only from inside the contract.
    */
    function getTodayReward(uint256 _pid) external view returns (uint256) {
        UserInfo memory currentUser = userInfo[_pid][msg.sender];
        // Calculating the difference between the current and last claimed day.
        uint256 day = block.timestamp.sub(currentUser.claimedTimestamp).div(
            dayseconds
        );
        uint256 claimedToday;
        if (day == 0) {
            // If diffrence is 0 then it returns the claimedToday value from UserInfo object
            claimedToday = currentUser.claimedToday;
        } else {
            // Otherwise it returns 0 because the claimed value celongs to other previous day not for today.
            claimedToday = 0;
        }
        return claimedToday;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function emerergencyWithdrawal(uint256 _amount) external onlyOwner{
        safeASTRTransfer(msg.sender, _amount);
    }

    function airdropNFT(address[] memory _userAddresses, uint256[] memory _tokenIds, address tokenAddress) external onlyOwner {
        require(_userAddresses.length == _tokenIds.length, "Wrong configuration");
        for(uint256 i=0; i< _userAddresses.length; i++){
            IERC721(tokenAddress).safeTransferFrom(
                address(this),
                _userAddresses[i],
                _tokenIds[i]
            );
        }
    }
}