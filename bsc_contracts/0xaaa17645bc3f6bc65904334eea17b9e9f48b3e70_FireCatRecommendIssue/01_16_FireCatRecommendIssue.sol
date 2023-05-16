// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FireCatAccessControl} from "../src/utils/FireCatAccessControl.sol";
import {IFireCatRecommendIssue} from "../src/interfaces/IFireCatRecommendIssue.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";

/**
 * @title FireCat's Recommend Contract
 * @notice Add Recommend to this contract
 * @author FireCat Finance
 */
contract FireCatRecommendIssue is IFireCatRecommendIssue, FireCatTransfer, ModifyControl {
    using SafeMath for uint256;

    event TopUp(address user_, uint256 amount_, uint256 totalSupplyNew_);
    event AddReward(address user_, uint256 amount_, uint256 totalReward_);
    event WithdrawReward(address user_, uint256 amount_, uint256 totalReward_);
    event Claimed(address user_, uint256 actualClaimedAmount_, uint256 totalClaimedNew_);
    
    address public rewardToken;
    uint256 public totalReward;
    uint256 public totalClaimed;

    uint256 private _totalSupply;
    mapping(address => uint256) private _userReward;
    mapping(address => uint256) private _userClaimed;

    function initialize(address token) initializer public {
        rewardToken = token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);   
        _setupRole(DATA_ADMIN, msg.sender);   
        _setupRole(SAFE_ADMIN, msg.sender);   
    }

    /// @inheritdoc IFireCatRecommendIssue
    function rewardOf(address user) public view returns (uint256) {
        return _userReward[user];
    }

    /// @inheritdoc IFireCatRecommendIssue
    function claimedOf(address user) public view returns (uint256) {
        return _userClaimed[user];
    }

    function topUp(uint256 addAmount) external onlyRole(SAFE_ADMIN) returns (uint256) {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= addAmount, "POOL:E02");

        uint256 actualAddAmount = doTransferIn(rewardToken, msg.sender, addAmount);
        // totalReservesNew + actualAddAmount
        uint256 totalSupplyNew = _totalSupply.add(actualAddAmount);

        /* Revert on overflow */
        require(totalSupplyNew > _totalSupply, "POOL:E03");

        _totalSupply = totalSupplyNew;
        emit TopUp(msg.sender, actualAddAmount, totalSupplyNew);
        return actualAddAmount;
    }

    /// @inheritdoc IFireCatRecommendIssue
    function addReward(address user, uint256 addAmount) external onlyRole(FIRECAT_GATE) returns (uint256) {
        uint totalRewardNew;

        // totalRewardNew + addAmount
        totalRewardNew = totalReward.add(addAmount);

        /* Revert on overflow */
        require(totalRewardNew >= totalReward, "RES:E02");

        totalReward = totalRewardNew;
        _userReward[user] = _userReward[user].add(addAmount);

        emit AddReward(user, addAmount, totalRewardNew);
        return addAmount;
    }

    /// @inheritdoc IFireCatRecommendIssue
    function withdrawReward(uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint) {
        require(amount <= totalReward, "RES:E01");
        uint totalRewardNew;
        uint actualSubAmount;

        actualSubAmount = doTransferOut(rewardToken, msg.sender, amount);
        // totalReward - actualSubAmount
        totalRewardNew = totalReward.sub(actualSubAmount);

        /* Revert on overflow */
        require(totalRewardNew <= totalReward, "RES:E03");
        totalReward = totalRewardNew;
        
        emit WithdrawReward(msg.sender, actualSubAmount, totalRewardNew);
        return actualSubAmount;
    }

    /// @inheritdoc IFireCatRecommendIssue
    function withdrawRemaining(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint) {
        require(token != rewardToken, "RES:E04");
        return withdraw(token, to, amount);
    }

    /// @inheritdoc IFireCatRecommendIssue
    function claim() external beforeClaim nonReentrant returns (uint256) {
        require(_userReward[msg.sender] > 0, "ARD:E04");
        require(IERC20(rewardToken).balanceOf(address(this)) >= _userReward[msg.sender], "ARD:E02");

        uint256 actualClaimedAmount = doTransferOut(rewardToken, msg.sender, _userReward[msg.sender]);
        _userClaimed[msg.sender] = _userClaimed[msg.sender].add(actualClaimedAmount);
        _userReward[msg.sender] = _userReward[msg.sender].sub(actualClaimedAmount);

        totalClaimed = totalClaimed.add(actualClaimedAmount);
        emit Claimed(msg.sender, actualClaimedAmount, totalClaimed);
        return actualClaimedAmount;
    }

}