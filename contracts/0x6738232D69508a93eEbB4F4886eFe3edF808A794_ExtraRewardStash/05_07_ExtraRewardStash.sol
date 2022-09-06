// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";

/// @title ExtraRewardStash
contract ExtraRewardStash is IStash {
    using SafeERC20 for IERC20;
    using MathUtil for uint256;

    error Unauthorized();
    error AlreadyInitialized();

    event RewardHookSet(address newRewardHook);
    event ExtraRewardsCleared();
    event ExtraRewardCleared(address extraReward);

    uint256 private constant MAX_REWARDS = 8;
    address public immutable bal;

    uint256 public pid;
    address public operator;
    address public gauge;
    address public rewardFactory;
    address public rewardHook; // address to call for reward pulls
    bool public hasBalRewards;

    mapping(address => uint256) public historicalRewards;

    struct TokenInfo {
        address token;
        address rewardAddress;
    }

    // use mapping + array so that we dont have to loop check each time setToken is called
    mapping(address => TokenInfo) public tokenInfo;
    address[] public tokenList;

    constructor(address _bal) {
        bal = _bal;
    }

    function initialize(
        uint256 _pid,
        address _operator,
        address _gauge,
        address _rFactory
    ) external {
        if (gauge != address(0)) {
            revert AlreadyInitialized();
        }
        pid = _pid;
        operator = _operator;
        gauge = _gauge;
        rewardFactory = _rFactory;
    }

    modifier onlyAddress(address authorizedAddress) {
        if (msg.sender != authorizedAddress) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Returns the length of the tokenList
    function tokenCount() external view returns (uint256) {
        return tokenList.length;
    }

    /// @notice Claims registered reward tokens
    function claimRewards() external onlyAddress(operator) {
        // this is updateable from v2 gauges now so must check each time.
        checkForNewRewardTokens();

        if (hasBalRewards) {
            // claim rewards on gauge for staker
            // using reward_receiver so all rewards will be moved to this stash
            IController(operator).claimRewards(pid, gauge);
        }

        // hook for reward pulls
        if (rewardHook != address(0)) {
            // solhint-disable-next-line
            try IRewardHook(rewardHook).onRewardClaim() {} catch {}
        }
    }

    /// @notice Clears extra rewards
    /// @dev Only Prime multising has the ability to do this
    /// if you want to remove only one token, use `clearExtraReward`
    function clearExtraRewards() external onlyAddress(IController(operator).owner()) {
        address[] memory tokenListMemory = tokenList;

        for (uint256 i = 0; i < tokenListMemory.length; i = i.unsafeInc()) {
            delete tokenInfo[tokenListMemory[i]];
        }

        delete tokenList;
        emit ExtraRewardsCleared();
    }

    /// @notice Clears extra reward by index
    /// @param index index of the extra reward to clear
    function clearExtraReward(uint256 index) external onlyAddress(IController(operator).owner()) {
        address extraReward = tokenList[index];
        // Move the last element into the place to delete
        tokenList[index] = tokenList[tokenList.length - 1];
        // Remove the last element
        tokenList.pop();
        delete tokenInfo[extraReward];
        emit ExtraRewardCleared(extraReward);
    }

    /// @notice Checks if the gauge rewards have changed
    function checkForNewRewardTokens() internal {
        for (uint256 i = 0; i < MAX_REWARDS; i = i.unsafeInc()) {
            address token = IBalGauge(gauge).reward_tokens(i);
            if (token == address(0)) {
                break;
            }
            if (!hasBalRewards) {
                hasBalRewards = true;
            }
            setToken(token);
        }
    }

    /// @notice Registers an extra reward token to be handled
    /// @param _token The reward token address
    /// @dev Used for any new incentive that is not directly on balancer gauges
    function setExtraReward(address _token) external onlyAddress(IController(operator).owner()) {
        setToken(_token);
    }

    /// @notice Sets the reward hook address
    /// @param _hook The address of the reward hook
    function setRewardHook(address _hook) external onlyAddress(IController(operator).owner()) {
        rewardHook = _hook;
        emit RewardHookSet(_hook);
    }

    /// @notice Replaces a token on the token list
    /// @param _token The address of the token
    function setToken(address _token) internal {
        TokenInfo storage t = tokenInfo[_token];

        if (t.token == address(0)) {
            //set token address
            t.token = _token;

            //check if BAL
            if (_token != bal) {
                //create new reward contract (for NON-BAL tokens only)
                (, , , address mainRewardContract, , ) = IController(operator).poolInfo(pid);
                address rewardContract = IRewardFactory(rewardFactory).createTokenRewards(
                    _token,
                    mainRewardContract,
                    address(this)
                );

                t.rewardAddress = rewardContract;
            }
            //add token to list of known rewards
            tokenList.push(_token);
        }
    }

    /// @notice Sends all of the extra rewards to the reward contracts
    function processStash() external onlyAddress(operator) {
        uint256 tCount = tokenList.length;
        for (uint256 i = 0; i < tCount; i++) {
            TokenInfo storage t = tokenInfo[tokenList[i]];
            address token = t.token;
            if (token == address(0)) continue;

            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                historicalRewards[token] = historicalRewards[token] + amount;
                if (token == bal) {
                    //if BAL, send back to booster to distribute
                    IERC20(token).safeTransfer(operator, amount);
                    continue;
                }
                //add to reward contract
                address rewards = t.rewardAddress;
                IERC20(token).safeTransfer(rewards, amount);
                IRewards(rewards).queueNewRewards(amount);
            }
        }
    }
}