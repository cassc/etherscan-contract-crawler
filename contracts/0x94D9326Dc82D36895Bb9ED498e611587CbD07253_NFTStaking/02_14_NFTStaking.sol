/**
 *
 * @title Pulselorian Non-Fungible Tokens (NFT) Staking
 * @author Faajari Trutt <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * Pulselorian NFTs are the coolest collection of Pulselorian head armor
 * These NFTs are stakable and generate LBSKR yield. LBSKR is the best crypto currency there is!!
 *
 * - Pulselorian NFT Staking audit
 *      <TODO Audit report link to be added here>
 *
 *
 *    (   (  (  (     (   (( (   .  (   (    (( (   ((
 *    )\  )\ )\ )\    )\ (\())\   . )\  )\   ))\)\  ))\
 *   ((_)((_)(_)(_)  ((_))(_)(_)   ((_)((_)(((_)_()((_)))
 *   | _ \ | | | |  / __| __| |   / _ \| _ \_ _|   \ \| |
 *   |  _/ |_| | |__\__ \ _|| |__| (_) |   /| || - | .  |
 *   |_|  \___/|____|___/___|____|\___/|_|_\___|_|_|_|\_|
 *
 * Tokenomics:
 *
 * LBSKR yield rewards: 1555 LBSKR per hour divided among all stakers proportionally
 *
 */

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "./imports/ILBSKR.sol";
import "./openzeppelin/access/OwnableUpgradeable.sol";
import "./openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "./openzeppelin/security/ReentrancyGuardUpgradeable.sol";
import "./openzeppelin/token/ERC721/IERC721Upgradeable.sol";

