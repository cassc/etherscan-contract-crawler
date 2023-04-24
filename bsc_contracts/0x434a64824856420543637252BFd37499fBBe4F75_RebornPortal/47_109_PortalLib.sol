// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RewardVault} from "src/RewardVault.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

library PortalLib {
    uint256 public constant PERSHARE_BASE = 10e18;
    // percentage base of refer reward fees
    uint256 public constant PERCENTAGE_BASE = 10000;

    bytes32 public constant _SOUPPARAMS_TYPEHASH =
        keccak256(
            "AuthenticateSoupArg(address user,uint256 soupPrice,uint256 incarnateCounter,uint256 tokenId,uint256 deadline)"
        );

    bytes32 public constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    uint256 public constant ONE_HUNDRED = 100;

    struct CharacterParams {
        uint256 maxAP;
        uint256 restoreTimePerAP;
        uint256 level;
    }

    // TODO: use more compact storage
    struct CharacterProperty {
        uint8 currentAP;
        uint8 maxAP;
        uint24 restoreTimePerAP; // Time Needed to Restore One Action Point
        uint32 lastTimeAPUpdate;
        uint8 level;
    }

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
        uint128 droppedRebornTotal;
        uint128 droppedNativeTotal;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
        uint32 lastDropNativeTime;
        uint32 lastDropRebornTime;
        uint192 placeholder;
    }

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
    struct Portfolio {
        uint256 accumulativeAmount;
        uint128 rebornRewardDebt;
        uint128 nativeRewardDebt;
        /// @dev reward for holding the NFT when the NFT is selected
        uint128 pendingOwnerRebornReward;
        uint128 pendingOwnerNativeReward;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
    }

    struct AirdropConf {
        uint8 _dropOn; //                  ---
        bool _lockRequestDropReborn;
        bool _lockRequestDropNative;
        uint24 _rebornDropInterval; //        |
        uint24 _nativeDropInterval; //        |
        uint32 _rebornDropLastUpdate; //      |
        uint32 _nativeDropLastUpdate; //      |
        uint16 _nativeTopDropRatio; //        |
        uint16 _nativeRaffleDropRatio; //   |
        uint40 _rebornTopEthAmount; // |
        uint40 _rebornRaffleEthAmount; //    ---
        uint8 _placeholder;
    }

    struct VrfConf {
        bytes32 keyHash;
        uint64 s_subscriptionId;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
    }

    event DropNative(uint256 indexed tokenId, uint256 amount);
    event DropReborn(uint256 indexed tokenId, uint256 amount);
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
    event Refer(address referee, address referrer);

    function _claimPoolRebornDrop(
        uint256 tokenId,
        RewardVault vault,
        AirdropConf storage dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeReborn;
        (, uint256 userRebornCoinday) = _computeUserCoindayOfAirdropTimestamp(
            tokenId,
            msg.sender,
            dropConf,
            _seasonData
        );
        // if no coinday or tribute, no pending tribute reward
        // no tribute include no coinday
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeReborn = 0;
        } else {
            uint256 cumulativeRebornReward = (userRebornCoinday *
                pool.accRebornPerShare) / PERSHARE_BASE;
            // if cumulative reward is less than debt, return
            // if no more aidrop, coinday update would always larget than airdrop update
            // then no valid coiday for this pool
            if (cumulativeRebornReward < portfolio.rebornRewardDebt) {
                return;
            }
            pendingTributeReborn =
                cumulativeRebornReward -
                portfolio.rebornRewardDebt;

            // here, userRebornCoinday must larger than 0
            portfolio.rebornRewardDebt = uint128(cumulativeRebornReward);
        }

        uint256 pendingReborn = pendingTributeReborn +
            portfolio.pendingOwnerRebornReward;

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
        AirdropConf storage dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeNative;
        (uint256 userNativeCoinday, ) = _computeUserCoindayOfAirdropTimestamp(
            tokenId,
            msg.sender,
            dropConf,
            _seasonData
        );

        // if no coinday/tribute, no pending tribute reward
        // no tribute include no coinday
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeNative = 0;
        } else {
            uint256 cumulativeNativeReward = (userNativeCoinday *
                pool.accNativePerShare) / PERSHARE_BASE;
            // if cumulative reward is less than debt, return
            // if no more aidrop, coinday update would always larget than airdrop update
            // then no valid coiday for this pool
            if (cumulativeNativeReward < portfolio.nativeRewardDebt) {
                return;
            }
            pendingTributeNative =
                cumulativeNativeReward -
                portfolio.nativeRewardDebt;

            // set current amount as debt
            // here, userNativeCoinday must larger than zero
            portfolio.nativeRewardDebt = uint128(cumulativeNativeReward);
        }

        uint256 pendingNative = pendingTributeNative +
            portfolio.pendingOwnerNativeReward;

        // clean up reward as owner
        portfolio.pendingOwnerNativeReward = 0;

        /// @dev send drop
        if (pendingNative > 0) {
            payable(msg.sender).transfer(pendingNative);

            emit ClaimNativeDrop(tokenId, pendingNative);
        }
    }

    /**
     * @dev calculate drop from a pool
     */
    function _calculatePoolDrop(
        uint256 tokenId,
        IRebornDefination.SeasonData storage _seasonData,
        AirdropConf storage dropConf
    ) public view returns (uint256 pendingNative, uint256 pendingReborn) {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];

        uint256 pendingTributeNative;
        uint256 pendingTributeReborn;
        // if no accumulativeAmount, no pending tribute reward
        if (portfolio.accumulativeAmount == 0) {
            pendingTributeNative = 0;
            pendingTributeReborn = 0;
        } else {
            (
                uint256 userNativeCoinday,
                uint256 userRebornCoinday
            ) = _computeUserCoindayOfAirdropTimestamp(
                    tokenId,
                    msg.sender,
                    dropConf,
                    _seasonData
                );

            pendingTributeNative = userNativeCoinday > 0
                ? (userNativeCoinday * pool.accNativePerShare) /
                    PERSHARE_BASE -
                    portfolio.nativeRewardDebt
                : 0;

            pendingTributeReborn = userRebornCoinday > 0
                ? (userRebornCoinday * pool.accRebornPerShare) /
                    PERSHARE_BASE -
                    portfolio.rebornRewardDebt
                : 0;
        }

        pendingNative =
            pendingTributeNative +
            portfolio.pendingOwnerNativeReward;

        pendingReborn =
            pendingTributeReborn +
            portfolio.pendingOwnerRebornReward;
    }

    function _flattenRewardDebt(
        uint256 tokenId,
        address user,
        AirdropConf storage dropConf,
        IRebornDefination.SeasonData storage _seasonData
    ) public {
        Pool storage pool = _seasonData.pools[tokenId];
        Portfolio storage portfolio = _seasonData.portfolios[user][tokenId];

        (
            uint256 userNativeCoinday,
            uint256 userRebornCoinday
        ) = _computeUserCoindayOfAirdropTimestamp(
                tokenId,
                msg.sender,
                dropConf,
                _seasonData
            );

        unchecked {
            // flatten native reward
            portfolio.nativeRewardDebt = uint128(
                (userNativeCoinday * pool.accNativePerShare) / PERSHARE_BASE
            );

            // flatten reborn reward
            portfolio.rebornRewardDebt = uint128(
                (userRebornCoinday * pool.accRebornPerShare) / PERSHARE_BASE
            );
        }
    }

    /**
     * @dev read pending reward from specific pool
     * @param tokenIds tokenId array of the pools
     */
    function _pendingDrop(
        IRebornDefination.SeasonData storage _seasonData,
        uint256[] memory tokenIds,
        AirdropConf storage dropConf
    ) external view returns (uint256 pNative, uint256 pReborn) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 n, uint256 r) = _calculatePoolDrop(
                tokenIds[i],
                _seasonData,
                dropConf
            );
            pNative += n;
            pReborn += r;
        }
    }

    function _directDropNativeToTopTokenIds(
        uint256[] memory tokenIds,
        uint256 dropAmount,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            // if tokenId is zero, return
            // as there is no enough incarnation
            if (tokenId == 0) {
                return;
            }

            uint256 poolCoinday = getPoolCoinday(tokenId, _seasonData);
            // if no coin day, cointue and jump to next one
            if (poolCoinday == 0) {
                continue;
            }

            Pool storage pool = _seasonData.pools[tokenId];
            pool.lastDropNativeTime = uint32(block.timestamp);

            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];

            unchecked {
                // 80% to pool
                pool.droppedNativeTotal += (4 * uint128(dropAmount)) / 5;
                pool.accNativePerShare =
                    (pool.droppedNativeTotal * PERSHARE_BASE) /
                    poolCoinday;

                // 20% to owner

                portfolio.pendingOwnerNativeReward += uint128(
                    (dropAmount * 1) / 5
                );
            }

            emit DropNative(tokenId, dropAmount);

            // i auto increment
            unchecked {
                i++;
            }
        }
    }

    function _directDropNativeToRaffleTokenIds(
        uint256[] memory tokenIds,
        uint256 dropAmount,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // if it's empty, continue as it's raffle
            if (tokenId == 0) {
                continue;
            }

            uint256 poolCoinday = getPoolCoinday(tokenId, _seasonData);
            // if no coinday, continue and jump to next one
            if (poolCoinday == 0) {
                continue;
            }

            Pool storage pool = _seasonData.pools[tokenId];
            pool.lastDropNativeTime = uint32(block.timestamp);

            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];

            unchecked {
                // 80% to pool
                pool.droppedNativeTotal += (4 * uint128(dropAmount)) / 5;
                pool.accNativePerShare =
                    (pool.droppedNativeTotal * PERSHARE_BASE) /
                    poolCoinday;

                // 20% to owner
                portfolio.pendingOwnerNativeReward += uint128(
                    (dropAmount * 1) / 5
                );
            }

            emit DropNative(tokenId, dropAmount);
        }
    }

    function _directDropRebornToTopTokenIds(
        uint256[] memory tokenIds,
        uint256 dropAmount,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // if tokenId is zero, return
            // as 0 means there is no more tokenIds
            if (tokenId == 0) {
                return;
            }

            uint256 poolCoinday = getPoolCoinday(tokenId, _seasonData);
            // if no coinday,
            // continue and jump to next one
            if (poolCoinday == 0) {
                continue;
            }

            Pool storage pool = _seasonData.pools[tokenId];
            pool.lastDropRebornTime = uint32(block.timestamp);

            unchecked {
                // 80% to pool
                pool.droppedRebornTotal += (4 * uint128(dropAmount)) / 5;
                pool.accRebornPerShare =
                    (pool.droppedRebornTotal * PERSHARE_BASE) /
                    poolCoinday;
            }

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];

            unchecked {
                portfolio.pendingOwnerRebornReward += uint128(
                    (dropAmount * 1) / 5
                );
            }

            emit DropReborn(tokenId, dropAmount);
        }
    }

    function _directDropRebornToRaffleTokenIds(
        uint256[] memory tokenIds,
        uint256 dropAmount,
        IRebornDefination.SeasonData storage _seasonData
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // if tokenId is zero, continue
            // as it's raffle
            if (tokenId == 0) {
                continue;
            }
            uint256 poolCoinday = getPoolCoinday(tokenId, _seasonData);
            // if no coinday, continue
            if (poolCoinday == 0) {
                continue;
            }

            Pool storage pool = _seasonData.pools[tokenId];
            pool.lastDropRebornTime = uint32(block.timestamp);

            unchecked {
                // 80% to pool
                pool.droppedRebornTotal += (4 * uint128(dropAmount)) / 5;
                pool.accRebornPerShare =
                    (pool.droppedRebornTotal * PERSHARE_BASE) /
                    poolCoinday;
            }

            // 20% to owner
            address owner = IERC721(address(this)).ownerOf(tokenId);
            Portfolio storage portfolio = _seasonData.portfolios[owner][
                tokenId
            ];

            unchecked {
                portfolio.pendingOwnerRebornReward += uint128(
                    (dropAmount * 1) / 5
                );
            }

            emit DropReborn(tokenId, dropAmount);
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
        RewardType rewardType
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
                : (amount * rewardFees.vaultRef1Fee) / PERCENTAGE_BASE;
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
    function _sendNativeRewardToRefs(
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
                RewardType.NativeToken
            );

        if (ref1Reward > 0) {
            payable(ref1).transfer(ref1Reward);
        }

        if (ref2Reward > 0) {
            payable(ref2).transfer(ref2Reward);
        }

        unchecked {
            total = ref1Reward + ref2Reward;
        }

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
        uint256 amount
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
                RewardType.RebornToken
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

    function _computeUserCoindayOfAirdropTimestamp(
        uint256 tokenId,
        address account,
        AirdropConf storage dropConf,
        IRebornDefination.SeasonData storage _seasonData
    )
        internal
        view
        returns (uint256 userNativeCoinday, uint256 userRebornCoinday)
    {
        PortalLib.Portfolio storage portfolio = _seasonData.portfolios[account][
            tokenId
        ];

        PortalLib.Pool storage pool = _seasonData.pools[tokenId];

        uint256 lastNativeUpdate;
        uint256 lastRebornUpdate;
        if (pool.lastDropNativeTime == 0) {
            lastNativeUpdate = dropConf._nativeDropLastUpdate;
        } else {
            lastNativeUpdate = pool.lastDropNativeTime;
        }
        if (pool.lastDropRebornTime == 0) {
            lastRebornUpdate = dropConf._rebornDropLastUpdate;
        } else {
            lastRebornUpdate = pool.lastDropRebornTime;
        }

        unchecked {
            if (portfolio.coindayUpdateLastTime < lastNativeUpdate) {
                userNativeCoinday =
                    portfolio.coindayCumulant +
                    ((lastNativeUpdate - portfolio.coindayUpdateLastTime) *
                        portfolio.accumulativeAmount) /
                    1 days;
            }

            if (portfolio.coindayUpdateLastTime < lastRebornUpdate) {
                userRebornCoinday =
                    portfolio.coindayCumulant +
                    ((lastRebornUpdate - portfolio.coindayUpdateLastTime) *
                        portfolio.accumulativeAmount) /
                    1 days;
            }
        }
    }

    function getPoolCoinday(
        uint256 tokenId,
        IRebornDefination.SeasonData storage _seasonData
    ) public view returns (uint256 poolCoinday) {
        PortalLib.Pool storage pool = _seasonData.pools[tokenId];

        unchecked {
            uint256 poolPending = ((block.timestamp -
                pool.coindayUpdateLastTime) * pool.totalAmount) / 1 days;
            poolCoinday = poolPending + pool.coindayCumulant;
        }
    }

    function _updateCoinday(
        PortalLib.Portfolio storage portfolio,
        PortalLib.Pool storage pool
    ) public {
        unchecked {
            portfolio.coindayCumulant +=
                ((block.timestamp - portfolio.coindayUpdateLastTime) *
                    portfolio.accumulativeAmount) /
                1 days;
            portfolio.coindayUpdateLastTime = uint32(block.timestamp);

            pool.coindayCumulant +=
                ((block.timestamp - pool.coindayUpdateLastTime) *
                    pool.totalAmount) /
                1 days;
            pool.coindayUpdateLastTime = uint32(block.timestamp);
        }
    }

    function getCoinday(
        uint256 tokenId,
        address account,
        IRebornDefination.SeasonData storage _seasonData
    ) public view returns (uint256 userCoinday, uint256 poolCoinday) {
        PortalLib.Portfolio memory portfolio = _seasonData.portfolios[account][
            tokenId
        ];
        PortalLib.Pool memory pool = _seasonData.pools[tokenId];

        unchecked {
            uint256 userPending = ((block.timestamp -
                portfolio.coindayUpdateLastTime) *
                portfolio.accumulativeAmount) / 1 days;

            uint256 poolPending = ((block.timestamp -
                pool.coindayUpdateLastTime) * pool.totalAmount) / 1 days;

            userCoinday = userPending + portfolio.coindayCumulant;
            poolCoinday = poolPending + pool.coindayCumulant;
        }
    }

    function _increasePool(
        uint256 tokenId,
        uint256 amount,
        IRebornDefination.TributeDirection tributeDirection,
        IRebornDefination.SeasonData storage _seasonData
    ) internal returns (uint256 totalPoolTribute) {
        Portfolio storage portfolio = _seasonData.portfolios[msg.sender][
            tokenId
        ];
        Pool storage pool = _seasonData.pools[tokenId];

        // update coinday
        _updateCoinday(portfolio, pool);

        // if user have no stake before, should flatten debt
        if (portfolio.accumulativeAmount == 0) {
            unchecked {
                // flatten native reward
                portfolio.nativeRewardDebt = uint128(
                    (portfolio.coindayCumulant * pool.accNativePerShare) /
                        PERSHARE_BASE
                );

                // flatten reborn reward
                portfolio.rebornRewardDebt = uint128(
                    (portfolio.coindayCumulant * pool.accRebornPerShare) /
                        PERSHARE_BASE
                );
            }
        }

        unchecked {
            portfolio.accumulativeAmount += amount;
            pool.totalAmount += amount;
        }

        if (
            (portfolio.totalForwardTribute > portfolio.totalReverseTribute &&
                tributeDirection ==
                IRebornDefination.TributeDirection.Reverse) ||
            (portfolio.totalForwardTribute < portfolio.totalReverseTribute &&
                tributeDirection == IRebornDefination.TributeDirection.Forward)
        ) {
            revert IRebornDefination.DirectionError();
        }

        if (tributeDirection == IRebornDefination.TributeDirection.Forward) {
            pool.totalForwardTribute += uint112(amount);
            portfolio.totalForwardTribute += uint112(amount);
        } else {
            pool.totalReverseTribute += uint112(amount);
            portfolio.totalReverseTribute += uint112(amount);
        }
        totalPoolTribute = _getTotalTributeOfPool(pool);
    }

    function _decreaseFromPool(
        uint256 tokenId,
        uint256 amount,
        IRebornDefination.SeasonData storage _seasonData
    )
        internal
        returns (
            uint256 totalTribute,
            IRebornDefination.TributeDirection tributeDirection
        )
    {
        PortalLib.Portfolio storage portfolio = _seasonData.portfolios[
            msg.sender
        ][tokenId];
        PortalLib.Pool storage pool = _seasonData.pools[tokenId];

        _updateCoinday(portfolio, pool);

        // don't need to check accumulativeAmount, as it would revert if accumulativeAmount is less
        portfolio.accumulativeAmount -= amount;
        pool.totalAmount -= amount;

        if (portfolio.totalForwardTribute > portfolio.totalReverseTribute) {
            portfolio.totalReverseTribute += uint112(amount);
            pool.totalReverseTribute += uint112(amount);
            tributeDirection = IRebornDefination.TributeDirection.Reverse;
        } else if (
            portfolio.totalForwardTribute < portfolio.totalReverseTribute
        ) {
            portfolio.totalForwardTribute += uint112(amount);
            pool.totalForwardTribute += uint112(amount);
            tributeDirection = IRebornDefination.TributeDirection.Forward;
        }

        totalTribute = _getTotalTributeOfPool(pool);
    }

    function _getTotalTributeOfPool(
        PortalLib.Pool storage pool
    ) public view returns (uint256) {
        return
            pool.totalForwardTribute > pool.totalReverseTribute
                ? pool.totalForwardTribute - pool.totalReverseTribute
                : 0;
    }

    function _calculateCurrentAP(
        CharacterProperty memory charProperty
    ) public view returns (uint256 currentAP) {
        if (charProperty.restoreTimePerAP == 0) {
            return charProperty.currentAP;
        }

        uint256 calculatedRestoreAp = (block.timestamp -
            charProperty.lastTimeAPUpdate) / charProperty.restoreTimePerAP;

        uint256 calculatedCurrentAP = calculatedRestoreAp +
            charProperty.currentAP;

        if (calculatedCurrentAP <= charProperty.maxAP) {
            currentAP = calculatedCurrentAP;
        } else {
            currentAP = charProperty.maxAP;
        }
    }

    function _comsumeAP(
        uint256 tokenId,
        mapping(uint256 => CharacterProperty) storage _characterProperties
    ) public {
        CharacterProperty storage charProperty = _characterProperties[tokenId];

        // restore AP and decrement
        charProperty.currentAP = uint8(_calculateCurrentAP(charProperty) - 1);

        charProperty.lastTimeAPUpdate = uint32(block.timestamp);
        // AP decrement
    }

    function setCharProperty(
        uint256[] calldata tokenIds,
        CharacterParams[] calldata charParams,
        mapping(uint256 => CharacterProperty) storage _characterProperties
    ) external {
        uint256 tokenIdLength = tokenIds.length;
        uint256 charParamsLength = charParams.length;
        if (tokenIdLength != charParamsLength) {
            revert CommonError.InvalidParams();
        }
        for (uint256 i = 0; i < tokenIdLength; ) {
            uint256 tokenId = tokenIds[i];
            PortalLib.CharacterParams memory charParam = charParams[i];
            PortalLib.CharacterProperty
                storage charProperty = _characterProperties[tokenId];

            charProperty.maxAP = uint8(charParam.maxAP);
            charProperty.restoreTimePerAP = uint24(charParam.restoreTimePerAP);

            // TODO: to check, restore all AP immediately
            charProperty.currentAP = uint8(charParam.maxAP);

            charProperty.level = uint8(charParam.level);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev record referrer relationship
     */
    function _refer(
        mapping(address => address) storage referrals,
        address referrer
    ) external {
        if (
            referrals[msg.sender] == address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            referrals[msg.sender] = referrer;
            emit Refer(msg.sender, referrer);
        }
    }

    function _useSoupParam(
        IRebornDefination.SoupParams calldata soupParams,
        uint256 nonce,
        mapping(uint256 => PortalLib.CharacterProperty)
            storage _characterProperties,
        mapping(address => bool) storage signers
    ) internal {
        _checkSig(soupParams, nonce, signers);

        if (soupParams.charTokenId != 0) {
            _comsumeAP(soupParams.charTokenId, _characterProperties);
        }
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("Altar"),
                keccak256("1")
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _checkSig(
        IRebornDefination.SoupParams calldata soupParams,
        uint256 nonce,
        mapping(address => bool) storage signers
    ) internal view {
        if (block.timestamp >= soupParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._SOUPPARAMS_TYPEHASH,
                msg.sender,
                soupParams.soupPrice,
                nonce,
                soupParams.charTokenId,
                soupParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _domainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            soupParams.v,
            soupParams.r,
            soupParams.s
        );

        if (!signers[signer]) {
            revert CommonError.NotSigner();
        }
    }

    function readCharProperty(
        uint256 tokenId,
        mapping(uint256 => PortalLib.CharacterProperty)
            storage _characterProperties
    ) public view returns (PortalLib.CharacterProperty memory) {
        PortalLib.CharacterProperty memory charProperty = _characterProperties[
            tokenId
        ];

        charProperty.currentAP = uint8(_calculateCurrentAP(charProperty));

        return charProperty;
    }
}