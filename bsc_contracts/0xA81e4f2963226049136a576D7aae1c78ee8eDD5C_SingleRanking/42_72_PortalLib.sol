// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RewardVault} from "src/RewardVault.sol";

library PortalLib {
    uint256 public constant PERSHARE_BASE = 10e18;
    // percentage base of refer reward fees
    uint256 public constant PERCENTAGE_BASE = 10000;

    enum RewardType {
        NativeToken,
        RebornToken
    }

    struct ReferrerRewardFees {
        uint16 incarnateRef1Fee;
        uint16 incarnateRef2Fee;
        uint16 vaultRef1Fee;
        uint16 vaultRef2Fee;
        uint192 _slotPlaceholder;
    }

    struct Pool {
        uint256 totalAmount;
        uint256 accRebornPerShare;
        uint256 accNativePerShare;
        uint256 epoch;
        uint256 lastUpdated;
    }

    struct Portfolio {
        uint256 accumulativeAmount;
        uint256 rebornRewardDebt;
        uint256 nativeRewardDebt;
        //
        // We do some fancy math here. Basically, any point in time, the amount
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (Amount * pool.accPerShare) - user.rewardDebt
        //
        // Whenever a user infuse or switchPool. Here's what happens:
        //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        /// @dev reward for holding the NFT when the NFT is selected
        uint256 pendingOwnerRebornReward;
        uint256 pendingOwnerNativeReward;
    }

    struct AirdropConf {
        uint8 _dropOn; //                  ---
        uint40 _rebornDropInterval; //        |
        uint40 _nativeDropInterval; //        |
        uint40 _rebornDropLastUpdate; //      |
        uint40 _nativeDropLastUpdate; //      |
        uint16 _nativeTopDropRatio; //        |
        uint16 _nativeRaffleDropRatio; //   |
        uint16 _rebornTopEthAmount; // |
        uint40 _rebornRaffleEthAmount; //    ---
    }

    struct VrfConf {
        bytes32 keyHash;
        uint64 s_subscriptionId;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
    }

    event DropNative(uint256 indexed tokenId);
    event DropReborn(uint256 indexed tokenId);
    event ClaimRebornDrop(uint256 indexed tokenId, uint256 rebornAmount);
    event ClaimNativeDrop(uint256 indexed tokenId, uint256 nativeAmount);
    event NewDropConf(AirdropConf conf);
    event NewVrfConf(VrfConf conf);
    event SignerUpdate(address signer, bool valid);
    event ReferReward(
        address indexed user,
        address indexed ref1,
        uint256 amount1,
        address indexed ref2,
        uint256 amount2,
        RewardType rewardType
    );

    function _claimPoolRebornDrop(
        uint256 tokenId,
        RewardVault vault,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeReborn;
        // if no portfolio, no pending tribute reward
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeReborn = 0;
        } else {
            pendingTributeReborn =
                ((portfolio.accumulativeAmount * pool.accRebornPerShare) /
                    PERSHARE_BASE) -
                portfolio.rebornRewardDebt;
        }

        uint256 pendingReborn = pendingTributeReborn +
            portfolio.pendingOwnerRebornReward;

        // set current amount as debt
        portfolio.rebornRewardDebt =
            (portfolio.accumulativeAmount * pool.accRebornPerShare) /
            PERSHARE_BASE;

        // clean up reward as owner
        portfolio.pendingOwnerRebornReward = 0;

        /// @dev send drop
        if (pendingReborn > 0) {
            vault.reward(msg.sender, pendingReborn);
            emit ClaimRebornDrop(tokenId, pendingReborn);
        }
    }

    function _claimPoolNativeDrop(
        uint256 tokenId,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeNative;
        // if no portfolio, no pending tribute reward
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeNative = 0;
        } else {
            pendingTributeNative =
                (portfolio.accumulativeAmount * pool.accNativePerShare) /
                PERSHARE_BASE -
                portfolio.nativeRewardDebt;
        }

        uint256 pendingNative = pendingTributeNative +
            portfolio.pendingOwnerNativeReward;

        // set current amount as debt
        portfolio.nativeRewardDebt =
            (portfolio.accumulativeAmount * pool.accNativePerShare) /
            PERSHARE_BASE;

        // clean up reward as owner
        portfolio.pendingOwnerNativeReward = 0;

        /// @dev send drop
        if (pendingNative > 0) {
            payable(msg.sender).transfer(pendingNative);

            emit ClaimNativeDrop(tokenId, pendingNative);
        }
    }

    function _flattenRewardDebt(
        Pool storage pool,
        Portfolio storage portfolio
    ) external {
        // flatten native reward
        portfolio.nativeRewardDebt =
            (portfolio.accumulativeAmount * pool.accNativePerShare) /
            PERSHARE_BASE;

        // flatten reborn reward
        portfolio.rebornRewardDebt =
            (portfolio.accumulativeAmount * pool.accRebornPerShare) /
            PERSHARE_BASE;
    }

    /**
     * @dev calculate drop from a pool
     */
    function _calculatePoolDrop(
        uint256 tokenId,
        IRebornDefination.SeasonData storage _seasonData
    ) public view returns (uint256 pendingNative, uint256 pendingReborn) {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeNative;
        uint256 pendingTributeReborn;
        // if no portfolio, no pending tribute reward
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeNative = 0;
            pendingTributeReborn = 0;
        } else {
            pendingTributeNative =
                (portfolio.accumulativeAmount * pool.accNativePerShare) /
                PERSHARE_BASE -
                portfolio.nativeRewardDebt;

            pendingTributeReborn =
                ((portfolio.accumulativeAmount * pool.accRebornPerShare) /
                    PERSHARE_BASE) -
                portfolio.rebornRewardDebt;
        }

        pendingNative =
            pendingTributeNative +
            portfolio.pendingOwnerNativeReward;

        pendingReborn =
            pendingTributeReborn +
            portfolio.pendingOwnerRebornReward;
    }

    /**
     * @dev read pending reward from specific pool
     * @param tokenIds tokenId array of the pools
     */
    function _pendingDrop(
        IRebornDefination.SeasonData storage _seasonData,
        uint256[] memory tokenIds
    ) external view returns (uint256 pNative, uint256 pReborn) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 n, uint256 r) = _calculatePoolDrop(
                tokenIds[i],
                _seasonData
            );
            pNative += n;
            pReborn += r;
        }
    }

    function _directDropNativeToTopTokenIds(
        uint256[] memory tokenIds,
        AirdropConf storage _dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        uint256 dropAmount = (_dropConf._nativeTopDropRatio *
            _seasonData._jackpot) / PERCENTAGE_BASE;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // if tokenId is zero , return
            if (tokenId == 0) {
                return;
            }

            Pool storage pool = _seasonData.pools[tokenId];

            // if no one tribute, return
            // as it's loof from high tvl to low tvl
            if (pool.totalAmount == 0) {
                return;
            }

            // 80% to pool
            pool.accNativePerShare +=
                (4 * dropAmount * PERSHARE_BASE) /
                (5 * pool.totalAmount);

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];
            portfolio.pendingOwnerNativeReward += (dropAmount * 1) / 5;

            emit DropNative(tokenId);
        }
    }

    function _directDropNativeToRaffleTokenIds(
        uint256[] memory tokenIds,
        AirdropConf storage _dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        uint256 dropAmount = (_dropConf._nativeRaffleDropRatio *
            _seasonData._jackpot) / PERCENTAGE_BASE;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // if tokenId is zero , return
            if (tokenId == 0) {
                return;
            }

            Pool storage pool = _seasonData.pools[tokenId];

            // if no one tribute, return
            // as it's loof from high tvl to low tvl
            if (pool.totalAmount == 0) {
                return;
            }

            // 80% to pool
            pool.accNativePerShare +=
                (4 * dropAmount * PERSHARE_BASE) /
                (5 * pool.totalAmount);

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];
            portfolio.pendingOwnerNativeReward += (dropAmount * 1) / 5;

            emit DropNative(tokenId);
        }
    }

    function _directDropRebornToTopTokenIds(
        uint256[] memory tokenIds,
        AirdropConf storage _dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        uint256 dropAmount = uint256(_dropConf._rebornTopEthAmount) * 1 ether;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // if tokenId is zero, continue
            if (tokenId == 0) {
                return;
            }
            Pool storage pool = _seasonData.pools[tokenId];

            // if no one tribute, continue
            // as it's loof from high tvl to low tvl
            if (pool.totalAmount == 0) {
                return;
            }

            // 80% to pool
            pool.accRebornPerShare +=
                (dropAmount * 4 * PortalLib.PERSHARE_BASE) /
                (5 * pool.totalAmount);

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];
            portfolio.pendingOwnerRebornReward += (dropAmount * 1) / 5;

            emit DropReborn(tokenId);
        }
    }

    function _directDropRebornToRaffleTokenIds(
        uint256[] memory tokenIds,
        AirdropConf storage _dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        uint256 dropAmount = uint256(_dropConf._rebornRaffleEthAmount) *
            1 ether;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // if tokenId is zero, continue
            if (tokenId == 0) {
                return;
            }
            Pool storage pool = _seasonData.pools[tokenId];

            // if no one tribute, continue
            // as it's loof from high tvl to low tvl
            if (pool.totalAmount == 0) {
                return;
            }

            // 80% to pool
            pool.accRebornPerShare +=
                (dropAmount * 4 * PortalLib.PERSHARE_BASE) /
                (5 * pool.totalAmount);

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];
            portfolio.pendingOwnerRebornReward += (dropAmount * 1) / 5;

            emit DropReborn(tokenId);
        }
    }

    function _toLastHour(uint256 timestamp) internal pure returns (uint256) {
        return timestamp - (timestamp % (1 hours));
    }

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function _updateSigners(
        mapping(address => bool) storage signers,
        address[] calldata toAdd,
        address[] calldata toRemove
    ) public {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], false);
        }
    }

    /**
     * @dev returns referrer and referer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function _calculateReferReward(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        address account,
        uint256 amount,
        RewardType rewardType,
        uint256 extraReward
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        ref1 = referrals[account];
        ref2 = referrals[ref1];

        if (rewardType == RewardType.NativeToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef2Fee) / PERCENTAGE_BASE;
        }

        if (rewardType == RewardType.RebornToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : extraReward +
                    (amount * rewardFees.vaultRef1Fee) /
                    PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef2Fee) / PERCENTAGE_BASE;
        }
    }

    /**
     * @notice mul 10000 when set. eg: 8% -> 800 18%-> 1800
     * @dev set percentage of referrer reward
     * @param rewardType 0: incarnate reward 1: engrave reward
     */
    function _setReferrerRewardFee(
        ReferrerRewardFees storage rewardFees,
        uint16 refL1Fee,
        uint16 refL2Fee,
        RewardType rewardType
    ) external {
        if (rewardType == RewardType.NativeToken) {
            rewardFees.incarnateRef1Fee = refL1Fee;
            rewardFees.incarnateRef2Fee = refL2Fee;
        } else if (rewardType == RewardType.RebornToken) {
            rewardFees.vaultRef1Fee = refL1Fee;
            rewardFees.vaultRef2Fee = refL2Fee;
        }
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        address account,
        uint256 amount
    ) public returns (uint256 total) {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.NativeToken,
                0
            );

        if (ref1Reward > 0) {
            payable(ref1).transfer(ref1Reward);
        }

        if (ref2Reward > 0) {
            payable(ref2).transfer(ref2Reward);
        }

        total = ref1Reward + ref2Reward;

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.NativeToken
        );
    }

    /**
     * @dev vault $REBORN token to referrers
     */
    function _vaultRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        RewardVault vault,
        address account,
        uint256 amount,
        uint256 extraReward
    ) public {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.RebornToken,
                extraReward
            );

        if (ref1Reward > 0) {
            vault.reward(ref1, ref1Reward);
        }

        if (ref2Reward > 0) {
            vault.reward(ref2, ref2Reward);
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.RebornToken
        );
    }
}