// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVEALSD.sol";
import "./interfaces/IALSD.sol";

import "./lib/CurrencyTransferLib.sol";
import "./StakingPool.sol";
import "./EthStakingPool.sol";

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

/*
 * The StakingPoolFactory enables the creation and management of staking pools for various LST tokens.
 * Staking pools allow users to stake their tokens and earn rewards. The factory contract keeps
 * track of the deployed staking pools and their associated information.
 *
 * The factory contract has functions to deploy new staking pools, specify the staking token,
 * start time, and duration. Pools mainly accept LST tokens or WETH as the staking token.
 * The rewards for staking are distributed in the form of a separate ERC20 token specified by the
 * rewardsToken variable (here veALSD).
 *
 * The contract also includes functions to withdraw rewards from a staking pool and add more rewards
 * to a pool. When rewards are added, the factory mints incentive liquidity tokens, approves their
 * conversion into a different ERC20 token, and transfers the converted rewards to the staking pool.
 */

contract StakingPoolFactory is Ownable {
    using SafeMath for uint256;

    address public immutable rewardsToken;
    address public immutable nativeTokenWrapper;

    address[] private stakingTokens;

    mapping(address => StakingPoolInfo) private stakingPoolInfoByStakingToken;

    event StakingPoolDeployed(
        address indexed poolAddress,
        address indexed stakingToken,
        uint256 startTime
    );

    struct StakingPoolInfo {
        address poolAddress;
        uint256 startTime;
        uint256 roundDurationInDays;
        uint256 totalRewardsAmount;
    }

    IALSD public immutable alsdContract;
    IVEALSD public immutable vealsdContract;

    constructor(
        address _veAlsdToken,
        address _nativeTokenWrapper,
        address _alsdToken
    ) Ownable() {
        rewardsToken = _veAlsdToken;
        vealsdContract = IVEALSD(_veAlsdToken);
        nativeTokenWrapper = _nativeTokenWrapper;
        alsdContract = IALSD(_alsdToken);
    }

    function getStakingPoolAddress(
        address stakingToken
    ) external view virtual returns (address) {
        StakingPoolInfo storage info = stakingPoolInfoByStakingToken[
            stakingToken
        ];
        return info.poolAddress;
    }

    function deployPool(
        address stakingToken,
        uint256 startTime,
        uint256 durationInDays
    ) external onlyOwner {
        require(
            stakingPoolInfoByStakingToken[stakingToken].poolAddress ==
                address(0),
            "Pool already exists for staking token"
        );

        StakingPoolInfo storage info = stakingPoolInfoByStakingToken[
            stakingToken
        ];

        if (stakingToken == CurrencyTransferLib.NATIVE_TOKEN) {
            info.poolAddress = address(
                new EthStakingPool(
                    address(this),
                    rewardsToken,
                    nativeTokenWrapper,
                    durationInDays,
                    msg.sender
                )
            );
        } else {
            info.poolAddress = address(
                new StakingPool(
                    address(this),
                    rewardsToken,
                    stakingToken,
                    durationInDays,
                    msg.sender
                )
            );
        }
        info.startTime = startTime;
        info.roundDurationInDays = durationInDays;
        info.totalRewardsAmount = 0;

        stakingTokens.push(stakingToken);
        emit StakingPoolDeployed(info.poolAddress, stakingToken, startTime);
    }

    function withdrawExcess(
        address stakingToken,
        address to
    ) external onlyOwner {
        StakingPoolInfo storage info = stakingPoolInfoByStakingToken[
            stakingToken
        ];
        require(block.timestamp >= info.startTime, "Not started");

        StakingPool(payable(address(info.poolAddress))).withdrawExcess(to);
    }

    function addRewards(
        address stakingToken,
        uint256 rewardsAmount
    ) public onlyOwner {
        StakingPoolInfo storage info = stakingPoolInfoByStakingToken[
            stakingToken
        ];
        require(block.timestamp >= info.startTime, "Not started");

        if (rewardsAmount > 0) {
            info.totalRewardsAmount = info.totalRewardsAmount.add(
                rewardsAmount
            );

            require(
                alsdContract.mintIncentiveLiquidity(rewardsAmount),
                "Mint liquidity failed"
            );
            require(
                alsdContract.approve(address(vealsdContract), rewardsAmount),
                "Approve failed"
            );
            require(vealsdContract.convert(rewardsAmount), "Convert failed");
            require(
                IERC20(rewardsToken).transfer(info.poolAddress, rewardsAmount),
                "Transfer failed"
            );
            StakingPool(payable(address(info.poolAddress))).notifyRewardAmount(
                rewardsAmount
            );
        }
    }
}