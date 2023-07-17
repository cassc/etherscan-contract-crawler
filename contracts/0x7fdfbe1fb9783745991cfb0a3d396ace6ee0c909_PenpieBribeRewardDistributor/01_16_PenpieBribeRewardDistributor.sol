// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../libraries/math/Math.sol";

/// @title PenpieBribeRewardDistributor
/// @notice Penpie bribe reward distributor is used for distributing rewards from voting.
///         We aggregate all reward tokens for each user who voted on any pools off-chain,
///         so that users can claim their rewards by simply looping through and saving on
///         gas costs.
///         When importing the merkleTree, we will include the previous amount of users
///         and record the claimed amount for each user, ensuring that users always receive
///         the correct amount of rewards.
///
/// @author Magpie Team
contract PenpieBribeRewardDistributor is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct Distribution {
        address token;
        bytes32 merkleRoot;
    }

    struct Reward {
        bytes32 merkleRoot;
        bytes32 proof;
        uint256 updateCount;
    }

    struct Claimable {
        address token;
        uint256 amount;
    }

    struct Claim {
        address token;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /* ============ State Variables ============ */

    address constant NATIVE = address(1);
    address public bribeManager;

    mapping(address => Reward) public rewards; // Maps each of the token to its reward metadata
    mapping(address => mapping(address => uint256)) public claimed; // Tracks the amount of claimed reward for the specified token+account
    mapping(address => bool) public allowedOperator;

    /* ============ Events ============ */

    event RewardClaimed(
        address indexed token,
        address indexed account,
        uint256 amount,
        uint256 updateCount
    );
    event RewardMetadataUpdated(
        address indexed token,
        bytes32 merkleRoot,
        uint256 indexed updateCount
    );
    event UpdateOperatorStatus(
        address indexed _user, 
        bool _status
    );

    /* ============ Errors ============ */

    error OnlyOperator();
    error OnlyBribeManager();
    error DistributionNotEnabled();
    error InvalidProof();
    error InsufficientClaimable();
    error TransferFailed();
    error InvalidDistributions();

    /* ============ Constructor ============ */
    constructor() {
        _disableInitializers();
    }

    function __PenpieBribeRewardDistributor_init(
        address _bribeManager
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        bribeManager = _bribeManager;
        allowedOperator[owner()] = true;
    }

    /* ============ Modifiers ============ */

    modifier onlyOperator() {
        if (!allowedOperator[msg.sender]) revert OnlyOperator();
        _;
    }

    modifier onlyBribeManager() {
        if (msg.sender != bribeManager) revert OnlyBribeManager();
        _;
    }

    /* ============ External Getters ============ */

    /* ============ External Functions ============ */

    receive() external payable { }

    function getClaimable(Claim[] calldata _claims) external view returns(Claimable[] memory) {
        Claimable[] memory claimables = new Claimable[](_claims.length);

        for (uint256 i; i < _claims.length; ++i) {
            claimables[i] = Claimable(
                _claims[i].token,
                _claimable(
                    _claims[i].token,
                    _claims[i].account,
                    _claims[i].amount,
                    _claims[i].merkleProof
                )
            );
        }

        return claimables;
    }

    function claim(Claim[] calldata _claims) external nonReentrant {
        for (uint256 i; i < _claims.length; ++i) {
            _claim(
                _claims[i].token,
                _claims[i].account,
                _claims[i].amount,
                _claims[i].merkleProof
            );
        }
    }

    /* ============ Internal Functions ============ */

    /**
        @notice Claim a reward
        @param  _token             address    Token address
        @param  _account           address    Eligible user account
        @param  _amount            uint256    Reward amount
        @param  _merkleProof       bytes32[]  Merkle proof
     */
    function _claimable(
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private view returns(uint256 claimable) {
        Reward memory reward = rewards[_token];

        if (reward.merkleRoot == 0) revert DistributionNotEnabled();

        // Verify the merkle proof
        if (
            !MerkleProof.verify(
                _merkleProof,
                reward.merkleRoot,
                keccak256(abi.encodePacked(_account, _amount))
            )
        ) revert InvalidProof();

        // Verify the claimable amount
        if (claimed[_token][_account] >= _amount)
            revert InsufficientClaimable();

        // Calculate the claimable amount based off the total of reward (used in the merkle tree)
        // since the beginning for the user, minus the total claimed so far
        claimable = _amount - claimed[_token][_account];
    }

    /**
        @notice Claim a reward
        @param  _token             address    Token address
        @param  _account           address    Eligible user account
        @param  _amount            uint256    Reward amount
        @param  _merkleProof       bytes32[]  Merkle proof
     */
    function _claim(
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private {
        Reward memory reward = rewards[_token];

        if (reward.merkleRoot == 0) revert DistributionNotEnabled();

        // Verify the merkle proof
        if (
            !MerkleProof.verify(
                _merkleProof,
                reward.merkleRoot,
                keccak256(abi.encodePacked(_account, _amount))
            )
        ) revert InvalidProof();

        // Verify the claimable amount
        if (claimed[_token][_account] >= _amount)
            revert InsufficientClaimable();

        // Calculate the claimable amount based off the total of reward (used in the merkle tree)
        // since the beginning for the user, minus the total claimed so far
        uint256 claimable = _amount - claimed[_token][_account];
        // Update the claimed amount to the current total
        claimed[_token][_account] = _amount;

        // Check whether the reward is in the form of native tokens or ERC20
        // by checking if the token address is set to NATIVE
        if (_token != NATIVE) {
            IERC20(_token).safeTransfer(_account, claimable);
        } else {
            (bool sent, ) = payable(_account).call{ value: claimable }("");
            if (!sent) revert TransferFailed();
        }

        emit RewardClaimed(_token, _account, claimable, reward.updateCount);
    }

    /* ============ Admin Functions ============ */

    function updateDistribution(
        Distribution[] calldata _distributions
    ) external onlyOwner {
        if (_distributions.length == 0) revert InvalidDistributions();

        for (uint256 i; i < _distributions.length; ++i) {
            // Update the metadata and also increment the update counter
            Distribution calldata distribution = _distributions[i];
            Reward storage reward = rewards[distribution.token];
            reward.merkleRoot = distribution.merkleRoot;
            ++reward.updateCount;

            emit RewardMetadataUpdated(
                distribution.token,
                distribution.merkleRoot,
                reward.updateCount
            );
        }
    }

    function emergencyWithdraw(address _token, address _receiver) external onlyOwner {
        if (_token == bribeManager) {
            address payable recipient = payable(_receiver);
            recipient.transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(
                _receiver,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function updateAllowedUperator(address _user, bool _allowed) external onlyOwner {
        allowedOperator[_user] = _allowed;

        emit UpdateOperatorStatus(_user, _allowed);
    }

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}
}