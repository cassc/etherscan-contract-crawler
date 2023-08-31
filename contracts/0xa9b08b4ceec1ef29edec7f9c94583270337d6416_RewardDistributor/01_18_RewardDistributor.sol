// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Common} from "./libraries/Common.sol";
import {Errors} from "./libraries/Errors.sol";

contract RewardDistributor is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct Reward {
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
        uint256 activeAt;
    }

    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    uint256 public constant MINIMUM_ACTIVE_TIMER = 3 hours;

    // Maps each of the identifiers to its reward metadata
    mapping(bytes32 => Reward) public rewards;
    // Tracks the amount of claimed reward for the specified identifier+account
    mapping(bytes32 => mapping(address => uint256)) public claimed;
    // Used for calculating the timestamp on which rewards can be claimed after an update
    uint256 public activeTimerDuration;

    event RewardClaimed(
        bytes32 indexed identifier,
        address indexed token,
        address indexed account,
        uint256 amount
    );
    event RewardMetadataUpdated(
        bytes32 indexed identifier,
        address indexed token,
        bytes32 merkleRoot,
        bytes32 proof,
        uint256 activeAt
    );
    event SetActiveTimerDuration(uint256 duration);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setActiveTimerDuration(MINIMUM_ACTIVE_TIMER);
    }

    /**
        @notice Claim rewards based on the specified metadata
        @param  _claims  Claim[] List of claim metadata
     */
    function claim(
        Claim[] calldata _claims
    ) external nonReentrant whenNotPaused {
        uint256 cLen = _claims.length;

        if (cLen == 0) revert Errors.InvalidArray();

        for (uint256 i; i < cLen; ) {
            _claim(
                _claims[i].identifier,
                _claims[i].account,
                _claims[i].amount,
                _claims[i].merkleProof
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Update rewards metadata
        @param  _distributions  Distribution[] List of reward distribution details
     */
    function updateRewardsMetadata(
        Common.Distribution[] calldata _distributions
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 dLen = _distributions.length;

        if (dLen == 0) revert Errors.InvalidDistribution();

        uint256 activeAt = block.timestamp + activeTimerDuration;

        for (uint256 i; i < dLen; ) {
            // Update the metadata and start the timer until the rewards will be active/claimable
            Common.Distribution calldata distribution = _distributions[i];
            Reward storage reward = rewards[distribution.identifier];
            reward.merkleRoot = distribution.merkleRoot;
            reward.proof = distribution.proof;
            reward.activeAt = activeAt;

            // Should only be set once per identifier
            if (reward.token == address(0)) {
                reward.token = distribution.token;
            }

            emit RewardMetadataUpdated(
                distribution.identifier,
                distribution.token,
                distribution.merkleRoot,
                distribution.proof,
                activeAt
            );

            unchecked {
                ++i;
            }
        }
    }

    /** 
        @notice Set the contract's pause state (ie. before taking snapshot for the harvester)
        @dev    More efficient compared to setting the merkle proofs of all affected rewardIds to 0x
        @param  state  bool  Pause state
    */
    function setPauseState(bool state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
        @notice Set the active timer duration
        @param  _duration  uint256  Timer duration
    */
    function changeActiveTimerDuration(
        uint256 _duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setActiveTimerDuration(_duration);
    }

    /**
        @notice Claim a reward
        @param  _identifier   bytes32    Merkle identifier
        @param  _account      address    Eligible user account
        @param  _amount       uint256    Reward amount
        @param  _merkleProof  bytes32[]  Merkle proof
     */
    function _claim(
        bytes32 _identifier,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private {
        Reward memory reward = rewards[_identifier];

        if (reward.merkleRoot == 0) revert Errors.InvalidMerkleRoot();
        if (reward.activeAt > block.timestamp) revert Errors.RewardInactive();

        uint256 lifeTimeAmount = claimed[_identifier][_account] + _amount;

        // Verify the merkle proof
        if (
            !MerkleProof.verifyCalldata(
                _merkleProof,
                reward.merkleRoot,
                keccak256(abi.encodePacked(_account, lifeTimeAmount))
            )
        ) revert Errors.InvalidProof();

        // Update the claimed amount to the current total
        claimed[_identifier][_account] = lifeTimeAmount;

        address token = reward.token;

        IERC20(token).safeTransfer(_account, _amount);

        emit RewardClaimed(_identifier, token, _account, _amount);
    }

    /**
        @dev    Internal to set the active timer duration
        @param  _duration  uint256  Timer duration
     */
    function _setActiveTimerDuration(uint256 _duration) internal {
        if (_duration < MINIMUM_ACTIVE_TIMER)
            revert Errors.InvalidTimerDuration();

        activeTimerDuration = _duration;

        emit SetActiveTimerDuration(_duration);
    }
}