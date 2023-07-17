// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {SafeCast} from "../libraries/utils/SafeCast.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IGaugeController} from "../interfaces/IGaugeController.sol";
import {INativeToken} from "../interfaces/INativeToken.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {PercentageMath} from "../libraries/utils/PercentageMath.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title VotingEscrow
/// @author leNFT
/// @notice Manages the locking of LE tokens
/// @dev Provides functionality for locking LE tokens for a specified period of time and is the center of the epoch logic
contract VotingEscrow is
    IVotingEscrow,
    ERC165Upgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 private constant MINLOCKTIME = 2 weeks;
    uint256 private constant MAXLOCKTIME = 4 * 52 weeks;
    uint256 private constant EPOCH_PERIOD = 1 weeks; // TESTNET: 1 day

    IAddressProvider private immutable _addressProvider;
    uint256 private _deployTimestamp;
    // Locked balance for each lock
    mapping(uint256 => DataTypes.LockedBalance) private _lockedBalance;
    // Next claimable rebate epoch for each lock
    mapping(uint256 => uint256) private _nextClaimableEpoch;
    // History of actions for each lock
    mapping(uint256 => DataTypes.Point[]) private _lockHistory;
    // Epoch history of total weight
    uint256[] private _totalWeightHistory;
    // Epoch history of total token supply (used to compute locked ratio)
    uint256[] private _totalSupplyHistory;
    // Epoch history of total locked balance
    uint256[] private _totalLockedHistory;
    // Last checkpoint for the total weight
    DataTypes.Point private _lastWeightCheckpoint;
    // Total weight slope Changes per timestamp
    mapping(uint256 => uint256) private _slopeChanges;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier lockExists(uint256 lockId) {
        _requireLockExists(lockId);
        _;
    }

    modifier lockOwner(uint256 lockId) {
        _requireLockOwner(lockId);
        _;
    }

    modifier lockNotExpired(uint256 lockId) {
        _requireLockNotExpired(lockId);
        _;
    }

    modifier noFutureEpoch(uint256 epoch) {
        _requireNoFutureEpoch(epoch);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IAddressProvider addressProvider) {
        _addressProvider = addressProvider;
        _disableInitializers();
    }

    /// @notice Initializes the VotingEscrow contract.
    function initialize() external initializer {
        __ERC721_init("Vote Escrowed LE", "veLE");
        __ERC721Enumerable_init();
        __ERC165_init();
        __ReentrancyGuard_init();
        _deployTimestamp = block.timestamp;
        _totalWeightHistory.push(0);
        _lastWeightCheckpoint = DataTypes.Point(
            0,
            0,
            SafeCast.toUint40(block.timestamp)
        );
        _totalSupplyHistory.push(0);
        _totalLockedHistory.push(0);
    }

    /// @notice Returns the length of an epoch period in seconds.
    /// @return The length of an epoch period in seconds.
    function getEpochPeriod() external pure override returns (uint256) {
        return EPOCH_PERIOD;
    }

    /// @notice Returns the epoch number for a given timestamp.
    /// @param timestamp The timestamp for which to retrieve the epoch number.
    /// @return The epoch number.
    function getEpoch(uint256 timestamp) public view returns (uint256) {
        uint256 deployTimestamp = _deployTimestamp;
        require(timestamp > deployTimestamp, "VE:E:FUTURE_TIMESTAMP");
        return (timestamp / EPOCH_PERIOD) - (deployTimestamp / EPOCH_PERIOD);
    }

    /// @notice Returns the timestamp of the start of an epoch.
    /// @param _epoch The epoch number for which to retrieve the start timestamp.
    /// @return The start timestamp of the epoch.
    function getEpochTimestamp(uint256 _epoch) public view returns (uint256) {
        return (_deployTimestamp / EPOCH_PERIOD + _epoch) * EPOCH_PERIOD;
    }

    /// @notice Returns a token's encoded URI
    /// @param tokenId The token ID for which to retrieve the URI.
    /// @return The token's encoded URI.
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable)
        lockExists(tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": "veLE Lock #',
                            Strings.toString(tokenId),
                            '",',
                            '"description": "Vote Escrowed LE Lock",',
                            '"image": ',
                            '"data:image/svg+xml;base64,',
                            Base64.encode(svg(tokenId)),
                            '",',
                            '"attributes": [',
                            string(
                                abi.encodePacked(
                                    '{ "trait_type": "end", "value": "',
                                    Strings.toString(
                                        _lockedBalance[tokenId].end
                                    ),
                                    '" },',
                                    '{ "trait_type": "weight", "value": "',
                                    Strings.toString(getLockWeight(tokenId)),
                                    '" },',
                                    '{ "trait_type": "amount", "value": "',
                                    Strings.toString(
                                        _lockedBalance[tokenId].amount
                                    ),
                                    '" }'
                                )
                            ),
                            "]",
                            "}"
                        )
                    )
                )
            );
    }

    /// @notice Returns a token's encoded SVG
    /// @param tokenId The token ID for which to retrieve the SVG.
    /// @return The token's encoded SVG.
    function svg(
        uint256 tokenId
    ) public view lockExists(tokenId) returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" style="width:100%;background:#eaeaea;fill:black;font-family:monospace">',
                '<text x="50%" y="30%" text-anchor="middle" font-size="18">',
                "veLE Lock #",
                Strings.toString(tokenId),
                "</text>",
                '<text x="50%" y="50%" text-anchor="middle" font-size="14">',
                Strings.toString(_lockedBalance[tokenId].amount),
                " LE",
                "</text>",
                "</svg>"
            );
    }

    /// @notice Updates the total weight history array and checkpoint with the current weight.
    /// @dev This function will break if it is not called for 128 epochs.
    function writeTotalWeightHistory() public {
        // Update last saved weight checkpoint and record weight for epochs
        uint256 epochTimestampPointer = getEpochTimestamp(
            _totalWeightHistory.length
        );
        for (uint256 i = 0; i < 2 ** 7; i++) {
            if (epochTimestampPointer > block.timestamp) {
                break;
            }

            // Save epoch total weight
            uint256 epochTotalWeight = _lastWeightCheckpoint.bias -
                _lastWeightCheckpoint.slope *
                (epochTimestampPointer - _lastWeightCheckpoint.timestamp);
            _totalWeightHistory.push(epochTotalWeight);

            // Update last weight checkpoint
            _lastWeightCheckpoint.bias = SafeCast.toUint128(epochTotalWeight);
            _lastWeightCheckpoint.timestamp = SafeCast.toUint40(
                epochTimestampPointer
            );
            _lastWeightCheckpoint.slope -= SafeCast.toUint128(
                _slopeChanges[epochTimestampPointer]
            );

            // Get native token address inside loop because most transactions will break on the first iteration
            address nativeToken = _addressProvider.getNativeToken();
            // Update total locked and total supply histories
            // Will always be accurate since its called eveytime there's a change in total or locked supply
            _totalLockedHistory.push(
                IERC20Upgradeable(nativeToken).balanceOf(address(this))
            );
            _totalSupplyHistory.push(
                IERC20Upgradeable(nativeToken).totalSupply()
            );

            //Increase epoch timestamp
            epochTimestampPointer += EPOCH_PERIOD;
        }
    }

    /// @notice Simulates a lock's weight for a given amount of tokens and unlock time.
    /// @param amount The amount of tokens to be locked.
    /// @param end The unlock time for the lock operation.
    /// @return The weight of the lock.
    function simulateLock(
        uint256 amount,
        uint256 end
    ) external view returns (uint256) {
        // Round the locktime to whole epochs
        uint256 roundedUnlockTime = (end / EPOCH_PERIOD) * EPOCH_PERIOD;

        require(
            roundedUnlockTime >= MINLOCKTIME + block.timestamp,
            "VE:SL:LOCKTIME_TOO_LOW"
        );
        require(
            roundedUnlockTime <= MAXLOCKTIME + block.timestamp,
            "VE:SL:LOCKTIME_TOO_HIGH"
        );

        return (amount * (roundedUnlockTime - block.timestamp)) / MAXLOCKTIME;
    }

    /// @notice Updates the global tracking variables and the user's history of locked balances.
    /// @param tokenId The veLock token id whose balance is being updated.
    /// @param oldBalance The user's previous locked balance.
    /// @param newBalance The user's new locked balance.
    function _checkpoint(
        uint256 tokenId,
        DataTypes.LockedBalance memory oldBalance,
        DataTypes.LockedBalance memory newBalance
    ) internal {
        DataTypes.Point memory oldPoint;
        DataTypes.Point memory newPoint;

        // Bring epoch records into the present
        writeTotalWeightHistory();

        // Calculate slopes and bias
        if (oldBalance.end > block.timestamp && oldBalance.amount > 0) {
            oldPoint.slope = SafeCast.toUint128(
                oldBalance.amount / MAXLOCKTIME
            );
            oldPoint.bias = SafeCast.toUint128(
                oldPoint.slope * (oldBalance.end - block.timestamp)
            );
        }
        if (newBalance.end > block.timestamp && newBalance.amount > 0) {
            newPoint.slope = SafeCast.toUint128(
                newBalance.amount / MAXLOCKTIME
            );
            newPoint.bias = SafeCast.toUint128(
                newPoint.slope * (newBalance.end - block.timestamp)
            );
            newPoint.timestamp = SafeCast.toUint40(block.timestamp);
        }

        // Update last saved total weight
        _lastWeightCheckpoint.bias = SafeCast.toUint128(
            _lastWeightCheckpoint.bias -
                _lastWeightCheckpoint.slope *
                (block.timestamp - _lastWeightCheckpoint.timestamp) +
                newPoint.bias -
                oldPoint.bias
        );
        _lastWeightCheckpoint.slope = SafeCast.toUint128(
            _lastWeightCheckpoint.slope + newPoint.slope - oldPoint.slope
        );
        _lastWeightCheckpoint.timestamp = SafeCast.toUint40(block.timestamp);

        // Read and update slope changes in accordance
        if (oldBalance.end > block.timestamp) {
            // Cancel old slope change
            _slopeChanges[oldBalance.end] -= oldPoint.slope;
        }

        if (newBalance.end > block.timestamp) {
            _slopeChanges[newBalance.end] += newPoint.slope;
        }

        // Update user history
        _lockHistory[tokenId].push(newPoint);
    }

    /// @notice Returns the length of the history array for the specified lock.
    /// @param tokenId The token id of the lock for which to retrieve the history length.
    /// @return The length of the user's history array.
    function getLockHistoryLength(
        uint256 tokenId
    ) public view override lockExists(tokenId) returns (uint256) {
        return _lockHistory[tokenId].length;
    }

    /// @notice Returns the lock's history point at a given index.
    /// @param tokenId The token id of the lock for which to retrieve the history point.
    /// @param index The index of the history point to retrieve.
    /// @return The user's history point at the given index.
    function getLockHistoryPoint(
        uint256 tokenId,
        uint256 index
    )
        public
        view
        override
        lockExists(tokenId)
        returns (DataTypes.Point memory)
    {
        return _lockHistory[tokenId][index];
    }

    /// @notice Returns the ratio of locked tokens for a certain epoch
    /// @dev Multiplied by 10000 (e.g. 50% = 5000)
    /// @param _epoch The epoch number for which to retrieve the ratio.
    /// @return The ratio of locked tokens at the given epoch.
    function getLockedRatioAt(
        uint256 _epoch
    ) external override noFutureEpoch(_epoch) returns (uint256) {
        // Update total weight history
        writeTotalWeightHistory();

        if (_totalSupplyHistory[_epoch] == 0) {
            return 0;
        }

        return
            (_totalLockedHistory[_epoch] * PercentageMath.PERCENTAGE_FACTOR) /
            _totalSupplyHistory[_epoch];
    }

    /// @notice Returns the total weight of locked tokens at a given epoch.
    /// @param _epoch The epoch number for which to retrieve the total weight.
    /// @return The total weight of locked tokens at the given epoch.
    function getTotalWeightAt(
        uint256 _epoch
    ) external noFutureEpoch(_epoch) returns (uint256) {
        // Update total weight history
        writeTotalWeightHistory();

        return _totalWeightHistory[_epoch];
    }

    /// @notice Returns the total weight for all the locks at the current block timestamp
    /// @return The total weight for all the locks.
    function getTotalWeight() public returns (uint256) {
        // Update total weight history
        writeTotalWeightHistory();
        return
            _lastWeightCheckpoint.bias -
            _lastWeightCheckpoint.slope *
            (block.timestamp - _lastWeightCheckpoint.timestamp);
    }

    /// @notice Returns the weight of locked tokens for a given lock.
    /// @param tokenId The tokenid for which to retrieve the locked balance weight.
    /// @return The weight of locked tokens for the given account.
    function getLockWeight(
        uint256 tokenId
    ) public view lockExists(tokenId) returns (uint256) {
        // If the locked token end time has passed
        if (_lockedBalance[tokenId].end < block.timestamp) {
            return 0;
        }
        DataTypes.Point memory lastLockPoint = _lockHistory[tokenId][
            _lockHistory[tokenId].length - 1
        ];

        return
            lastLockPoint.bias -
            lastLockPoint.slope *
            (block.timestamp - lastLockPoint.timestamp);
    }

    /// @notice Returns the weight of locked tokens for a given account.
    /// @param user The address for which to retrieve the locked balance weight.
    /// @return weight The weight of locked tokens for the given account.
    function getUserWeight(
        address user
    ) external view returns (uint256 weight) {
        uint256 length = balanceOf(user);
        for (uint256 i = 0; i < length; i++) {
            weight += getLockWeight(tokenOfOwnerByIndex(user, i));
        }
    }

    /// @notice Locks tokens into the voting escrow contract for a specified amount of time.
    /// @param receiver The address that will receive the locked tokens.
    /// @param amount The amount of tokens to be locked.
    /// @param unlockTime The timestamp at which the tokens will be unlocked.
    /// @dev Calls a checkpoint event
    function createLock(
        address receiver,
        uint256 amount,
        uint256 unlockTime
    ) external nonReentrant {
        // Round the locktime to whole epochs
        uint256 roundedUnlockTime = (unlockTime / EPOCH_PERIOD) * EPOCH_PERIOD;

        require(amount > 0, "VE:CL:AMOUNT_ZERO");

        require(
            roundedUnlockTime >= MINLOCKTIME + block.timestamp,
            "VE:CL:LOCKTIME_TOO_LOW"
        );
        require(
            roundedUnlockTime <= MAXLOCKTIME + block.timestamp,
            "VE:CL:LOCKTIME_TOO_HIGH"
        );

        // Mint a veNFT to represent the lock and increase the token id counter
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Setup the next claimable rebate epoch
        _nextClaimableEpoch[tokenId] = getEpoch(block.timestamp) + 1;

        // Init the locked balance state variable
        _lockedBalance[tokenId] = DataTypes.LockedBalance(
            SafeCast.toUint128(amount),
            SafeCast.toUint40(roundedUnlockTime)
        );

        // Call a checkpoint and update global tracking vars (the old locked balance will be 0 since this is a new lock)
        _checkpoint(
            tokenId,
            DataTypes.LockedBalance(0, 0),
            DataTypes.LockedBalance(
                SafeCast.toUint128(amount),
                SafeCast.toUint40(roundedUnlockTime)
            )
        );

        // Transfer the locked tokens from the caller to this contract
        IERC20Upgradeable(_addressProvider.getNativeToken()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Mint the veNFT
        _safeMint(receiver, tokenId);

        emit CreateLock(receiver, tokenId, amount, roundedUnlockTime);
    }

    /// @notice Increases the locked balance of the caller by the given amount and performs a checkpoint
    /// @param tokenId The token id of the lock to increase the amount of
    /// @param amount The amount to increase the locked balance by
    /// @dev Requires the caller to have an active lock on their balance
    /// @dev Transfers the native token from the caller to this contract
    /// @dev Calls a checkpoint event
    function increaseAmount(
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant lockOwner(tokenId) lockNotExpired(tokenId) {
        require(amount > 0, "VE:IA:AMOUNT_ZERO");
        // Claim any existing rebates
        claimRebates(tokenId);

        // Save oldLocked and update the locked balance
        DataTypes.LockedBalance memory oldLocked = _lockedBalance[tokenId];
        _lockedBalance[tokenId].amount += SafeCast.toUint128(amount);

        // Call a checkpoint and update global tracking vars
        _checkpoint(tokenId, oldLocked, _lockedBalance[tokenId]);

        IERC20Upgradeable(_addressProvider.getNativeToken()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit IncreaseAmount(tokenId, amount);
    }

    /// @notice Increases the unlock time of the caller's lock to the given time and performs a checkpoint
    /// @param tokenId The token id of the lock to increase the unlock time of
    /// @param newUnlockTime The new unlock time to set
    /// @dev Requires the caller to have an active lock on their balance
    /// @dev Requires the new unlock time to be greater than or equal to the current unlock time
    /// @dev Requires the new unlock time to be less than or equal to the maximum lock time
    /// @dev Calls a checkpoint event
    function increaseUnlockTime(
        uint256 tokenId,
        uint256 newUnlockTime
    ) external nonReentrant lockOwner(tokenId) lockNotExpired(tokenId) {
        // Round the locktime to whole epochs
        uint256 roundedUnlocktime = (newUnlockTime / EPOCH_PERIOD) *
            EPOCH_PERIOD;

        require(
            roundedUnlocktime > _lockedBalance[tokenId].end,
            "VE:IUT:TIME_NOT_INCREASED"
        );

        require(
            roundedUnlocktime <= MAXLOCKTIME + block.timestamp,
            "VE:IUT:LOCKTIME_TOO_HIGH"
        );

        // Claim any existing rebates so they are not lost
        claimRebates(tokenId);

        // Cache oldLocked and update the locked balance
        DataTypes.LockedBalance memory oldLocked = _lockedBalance[tokenId];
        _lockedBalance[tokenId].end = SafeCast.toUint40(roundedUnlocktime);

        // Call a checkpoint and update global tracking vars
        _checkpoint(tokenId, oldLocked, _lockedBalance[tokenId]);

        emit IncreaseUnlockTime(tokenId, roundedUnlocktime);
    }

    /// @notice Withdraws the locked balance of the caller and performs a checkpoint
    /// @param tokenId The token id of the lock to withdraw from
    /// @dev Requires the caller to have a non-zero locked balance and an expired lock time
    /// @dev Requires the caller to have no active votes in the gauge controller
    /// @dev Transfers the native token from this contract to the caller
    /// @dev Calls a checkpoint event
    /// @dev User needs to claim fees before withdrawing or will lose them
    function withdraw(uint256 tokenId) external lockOwner(tokenId) {
        require(_lockedBalance[tokenId].amount > 0, "VE:W:ZERO_BALANCE");
        require(
            block.timestamp > _lockedBalance[tokenId].end,
            "VE:W:LOCK_NOT_EXPIRED"
        );

        // Make sure the tokenId has no active votes
        require(
            IGaugeController(_addressProvider.getGaugeController())
                .getLockVoteRatio(tokenId) == 0,
            "VE:W:HAS_ACTIVE_VOTES"
        );

        // Claim any existing rebates so they are not lost
        claimRebates(tokenId);

        // Save oldLocked and update the locked balance
        DataTypes.LockedBalance memory oldLocked = _lockedBalance[tokenId];
        delete _lockedBalance[tokenId];

        // Call a checkpoint and update global tracking vars
        _checkpoint(tokenId, oldLocked, _lockedBalance[tokenId]);

        // Send locked amount back to user
        IERC20Upgradeable(_addressProvider.getNativeToken()).safeTransfer(
            msg.sender,
            oldLocked.amount
        );

        // Burn the veNFT
        _burn(tokenId);

        emit Withdraw(tokenId);
    }

    /// @notice Claims all available rebates for the given token id
    /// @param tokenId The token id of the lock to claim rebates for
    /// @return amountToClaim The amount of rebates claimed
    function claimRebates(
        uint256 tokenId
    ) public lockOwner(tokenId) returns (uint256 amountToClaim) {
        // Update total weight tracking vars
        writeTotalWeightHistory();

        // Claim all the available rebates for the lock
        uint256 maxEpochRebates;
        uint256 nextClaimableEpoch = _nextClaimableEpoch[tokenId];
        uint256 currentEpoch = getEpoch(block.timestamp);

        // Claim a maximum of 50 epochs at a time
        for (uint i = 0; i < 50 && nextClaimableEpoch < currentEpoch; ) {
            if (
                getEpochTimestamp(nextClaimableEpoch) >
                _lockedBalance[tokenId].end
            ) {
                break;
            }

            if (_totalSupplyHistory[nextClaimableEpoch] > 0) {
                // Get the full amount of rebates to claim for the epoch as if everyone was locked at max locktime
                maxEpochRebates =
                    (_totalLockedHistory[nextClaimableEpoch] *
                        IGaugeController(_addressProvider.getGaugeController())
                            .getEpochRewards(nextClaimableEpoch)) /
                    _totalSupplyHistory[nextClaimableEpoch];

                // Get the rebate share for this specific lock
                // It will depend on the size and duration of the lock
                amountToClaim +=
                    (maxEpochRebates *
                        _lockedBalance[tokenId].amount *
                        (_lockedBalance[tokenId].end -
                            getEpochTimestamp(nextClaimableEpoch))) /
                    (_totalLockedHistory[nextClaimableEpoch] * MAXLOCKTIME);
            }

            // Increase next claimable epoch
            nextClaimableEpoch++;

            // Increase the counter
            unchecked {
                ++i;
            }
        }

        // Update the next claimable epoch
        _nextClaimableEpoch[tokenId] = nextClaimableEpoch;

        // Mint the rebates to the user's wallet
        if (amountToClaim > 0) {
            INativeToken(_addressProvider.getNativeToken()).mintRebates(
                msg.sender,
                amountToClaim
            );

            emit ClaimRebates(msg.sender, tokenId, amountToClaim);
        }
    }

    /// @notice Claims all available rebates for the given token ids
    /// @param tokensIds The token ids of the locks to claim rebates for
    /// @return amountToClaim The amount of rebates claimed
    function claimRebatesBatch(
        uint256[] calldata tokensIds
    ) external returns (uint256 amountToClaim) {
        for (uint i = 0; i < tokensIds.length; i++) {
            amountToClaim += claimRebates(tokensIds[i]);
        }
    }

    /// @notice Returns the details for a single lock
    /// @param tokenId The token id of the lock to get the locked balance of and end time of
    /// @return The locked object of the user
    function getLock(
        uint256 tokenId
    )
        external
        view
        lockExists(tokenId)
        returns (DataTypes.LockedBalance memory)
    {
        return _lockedBalance[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(
            from,
            to,
            tokenId,
            batchSize
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721EnumerableUpgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _requireLockExists(uint256 tokenId) internal view {
        require(_exists(tokenId), "VE:LOCK_NOT_FOUND");
    }

    function _requireLockOwner(uint256 tokenId) internal view {
        require(_ownerOf(tokenId) == msg.sender, "VE:NOT_OWNER");
    }

    function _requireLockNotExpired(uint256 tokenId) internal view {
        require(
            _lockedBalance[tokenId].end > block.timestamp,
            "VE:LOCK_EXPIRED"
        );
    }

    function _requireNoFutureEpoch(uint256 epoch) internal view {
        require(epoch <= getEpoch(block.timestamp), "VE:FUTURE_EPOCH");
    }
}