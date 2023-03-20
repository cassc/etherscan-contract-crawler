// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Upgradeable} from "src/modified/VRFConsumerBaseV2Upgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {RankUpgradeable} from "src/RankUpgradeable.sol";
import {Renderer} from "src/lib/Renderer.sol";

import {PortalLib} from "src/PortalLib.sol";
import {FastArray} from "src/lib/FastArray.sol";

contract RebornPortal is
    IRebornPortal,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    RebornPortalStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AutomationCompatible,
    RankUpgradeable,
    VRFConsumerBaseV2Upgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using FastArray for FastArray.Data;

    /**
     * @dev initialize function
     * @param rebornToken_ $REBORN token address
     * @param owner_ owner address
     * @param name_ ERC712 name
     * @param symbol_ ERC721 symbol
     * @param vrfCoordinator_ chainlink vrf coordinator_ address
     */
    function initialize(
        RBT rebornToken_,
        address owner_,
        string memory name_,
        string memory symbol_,
        address vrfCoordinator_
    ) public initializer {
        if (address(rebornToken_) == address(0)) {
            revert ZeroAddressSet();
        }
        rebornToken = rebornToken_;
        __Ownable_init(owner_);
        __ERC721_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Pausable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator_);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        Innate calldata innate,
        address referrer,
        uint256 _soupPrice
    )
        external
        payable
        override
        checkIncarnationCount
        whenNotPaused
        nonReentrant
    {
        _refer(referrer);
        _incarnate(innate, _soupPrice);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function engrave(
        bytes32 seed,
        address user,
        uint256 reward,
        uint256 score,
        uint256 age,
        uint256 cost,
        string calldata creatorName
    ) external override onlySigner whenNotPaused {
        if (_seeds.get(uint256(seed))) {
            revert SameSeed();
        }
        _seeds.set(uint256(seed));

        // tokenId auto increment
        uint256 tokenId = ++idx + (block.chainid * 1e18);

        details[tokenId] = LifeDetail(
            seed,
            user,
            uint16(age),
            ++rounds[user],
            0,
            uint128(cost),
            uint128(reward),
            score,
            creatorName
        );
        // mint erc721
        _safeMint(user, tokenId);
        // send $REBORN reward
        vault.reward(user, reward);

        // let tokenId enter the score rank
        _enterScoreRank(tokenId, score);

        // mint to referrer
        _vaultRewardToRefs(user, reward);

        emit Engrave(seed, user, tokenId, score, reward);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function baptise(
        address user,
        uint256 amount
    ) external override onlySigner whenNotPaused {
        vault.reward(user, amount);

        emit Baptise(user, amount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount
    ) external override whenNotPaused {
        _claimPoolDrop(tokenId);
        _infuse(tokenId, amount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external override whenNotPaused {
        _claimPoolDrop(tokenId);
        _permit(permitAmount, deadline, r, s, v);
        _infuse(tokenId, amount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount
    ) external override whenNotPaused {
        _claimPoolDrop(fromTokenId);
        _claimPoolDrop(toTokenId);
        _decreaseFromPool(fromTokenId, amount);
        _increaseToPool(toTokenId, amount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimDrops(
        uint256[] calldata tokenIds
    ) external override whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claimPoolDrop(tokenIds[i]);
        }
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimNativeDrops(
        uint256[] calldata tokenIds
    ) external override whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            PortalLib._claimPoolNativeDrop(tokenIds[i], _seasonData[_season]);
        }
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimRebornDrops(
        uint256[] calldata tokenIds
    ) external override whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            PortalLib._claimPoolRebornDrop(
                tokenIds[i],
                vault,
                _seasonData[_season]
            );
        }
    }

    /**
     * @dev Upkeep perform of chainlink automation
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotPaused {
        (uint256 t, uint256 id) = abi.decode(performData, (uint256, uint256));

        if (t == 1) {
            _requestDropReborn();
        } else if (t == 2) {
            _requestDropNative();
        } else if (t == 3) {
            _fulfillDropReborn(id);
        } else if (t == 4) {
            _fulfillDropNative(id);
        }
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function toNextSeason() external onlyOwner {
        _season += 1;

        // pause the contract
        _pause();

        // 16% jackpot to next season
        _seasonData[_season]._jackpot =
            (_seasonData[_season - 1]._jackpot * 16) /
            100;

        emit NewSeason(_season);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function setDropConf(
        PortalLib.AirdropConf calldata conf
    ) external override onlyOwner {
        _dropConf = conf;
        emit PortalLib.NewDropConf(conf);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function setVrfConf(
        PortalLib.VrfConf calldata conf
    ) external override onlyOwner {
        _vrfConf = conf;
        emit PortalLib.NewVrfConf(conf);
    }

    /**
     * @dev set vault
     * @param vault_ new vault address
     */
    function setVault(RewardVault vault_) external onlyOwner {
        vault = vault_;
        emit VaultSet(address(vault_));
    }

    /**
     * @dev set incarnation limit
     */
    function setIncarnationLimit(uint256 limit) external onlyOwner {
        _incarnateCountLimit = limit;
        emit NewIncarnationLimit(limit);
    }

    /**
     * @dev withdraw token from vault
     * @param to the address which owner withdraw token to
     */
    function withdrawVault(address to) external whenPaused onlyOwner {
        vault.withdrawEmergency(to);
    }

    /**
     * @dev burn $REBORN from burn pool
     * @param amount burn from burn pool
     */
    function burnFromBurnPool(uint256 amount) external onlyOwner {
        IBurnPool(burnPool).burn(amount);
    }

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        PortalLib._updateSigners(signers, toAdd, toRemove);
    }

    /**
     * @notice mul 100 when set. eg: 8% -> 800 18%-> 1800
     * @dev set percentage of referrer reward
     * @param rewardType 0: incarnate reward 1: engrave reward
     */
    function setReferrerRewardFee(
        uint16 refL1Fee,
        uint16 refL2Fee,
        PortalLib.RewardType rewardType
    ) external onlyOwner {
        PortalLib._setReferrerRewardFee(
            rewardFees,
            refL1Fee,
            refL2Fee,
            rewardType
        );
    }

    function setExtraReward(uint256 extraReward) external onlyOwner {
        _extraReward = extraReward;

        emit NewExtraReward(_extraReward);
    }

    // set burnPool address for pre burn $REBORN
    function setBurnPool(address burnPool_) external onlyOwner {
        if (burnPool_ == address(0)) {
            revert ZeroAddressSet();
        }
        burnPool = burnPool_;
    }

    /**
     * @dev anticheat, downgrade score and remove from rank
     */
    function antiCheat(uint256 tokenId, uint256 score) external onlyOwner {
        LifeDetail storage detail = details[tokenId];
        uint256 oldScore = detail.score;

        detail.score = score;

        // if it's top one hundred make this tokenId exit rank
        _exitRank(tokenId, oldScore);
    }

    /**
     * @dev withdraw native token for reward distribution
     * @dev amount how much to withdraw
     */
    function withdrawNativeToken(uint256 amount) external whenPaused onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev read pending reward from specific pool
     * @param tokenIds tokenId array of the pools
     */
    function pendingDrop(
        uint256[] memory tokenIds
    ) external view returns (uint256 pNative, uint256 pReborn) {
        return PortalLib._pendingDrop(_seasonData[_season], tokenIds);
    }

    /**
     * @dev checkUpkeep for chainlink automation
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (_dropConf._dropOn == 1) {
            // first, check whether airdrop is ready and send vrf request
            if (
                block.timestamp >
                _dropConf._rebornDropLastUpdate + _dropConf._rebornDropInterval
            ) {
                upkeepNeeded = true;
                performData = abi.encode(1, 0);
                return (upkeepNeeded, performData);
            } else if (
                block.timestamp >
                _dropConf._nativeDropLastUpdate + _dropConf._nativeDropInterval
            ) {
                upkeepNeeded = true;
                performData = abi.encode(2, 0);
                return (upkeepNeeded, performData);
            }
            // second, check pending drop and execute
            if (FastArray.length(_pendingDrops) > 0) {
                uint256 id = _pendingDrops.get(0);
                upkeepNeeded = true;
                if (_vrfRequests[id].t == AirdropVrfType.DropReborn) {
                    performData = abi.encode(3, id);
                } else if (_vrfRequests[id].t == AirdropVrfType.DropNative) {
                    performData = abi.encode(4, id);
                }
                return (upkeepNeeded, performData);
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return Renderer.renderByTokenId(details, tokenId);
    }

    /**
     * @dev check whether the seed is used on-chain
     * @param seed random seed in bytes32
     */
    function seedExists(bytes32 seed) external view returns (bool) {
        return _seeds.get(uint256(seed));
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal {
        rebornToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function _infuse(uint256 tokenId, uint256 amount) internal {
        // it's not necessary to check the whether the address of burnPool is zero
        // as function tranferFrom does not allow transfer to zero address by default
        rebornToken.transferFrom(msg.sender, burnPool, amount);

        _increasePool(tokenId, amount);

        emit Infuse(msg.sender, tokenId, amount);
    }

    /**
     * @dev implementation of incarnate
     */
    function _incarnate(Innate calldata innate, uint256 _soupPrice) internal {
        uint256 totalFee = _soupPrice +
            innate.talentPrice +
            innate.propertyPrice;
        if (msg.value < totalFee) {
            revert InsufficientAmount();
        }
        // transfer redundant native token back
        payable(msg.sender).transfer(msg.value - totalFee);

        // reward referrers
        uint256 referAmount = _sendRewardToRefs(msg.sender, totalFee);

        // rest native token to to jackpot
        _seasonData[_season]._jackpot += totalFee - referAmount;

        emit Incarnate(
            msg.sender,
            innate.talentPrice,
            innate.propertyPrice,
            _soupPrice
        );
    }

    /**
     * @dev record referrer relationship
     */
    function _refer(address referrer) internal {
        if (
            referrals[msg.sender] == address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            referrals[msg.sender] = referrer;
            emit Refer(msg.sender, referrer);
        }
    }

    /**
     * @dev airdrop to top 100 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 100
     */
    function _fulfillDropReborn(uint256 requestId) internal onlyDropOn {
        uint256[] memory topTens = _getTopNTokenId(10);
        uint256[] memory topTenToHundreds = _getFirstNTokenIdByOffSet(10, 90);

        PortalLib._directDropRebornToTopTokenIds(
            topTens,
            _dropConf,
            _seasonData[_season]
        );

        uint256[] memory selectedTokenIds = new uint256[](10);

        RequestStatus storage rs = _vrfRequests[requestId];
        rs.executed = true;

        for (uint256 i = 0; i < 10; i++) {
            selectedTokenIds[i] = topTenToHundreds[rs.randomWords[i] % 90];
        }

        PortalLib._directDropRebornToRaffleTokenIds(
            selectedTokenIds,
            _dropConf,
            _seasonData[_season]
        );

        _pendingDrops.remove(requestId);
    }

    /**
     * @dev airdrop to top 100 tvl pool
     * @dev directly drop to top 10
     * @dev raffle 10 from top 11 - top 100
     */
    function _fulfillDropNative(uint256 requestId) internal onlyDropOn {
        uint256[] memory topTens = _getTopNTokenId(10);
        uint256[] memory topTenToHundreds = _getFirstNTokenIdByOffSet(10, 90);

        PortalLib._directDropNativeToTopTokenIds(
            topTens,
            _dropConf,
            _seasonData[_season]
        );

        uint256[] memory selectedTokenIds = new uint256[](10);

        RequestStatus storage rs = _vrfRequests[requestId];
        rs.executed = true;

        for (uint256 i = 0; i < 10; i++) {
            selectedTokenIds[i] = topTenToHundreds[rs.randomWords[i] % 90];
        }

        PortalLib._directDropNativeToRaffleTokenIds(
            selectedTokenIds,
            _dropConf,
            _seasonData[_season]
        );

        // remove the amount from jackpot
        uint256 totalDropAmount = (((uint256(_dropConf._nativeTopDropRatio) *
            10) + (uint256(_dropConf._nativeRaffleDropRatio) * 10)) *
            _seasonData[_season]._jackpot) / PortalLib.PERCENTAGE_BASE;
        _seasonData[_season]._jackpot -= totalDropAmount;

        _pendingDrops.remove(requestId);
    }

    function _requestDropReborn() internal onlyDropOn {
        // update last drop timestamp to specific hour
        _dropConf._rebornDropLastUpdate = uint40(
            PortalLib._toLastHour(block.timestamp)
        );

        // raffle
        uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                _vrfConf.keyHash,
                _vrfConf.s_subscriptionId,
                _vrfConf.requestConfirmations,
                _vrfConf.callbackGasLimit,
                _vrfConf.numWords
            );

        _vrfRequests[requestId].exists = true;
        _vrfRequests[requestId].t = AirdropVrfType.DropReborn;
    }

    function _requestDropNative() internal onlyDropOn {
        // update last drop timestamp to specific hour
        _dropConf._nativeDropLastUpdate = uint40(
            PortalLib._toLastHour(block.timestamp)
        );

        // raffle
        uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                _vrfConf.keyHash,
                _vrfConf.s_subscriptionId,
                _vrfConf.requestConfirmations,
                _vrfConf.callbackGasLimit,
                _vrfConf.numWords
            );

        _vrfRequests[requestId].exists = true;
        _vrfRequests[requestId].t = AirdropVrfType.DropNative;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (
            !_vrfRequests[requestId].fulfilled && _vrfRequests[requestId].exists
        ) {
            _vrfRequests[requestId].randomWords = randomWords;
            _vrfRequests[requestId].fulfilled = true;

            _pendingDrops.insert(requestId);
        }
    }

    /**
     * @dev user claim a drop from a pool
     */
    function _claimPoolDrop(uint256 tokenId) internal nonReentrant {
        PortalLib._claimPoolNativeDrop(tokenId, _seasonData[_season]);
        PortalLib._claimPoolRebornDrop(tokenId, vault, _seasonData[_season]);
    }

    /**
     * @dev vault $REBORN token to referrers
     */
    function _vaultRewardToRefs(address account, uint256 amount) internal {
        PortalLib._vaultRewardToRefs(
            referrals,
            rewardFees,
            vault,
            account,
            amount,
            _extraReward
        );
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendRewardToRefs(
        address account,
        uint256 amount
    ) internal returns (uint256) {
        return
            PortalLib._sendRewardToRefs(referrals, rewardFees, account, amount);
    }

    /**
     * @dev decrease amount from pool of switch from
     */
    function _decreaseFromPool(uint256 tokenId, uint256 amount) internal {
        PortalLib.Portfolio storage portfolio = _seasonData[_season].portfolios[
            msg.sender
        ][tokenId];
        PortalLib.Pool storage pool = _seasonData[_season].pools[tokenId];

        // don't need to check accumulativeAmount, as it would revert if accumulativeAmount is less
        portfolio.accumulativeAmount -= amount;
        pool.totalAmount -= amount;

        PortalLib._flattenRewardDebt(pool, portfolio);

        _enterTvlRank(tokenId, pool.totalAmount);

        emit DecreaseFromPool(msg.sender, tokenId, amount);
    }

    /**
     * @dev increase amount to pool of switch to
     */
    function _increaseToPool(uint256 tokenId, uint256 amount) internal {
        uint256 restakeAmount = (amount * 95) / 100;

        _increasePool(tokenId, restakeAmount);

        emit IncreaseToPool(msg.sender, tokenId, restakeAmount);
    }

    function _increasePool(uint256 tokenId, uint256 amount) internal {
        PortalLib.Portfolio storage portfolio = _seasonData[_season].portfolios[
            msg.sender
        ][tokenId];
        portfolio.accumulativeAmount += amount;

        PortalLib.Pool storage pool = _seasonData[_season].pools[tokenId];
        pool.totalAmount += amount;

        PortalLib._flattenRewardDebt(pool, portfolio);

        _enterTvlRank(tokenId, pool.totalAmount);
    }

    /**
     * @dev returns referrer and referer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function calculateReferReward(
        address account,
        uint256 amount,
        PortalLib.RewardType rewardType
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
        return
            PortalLib._calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                rewardType,
                _extraReward
            );
    }

    /**
     * @dev read pool attribute
     */
    function getPool(
        uint256 tokenId
    ) public view returns (PortalLib.Pool memory) {
        return _seasonData[_season].pools[tokenId];
    }

    /**
     * @dev read pool attribute
     */
    function getPortfolio(
        address user,
        uint256 tokenId
    ) public view returns (PortalLib.Portfolio memory) {
        return _seasonData[_season].portfolios[user][tokenId];
    }

    function getDropConf() public view returns (PortalLib.AirdropConf memory) {
        return _dropConf;
    }

    /**
     * A -> B -> C: B: level1 A: level2
     * @dev referrer1: level1 of referrers referrer2: level2 of referrers
     */
    function getRerferrers(
        address account
    ) public view returns (address referrer1, address referrer2) {
        referrer1 = referrals[account];
        referrer2 = referrals[referrer1];
    }

    /**
     * @dev return the jackpot amount of current season
     */
    function getJackPot() public view returns (uint256) {
        return _seasonData[_season]._jackpot;
    }

    /**
     * @dev check signer implementation
     */
    function _checkSigner() internal view {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
    }

    /**
     * @dev check incarnation Count and auto increment if it meets
     */
    modifier checkIncarnationCount() {
        if (_incarnateCounts[msg.sender] >= _incarnateCountLimit) {
            revert IncarnationExceedLimit();
        }
        _incarnateCounts[msg.sender] += 1;
        _;
    }

    /**
     * @dev only allowed signer address can do something
     */
    modifier onlySigner() {
        _checkSigner();
        _;
    }

    /**
     * @dev only allowed when drop is on
     */
    modifier onlyDropOn() {
        if (_dropConf._dropOn == 0) {
            revert DropOff();
        }
        _;
    }
}