//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFarmDeployer.sol";

contract ERC20FarmFixEnd is Ownable, ReentrancyGuard, IERC20FarmFixEnd{

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 rewardsAmount
    );
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 shares);
    event NewStartBlock(uint256);
    event NewEndBlock(uint256);
    event NewMinimumLockTime(uint256);
    event NewUserStakeLimit(uint256);
    event NewEarlyWithdrawalFee(uint256);
    event RewardIncome(uint256);
    event NewReflectionOnDeposit(bool);
    event NewFeeReceiver(address);
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 rewardsAmount
    );

    address public feeReceiver;
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    IFarmDeployer private farmDeployer;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public lastRewardBlock;
    uint256 public userStakeLimit;
    uint256 public minimumLockTime;
    uint256 public earlyWithdrawalFee;
    uint256 public rewardTotalShares = 0;
    uint256 public stakeTotalShares = 0;
    uint256 public totalPendingReward = 0;
    uint256 public defaultStakePPS;
    uint256 public defaultRewardPPS;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each user that stakes tokens (stakeToken)
    mapping(address => UserInfo) public userInfo;
    bool private initialized = false;

    struct UserInfo {
        uint256 shares; // How many shares the user has for staking
        uint256 rewardDebt; // Reward debt
        uint256 depositBlock; // Reward debt
    }

    /*
     * @notice Initialize the contract
     * @param _stakeToken: stake token address
     * @param _rewardToken: reward token address
     * @param _startBlock: start block
     * @param _endBlock: end reward block
     * @param _userStakeLimit: maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param owner: admin address with ownership
     */
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        address contractOwner
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        transferOwnership(contractOwner);

        if(_feeReceiver == address(0)){
            feeReceiver = address(this);
        } else {
            feeReceiver = _feeReceiver;
        }

        farmDeployer = IFarmDeployer(IFarmDeployer20FixEnd(msg.sender).farmDeployer());

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        endBlock = _endBlock;
        userStakeLimit = _userStakeLimit;
        minimumLockTime = _minimumLockTime;
        earlyWithdrawalFee = _earlyWithdrawalFee;

        uint256 decimalsRewardToken = uint256(
            IERC20Metadata(_rewardToken).decimals()
        );
        uint256 decimalsStakeToken = uint256(
            IERC20Metadata(_stakeToken).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(30 - decimalsRewardToken));
        require(decimalsRewardToken >= 5 && decimalsStakeToken >= 5, "Invalid decimals");

        defaultRewardPPS = 10 ** (decimalsRewardToken / 2);
        if (_rewardToken == _stakeToken) {
            defaultStakePPS = defaultRewardPPS;
        } else {
            defaultStakePPS = 10 ** (decimalsStakeToken - decimalsStakeToken / 2);
        }
    }


    /*
      * @notice Deposit staked tokens on behalf of msg.sender and collect reward tokens (if any)
     * @param amount: amount to deposit (in stakedToken)
     */
    function deposit(uint256 amount) external {
        _deposit(amount, address(msg.sender));
    }


    /*
     * @notice Deposit staked tokens on behalf account and collect reward tokens (if any)
     * @param amount: amount to deposit (in stakedToken)
     * @param account: future owner of deposit
     */
    function depositOnBehalf(uint256 amount, address account) external {
        _deposit(amount, account);
    }


    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param amount: amount to deposit (in stakedToken)
     * @param account: future owner of deposit
     * @dev Internal function
     */
    function _deposit(uint256 amount, address account) internal nonReentrant {
        require(block.number >= startBlock, "Pool is not active yet");
        require(block.number < endBlock, "Pool has ended");
        UserInfo storage user = userInfo[account];

        if (userStakeLimit > 0) {
            require(
                amount + user.shares * stakePPS() <= userStakeLimit,
                "User amount above limit"
            );
        }

        _updatePool();
        uint256 PPS = stakePPS();

        uint256 pending = 0;
        uint256 rewardsAmount = 0;
        if (user.shares > 0) {
            pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardsAmount = _transferReward(account, pending);
                if (totalPendingReward >= pending) {
                    totalPendingReward -= pending;
                } else {
                    totalPendingReward = 0;
                }
            }
        }

        uint256 depositedAmount = 0;
        {
            uint256 initialBalance = stakeToken.balanceOf(address(this));
            stakeToken.transferFrom(
                address(msg.sender),
                address(this),
                amount
            );
            uint256 subsequentBalance = stakeToken.balanceOf(address(this));
            depositedAmount = subsequentBalance - initialBalance;
        }
        uint256 newShares = depositedAmount / PPS;
        require(newShares >= 100, "Below minimum amount");

        user.shares = user.shares + newShares;
        stakeTotalShares += newShares;

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;
        user.depositBlock = block.number;

        emit Deposit(account, depositedAmount, newShares, rewardsAmount);
    }


    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @notice Early withdrawal has a penalty
     * @param _shares: amount of shares to withdraw
     */
    function withdraw(uint256 _shares) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _shares, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;

        uint256 transferredAmount = 0;
        if (_shares > 0) {
            user.shares = user.shares - _shares;
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                transferredAmount = _transferStakeWithFee(address(msg.sender), _shares);
            } else {
                transferredAmount = _transferStake(address(msg.sender), _shares);
            }
        }

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;

        uint256 rewardsAmount = 0;
        if (pending > 0) {
            rewardsAmount = _transferReward(address(msg.sender), pending);
            if (totalPendingReward >= pending) {
                totalPendingReward -= pending;
            } else {
                totalPendingReward = 0;
            }
        }

        emit Withdraw(msg.sender, transferredAmount, _shares, rewardsAmount);
    }


    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @notice Early withdrawal has a penalty
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 shares = user.shares;

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        if (totalPendingReward >= pending) {
            totalPendingReward -= pending;
        } else {
            totalPendingReward = 0;
        }
        user.shares = 0;
        user.rewardDebt = 0;

        uint256 transferredAmount = 0;
        if (shares > 0) {
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                transferredAmount = _transferStakeWithFee(address(msg.sender), shares);
            } else {
                transferredAmount = _transferStake(address(msg.sender), shares);
            }
        }

        emit EmergencyWithdraw(msg.sender, transferredAmount, shares);
    }


    /*
     * @notice Calculates the reward per block shares amount
     * @return Amount of reward shares
     * @dev Internal function for smart contract calculations
     */
    function _rewardPerBlock() private view returns (uint256) {
        if(endBlock <= lastRewardBlock) {
            return 0;
        }
        return (rewardTotalShares - totalPendingReward) / (endBlock - lastRewardBlock);
    }


    /*
     * @notice Calculates the reward per block shares amount
     * @return Amount of reward shares
     * @dev External function for the front end
     */
    function rewardPerBlock() external view returns (uint256) {
        uint256 firstBlock = stakeTotalShares == 0 ? block.number : lastRewardBlock;
        if(endBlock <= firstBlock) {
            return 0;
        }
        return (rewardTotalShares - totalPendingReward) / (endBlock - firstBlock);
    }


    /*
     * @notice Calculates Price Per Share of Stake token
     * @return Price Per Share of Stake token
     */
    function stakePPS() public view returns(uint256) {
        if(stakeTotalShares > 1000) {
            if(address(stakeToken) != address(rewardToken)){
                return stakeToken.balanceOf(address(this)) / stakeTotalShares;
            } else {
                return stakeToken.balanceOf(address(this)) / (stakeTotalShares + rewardTotalShares);
            }
        } else if (address(stakeToken) == address(rewardToken) && rewardTotalShares > 0) {
            return rewardPPS();
        }
        return defaultStakePPS;
    }


    /*
     * @notice Calculates Price Per Reward of Reward token
     * @return Price Per Share of Reward token
     */
    function rewardPPS() public view returns(uint256) {
        if(rewardTotalShares > 1000) {
            if(address(stakeToken) != address(rewardToken)){
                return rewardToken.balanceOf(address(this)) / rewardTotalShares;
            } else {
                return rewardToken.balanceOf(address(this)) / (stakeTotalShares + rewardTotalShares);
            }
        } else if (address(stakeToken) == address(rewardToken) && stakeTotalShares > 0) {
            return stakePPS();
        }
        return defaultRewardPPS;
    }


    /*
     * @notice Allows Owner to withdraw ERC20 tokens from the contract
     * @notice Can't withdraw deposited funds
     * @param _tokenAddress: Address of ERC20 token contract
     * @param _tokenAmount: Amount of tokens to withdraw
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        //If stake and reward tokens are same - forbid recover of these tokens
        require(!(address(stakeToken) == address(rewardToken)
            && _tokenAddress == address(stakeToken))
            , "Not allowed");
        _updatePool();

        if(_tokenAddress == address(stakeToken)){
            require(_tokenAmount <= (stakeToken.balanceOf(address(this)) - stakeTotalShares * stakePPS())
            , "Over deposits amount");
        }

        if(_tokenAddress == address(rewardToken)){
            uint256 _rewardPPS = rewardPPS();
            uint256 sameTokens = 0;
            if(_tokenAddress == address(stakeToken)){
                sameTokens = stakeTotalShares * stakePPS();
            }
            uint256 allowedAmount = (rewardTotalShares - totalPendingReward) * _rewardPPS - sameTokens;
            require(_tokenAmount <= allowedAmount, "Over pending rewards");
            if(rewardTotalShares * _rewardPPS > _tokenAmount) {
                rewardTotalShares -= _tokenAmount / _rewardPPS;
            } else {
                rewardTotalShares = 0;
            }
        }

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }


    /*
     * @notice Sets start block of the pool
     * @param _startBlock: Number of start block
     */
    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(_startBlock >= block.number, "Can't set past block");
        require(startBlock >= block.number, "Staking has already started");
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;

        emit NewStartBlock(_startBlock);
    }


    /*
     * @notice Sets end block of reward distribution
     * @param _endBlock: End block
     */
    function setEndBlock(uint256 _endBlock) public onlyOwner {
        require(block.number < _endBlock, "Invalid number");
        _updatePool();
        endBlock = _endBlock;

        emit NewEndBlock(_endBlock);
    }


    /*
     * @notice Sets maximum amount of tokens 1 user is able to stake. 0 for no limit
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     */
    function setUserStakeLimit(uint256 _userStakeLimit) public onlyOwner {
        require(_userStakeLimit != 0);
        userStakeLimit = _userStakeLimit;

        emit NewUserStakeLimit(_userStakeLimit);
    }


    /*
     * @notice Sets early withdrawal fee
     * @param _earlyWithdrawalFee: Early withdrawal fee (in basis points)
     */
    function setEarlyWithdrawalFee(uint256 _earlyWithdrawalFee) public onlyOwner {
        require(_earlyWithdrawalFee <= 10000);
        require(_earlyWithdrawalFee < earlyWithdrawalFee, "Can't increase");
        earlyWithdrawalFee = _earlyWithdrawalFee;

        emit NewEarlyWithdrawalFee(_earlyWithdrawalFee);
    }


    /*
     * @notice Sets minimum amount of blocks that should pass before user can withdraw
     * his deposit without a fee
     * @param _minimumLockTime: Number of blocks
     */
    function setMinimumLockTime(uint256 _minimumLockTime) public onlyOwner {
        require(_minimumLockTime <= farmDeployer.maxLockTime(),"Over max lock time");
        require(_minimumLockTime < minimumLockTime, "Can't increase");
        minimumLockTime = _minimumLockTime;

        emit NewMinimumLockTime(_minimumLockTime);
    }


    /*
     * @notice Sets receivers of fees for early withdrawal
     * @param _feeReceiver: Address of fee receiver
     */
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0));
        require(_feeReceiver != feeReceiver, "Already set");

        feeReceiver = _feeReceiver;

        emit NewFeeReceiver(_feeReceiver);
    }


    /*
     * @notice Sets farm variables
     * @param _startBlock: Number of start block
     * @param _endBlock: End block
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     * @param _earlyWithdrawalFee: Early withdrawal fee (in basis points)
     * @param _minimumLockTime: Number of blocks
     * @param _feeReceiver: Address of fee receiver
     */
    function setFarmValues(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _userStakeLimit,
        uint256 _earlyWithdrawalFee,
        uint256 _minimumLockTime,
        address _feeReceiver
    ) external onlyOwner {
        //start block
        if (startBlock != _startBlock) {
            setStartBlock(_startBlock);
        }

        //reward per block
        if (endBlock != _endBlock) {
            setEndBlock(_endBlock);
        }

        //user stake limit
        if (userStakeLimit != _userStakeLimit) {
            setUserStakeLimit(_userStakeLimit);
        }

        //early withdrawal fee
        if (earlyWithdrawalFee != _earlyWithdrawalFee) {
            setEarlyWithdrawalFee(_earlyWithdrawalFee);
        }

        //min lock time
        if (minimumLockTime != _minimumLockTime) {
            setMinimumLockTime(_minimumLockTime);
        }

        //fee receiver
        if (feeReceiver != _feeReceiver) {
            setFeeReceiver(_feeReceiver);
        }
    }


    /*
     * @notice Adds reward to the pool
     * @param amount: Amount of reward token
     */
    function addReward(uint256 amount) external {
        require(amount != 0);
        rewardToken.transferFrom(msg.sender, address(this), amount);

        uint256 incomeFee = farmDeployer.incomeFee();
        uint256 feeAmount = 0;
        if (incomeFee > 0) {
            feeAmount = amount * farmDeployer.incomeFee() / 10_000;
            rewardToken.transfer(farmDeployer.feeReceiver(), feeAmount);
        }
        uint256 finalAmount = amount - feeAmount;

        rewardTotalShares += finalAmount / rewardPPS();
        emit RewardIncome(finalAmount);
    }


    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.number > lastRewardBlock && stakeTotalShares != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * _rewardPerBlock();
            uint256 adjustedTokenPerShare = accTokenPerShare +
                cakeReward * PRECISION_FACTOR / stakeTotalShares;
            return (user.shares * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt) * rewardPPS();
        } else {
            return (user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt) * rewardPPS();
        }
    }


    /*
     * @notice Updates pool variables
     */
    function _updatePool() private {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (stakeTotalShares == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier == 0 ? 0 : multiplier * _rewardPerBlock();
        totalPendingReward += cakeReward;
        accTokenPerShare = accTokenPerShare +
            cakeReward * PRECISION_FACTOR / stakeTotalShares;
        lastRewardBlock = block.number;
    }


    /*
     * @notice Calculates number of blocks to pay reward for.
     * @param _from: Starting block
     * @param _to: Ending block
     * @return Number of blocks, that should be rewarded
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    )
    private
    view
    returns (uint256)
    {
        if (_to <= endBlock) {
            return _to - _from;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock - _from;
        }
    }


    /*
     * @notice Transfers specific amount of shares of stake tokens.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     * @return transferAmount: Amount of tokens to transfer
     */
    function _transferStake(address receiver, uint256 shares)
        private returns(uint256 transferredAmount)
    {
        transferredAmount = shares * stakePPS();
        stakeToken.transfer(receiver, transferredAmount);
        stakeTotalShares -= shares;
    }


    /*
     * @notice Transfers specific amount of shares of stake tokens.
     * @notice Calculating fee for early withdrawal.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     * @return transferAmount: Amount of tokens that were transferred to the user
     */
    function _transferStakeWithFee(address receiver, uint256 shares)
        private returns(uint256 transferredAmount)
    {
        uint256 feeAmount = shares * earlyWithdrawalFee / 10000;
        uint256 transferAmount = shares - feeAmount;
        transferredAmount = _transferStake(receiver, transferAmount);

        if(feeReceiver != address(this)) {
            _transferStake(feeReceiver, feeAmount);
        } else if(address(stakeToken) == address(rewardToken)) {
            rewardTotalShares += feeAmount;
        }
    }


    /*
     * @notice Transfers specific amount of shares of reward tokens.
     * @param receiver: Receiver address
     * @param shares: Amount of shares
     * @return rewardsAmount rewardsAmount
     */
    function _transferReward(address receiver, uint256 shares)
    private returns(uint256 rewardsAmount){
        rewardsAmount = shares * rewardPPS();
        rewardToken.transfer(receiver, rewardsAmount);
        rewardTotalShares -= shares;
    }
}