contract NFTStaking is
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct Stake {
        uint256 claimedRewards;
        uint256 rewards2Exclude;
        uint256 since;
        uint256 tokenID;
    }

    struct StakesMeta {
        Stake[] stakes;
        uint256 totalClaimedRewards;
        uint256 totalRewards2Exclude;
    }

    IERC721Upgradeable public nftCollection;
    ILBSKR public lbskrToken;
    address[] public stakersArray;
    bool public rewardsAccruing;
    mapping(address => StakesMeta) public stakeMap; // stakeholder address -> StakesMeta data
    mapping(uint256 => address) public tokenStakerMap; // token ID -> stakeholder address
    uint24 private constant _SECS_IN_FOUR_WEEKS = 2419200; // 3600 * 24 * 7 * 4
    uint256 private constant _WEI = 10**18;
    uint256 private constant _BUFFER_REWARDS = 0x3751D9497328E6E00000; // 7 days woth LBSKR rewards
    uint256 private constant _REWARDS_PER_HOUR = 0x544BF5C541C46C0000; // 1555 LBSKR in wei
    uint256 public accYieldPerTknWei; // _WEI precision
    uint256 public countOfStakes;
    uint256 public grossDueRewards; // TODO can be made private
    uint256 public lastUpdateTS;
    uint256 public rewardBalance; // reward balance as per periodic checks

    /**
     * @notice Initializes NFT Staking contract with first implementation version
     * @param nftCollectionA Growth address
     * @param lbskrTokenA LBSKR address
     */
    function __NFTStaking_init(address nftCollectionA, address lbskrTokenA)
        external
        initializer
    {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __NFTStaking_init_unchained(nftCollectionA, lbskrTokenA);
    }

    function __NFTStaking_init_unchained(
        address nftCollectionA,
        address lbskrTokenA
    ) internal onlyInitializing {
        nftCollection = IERC721Upgradeable(nftCollectionA);
        lbskrToken = ILBSKR(lbskrTokenA);
        rewardsAccruing = true;
        rewardBalance = 0xBBCD970FE2DDA08C00000;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and _REWARDS_PER_HOUR.
    function _calculateRewards(address stakerA)
        private
        view
        returns (uint256 rewards)
    {
        if (countOfStakes == 0 || lastUpdateTS == 0) {
            return 0;
        }

        StakesMeta memory stakesMeta = stakeMap[stakerA];
        uint256 nowTS = block.timestamp;
        uint256 tmpAccYieldPerTknWei;

        if (rewardsAccruing && (nowTS > lastUpdateTS)) {
            tmpAccYieldPerTknWei =
                accYieldPerTknWei +
                (((nowTS - lastUpdateTS) * _REWARDS_PER_HOUR * _WEI) /
                    countOfStakes /
                    3600);
        } else {
            tmpAccYieldPerTknWei = accYieldPerTknWei;
        }

        rewards =
            ((tmpAccYieldPerTknWei * stakesMeta.stakes.length) / _WEI) -
            stakesMeta.totalClaimedRewards -
            stakesMeta.totalRewards2Exclude;

        return rewards;
    }

    // Iterate thru all stakeholders and add the rewards since last update
    // Finally set the update timestamp to current time
    function _creditRewards() private {
        uint256 nowTS = block.timestamp;

        if (countOfStakes > 0 && rewardsAccruing && nowTS > lastUpdateTS) {
            uint256 newRewardsWeiPerTkn = (((nowTS - lastUpdateTS) *
                _REWARDS_PER_HOUR *
                _WEI) /
                countOfStakes /
                3600);

            accYieldPerTknWei += newRewardsWeiPerTkn;
            grossDueRewards += ((((newRewardsWeiPerTkn * countOfStakes) /
                _WEI) >> 1) << 1); // to reduce chances of underflow take rounding hit

            // The purpose of reward balance is for central check in the DAPP
            // DAPP would disable the stake button and display warning that rewards are depleting
            uint256 lbskrBal = lbskrToken.balanceOf(address(this));

            if (rewardBalance < lbskrBal) {
                rewardBalance = lbskrBal;
            }

            if (lbskrBal < (_BUFFER_REWARDS + grossDueRewards)) {
                rewardsAccruing = false;
            }
        }
        lastUpdateTS = nowTS;
    }

    function _penaltyFor(uint256 fromTimestamp, uint256 toTimestamp)
        private
        pure
        returns (uint256 penaltyBasis)
    {
        if (fromTimestamp + 52 weeks > toTimestamp) {
            uint256 fourWeeksElapsed = (toTimestamp - fromTimestamp) /
                _SECS_IN_FOUR_WEEKS;

            if (fourWeeksElapsed < 13) {
                penaltyBasis = ((13 - fourWeeksElapsed) * 100); // If one four weeks have elapsed - penalty is 12% or 1200/10000
            }
        }
        return penaltyBasis;
    }

    /**
     * @notice Lets the user claim his/her rewards
     */
    function claimRewards() external {
        _creditRewards();
        StakesMeta storage stakesMeta = stakeMap[_msgSender()];
        require(stakesMeta.stakes.length > 0, "N: No stakes");

        uint256 rewardsPen;
        uint256 rewards;
        uint256 nowTS = block.timestamp;
        for (uint256 j; j < stakesMeta.stakes.length; ++j) {
            uint256 eligibleBasis = 10000 -
                _penaltyFor(stakesMeta.stakes[j].since, nowTS);

            uint256 rwd = (accYieldPerTknWei / _WEI) -
                stakesMeta.stakes[j].rewards2Exclude -
                stakesMeta.stakes[j].claimedRewards;
            rewardsPen += (rwd * eligibleBasis) / 10000;
            rewards += rwd;
            stakesMeta.stakes[j].claimedRewards += rwd;
        }

        require(rewards > 0, "N: No rewards");

        uint256 lbskrBal = lbskrToken.balanceOf(address(this));
        rewardsPen = rewardsPen < lbskrBal ? rewardsPen : lbskrBal;
        if (lbskrBal > 0) {
            grossDueRewards -= ((rewards >> 1) << 1); // this may be inaccurate, if funds deplete unexpectedly

            stakeMap[_msgSender()].totalClaimedRewards += rewards;
            lbskrToken.transfer(_msgSender(), rewardsPen);
        }
    }

    /**
     * @notice Meant for manager to disable accruing when approaching depletion
     * DAPP could have this logic as well
     */
    function creditRewards() external {
        _creditRewards();
    }

    /**
     * @notice Calculates penalty amount for given stake if unstaked now
     * @param stakerA user address
     * @param stakeIndex Array index of the stake
     * @return penaltyBasis Basis points of applicable penalty
     */
    function penaltyIfUnstakedNow(address stakerA, uint256 stakeIndex)
        external
        view
        returns (uint256 penaltyBasis)
    {
        require(stakerA != address(0), "N: Invalid staker");
        StakesMeta memory staker = stakeMap[stakerA];

        require(stakeIndex < staker.stakes.length, "N: Invalid stake");
        return _penaltyFor(staker.stakes[stakeIndex].since, block.timestamp);
    }

    /**
     * @notice Stakes NFT after crediting rewards to all stakers
     * @param tokenIds List of token IDs to stake
     */
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        _creditRewards();
        if (stakeMap[_msgSender()].stakes.length > 0) {
            // do nothing
        } else {
            stakersArray.push(_msgSender());
        }

        uint256 nowTS = block.timestamp;
        stakeMap[_msgSender()].totalRewards2Exclude += ((accYieldPerTknWei /
            _WEI) * tokenIds.length); // we want to take rounding down to avoid underflow

        for (uint256 i; i < tokenIds.length; ++i) {
            require(
                nftCollection.ownerOf(tokenIds[i]) == _msgSender(),
                "N: Don't own!"
            );
            nftCollection.transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );
            tokenStakerMap[tokenIds[i]] = _msgSender();
            stakeMap[_msgSender()].stakes.push(
                Stake(0, (accYieldPerTknWei / _WEI), nowTS, tokenIds[i])
            );
            ++countOfStakes;
        }
    }

    /**
     * @notice Information about user's stakes
     * @param user user address
     * @return tokensStaked staked token balance
     * @return availableRewards available rewards balance
     * @return claimedRewards claimed rewards balance
     */
    function userStakeInfo(address user)
        external
        view
        returns (
            uint256 tokensStaked,
            uint256 availableRewards,
            uint256 claimedRewards
        )
    {
        return (
            stakeMap[user].stakes.length,
            _calculateRewards(user),
            stakeMap[user].totalClaimedRewards
        );
    }

    /**
     * @notice Get list of user staked tokens
     * @param user user address
     * @return tokenIds List of token IDs
     */
    function userStakedTokenIds(address user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](stakeMap[user].stakes.length);
        for (uint256 sIndex; sIndex < tokenIds.length; ++sIndex) {
            tokenIds[sIndex] = stakeMap[user].stakes[sIndex].tokenID;
        }
        return tokenIds;
    }

    /**
     * @notice Unstake function, user claims the rewards as he/she unstakes
     * @param tokenIds List of token IDs to unstake
     */
    function withdraw(uint256[] calldata tokenIds) external nonReentrant {
        _creditRewards();
        StakesMeta storage stakesMeta = stakeMap[_msgSender()];
        require(stakesMeta.stakes.length > 0, "N: No stakes");

        uint256 rewardsPen;
        uint256 rewards;
        uint256 nowTS = block.timestamp;
        for (uint256 i; i < tokenIds.length; ++i) {
            require(tokenStakerMap[tokenIds[i]] == _msgSender(), "N: Not ur stake");
            tokenStakerMap[tokenIds[i]] = address(0);
            nftCollection.transferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );

            for (uint256 j; j < stakesMeta.stakes.length; ++j) {
                if (stakesMeta.stakes[j].tokenID == tokenIds[i]) {
                    uint256 eligibleBasis = 10000 -
                        _penaltyFor(stakesMeta.stakes[j].since, nowTS);

                    uint256 rwd = (accYieldPerTknWei / _WEI) -
                        stakesMeta.stakes[j].rewards2Exclude -
                        stakesMeta.stakes[j].claimedRewards;
                    rewardsPen += (rwd * eligibleBasis) / 10000;
                    rewards += rwd;

                    stakesMeta.totalClaimedRewards -= stakesMeta
                        .stakes[j]
                        .claimedRewards;
                    stakesMeta.totalRewards2Exclude -= stakesMeta
                        .stakes[j]
                        .rewards2Exclude;

                    stakesMeta.stakes[j] = stakesMeta.stakes[
                        stakesMeta.stakes.length - 1
                    ];
                    stakesMeta.stakes.pop();
                    --countOfStakes;
                }
            }
        }

        if (rewards > 0) {
            // Additional check to ensure transfer does not fail and user gets balance rewards if shortage
            uint256 lbskrBal = lbskrToken.balanceOf(address(this));
            rewardsPen = rewardsPen < lbskrBal ? rewardsPen : lbskrBal;
            if (lbskrBal > 0) {
                grossDueRewards -= ((rewards >> 1) << 1); // this may be inaccurate, if funds deplete unexpectedly
                lbskrToken.transfer(_msgSender(), rewardsPen);
            }
        }

        if (stakeMap[_msgSender()].stakes.length == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == _msgSender()) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
    }

    /**
     * @notice Approximate estimate of when yield may deplete
     * @return timestamp Estimated timestamp when the vault may deplete
     */
    function yieldDepleteEstimate() external view returns (uint256 timestamp) {
        uint256 lbskrBal = lbskrToken.balanceOf(address(this));
        uint256 timeoutSecs = (lbskrBal * 3600) / _REWARDS_PER_HOUR;
        if (lastUpdateTS == 0) {
            return (block.timestamp + timeoutSecs);
        }
        return (lastUpdateTS + timeoutSecs);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}