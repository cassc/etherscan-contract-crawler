// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvex.sol";
import "../../interfaces/convex/IConvexToken.sol";

// Convex Strategies common variables and helper functions
abstract contract ConvexBase {
    using SafeERC20 for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    IConvex public constant BOOSTER = IConvex(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    Rewards public immutable cvxCrvRewards;
    uint256 public immutable convexPoolId;

    struct ClaimableRewardInfo {
        address token;
        uint256 amount;
    }

    constructor(uint256 convexPoolId_) {
        (, , , address _reward, , ) = BOOSTER.poolInfo(convexPoolId_);
        cvxCrvRewards = Rewards(_reward);
        convexPoolId = convexPoolId_;
    }

    /**
     * @notice Add reward tokens
     * The Convex pools have CRV and CVX as base rewards and may have others tokens as extra rewards
     * In some cases, CVX is also added as extra reward, reason why we have to ensure to not add it twice
     * @return _rewardTokens The array of reward tokens (both base and extra rewards)
     */
    function _getRewardTokens() internal view returns (address[] memory _rewardTokens) {
        uint256 _extraRewardCount;
        uint256 _length = cvxCrvRewards.extraRewardsLength();

        for (uint256 i; i < _length; ++i) {
            address _rewardToken = Rewards(cvxCrvRewards.extraRewards(i)).rewardToken();
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (_rewardToken != CRV && _rewardToken != CVX) {
                _extraRewardCount++;
            }
        }

        _rewardTokens = new address[](_extraRewardCount + 2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        uint256 _nextIdx = 2;

        for (uint256 i; i < _length; ++i) {
            address _rewardToken = Rewards(cvxCrvRewards.extraRewards(i)).rewardToken();
            // CRV and CVX already added in array
            if (_rewardToken != CRV && _rewardToken != CVX) {
                _rewardTokens[_nextIdx++] = _rewardToken;
            }
        }
    }
}