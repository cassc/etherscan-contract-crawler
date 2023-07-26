pragma solidity ^0.8.10;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { Initializable } from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import { IBalancerVault } from "./interfaces/IBalancerVault.sol";

import { FixedPoint } from "./utils/FixedPoint.sol";
import { IBooster } from "./interfaces/IBooster.sol";
import { IBaseRewardPool } from "./interfaces/IBaseRewardPool.sol";
import { MultiPoolStrategy as IMultiPoolStrategy } from "./MultiPoolStrategy.sol";

contract AuraAdapterBase is Initializable {
    using FixedPoint for uint256;

    /// @notice Balancer pool id.
    bytes32 public poolId;
    /// @notice The address of the Balancer vault.
    IBalancerVault public vault;
    /// @notice The address of the Aura reward pool.
    IBaseRewardPool public auraRewardPool;
    /// @notice The address of the underlying token.
    IERC20 public underlyingToken;
    /// @notice The address of the Balancer pool.
    address public pool;
    /// @dev The index of the underlying token in the Balancer pool.
    uint256 tokenIndex;
    /// @dev PID of the pool in the Aura booster.
    uint256 auraPid;
    /// @notice Addresses of the reward tokens
    address[] public rewardTokens;
    /// @notice The address of the MultiPoolStrategy contract.
    address public multiPoolStrategy;
    uint256 public storedUnderlyingBalance;
    uint256 public healthFactor;
    //// CONSTANTS
    address public constant AURA_BOOSTER = 0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

    struct RewardData {
        address token;
        uint256 amount;
    }

    error Unauthorized();
    error InvalidHealthFactor();

    modifier onlyMultiPoolStrategy() {
        if (msg.sender != multiPoolStrategy) revert Unauthorized();
        _;
    }
    /**
     * @notice Initialize the contract.
     * @param _poolId Balancer Pool Id
     * @param _multiPoolStrategy Address of the MultiPoolStrategy contract
     * @param _auraPid PID of the pool in the Aura booster
     */

    function initialize(bytes32 _poolId, address _multiPoolStrategy, uint256 _auraPid) public initializer {
        poolId = _poolId;
        multiPoolStrategy = _multiPoolStrategy;
        underlyingToken = IERC20(IMultiPoolStrategy(_multiPoolStrategy).asset());
        vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        (address[] memory tokens,,) = vault.getPoolTokens(poolId);
        (pool,) = vault.getPool(poolId);
        auraPid = _auraPid;
        (,,, address _auraRewardPool,,) = IBooster(AURA_BOOSTER).poolInfo(_auraPid);
        auraRewardPool = IBaseRewardPool(_auraRewardPool);
        healthFactor = 200; // 2%
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(underlyingToken)) {
                tokenIndex = i;
                break;
            }
        }
        uint256 extraRewardsLength = auraRewardPool.extraRewardsLength();
        underlyingToken.approve(address(vault), type(uint256).max);
        IERC20(pool).approve(address(AURA_BOOSTER), type(uint256).max);
        if (extraRewardsLength > 0) {
            for (uint256 i = 0; i < extraRewardsLength; i++) {
                rewardTokens.push(IBaseRewardPool(auraRewardPool.extraRewards(i)).rewardToken());
            }
        }
    }

    function deposit(uint256 _amount, uint256 _minBalancerLpAmount) external virtual onlyMultiPoolStrategy {
        (address[] memory tokens,,) = vault.getPoolTokens(poolId);
        uint256[] memory maxAmountsIn = new uint256[](tokens.length);
        maxAmountsIn[tokenIndex] = _amount;
        IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
            tokens, maxAmountsIn, abi.encode(1, maxAmountsIn, _minBalancerLpAmount), false
        );
        vault.joinPool(poolId, address(this), address(this), pr);
        uint256 lpBal = IERC20(pool).balanceOf(address(this));
        IBooster(AURA_BOOSTER).deposit(auraPid, lpBal, true);
        storedUnderlyingBalance = underlyingBalance();
    }

    function withdraw(uint256 _amount, uint256 _minReceiveAmount) external virtual onlyMultiPoolStrategy {
        uint256 _underlyingBalance = underlyingBalance();
        (address[] memory tokens,,) = vault.getPoolTokens(poolId);
        uint256[] memory minAmountsOut = new uint256[](tokens.length);
        minAmountsOut[tokenIndex] = _minReceiveAmount;
        auraRewardPool.withdrawAndUnwrap(_amount, false);
        IBalancerVault.ExitPoolRequest memory pr =
            IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, abi.encode(0, _amount, tokenIndex), false);
        vault.exitPool(poolId, address(this), address(this), pr);
        uint256 underlyingBal = IERC20(underlyingToken).balanceOf(address(this));
        IERC20(underlyingToken).transfer(multiPoolStrategy, underlyingBal);
        uint256 healthyBalance = storedUnderlyingBalance - (storedUnderlyingBalance * healthFactor / 10_000);
        if (_underlyingBalance > healthyBalance) {
            storedUnderlyingBalance = _underlyingBalance - underlyingBal;
        } else {
            storedUnderlyingBalance -= underlyingBal;
        }
    }

    function underlyingBalance() public view virtual returns (uint256) { }

    function claim() external onlyMultiPoolStrategy {
        auraRewardPool.getReward(address(this), true);
        uint256 balBalance = IERC20(BAL).balanceOf(address(this));
        if (balBalance > 0) {
            IERC20(BAL).transfer(multiPoolStrategy, balBalance);
        }
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; i++) {
            uint256 rewardTokenBal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (rewardTokenBal > 0) {
                IERC20(rewardTokens[i]).transfer(multiPoolStrategy, rewardTokenBal);
            }
        }
    }

    function lpBalance() external view returns (uint256 lpBal) {
        lpBal = auraRewardPool.balanceOf(address(this));
    }

    function totalClaimable() external view returns (RewardData[] memory) {
        uint256 rewardTokensLength = rewardTokens.length;
        RewardData[] memory rewards = new RewardData[](rewardTokensLength + 1);
        rewards[0] = RewardData({ token: BAL, amount: auraRewardPool.earned(address(this)) });
        if (rewardTokensLength > 0) {
            for (uint256 i; i < rewardTokensLength; i++) {
                rewards[i + 1] = RewardData({
                    token: rewardTokens[i],
                    amount: IBaseRewardPool(auraRewardPool.extraRewards(i)).earned(address(this))
                });
            }
        }
        return rewards;
    }

    function isHealthy() external view returns (bool) {
        uint256 underlyingBal = underlyingBalance();
        uint256 healthThreshold = storedUnderlyingBalance - (storedUnderlyingBalance * healthFactor / 10_000);
        return underlyingBal >= healthThreshold;
    }

    function setHealthFactor(uint256 _newHealthFactor) external onlyMultiPoolStrategy {
        if (_newHealthFactor > 10_000) {
            revert InvalidHealthFactor();
        }
        healthFactor = _newHealthFactor;
    }
}