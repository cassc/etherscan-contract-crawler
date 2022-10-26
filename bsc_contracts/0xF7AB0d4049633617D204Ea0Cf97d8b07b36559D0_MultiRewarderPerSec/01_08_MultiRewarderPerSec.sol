// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IMultiRewarder.sol';

/**
 * This is a sample contract to be used in the Master contract for partners to reward
 * stakers with their native token alongside WOM.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the WOM-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * - This contract has no knowledge on the LP amount and Master is
 *   responsible to pass the amount into this contract
 * - Supports multiple reward tokens
 */
contract MultiRewarderPerSec is IMultiRewarder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant ACC_TOKEN_PRECISION = 1e12;
    IERC20 public immutable lpToken;
    address public immutable master;

    struct UserInfo {
        uint128 amount; // 20.18 fixed point.
        // if the pool is activated, rewardDebt should be > 0
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        uint256 unpaidRewards; // 20.18 fixed point.
    }

    /// @notice Info of each rewardInfo.
    struct RewardInfo {
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
    }

    /// @notice address of the operator
    /// @dev operator is able to set emission rate
    address public operator;

    uint256 public lastRewardTimestamp;

    /// @notice Info of the rewardInfo.
    RewardInfo[] public rewardInfo;
    /// @notice tokenId => userId => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);

    modifier onlyMaster() {
        require(msg.sender == address(master), 'onlyMaster: only Master can call this function');
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner() || msg.sender == operator, 'onlyOperatorOrOwner');
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    constructor(
        address _master,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_master)), 'constructor: Master must be a valid contract');
        require(_startTimestamp >= block.timestamp);

        master = _master;
        lpToken = _lpToken;

        lastRewardTimestamp = _startTimestamp;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18
        });
        rewardInfo.push(reward);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @notice Set operator address
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function addRewardToken(IERC20 _rewardToken, uint96 _tokenPerSec) external onlyOwner {
        _updateReward();
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18
        });
        rewardInfo.push(reward);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    function updateReward() public {
        _updateReward();
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updateReward() internal {
        _updateReward(_getTotalShare());
    }

    function _updateReward(uint256 totalShare) internal {
        if (block.timestamp > lastRewardTimestamp && totalShare > 0) {
            uint256 length = rewardInfo.length;
            for (uint256 i; i < length; ++i) {
                RewardInfo storage reward = rewardInfo[i];
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * reward.tokenPerSec;
                reward.accTokenPerShare += toUint128((tokenReward * ACC_TOKEN_PRECISION) / totalShare);
            }
            lastRewardTimestamp = block.timestamp;
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the rewardInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updateReward();

        uint256 oldRate = rewardInfo[_tokenId].tokenPerSec;
        rewardInfo[_tokenId].tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(address(rewardInfo[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by Master whenever staker claims WOM harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume `_getTotalShare` isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The new amount of LP
    function onReward(address _user, uint256 _lpAmount)
        external
        virtual
        override
        onlyMaster
        nonReentrant
        returns (uint256[] memory rewards)
    {
        _updateReward();
        return _onReward(_user, _lpAmount);
    }

    function _onReward(address _user, uint256 _lpAmount) internal virtual returns (uint256[] memory rewards) {
        uint256 length = rewardInfo.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo storage reward = rewardInfo[i];
            UserInfo storage user = userInfo[i][_user];
            IERC20 rewardToken = reward.rewardToken;

            if (user.rewardDebt > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should distribute rewards
                uint256 pending = ((user.amount * uint256(reward.accTokenPerShare)) / ACC_TOKEN_PRECISION) +
                    user.unpaidRewards -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        // Note: this line may fail if the receiver is a contract and refuse to receive BNB
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        user.unpaidRewards = pending - tokenBalance;
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        user.unpaidRewards = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.unpaidRewards = pending - tokenBalance;
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        user.unpaidRewards = 0;
                    }
                }
            }

            user.amount = toUint128(_lpAmount);
            user.rewardDebt = toUint128((_lpAmount * reward.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
    }

    /// @notice returns reward length
    function rewardLength() external view virtual returns (uint256) {
        return _rewardLength();
    }

    function _rewardLength() internal view returns (uint256) {
        return rewardInfo.length;
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return rewards reward for a given user.
    function pendingTokens(address _user) external view virtual returns (uint256[] memory rewards) {
        return _pendingTokens(_user);
    }

    function _pendingTokens(address _user) internal view returns (uint256[] memory rewards) {
        uint256 length = rewardInfo.length;
        rewards = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo memory pool = rewardInfo[i];
            UserInfo storage user = userInfo[i][_user];

            uint256 accTokenPerShare = pool.accTokenPerShare;
            uint256 totalShare = _getTotalShare();

            if (block.timestamp > lastRewardTimestamp && totalShare > 0) {
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                accTokenPerShare += (tokenReward * ACC_TOKEN_PRECISION) / totalShare;
            }

            rewards[i] =
                ((user.amount * uint256(accTokenPerShare)) / ACC_TOKEN_PRECISION) -
                user.rewardDebt +
                user.unpaidRewards;
        }
    }

    function _getTotalShare() internal view virtual returns (uint256) {
        return lpToken.balanceOf(address(master));
    }

    /// @notice return an array of reward tokens
    function _rewardTokens() internal view returns (IERC20[] memory tokens) {
        uint256 length = rewardInfo.length;
        tokens = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo memory pool = rewardInfo[i];
            tokens[i] = pool.rewardToken;
        }
    }

    function rewardTokens() external view virtual returns (IERC20[] memory tokens) {
        return _rewardTokens();
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() external onlyOwner {
        uint256 length = rewardInfo.length;

        for (uint256 i; i < length; ++i) {
            RewardInfo storage pool = rewardInfo[i];
            emergencyTokenWithdraw(address(pool.rewardToken));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice View function to see balances of reward token.
    function balances() external view returns (uint256[] memory balances_) {
        uint256 length = rewardInfo.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo storage pool = rewardInfo[i];
            if (address(pool.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = pool.rewardToken.balanceOf(address(this));
            }
        }
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }
}