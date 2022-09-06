// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

// MasterChef is the master of ASTR. He can make ASTR and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ASTR is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

interface Dao {
    function getVotingStatus(address _user) external view returns (bool);
}

contract MasterChef is
    Initializable,
    OwnableUpgradeable
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
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that ASTRs distribution occurs.
        uint256 accASTRPerShare; // Accumulated ASTRs per share, times 1e12. See below.
        uint256 totalBaseMultiplier; // Total rm count of all user
        uint256 totalAmount; // Total amount for Pool
    }

    // The ASTR TOKEN!
    address public ASTR;
    // Lm pool contract address
    mapping(address => bool) public lmpooladdr;
    // DAA contract address
    address public daaAddress;
    // DAO contract address
    address public daoAddress;
    // Block number when bonus ASTR period ends.
    uint256 public bonusEndBlock;
    // ASTR tokens created per block.
    uint256 public ASTRPerBlock;
    // Bonus muliplier for early ASTR makers.
    uint256 public constant BONUS_MULTIPLIER = 1; //no Bonus
    // Pool lptokens info
    mapping(IERC20Upgradeable => bool) public lpTokensStatus;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when ASTR mining starts.
    uint256 public startBlock;
    // The TimeLock Address!
    address public timelock;
    // The vault list
    mapping(uint256 => bool) public vaultList;
    // Total users in pool
    uint256 public totalUsersPool;
    // Total number or pools
    uint256 public totalPools;

    // Latest astra pool ID. Used for deposit from DAA and DAO.
    uint256 public latestAstraPool;
    // Check if its is initial astra pool or not.
    bool public astraPoolInitialized;

    //staking info structure
    struct StakeInfo {
        uint256 amount;
        uint256 totalAmount;
        uint256 timestamp;
        uint256 vault;
        bool deposit;
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
    uint256 public ASTRPoolId;

    //highest staked users
    struct HighestAstaStaker {
        uint256 deposited;
        address addr;
    }
    mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyDaaOrDAO() {
        require(
            daaAddress == _msgSender() || daoAddress == _msgSender(),
            "depositFromDaaAndDAO: caller is not the DAA/DAO"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the lm pool contract.
     */
    modifier onlyLmPool() {
        require(lmpooladdr[_msgSender()], "Caller is not the LmPool");
        _;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositStateUpdate(
        address indexed user,
        uint256 indexed pid,
        bool state,
        uint256 depositID
    );
    event AddPool(address indexed tokenAddress);
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
    This function is basically used to initialize the necessary things of chef contract and set the owner of the
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
        totalPools = 99;
    }

    /**
    @notice Fetching the count of pools are already created
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
    @notice Fetching the list of top astra stakers 
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function getStakerList(uint256 _pid)
        public
        view
        returns (HighestAstaStaker[] memory)
    {
        return highestStakerInPool[_pid];
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
    @notice Update the maximum pools supported.
    @param _totalPools : new maximum number of pools.
    @dev    This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function updateMaximumPool(uint256 _totalPools)
        external
        onlyOwner
    {
        totalPools = _totalPools;
    }

    /**
    @notice Add a new pool for iToken and astra. Can only be called by the owner.
    @param _lpToken : iToken or astra contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function add(IERC20Upgradeable _lpToken) external onlyOwner {
        require(address(_lpToken) != address(0), "Zero Address");
        require(totalPools > poolInfo.length, "Maximum pool limit reached");
        if (ASTR == address(_lpToken)) {
            if (!astraPoolInitialized) {
                astraPoolInitialized = true;
                ASTRPoolId = poolInfo.length;
            }
            // Pushing the pool info object after setting the all neccessary values.
            latestAstraPool = poolInfo.length;
        }
        // Here if the current block number is greater than start block then the lastRewardBlock will be current block
        // otherwise it will the same as start block.
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lastRewardBlock: lastRewardBlock,
                accASTRPerShare: 0,
                totalBaseMultiplier: 0,
                totalAmount: 0
            })
        );
        // Setting the lp token status true becuase pool is active.
        lpTokensStatus[_lpToken] = true;
        emit AddPool(address(_lpToken));
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
    @notice Set lm pool address. Can only be called by the owner.
    @param _lmpooladdr : lm pool contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setLmPoolAddress(address _lmpooladdr, bool _status)
        external
        onlyOwner
    {
        require(_lmpooladdr != address(0), "Zero Address");
        lmpooladdr[_lmpooladdr] = _status;
    }

    /**
    @notice Set DAO address. Can only be called by the owner.
    @param _daoAddress : DAO contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setDaoAddress(address _daoAddress) external onlyOwner {
        require(_daoAddress != address(0), "Zero Address");
        daoAddress = _daoAddress;
    }

    /**
    @notice Set timelock address. Can only be called by the owner.
    @param _timeLock : timelock contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setTimeLockAddress(address _timeLock) external onlyOwner {
        require(_timeLock != address(0), "Zero Address");
        timelock = _timeLock;
    }

    /**
    @notice Set Daa address. Can only be called by the owner.
    @param _address : Daa contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setDaaAddress(address _address) external {
        require(_address != address(0), "Zero Address");
        require(
            msg.sender == owner() || msg.sender == address(timelock),
            "Can only be called by the owner/timelock"
        );
        require(daaAddress != _address, "Already updated");
        daaAddress = _address;
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
    @param _pid : LM pool id
    @param _user : user account address
    @dev Description :
    Depending on users’ staking scores and whether they’ve decided to move Astra tokens to one of the
    lockups vaults, users will get up to 2.5x higher rewards and voting power
    */
    function getRewardMultiplier(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        //Lockup period
        //12months  Threshold/requirement  Staking/LM rewaryds multiplication xx1.8
        //9months   Threshold/requirement  Staking/LM rewards multiplication  x1.3
        //6months   Threshold/requirement  Staking/LM rewards multiplication  x1.2
        uint256 lockupMultiplier = vaultMultiplier(_pid, _user);

        //staking score threshold
        //800k  Threshold/requirement  Staking/LM rewards multiplication  xx1.7
        //300k  Threshold/requirement  Staking/LM rewards multiplication  x1.3
        //100k  Threshold/requirement  Staking/LM rewards multiplication  x1.2
        uint256 stakingscoreMultiplier = 10;
        uint256 stakingscoreval = stakingScore(_pid, _user);
        // Multiplied the value with 10**18 becuase eth network accept the values with 10**18. otherwise below value will
        // be counted after dividing by 10**18.
        uint256 eightk = 800000 * 10**18;
        uint256 threek = 300000 * 10**18;
        uint256 onek = 100000 * 10**18;

        if (stakingscoreval >= eightk) {
            stakingscoreMultiplier = 17;
        } else if (stakingscoreval >= threek) {
            stakingscoreMultiplier = 13;
        } else if (stakingscoreval >= onek) {
            stakingscoreMultiplier = 12;
        }
        // for calculating reward multiplier we need to add staking multiplier and lockupmultiplier
        // and then substract it by 10
        // RM = RM1 + RM2
        return stakingscoreMultiplier.add(lockupMultiplier).sub(10);
    }

    /**
    @notice Calculating the average vault multiplier for multiple vault staking.
    @param _pid : pool id
    @param _user : user address
    @dev Description :
    Here the logic is added to calculate the average vaultMultiplier if user stakes the amount with multiple lockup vaults
    As staking details managed in StakeInfo struct. So from there vault month gets fatched and then the average is calculated
    for all vault period. Let's take an example
    If user has staked the amount in two vaults like 6 and 9 months then vault multiplier would be 11 and 13(it would be
    divided by 10 when we use it) and then the avarage gets calculated as below
    averageVaultMul = (VM1 + VM2)/2 = (11 + 13)/2 = 12, So it would be 1.2 after dividing by 10.
    This function definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function vaultMultiplier(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // final vaultMultiplier value
        uint256 vaultMul;
        // count of the user staking record in which deposit true
        uint256 depositCount;
        uint256 countofstake = userStakingTrack[_pid][_user];
        // Applied the loop for getting the vault value from stake info object and the add it and then
        // divide it with depositCount.
        for (uint256 i = 1; i <= countofstake; i++) {
            StakeInfo memory stkInfo = stakeInfo[_pid][_user][i];
            if (stkInfo.deposit == true) {
                depositCount++;
                if (stkInfo.vault == 12) {
                    vaultMul = vaultMul.add(18);
                } else if (stkInfo.vault == 9) {
                    vaultMul = vaultMul.add(13);
                } else if (stkInfo.vault == 6) {
                    vaultMul = vaultMul.add(11);
                } else {
                    vaultMul = vaultMul.add(10);
                }
            }
        }
        // If deposit count is more than zero then it returns average otherwise it returns 10 means 1.
        if (depositCount > 0) {
            return vaultMul.div(depositCount);
        } else {
            return 10;
        }
    }

    /**
    @notice This function is used to get premium payout bonus percentage.
    @param _pid : pool id
    @param _user : user account address
    @dev Description :
    The basic logic for calculating the premium payout bonus percentage is totally on the basis of user staking score. It 
    will vary as the user staking score gets increased. Here 10 multiplier is used beacause solidity does not supports
    float value. It will be divided by 10 wherever it will be used
    */
    function getPremiumPayoutBonus(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // staking score threshold
        uint256 stakingscoreaddition;
        uint256 stakingscorevalue = stakingScore(_pid, _user);
        // Multiplied the value with 10**18 becuase eth network accept the values with 10**18. otherwise below value will
        // be counted after dividing by 10**18.
        uint256 eightk = 800000 * 10**18;
        uint256 threek = 300000 * 10**18;
        uint256 onek = 100000 * 10**18;

        // Here premium payout bonus percentage is calculated on the basis of staking score
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 2.
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 1.
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 0.5.
        if (stakingscorevalue >= eightk) {
            stakingscoreaddition = 20;
        } else if (stakingscorevalue >= threek) {
            stakingscoreaddition = 10;
        } else if (stakingscorevalue >= onek) {
            stakingscoreaddition = 5;
        }
        return stakingscoreaddition;
    }

    /**
    @notice Deposit/Stake iTokens and astra token to MasterChef.
    @param _pid : pool id
    @param _amount : amount to be deposited
    @param vault : vault months
    @dev Description :
    Deposit/Stake the amount by user. On chef contract user can stake iToken and astra token for getting the ASTRA rewards.
    This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 vault
    ) external {
        require(vaultList[vault] == true, "no vault");
        PoolInfo storage pool = poolInfo[_pid];
        // This function is called for updating the total reward value which user is getting through block rewards
        updateBlockReward(_pid, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        // This function is called to keep record of who is staking the tokens on the chef contract with pool id.
        addUserAddress(msg.sender, _pid);
        if (_amount > 0) {
            // Here if entered amount is greater than 0 then that amount would be transferred from user account to
            // chef contract
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
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

        //user timestamp
        user.timestamp = block.timestamp;
        // update hishest staker array
        addHighestStakedUser(_pid, user.amount, msg.sender);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
    @notice Deposit iTokens to MasterChef from DAA contract for ASTR allocation.
    @param _pid : pool id
    @param _amount : amount to be deposited
    @param vault : vault months
    @param _sender : spender address
    @param isPremium : premium option choice
    @dev Description : deposit/stake the amount by user from DAA contract. this function definition is marked 
         "external" because this fuction is called only from outside the contract.
    */
    function depositFromDaaAndDAO(
        uint256 _pid,
        uint256 _amount,
        uint256 vault,
        address _sender,
        bool isPremium
    ) external onlyDaaOrDAO {
        require(vaultList[vault] == true, "no vault");
        _pid = latestAstraPool;
        PoolInfo storage pool = poolInfo[_pid];
        updateBlockReward(_pid, _sender);
        UserInfo storage user = userInfo[_pid][_sender];
        addUserAddress(_sender, _pid);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            uint256 bonusAmount = getBonusAmount(
                _pid,
                _sender,
                _amount,
                isPremium
            );
            _amount = _amount.add(bonusAmount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        //deposit staking score structure update
        userStakingTrack[_pid][_sender] = userStakingTrack[_pid][_sender].add(
            1
        );
        // Set the id of user staking info.
        uint256 userstakeid = userStakingTrack[_pid][_sender];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = stakeInfo[_pid][_sender][userstakeid];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.totalAmount = user.amount;
        staker.timestamp = block.timestamp;
        staker.vault = vault;
        staker.deposit = true;

        //user timestamp
        user.timestamp = block.timestamp;
        // update hishest staker array
        addHighestStakedUser(_pid, user.amount, _sender);
        emit Deposit(_sender, _pid, _amount);
    }

    /**
    @notice Getting the premium pay ou bonus amount.
    @param _pid : pool id
    @param _user : spender address
    @param _amount : amount to be deposited
    @param isPremium : premium option choice
    @dev Description : Calculate the premium bonus amount which needs to be paid to user who are premium users.
         This function definition is marked "private" because this fuction is called only from inside the contract.
    */
    function getBonusAmount(
        uint256 _pid,
        address _user,
        uint256 _amount,
        bool isPremium
    ) private view returns (uint256) {
        uint256 ppb;
        if (isPremium) {
            ppb = getPremiumPayoutBonus(_pid, _user).add(20);
        } else {
            ppb = getPremiumPayoutBonus(_pid, _user);
        }
        uint256 bonusAmount = _amount.mul(ppb).div(1000);
        return bonusAmount;
    }

    /**
    @notice Withdraw the staked/deposited amount from the pool.
    @param _pid : pool id
    @param _withStake : withdraw the amount with or without stake.
    @dev Description :
    Withdraw the staked/deposited amount and astra reward from chef contract. This function definition is marked"external"
    because this fuction is called only from outside the contract.
    */
    function withdraw(uint256 _pid, bool _withStake) external {
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
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        //update user cooldown status
        user.cooldown = false;
        user.cooldowntimestamp = 0;
        user.totalUserBaseMul = 0;
        // update hishest staker array
        removeHighestStakedUser(_pid, user.amount, msg.sender);
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
    Transfer ASTR Tokens from MasterChef address to the recipient. This function definition is marked "internal"
    because this fuction is called only from inside the contract.
    */
    function safeASTRTransfer(address _to, uint256 _amount) internal {
        uint256 ASTRBal = IERC20Upgradeable(ASTR).balanceOf(address(this));
        require(!(_amount > ASTRBal), "Insufficient amount on chef contract");
        IERC20Upgradeable(ASTR).safeTransfer(_to, _amount);
    }

    /**
    @notice staking score from staked amount
    @param _pid :  pool id
    @param _userAddress : user account address
    @dev Description :
    The staking score is calculated using average holdings over the last 60 days.
    The idea of staking score is to recognise the value of a long term holding even if held assets are small. This is illustrated by below example:
    Holder who stakes 1000 tokens for the last 60 days has an average staking score of 1000
    Holder who stakes 60 000 tokens for 1 day, also has average staking score of 1000
    */
    function stakingScore(uint256 _pid, address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 timeofstakes;
        uint256 amountstaked;
        uint256 daysecondss = 86400;
        uint256 daysOfStakingscore = 60;
        UserInfo storage user = userInfo[_pid][_userAddress];
        uint256 countofstake = userStakingTrack[_pid][_userAddress];
        uint256 stakingscorenett = 0;
        uint256 userStakingScores = 0;

        for (uint256 i = 1; i <= countofstake; i++) {
            // Fetching stake info
            StakeInfo memory stkInfo = stakeInfo[_pid][_userAddress][i];
            if (stkInfo.deposit == true) {
                // timestamp when user deposited/staked the amount
                timeofstakes = stkInfo.timestamp;
                // amount is staked by the user.
                amountstaked = stkInfo.amount;
                //get staking vault
                uint256 vaultMonth = stkInfo.vault;
                // Calling this function for calculating the staking score for each deposit
                stakingscorenett = calcstakingscore(
                    timeofstakes,
                    vaultMonth,
                    amountstaked,
                    stakingscorenett,
                    daysOfStakingscore,
                    daysecondss
                );
                // Once we got the staking score single deposit then we add those into a one varible and get the total
                // staking score of a user.
                userStakingScores = userStakingScores.add(stakingscorenett);
                if (userStakingScores > user.amount) {
                    userStakingScores = user.amount;
                }
            } else {
                userStakingScores = 0;
            }
        }
        return userStakingScores;
    }

    /**
    @notice Staking score calculation
    @param timeofstakes : time of stake
    @param vaultMonth : vault of month
    @param amountstaked : Amount month
    @param stakingscorenett : vault of month
    @param daysOfStakingscore : days Of Stakingscore
    @param daysecondss : day seconds
    @dev Description :The staking score formaula calculation
    */
    function calcstakingscore(
        uint256 timeofstakes,
        uint256 vaultMonth,
        uint256 amountstaked,
        uint256 stakingscorenett,
        uint256 daysOfStakingscore,
        uint256 daysecondss
    ) internal view returns (uint256) {
        uint256 stakeIndays = 0;
        uint256 month = 12;
        // daysOfStakingscore / month (60 / 12) = 5
        uint256 daysByMonthConstant = daysOfStakingscore.div(month);
        uint256 diffInTimestamp = block.timestamp.sub(timeofstakes);
        if (diffInTimestamp > daysecondss) {
            stakeIndays = diffInTimestamp.div(daysecondss);
        } else {
            stakeIndays = 0;
        }

        // This means that if user exceeds the 60 day time period user staking score will remain the same
        if (stakeIndays > 60) {
            stakeIndays = 60;
        }

        //staking score calculation
        if (vaultMonth == 12) {
            if (stakeIndays == 0) {
                amountstaked = 0;
            }
            stakingscorenett = amountstaked;
        } else {
            // on 0 vault not required calcation to get staking days
            if (vaultMonth != 0) {
                daysOfStakingscore = daysOfStakingscore.sub(
                    daysByMonthConstant.mul(vaultMonth)
                );
            }
            stakingscorenett = amountstaked.mul(stakeIndays).div(
                daysOfStakingscore
            );
        }
        return stakingscorenett;
    }

    /**
    @notice Manage the all user address wrt to chef contract pool.
    @param _pid : pool id
    @dev Description :
    Manage the all user address wrt to chef contract pool. Its store all the user address in a map where key is
    pool id and value is array of user address. It is basically used for calculating the every user reward share.
    */
    function addUserAddress(address _user, uint256 _pid) private {
        address[] storage adds = userAddressesInPool[_pid];
        if (userStakingTrack[_pid][_user] == 0) {
            require(
                adds.length < totalUsersPool,
                "Pool maximum number limit reached"
            );
            adds.push(_user);
        }
    }

    /**
    @notice Distribute Individual, Flat and TVL adjusted reward
    @param _pid : pool id
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
    @param _pid : pool id
    @param _amount : amount which needs to be distributed
    @dev Description :
    In individual reward, all base value is calculated in a single iToken pool and calculate the share for every user by
    dividing pool base multiplier with user base mulitiplier.
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
            uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
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
                uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
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
    @notice store Highest 100 staked users
    @param _pid : pool id
    @param _amount : amount
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. After the first 90 days, DAO governors
    will be based on the staking score, without any limitations.
    */
    function addHighestStakedUser(
        uint256 _pid,
        uint256 _amount,
        address user
    ) private {
        uint256 i;
        // Getting the array of Highest staker as per pool id.
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[_pid];
        //for loop to check if the staking address exist in array
        for (i = 0; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                higheststaker[i].deposited = _amount;
                // Called the function for sorting the array in ascending order.
                quickSort(_pid, 0, higheststaker.length - 1);
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
        quickSort(_pid, 0, higheststaker.length - 1);
    }

    /**
    @notice Astra staking track the Highest 100 staked users
    @param _pid : pool id
    @param user : user address
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. 
    */
    function checkHighestStaker(uint256 _pid, address user)
        external
        view
        returns (bool)
    {
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[_pid];
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
    @notice check Staking Score For Delegation
    @param _pid : pool id
    @param user : user
    @dev Description :After the first 90 days, DAO governors
      will be based on the staking score.
    */
    function checkStakingScoreForDelegation(uint256 _pid, address user)
        external
        view
        returns (bool)
    {
        uint256 sscore = stakingScore(_pid, user);
        uint256 onek = 100000 * 10**18;
        //Any ecosystem member with a staking score higher than [X] can submit a voting proposal.
        //On doc there not staking score value fixed yet for now taking One hundred K Token
        if (sscore == onek) {
            return true;
        } else {
            return false;
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
    function updateBlockReward(uint256 _pid, address _sender) public {
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
        UserInfo storage currentUser = userInfo[_pid][_sender];
        uint256 totalPoolBaseMul = 0;
        // Getting the user list of pool.
        address[] memory adds = userAddressesInPool[_pid];
        // Applied the for upadating the pool base multiplier and get the reward mulplier for each user.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            if (user.amount > 0) {
                uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
                if (_sender != adds[i]) {
                    user.preBlockReward = user.preBlockReward.add(blockReward);
                }
                totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
            }
        }
        // Called the fuction to update the total raward with shared block reward for the current user.
        updateCurBlockReward(
            currentUser,
            blockReward,
            totalPoolBaseMul,
            _sender
        );
        pool.lastRewardBlock = PoolEndBlock;
    }

    /**
    @notice Update the current block reward for a single user.
    @param currentUser : current user info obj
    @param blockReward : block reward
    @param totalPoolBaseMul : total base multiplier
    @param _sender : sender address
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
        uint256 totalPoolBaseMul,
        address _sender
    ) private {
        uint256 userBaseMul = currentUser.amount.mul(
            getRewardMultiplier(ASTRPoolId, _sender)
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
    function viewRewardInfo(uint256 _pid) external view returns (uint256) {
        UserInfo memory currentUser = userInfo[_pid][msg.sender];
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
            uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
            totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
        }
        uint256 userBaseMul = currentUser.amount.mul(
            getRewardMultiplier(ASTRPoolId, msg.sender)
        );
        uint256 totalBlockReward = blockReward.add(currentUser.preBlockReward);
        // Calculting the share percentage for the currenct user.
        uint256 sharePercentage = userBaseMul.mul(10000).div(totalPoolBaseMul);
        return
            currentUser.totalReward.add(
                (totalBlockReward.mul(sharePercentage)).div(10000)
            );
    }

    /**
    @notice Distributing the exit fee share
    @param _amount : amount ro be distributed
    @dev Description :
        It is used for ditributing exit fee share and it called from DAA contract. This function definition is marked
        "external" because this fuction is called only from outside the contract.
    */
    function distributeExitFeeShare(uint256 _amount) external onlyDaaOrDAO {
        require(_amount > 0, "Amount should not be zero");
        distributeIndividualReward(ASTRPoolId, _amount);
    }

    /**
    @notice Sorting the highes astra staker in pool
    @param _pid : pool id
    @param left : left
    @param right : right
    @dev Description :
        It is used for sorting the highes astra staker in pool. This function definition is marked
        "internal" because this fuction is called only from inside the contract.
    */
    function quickSort(
        uint256 _pid,
        uint256 left,
        uint256 right
    ) internal {
        HighestAstaStaker[] storage arr = highestStakerInPool[_pid];
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
        if (j > left) quickSort(_pid, left, j - 1); // j > left, so j > 0
        quickSort(_pid, j + 1, right);
    }

    /**
    @notice Remove highest staker from the staker array
    @param _pid : pool id
    @param user : user address
    @dev Description :
    This function is basically called from the withdraw function and update the highest staker list. It is used to remove
    highest staker from the staker array. This function definition is marked "private" because this fuction is called only
    from inside the contract.
    */
    function removeHighestStakedUser(
        uint256 _pid,
        uint256 _amount,
        address user
    ) private {
        // Getting Highest staker list as per the pool id
        HighestAstaStaker[] storage highestStaker = highestStakerInPool[_pid];
        // Applied this loop is just to find the staker
        for (uint256 i = 0; i < highestStaker.length; i++) {
            if (highestStaker[i].addr == user) {
                // Deleting the staker from the array.
                delete highestStaker[i];
                if (_amount > 0) {
                    // If amount is greater than 0 than we need to add this again in the hisghest staker list.
                    addHighestStakedUser(_pid, _amount, user);
                }
                return;
            }
        }
    }

    /**
    @notice voting power calculation
    @param _pid : pool id
    @param _user : user address
    @dev Description :
        Voting power is expressed in voting points (VP). One voting point is equivalent to one staking score
        point. Staking score multipliers apply to voting power.. 
    */
    function votingPower(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        //User get x1.3 from the start for locking funds  on 6 month lockup vault.
        //with pool id and user address call the staking score
        uint256 stakingsScore = stakingScore(_pid, _user);

        //User unlocks additional x1.2 for staking score higher or equal than 100k.
        // Accumulated mulitpliers are now x1.5 (1 + 0.3 + 0.2)
        //User unlocks higher bonus  for staking score higher or equal than 300k.
        //Accumulated mulitpliers are now x1.6 (1 + 0.3 + 0.3)
        uint256 rewardMult = getRewardMultiplier(_pid, _user);
        uint256 votingpower = (stakingsScore.mul(rewardMult)).div(10);
        return votingpower;
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
        // Update the block reward for the current user.
        updateBlockReward(_pid, msg.sender);
        UserInfo storage currentUser = userInfo[_pid][msg.sender];
        if (_withStake) {
            // If user choses to withdraw the ASTRA with staking it in to astra.
            uint256 _amount = currentUser.totalReward;
            // Called this function for staking the ASTRA rewards in astra pool.
            _stakeASTRReward(msg.sender, ASTRPoolId, _amount);
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
    @notice Staking the ASTR reward in ASTR pool. Called only from Lm pool contract
    @param _pid : pool id
    @param _currUserAddr : current user address
    @param _amount : amount for staking
    @dev Description :
        This function is called from withdrawASTRReward If user choose to stake the 100% reward. In this function
        the amount will be staked in ASTR pool. This function is only called from Lm pool contract.
    */
    function stakeASTRReward(
        address _currUserAddr,
        uint256 _pid,
        uint256 _amount
    ) external onlyLmPool {
        _stakeASTRReward(_currUserAddr, _pid, _amount);
    }

    /**
    @notice Staking the ASTR reward in ASTR pool.
    @param _pid : pool id
    @param _currUserAddr : current user address
    @param _amount : amount for staking
    @dev Description :
        This function is called from withdrawASTRReward If user choose to stake the 100% reward. In this function
        the amount will be staked in ASTR pool.
    */
    function _stakeASTRReward(
        address _currUserAddr,
        uint256 _pid,
        uint256 _amount
    ) private {
        UserInfo storage currentUser = userInfo[_pid][_currUserAddr];
        addUserAddress(_currUserAddr, _pid);
        if (_amount > 0) {
            currentUser.amount = currentUser.amount.add(_amount);
            // staking score structure update
            userStakingTrack[_pid][_currUserAddr] = userStakingTrack[_pid][
                _currUserAddr
            ].add(1);
            uint256 userstakeid = userStakingTrack[_pid][_currUserAddr];
            StakeInfo storage staker = stakeInfo[_pid][_currUserAddr][
                userstakeid
            ];
            staker.amount = _amount;
            staker.totalAmount = currentUser.amount;
            staker.timestamp = block.timestamp;
            staker.vault = 3;
            staker.deposit = true;

            //user timestamp
            currentUser.timestamp = block.timestamp;
        }
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
}