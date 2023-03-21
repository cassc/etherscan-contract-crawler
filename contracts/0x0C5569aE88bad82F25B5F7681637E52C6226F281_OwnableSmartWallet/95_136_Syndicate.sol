pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ISyndicateInit } from "../interfaces/ISyndicateInit.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";
import {
    ZeroAddress,
    EmptyArray,
    InconsistentArrayLengths,
    InvalidBLSPubKey,
    InvalidNumberOfCollateralizedOwners,
    KnotSlashed,
    FreeFloatingStakeAmountTooSmall,
    KnotIsNotRegisteredWithSyndicate,
    NotPriorityStaker,
    KnotIsFullyStakedWithFreeFloatingSlotTokens,
    InvalidStakeAmount,
    KnotIsNotAssociatedWithAStakeHouse,
    UnableToStakeFreeFloatingSlot,
    NothingStaked,
    TransferFailed,
    NotCollateralizedOwnerAtIndex,
    InactiveKnot,
    DuplicateArrayElements,
    KnotIsAlreadyRegistered,
    KnotHasAlreadyBeenDeRegistered,
    NotKickedFromBeaconChain
} from "./SyndicateErrors.sol";

interface IExtendedAccountManager {
    function blsPublicKeyToLastState(bytes calldata _blsPublicKey) external view returns (
        bytes memory, // BLS public key
        bytes memory, // Withdrawal credentials
        bool,  // Slashed
        uint64,// Active balance
        uint64,// Effective balance
        uint64,// Exit epoch
        uint64,// Activation epoch
        uint64,// Withdrawal epoch
        uint64 // Current checkpoint epoch
    );
}

