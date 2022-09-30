//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFarmDeployer.sol";

contract ERC20Farm is Ownable, ReentrancyGuard, IERC20Farm{

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 shares, uint256 rewards);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 shares);
    event NewStartBlock(uint256 startBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewMinimumLockTime(uint256 minimumLockTime);
    event NewUserStakeLimit(uint256 userStakeLimit);
    event NewEarlyWithdrawalFee(uint256 earlyWithdrawalFee);
    event NewReflectionOnDeposit(bool);
    event NewFeeReceiver(address);
    event Withdraw(address indexed user, uint256 amount, uint256 shares, uint256 rewards);

    address public feeReceiver;
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    IFarmDeployer private farmDeployer;

    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;
    uint256 public userStakeLimit;
    uint256 public minimumLockTime;
    uint256 public earlyWithdrawalFee;
    uint256 public stakeTotalShares = 0;
    uint256 public totalPendingReward = 0;
    uint256 public lastRewardTokenBalance = 0;
    uint256 public defaultStakePPS;
    bool public keepReflectionOnDeposit;
    bool private initialized = false;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each user that stakes tokens (stakeToken)
    mapping(address => UserInfo) public userInfo;

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
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _userStakeLimit: maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: minimum number of blocks user should wait after deposit to withdraw without fee
     * @param _earlyWithdrawalFee: fee for early withdrawal - in basis points
     * @param _feeReceiver: Receiver of early withdrawal fees
     * @param _keepReflectionOnDeposit: Should the farm keep track of reflection tokens on deposit?
     * @param owner: admin address with ownership
     */
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        uint256 _earlyWithdrawalFee,
        address _feeReceiver,
        bool _keepReflectionOnDeposit,
        address contractOwner
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        if(_keepReflectionOnDeposit) {
            require(_stakeToken != _rewardToken, "Can't track deposit reflections with same reward token");
        }
        require(_rewardPerBlock > 0, "Invalid reward per block");
        transferOwnership(contractOwner);

        if(_feeReceiver == address(0)){
            feeReceiver = address(this);
        } else {
            feeReceiver = _feeReceiver;
        }

        farmDeployer = IFarmDeployer(IFarmDeployer20(msg.sender).farmDeployer());

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        rewardPerBlock = _rewardPerBlock;
        userStakeLimit = _userStakeLimit;
        minimumLockTime = _minimumLockTime;
        earlyWithdrawalFee = _earlyWithdrawalFee;
        keepReflectionOnDeposit = _keepReflectionOnDeposit;

        uint256 decimalsRewardToken = uint256(
            IERC20Metadata(_rewardToken).decimals()
        );
        uint256 decimalsStakeToken = uint256(
            IERC20Metadata(_stakeToken).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(30 - decimalsRewardToken));
        require(decimalsRewardToken >= 5 && decimalsStakeToken >= 5, "Invalid decimals");

        defaultStakePPS = 10 ** (decimalsStakeToken - 4);
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
        _collectFee();
        require(block.number >= startBlock, "Pool is not active yet");
        require(block.number < getFinalBlockNumber(), "Pool has ended");
        UserInfo storage user = userInfo[account];

        if (userStakeLimit > 0) {
            require(
                amount + user.shares * pricePerShare() <= userStakeLimit,
                "User amount above limit"
            );
        }

        _updatePool();
        uint256 PPS = pricePerShare();

        uint256 pending = 0;
        if (user.shares > 0) {
            pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardToken.transfer(account, pending);
            }
            totalPendingReward -= pending;
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
        require(depositedAmount > defaultStakePPS, "Below minimum amount");

        user.shares = user.shares + depositedAmount / PPS;
        stakeTotalShares += depositedAmount / PPS;

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;
        user.depositBlock = block.number;
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Deposit(account, depositedAmount, depositedAmount / PPS, pending);
    }


    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @notice Early withdrawal has a penalty
     * @param _shares: amount of shares to withdraw
     */
    function withdraw(uint256 _shares) external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _shares, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        uint256 transferAmount = _shares * pricePerShare();

        if (_shares > 0) {
            user.shares = user.shares - _shares;
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                uint256 feeAmount = transferAmount * earlyWithdrawalFee / 10000;
                transferAmount -= feeAmount;
                stakeToken.transfer(address(msg.sender), transferAmount);
                if(address(stakeToken) != address(rewardToken) && feeAmount > 0) {
                    stakeToken.transfer(feeReceiver, feeAmount);
                }
            } else {
                stakeToken.transfer(address(msg.sender), transferAmount);
            }
            stakeTotalShares -= _shares;
        }

        user.rewardDebt = user.shares * accTokenPerShare / PRECISION_FACTOR;

        if (pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
            totalPendingReward -= pending;
        }
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Withdraw(msg.sender, transferAmount, _shares, pending);
    }


    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @notice Early withdrawal has a penalty
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];
        uint256 shares = user.shares;
        uint256 amountToTransfer = user.shares * pricePerShare();

        uint256 pending = user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        totalPendingReward -= pending;
        user.shares = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
            if(block.number < earliestBlockToWithdrawWithoutFee){
                uint256 feeAmount = amountToTransfer * earlyWithdrawalFee / 10000;
                amountToTransfer -= feeAmount;
                stakeToken.transfer(address(msg.sender), amountToTransfer);
                if(address(stakeToken) != address(rewardToken) && feeAmount > 0) {
                    stakeToken.transfer(feeReceiver, feeAmount);
                }
            } else {
                stakeToken.transfer(address(msg.sender), amountToTransfer);
            }
            stakeTotalShares -= shares;
        }

        lastRewardTokenBalance = rewardToken.balanceOf(address(this));
        emit EmergencyWithdraw(msg.sender, amountToTransfer, shares);
    }


    /*
     * @notice Calculates the last block number according to available funds
     */
    function getFinalBlockNumber() public view returns (uint256) {
        //in case reward token == stake token
        uint256 sameTokenAmount = address(rewardToken) == address(stakeToken)
            ? stakeTotalShares * pricePerShare()
            : 0;

        uint256 firstBlock = stakeTotalShares == 0 ? block.number : lastRewardBlock;
        uint256 contractBalance = rewardToken.balanceOf(address(this)) - sameTokenAmount;
        return firstBlock + (contractBalance - totalPendingReward) / rewardPerBlock;
    }


    /*
     * @notice Calculates Price Per Share
     */
    function pricePerShare() public view returns(uint256) {
        if(keepReflectionOnDeposit && stakeTotalShares > 10000) {
            return stakeToken.balanceOf(address(this)) / stakeTotalShares;
        }
        return defaultStakePPS;
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
        if(keepReflectionOnDeposit) {
            require(_tokenAddress != address(stakeToken), "Can't recover reflection stake token");
        }
        _updatePool();

        if(_tokenAddress == address(stakeToken)){
            require(_tokenAmount <= (stakeToken.balanceOf(address(this)) - stakeTotalShares * pricePerShare())
            , "Over deposits amount");
        }

        if(_tokenAddress == address(rewardToken)){
            uint256 allowedAmount = rewardToken.balanceOf(address(this)) - totalPendingReward;
            require(_tokenAmount <= allowedAmount, "Over allowed amount");
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
     * @notice Sets reward amount per block
     * @param _rewardPerBlock: Token amount to be distributed for each block
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        require(_rewardPerBlock != 0);
        rewardPerBlock = _rewardPerBlock;

        emit NewRewardPerBlock(_rewardPerBlock);
    }


    /*
     * @notice Sets maximum amount of tokens 1 user is able to stake. 0 for no limit
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     */
    function setUserStakeLimit(uint256 _userStakeLimit) public onlyOwner {
        userStakeLimit = _userStakeLimit;

        emit NewUserStakeLimit(_userStakeLimit);
    }


    /*
     * @notice Sets early withdrawal fee
     * @param _earlyWithdrawalFee: Early withdrawal fee (in basis points)
     */
    function setEarlyWithdrawalFee(uint256 _earlyWithdrawalFee) public onlyOwner {
        require(_earlyWithdrawalFee <= 10000, "Over 10000");
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
     * @notice Sets calculation of reflection tokens on deposit
     * @param _keepReflectionOnDeposit: Should contract keep track of reflections of deposit tokens?
     * @dev Can only be set to true
     */
    function setReflectionOnDeposit(bool _keepReflectionOnDeposit) public onlyOwner {
        require(_keepReflectionOnDeposit == true, "Can't turn off");
        require(_keepReflectionOnDeposit != keepReflectionOnDeposit, "Already set");
        require(address(stakeToken) != address(rewardToken), "Can't track deposit reflections with same reward token");
        keepReflectionOnDeposit = _keepReflectionOnDeposit;

        emit NewReflectionOnDeposit(_keepReflectionOnDeposit);
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
     * @param _rewardPerBlock: Token amount to be distributed for each block
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     * @param _earlyWithdrawalFee: Early withdrawal fee (in basis points)
     * @param _minimumLockTime: Number of blocks
     * @param _keepReflectionOnDeposit: Should contract keep track of reflections of deposit tokens?
     * @param _feeReceiver: Address of fee receiver
     */
    function setFarmValues(
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _earlyWithdrawalFee,
        uint256 _minimumLockTime,
        bool _keepReflectionOnDeposit,
        address _feeReceiver
    ) external onlyOwner {
        //start block
        if (startBlock != _startBlock) {
            setStartBlock(_startBlock);
        }

        //reward per block
        if (rewardPerBlock != _rewardPerBlock) {
            setRewardPerBlock(_rewardPerBlock);
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

        //reflection on deposit
        if (keepReflectionOnDeposit != _keepReflectionOnDeposit) {
            setReflectionOnDeposit(_keepReflectionOnDeposit);
        }

        //fee receiver
        if (feeReceiver != _feeReceiver) {
            setFeeReceiver(_feeReceiver);
        }
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
            uint256 cakeReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                cakeReward * PRECISION_FACTOR / stakeTotalShares;
            return user.shares * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return user.shares * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
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
        uint256 cakeReward = multiplier * rewardPerBlock;
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
        uint256 finalBlock = getFinalBlockNumber();
        if (_to <= finalBlock) {
            return _to - _from;
        } else if (_from >= finalBlock) {
            return 0;
        } else {
            return finalBlock - _from;
        }
    }


    /*
     * @notice Calculates reward token income and transfers specific fee amount.
     * @notice Fee share and fee receiver are specified on Deployer contract
     */
    function _collectFee() private {
        uint256 incomeFee = farmDeployer.incomeFee();
        if (incomeFee > 0) {
            uint256 rewardBalance = rewardToken.balanceOf(address(this));
            if(rewardBalance != lastRewardTokenBalance) {
                uint256 income = rewardBalance - lastRewardTokenBalance;
                uint256 feeAmount = income * incomeFee / 10_000;
                rewardToken.transfer(farmDeployer.feeReceiver(), feeAmount);
            }
        }
    }
}