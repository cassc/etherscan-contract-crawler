pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/AMO__IBaseRewardPool.sol";
import "./interfaces/AMO__IAuraBooster.sol";
import "./helpers/AMOCommon.sol";

contract AuraStaking is Ownable {
    using SafeERC20 for IERC20;

    address public operator;
    // @notice BPT tokens for balancer pool
    IERC20 public immutable bptToken;
    AuraPoolInfo public auraPoolInfo;
    // @notice Aura booster
    AMO__IAuraBooster public immutable booster;

    address public rewardsRecipient;
    address[] public rewardTokens;

    struct AuraPoolInfo {
        address token;
        address rewards;
        uint32 pId;
    }

    struct Position {
        uint256 staked;
        uint256 earned;
    }

    error NotOperator();
    error NotOperatorOrOwner();

    event SetAuraPoolInfo(uint32 indexed pId, address token, address rewards);
    event SetOperator(address operator);
    event RecoveredToken(address token, address to, uint256 amount);
    event SetRewardsRecipient(address recipient);

    constructor(
        address _operator,
        IERC20 _bptToken,
        AMO__IAuraBooster _booster,
        address[] memory _rewardTokens
    ) {
        operator = _operator;
        bptToken = _bptToken;
        booster = _booster;
        rewardTokens = _rewardTokens;
    }

    function setAuraPoolInfo(uint32 _pId, address _token, address _rewards) external onlyOwner {
        auraPoolInfo.pId = _pId;
        auraPoolInfo.token = _token;
        auraPoolInfo.rewards = _rewards;

        emit SetAuraPoolInfo(_pId, _token, _rewards);
    }

    /**
     * @notice Set operator
     * @param _operator New operator
     */
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;

        emit SetOperator(_operator);
    }

    function setRewardsRecipient(address _recipeint) external onlyOwner {
        rewardsRecipient = _recipeint;

        emit SetRewardsRecipient(_recipeint);
    }

    /**
     * @notice Recover any token from AMO
     * @param token Token to recover
     * @param to Recipient address
     * @param amount Amount to recover
     */
    function recoverToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);

        emit RecoveredToken(token, to, amount);
    }
    
    function depositAndStake(uint256 amount) external onlyOperator {
        bptToken.safeIncreaseAllowance(address(booster), amount);
        booster.deposit(auraPoolInfo.pId, amount, true);
    }

    // withdraw deposit token and unwrap to bpt tokens
    function withdrawAndUnwrap(uint256 amount, bool claim, address to) external onlyOperatorOrOwner {
        AMO__IBaseRewardPool(auraPoolInfo.rewards).withdrawAndUnwrap(amount, claim);
        if (to != address(0)) {
            // unwrapped amount is 1 to 1
            bptToken.safeTransfer(to, amount);
        }
    }

    function withdrawAllAndUnwrap(bool claim, bool sendToOperator) external onlyOwner {
        uint256 depositTokenBalance = AMO__IBaseRewardPool(auraPoolInfo.rewards).balanceOf(address(this));
        AMO__IBaseRewardPool(auraPoolInfo.rewards).withdrawAllAndUnwrap(claim);
        if (sendToOperator) {
            // unwrapped amount is 1 to 1
            bptToken.safeTransfer(operator, depositTokenBalance);
        }
    }

    function getReward(bool claimExtras) external {
        AMO__IBaseRewardPool(auraPoolInfo.rewards).getReward(address(this), claimExtras);
        if (rewardsRecipient != address(0)) {
            for (uint i=0; i<rewardTokens.length; i++) {
                uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));
                IERC20(rewardTokens[i]).safeTransfer(rewardsRecipient, balance);
            }
        }
    }

    function stakedBalance() public view returns (uint256 balance) {
        balance = AMO__IBaseRewardPool(auraPoolInfo.rewards).balanceOf(address(this));
    }

    function earned() public view returns (uint256 earnedRewards) {
        earnedRewards = AMO__IBaseRewardPool(auraPoolInfo.rewards).earned(address(this));
    }

    /**
     * @notice show staked position and earned rewards
     */
    function showPositions() external view returns (Position memory position){
        position.staked = stakedBalance();
        position.earned = earned();
    }

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    modifier onlyOperatorOrOwner() {
        if (msg.sender != operator && msg.sender != owner()) {
            revert NotOperatorOrOwner();
        }
        _;
    }
}