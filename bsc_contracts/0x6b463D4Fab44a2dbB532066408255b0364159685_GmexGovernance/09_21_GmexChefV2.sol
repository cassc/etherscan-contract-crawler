/*
 * Global Market Exchange 
 * Official Site  : https://globalmarket.host
 * Private Sale   : https://globalmarketinc.io
 * Email          : [email protected]
 * Telegram       : https://t.me/gmekcommunity
 * Development    : Digichain Development Technology
 * Dev Is         : Tommy Chain & Team
 * Powering new equity blockchain on decentralized real and virtual projects
 * It is a revolutionary blockchain, DeFi and crypto architecture technology project
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Pausable.sol";

import "./lib/VotingPower.sol";

import "./GmexToken.sol";
import "./governance/GmexGovernance.sol";

// Master Contract of Global Market Exchange
contract GmexChefV2 is Initializable, OwnableUpgradeable, Pausable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for GmexToken;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastStakedDate; // quasi-last staked date
        uint256 lastDeposited; // last deposited timestamp
        uint256 lastDepositedAmount; // last deposited amount
        uint256 multiplier; // individual multiplier, times 10000. should not exceed 10000
        //
        // We do some fancy math here. Basically, any point in time, the amount of GMEXs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGMEXPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGMEXPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        // uint256 allocPoint; // How many allocation points assigned to this pool. GMEXs to distribute per block.
        uint256 allocPoint; // Considering 1000 for equal share as other pools
        uint256 lastRewardBlock; // Last block number that GMEXs distribution occurs.
        // uint256 accGMEXPerShare; // Accumulated GMEXs per share, times 1e12. See below.
        uint256 accGMEXPerShareForValidator; // Reward for staking(Rs) + Commission Rate(root(Rs))
        uint256 accGMEXPerShareForNominator; // Reward for staking(Rs)
    }

    string public name;

    GmexToken public gmexToken;
    GmexGovernance public gmexGovernance;

    // Gmex tokens created per block.
    uint256 public gmexPerBlockForValidator;
    uint256 public gmexPerBlockForNominator;

    // Bonus muliplier for early Gmex makers.
    uint256 public bonusMultiplier;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when mining starts.
    uint256 public startBlock;
    // Estimated Total Blocks per year.
    uint256 public blockPerYear;

    // penalty fee when withdrawing reward within 4 weeks of last deposit and after 4 weeks
    uint256 public penaltyFeeRate1;
    uint256 public penaltyFeeRate2;
    // Penalties period
    uint256 public penaltyPeriod;
    // Treasury address
    address public treasury;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier onlyGmexGovernance() {
        require(
            msg.sender == address(gmexGovernance),
            "Only GmexGovernance can perform this action"
        );
        _;
    }

    modifier fridayOnly() {
        uint256 dayCount = block.timestamp / 1 days;
        uint256 dayOfWeek = (dayCount - 2) % 7;
        require(
            dayOfWeek == 5,
            "GmexChef: Operation is allowed only during Friday."
        );
        _;

        // Explanation
        // 1970 January 1 is Thrusday
        // So to get current day's index counting from Saturday as 0,
        // we are subtracting 2 from dayCount and modulo 7.
    }

    function initialize(
        GmexToken _gmexToken,
        address _treasury,
        uint256 _startBlock
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        gmexToken = _gmexToken;
        treasury = _treasury;
        // gmexPerBlock = _gmexPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _gmexToken,
                allocPoint: 1000,
                lastRewardBlock: _startBlock,
                accGMEXPerShareForValidator: 0,
                accGMEXPerShareForNominator: 0
            })
        );
        totalAllocPoint = 1000;

        name = "Gmex Chef";
        bonusMultiplier = 1;
        blockPerYear = 31536000 / 5; // 1 year in seconds / 5 seconds(mean block time).
        penaltyFeeRate1 = 20; // withdraw penalty fee if last deposited is < 4 weeks
        penaltyFeeRate2 = 15; // fee if last deposited is > 4 weeks (always implemented)
        penaltyPeriod = 4 weeks;
    }

    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    function updateGmexGovernanceAddress(GmexGovernance _gmexGovernanceAddress)
        public
        onlyOwner
    {
        gmexGovernance = _gmexGovernanceAddress;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        require(multiplierNumber > 0, "Multipler is too less");
        bonusMultiplier = multiplierNumber;
        //determining the Gmex tokens allocated to each farm
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
        //Determine how many pools we have
    }

    function getPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(bonusMultiplier);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (block.number <= startBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 gmexRewardForValidator = multiplier
            .mul(gmexPerBlockForValidator)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        uint256 gmexRewardForNominator = multiplier
            .mul(gmexPerBlockForNominator)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accGMEXPerShareForValidator = pool.accGMEXPerShareForValidator.add(
            gmexRewardForValidator.mul(1e12).div(lpSupply)
        );
        pool.accGMEXPerShareForNominator = pool.accGMEXPerShareForNominator.add(
            gmexRewardForNominator.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken,
        bool _withUpdate
    ) external onlyOwner whenNotPaused {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGMEXPerShareForValidator: 0,
                accGMEXPerShareForNominator: 0
            })
        );

        updateStakingPool();
    }

    // Update the given pool's Gmex allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner whenNotPaused {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(
                points
            );
            poolInfo[0].allocPoint = points; //setting first pool allocation points to total pool allocation/3
        }
    }

    // To be called at the start of new 3 months tenure, after releasing the vested tokens to this contract.
    // function reallocPoint(bool _withUpdate) public onlyOwner {
    //     if (_withUpdate) {
    //         massUpdatePools();
    //     }
    //     uint256 totalAvailableGMEX = gmexToken.balanceOf(address(this));
    //     uint256 totalGmexPerBlock = (totalAvailableGMEX.mul(4)).div(
    //         blockPerYear
    //     );
    //     // gmexPerBlockForValidator =
    //     // gmexPerBlockForNominator
    // }

    // View function to see pending Rewards.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid]; //getting the specific pool with it id
        UserInfo storage user = userInfo[_pid][_user]; //getting user belongs to that pool
        //getting the accumulated gmex per share in that pool
        uint256 accGMEXPerShare = 0;
        uint256 gmexPerBlock = 0;
        if (gmexGovernance.getValidatorsExists(_user)) {
            accGMEXPerShare = pool.accGMEXPerShareForValidator;
            gmexPerBlock = gmexPerBlockForValidator;
        } else {
            accGMEXPerShare = pool.accGMEXPerShareForNominator;
            gmexPerBlock = gmexPerBlockForNominator;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)); //how many lptokens are there in that pool
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 gmexReward = multiplier
                .mul(gmexPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint); //calculating the Gmex reward
            accGMEXPerShare = accGMEXPerShare.add(
                gmexReward.mul(1e12).div(lpSupply)
            ); //accumulated Gmex per each share
        }
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        return rewardDebt.sub(user.rewardDebt); //get the pending GMEXs which are rewarded to us to harvest
    }

    // Safe Gmex transfer function, just in case if rounding error causes pool to not have enough GMEXs.
    function safeGMEXTransfer(address _to, uint256 _amount) internal {
        uint256 gmexBal = gmexToken.balanceOf(address(this));
        if (_amount > gmexBal) {
            gmexToken.transfer(_to, gmexBal);
        } else {
            gmexToken.transfer(_to, _amount);
        }
    }

    // calculates last deposit timestamp for fair withdraw fee
    function getLastDepositTimestamp(
        uint256 lastDepositedTimestamp,
        uint256 lastDepositedAmount,
        uint256 currentAmount
    ) internal view returns (uint256) {
        if (lastDepositedTimestamp <= 0) {
            return block.timestamp;
        } else {
            uint256 currentTimestamp = block.timestamp;
            uint256 multiplier = currentAmount.div(
                (lastDepositedAmount.add(currentAmount))
            );
            return
                (currentTimestamp.sub(lastDepositedTimestamp))
                    .mul(multiplier)
                    .add(lastDepositedTimestamp);
        }
    }

    // to fetch staked amount in given pool of given user
    // this can be used to know if user has staked or not
    function getStakedAmountInPool(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].amount;
    }

    // to fetch last staked date in given pool of given user
    function getLastStakedDateInPool(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].lastStakedDate;
    }

    // to fetch if user is LP Token Staker or not
    function multiPoolOrNot(address _user) public view returns (bool) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid < length; pid++) {
            if (userInfo[pid][_user].amount > 0) {
                return true;
            }
        }
        return false;
    }

    function transferRewardWithWithdrawFee(
        uint256 userLastDeposited,
        uint256 pending
    ) internal {
        uint256 withdrawFee = 0;
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp < userLastDeposited.add(penaltyPeriod)) {
            withdrawFee = getWithdrawFee(pending, penaltyFeeRate1);
        } else {
            withdrawFee = getWithdrawFee(pending, penaltyFeeRate2);
        }

        uint256 rewardAmount = pending.sub(withdrawFee);

        require(
            pending == withdrawFee + rewardAmount,
            "Gmex::transfer: withdrawfee invalid"
        );

        safeGMEXTransfer(treasury, withdrawFee);
        safeGMEXTransfer(msg.sender, rewardAmount);
    }

    function getAccGMEXPerShare(PoolInfo memory pool)
        internal
        view
        returns (uint256)
    {
        if (gmexGovernance.getValidatorsExists(msg.sender)) {
            return pool.accGMEXPerShareForValidator;
        } else {
            return pool.accGMEXPerShareForNominator;
        }
    }

    function getRewardDebt(UserInfo memory user, uint256 accGMEXPerShare)
        internal
        pure
        returns (uint256)
    {
        return
            user.amount.mul(accGMEXPerShare).div(1e12).mul(user.multiplier).div(
                1e4
            );
    }

    // Deposit LP tokens to GmexChef for Gmex allocation.
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(_pid != 0, "deposit Gmex by staking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 accGMEXPerShare = getAccGMEXPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        if (user.amount > 0) {
            uint256 pending = rewardDebt.sub(user.rewardDebt);
            if (pending > 0) {
                transferRewardWithWithdrawFee(user.lastDeposited, pending);
            }
        }
        if (_amount > 0) {
            // pool.lpToken.safeTransferFrom(
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            user.lastStakedDate = getLastDepositTimestamp(
                user.lastDeposited,
                user.lastDepositedAmount,
                _amount
            );
            user.lastDeposited = block.timestamp;
            user.lastDepositedAmount = _amount;
        }

        user.rewardDebt = rewardDebt;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function getVotingPower(address _user) public view returns (uint256) {
        uint256 gmexStaked = getStakedAmountInPool(0, _user);
        require(gmexStaked > 0, "GmexChefV2: Stake not enough to vote");

        uint256 lastGmexStakedDate = getLastStakedDateInPool(0, _user);
        uint256 numberOfDaysStaked = block
            .timestamp
            .sub(lastGmexStakedDate)
            .div(86400);
        bool multiPool = multiPoolOrNot(_user);
        uint256 votingPower = VotingPower.calculate(
            numberOfDaysStaked,
            gmexStaked,
            multiPool
        );

        return votingPower;
    }

    // Withdraw LP tokens from GmexChef.
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(_pid != 0, "withdraw Gmex by unstaking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 accGMEXPerShare = getAccGMEXPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = rewardDebt;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Get Withdraw fee
    function getWithdrawFee(uint256 _amount, uint256 _penaltyFeeRate)
        internal
        pure
        returns (uint256)
    {
        return _amount.mul(_penaltyFeeRate).div(100);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Update treasury address by the previous treasury address holder.
    function updateTreasuryAddress(address _treasury) external {
        require(msg.sender == treasury, "Updating Treasury Forbidden !");
        treasury = _treasury;
    }

    //Update start reward block
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
    }

    // update gmex per block
    // function updateGmexPerBlock(uint256 _gmexPerBlock) public onlyOwner {
    //     gmexPerBlock = _gmexPerBlock;
    // }

    function updateGmexPerBlockForValidator(uint256 _gmexPerBlock)
        external
        onlyOwner
    {
        gmexPerBlockForValidator = _gmexPerBlock;
    }

    function updateGmexPerBlockForNominator(uint256 _gmexPerBlock)
        external
        onlyOwner
    {
        gmexPerBlockForNominator = _gmexPerBlock;
    }

    // Stake Gmex tokens to GmexChef
    function enterStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        uint256 accGMEXPerShare = getAccGMEXPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        if (user.amount > 0) {
            uint256 pending = rewardDebt.sub(user.rewardDebt);
            if (pending > 0) {
                transferRewardWithWithdrawFee(user.lastDeposited, pending);
            }
        }
        if (_amount > 0) {
            // pool.lpToken.safeTransferFrom(
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            user.lastStakedDate = getLastDepositTimestamp(
                user.lastDeposited,
                user.lastDepositedAmount,
                _amount
            );
            user.lastDeposited = block.timestamp;
            user.lastDepositedAmount = _amount;
        }
        user.rewardDebt = rewardDebt;
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw Gmex tokens from STAKING.
    function leaveStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 accGMEXPerShare = getAccGMEXPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        if (_amount > 0) {
            // check for validator
            if (_amount > gmexGovernance.getValidatorsMinStake()) {
                gmexGovernance.leftStakingAsValidator(msg.sender);
            }

            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = rewardDebt;
        emit Withdraw(msg.sender, 0, _amount);
    }

    // function withdrawReward(uint256 _pid) external fridayOnly {
    function withdrawReward(uint256 _pid) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: not good");
        updatePool(_pid);
        uint256 accGMEXPerShare = getAccGMEXPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accGMEXPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        user.rewardDebt = rewardDebt;
    }

    function slashOfflineValidators(
        uint256 slashingParameter,
        address[] memory offlineValidators,
        address[] memory onlineValidators
    ) public onlyGmexGovernance whenNotPaused {
        require(
            msg.sender == address(gmexGovernance),
            "Only GmexGovernance can slash offline validators"
        );
        if (slashingParameter > 0) {
            for (uint256 i = 0; i < offlineValidators.length; i++) {
                address user = offlineValidators[i];
                uint256 userStake = getStakedAmountInPool(0, user);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeGMEXTransfer(treasury, toBeSlashedAmount);

                UserInfo storage userData = userInfo[0][user];
                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }

        // Reducing multiplier
        for (uint256 i = 0; i < offlineValidators.length; i++) {
            address user = offlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 5000;
        }

        // Recovering multiplier
        for (uint256 i = 0; i < onlineValidators.length; i++) {
            address user = onlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 10000;
        }
    }

    function evaluateThreeValidatorsNominatedByNominator(
        uint256 slashingParameter,
        address[] memory nominators
    ) public onlyGmexGovernance whenNotPaused {
        require(
            msg.sender == address(gmexGovernance),
            "Only GmexGovernance can evaluate three validators nominated by nominator"
        );
        for (uint256 i = 0; i < nominators.length; i++) {
            address nominator = nominators[i];
            UserInfo storage userData = userInfo[0][nominator];
            address[3] memory validatorsNominatedByNominator = gmexGovernance
                .getValidatorsNominatedByNominator(nominator);

            for (uint256 j = 0; j < 3; j++) {
                address validator = validatorsNominatedByNominator[j];
                if (gmexGovernance.haveCastedVote(validator)) {
                    userData.multiplier = 10000;

                    if (j != 0) {
                        gmexGovernance.vestVotesToDifferentValidator(
                            nominator,
                            validatorsNominatedByNominator[0],
                            validator
                        );
                    }

                    return;
                }
            }
            userData.multiplier = 5000;

            if (slashingParameter > 0) {
                uint256 userStake = getStakedAmountInPool(0, nominator);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeGMEXTransfer(treasury, toBeSlashedAmount);

                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }
    }
}