/// @notice Syndicate registry and funds splitter for EIP1559 execution layer transaction tips across SLOT shares
/// @dev This contract can be extended to allow lending and borrowing of time slots for borrower to redeem any revenue generated within the specified window
contract Syndicate is ISyndicateInit, Initializable, Ownable, ReentrancyGuard, StakehouseAPI, ETHTransferHelper {

    /// @notice Emitted when the contract is initially deployed
    event ContractDeployed();

    /// @notice Emitted when accrued ETH per SLOT share type is updated
    event UpdateAccruedETH(uint256 unprocessed);

    /// @notice Emitted when new collateralized SLOT owners for a knot prompts re-calibration
    event CollateralizedSLOTReCalibrated(bytes BLSPubKey);

    /// @notice Emitted when a new KNOT is associated with the syndicate contract
    event KNOTRegistered(bytes BLSPubKey);

    /// @notice Emitted when a KNOT is de-registered from the syndicate
    event KnotDeRegistered(bytes BLSPubKey);

    /// @notice Emitted when a priority staker is added to the syndicate
    event PriorityStakerRegistered(address indexed staker);

    /// @notice Emitted when a user stakes free floating sETH tokens
    event Staked(bytes BLSPubKey, uint256 amount);

    /// @notice Emitted when a user unstakes free floating sETH tokens
    event UnStaked(bytes BLSPubKey, uint256 amount);

    /// @notice Emitted when either an sETH staker or collateralized SLOT owner claims ETH
    event ETHClaimed(bytes BLSPubKey, address indexed user, address recipient, uint256 claim, bool indexed isCollateralizedClaim);

    /// @notice Emitted when the owner specifies a new activation distance
    event ActivationDistanceUpdated();

    /// @notice Precision used in rewards calculations for scaling up and down
    uint256 public constant PRECISION = 1e24;

    /// @notice Total accrued ETH per free floating share for new and old stakers
    uint256 public accumulatedETHPerFreeFloatingShare;

    /// @notice Total accrued ETH for all collateralized SLOT holders per knot which is then distributed based on individual balances
    uint256 public accumulatedETHPerCollateralizedSlotPerKnot;

    /// @notice Last cached highest seen balance for all collateralized shares
    uint256 public lastSeenETHPerCollateralizedSlotPerKnot;

    /// @notice Last cached highest seen balance for all free floating shares
    uint256 public lastSeenETHPerFreeFloating;

    /// @notice Total number of sETH token shares staked across all houses
    uint256 public totalFreeFloatingShares;

    /// @notice Total amount of ETH drawn down by syndicate beneficiaries regardless of SLOT type
    uint256 public totalClaimed;

    /// @notice Number of knots registered with the syndicate which can be across any house
    uint256 public numberOfActiveKnots;

    /// @notice Informational - is the knot registered to this syndicate or not - the node should point to this contract
    mapping(bytes => bool) public isKnotRegistered;

    /// @notice Block number after which if there are sETH staking slots available, it can be supplied by anyone on the market
    uint256 public priorityStakingEndBlock;

    /// @notice Syndicate deployer can highlight addresses that get priority for staking free floating house sETH up to a certain block before anyone can do it
    mapping(address => bool) public isPriorityStaker;

    /// @notice Total amount of free floating sETH staked
    mapping(bytes => uint256) public sETHTotalStakeForKnot;

    /// @notice Amount of sETH staked by user against a knot
    mapping(bytes => mapping(address => uint256)) public sETHStakedBalanceForKnot;

    /// @notice Amount of ETH claimed by user from sETH staking
    mapping(bytes => mapping(address => uint256)) public sETHUserClaimForKnot;

    /// @notice Total amount of ETH that has been allocated to the collateralized SLOT owners of a KNOT
    mapping(bytes => uint256) public totalETHProcessedPerCollateralizedKnot;

    /// @notice Total amount of ETH accrued for the collateralized SLOT owner of a KNOT
    mapping(bytes => mapping(address => uint256)) public accruedEarningPerCollateralizedSlotOwnerOfKnot;

    /// @notice Total amount of ETH claimed by the collateralized SLOT owner of a KNOT
    mapping(bytes => mapping(address => uint256)) public claimedPerCollateralizedSlotOwnerOfKnot;

    /// @notice Whether a BLS public key, that has been previously registered, is no longer part of the syndicate and its shares (free floating or SLOT) cannot earn any more rewards
    mapping(bytes => bool) public isNoLongerPartOfSyndicate;

    /// @notice Once a BLS public key is no longer part of the syndicate, the accumulated ETH per free floating SLOT share is snapshotted so historical earnings can be drawn down correctly
    mapping(bytes => uint256) public lastAccumulatedETHPerFreeFloatingShare;

    /// @notice Future activation block of a KNOT i.e. from what block they can start to accrue rewards. Enforced delay to protect against dilution
    mapping(bytes => uint256) public activationBlock;

    /// @notice List of proposers that required historical activation
    bytes[] public proposersToActivate;

    /// @notice Distance in blocks new proposers must wait before being able to receive Syndicate rewards
    uint256 public activationDistance;

    /// @notice Monotonically increasing pointer used to track which proposers have been activated
    uint256 public activationPointer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _contractOwner Ethereum public key that will receive management rights of the contract
    /// @param _priorityStakingEndBlock Block number when priority sETH staking ends and anyone can stake
    /// @param _priorityStakers Optional list of addresses that will have priority for staking sETH against each knot registered
    /// @param _blsPubKeysForSyndicateKnots List of BLS public keys of Stakehouse protocol registered KNOTs participating in syndicate
    function initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) external virtual override initializer {
        _initialize(
            _contractOwner,
            _priorityStakingEndBlock,
            _priorityStakers,
            _blsPubKeysForSyndicateKnots
        );
    }

    /// @notice Allows the contract owner to append to the list of knots that are part of the syndicate
    /// @param _newBLSPublicKeyBeingRegistered List of BLS public keys being added to the syndicate
    function registerKnotsToSyndicate(
        bytes[] calldata _newBLSPublicKeyBeingRegistered
    ) external onlyOwner {
        // update accrued ETH per SLOT type
        activateProposers();
        _registerKnotsToSyndicate(_newBLSPublicKeyBeingRegistered);
    }

    /// @notice Make knot shares of a registered list of BLS public keys inactive - the action cannot be undone and no further ETH accrued
    function deRegisterKnots(bytes[] calldata _blsPublicKeys) external onlyOwner {
        _deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allow syndicate users to inform the contract that a beacon chain kicking has taken place -
    /// @notice The associated SLOT shares should not continue to earn pro-rata shares
    /// @param _blsPublicKeys List of BLS keys reported to the Stakehouse protocol
    function informSyndicateKnotsAreKickedFromBeaconChain(bytes[] calldata _blsPublicKeys) external {
        for (uint256 i; i < _blsPublicKeys.length; ++i) {
            (,,bool slashed,,,,,,) = IExtendedAccountManager(address(getAccountManager())).blsPublicKeyToLastState(
                _blsPublicKeys[i]
            );

            if (!slashed) revert NotKickedFromBeaconChain();
        }

        _deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allows the contract owner to append to the list of priority sETH stakers
    /// @param _priorityStakers List of staker addresses eligible for sETH staking
    function addPriorityStakers(address[] calldata _priorityStakers) external onlyOwner {
        activateProposers();
        _addPriorityStakers(_priorityStakers);
    }

    /// @notice Should this block be in the future, it means only those listed in the priority staker list can stake sETH
    /// @param _endBlock Arbitrary block number after which anyone can stake up to 4 SLOT in sETH per KNOT
    function updatePriorityStakingBlock(uint256 _endBlock) external onlyOwner {
        activateProposers();
        priorityStakingEndBlock = _endBlock;
    }

    /// @notice Allow syndicate owner to manage activation distance for new proposers
    function updateActivationDistanceInBlocks(uint256 _distance) external onlyOwner {
        activationDistance = _distance;
        emit ActivationDistanceUpdated();
    }

    /// @notice Total number knots that registered with the syndicate
    function numberOfRegisteredKnots() external view returns (uint256) {
        return proposersToActivate.length;
    }

    /// @notice Total number of registered proposers that are yet to be activated
    function totalProposersToActivate() external view returns (uint256) {
        return proposersToActivate.length - activationPointer;
    }

    /// @notice Allow for a fixed number of proposers to be activated to start earning pro-rata ETH
    function activateProposers() public {
        // Snapshot historical earnings
        if (numberOfActiveKnots > 0) {
            updateAccruedETHPerShares();
        }

        // Retrieve number of proposers to activate capping total number that are activated
        uint256 currentActivated = numberOfActiveKnots;
        uint256 numToActivate = proposersToActivate.length - activationPointer;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        while (numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[activationPointer];

            // The expectation is that everyone in the queue of proposers to activate have increasing activation block numbers
            if (block.number < activationBlock[blsPublicKey]) {
                break;
            }

            totalFreeFloatingShares += sETHTotalStakeForKnot[blsPublicKey];

            // incoming knot collateralized SLOT holders do not get historical earnings
            totalETHProcessedPerCollateralizedKnot[blsPublicKey] = accumulatedETHPerCollateralizedSlotPerKnot;

            // incoming knot free floating SLOT holders do not get historical earnings
            lastAccumulatedETHPerFreeFloatingShare[blsPublicKey] = accumulatedETHPerFreeFloatingShare;

            numberOfActiveKnots += 1;
            activationPointer += 1;
            numToActivate -= 1;
        }

        if (currentActivated == 0) {
            updateAccruedETHPerShares();
        }
    }

    /// @notice Update accrued ETH per SLOT share without distributing ETH as users of the syndicate individually pull funds
    function updateAccruedETHPerShares() public {
        // Ensure there are registered KNOTs. Syndicates are deployed with at least 1 registered but this can fall to zero.
        // Fee recipient should be re-assigned in the event that happens as any further ETH can be collected by owner
        if (numberOfActiveKnots > 0) {
            // All time, total ETH that was earned per slot type (free floating or collateralized)
            uint256 totalEthPerSlotType = calculateETHForFreeFloatingOrCollateralizedHolders();

            // Process free floating if there are staked shares
            uint256 freeFloatingUnprocessed;
            if (totalFreeFloatingShares > 0) {
                freeFloatingUnprocessed = getUnprocessedETHForAllFreeFloatingSlot();
                accumulatedETHPerFreeFloatingShare += _calculateNewAccumulatedETHPerFreeFloatingShare(freeFloatingUnprocessed, false);
                lastSeenETHPerFreeFloating = totalEthPerSlotType;
            }

            uint256 collateralizedUnprocessed = ((totalEthPerSlotType - lastSeenETHPerCollateralizedSlotPerKnot) / numberOfActiveKnots);
            accumulatedETHPerCollateralizedSlotPerKnot += collateralizedUnprocessed;
            lastSeenETHPerCollateralizedSlotPerKnot = totalEthPerSlotType;

            emit UpdateAccruedETH(freeFloatingUnprocessed + collateralizedUnprocessed);
        }
    }

    /// @notice Stake up to 4 collateralized SLOT worth of sETH per KNOT to get a portion of syndicate rewards
    /// @param _blsPubKeys List of BLS public keys for KNOTs registered with the syndicate
    /// @param _sETHAmounts Per BLS public key, the total amount of sETH that will be staked (up to 4 collateralized SLOT per KNOT)
    /// @param _onBehalfOf Allows a caller to specify an address that will be assigned stake ownership and rights to claim
    function stake(bytes[] calldata _blsPubKeys, uint256[] calldata _sETHAmounts, address _onBehalfOf) external {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (numOfKeys != _sETHAmounts.length) revert InconsistentArrayLengths();
        if (_onBehalfOf == address(0)) revert ZeroAddress();

        // Make sure we have the latest accrued information
        activateProposers();

        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            uint256 _sETHAmount = _sETHAmounts[i];

            if (_sETHAmount < 1 gwei) revert FreeFloatingStakeAmountTooSmall();
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (isNoLongerPartOfSyndicate[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();

            if (block.number < priorityStakingEndBlock && !isPriorityStaker[_onBehalfOf]) revert NotPriorityStaker();

            uint256 totalStaked = sETHTotalStakeForKnot[_blsPubKey];
            if (totalStaked == 12 ether) revert KnotIsFullyStakedWithFreeFloatingSlotTokens();

            if (_sETHAmount + totalStaked > 12 ether) revert InvalidStakeAmount();

            if (block.number > activationBlock[_blsPubKey]) {
                // Pre activation block we cannot increase but post activation we need to instantly increase shares
                totalFreeFloatingShares += _sETHAmount;
            }

            sETHTotalStakeForKnot[_blsPubKey] += _sETHAmount;
            sETHStakedBalanceForKnot[_blsPubKey][_onBehalfOf] += _sETHAmount;
            sETHUserClaimForKnot[_blsPubKey][_onBehalfOf] += (_sETHAmount * accumulatedETHPerFreeFloatingShare) / PRECISION;

            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);
            if (stakeHouse == address(0)) revert KnotIsNotAssociatedWithAStakeHouse();
            if (!isActive) revert InactiveKnot();

            IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakeHouse));

            bool transferResult = sETH.transferFrom(msg.sender, address(this), _sETHAmount);
            if (!transferResult) revert UnableToStakeFreeFloatingSlot();

            emit Staked(_blsPubKey, _sETHAmount);
        }
    }

    /// @notice Unstake an sETH position against a particular KNOT and claim ETH on exit
    /// @param _unclaimedETHRecipient The address that will receive any unclaimed ETH received to the syndicate
    /// @param _sETHRecipient The address that will receive the sETH that is being unstaked
    /// @param _blsPubKeys List of BLS public keys for KNOTs registered with the syndicate
    /// @param _sETHAmounts Per BLS public key, the total amount of sETH that will be unstaked
    function unstake(
        address _unclaimedETHRecipient,
        address _sETHRecipient,
        bytes[] calldata _blsPubKeys,
        uint256[] calldata _sETHAmounts
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (numOfKeys != _sETHAmounts.length) revert InconsistentArrayLengths();
        if (_unclaimedETHRecipient == address(0)) revert ZeroAddress();
        if (_sETHRecipient == address(0)) revert ZeroAddress();

        // Claim all ETH owed before unstaking but even if nothing is owed `updateAccruedETHPerShares` will be called
        _claimAsStaker(_unclaimedETHRecipient, _blsPubKeys);

        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            uint256 _sETHAmount = _sETHAmounts[i];
            if (sETHStakedBalanceForKnot[_blsPubKey][msg.sender] < _sETHAmount) revert NothingStaked();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);
            IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakeHouse));

            // Only decrease totalFreeFloatingShares in the event that the knot is still active in the syndicate
            if (!isNoLongerPartOfSyndicate[_blsPubKey]) {
                totalFreeFloatingShares -= _sETHAmount;
            }

            sETHTotalStakeForKnot[_blsPubKey] -= _sETHAmount;
            sETHStakedBalanceForKnot[_blsPubKey][msg.sender] -= _sETHAmount;

            uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);
            sETHUserClaimForKnot[_blsPubKey][msg.sender] =
                (accumulatedETHPerShare * sETHStakedBalanceForKnot[_blsPubKey][msg.sender]) / PRECISION;

            // If the stakehouse lets the syndicate know the knot is no longer active, kick knot from syndicate to prevent more rewards being earned
            if (!isNoLongerPartOfSyndicate[_blsPubKey] && !isActive) {
                _deRegisterKnot(_blsPubKey);
            }

            bool transferResult = sETH.transfer(_sETHRecipient, _sETHAmount);
            if (!transferResult) revert TransferFailed();

            emit UnStaked(_blsPubKey, _sETHAmount);
        }
    }

    /// @notice Claim ETH cashflow from the syndicate as an sETH staker proportional to how much the user has staked
    /// @param _recipient Address that will receive the share of ETH funds
    /// @param _blsPubKeys List of BLS public keys that the caller has staked against
    function claimAsStaker(address _recipient, bytes[] calldata _blsPubKeys) public nonReentrant {
        _claimAsStaker(_recipient, _blsPubKeys);
    }

    /// @param _blsPubKeys List of BLS public keys that the caller has staked against
    function claimAsCollateralizedSLOTOwner(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();
        if (_recipient == address(this)) revert ZeroAddress();

        // Make sure we have the latest accrued information for all shares
        activateProposers();

        uint256 totalToTransfer;
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            // process newly accrued ETH and distribute it to collateralized SLOT owners for the given knot
            _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKey);

            // Calculate total amount of unclaimed ETH
            uint256 userShare = accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender];

            // This is designed to cope with falling SLOT balances i.e. when collateralized SLOT is burnt after applying penalties
            uint256 unclaimedUserShare = userShare - claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender];

            // Send ETH to the user if there is an unclaimed amount
            if (unclaimedUserShare > 0) {
                // Increase total claimed and claimed at the user level
                totalClaimed += unclaimedUserShare;
                claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender] = userShare;

                // Send ETH to user
                totalToTransfer += unclaimedUserShare;

                emit ETHClaimed(
                    _blsPubKey,
                    msg.sender,
                    _recipient,
                    unclaimedUserShare,
                    true
                );
            }
        }

        _transferETH(_recipient, totalToTransfer);
    }

    /// @notice For any new ETH received by the syndicate, at the knot level allocate ETH owed to each collateralized owner
    /// @param _blsPubKey BLS public key relating to the collateralized owners that need updating
    function updateCollateralizedSlotOwnersAccruedETH(bytes memory _blsPubKey) external {
        activateProposers();
        _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKey);
    }

    /// @notice For any new ETH received by the syndicate, at the knot level allocate ETH owed to each collateralized owner and do it for a batch of knots
    /// @param _blsPubKeys List of BLS public keys related to the collateralized owners that need updating
    function batchUpdateCollateralizedSlotOwnersAccruedETH(bytes[] memory _blsPubKeys) external {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        activateProposers();
        for (uint256 i; i < numOfKeys; ++i) {
            _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKeys[i]);
        }
    }

    /// @notice Syndicate contract can receive ETH
    receive() external payable {
        // No logic here because one cannot assume that more than 21K GAS limit is forwarded
    }

    /// @notice Calculate the amount of unclaimed ETH for a given BLS publice key + free floating SLOT staker without factoring in unprocessed rewards
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    /// @param _user The address of a user that has staked sETH against the BLS public key
    function calculateUnclaimedFreeFloatingETHShare(bytes memory _blsPubKey, address _user) public view returns (uint256) {
        // Check the user has staked sETH for the KNOT
        uint256 stakedBal = sETHStakedBalanceForKnot[_blsPubKey][_user];

        // Get the amount of ETH eligible for the user based on their staking amount
        uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);
        uint256 userShare = (accumulatedETHPerShare * stakedBal) / PRECISION;

        // When the user is claiming ETH from the syndicate for the first time, we need to adjust for the activation
        // This will ensure that rewards accrued before activation are not considered
        uint256 adjustedClaimForActivation;
        if (!isNoLongerPartOfSyndicate[_blsPubKey] && sETHUserClaimForKnot[_blsPubKey][_user] == 0) {
            adjustedClaimForActivation = (lastAccumulatedETHPerFreeFloatingShare[_blsPubKey] * stakedBal) / PRECISION;
        }

        // Calculate how much their unclaimed share of ETH is based on total ETH claimed so far
        return userShare - sETHUserClaimForKnot[_blsPubKey][_user] - adjustedClaimForActivation;
    }

    /// @notice Using `highestSeenBalance`, this is the amount that is separately allocated to either free floating or collateralized SLOT holders
    function calculateETHForFreeFloatingOrCollateralizedHolders() public view returns (uint256) {
        // Get total amount of ETH that can be drawn down by all SLOT holders associated with a knot
        uint256 ethPerKnot = totalETHReceived();

        // Get the amount of ETH eligible for free floating sETH or collateralized SLOT stakers
        return ethPerKnot / 2;
    }

    /// @notice Preview how many proposers can be activated either manually or when the accrued ETH per shares are updated
    function previewActivateableProposers() public view returns (uint256) {
        uint256 index = activationPointer;
        uint256 numToActivate = proposersToActivate.length - index;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        uint256 numOfActivateable;
        while(numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[index];

            if (block.number < activationBlock[blsPublicKey]) {
                break;
            } else {
                numOfActivateable += 1;
            }

            index += 1;
            numToActivate -= 1;
        }

        return numOfActivateable;
    }

    /// @notice Total free floating shares that can be activated in the next block
    function previewTotalFreeFloatingSharesToActivate() public view returns (uint256) {
        uint256 index = activationPointer;
        uint256 numToActivate = proposersToActivate.length - index;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        uint256 totalSharesToActivate;
        while(numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[index];

            if (block.number < activationBlock[blsPublicKey]) {
                break;
            } else {
                totalSharesToActivate += sETHTotalStakeForKnot[blsPublicKey];
            }

            index += 1;
            numToActivate -= 1;
        }

        return totalSharesToActivate;
    }

    /// @notice Calculate the total unclaimed ETH across an array of BLS public keys for a free floating staker
    function batchPreviewUnclaimedETHAsFreeFloatingStaker(
        address _staker,
        bytes[] calldata _blsPubKeys
    ) external view returns (uint256) {
        uint256 accumulated;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            accumulated += previewUnclaimedETHAsFreeFloatingStaker(_staker, _blsPubKeys[i]);
        }

        return accumulated;
    }

    /// @notice Preview the amount of unclaimed ETH available for an sETH staker against a KNOT which factors in unprocessed rewards from new ETH sent to contract
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    /// @param _staker The address of a user that has staked sETH against the BLS public key
    function previewUnclaimedETHAsFreeFloatingStaker(
        address _staker,
        bytes calldata _blsPubKey
    ) public view returns (uint256) {
        uint256 currentAccumulatedETHPerFreeFloatingShare = accumulatedETHPerFreeFloatingShare;
        uint256 updatedAccumulatedETHPerFreeFloatingShare =
                            currentAccumulatedETHPerFreeFloatingShare + calculateNewAccumulatedETHPerFreeFloatingShare();

        uint256 stakedBal = sETHStakedBalanceForKnot[_blsPubKey][_staker];
        uint256 userShare = (updatedAccumulatedETHPerFreeFloatingShare * stakedBal) / PRECISION;

        return userShare - sETHUserClaimForKnot[_blsPubKey][_staker];
    }

    /// @notice Calculate the total unclaimed ETH across an array of BLS public keys for a collateralized SLOT staker
    function batchPreviewUnclaimedETHAsCollateralizedSlotOwner(
        address _staker,
        bytes[] calldata _blsPubKeys
    ) external view returns (uint256) {
        uint256 accumulated;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            accumulated += previewUnclaimedETHAsCollateralizedSlotOwner(_staker, _blsPubKeys[i]);
        }

        return accumulated;
    }

    /// @notice Preview the amount of unclaimed ETH available for a collatearlized SLOT staker against a KNOT which factors in unprocessed rewards from new ETH sent to contract
    /// @param _staker Address of a collateralized SLOT owner for a KNOT
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    function previewUnclaimedETHAsCollateralizedSlotOwner(
        address _staker,
        bytes calldata _blsPubKey
    ) public view returns (uint256) {
        if (numberOfActiveKnots + previewActivateableProposers() == 0) return 0;

        // Per collateralized SLOT per KNOT before distributing to individual collateralized owners
        uint256 accumulatedSoFar = accumulatedETHPerCollateralizedSlotPerKnot
                    + ((calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerCollateralizedSlotPerKnot) / (numberOfActiveKnots + previewActivateableProposers()));

        uint256 unprocessedForKnot = accumulatedSoFar - totalETHProcessedPerCollateralizedKnot[_blsPubKey];

        // Fetch information on what has been processed so far against the ECDSA address of the collateralized SLOT owner
        uint256 currentAccrued = accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][_staker];

        // Fetch information about the knot including total slashed amount
        uint256 currentSlashedAmount = getSlotRegistry().currentSlashedAmountOfSLOTForKnot(_blsPubKey);
        uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(_blsPubKey);
        (address stakeHouse,,,,,) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);

        // Find the collateralized SLOT owner and work out how much they're owed
        for (uint256 i; i < numberOfCollateralisedSlotOwnersForKnot; ++i) {
            address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, i);
            if (collateralizedOwnerAtIndex == _staker) {
                uint256 balance = getSlotRegistry().totalUserCollateralisedSLOTBalanceForKnot(
                    stakeHouse,
                    collateralizedOwnerAtIndex,
                    _blsPubKey
                );

                if (currentSlashedAmount < 4 ether) {
                    currentAccrued +=
                    numberOfCollateralisedSlotOwnersForKnot > 1 ? balance * unprocessedForKnot / (4 ether - currentSlashedAmount)
                    : unprocessedForKnot;
                }
                break;
            }
        }

        return currentAccrued - claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][_staker];
    }

    /// @notice Amount of ETH per free floating share that hasn't yet been allocated to each share
    function getUnprocessedETHForAllFreeFloatingSlot() public view returns (uint256) {
        return calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerFreeFloating;
    }

    /// @notice Amount of ETH per collateralized share that hasn't yet been allocated to each share
    function getUnprocessedETHForAllCollateralizedSlot() public view returns (uint256) {
        if (numberOfActiveKnots == 0) return 0;
        return ((calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerCollateralizedSlotPerKnot) / numberOfActiveKnots);
    }

    /// @notice New accumulated ETH per free floating share that hasn't yet been applied
    /// @dev The return value is scaled by 1e24
    function calculateNewAccumulatedETHPerFreeFloatingShare() public view returns (uint256) {
        uint256 ethSinceLastUpdate = getUnprocessedETHForAllFreeFloatingSlot();
        return _calculateNewAccumulatedETHPerFreeFloatingShare(ethSinceLastUpdate, true);
    }

    /// @notice New accumulated ETH per collateralized share per knot that hasn't yet been applied
    function calculateNewAccumulatedETHPerCollateralizedSharePerKnot() public view returns (uint256) {
        uint256 ethSinceLastUpdate = getUnprocessedETHForAllCollateralizedSlot();
        return accumulatedETHPerCollateralizedSlotPerKnot + ethSinceLastUpdate;
    }

    /// @notice Total amount of ETH received by the contract
    function totalETHReceived() public view returns (uint256) {
        return address(this).balance + totalClaimed;
    }

    /// @dev Internal logic for initializing the syndicate contract
    function _initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) internal {
        // Transfer ownership from the deployer to the address specified as the owner
        _transferOwnership(_contractOwner);

        // Add the initial set of knots to the syndicate
        _registerKnotsToSyndicate(_blsPubKeysForSyndicateKnots);

        // Optionally process priority staking if the required params and array is configured
        if (_priorityStakingEndBlock > block.number) {
            priorityStakingEndBlock = _priorityStakingEndBlock;
            _addPriorityStakers(_priorityStakers);
        }

        emit ContractDeployed();
    }

    /// Given an amount of ETH allocated to the collateralized SLOT owners of a KNOT, distribute this amongs the current set of collateralized owners (a dynamic set of addresses and balances)
    function _updateCollateralizedSlotOwnersLiabilitySnapshot(bytes memory _blsPubKey) internal {
        // Establish how much new ETH is for the new KNOT
        uint256 unprocessedETHForCurrentKnot =
                    accumulatedETHPerCollateralizedSlotPerKnot - totalETHProcessedPerCollateralizedKnot[_blsPubKey];

        // Get information about the knot i.e. associated house and whether its active
        (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);

        // Assuming that there is unprocessed ETH and the knot is still part of the syndicate
        if (unprocessedETHForCurrentKnot > 0) {
            uint256 currentSlashedAmount = getSlotRegistry().currentSlashedAmountOfSLOTForKnot(_blsPubKey);

            // Don't allocate ETH when the current slashed amount is four. Syndicate will wait until ETH is topped up to claim revenue
            if (currentSlashedAmount < 4 ether) {
                // This copes with increasing numbers of collateralized slot owners and also copes with SLOT that has been slashed but not topped up
                uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(_blsPubKey);

                if (numberOfCollateralisedSlotOwnersForKnot == 1) {
                    // For only 1 collateralized SLOT owner, they get the full amount of unprocessed ETH for the knot
                    address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, 0);
                    accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][collateralizedOwnerAtIndex] += unprocessedETHForCurrentKnot;
                } else {
                    for (uint256 i; i < numberOfCollateralisedSlotOwnersForKnot; ++i) {
                        address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, i);
                        uint256 balance = getSlotRegistry().totalUserCollateralisedSLOTBalanceForKnot(
                            stakeHouse,
                            collateralizedOwnerAtIndex,
                            _blsPubKey
                        );

                        accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][collateralizedOwnerAtIndex] +=
                            balance * unprocessedETHForCurrentKnot / (4 ether - currentSlashedAmount);
                    }
                }

                // record so unprocessed goes to zero
                totalETHProcessedPerCollateralizedKnot[_blsPubKey] = accumulatedETHPerCollateralizedSlotPerKnot;
            }
        }

        // if the knot is no longer active, no further accrual of rewards are possible snapshots are possible but ETH accrued up to that point
        // Basically, under a rage quit or voluntary withdrawal from the beacon chain, the knot kick is auto-propagated to syndicate
        if (!isActive && !isNoLongerPartOfSyndicate[_blsPubKey]) {
            _deRegisterKnot(_blsPubKey);
        }
    }

    /// @dev Business logic for calculating per free floating share how much ETH from 1559 rewards is owed
    function _calculateNewAccumulatedETHPerFreeFloatingShare(uint256 _ethSinceLastUpdate, bool _previewFreeFloatingSharesToActivate) internal view returns (uint256) {
        uint256 sharesToActivate = _previewFreeFloatingSharesToActivate ? previewTotalFreeFloatingSharesToActivate() : 0;
        return (totalFreeFloatingShares + sharesToActivate) > 0 ? (_ethSinceLastUpdate * PRECISION) / (totalFreeFloatingShares + sharesToActivate) : 0;
    }

    /// @dev Business logic for adding a new set of knots to the syndicate for collecting revenue
    function _registerKnotsToSyndicate(bytes[] memory _blsPubKeysForSyndicateKnots) internal {
        uint256 knotsToRegister = _blsPubKeysForSyndicateKnots.length;
        if (knotsToRegister == 0) revert EmptyArray();

        for (uint256 i; i < knotsToRegister; ++i) {
            bytes memory blsPubKey = _blsPubKeysForSyndicateKnots[i];

            if (isKnotRegistered[blsPubKey]) revert KnotIsAlreadyRegistered();

            // Health check - if knot is inactive or slashed, should it really be part of the syndicate?
            // KNOTs closer to 32 effective at all times is the target
            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(blsPubKey);
            if (!isActive) revert InactiveKnot();

            if (proposersToActivate.length > 0) {
                (address houseAddressForSyndicate,,,,,) = getStakeHouseUniverse().stakeHouseKnotInfo(proposersToActivate[0]);
                if (houseAddressForSyndicate != stakeHouse) revert KnotIsNotAssociatedWithAStakeHouse();
            }

            uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(blsPubKey);
            if (numberOfCollateralisedSlotOwnersForKnot < 1) revert InvalidNumberOfCollateralizedOwners();
            if (getSlotRegistry().currentSlashedAmountOfSLOTForKnot(blsPubKey) != 0) revert InvalidNumberOfCollateralizedOwners();

            isKnotRegistered[blsPubKey] = true;
            activationBlock[blsPubKey] = _computeNextActivationBlock();
            proposersToActivate.push(blsPubKey);
            emit KNOTRegistered(blsPubKey);
        }
    }

    /// @dev Business logic for adding priority stakers to the syndicate
    function _addPriorityStakers(address[] memory _priorityStakers) internal {
        uint256 numOfStakers = _priorityStakers.length;
        if (numOfStakers == 0) revert EmptyArray();
        for (uint256 i; i < numOfStakers; ++i) {
            address staker = _priorityStakers[i];

            if (isPriorityStaker[staker]) revert DuplicateArrayElements();

            isPriorityStaker[staker] = true;

            emit PriorityStakerRegistered(staker);
        }
    }

    /// @dev Business logic for de-registering a set of knots from the syndicate and doing the required snapshots to ensure historical earnings are preserved
    function _deRegisterKnots(bytes[] calldata _blsPublicKeys) internal {
        uint256 numOfKeys = _blsPublicKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory blsPublicKey = _blsPublicKeys[i];

            // Execute the business logic for de-registering the single knot
            _deRegisterKnot(blsPublicKey);
        }
    }

    /// @dev Business logic for de-registering a specific knots assuming all accrued ETH has been processed
    function _deRegisterKnot(bytes memory _blsPublicKey) internal {
        if (!isKnotRegistered[_blsPublicKey]) revert KnotIsNotRegisteredWithSyndicate();
        if (isNoLongerPartOfSyndicate[_blsPublicKey]) revert KnotHasAlreadyBeenDeRegistered();

        // Update global system params before doing de-registration
        activateProposers();

        // We flag that the knot is no longer part of the syndicate
        isNoLongerPartOfSyndicate[_blsPublicKey] = true;

        // Do one final snapshot of ETH owed to the collateralized SLOT owners so they can claim later
        _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPublicKey);

        // For the free floating and collateralized SLOT of the knot, snapshot the accumulated ETH per share
        lastAccumulatedETHPerFreeFloatingShare[_blsPublicKey] = accumulatedETHPerFreeFloatingShare;

        // We need to reduce `totalFreeFloatingShares` in order to avoid further ETH accruing to shares of de-registered knot
        totalFreeFloatingShares -= sETHTotalStakeForKnot[_blsPublicKey];

        // Total number of registered knots with the syndicate reduces by one
        numberOfActiveKnots -= 1;

        emit KnotDeRegistered(_blsPublicKey);
    }

    /// @dev Work out the accumulated ETH per free floating share value that must be used for distributing ETH
    function _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(
        bytes memory _blsPublicKey
    ) internal view returns (uint256) {
        if (isNoLongerPartOfSyndicate[_blsPublicKey]) {
            return lastAccumulatedETHPerFreeFloatingShare[_blsPublicKey];
        }

        return accumulatedETHPerFreeFloatingShare;
    }

    /// @dev Business logic for allowing a free floating SLOT holder to claim their share of ETH
    function _claimAsStaker(address _recipient, bytes[] calldata _blsPubKeys) internal {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();
        if (_recipient == address(this)) revert ZeroAddress();

        // Make sure we have the latest accrued information
        activateProposers();

        uint256 totalToTransfer;
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            uint256 unclaimedUserShare = calculateUnclaimedFreeFloatingETHShare(_blsPubKey, msg.sender);

            // this means that user can call the funtion even if there is nothing to claim but the
            // worst that will happen is that they will just waste gas. this is needed for unstaking
            if (unclaimedUserShare > 0) {
                // Increase total claimed at the contract level
                totalClaimed += unclaimedUserShare;

                // Work out which accumulated ETH per free floating share value was used
                uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);

                // Update the total ETH claimed by the free floating SLOT holder based on their share of sETH
                sETHUserClaimForKnot[_blsPubKey][msg.sender] =
                (accumulatedETHPerShare * sETHStakedBalanceForKnot[_blsPubKey][msg.sender]) / PRECISION;

                // Calculate how much ETH to send to the user
                totalToTransfer += unclaimedUserShare;

                emit ETHClaimed(
                    _blsPubKey,
                    msg.sender,
                    _recipient,
                    unclaimedUserShare,
                    false
                );
            }
        }

        _transferETH(_recipient, totalToTransfer);
    }

    function _computeNextActivationBlock() internal view returns (uint256) {
        // As per ethereum spec, this is SLOT + 1 + 4 Epochs (4 * 32 = 128) - it is an approximation
        uint256 activationDistance = activationDistance > 0 ? activationDistance : 1 + 128;
        return block.number + activationDistance;
    }
}