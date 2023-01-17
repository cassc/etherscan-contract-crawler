//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITresuary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Tresuary is ITresuary, Ownable { 
    using SafeMath for uint256;

    address public stakingContract;
    address public deployer;

    IERC20 public stakingToken;
    IERC20 public dividendToken;


    /// @notice Info of each user
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        /**
         * @notice We do some fancy math here. Basically, any point in time, the amount of stakingTokens
         * entitled to a user but is pending to be distributed is:
         *
         *   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt
         *
         * Whenever a user deposits or withdraws stakingToken. Here's what happens:
         *   1. accRewardPerShare (and `lastRewardBalance`) gets updated
         *   2. User receives the pending reward sent to his/her address
         *   3. User's `amount` gets updated
         *   4. User's `rewardDebt` gets updated
         */
    }

    /// @dev Internal balance of stakingToken, this gets updated on user deposits / withdrawals
    /// this allows to reward users with stakingToken
    uint256 public internalStakingTokenBalance;

    /// @notice Last reward balance 
    uint256 public lastRewardBalance;

    /// @notice Accumulated rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`
    uint256 public accRewardPerShare;

    /// @notice The precision of `accRewardPerShare`
    uint256 public ACC_REWARD_PER_SHARE_PRECISION;

    /// @dev Info of each user that stakes stakingToken
    mapping(address => UserInfo) private userInfo;


    event Deposit(address user, uint256 amount);
    event Withdrawal(address user, uint256 amount);
    event LogWithdrawalBNB(address account, uint256 amount);
    event LogWithdrawToken(address token, address account, uint256 amount);
    event LogUpdateDeployerAddress(address newDeployer);

    /// @notice Emitted when a user claims reward
    event ClaimReward(address indexed user, uint256 amount);


    /** 
     * @dev Throws if called by any account other than the owner or deployer.
     */
    modifier onlyDeployer() {
        require(deployer == _msgSender(), "Ownable: caller is not the deployer");
        _;
    }

    constructor(address _stakingContract, address _stakingToken, address _dividendToken){
        require(_stakingContract != address(0), "StakingContract Address 0 validation");
        require(_stakingToken != address(0), "StakingToken Address 0 validation");
        require(_dividendToken != address(0), "DividendToken Address 0 validation");
        deployer = _msgSender();
        stakingContract = _stakingContract;
        stakingToken = IERC20(_stakingToken);
        dividendToken = IERC20(_dividendToken);
        ACC_REWARD_PER_SHARE_PRECISION = 1e24;
        transferOwnership(_stakingContract);
    }

    function deposit(address staker, uint256 amount) external onlyOwner{
        require(stakingToken.allowance(staker, address(this)) >= amount, "Insufficient allowance.");
        UserInfo storage user = userInfo[staker];
        uint256 _previousAmount = user.amount;
        uint256 _newAmount = user.amount.add(amount);
        user.amount = _newAmount;

        updateReward();
        uint256 _previousRewardDebt = user.rewardDebt;
        user.rewardDebt = _newAmount.mul(accRewardPerShare).div(ACC_REWARD_PER_SHARE_PRECISION);
        if (_previousAmount != 0) {
            uint256 _pending = _previousAmount
                .mul(accRewardPerShare)
                .div(ACC_REWARD_PER_SHARE_PRECISION)
                .sub(_previousRewardDebt);
            if (_pending != 0) {
                safeTokenTransfer(staker, _pending);
                emit ClaimReward(staker, _pending);
            }
        }
        
        internalStakingTokenBalance = internalStakingTokenBalance.add(amount);
        stakingToken.transferFrom(staker, address(this), amount);
        emit Deposit(staker, amount);
    }

    /**
     * @notice Get user info
     * @param _user The address of the user
     * @return The amount of stakingToken user has deposited
     * @return The reward debt for the chosen token
     */
    function getUserInfo(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        return (user.amount, user.rewardDebt); 
    }


    /**
     * @notice View function to see pending reward token on frontend
     * @param _user The address of the user
     * @return `_user`'s pending reward token
     */
    function pendingReward(address _user) external view returns (uint256) {

        UserInfo storage user = userInfo[_user];
        uint256 _totalStakingToken = internalStakingTokenBalance;
        uint256 _accRewardTokenPerShare = accRewardPerShare;

        uint256 _currRewardBalance = dividendToken.balanceOf(address(this));
        uint256 _rewardBalance = _currRewardBalance;

        if (_rewardBalance != lastRewardBalance && _totalStakingToken != 0) {
            uint256 _accruedReward = _rewardBalance.sub(lastRewardBalance);
            _accRewardTokenPerShare = _accRewardTokenPerShare.add(
                _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(_totalStakingToken)
            );
        }
        return
            user.amount.mul(_accRewardTokenPerShare).div(ACC_REWARD_PER_SHARE_PRECISION).sub(user.rewardDebt);
    }

    function withdraw(address staker, uint256 amount) external onlyOwner{
        UserInfo storage user = userInfo[staker];
        uint256 _previousAmount = user.amount;
        require(_previousAmount >= amount, "Insufficient funds");
        uint256 _newAmount = user.amount.sub(amount);
        user.amount = _newAmount;

        if (_previousAmount != 0) { 
            updateReward();   
            uint256 _pending = _previousAmount
                .mul(accRewardPerShare)
                .div(ACC_REWARD_PER_SHARE_PRECISION)
                .sub(user.rewardDebt);
            user.rewardDebt = _newAmount.mul(accRewardPerShare).div(ACC_REWARD_PER_SHARE_PRECISION) ;  
            if (_pending != 0) {
                safeTokenTransfer(staker, _pending);
                emit ClaimReward(staker, _pending);
            }
        }
      

        internalStakingTokenBalance = internalStakingTokenBalance.sub(amount);
        stakingToken.transfer(staker, amount);
        emit Withdrawal(staker, amount);
    }

    function withdrawDividends() external {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount != 0) { 
            updateReward();   
            uint256 _pending = user.amount
                .mul(accRewardPerShare)
                .div(ACC_REWARD_PER_SHARE_PRECISION)
                .sub(user.rewardDebt);
            user.rewardDebt = user.amount.mul(accRewardPerShare).div(ACC_REWARD_PER_SHARE_PRECISION) ;  
            if (_pending != 0) {
                safeTokenTransfer(msg.sender, _pending);
                emit ClaimReward(msg.sender, _pending);
            }
        }
    }

    /**
     * @notice Update reward variables
     * @dev Needs to be called before any deposit or withdrawal
     */
    function updateReward() public {
        uint256 _totalStakingToken = internalStakingTokenBalance;

        uint256 _currRewardBalance = dividendToken.balanceOf(address(this));
        uint256 _rewardBalance = _currRewardBalance;
    

        // Did  tresuary receive any token
        if (_rewardBalance == lastRewardBalance || _totalStakingToken == 0) {
            return;
        }

        uint256 _accruedReward = _rewardBalance.sub(lastRewardBalance);

        accRewardPerShare = accRewardPerShare.add(
            _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(_totalStakingToken)
        );
        lastRewardBalance = _rewardBalance;
    }

    /**
     * @notice Safe token transfer function, just in case if rounding error
     * causes pool to not have enough reward tokens
     * @param _to The address that will receive `_amount` `rewardToken`
     * @param _amount The amount to send to `_to`
     */
    function safeTokenTransfer(
        address _to,
        uint256 _amount
    ) internal {
        uint256 _currRewardBalance = dividendToken.balanceOf(address(this));
        uint256 _rewardBalance = _currRewardBalance;

        if (_amount > _rewardBalance) {
            lastRewardBalance = lastRewardBalance.sub(_rewardBalance);
            dividendToken.transfer(_to, _rewardBalance);
        } else {
            lastRewardBalance = lastRewardBalance.sub(_amount);
            dividendToken.transfer(_to, _amount);
        }
    }

    function withdrawBNB(address payable account, uint256 amount) external onlyDeployer {
      require(amount <= (address(this)).balance, "Incufficient funds");
      safeTransferBNB(account, amount);
      emit LogWithdrawalBNB(account, amount);
    }

    // Internal function to handle safe transfer
    function safeTransferBNB(address to, uint256 value) internal {
       (bool success, ) = to.call{value: value}(new bytes(0));
       require(success);
    }

    /**
     * @notice Should not be withdrawn scam token.
     */
    function withdrawToken(address token, address account, uint256 amount) external onlyDeployer {
        require(amount <= IERC20(token).balanceOf(account), "Incufficient funds");
        require(token != address(dividendToken), "Can't withdraw dividendToken");
        require(token != address(stakingToken), "Can't withdraw stakingToken");
        require(IERC20(token).transfer(account, amount), "Transfer Fail");

        emit LogWithdrawToken(address(token), account, amount);
    }

    function updateDeployerAddress(address newDeployer) external onlyDeployer{
      require(deployer != newDeployer, "The address is already set");
      deployer = newDeployer;
      emit LogUpdateDeployerAddress(newDeployer);
    }
    
}