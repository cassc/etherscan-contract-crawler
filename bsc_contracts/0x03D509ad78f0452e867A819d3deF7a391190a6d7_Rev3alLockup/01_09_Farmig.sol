// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Imports
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libs/IUniRouter02.sol";
import "./libs/IWETH.sol";
import "./libs/IERC20.sol";

// Interface
interface IToken {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

contract Rev3alLockup is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public poolLimitPerUser;
    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;
    uint256 public startBlock;
    uint256 public bonusEndBlock;
    uint256 public duration = 365; // 365 days
    uint256 public PRECISION_FACTOR;
    uint256 public totalStaked;
    uint256 private totalEarned;
    uint256 constant MAX_STAKES = 256;

    bool public hasUserLimit;
    bool public isInitialized;

    uint256 public totalUsers = 0;

    address public POOL_FACTORY;
    address public uniRouterAddress;
    address[] public earnedToStakedPath;
    address public walletA;
    address public stakingToken;
    address public earnedToken;

    struct Lockup {
        uint8 stakeType;
        uint256 duration;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 rate;
        uint256 accTokenPerShare;
        uint256 lastRewardBlock;
        uint256 totalStaked;
        bool enableCompound;
        uint256 emergencyWithdrawFee;
    }

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 locked;
        uint256 available;
    }

    struct Stake {
        uint8 stakeType;
        uint256 amount; // amount to stake
        uint256 duration; // the lockup duration of the stake
        uint256 end; // when does the staking period end
        uint256 rewardDebt; // Reward debt
    }

    Lockup[] public lockups;
    mapping(address => Stake[]) public userStakes;
    mapping(address => UserInfo) public userStaked;

    // Events
    event Deposit(address indexed user, uint256 stakeType, uint256 amount);
    event Withdraw(address indexed user, uint256 stakeType, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event LockupUpdated(
        uint8 _type,
        uint256 _duration,
        uint256 _fee0,
        uint256 _fee1,
        uint256 _rate,
        bool _enableCompound,
        uint256 _emergencyWithdrawFee
    );
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);

    event DevWalletUpdated(address _dev);
    event CharityWalletUpdated(address _charity);
    event WalletAUpadted(address _walletA);
    event BuybackAddressUpadted(address _addr);
    event DurationUpdated(uint256 _duration);

    event SetSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] _path0
    );

    constructor() {
        POOL_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _earnedToken: earned token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _earnedToStakedPath: swap path to compound (earned -> staking path)
     */
    function initialize(
        address _stakingToken,
        address _earnedToken,
        address _uniRouter,
        address[] memory _earnedToStakedPath
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(msg.sender == POOL_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;
        earnedToken = _earnedToken;

        walletA = msg.sender;

        uint256 decimalsRewardToken = uint256(
            IToken(address(earnedToken)).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(uint256(40).sub(decimalsRewardToken)));

        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;

        lockups.push(Lockup(0, 30, 0, 0, 0, 0, 0, 0, false, 130));
        lockups.push(Lockup(2, 180, 0, 0, 0, 0, 0, 0, false, 90));
        lockups.push(Lockup(3, 365, 0, 0, 0, 0, 0, 0, false, 70));

        _resetAllowances();
    }

    function getLatestLockEndTime(address _account, uint8 _stakeType)
        external
        view
        returns (uint256)
    {
        require(_stakeType < lockups.length, "Invalid stake type");

        Stake[] storage stakes = userStakes[_account];
        uint256 end = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            end = stake.end;
            break;
        }
        return end;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function deposit(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);
            if (stake.end > block.timestamp) {
                pendingCompound = pendingCompound.add(_pending);

                if (
                    address(stakingToken) != address(earnedToken) &&
                    _pending > 0
                ) {
                    uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _pending = _afterAmount.sub(_beforeAmount);
                }
                compounded = compounded.add(_pending);
                stake.amount = stake.amount.add(_pending);
            } else {
                pending = pending.add(_pending);
            }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if (compounded > 0) {
            IERC20(stakingToken).transfer(address(this), compounded);
        }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) {
            if (totalEarned > pendingCompound) {
                totalEarned = totalEarned.sub(pendingCompound);
            } else {
                totalEarned = 0;
            }
        }

        uint256 beforeAmount = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = IERC20(stakingToken).balanceOf(address(this));
        uint256 realAmount = afterAmount.sub(beforeAmount);

        if (hasUserLimit) {
            require(
                realAmount.add(user.amount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }
        if (lockup.depositFee > 0) {
            uint256 fee = realAmount.mul(lockup.depositFee).div(10000);
            if (fee > 0) {
                IERC20(stakingToken).transfer(walletA, fee);
                realAmount = realAmount.sub(fee);
            }
        }

        _addStake(_stakeType, msg.sender, lockup.duration, realAmount);

        user.amount = user.amount.add(realAmount).add(compounded);
        lockup.totalStaked = lockup.totalStaked.add(realAmount).add(compounded);
        totalStaked = totalStaked.add(realAmount).add(compounded);

        emit Deposit(msg.sender, _stakeType, realAmount.add(compounded));
    }

    function _addStake(
        uint8 _stakeType,
        address _account,
        uint256 _duration,
        uint256 _amount
    ) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp.add(_duration.mul(1 days));
        uint256 i = stakes.length;
        require(i < MAX_STAKES, "Max stakes");

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        while (i != 0 && stakes[i - 1].end > end) {
            // shift it back one
            stakes[i] = stakes[i - 1];
            i -= 1;
        }

        Lockup storage lockup = lockups[_stakeType];

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.stakeType = _stakeType;
        newStake.duration = _duration;
        newStake.end = end;
        newStake.amount = _amount;
        newStake.rewardDebt = newStake.amount.mul(lockup.accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function withdraw(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        uint256 remained = _amount;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;
            if (remained == 0) break;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);

            if (stake.end > block.timestamp) {
                pendingCompound = pendingCompound.add(_pending);

                if (
                    address(stakingToken) != address(earnedToken) &&
                    _pending > 0
                ) {
                    uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _pending = _afterAmount.sub(_beforeAmount);
                }
                compounded = compounded.add(_pending);
                stake.amount = stake.amount.add(_pending);
            } else {
                pending = pending.add(_pending);
                if (stake.amount > remained) {
                    stake.amount = stake.amount.sub(remained);
                    remained = 0;
                } else {
                    remained = remained.sub(stake.amount);
                    stake.amount = 0;
                }
            }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) { 
            IERC20(stakingToken).transfer(address(this), pendingCompound); 

            if (totalEarned > pendingCompound) {
                totalEarned = totalEarned.sub(pendingCompound);
            } else {
                totalEarned = 0;
            }

            emit Deposit(msg.sender, _stakeType, compounded);
        }

        uint256 realAmount = _amount.sub(remained);
        user.amount = user.amount.sub(realAmount).add(pendingCompound);
        lockup.totalStaked = lockup.totalStaked.sub(realAmount).add(
            pendingCompound
        );
        totalStaked = totalStaked.sub(realAmount).add(pendingCompound);

        if (realAmount > 0) {
            if (lockup.withdrawFee > 0) {
                uint256 fee = realAmount.mul(lockup.withdrawFee).div(10000);
                IERC20(stakingToken).transfer(walletA, fee);
                realAmount = realAmount.sub(fee);
            }

            IERC20(stakingToken).transfer(address(msg.sender), realAmount);
        }

        emit Withdraw(msg.sender, _stakeType, realAmount);
    }

    function claimReward(uint8 _stakeType) external nonReentrant {
        if (_stakeType >= lockups.length) return;
        if (startBlock == 0) return;

        _updatePool(_stakeType);

        // UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        // uint256 pendingCompound = 0;
        // uint256 compounded = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);

            // if (stake.end > block.timestamp) {
            //     pendingCompound = pendingCompound.add(_pending);

            //     if (
            //         address(stakingToken) != address(earnedToken) &&
            //         _pending > 0
            //     ) {
            //         uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
            //             address(this)
            //         );
            //         _safeSwap(_pending, earnedToStakedPath, address(this));
            //         uint256 _afterAmount = IERC20(stakingToken).balanceOf(
            //             address(this)
            //         );
            //         _pending = _afterAmount.sub(_beforeAmount);
            //     }
            //     compounded = compounded.add(_pending);
            //     stake.amount = stake.amount.add(_pending);
            // } else {
            pending = pending.add(_pending);
            // }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        // if (pendingCompound > 0) {

        //     if (totalEarned > pendingCompound) {
        //         totalEarned = totalEarned.sub(pendingCompound);
        //     } else {
        //         totalEarned = 0;
        //     }

        //     user.amount = user.amount.add(compounded);
        //     lockup.totalStaked = lockup.totalStaked.add(compounded);
        //     totalStaked = totalStaked.add(compounded);

        //     emit Deposit(msg.sender, _stakeType, compounded);
        // }
    }

    function compoundReward(uint8 _stakeType) external nonReentrant {
        if (_stakeType >= lockups.length) return;
        if (startBlock == 0) return;

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];
        require(lockup.enableCompound, "Compound is disabled in this lockup!");

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);
            pending = pending.add(_pending);

            if (address(stakingToken) != address(earnedToken) && _pending > 0) {
                uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                    address(this)
                );
                _safeSwap(_pending, earnedToStakedPath, address(this));
                uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                    address(this)
                );
                _pending = _afterAmount.sub(_beforeAmount);
            }
            pendingCompound = pendingCompound.add(_pending);

            stake.amount = stake.amount.add(_pending);
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if(pendingCompound > 0) {
            IERC20(stakingToken).transfer(address(this), pendingCompound);
        }

        if (pending > 0) {
            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }

            user.amount = user.amount.add(pendingCompound);
            lockup.totalStaked = lockup.totalStaked.add(pendingCompound);
            totalStaked = totalStaked.add(pendingCompound);

            emit Deposit(msg.sender, _stakeType, pendingCompound);
        }
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw(uint8 _stakeType) external nonReentrant {
        if (_stakeType >= lockups.length) return;

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 amountToTransfer = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            amountToTransfer = amountToTransfer.add(stake.amount);

            stake.amount = 0;
            stake.rewardDebt = 0;
        }

        uint256 withdrawFee = amountToTransfer
            .mul(lockup.emergencyWithdrawFee)
            .div(1000);
            
        if (withdrawFee > 0) {
            IERC20(stakingToken).transfer(
                walletA,
                withdrawFee
            );
        }

        if (amountToTransfer > 0) {
            IERC20(stakingToken).transfer(
                address(msg.sender),
                amountToTransfer.sub(withdrawFee)
            );

            user.amount = user.amount.sub(amountToTransfer);
            lockup.totalStaked = lockup.totalStaked.sub(amountToTransfer);
            totalStaked = totalStaked.sub(amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    function rewardPerBlock(uint8 _stakeType) public view returns (uint256) {
        if (_stakeType >= lockups.length) return 0;

        return lockups[_stakeType].rate;
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 _amount = IERC20(earnedToken).balanceOf(address(this));
        if (address(earnedToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount.sub(totalStaked);
        }

        return _amount;
    }

    function userInfo(uint8 _stakeType, address _account)
        public
        view
        returns (
            uint256 amount,
            uint256 available,
            uint256 locked
        )
    {
        Stake[] storage stakes = userStakes[_account];

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];

            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            amount = amount.add(stake.amount);
            if (block.timestamp > stake.end) {
                available = available.add(stake.amount);
            } else {
                locked = locked.add(stake.amount);
            }
        }
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _account, uint8 _stakeType)
        external
        view
        returns (uint256)
    {
        if (_stakeType >= lockups.length) return 0;
        if (startBlock == 0) return 0;

        Stake[] storage stakes = userStakes[_account];
        Lockup storage lockup = lockups[_stakeType];

        if (lockup.totalStaked == 0) return 0;

        uint256 adjustedTokenPerShare = lockup.accTokenPerShare;
        if (block.number > lockup.lastRewardBlock && lockup.totalStaked != 0) {
            uint256 multiplier = _getMultiplier(
                lockup.lastRewardBlock,
                block.number
            );
            uint256 reward = multiplier.mul(lockup.rate);
            adjustedTokenPerShare = lockup.accTokenPerShare.add(
                reward.mul(PRECISION_FACTOR).div(lockup.totalStaked)
            );
        }

        uint256 pending = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            pending = pending.add(
                stake
                    .amount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(stake.rewardDebt)
            );
        }
        return pending;
    }

    function lastIndex(address _who) public view returns (uint256) {
        Stake[] storage stakes = userStakes[_who];
        if(stakes.length == 0) {
            revert("No deposits!");
        }
        return stakes.length - 1;
    }

    /************************
     ** Admin Methods
     *************************/
    function harvest() external onlyOwner {
        _updatePool(0);

        uint256 _amount = IERC20(stakingToken).balanceOf(address(this));
        _amount = _amount.sub(totalStaked);
    }

    /*
     * @notice Deposit reward token
     * @dev Only call by owner.
     */
    function depositRewards(uint256 _amount) external nonReentrant {
        require(_amount > 0);

        uint256 beforeAmt = IERC20(earnedToken).balanceOf(address(this));
        IERC20(earnedToken).transferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = IERC20(earnedToken).balanceOf(address(this));

        totalEarned = totalEarned.add(afterAmt).sub(beforeAmt);
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(block.number > bonusEndBlock, "Pool is running");

        IERC20(earnedToken).transfer(address(msg.sender), _amount);

        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned.sub(_amount);
            }
        }
    }

    function getActiveStake(address user, uint8 stakeType)
        public
        view
        returns (Stake memory stake_)
    {
        Stake[] memory stakes = userStakes[user];
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeType == stakeType && stakes[i].amount != 0) {
                stake_ = stakes[i];
                break;
            }
        }
        return stake_;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(earnedToken),
            "Cannot be reward token"
        );

        if (_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = IERC20(stakingToken).balanceOf(address(this));
            require(
                _tokenAmount <= tokenBal.sub(totalStaked),
                "Insufficient balance"
            );
        }

        if (_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function startReward() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = block.number.add(100);
        bonusEndBlock = startBlock.add(duration * 28800);
        for (uint256 i = 0; i < lockups.length; i++) {
            lockups[i].lastRewardBlock = startBlock;
        }

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    function updateLockup(
        uint8 _stakeType,
        uint256 _duration,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _rate,
        bool _enableCompound,
        uint256 _emergencyWithdrawFee
    ) external onlyOwner {
        // require(block.number < startBlock, "Pool was already started");
        require(_stakeType < lockups.length, "Lockup Not found");
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        Lockup storage _lockup = lockups[_stakeType];
        _lockup.duration = _duration;
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;
        _lockup.rate = _rate;
        _lockup.enableCompound = _enableCompound;
        _lockup.emergencyWithdrawFee = _emergencyWithdrawFee;

        emit LockupUpdated(
            _stakeType,
            _duration,
            _depositFee,
            _withdrawFee,
            _rate,
            _enableCompound,
            _emergencyWithdrawFee
        );
    }

    function addLockup(
        uint256 _duration,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _rate,
        bool _enableCompound,
        uint256 _emergencyWithdrawFee
    ) external onlyOwner {
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        lockups.push();

        Lockup storage _lockup = lockups[lockups.length - 1];
        _lockup.duration = _duration;
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;
        _lockup.rate = _rate;
        _lockup.enableCompound = _enableCompound;
        _lockup.emergencyWithdrawFee = _emergencyWithdrawFee;
        _lockup.lastRewardBlock = block.number;

        emit LockupUpdated(
            uint8(lockups.length - 1),
            _duration,
            _depositFee,
            _withdrawFee,
            _rate,
            _enableCompound,
            _emergencyWithdrawFee
        );
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(
            _walletA != address(0x0) || _walletA != walletA,
            "Invalid address"
        );

        walletA = _walletA;
        emit WalletAUpadted(_walletA);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(startBlock == 0, "Pool was already started");
        require(_duration >= 30, "lower limit reached");

        duration = _duration;
        emit DurationUpdated(_duration);
    }

    function setSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] memory _earnedToStakedPath
    ) external onlyOwner {
        require(
            _slippageFactor <= slippageFactorUL,
            "_slippageFactor too high"
        );

        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;

        emit SetSettings(_slippageFactor, _uniRouter, _earnedToStakedPath);
    }

    function resetAllowances() external onlyOwner {
        _resetAllowances();
    }

    /************************
     ** Internal Methods
     *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool(uint8 _stakeType) internal {
        Lockup storage lockup = lockups[_stakeType];
        if (block.number <= lockup.lastRewardBlock) return;

        if (lockup.totalStaked == 0) {
            lockup.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(
            lockup.lastRewardBlock,
            block.number
        );
        uint256 _reward = multiplier.mul(lockup.rate);
        lockup.accTokenPerShare = lockup.accTokenPerShare.add(
            _reward.mul(PRECISION_FACTOR).div(lockup.totalStaked)
        );
        lockup.lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(
            _amountIn,
            _path
        );
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            block.timestamp.add(600)
        );
    }

    function _resetAllowances() internal {
        IERC20(earnedToken).approve(uniRouterAddress, uint256(0));
        IERC20(earnedToken).increaseAllowance(
            uniRouterAddress,
            type(uint256).max
        );
    }

    receive() external payable {}
}