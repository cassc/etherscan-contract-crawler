// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "../../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvex.sol";
import "../../interfaces/convex/IConvexToken.sol";

// Convex Strategies common variables and helper functions
abstract contract ConvexStrategyBase {
    using SafeERC20 for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public immutable cvxCrvRewards;
    uint256 public immutable convexPoolId;
    bool public isClaimRewards;
    uint256 internal constant SUSHISWAP_ROUTER_INDEX = 1;

    struct ClaimableRewardInfo {
        address token;
        uint256 amount;
    }

    constructor(address _crvLp, uint256 _convexPoolId) {
        (address _lp, , , address _reward, , ) = IConvex(BOOSTER).poolInfo(_convexPoolId);
        require(_lp == address(_crvLp), "incorrect-lp-token");
        cvxCrvRewards = _reward;
        convexPoolId = _convexPoolId;
    }

    function _getRewardTokens() internal view returns (address[] memory) {
        uint256 extraRewardCount;
        for (uint256 i = 0; i < Rewards(cvxCrvRewards).extraRewardsLength(); i++) {
            Rewards rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (rewardContract.rewardToken() != CRV && rewardContract.rewardToken() != CVX) {
                extraRewardCount++;
            }
        }
        address[] memory _rewardTokens = new address[](extraRewardCount + 2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        uint256 index = 2;
        for (uint256 i = 0; i < Rewards(cvxCrvRewards).extraRewardsLength(); i++) {
            Rewards rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            // CRV and CVX already added in array
            if (rewardContract.rewardToken() != CRV && rewardContract.rewardToken() != CVX) {
                _rewardTokens[index] = rewardContract.rewardToken();
                index++;
            }
        }
        return _rewardTokens;
    }

    /// @dev Returns a list of (token, amount) for all rewards claimable in a Convex Pool
    function _claimableRewards() internal view returns (ClaimableRewardInfo[] memory) {
        uint256 _extraRewardCount = Rewards(cvxCrvRewards).extraRewardsLength();
        ClaimableRewardInfo[] memory _claimableRewardsInfo = new ClaimableRewardInfo[](_extraRewardCount + 2);
        uint256 _baseReward = Rewards(cvxCrvRewards).earned(address(this));

        // CVX rewards are minted proportionally to baseReward (CRV)
        uint256 _cvxReward = _calculateCVXRewards(_baseReward);
        _claimableRewardsInfo[0] = ClaimableRewardInfo(CRV, _baseReward);
        _claimableRewardsInfo[1] = ClaimableRewardInfo(CVX, _cvxReward);

        // Don't care if there are additional CRV, or CVX in extraRewards
        // total amount will be summed together in claimableRewardsInCollateral()
        for (uint256 i = 0; i < _extraRewardCount; i++) {
            Rewards _rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            _claimableRewardsInfo[2 + i] = ClaimableRewardInfo(
                _rewardContract.rewardToken(),
                _rewardContract.earned(address(this))
            );
        }
        return _claimableRewardsInfo;
    }

    // TODO: review this again.  There may be substitute
    function _calculateCVXRewards(uint256 _claimableCrvRewards) internal view returns (uint256 _total) {
        // CVX Rewards are minted based on CRV rewards claimed upon withdraw
        // This will calculate the CVX amount based on CRV rewards accrued
        // without having to claim CRV rewards first
        // ref 1: https://github.com/convex-eth/platform/blob/main/contracts/contracts/Cvx.sol#L61-L76
        // ref 2: https://github.com/convex-eth/platform/blob/main/contracts/contracts/Booster.sol#L458-L466

        uint256 _reductionPerCliff = IConvexToken(CVX).reductionPerCliff();
        uint256 _totalSupply = IConvexToken(CVX).totalSupply();
        uint256 _maxSupply = IConvexToken(CVX).maxSupply();
        uint256 _cliff = _totalSupply / _reductionPerCliff;
        uint256 _totalCliffs = 1000;

        if (_cliff < _totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 _reduction = _totalCliffs - _cliff;
            //reduce
            _total = (_claimableCrvRewards * _reduction) / _totalCliffs;

            //supply cap check
            uint256 _amtTillMax = _maxSupply - _totalSupply;
            if (_total > _amtTillMax) {
                _total = _amtTillMax;
            }
        }
    }
}