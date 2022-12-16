// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IAdminAccess.sol";


/// @title  SimpleRewardPool
/// @notice SimpleRewardPool for fixed APR staking
contract SimpleRewardPool {
    /// @notice sherpa global permission role
    IAdminAccess public access;
    event RewardPaid(address indexed user, uint256 reward);
    using SafeERC20 for IERC20;
    IERC20 public rewardToken;
    address public operator;
    constructor(
        address reward_,
        address operator_,
        address accessControl_
    ) {
        rewardToken = IERC20(reward_);
        operator = operator_;
        access= IAdminAccess(accessControl_);
    }
    modifier onlyOperator() {
        require(operator==msg.sender, "!auth");
        _;
    }
    modifier onlyOwner() {
        require(access.getOwner() == msg.sender, "!O");
        _;
    }
    /// @notice claimRewards
    /// @dev claim reward called by operator staking pool
    /// @param _account, user stake address
    /// @param _reward, user unclaimed reward
    /// @param _feeAddress, address to receive fee
    /// @param _commissionPercentage, commission fee from user reward,the range should be [0,10000],1728 means 17.28%
    /// @return Returns success.
    function claimRewards(address _account,uint256 _reward,address _feeAddress,uint256 _commissionPercentage) public onlyOperator returns(bool){
        if (_reward>0){
            require(rewardToken.balanceOf(address(this))>=_reward,"!B");
            uint256 commissionFee=_reward*_commissionPercentage/uint256(10000);
            uint256 transferReward=_reward-commissionFee;
            if (transferReward>0){
                rewardToken.safeTransfer(_account, transferReward);
            }
            if (commissionFee>0){
                rewardToken.safeTransfer(_feeAddress, commissionFee);
            }
            emit RewardPaid(_account, transferReward);
        }
        return true;
    }
    /// @notice withdrawERC20Token
    /// @param token, address of ERC20
    /// @param amount, withdraw amount of ERC20
    function withdrawERC20Token(address token,uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

}