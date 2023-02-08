// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "./UserInfoIterableMapping.sol";

contract FarmerDogeStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UserInfoIterableMapping for UserInfoIterableMapping.Map;
    using UserInfoIterableMapping for UserInfoIterableMapping.UserInfo;
    uint256 private constant PERCENT_PRECISION = 10000;

    // Whether it is initialized
    bool public isInitialized;
    uint256 public duration = 365; // 365 days

    // Whether a limit is set for users
    bool public hasUserLimit;
    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // The block number when staking starts.
    uint256 public startBlock;
    // The block number when staking ends.
    uint256 public bonusEndBlock;

    bool public activeEmergencyWithdraw = false;

    // swap router and path, slipPage
    uint256 public slippageFactor = 8000; // 20% default slippage tolerance
    uint256 public constant slippageFactorUL = 9950;

    address public uniRouterAddress;
    address public walletA;
    address public performanceWallet = 0x315Fd38489A546980a6C91B76C2f64fb6AC5c6bB;
    uint256 public performanceFee = 0.0035 ether;

    // The precision factor
    uint256 public PRECISION_FACTOR;
    uint256[] public PRECISION_FACTOR_DIVIDEND;

    // The staked token
    IERC20 public stakingToken;
    // The dividend token of staking token
    address[] public dividendTokens;

    // Accrued token per share
    uint256[] public accDividendPerShare;

    uint256 public totalStaked;

    uint256 private totalEarned;
    uint256[] public totalDividends;
    uint256[] private dividends;

    uint256 private paidRewards;
    uint256 private shouldTotalPaid;

    struct Lockup {
        uint256 duration;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 rate;
        uint256 accTokenPerShare;
        uint256 lastRewardBlock;
        uint256 totalStaked;
    }

    struct Stake {
        uint256 amount;     // amount to stake
        uint256 duration;   // the lockup duration of the stake
        uint256 end;        // when does the staking period end
        uint256 rewardDebt; // Reward debt
    }
    uint256 constant MAX_STAKES = 256;
    uint256 private processingLimit = 30;

    Lockup public lockupInfo;

    mapping(address => Stake[]) public userStakes;
    UserInfoIterableMapping.Map private userStaked;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);
    event SetEmergencyWithdrawStatus(bool status);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event LockupUpdated(uint256 _duration, uint256 _fee0, uint256 _fee1, uint256 _rate);
    event RewardsStop(uint256 blockNumber);
    event EndBlockUpdated(uint256 blockNumber);
    event UpdatePoolLimit(uint256 poolLimitPerUser, bool hasLimit);

    event ServiceInfoUpadted(address _addr, uint256 _fee);
    event WalletAUpdated(address _addr);
    event DurationUpdated(uint256 _duration);

    event SetSettings(
        uint256 _slippageFactor,
        address _uniRouter
    );

    constructor() {}

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _dividendToken: dividend token address
     * @param _uniRouter: uniswap router address for swap tokens
     */
    function initialize(
        IERC20 _stakingToken,
        address[] memory _dividendTokens,
        uint256 _rewardPerBlock,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _duration,
        address _uniRouter
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;

        walletA = msg.sender;

        uint256 decimalsRewardToken = uint256(IERC20Metadata(address(stakingToken)).decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(40 - decimalsRewardToken));

        for(uint i = 0; i < _dividendTokens.length; i++) {
            dividendTokens.push(_dividendTokens[i]);
            totalDividends.push(0);
            accDividendPerShare.push(0);
            dividends.push(0);

            uint256 decimalsDividendToken = 18;
            if(address(dividendTokens[i]) != address(0x0)) {
                decimalsDividendToken = uint256(IERC20Metadata(address(dividendTokens[i])).decimals());
                require(decimalsDividendToken < 30, "Must be inferior to 30");
            }
            PRECISION_FACTOR_DIVIDEND.push(uint256(10**(40 - decimalsDividendToken)));
        }

        uniRouterAddress = _uniRouter;

        lockupInfo.duration = _duration;
        lockupInfo.depositFee = _depositFee;
        lockupInfo.withdrawFee = _withdrawFee;
        lockupInfo.rate = _rewardPerBlock;
        lockupInfo.accTokenPerShare = 0;
        lockupInfo.lastRewardBlock = 0;
        lockupInfo.totalStaked = 0;
    }

    function addNewDividendToken(address dividendToken) external onlyOwner {
        dividendTokens.push(dividendToken);
        totalDividends.push(0);
        accDividendPerShare.push(0);
        dividends.push(0);

        uint256 decimalsDividendToken = 18;
        if(address(dividendToken) != address(0x0)) {
            decimalsDividendToken = uint256(IERC20Metadata(address(dividendToken)).decimals());
            require(decimalsDividendToken < 30, "Must be inferior to 30");
        }
        uint256 precisionFactor = uint256(10**(40 - decimalsDividendToken));
        PRECISION_FACTOR_DIVIDEND.push(precisionFactor);

        for(uint256 i = 0; i < userStaked.size(); i++){
            UserInfoIterableMapping.UserInfo storage user = userStaked.values[userStaked.keys[i]];
            user.dividendDebt.push(user.amount * 0 / precisionFactor);
        }

    }
    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in stakingToken)
     */
    function deposit(uint256 _amount) external payable nonReentrant {
        require(startBlock > 0 && startBlock < block.number, "Staking hasn't started yet");
        require(_amount > 0, "Amount should be greater than 0");

        _transferPerformanceFee();
        _updatePool();

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];

        if(user.amount > 0) {
            for(uint256 i = 0; i < dividendTokens.length; i++) {
                uint256 pendingDividend =
                user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i] - user.dividendDebt[i];

                pendingDividend = estimateDividendAmount(i, pendingDividend);
                if (pendingDividend > 0) {
                    if(address(dividendTokens[i]) == address(0x0)) {
                        payable(msg.sender).transfer(pendingDividend);
                    } else {
                        IERC20(dividendTokens[i]).safeTransfer(address(msg.sender), pendingDividend);
                    }
                    totalDividends[i] = totalDividends[i] - pendingDividend;
                }
            }
        }

        uint256 beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = stakingToken.balanceOf(address(this));
        uint256 realAmount = afterAmount - beforeAmount;

        if (hasUserLimit) {
            require(
                realAmount + user.amount <= poolLimitPerUser,
                "User amount above limit"
            );
        }
        if (lockupInfo.depositFee > 0) {
            uint256 fee = realAmount * lockupInfo.depositFee / PERCENT_PRECISION;
            if (fee > 0) {
                stakingToken.safeTransfer(walletA, fee);
                realAmount = realAmount - fee;
            }
        }

        _addStake(msg.sender, lockupInfo.duration, realAmount, user.firstIndex);

        user.amount = user.amount + realAmount;
        if(user.dividendDebt.length == 0) {
            for(uint i = 0; i < dividendTokens.length; i++) {
                user.dividendDebt.push(user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i]);
            }
        } else {
            for(uint i = 0; i < dividendTokens.length; i++) {
                user.dividendDebt[i] = user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
            }
        }

        lockupInfo.totalStaked = lockupInfo.totalStaked + realAmount;
        totalStaked = totalStaked + realAmount;

        emit Deposit(msg.sender, realAmount);
    }

    function _addStake(address _account, uint256 _duration, uint256 _amount, uint256 firstIndex) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp + _duration * 1 days;
        uint256 i = stakes.length;
        require(i < MAX_STAKES, "Max stakes");

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        while (i != 0 && stakes[i - 1].end > end && i >= firstIndex) {
            // shift it back one
            stakes[i] = stakes[i - 1];
            i -= 1;
        }

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.duration = _duration;
        newStake.end = end;
        newStake.amount = _amount;
        newStake.rewardDebt = newStake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;

        userStaked.keys.push(_account);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in stakingToken)
     */
    function withdraw(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "Amount should be greater than 0");

        _transferPerformanceFee();
        _updatePool();

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        bool bUpdatable = true;
        uint256 firstIndex = user.firstIndex;

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        uint256 remained = _amount;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(bUpdatable && stake.amount == 0) firstIndex = j;
            if(stake.amount == 0) continue;
            if(remained == 0) break;

            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;
            if(stake.end > block.timestamp) {
                pendingCompound = pendingCompound + _pending;
                compounded = compounded + _pending;
                stake.amount = stake.amount + _pending;
            } else {
                pending = pending + _pending;
                if(stake.amount > remained) {
                    stake.amount = stake.amount - remained;
                    remained = 0;
                } else {
                    remained = remained - stake.amount;
                    stake.amount = 0;

                    if(bUpdatable) firstIndex = j;
                }
            }
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;

            if(stake.amount > 0) bUpdatable = false;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            stakingToken.safeTransfer(address(msg.sender), pending);
            _updateEarned(pending);
            paidRewards = paidRewards + pending;
        }

        if (pendingCompound > 0) {
            require(availableRewardTokens() >= pendingCompound, "Insufficient reward tokens");
            _updateEarned(pendingCompound);
            paidRewards = paidRewards + pendingCompound;

            emit Deposit(msg.sender, compounded);
        }

        for(uint256 i = 0; i < dividendTokens.length; i++) {
            uint256 pendingDividend =
            user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i] - user.dividendDebt[i];

            pendingDividend = estimateDividendAmount(i, pendingDividend);
            if (pendingDividend > 0) {
                if(address(dividendTokens[i]) == address(0x0)) {
                    payable(msg.sender).transfer(pendingDividend);
                } else {
                    IERC20(dividendTokens[i]).safeTransfer(address(msg.sender), pendingDividend);
                }
                totalDividends[i] = totalDividends[i] - pendingDividend;
            }
        }

        uint256 realAmount = _amount - remained;

        user.firstIndex = firstIndex;
        user.amount = user.amount - realAmount + compounded;
        lockupInfo.totalStaked = lockupInfo.totalStaked - realAmount + compounded;
        totalStaked = totalStaked - realAmount + compounded;

        if(realAmount > 0) {
            if (lockupInfo.withdrawFee > 0) {
                uint256 fee = realAmount * lockupInfo.withdrawFee / PERCENT_PRECISION;
                stakingToken.safeTransfer(walletA, fee);
                realAmount = realAmount - fee;
            }

            stakingToken.safeTransfer(address(msg.sender), realAmount);
        }

        for(uint i = 0; i < dividendTokens.length; i++) {
            user.dividendDebt[i] = user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
        }

        emit Withdraw(msg.sender, realAmount);
    }

    function claimReward() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) continue;
            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;

            if(stake.end > block.timestamp) {
                pendingCompound = pendingCompound + _pending;
                compounded = compounded + _pending;
                stake.amount = stake.amount + _pending;
            } else {
                pending = pending + _pending;
            }
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            stakingToken.safeTransfer(address(msg.sender), pending);
            _updateEarned(pending);
            paidRewards = paidRewards + pending;
        }

        if (pendingCompound > 0) {
            require(availableRewardTokens() >= pendingCompound, "Insufficient reward tokens");
            _updateEarned(pendingCompound);
            paidRewards = paidRewards + pendingCompound;

            user.amount = user.amount + compounded;
            lockupInfo.totalStaked = lockupInfo.totalStaked + compounded;
            totalStaked = totalStaked + compounded;

            for(uint i = 0; i < dividendTokens.length; i++) {
                user.dividendDebt[i] = user.dividendDebt[i] + compounded * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
            }

            emit Deposit(msg.sender, compounded);
        }
    }

    function claimDividend() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];
        if (user.amount == 0) return;
        for(uint i = 0; i < dividendTokens.length; i++) {
            uint256 pendingDividend =
            user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i] - user.dividendDebt[i];

            pendingDividend = estimateDividendAmount(i, pendingDividend);
            if (pendingDividend > 0) {
                if(address(dividendTokens[i]) == address(0x0)) {
                    payable(msg.sender).transfer(pendingDividend);
                } else {
                    IERC20(dividendTokens[i]).safeTransfer(address(msg.sender), pendingDividend);
                }
                totalDividends[i] = totalDividends[i] - pendingDividend;
            }

            user.dividendDebt[i] = user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
        }
    }

    function compoundReward() external payable nonReentrant {
        if(startBlock == 0) return;

        _transferPerformanceFee();
        _updatePool();

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 pending = 0;
        uint256 compounded = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) continue;
            if(j - user.firstIndex > processingLimit) break;

            uint256 _pending = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR - stake.rewardDebt;
            pending = pending + _pending;
            compounded = compounded + _pending;

            stake.amount = stake.amount + _pending;
            stake.rewardDebt = stake.amount * lockupInfo.accTokenPerShare / PRECISION_FACTOR;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");

            _updateEarned(pending);
            paidRewards = paidRewards + pending;

            user.amount = user.amount + compounded;
            lockupInfo.totalStaked = lockupInfo.totalStaked + compounded;
            totalStaked = totalStaked + compounded;
            for(uint i = 0; i < dividendTokens.length; i++) {
                user.dividendDebt[i] = user.dividendDebt[i] + compounded * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
            }

            emit Deposit(msg.sender, compounded);
        }
    }

    function compoundDividend() external pure {}

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas to compound or harvest');

        payable(performanceWallet).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        require(activeEmergencyWithdraw, "Emergnecy withdraw not enabled");

        UserInfoIterableMapping.UserInfo storage user = userStaked.values[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 firstIndex = user.firstIndex;
        uint256 amountToTransfer = 0;
        for(uint256 j = user.firstIndex; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.amount == 0) {
                firstIndex = j;
                continue;
            }
            if(j - user.firstIndex > processingLimit) break;

            amountToTransfer = amountToTransfer + stake.amount;

            stake.amount = 0;
            stake.rewardDebt = 0;

            firstIndex = j;
        }

        if (amountToTransfer > 0) {
            stakingToken.safeTransfer(address(msg.sender), amountToTransfer);

            user.firstIndex = firstIndex;
            user.amount = user.amount - amountToTransfer;
            for(uint i = 0; i < dividendTokens.length; i++) {
                user.dividendDebt[i] = user.amount * accDividendPerShare[i] / PRECISION_FACTOR_DIVIDEND[i];
            }

            lockupInfo.totalStaked = lockupInfo.totalStaked - amountToTransfer;
            totalStaked = totalStaked - amountToTransfer;
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    function rewardPerBlock() external view returns (uint256) {
        return lockupInfo.rate;
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 _amount = stakingToken.balanceOf(address(this));
        if (address(stakingToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount - totalStaked;
        }

        return _amount;
    }

    /**
     * @notice Available amount of dividend token
     */
    function availableDividendTokens(uint index) public view returns (uint256) {
        if(address(dividendTokens[index]) == address(0x0)) {
            return address(this).balance;
        }

        uint256 _amount = IERC20(dividendTokens[index]).balanceOf(address(this));
        if(address(dividendTokens[index]) == address(stakingToken)) {
            if(_amount < totalEarned) return 0;
            _amount = _amount - totalEarned;
        }

        if(address(dividendTokens[index]) == address(stakingToken)) {
            if(_amount < totalStaked) return 0;
            _amount = _amount - totalStaked;
        }

        return _amount;
    }

    function insufficientRewards() external view returns (uint256) {
        uint256 adjustedShouldTotalPaid = shouldTotalPaid;
        uint256 remainRewards = availableRewardTokens() + paidRewards;

        if(startBlock == 0) {
            adjustedShouldTotalPaid += lockupInfo.rate * duration * 28800;
        } else {
            uint256 remainBlocks = _getMultiplier(lockupInfo.lastRewardBlock, bonusEndBlock);
            adjustedShouldTotalPaid += lockupInfo.rate * remainBlocks;
        }

        if(remainRewards >= adjustedShouldTotalPaid) return 0;
        return adjustedShouldTotalPaid - remainRewards;
    }

    function userInfo(address _account) external view returns (uint256 amount, uint256 available, uint256 locked) {
        UserInfoIterableMapping.UserInfo memory user = userStaked.values[msg.sender];
        Stake[] memory stakes = userStakes[_account];

        for(uint256 i = user.firstIndex; i < stakes.length; i++) {
            Stake memory stake = stakes[i];
            if(stake.amount == 0) continue;

            amount = amount + stake.amount;
            if(block.timestamp > stake.end) {
                available = available + stake.amount;
            } else {
                locked = locked + stake.amount;
            }
        }
        return (amount, available, locked);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _account) external view returns (uint256) {
        if(startBlock == 0) return 0;
        if(lockupInfo.totalStaked == 0) return 0;

        UserInfoIterableMapping.UserInfo memory user = userStaked.values[msg.sender];
        Stake[] memory stakes = userStakes[_account];

        if(user.amount == 0) return 0;

        uint256 adjustedTokenPerShare = lockupInfo.accTokenPerShare;
        if (block.number > lockupInfo.lastRewardBlock && lockupInfo.totalStaked != 0 && lockupInfo.lastRewardBlock > 0) {
            uint256 multiplier = _getMultiplier(lockupInfo.lastRewardBlock, block.number);
            uint256 reward = multiplier * lockupInfo.rate;
            adjustedTokenPerShare = lockupInfo.accTokenPerShare + reward * PRECISION_FACTOR / lockupInfo.totalStaked;
        }

        uint256 pending = 0;
        for(uint256 i = user.firstIndex; i < stakes.length; i++) {
            Stake memory stake = stakes[i];
            if(stake.amount == 0) continue;

            pending = pending + (
            stake.amount * adjustedTokenPerShare / PRECISION_FACTOR - stake.rewardDebt
            );
        }
        return pending;
    }

    function pendingDividends(address _account) external view returns (uint256[] memory data) {
        data = new uint256[](dividendTokens.length);
        if(startBlock == 0 || totalStaked == 0) return data;

        UserInfoIterableMapping.UserInfo memory user = userStaked.values[_account];
        if(user.amount == 0) return data;

        for(uint i = 0; i < dividendTokens.length; i++) {
            uint256 dividendAmount = availableDividendTokens(i);
            if(dividendAmount < totalDividends[i]) {
                dividendAmount = totalDividends[i];
            }

            uint256 sTokenBal = totalStaked;
            uint256 eTokenBal = availableRewardTokens();
            if(address(stakingToken) == address(stakingToken)) {
                sTokenBal = sTokenBal + eTokenBal;
            }

            uint256 adjustedDividendPerShare = accDividendPerShare[i] + (
            (dividendAmount - totalDividends[i]) * PRECISION_FACTOR_DIVIDEND[i] / sTokenBal
            );

            uint256 pendingDividend = 0;
            if(user.dividendDebt.length >= i + 1){
                pendingDividend = user.amount * adjustedDividendPerShare / PRECISION_FACTOR_DIVIDEND[i] - user.dividendDebt[i];
            }

            data[i] = pendingDividend;
        }

        return data;
    }

    /************************
    ** Admin Methods
    *************************/
    function harvest() external onlyOwner {
        _updatePool();

        for(uint i = 0; i < dividendTokens.length; i++) {
            dividends[i] = estimateDividendAmount(i, dividends[i]);
            if(dividends[i] > 0) {
                if(address(dividendTokens[i]) == address(0x0)) {
                    payable(walletA).transfer(dividends[i]);
                } else {
                    IERC20(dividendTokens[i]).safeTransfer(walletA, dividends[i]);
                }

                totalDividends[i] = totalDividends[i] - dividends[i];
                dividends[i] = 0;
            }
        }
    }

    /*
     * @notice Deposit reward token
     * @dev Only call by owner. Needs to be for deposit of reward token when dividend token is same with reward token.
     */
    function depositRewards(uint _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "invalid amount");

        uint256 beforeAmt = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = stakingToken.balanceOf(address(this));

        totalEarned = totalEarned + afterAmt - beforeAmt;
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require( block.number > bonusEndBlock, "Pool is running");
        require(availableRewardTokens() >= _amount, "Insufficient reward tokens");

        stakingToken.safeTransfer(address(msg.sender), _amount);

        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned - _amount;
            }
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(
            _tokenAddress != address(stakingToken),
            "Cannot be reward token"
        );

        if(_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = stakingToken.balanceOf(address(this));
            require(_tokenAmount <= tokenBal - totalStaked, "Insufficient balance");
        }

        if(_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function startReward() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = block.number + 100;
        bonusEndBlock = startBlock + duration * 28800;
        lockupInfo.lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
        emit RewardsStop(bonusEndBlock);
    }

    function updateEndBlock(uint256 _endBlock) external onlyOwner {
        require(startBlock > 0, "Pool is not started");
        require(bonusEndBlock > block.number, "Pool was already finished");
        require(_endBlock > block.number && _endBlock > startBlock, "Invalid end block");
        bonusEndBlock = _endBlock;
        emit EndBlockUpdated(_endBlock);
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser( bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            poolLimitPerUser = 0;
        }
        hasUserLimit = _hasUserLimit;

        emit UpdatePoolLimit(poolLimitPerUser, hasUserLimit);
    }

    function updateLockup(uint256 _duration, uint256 _depositFee, uint256 _withdrawFee, uint256 _rate) external onlyOwner {
        // require(block.number < startBlock, "Pool was already started");
        require(_depositFee < 2000 && _withdrawFee < 2000, "Invalid fee");

        _updatePool();

        lockupInfo.duration = _duration;
        lockupInfo.depositFee = _depositFee;
        lockupInfo.withdrawFee = _withdrawFee;
        lockupInfo.rate = _rate;

        emit LockupUpdated(_duration, _depositFee, _withdrawFee, _rate);
    }

    function setServiceInfo(address _addr, uint256 _fee) external {
        require(msg.sender == performanceWallet, "setServiceInfo: FORBIDDEN");
        require(_addr != address(0x0), "Invalid address");

        performanceWallet = _addr;
        performanceFee = _fee;

        emit ServiceInfoUpadted(_addr, _fee);
    }

    function setEmergencyWithdraw(bool _status) external {
        require(msg.sender == performanceWallet || msg.sender == owner(), "setEmergencyWithdraw: FORBIDDEN");

        activeEmergencyWithdraw = _status;
        emit SetEmergencyWithdrawStatus(_status);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        duration = _duration;
        emit DurationUpdated(_duration);
    }

    function setProcessingLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid limit");
        processingLimit = _limit;
    }

    function setSettings(
        uint256 _slippageFactor,
        address _uniRouter
    ) external onlyOwner {
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");

        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouter;

        emit SetSettings(_slippageFactor, _uniRouter);
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(_walletA != address(0x0) || _walletA != walletA, "Invalid address");

        walletA = _walletA;
        emit WalletAUpdated(_walletA);
    }


    /************************
    ** Internal Methods
    *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        // calc dividend rate
        if(totalStaked > 0) {
            uint256 sTokenBal = totalStaked;
            uint256 eTokenBal = availableRewardTokens();
            if(address(stakingToken) == address(stakingToken)) {
                sTokenBal = sTokenBal + eTokenBal;
            }

            for(uint i  = 0; i < dividendTokens.length; i++) {
                uint256 dividendAmount = availableDividendTokens(i);
                if(dividendAmount < totalDividends[i]) {
                    dividendAmount = totalDividends[i];
                }

                accDividendPerShare[i] = accDividendPerShare[i] + (
                (dividendAmount - totalDividends[i]) * PRECISION_FACTOR_DIVIDEND[i] / sTokenBal
                );

                if(address(stakingToken) == address(stakingToken)) {
                    dividends[i] = dividends[i] + (dividendAmount - totalDividends[i]) * eTokenBal / sTokenBal;
                }
                totalDividends[i] = dividendAmount;
            }
        }

        if (block.number <= lockupInfo.lastRewardBlock || lockupInfo.lastRewardBlock == 0) return;

        if (lockupInfo.totalStaked == 0) {
            lockupInfo.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lockupInfo.lastRewardBlock, block.number);
        uint256 _reward = multiplier * lockupInfo.rate;
        lockupInfo.accTokenPerShare = lockupInfo.accTokenPerShare + (
        _reward * PRECISION_FACTOR / lockupInfo.totalStaked
        );
        lockupInfo.lastRewardBlock = block.number;
        shouldTotalPaid = shouldTotalPaid + _reward;
    }

    function estimateDividendAmount(uint256 index, uint256 amount) internal view returns(uint256) {
        uint256 dTokenBal = availableDividendTokens(index);
        if(amount > totalDividends[index]) amount = totalDividends[index];
        if(amount > dTokenBal) amount = dTokenBal;
        return amount;
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
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function _updateEarned(uint256 _amount) internal {
        if(totalEarned > _amount) {
            totalEarned = totalEarned - _amount;
        } else {
            totalEarned = 0;
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniswapV2Router02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IERC20(_path[0]).safeApprove(uniRouterAddress, _amountIn);
        IUniswapV2Router02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut * slippageFactor / PERCENT_PRECISION,
            _path,
            _to,
            block.timestamp + 600
        );
    }

    receive() external payable {}
}