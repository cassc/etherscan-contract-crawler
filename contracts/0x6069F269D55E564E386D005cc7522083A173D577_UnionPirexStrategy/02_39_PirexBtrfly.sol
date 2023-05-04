// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {PirexBtrflyBase} from "src/PirexBtrflyBase.sol";
import {PxBtrfly} from "src/PxBtrfly.sol";
import {PirexFees} from "src/PirexFees.sol";
import {UnionPirexVault} from "src/vault/UnionPirexVault.sol";
import {ERC1155Solmate} from "src/tokens/ERC1155Solmate.sol";
import {ERC1155PresetMinterSupply} from "src/tokens/ERC1155PresetMinterSupply.sol";
import {IRewardDistributor} from "src/interfaces/IRewardDistributor.sol";
import {IRLBTRFLY} from "src/interfaces/IRLBTRFLY.sol";

/**
    @notice
    Based on PirexCvx, updated and optimized using the latest guidelines
    Notable modifications:
        - Adapt main internal dependencies to use BTRFLYV2's contract suite
        - Remove vote delegation related functionalities
        - Add internal mapping structure to allow reward forwarding for specific accounts (ie. LPs)
        - Add methods to manage the reward forwarding above
        - Update snapshot reward redemption method to take into account reward forwarding
*/
contract PirexBtrfly is ReentrancyGuard, PirexBtrflyBase {
    using SafeTransferLib for ERC20;
    using Bytes32AddressLib for address;

    /**
        @notice Data pertaining to an emergency migration
        @param  recipient  address    Recipient of the tokens (e.g. new PirexBtrfly contract)
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
        PxBtrfly,
        PirexFees,
        RewardDistributor,
        UpxBtrfly,
        SpxBtrfly,
        VpxBtrfly,
        RpxBtrfly,
        UnionPirexVault
    }

    // Configurable fees
    enum Fees {
        Reward,
        RedemptionMax,
        RedemptionMin,
        Developers
    }

    // Duration for each reward distribution (1,209,600 seconds)
    uint32 public constant EPOCH_DURATION = 2 weeks;

    // Fee denominator
    uint32 public constant FEE_DENOMINATOR = 1_000_000;

    // Fee maximum
    uint32 public constant FEE_MAX = 100_000;

    // Maximum wait time for a BTRFLYV2 redemption (10,281,600 seconds)
    uint32 public constant MAX_REDEMPTION_TIME = 17 weeks;

    // Unused ERC1155 `data` param value
    bytes private constant UNUSED_1155_DATA = "";

    PxBtrfly public pxBtrfly;
    PirexFees public pirexFees;
    IRewardDistributor public rewardDistributor;
    ERC1155Solmate public upxBtrfly;
    ERC1155Solmate public spxBtrfly;
    ERC1155PresetMinterSupply public vpxBtrfly;
    ERC1155PresetMinterSupply public rpxBtrfly;
    UnionPirexVault public unionPirex;

    // Fees (e.g. 5000 / 1000000 = 0.5%)
    mapping(Fees => uint32) public fees;

    // BTRFLYV2 unlock timestamps mapped to amount being redeemed
    mapping(uint256 => uint256) public redemptions;

    // Reward forwarding mapping for the LPs
    mapping(address => address) public rewardForwarding;

    // Developers who are eligible for incentives as part of the new initiative
    // to enable builders to sustainably build apps for the Pirex ecosystem
    mapping(address => bool) public developers;

    // Emergency migration data
    EmergencyMigration public emergencyMigration;

    // Non-Pirex multisig which has authority to fulfill emergency procedures
    address public emergencyExecutor;

    // In the case of a mass unlock (ie. migration), the current upxBtrfly would be deprecated
    // and should allow holders to immediately redeem their BTRFLYV2 by burning upxBtrfly
    bool public upxBtrflyDeprecated;

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
    event ClaimReward(address indexed token, uint256 amount);
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
    event SetRewardForwarding(address account, address to);
    event UnsetRewardForwarding(address account);
    event InitializeEmergencyExecutor(address _emergencyExecutor);
    event SetEmergencyMigration(EmergencyMigration _emergencyMigration);
    event SetUpxBtrflyDeprecated(bool state);
    event ExecuteEmergencyMigration(address recipient, address[] tokens);

    error ZeroAmount();
    error BeforeUnlock();
    error InsufficientBalance();
    error AlreadyRedeemed();
    error InsufficientRedemptionAllowance();
    error PastExchangePeriod();
    error InvalidFee();
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
    error NotContract();
    error ForwardingNotSet();

    /**
        @param  _btrflyV2           address  BTRFLYV2 address    
        @param  _rlBtrfly           address  rlBTRFLY address
        @param  _pxBtrfly           address  PxBtrfly address
        @param  _upxBtrfly          address  UpxBtrfly address
        @param  _spxBtrfly          address  SpxBtrfly address
        @param  _vpxBtrfly          address  VpxBtrfly address
        @param  _rpxBtrfly          address  RpxBtrfly address
        @param  _pirexFees          address  PirexFees address
        @param  _rewardDistributor  address  RewardDistributor address
     */
    constructor(
        address _btrflyV2,
        address _rlBtrfly,
        address _pxBtrfly,
        address _upxBtrfly,
        address _spxBtrfly,
        address _vpxBtrfly,
        address _rpxBtrfly,
        address _pirexFees,
        address _rewardDistributor
    ) PirexBtrflyBase(_btrflyV2, _rlBtrfly) {
        // Init with paused state, should only unpause after fully perform the full setup
        _pause();

        if (_pxBtrfly == address(0)) revert ZeroAddress();
        if (_pirexFees == address(0)) revert ZeroAddress();
        if (_upxBtrfly == address(0)) revert ZeroAddress();
        if (_spxBtrfly == address(0)) revert ZeroAddress();
        if (_vpxBtrfly == address(0)) revert ZeroAddress();
        if (_rpxBtrfly == address(0)) revert ZeroAddress();
        if (_rewardDistributor == address(0)) revert ZeroAddress();

        pxBtrfly = PxBtrfly(_pxBtrfly);
        pirexFees = PirexFees(_pirexFees);
        upxBtrfly = ERC1155Solmate(_upxBtrfly);
        spxBtrfly = ERC1155Solmate(_spxBtrfly);
        vpxBtrfly = ERC1155PresetMinterSupply(_vpxBtrfly);
        rpxBtrfly = ERC1155PresetMinterSupply(_rpxBtrfly);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
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

        if (c == Contract.PxBtrfly) {
            pxBtrfly = PxBtrfly(contractAddress);
            return;
        }

        if (c == Contract.PirexFees) {
            pirexFees = PirexFees(contractAddress);
            return;
        }

        if (c == Contract.RewardDistributor) {
            rewardDistributor = IRewardDistributor(contractAddress);
            return;
        }

        if (c == Contract.UpxBtrfly) {
            upxBtrfly = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.SpxBtrfly) {
            spxBtrfly = ERC1155Solmate(contractAddress);
            return;
        }

        if (c == Contract.VpxBtrfly) {
            vpxBtrfly = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        if (c == Contract.RpxBtrfly) {
            rpxBtrfly = ERC1155PresetMinterSupply(contractAddress);
            return;
        }

        ERC20 pxBtrflyERC20 = ERC20(address(pxBtrfly));
        address oldUnionPirex = address(unionPirex);

        if (oldUnionPirex != address(0)) {
            pxBtrflyERC20.safeApprove(oldUnionPirex, 0);
        }

        unionPirex = UnionPirexVault(contractAddress);
        pxBtrflyERC20.safeApprove(address(unionPirex), type(uint256).max);
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
        @param  rounds    uint256  Rounds (i.e. Reward distribution rounds)
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

        ERC1155PresetMinterSupply token = f == Futures.Vote
            ? vpxBtrfly
            : rpxBtrfly;
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
        @notice Redeem BTRFLYV2 for specified unlock times
        @param  unlockTimes  uint256[]  rlBTRFLY unlock timestamps
        @param  assets       uint256[]  upxBTRFLY amounts
        @param  receiver     address    Receives BTRFLYV2
        @param  legacy       bool       Whether current upxBtrfly contract has been deprecated
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

        // Perform unlocking and locking procedure to ensure enough BTRFLYV2 is available
        if (!legacy) {
            _lock();
        }

        // Subtract redemption amount from outstanding BTRFLYV2 amount
        outstandingRedemptions -= totalAssets;

        // Reverts if sender has an insufficient upxBTRFLY balance for any `unlockTime` id
        upxBtrfly.burnBatch(msg.sender, unlockTimes, assets);

        // Validates `to`
        btrflyV2.safeTransfer(receiver, totalAssets);
    }

    /**
        @notice Redeem multiple snapshot rewards as a pxBTRFLY holder for an epoch
        @param  epoch          uint256    Epoch
        @param  rewardIndexes  uint256[]  Reward token indexes
        @param  account        address    pxBTRFLY holder
        @param  receiver       address    Reward receiver
    */
    function _redeemSnapshotRewards(
        uint256 epoch,
        uint256[] memory rewardIndexes,
        address account,
        address receiver
    ) internal {
        uint256 rewardLen = rewardIndexes.length;

        if (epoch == 0) revert InvalidEpoch();
        if (rewardLen == 0) revert EmptyArray();

        (
            uint256 snapshotId,
            bytes32[] memory rewards,
            uint256[] memory snapshotRewards,

        ) = pxBtrfly.getEpoch(epoch);

        // Used to update the redeemed flag locally before updating to the storage all at once for gas efficiency
        uint256 redeemed = pxBtrfly.getEpochRedeemedSnapshotRewards(
            account,
            epoch
        );

        // Check whether the holder maintained a positive balance before the snapshot
        uint256 snapshotBalance = pxBtrfly.balanceOfAt(account, snapshotId);
        uint256 snapshotSupply = pxBtrfly.totalSupplyAt(snapshotId);

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
            address token = address(uint160(bytes20(rewards[index])));
            uint256 rewardAmount = (snapshotRewards[index] * snapshotBalance) /
                snapshotSupply;

            if ((redeemed & indexRedeemed) != 0) revert AlreadyRedeemed();

            if (rewardAmount != 0) {
                redeemed |= indexRedeemed;

                ERC20(token).safeTransfer(receiver, rewardAmount);

                // Update pendingBaseRewards based on the claimed reward amount for BTRFLYV2
                if (token == address(btrflyV2)) {
                    pendingBaseRewards -= rewardAmount;
                }
            }
        }

        // Update the redeemed rewards flag in storage to prevent double claimings
        pxBtrfly.setEpochRedeemedSnapshotRewards(account, epoch, redeemed);
    }

    /**
        @notice Redeem futures rewards for rpxBTRFLY holders for an epoch
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  receiver  address  Receives futures rewards
    */
    function _redeemFuturesRewards(uint256 epoch, address receiver) internal {
        if (epoch == 0) revert InvalidEpoch();
        if (epoch > getCurrentEpoch()) revert InvalidEpoch();
        if (receiver == address(0)) revert ZeroAddress();

        // Prevent users from burning their futures notes before rewards are claimed
        (
            ,
            bytes32[] memory rewards,
            ,
            uint256[] memory futuresRewards
        ) = pxBtrfly.getEpoch(epoch);

        if (rewards.length == 0) revert NoRewards();

        emit RedeemFuturesRewards(epoch, receiver, rewards);

        // Check sender rpxBTRFLY balance
        uint256 rpxBtrflyBalance = rpxBtrfly.balanceOf(msg.sender, epoch);

        if (rpxBtrflyBalance == 0) revert InsufficientBalance();

        // Store rpxBTRFLY total supply before burning
        uint256 rpxBtrflyTotalSupply = rpxBtrfly.totalSupply(epoch);

        // Burn rpxBTRFLY tokens
        rpxBtrfly.burn(msg.sender, epoch, rpxBtrflyBalance);

        uint256 rLen = rewards.length;

        // Loop over rewards and transfer the amount entitled to the rpxBTRFLY token holder
        for (uint256 i; i < rLen; ++i) {
            address token = address(uint160(bytes20(rewards[i])));
            uint256 rewardAmount = (futuresRewards[i] * rpxBtrflyBalance) /
                rpxBtrflyTotalSupply;

            // Update reward amount by deducting the amount transferred to the receiver
            futuresRewards[i] -= rewardAmount;

            // Proportionate to the % of rpxBTRFLY owned out of the rpxBTRFLY total supply
            ERC20(token).safeTransfer(receiver, rewardAmount);

            // Update pendingBaseRewards based on the claimed reward amount for BTRFLYV2 rewards
            if (token == address(btrflyV2)) {
                pendingBaseRewards -= rewardAmount;
            }
        }

        // Update future rewards to reflect the amounts remaining post-redemption
        pxBtrfly.updateEpochFuturesRewards(epoch, futuresRewards);
    }

    /**
        @notice  Get reward indexes for the specified epoch
        @param   epoch          uint256    Epoch
        @return  rewardIndexes  uint256[]  Reward token indexes
    */
    function _getRewardIndexes(uint256 epoch)
        internal
        view
        returns (uint256[] memory rewardIndexes)
    {
        (, bytes32[] memory rewards, , ) = pxBtrfly.getEpoch(epoch);

        uint256 tLen = rewards.length;
        rewardIndexes = new uint256[](tLen);

        for (uint256 i; i < tLen; ++i) {
            rewardIndexes[i] = i;
        }
    }

    /**
        @notice Calculate rewards
        @param  feePercent       uint32   Reward fee percent
        @param  snapshotSupply   uint256  pxBTRFLY supply for the current snapshot id
        @param  rpxBtrflySupply  uint256  rpxBTRFLY supply for the current epoch
        @param  received         uint256  Received amount
        @return rewardFee        uint256  Fee for protocol
        @return snapshotRewards  uint256  Rewards for pxBTRFLY token holders
        @return futuresRewards   uint256  Rewards for futures token holders
    */
    function _calculateRewards(
        uint32 feePercent,
        uint256 snapshotSupply,
        uint256 rpxBtrflySupply,
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
            (snapshotSupply + rpxBtrflySupply);

        // Rewards distributed to rpxBTRFLY token holders
        futuresRewards = rewards - snapshotRewards;
    }

    /**
        @notice Deposit BTRFLYV2
        @param  assets          uint256  BTRFLYV2 amount
        @param  receiver        address  Receives pxBTRFLY
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

        // Track amount of BTRFLYV2 waiting to be locked before `assets` is modified
        pendingLocks += assets;

        // Calculate the dev incentive, which will come out of the minted pxBTRFLY
        uint256 developerIncentive = developer != address(0) &&
            developers[developer]
            ? (assets * fees[Fees.Developers]) / FEE_DENOMINATOR
            : 0;

        // Take snapshot if necessary
        pxBtrfly.takeEpochSnapshot();

        // Mint pxBTRFLY sans developer incentive - recipient depends on shouldCompound
        pxBtrfly.mint(
            shouldCompound ? address(this) : receiver,
            assets - developerIncentive
        );

        // Transfer BTRFLYV2 to self in preparation for lock
        btrflyV2.safeTransferFrom(msg.sender, address(this), assets);

        if (developerIncentive != 0) {
            // Mint pxBTRFLY for the developer
            pxBtrfly.mint(developer, developerIncentive);
        }

        if (shouldCompound) {
            // Update assets to ensure only the appropriate amount is deposited in vault
            assets -= developerIncentive;

            // Deposit pxBTRFLY into Union vault - user receives shares
            unionPirex.deposit(assets, receiver);
        }
    }

    /**
        @notice Initiate BTRFLYV2 redemption
        @param  lockData   IRLBTRFLY.LockedBalance  Locked balance index
        @param  f          enum                     Futures enum
        @param  assets     uint256                  pxBTRFLY amount
        @param  receiver   address                  Receives upxBTRFLY
        @param  feeMin     uint256                  Initiate redemption fee min
        @param  feeMax     uint256                  Initiate redemption fee max
        @return feeAmount  uint256                  Fee amount
     */
    function _initiateRedemption(
        IRLBTRFLY.LockedBalance memory lockData,
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

        // Mint upxBTRFLY with unlockTime as the id - validates `to`
        upxBtrfly.mint(receiver, unlockTime, postFeeAmount, UNUSED_1155_DATA);

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

        // Mint vpxBTRFLY or rpxBTRFLY (using assets as we do not take a fee from this)
        _mintFutures(rounds, f, assets, receiver);

        return feeAmount;
    }

    /**
        @notice Initiate BTRFLYV2 redemptions
        @param  lockIndexes  uint256[]  Locked balance index
        @param  f            enum       Futures enum
        @param  assets       uint256[]  pxBTRFLY amounts
        @param  receiver     address    Receives upxBTRFLY
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

        (, , , IRLBTRFLY.LockedBalance[] memory lockData) = rlBtrfly
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

        // Burn pxBTRFLY - reverts if sender balance is insufficient
        pxBtrfly.burn(msg.sender, totalAssets - feeAmount);

        if (feeAmount != 0) {
            // Allow PirexFees to distribute fees directly from sender
            pxBtrfly.operatorApprove(msg.sender, address(pirexFees), feeAmount);

            // Distribute fees
            pirexFees.distributeFees(msg.sender, address(pxBtrfly), feeAmount);
        }
    }

    /**
        @notice Redeem BTRFLYV2 for specified unlock times
        @param  unlockTimes  uint256[]  BTRFLYV2 unlock timestamps
        @param  assets       uint256[]  upxBTRFLY amounts
        @param  receiver     address    Receives BTRFLYV2
     */
    function redeem(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (upxBtrflyDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, false);
    }

    /**
        @notice Redeem BTRFLYV2 for deprecated upxBTRFLY holders if enabled
        @param  unlockTimes  uint256[]  BTRFLYV2 unlock timestamps
        @param  assets       uint256[]  upxBTRFLY amounts
        @param  receiver     address    Receives BTRFLYV2
     */
    function redeemLegacy(
        uint256[] calldata unlockTimes,
        uint256[] calldata assets,
        address receiver
    ) external whenPaused nonReentrant {
        if (!upxBtrflyDeprecated) revert RedeemClosed();

        _redeem(unlockTimes, assets, receiver, true);
    }

    /**
        @notice Stake pxBTRFLY
        @param  rounds    uint256  Rounds (i.e. Reward distribution rounds)
        @param  f         enum     Futures enum
        @param  assets    uint256  pxBTRFLY amount
        @param  receiver  address  Receives spxBTRFLY
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

        // Burn pxBTRFLY
        pxBtrfly.burn(msg.sender, assets);

        emit Stake(rounds, f, assets, receiver);

        // Mint spxBTRFLY with the stake expiry timestamp as the id
        spxBtrfly.mint(
            receiver,
            getCurrentEpoch() + EPOCH_DURATION * rounds,
            assets,
            UNUSED_1155_DATA
        );

        _mintFutures(rounds, f, assets, receiver);
    }

    /**
        @notice Unstake pxBTRFLY
        @param  id        uint256  spxBTRFLY id (an epoch timestamp)
        @param  assets    uint256  spxBTRFLY amount
        @param  receiver  address  Receives pxBTRFLY
    */
    function unstake(
        uint256 id,
        uint256 assets,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (id > block.timestamp) revert BeforeStakingExpiry();
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        // Mint pxBTRFLY for receiver
        pxBtrfly.mint(receiver, assets);

        emit Unstake(id, assets, receiver);

        // Burn spxBTRFLY from sender
        spxBtrfly.burn(msg.sender, id, assets);
    }

    /**
        @notice Claim multiple rewards from the RewardDistributor
        @param  claims  Claim[]  Rewards metadata
    */
    function claimRewards(IRewardDistributor.Claim[] calldata claims)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 tLen = claims.length;

        if (tLen == 0) revert EmptyArray();

        // Take snapshot before claiming rewards, if necessary
        pxBtrfly.takeEpochSnapshot();

        uint256 epoch = getCurrentEpoch();
        (uint256 snapshotId, , , ) = pxBtrfly.getEpoch(epoch);
        uint256 rpxBtrflySupply = rpxBtrfly.totalSupply(epoch);

        for (uint256 i; i < tLen; ++i) {
            address token = claims[i].token;
            uint256 amount = claims[i].amount;
            bytes32[] memory merkleProof = claims[i].merkleProof;
            ERC20 t = ERC20(token);

            if (token == address(0)) revert ZeroAddress();

            // Calculate actual claimable amount here
            // as the `amount` param is a cumulative amount since the first reward
            uint256 claimable = amount -
                pxBtrfly.cumulativeRewardsByToken(token);

            if (claimable == 0) revert ZeroAmount();

            // Perform claim only when needed
            if (rewardDistributor.claimed(token, address(this)) < amount) {
                IRewardDistributor.Claim[]
                    memory params = new IRewardDistributor.Claim[](1);
                params[0].token = token;
                params[0].account = address(this);
                params[0].amount = amount;
                params[0].merkleProof = merkleProof;

                // Validates `token`, `amount`, and `merkleProof`
                rewardDistributor.claim(params);
            }

            // Keep track of the last claimed amount for each reward token
            pxBtrfly.updateCumulativeRewardsByToken(token, amount);

            emit ClaimReward(token, amount);

            (
                uint256 rewardFee,
                uint256 snapshotRewards,
                uint256 futuresRewards
            ) = _calculateRewards(
                    fees[Fees.Reward],
                    pxBtrfly.totalSupplyAt(snapshotId),
                    rpxBtrflySupply,
                    claimable
                );

            // Update pendingBaseReward to exclude claimed BTRFLYV2 from being locked
            if (token == address(btrflyV2)) {
                pendingBaseRewards += snapshotRewards + futuresRewards;
            }

            // Add reward token address and snapshot/futuresRewards amounts (same index for all)
            pxBtrfly.addEpochRewardMetadata(
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
        @notice Redeem multiple snapshot rewards as a pxBTRFLY holder for an epoch
        @param  epoch          uint256    Epoch
        @param  rewardIndexes  uint256[]  Reward token indexes
        @param  receiver        address   Reward receiver
    */
    function redeemSnapshotRewards(
        uint256 epoch,
        uint256[] calldata rewardIndexes,
        address receiver
    ) external whenNotPaused nonReentrant {
        if (receiver == address(0)) revert ZeroAddress();

        _redeemSnapshotRewards(epoch, rewardIndexes, msg.sender, receiver);
    }

    /**
        @notice Restricted method to redeem snapshot rewards on behalf of an LP contract for an epoch
        @param  epoch          uint256    Epoch
        @param  rewardIndexes  uint256[]  Reward token indexes
        @param  lpContract     address    LP contract address
    */
    function redeemSnapshotRewardsPrivileged(
        uint256 epoch,
        uint256[] calldata rewardIndexes,
        address lpContract
    ) external whenNotPaused nonReentrant onlyOwner {
        address receiver = rewardForwarding[lpContract];

        if (receiver == address(0)) revert ForwardingNotSet();

        _redeemSnapshotRewards(epoch, rewardIndexes, lpContract, receiver);
    }

    /**
        @notice Bulk redeem snapshot rewards as a pxBTRFLY holder for multiple epochs
        @param  epochs    uint256[]  Epochs
        @param  receiver  address   Reward receiver
    */
    function bulkRedeemSnapshotRewards(
        uint256[] calldata epochs,
        address receiver
    ) external whenNotPaused nonReentrant {
        uint256 eLen = epochs.length;

        if (eLen == 0) revert EmptyArray();
        if (receiver == address(0)) revert ZeroAddress();

        for (uint256 i; i < eLen; ++i) {
            uint256 epoch = epochs[i];

            _redeemSnapshotRewards(
                epoch,
                _getRewardIndexes(epoch),
                msg.sender,
                receiver
            );
        }
    }

    /**
        @notice Restricted method to bulk redeem snapshot rewards on behalf of an LP contract for multiple epochs
        @param  epochs      uint256[]  Epochs
        @param  lpContract  address    LP contract address
    */
    function bulkRedeemSnapshotRewardsPrivileged(
        uint256[] calldata epochs,
        address lpContract
    ) external whenNotPaused nonReentrant onlyOwner {
        uint256 eLen = epochs.length;
        address receiver = rewardForwarding[lpContract];

        if (eLen == 0) revert EmptyArray();
        if (receiver == address(0)) revert ForwardingNotSet();

        for (uint256 i; i < eLen; ++i) {
            uint256 epoch = epochs[i];

            _redeemSnapshotRewards(
                epoch,
                _getRewardIndexes(epoch),
                lpContract,
                receiver
            );
        }
    }

    /**
        @notice Redeem futures rewards for rpxBTRFLY holders for an epoch
        @param  epoch     uint256  Epoch (ERC1155 token id)
        @param  receiver  address  Receives futures rewards
    */
    function redeemFuturesRewards(uint256 epoch, address receiver)
        external
        whenNotPaused
        nonReentrant
    {
        _redeemFuturesRewards(epoch, receiver);
    }

    /**
        @notice Bulk redeem futures rewards for rpxBTRFLY holders for multiple epochs
        @param  epochs    uint256[]  Epochs (ERC1155 token ids)
        @param  receiver  address    Receives futures rewards
    */
    function bulkRedeemFuturesRewards(
        uint256[] calldata epochs,
        address receiver
    ) external whenNotPaused nonReentrant {
        uint256 eLen = epochs.length;

        if (eLen == 0) revert EmptyArray();

        for (uint256 i; i < eLen; ++i) {
            _redeemFuturesRewards(epochs[i], receiver);
        }
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
            ? vpxBtrfly
            : rpxBtrfly;
        ERC1155PresetMinterSupply futuresOut = f == Futures.Vote
            ? rpxBtrfly
            : vpxBtrfly;

        emit ExchangeFutures(epoch, amount, receiver, f);

        // Validates `amount` (balance)
        futuresIn.burn(msg.sender, epoch, amount);

        // Validates `to`
        futuresOut.mint(receiver, epoch, amount, UNUSED_1155_DATA);
    }

    /**
        @notice Restricted method to set reward forwarding for LPs
        @param  lpContract  address  LP contract address
        @param  to          address  Account that rewards will be sent to
     */
    function setRewardForwarding(address lpContract, address to)
        external
        onlyOwner
    {
        if (lpContract.code.length == 0) revert NotContract();
        if (to == address(0)) revert ZeroAddress();

        rewardForwarding[lpContract] = to;

        emit SetRewardForwarding(lpContract, to);
    }

    /**
        @notice Restricted method to unset reward forwarding for LPs
        @param  lpContract  address  LP contract address
     */
    function unsetRewardForwarding(address lpContract) external onlyOwner {
        if (lpContract.code.length == 0) revert NotContract();

        delete rewardForwarding[lpContract];

        emit UnsetRewardForwarding(lpContract);
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

            if (token == btrflyV2) {
                // Transfer the diff between BTRFLYV2 balance and outstandingRedemptions
                balance = balance > o ? balance - o : 0;
            }

            token.safeTransfer(migrationRecipient, balance);
        }

        emit ExecuteEmergencyMigration(migrationRecipient, migrationTokens);
    }

    /**
        @notice Set whether the currently set upxBtrfly contract is deprecated or not
        @param  state  bool  Deprecation state
     */
    function setUpxBtrflyDeprecated(bool state) external onlyOwner whenPaused {
        upxBtrflyDeprecated = state;

        emit SetUpxBtrflyDeprecated(state);
    }
}