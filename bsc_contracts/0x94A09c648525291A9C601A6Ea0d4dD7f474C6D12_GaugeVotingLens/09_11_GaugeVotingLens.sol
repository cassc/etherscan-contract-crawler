// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./GaugeVoting.sol";
import "./WombexLensUI.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./GaugeVotingLens.sol";

/**
 * @title   GaugeVotingLens
 * @author  WombexFinance
 */
contract GaugeVotingLens {
    GaugeVoting public gaugeVoting;
    address public wmx;
    IERC20 public veWom;
    address public stakingToken;
    address public voterProxy;
    IBribeVoter public bribeVoter;
    WombexLensUI public wombexLensUI;

    struct Pool {
        address lpToken;
        address rewards;
        WombexLensUI.RewardItem[] userRewardItems;
        PoolVotes votes;
        bool isActive;
        string name;
        string symbol;
        uint128 rewardsApr;
        uint128 rewardsAprItem;
        uint128 bribeApr;
        uint128 bribeAprItem;
    }

    struct PoolVotes {
        uint128 vlVotes;
        int128 vlDelta;
        int128 veWomVotes;
        int128 veWomDelta;
    }

    struct UserReward {
        address lpToken;
        address rewards;
        address rewardToken;
        uint8 decimals;
        uint256 rewardAmount;
        uint256 usdAmount;
    }

    constructor(GaugeVoting _gaugeVoting, WombexLensUI _wombexLensUI) {
        gaugeVoting = _gaugeVoting;
        wmx = _wombexLensUI.WMX_TOKEN();
        stakingToken = address(_gaugeVoting.stakingToken());
        veWom = _gaugeVoting.veWom();
        voterProxy = _gaugeVoting.voterProxy();
        bribeVoter = _gaugeVoting.bribeVoter();
        wombexLensUI = _wombexLensUI;
    }

    function getPools(address _userAddress) public returns (Pool[] memory pools) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        (int256[] memory deltas, int256[] memory votes) = gaugeVoting.getVotesDelta();
        if (deltas.length == 0) {
            deltas = new int256[](lpTokens.length);
            votes = new int256[](lpTokens.length);
        }
        pools = new Pool[](lpTokens.length);
        uint256 stakingTokenPrice = wombexLensUI.estimateInBUSD(wmx, 1 ether, 18);
        uint256 stakingTotalSupply = IERC20(stakingToken).totalSupply();
        uint256 veWomBalance = veWom.balanceOf(voterProxy);
        for (uint256 i = 0; i < lpTokens.length; i++) {
            pools[i].rewards = gaugeVoting.lpTokenRewards(lpTokens[i]);
            pools[i].userRewardItems = wombexLensUI.getUserPendingRewards(0, pools[i].rewards, _userAddress);
            uint256 vlVotes = IERC20(pools[i].rewards).totalSupply();
            if (vlVotes == 0) {
                vlVotes = 1 ether;
            }
            if (votes[i] != 0) {
                int256 ratio = int256(vlVotes) * int256(1 ether) / votes[i];
                pools[i].votes = PoolVotes(
                    uint128(vlVotes),
                    int128(deltas[i] * ratio / int256(1 ether)),
                    int128(votes[i]),
                    int128(deltas[i])
                );
            }
            uint256 tvl = (stakingTokenPrice * vlVotes) / 1 ether;
            (pools[i].rewardsAprItem, pools[i].rewardsApr) = wombexLensUI.getRewardPoolTotalApr128(IBaseRewardPool4626(pools[i].rewards), tvl, 0, 0);
            (pools[i].bribeAprItem, pools[i].bribeApr) = wombexLensUI.getBribeTotalApr128(voterProxy, bribeVoter, lpTokens[i], tvl, (stakingTotalSupply * stakingTokenPrice) / 1 ether, veWomBalance);

            pools[i].lpToken = lpTokens[i];
            pools[i].isActive = isLpActive(lpTokens[i]);
            pools[i].name = ERC20(lpTokens[i]).name();
            pools[i].symbol = ERC20(lpTokens[i]).symbol();
        }
    }

    function isLpActive(address _lpToken) public view returns(bool) {
        return gaugeVoting.lpTokenStatus(_lpToken) == GaugeVoting.LpTokenStatus.ACTIVE;
    }

    function getUserVotes(address _user) public view returns (uint256[] memory votes) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        votes = new uint256[](lpTokens.length);
        for(uint256 i = 0; i < lpTokens.length; i++) {
            votes[i] = IERC20(gaugeVoting.lpTokenRewards(lpTokens[i])).balanceOf(_user);
        }
    }

    function getUserRewards(address _user, uint256 _rewardsPerLpToken) public returns (UserReward[] memory rewards) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        rewards = new UserReward[](lpTokens.length * _rewardsPerLpToken);
        uint256 rIndex = 0;

        for (uint256 j = 0; j < lpTokens.length; j++) {
            address rewardPool = gaugeVoting.lpTokenRewards(lpTokens[j]);
            uint256 rewardPoolBalance = IBribeRewardsPool(rewardPool).balanceOf(_user);

            address[] memory bribeRewardTokens = IBribeRewardsPool(rewardPool).rewardTokensList();
            for (uint256 i = 0; i < bribeRewardTokens.length; i++) {
                bool added = false;
                if (rewardPoolBalance == 0) {
                    for (uint256 k = 0; k < rIndex; k++) {
                        if (rewards[k].rewardToken == bribeRewardTokens[i]) {
                            added = true;
                            break;
                        }
                    }
                }
                if (added) {
                    continue;
                }
                uint8 decimals = wombexLensUI.getTokenDecimals(bribeRewardTokens[i]);
                uint256 earned = rewardPoolBalance == 0 ? 0 : IBribeRewardsPool(rewardPool).earned(bribeRewardTokens[i], _user);
                rewards[rIndex] = UserReward(
                    lpTokens[j],
                    rewardPool,
                    bribeRewardTokens[i],
                    decimals,
                    earned,
                    earned == 0 ? earned : wombexLensUI.estimateInBUSDEther(bribeRewardTokens[i], earned, decimals)
                );
                rIndex++;
            }
        }
    }

    function getTotalRewards(uint256 _rewardsPerLpToken) public returns (UserReward[] memory rewards) {
        address[] memory lpTokens = gaugeVoting.getLpTokensAdded();
        rewards = new UserReward[](lpTokens.length * _rewardsPerLpToken);
        uint256 rIndex = 0;

        for (uint256 i = 0; i < lpTokens.length; i++) {
            address rewardPool = gaugeVoting.lpTokenRewards(lpTokens[i]);
            address[] memory bribeRewardTokens = IBribeRewardsPool(rewardPool).rewardTokensList();
            for (uint256 j = 0; j < bribeRewardTokens.length; j++) {
                (, , , , , uint256 queuedRewards, , uint256 historicalRewards, ) = IBribeRewardsPool(rewardPool).tokenRewards(bribeRewardTokens[j]);
                uint8 decimals = wombexLensUI.getTokenDecimals(bribeRewardTokens[i]);
                uint256 amount = queuedRewards + historicalRewards;

                rewards[rIndex] = UserReward(
                    lpTokens[i],
                    rewardPool,
                    bribeRewardTokens[j],
                    decimals,
                    amount,
                    wombexLensUI.estimateInBUSDEther(bribeRewardTokens[i], amount, decimals)
                );
                rIndex++;
            }
        }
    }
}