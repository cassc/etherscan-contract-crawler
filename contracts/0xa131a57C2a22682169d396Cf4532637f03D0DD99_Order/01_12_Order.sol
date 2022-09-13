// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Order is Ownable, Pausable, ReentrancyGuard, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastDeposit; /// timestamp
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }

    struct HighestStaker {
        address wallet;
        uint256 amountStaked;
    }


    HighestStaker[] private HighestStakerInPool;
    // The stake token
    IERC20 public stakeToken;
    // The reward token
    IERC20 public rewardToken;
    // Reward tokens created per block.
    uint256 public rewardPerSecond;
    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;
    // Info of each pool.
    PoolInfo public myPool;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when Reward mining starts.
    uint256 private startTimestamp;
    // The block number when mining ends.
    uint256 private bonusEndTimestamp;
    /// If user withdraw before x hours after last deposit, he will pay 15% of fees
    uint256 public withdrawFeesBeforeDuration = 10;
    /// Constant withdraw fees for liquidity
    uint256 public liquidityFees = 5;
    // 72h
    uint256 public feesDuration = 172800;
    
    address private liquidityWallet;
    /// How many topStaker will be allow to make proposal
    uint256 public topStakerAmount = 50;
    

    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);

    constructor(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _bonusEndTimestamp,
        address _liquidityWallet
    )ERC20("Order", "ORDER") {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        bonusEndTimestamp = _bonusEndTimestamp;
        liquidityWallet = _liquidityWallet;
        // staking pool
        myPool = PoolInfo({
            lpToken: _stakeToken,
            allocPoint: 1000,
            lastRewardTimestamp: startTimestamp,
            accRewardTokenPerShare: 0
        });
        totalAllocPoint = 1000;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(from == address(0) || to == address(0)){
            super._beforeTokenTransfer(from, to, amount);
        }else{
            revert("Non transferable token");
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndTimestamp) {
            return _to.sub(_from);
        } else if (_from >= bonusEndTimestamp) {
            return 0;
        } else {
            return bonusEndTimestamp.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = myPool.accRewardTokenPerShare;
        if (block.timestamp > myPool.lastRewardTimestamp && totalStaked != 0) {
            uint256 multiplier = getMultiplier(
                myPool.lastRewardTimestamp,
                block.timestamp
            );
            uint256 tokenReward = multiplier
                .mul(rewardPerSecond)
                .mul(myPool.allocPoint)
                .div(totalAllocPoint);
            accRewardTokenPerShare = accRewardTokenPerShare.add(
                tokenReward.mul(1e30).div(totalStaked)
            );
        }
        return
            user.amount.mul(accRewardTokenPerShare).div(1e30).sub(
                user.rewardDebt
            );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public whenNotPaused {
        if (block.timestamp <= myPool.lastRewardTimestamp) {
            return;
        }
        if (totalStaked == 0) {
            myPool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            myPool.lastRewardTimestamp,
            block.timestamp
        );
        uint256 tokenReward = multiplier
            .mul(rewardPerSecond)
            .mul(myPool.allocPoint)
            .div(totalAllocPoint);
        myPool.accRewardTokenPerShare = myPool.accRewardTokenPerShare.add(
            tokenReward.mul(1e30).div(totalStaked)
        );
        myPool.lastRewardTimestamp = block.timestamp;
    }

    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Nothing to deposit");
        UserInfo storage user = userInfo[msg.sender];
        uint256 finalDepositAmount = 0;
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(myPool.accRewardTokenPerShare)
                .div(1e30)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 currentRewardBalance = rewardBalance();
                if (currentRewardBalance > 0) {
                    if (pending > currentRewardBalance) {
                        safeTransferReward(
                            address(msg.sender),
                            currentRewardBalance
                        );
                    } else {
                        safeTransferReward(address(msg.sender), pending);
                    }
                }
            }
        }
        if (_amount > 0) {
             uint256 preStakeBalance = totalStakeTokenBalance();
                myPool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            finalDepositAmount = totalStakeTokenBalance().sub(preStakeBalance);
            super._mint(msg.sender, finalDepositAmount);
            user.amount = user.amount.add(finalDepositAmount);
            user.lastDeposit = block.timestamp;
            totalStaked = totalStaked.add(finalDepositAmount);
            addHighestStaker(msg.sender, user.amount);
        }
        user.rewardDebt = user.amount.mul(myPool.accRewardTokenPerShare).div(
            1e30
        );
        emit Deposit(msg.sender, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) public whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user
            .amount
            .mul(myPool.accRewardTokenPerShare)
            .div(1e30)
            .sub(user.rewardDebt);
        if (pending > 0) {
            uint256 currentRewardBalance = rewardBalance();
            if (currentRewardBalance > 0) {
                if (pending > currentRewardBalance) {
                    safeTransferReward(
                        address(msg.sender),
                        currentRewardBalance
                    );
                } else {
                    safeTransferReward(
                        address(msg.sender), 
                        pending
                    );
                }
            }
        }
        if (_amount > 0) {
            uint256 amountDurationfees;
            uint256 amountLiquidityfees;
            if (user.lastDeposit.add(feesDuration) > block.timestamp){
                amountDurationfees = (user.amount.add(pending)).mul(withdrawFeesBeforeDuration).div(100);
            }
            amountLiquidityfees = (user.amount.add(pending)).mul(liquidityFees).div(100);
            super._burn(msg.sender, user.amount);
            removeHighestStaker(msg.sender);
            myPool.lpToken.approve(address(msg.sender), user.amount.sub(amountDurationfees).sub(amountLiquidityfees));
            myPool.lpToken.approve(liquidityWallet,amountLiquidityfees.add(amountDurationfees));
            myPool.lpToken.safeTransfer(liquidityWallet, amountLiquidityfees.add(amountDurationfees));
            myPool.lpToken.safeTransfer(address(msg.sender), user.amount.sub(amountDurationfees).sub(amountLiquidityfees));
            totalStaked = totalStaked.sub(user.amount);
            user.amount = user.amount.sub(user.amount);
            user.rewardDebt = user.amount.mul(myPool.accRewardTokenPerShare).div(
                1e30
            );
            emit Withdraw(msg.sender, _amount);
        }
        else {
            user.rewardDebt = user.amount.mul(myPool.accRewardTokenPerShare).div(
                1e30
            );
            emit Claim(msg.sender, pending);
        }        
    }


    function addHighestStaker(address _user, uint256 _amount) internal {
        HighestStaker[] storage arr = HighestStakerInPool;
        for(uint i;i<arr.length;i++){
            if (arr[i].wallet == _user){
                arr[i].amountStaked = _amount;
                quickSort(0, arr.length - 1);
                return;
            }
        }
        if (arr.length < topStakerAmount) {
            arr.push(HighestStaker(_user, _amount));
        }
        else {
            if (arr[0].amountStaked < _amount) {
                arr[0].amountStaked = _amount;
                arr[0].wallet = _user;
            }
        }
        quickSort(0, arr.length - 1);
    }

    function removeHighestStaker(address _user) internal {
        HighestStaker[] storage arr = HighestStakerInPool;
        for (uint i;i<arr.length;i++){
            if (arr[i].wallet == _user){
                arr[i] = arr[arr.length - 1];
                arr.pop();
            }
        }
        quickSort(0, arr.length-1);
    }

    function isHighestStaker(address user) public view returns (bool) {
        HighestStaker[] storage arr = HighestStakerInPool;
        uint256 i = 0;
        for (i; i < arr.length; i++) {
            if (arr[i].wallet == user) {
                return true;
            }
        }
        return false;
    }

    function lastHighestStaker() public view returns (uint256) {
        return HighestStakerInPool[0].amountStaked;
    }

    /// Obtain the reward balance of this contract
    /// @return wei balace of conract
    function rewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount) external {
        require(_amount > 0, "Deposit value must be greater than 0.");
        rewardToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit DepositRewards(_amount);
    }

    /// @param _to address to send reward token to
    /// @param _amount value of reward token to transfer
    function safeTransferReward(address _to, uint256 _amount) internal {
        rewardToken.safeTransfer(_to, _amount);
    }

    /* Admin Functions */
    /// @param _rewardPerSecond The amount of reward tokens to be given per block
    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        rewardPerSecond = _rewardPerSecond;
    }

    /// @param  _bonusEndTimestamp The block when rewards will end
    function setBonusEndTimestamp(uint256 _bonusEndTimestamp)
        external
        onlyOwner
    {
        // new bonus end block must be greater than current
        bonusEndTimestamp = _bonusEndTimestamp;
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return totalStakeTokenBalance().sub(totalStaked);
    }

    function getStartTimestamp() public view returns (uint256) {
        return startTimestamp;
    }

    function getEndTimestamp() public view returns (uint256) {
        return bonusEndTimestamp;
    }

    /// @dev Obtain the stake balance of this contract
    /// @return wei balace of contract
    function totalStakeTokenBalance() public view returns (uint256) {
        // Return BEO20 balance
        return stakeToken.balanceOf(address(this));
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();
        stakeToken.safeTransfer(msg.sender, stakeTokenFeeBalance);
        emit SkimStakeTokenFees(msg.sender, stakeTokenFeeBalance);
    }

    /* Emergency Functions */
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _account) external nonReentrant{
        UserInfo storage user = userInfo[_account];
        totalStaked = totalStaked.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        myPool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(_account, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardBalance(), "not enough rewards");
        // Withdraw rewards
        safeTransferReward(address(msg.sender), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    function emergencyRewardWithdrawTotal() external onlyOwner {
        uint256 _amount = rewardBalance();
        // Withdraw rewards
        safeTransferReward(address(msg.sender), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }
    
    function setFeesDuration(uint256 delay) external onlyOwner {
        feesDuration = delay;
    }

    function setWithdrawDurationFees(uint256 fees) external onlyOwner {
        withdrawFeesBeforeDuration = fees;
    }

    function setLiquidityFees(uint256 fees) external onlyOwner {
        liquidityFees = fees;
    }

    
    function quickSort(uint256 left, uint256 right) internal{
        uint256 i = left;
        uint256 j = right;
        HighestStaker[] storage arr = HighestStakerInPool;
        if(i==j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].amountStaked;
        while (i <= j) {
            while (arr[uint256(i)].amountStaked < pivot) i++;
            while (pivot < arr[uint256(j)].amountStaked) j--;
            if (i <= j) {
                (arr[uint256(i)].wallet, arr[uint256(j)].wallet) = (arr[uint256(j)].wallet, arr[uint256(i)].wallet);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(left, j);
        if (i < right)
            quickSort(i, right);
    }

    function setTopStakerAmount(uint256 amount) external onlyOwner {
        topStakerAmount = amount;
    }
}