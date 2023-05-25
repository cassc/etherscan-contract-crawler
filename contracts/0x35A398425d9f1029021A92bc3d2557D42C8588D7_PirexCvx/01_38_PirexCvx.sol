// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Bytes32AddressLib} from "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";
import {PirexCvxConvex} from "./PirexCvxConvex.sol";
import {PxCvx} from "./PxCvx.sol";
import {PirexFees} from "./PirexFees.sol";
import {UnionPirexVault} from "./vault/UnionPirexVault.sol";
import {ERC1155Solmate} from "./tokens/ERC1155Solmate.sol";
import {ERC1155PresetMinterSupply} from "./tokens/ERC1155PresetMinterSupply.sol";
import {IVotiumMultiMerkleStash} from "./interfaces/IVotiumMultiMerkleStash.sol";
import {ICvxLocker} from "./interfaces/ICvxLocker.sol";

/**
    For Jude 🐾 - kings never die. QmPXRvYyDSqiqk9Xj9zsoaLa3UMN2uL5A8J9CPQPHvPQ6i - kp
    Arise, you have nothing to lose but your barbed wire fences! - never
    Hakuna matata - greenbergz
    ZA WARUDO - seiji
    Why not both. The answer to all of life's questions. CVX locked or liquid? Crypto or childcare? - Percival
    Dreams are made of these... QmU6oGG8J1cKWKiuQU1y9YTiBF89LBUyojTjfvfzZ4GMif - funky
    🫡 - Sami
    Put cereal in my coffee, INNOVATING ON CHAIN & OFF CHAIN - Marcel
    Development will continue until morale improves - Alunara
    Imagine using a lame ass quote instead of ascii art - Benny
*/
contract PirexCvx is ReentrancyGuard, PirexCvxConvex {
    using SafeTransferLib for ERC20;
    using Bytes32AddressLib for address;

    /**
        @notice Data pertaining to an emergency migration
        @param  recipient  address    Recipient of the tokens (e.g. new PirexCvx contract)
        @param  tokens     address[]  Token addresses
     */
    struct EmergencyMigration {
        address recipient;
        address[] tokens;
    }

    // Users can choose between the two futures tokens when staking or initiating a redemption
    enum Futures {
        Vote,
        Reward
    }

    // Configurable contracts
    enum Contract {
        PxCvx,
        PirexFees,
        Votium,
        UpxCvx,
        SpxCvx,
        VpxCvx,
        RpxCvx,
        UnionPirexVault
    }

    // Configurable fees
    enum Fees {
        Reward,
        RedemptionMax,
        RedemptionMin,
        Developers
    }

    // Convex voting round duration (1,209,600 seconds)
    uint32 public constant EPOCH_DURATION = 2 weeks;

    // Fee denominator
    uint32 public constant FEE_DENOMINATOR = 1_000_000;

    // Fee maximum
    uint32 public constant FEE_MAX = 100_000;

    // Maximum wait time for a CVX redemption (10,281,600 seconds)
    uint32 public constant MAX_REDEMPTION_TIME = 17 weeks;

    // Unused ERC1155 `data` param value
    bytes private constant UNUSED_1155_DATA = "";

    PxCvx public pxCvx;
    PirexFees public pirexFees;
    IVotiumMultiMerkleStash public votiumMultiMerkleStash;
    ERC1155Solmate public upxCvx;
    ERC1155Solmate public spxCvx;
    ERC1155PresetMinterSupply public vpxCvx;
    ERC1155PresetMinterSupply public rpxCvx;
    UnionPirexVault public unionPirex;

    // Fees (e.g. 5000 / 1000000 = 0.5%)
    mapping(Fees => uint32) public fees;

    // Convex unlock timestamps mapped to amount being redeemed
    mapping(uint256 => uint256) public redemptions;

    // Developers who are eligible for incentives as part of the new initiative
    // to enable builders to sustainably build apps for the Pirex ecosystem
    mapping(address => bool) public developers;

    // Emergency migration data
    EmergencyMigration public emergencyMigration;

    // Non-Pirex multisig which has authority to fulfill emergency procedures
    address public emergencyExecutor;

    // In the case of a mass unlock by Convex, the current upxCVX would be deprecated
    // and should allow holders to immediately redeem their CVX by burning upxCVX
    bool public upxCvxDeprecated;

    event SetContract(Contract indexed c, address contractAddress);
    event SetFee(Fees indexed f, uint32 fee);
    event AddDeveloper(address developer);
    event RemoveDeveloper(address developer);
    event MintFutures(
        uint256 rounds,
        Futures indexed f,
        uint256 assets,
        address indexed receiver
    );
    event Deposit(
        uint256 assets,
        address indexed receiver,
        bool indexed shouldCompound,
        address indexed developer
    );
    event InitiateRedemptions(
        uint256[] lockIndexes,
        Futures indexed f,
        uint256[] assets,
        address indexed receiver
    );
    event Redeem(
        uint256[] unlockTimes,
        uint256[] assets,
        address indexed receiver,
        bool legacy
    );
    event Stake(
        uint256 rounds,
        Futures indexed f,
        uint256 assets,
        address indexed receiver
    );
    event Unstake(uint256 id, uint256 assets, address indexed receiver);
    event ClaimMiscRewards(uint256 timestamp, ConvexReward[] rewards);
    event ClaimVotiumReward(
        address indexed token,
        uint256 index,
        uint256 amount
    );
    event RedeemSnapshotRewards(
        uint256 indexed epoch,
        uint256[] rewardIndexes,
        address indexed receiver,
        uint256 snapshotBalance,
        uint256 snapshotSupply
    );
    event RedeemFuturesRewards(
        uint256 indexed epoch,
        address indexed receiver,
        bytes32[] rewards
    );
    event ExchangeFutures(
        uint256 indexed epoch,
        uint256 amount,
        address indexed receiver,
        Futures f
    );
    event InitializeEmergencyExecutor(address _emergencyExecutor);
    event SetEmergencyMigration(EmergencyMigration _emergencyMigration);
    event SetUpxCvxDeprecated(bool state);
    event ExecuteEmergencyMigration(address recipient, address[] tokens);

    error ZeroAmount();
    error BeforeUnlock();
    error InsufficientBalance();
    error AlreadyRedeemed();
    error InsufficientRedemptionAllowance();
    error PastExchangePeriod();
    error InvalidFee();
    error BeforeEffectiveTimestamp();
    error BeforeStakingExpiry();
    error InvalidEpoch();
    error EmptyArray();
    error MismatchedArrayLengths();
    error NoRewards();
    error RedeemClosed();
    error AlreadyInitialized();
    error NoEmergencyExecutor();
    error InvalidEmergencyMigration();
    error NotAuthorized();

    /**
        @param  _CVX                     address  CVX address    
        @param  _cvxLocker               address  CvxLocker address
        @param  _cvxDelegateRegistry     address  CvxDelegateRegistry address
        @param  _pxCvx                   address  PxCvx address
        @param  _upxCvx                  address  UpxCvx address
        @param  _spxCvx                  address  SpxCvx address
        @param  _vpxCvx                  address  VpxCvx address
        @param  _rpxCvx                  address  RpxCvx address
        @param  _pirexFees               address  PirexFees address
        @param  _votiumMultiMerkleStash  address  VotiumMultiMerkleStash address
     */
    constructor(
        address _CVX,
        address _cvxLocker,
        address _cvxDelegateRegistry,
        address _pxCvx,
        address _upxCvx,
        address _spxCvx,
        address _vpxCvx,
        address _rpxCvx,
        address _pirexFees,
        address _votiumMultiMerkleStash
    ) PirexCvxConvex(_CVX, _cvxLocker, _cvxDelegateRegistry) {
        // Init with paused state, should only unpause after fully perform the full setup
        _pause();

        if (_pxCvx == address(0)) revert ZeroAddress();
        if (_pirexFees == address(0)) revert ZeroAddress();
        if (_upxCvx == address(0)) revert ZeroAddress();
        if (_spxCvx == address(0)) revert ZeroAddress();
        if (_vpxCvx == address(0)) revert ZeroAddress();
        if (_rpxCvx == address(0)) revert ZeroAddress();
        if (_votiumMultiMerkleStash == address(0)) revert ZeroAddress();

        pxCvx = PxCvx(_pxCvx);
        pirexFees = PirexFees(_pirexFees);
        upxCvx = ERC1155Solmate(_upxCvx);
        spxCvx = ERC1155Solmate(_spxCvx);
        vpxCvx = ERC1155PresetMinterSupply(_vpxCvx);
        rpxCvx = ERC1155PresetMinterSupply(_rpxCvx);
        votiumMultiMerkleStash = IVotiumMultiMerkleStash(
            _votiumMultiMerkleStash
        );
    }

    /** 
        @notice Set a contract address
        @param  c                enum     Contract
        @param  contractAddress  address  Contract address    
     */
    function setContract(Contract c, address contractAddress)
        external
        onlyOwner
    {
        if (contractAddress == address(0)) revert ZeroAddress();

        emit SetContract(c, contractAddress);

        if (c == Contract.PxCvx) {
            pxCvx = PxCvx(contractAddress);
            return;
        }

        if (c == Contract.PirexFees) {
            pirexFees = PirexFees(contractAddress);
            return;
        }

        if (c == Contract.Votium) {
            votiumMultiMerkleStash = IVotiumMultiMerkleStash(contractAddress);
            return;
        }

        if (c == Contract.UpxCvx) {
            upxCvx = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.SpxCvx) {
            spxCvx = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.VpxCvx) {
            vpxCvx = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        if (c == Contract.RpxCvx) {
            rpxCvx = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        ERC20 pxCvxERC20 = ERC20(address(pxCvx));
        address oldUnionPirex = address(unionPirex);

        if (oldUnionPirex != address(0)) {
            pxCvxERC20.safeApprove(oldUnionPirex, 0);
        }

        unionPirex = UnionPirexVault(contractAddress);
        pxCvxERC20.safeApprove(address(unionPirex), type(uint256).max);
    }

    /** 
        @notice Set fee
        @param  f    enum    Fee
        @param  fee  uint32  Fee amount
     */
    function setFee(Fees f, uint32 fee) external onlyOwner {
        if (fee > FEE_MAX) revert InvalidFee();
        if (f == Fees.RedemptionMax && fee < fees[Fees.RedemptionMin])
            revert InvalidFee();
        if (f == Fees.RedemptionMin && fee > fees[Fees.RedemptionMax])
            revert InvalidFee();

        fees[f] = fee;

        emit SetFee(f, fee);
    }

    /** 
        @notice Add developer to whitelist mapping
        @param  developer  address  Developer
     */
    function addDeveloper(address developer) external onlyOwner {
        if (developer == address(0)) revert ZeroAddress();

        developers[developer] = true;

        emit AddDeveloper(developer);
    }

    /** 
        @notice Remove developer from whitelist mapping
        @param  developer  address  Developer
     */
    function removeDeveloper(address developer) external onlyOwner {
        if (developer == address(0)) revert ZeroAddress();

        developers[developer] = false;

        emit RemoveDeveloper(developer);
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /**
        @notice Mint futures tokens
        @param  rounds    uint256  Rounds (i.e. Convex voting rounds)
        @param  f         enum     Futures enum
        @param  assets    uint256  Futures amount
        @param  receiver  address  Receives futures
    */
    function _mintFutures(
        uint256 rounds,
        Futures f,
        uint256 assets,
        address receiver
    ) internal {
        emit MintFutures(rounds, f, assets, receiver);

        ERC1155PresetMinterSupply token = f == Futures.Vote ? vpxCvx : rpxCvx;
        uint256 startingEpoch = getCurrentEpoch() + EPOCH_DURATION;
        uint256[] memory tokenIds = new uint256[](rounds);
        uint256[] memory amounts = new uint256[](rounds);

        for (uint256 i; i < rounds; ++i) {
            tokenIds[i] = startingEpoch + i * EPOCH_DURATION;
            amounts[i] = assets;
        }

        token.mintBatch(receiver, tokenIds, amounts, UNUSED_1155_DATA);
    }

    /**
        @notice Redeem CVX for specified unlock times
        @param  unlockTimes  uint256[]  vlCVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
        @param  legacy       bool       Whether upxCVX has been deprecated
     */
    function _redeem(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver,
        bool legacy
    ) internal {
        uint256 unlockLen = unlockTimes.length;

        if (unlockLen == 0) revert EmptyArray();
        if (unlockLen != assets.length) revert MismatchedArrayLengths();
        if (receiver == address(0)) revert ZeroAddress();

        emit Redeem(unlockTimes, assets, receiver, legacy);

        uint256 totalAssets;

        for (uint256 i; i < unlockLen; ++i) {
            uint256 asset = assets[i];

            if (!legacy && unlockTimes[i] > block.timestamp)
                revert BeforeUnlock();
            if (asset == 0) revert ZeroAmount();

            totalAssets += asset;
        }

        // Perform unlocking and locking procedure to ensure enough CVX is available
        if (!legacy) {
            _lock();
        }

        // Subtract redemption amount from outstanding CVX amount
        outstandingRedemptions -= totalAssets;

        // Reverts if sender has an insufficient upxCVX balance for any `unlockTime` id
        upxCvx.burnBatch(msg.sender, unlockTimes, assets);

        // Validates `to`
        CVX.safeTransfer(receiver, totalAssets);
    }

    /**
        @notice Calculate rewards
        @param  feePercent       uint32   Reward fee percent
        @param  snapshotSupply   uint256  pxCVX supply for the current snapshot id
        @param  rpxCvxSupply     uint256  rpxCVX supply for the current epoch
        @param  received         uint256  Received amount
        @return rewardFee        uint256  Fee for protocol
        @return snapshotRewards  uint256  Rewards for pxCVX token holders
        @return futuresRewards   uint256  Rewards for futures token holders
    */
    function _calculateRewards(
        uint32 feePercent,
        uint256 snapshotSupply,
        uint256 rpxCvxSupply,
        uint256 received
    )
        internal
        pure
        returns (
            uint256 rewardFee,
            uint256 snapshotRewards,
            uint256 futuresRewards
        )
    {
        // Rewards paid to the protocol
        rewardFee = (received * feePercent) / FEE_DENOMINATOR;

        // Rewards distributed amongst snapshot and futures tokenholders
        uint256 rewards = received - rewardFee;

        // Rewards distributed to snapshotted tokenholders
        snapshotRewards =
            (rewards * snapshotSupply) /
            (snapshotSupply + rpxCvxSupply);

        // Rewards distributed to rpxCVX token holders
        futuresRewards = rewards - snapshotRewards;
    }

    /**
        @notice Deposit CVX
        @param  assets          uint256  CVX amount
        @param  receiver        address  Receives pxCVX
        @param  shouldCompound  bool     Whether to auto-compound
        @param  developer       address  Developer incentive receiver
     */
    function deposit(
        uint256 assets,
        address receiver,
        bool shouldCompound,
        address developer
    ) external whenNotPaused nonReentrant {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        emit Deposit(assets, receiver, shouldCompound, developer);

        // Track amount of CVX waiting to be locked before `assets` is modified
        pendingLocks += assets;

        // Calculate the dev incentive, which will come out of the minted pxCVX
        uint256 developerIncentive = developer != address(0) &&
            developers[developer]
            ? (assets * fees[Fees.Developers]) / FEE_DENOMINATOR
            : 0;

        // Take snapshot if necessary
        pxCvx.takeEpochSnapshot();

        // Mint pxCVX sans developer incentive - recipient depends on shouldCompound
        pxCvx.mint(
            shouldCompound ? address(this) : receiver,
            assets - developerIncentive
        );

        // Transfer CVX to self in preparation for lock
        CVX.safeTransferFrom(msg.sender, address(this), assets);

        if (developerIncentive != 0) {
            // Mint pxCVX for the developer
            pxCvx.mint(developer, developerIncentive);
        }

        if (shouldCompound) {
            // Update assets to ensure only the appropriate amount is deposited in vault
            assets -= developerIncentive;

            // Deposit pxCVX into Union vault - user receives shares
            unionPirex.deposit(assets, receiver);
        }
    }

    /**
        @notice Initiate CVX redemption
        @param  lockData   ICvxLocker.LockedBalance  Locked balance index
        @param  f          enum                      Futures enum
        @param  assets     uint256                   pxCVX amount
        @param  receiver   address                   Receives upxCVX
        @param  feeMin     uint256                   Initiate redemption fee min
        @param  feeMax     uint256                   Initiate redemption fee max
        @return feeAmount  uint256                   Fee amount
     */
    function _initiateRedemption(
        ICvxLocker.LockedBalance memory lockData,
        Futures f,
        uint256 assets,
        address receiver,
        uint256 feeMin,
        uint256 feeMax
    ) internal returns (uint256 feeAmount) {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        uint256 unlockTime = lockData.unlockTime;

        // Used for calculating the fee and conditionally adding a round
        uint256 waitTime = unlockTime - block.timestamp;

        if (feeMax != 0) {
            uint256 feePercent = feeMax -
                (((feeMax - feeMin) * waitTime) / MAX_REDEMPTION_TIME);

            feeAmount = (assets * feePercent) / FEE_DENOMINATOR;
        }

        uint256 postFeeAmount = assets - feeAmount;

        // Increment redemptions for this unlockTime to prevent over-redeeming
        redemptions[unlockTime] += postFeeAmount;

        // Check if there is any sufficient allowance after factoring in redemptions by others
        if (redemptions[unlockTime] > lockData.amount)
            revert InsufficientRedemptionAllowance();

        // Track assets that needs to remain unlocked for redemptions
        outstandingRedemptions += postFeeAmount;

        // Mint upxCVX with unlockTime as the id - validates `to`
        upxCvx.mint(receiver, unlockTime, postFeeAmount, UNUSED_1155_DATA);

        // Determine how many futures notes rounds to mint
        uint256 rounds = waitTime / EPOCH_DURATION;

        // Check if the lock was in the first week/half of an epoch
        // Handle case where remaining time is between 1 and 2 weeks
        if (
            rounds == 0 &&
            unlockTime % EPOCH_DURATION != 0 &&
            waitTime > (EPOCH_DURATION / 2)
        ) {
            // Rounds is 0 if waitTime is between 1 and 2 weeks
            // Increment by 1 since user should receive 1 round of rewards
            unchecked {
                ++rounds;
            }
        }

        // Mint vpxCVX or rpxCVX (using assets as we do not take a fee from this)
        _mintFutures(rounds, f, assets, receiver);

        return feeAmount;
    }

    /**
        @notice Initiate CVX redemptions
        @param  lockIndexes  uint256[]  Locked balance index
        @param  f            enum       Futures enum
        @param  assets       uint256[]  pxCVX amounts
        @param  receiver     address    Receives upxCVX
     */
    function initiateRedemptions(
        uint256[] calldata lockIndexes,
        Futures f,
        uint256[] calldata assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        uint256 lockLen = lockIndexes.length;

        if (lockLen == 0) revert EmptyArray();
        if (lockLen != assets.length) revert MismatchedArrayLengths();

        emit InitiateRedemptions(lockIndexes, f, assets, receiver);

        (, , , ICvxLocker.LockedBalance[] memory lockData) = cvxLocker
            .lockedBalances(address(this));
        uint256 totalAssets;
        uint256 feeAmount;
        uint256 feeMin = fees[Fees.RedemptionMin];
        uint256 feeMax = fees[Fees.RedemptionMax];

        for (uint256 i; i < lockLen; ++i) {
            totalAssets += assets[i];
            feeAmount += _initiateRedemption(
                lockData[lockIndexes[i]],
                f,
                assets[i],
                receiver,
                feeMin,
                feeMax
            );
        }

        // Burn pxCVX - reverts if sender balance is insufficient
        pxCvx.burn(msg.sender, totalAssets - feeAmount);

        if (feeAmount != 0) {
            // Allow PirexFees to distribute fees directly from sender
            pxCvx.operatorApprove(msg.sender, address(pirexFees), feeAmount);

            // Distribute fees
            pirexFees.distributeFees(msg.sender, address(pxCvx), feeAmount);
        }
    }

    /**
        @notice Redeem CVX for specified unlock times
        @param  unlockTimes  uint256[]  CVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
     */
    function redeem(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (upxCvxDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, false);
    }

    /**
        @notice Redeem CVX for deprecated upxCVX holders if enabled
        @param  unlockTimes  uint256[]  CVX unlock timestamps
        @param  assets       uint256[]  upxCVX amounts
        @param  receiver     address    Receives CVX
     */
    function redeemLegacy(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenPaused nonReentrant {
        if (!upxCvxDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, true);
    }

    /**
        @notice Stake pxCVX
        @param  rounds    uint256  Rounds (i.e. Convex voting rounds)
        @param  f         enum     Futures enum
        @param  assets    uint256  pxCVX amount
        @param  receiver  address  Receives spxCVX
    */
    function stake(
        uint256 rounds,
        Futures f,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (rounds == 0) revert ZeroAmount();
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Burn pxCVX
        pxCvx.burn(msg.sender, assets);

        emit Stake(rounds, f, assets, receiver);

        // Mint spxCVX with the stake expiry timestamp as the id
        spxCvx.mint(
            receiver,
            getCurrentEpoch() + EPOCH_DURATION * rounds,
            assets,
            UNUSED_1155_DATA
        );

        _mintFutures(rounds, f, assets, receiver);
    }

    /**
        @notice Unstake pxCVX
        @param  id        uint256  spxCVX id (an epoch timestamp)
        @param  assets    uint256  spxCVX amount
        @param  receiver  address  Receives pxCVX
    */
    function unstake(
        uint256 id,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (id > block.timestamp) revert BeforeStakingExpiry();
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Mint pxCVX for receiver
        pxCvx.mint(receiver, assets);

        emit Unstake(id, assets, receiver);

        // Burn spxCVX from sender
        spxCvx.burn(msg.sender, id, assets);
    }

    /**
        @notice Claim multiple Votium rewards
        @param  votiumRewards  VotiumRewards[]  Votium rewards metadata
    */
    function claimVotiumRewards(
        IVotiumMultiMerkleStash.claimParam[] calldata votiumRewards
    ) external whenNotPaused nonReentrant {
        uint256 tLen = votiumRewards.length;

        if (tLen == 0) revert EmptyArray();

        // Take snapshot before claiming rewards, if necessary
        pxCvx.takeEpochSnapshot();

        uint256 epoch = getCurrentEpoch();
        (uint256 snapshotId, , , ) = pxCvx.getEpoch(epoch);
        uint256 rpxCvxSupply = rpxCvx.totalSupply(epoch);

        for (uint256 i; i < tLen; ++i) {
            address token = votiumRewards[i].token;
            uint256 index = votiumRewards[i].index;
            uint256 amount = votiumRewards[i].amount;
            bytes32[] memory merkleProof = votiumRewards[i].merkleProof;

            if (token == address(0)) revert ZeroAddress();
            if (amount == 0) revert ZeroAmount();

            emit ClaimVotiumReward(token, index, amount);

            ERC20 t = ERC20(token);

            // Used for calculating the actual token amount received
            uint256 prevBalance = t.balanceOf(address(this));

            // Validates `token`, `index`, `amount`, and `merkleProof`
            votiumMultiMerkleStash.claim(
                token,
                index,
                address(this),
                amount,
                merkleProof
            );

            (
                uint256 rewardFee,
                uint256 snapshotRewards,
                uint256 futuresRewards
            ) = _calculateRewards(
                    fees[Fees.Reward],
                    pxCvx.totalSupplyAt(snapshotId),
                    rpxCvxSupply,
                    t.balanceOf(address(this)) - prevBalance
                );

            // Add reward token address and snapshot/futuresRewards amounts (same index for all)
            pxCvx.addEpochRewardMetadata(
                epoch,
                token.fillLast12Bytes(),
                snapshotRewards,
                futuresRewards
            );

            // Distribute fees
            t.safeApprove(address(pirexFees), rewardFee);
            pirexFees.distributeFees(address(this), token, rewardFee);
        }
    }

    /**
        @notice Claim misc. rewards (e.g. emissions) and distribute to stakeholders
     */
    function claimMiscRewards() external nonReentrant {
        // Get claimable rewards and balances
        ConvexReward[] memory c = _claimableRewards();

        emit ClaimMiscRewards(block.timestamp, c);

        // Claim rewards from Convex
        _getReward();

        uint256 cLen = c.length;

        // Iterate over rewards and distribute to stakeholders (rlBTRFLY, Redacted, and Pirex)
        for (uint256 i; i < cLen; ++i) {
            if (c[i].amount == 0) continue;

            ERC20 t = ERC20(c[i].token);
            uint256 received = t.balanceOf(address(this)) - c[i].balance;

            // Distribute fees
            t.safeApprove(address(pirexFees), received);
            pirexFees.distributeFees(address(this), c[i].token, received);
        }
    }

    /**
        @notice Redeem multiple Snapshot rewards as a pxCVX holder
        @param  epoch          uint256    Epoch
        @param  rewardIndexes  uint256[]  Reward token indexes
        @param  receiver       address    Receives snapshot rewards
    */
    function redeemSnapshotRewards(
        uint256 epoch,
        uint256[] calldata rewardIndexes,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (epoch == 0) revert InvalidEpoch();
        if (receiver == address(0)) revert ZeroAddress();

        uint256 rewardLen = rewardIndexes.length;

        if (rewardLen == 0) revert EmptyArray();

        (
            uint256 snapshotId,
            bytes32[] memory rewards,
            uint256[] memory snapshotRewards,

        ) = pxCvx.getEpoch(epoch);

        // Used to update the redeemed flag locally before updating to the storage all at once for gas efficiency
        uint256 redeemed = pxCvx.getEpochRedeemedSnapshotRewards(
            msg.sender,
            epoch
        );

        // Check whether msg.sender maintained a positive balance before the snapshot
        uint256 snapshotBalance = pxCvx.balanceOfAt(msg.sender, snapshotId);
        uint256 snapshotSupply = pxCvx.totalSupplyAt(snapshotId);

        if (snapshotBalance == 0) revert InsufficientBalance();

        emit RedeemSnapshotRewards(
            epoch,
            rewardIndexes,
            receiver,
            snapshotBalance,
            snapshotSupply
        );

        for (uint256 i; i < rewardLen; ++i) {
            uint256 index = rewardIndexes[i];
            uint256 indexRedeemed = (1 << index);

            if ((redeemed & indexRedeemed) != 0) revert AlreadyRedeemed();

            redeemed |= indexRedeemed;

            ERC20(address(uint160(bytes20(rewards[index])))).safeTransfer(
                receiver,
                (snapshotRewards[index] * snapshotBalance) / snapshotSupply
            );
        }

        // Update the redeemed rewards flag in storage to prevent double claimings
        pxCvx.setEpochRedeemedSnapshotRewards(msg.sender, epoch, redeemed);
    }

    /**
        @notice Redeem futures rewards for rpxCVX holders for an epoch
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  receiver  address  Receives futures rewards
    */
    function redeemFuturesRewards(uint256 epoch, address receiver)
        external
        whenNotPaused
        nonReentrant
    {
        if (epoch == 0) revert InvalidEpoch();
        if (epoch > getCurrentEpoch()) revert InvalidEpoch();
        if (receiver == address(0)) revert ZeroAddress();

        // Prevent users from burning their futures notes before rewards are claimed
        (, bytes32[] memory rewards, , uint256[] memory futuresRewards) = pxCvx
            .getEpoch(epoch);

        if (rewards.length == 0) revert NoRewards();

        emit RedeemFuturesRewards(epoch, receiver, rewards);

        // Check sender rpxCVX balance
        uint256 rpxCvxBalance = rpxCvx.balanceOf(msg.sender, epoch);

        if (rpxCvxBalance == 0) revert InsufficientBalance();

        // Store rpxCVX total supply before burning
        uint256 rpxCvxTotalSupply = rpxCvx.totalSupply(epoch);

        // Burn rpxCVX tokens
        rpxCvx.burn(msg.sender, epoch, rpxCvxBalance);

        uint256 rLen = rewards.length;

        // Loop over rewards and transfer the amount entitled to the rpxCVX token holder
        for (uint256 i; i < rLen; ++i) {
            uint256 rewardAmount = (futuresRewards[i] * rpxCvxBalance) /
                rpxCvxTotalSupply;

            // Update reward amount by deducting the amount transferred to the receiver
            futuresRewards[i] -= rewardAmount;

            // Proportionate to the % of rpxCVX owned out of the rpxCVX total supply
            ERC20(address(uint160(bytes20(rewards[i])))).safeTransfer(
                receiver,
                rewardAmount
            );
        }

        // Update future rewards to reflect the amounts remaining post-redemption
        pxCvx.updateEpochFuturesRewards(epoch, futuresRewards);
    }

    /**
        @notice Exchange one futures token for another
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  amount    uint256  Exchange amount
        @param  receiver  address  Receives futures token
        @param  f         enum     Futures enum
    */
    function exchangeFutures(
        uint256 epoch,
        uint256 amount,
        address receiver,
        Futures f
    ) external whenNotPaused {
        // Users can only exchange futures tokens for future epochs
        if (epoch <= getCurrentEpoch()) revert PastExchangePeriod();
        if (amount == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        ERC1155PresetMinterSupply futuresIn = f == Futures.Vote
            ? vpxCvx
            : rpxCvx;
        ERC1155PresetMinterSupply futuresOut = f == Futures.Vote
            ? rpxCvx
            : vpxCvx;

        emit ExchangeFutures(epoch, amount, receiver, f);

        // Validates `amount` (balance)
        futuresIn.burn(msg.sender, epoch, amount);

        // Validates `to`
        futuresOut.mint(receiver, epoch, amount, UNUSED_1155_DATA);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY/MIGRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
        @notice Initialize the emergency executor address
        @param  _emergencyExecutor  address  Non-Pirex multisig
     */
    function initializeEmergencyExecutor(address _emergencyExecutor)
        external
        onlyOwner
        whenPaused
    {
        if (_emergencyExecutor == address(0)) revert ZeroAddress();
        if (emergencyExecutor != address(0)) revert AlreadyInitialized();

        emergencyExecutor = _emergencyExecutor;

        emit InitializeEmergencyExecutor(_emergencyExecutor);
    }

    /** 
        @notice Set the emergency migration data
        @param  _emergencyMigration  EmergencyMigration  Emergency migration data
     */
    function setEmergencyMigration(
        EmergencyMigration calldata _emergencyMigration
    ) external onlyOwner whenPaused {
        if (emergencyExecutor == address(0)) revert NoEmergencyExecutor();
        if (_emergencyMigration.recipient == address(0))
            revert InvalidEmergencyMigration();
        if (_emergencyMigration.tokens.length == 0)
            revert InvalidEmergencyMigration();

        emergencyMigration = _emergencyMigration;

        emit SetEmergencyMigration(_emergencyMigration);
    }

    /** 
        @notice Execute the emergency migration
     */
    function executeEmergencyMigration() external whenPaused {
        if (msg.sender != emergencyExecutor) revert NotAuthorized();

        address migrationRecipient = emergencyMigration.recipient;

        if (migrationRecipient == address(0))
            revert InvalidEmergencyMigration();

        address[] memory migrationTokens = emergencyMigration.tokens;
        uint256 tLen = migrationTokens.length;

        if (tLen == 0) revert InvalidEmergencyMigration();

        uint256 o = outstandingRedemptions;

        for (uint256 i; i < tLen; ++i) {
            ERC20 token = ERC20(migrationTokens[i]);
            uint256 balance = token.balanceOf(address(this));

            if (token == CVX) {
                // Transfer the diff between CVX balance and outstandingRedemptions
                balance = balance > o ? balance - o : 0;
            }

            token.safeTransfer(migrationRecipient, balance);
        }

        emit ExecuteEmergencyMigration(migrationRecipient, migrationTokens);
    }

    /**
        @notice Set whether the currently set upxCvx is deprecated or not
        @param  state  bool  Deprecation state
     */
    function setUpxCvxDeprecated(bool state) external onlyOwner whenPaused {
        upxCvxDeprecated = state;

        emit SetUpxCvxDeprecated(state);
    }
}