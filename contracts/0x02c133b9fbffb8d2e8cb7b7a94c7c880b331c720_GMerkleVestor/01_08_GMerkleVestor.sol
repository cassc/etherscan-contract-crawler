// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import { IERC20 } from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import { MerkleProof } from 'openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol';
import { Ownable } from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import { SafeERC20 } from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GMerkleVestor
/// @notice Setups up a vesting schdule for a distribution token for users
/// using a merkle tree for claim verification
/// @dev The operator needs to send the distribution token to the contract for
/// distributions to work.
contract GMerkleVestor is Ownable {
	using SafeERC20 for IERC20;

	/*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

	// we can pack into one slot as totalClaim is less max type(uint128).max
	struct UserInfo {
		uint128 totalClaim;
		uint128 claimedAmount;
	}

	uint256 internal constant ONE_MONTH_SECONDS = 2629746; // average year (including leap years) in seconds / 12
	uint256 internal constant VESTING_TIME = ONE_MONTH_SECONDS * 23; // 2 years period - 1 month
	uint256 internal constant ONE_WEEK_SECONDS = 604800;

	address public immutable token;
	uint256 public immutable vestingStartTime;
	uint256 public immutable vestingEndTime;
	uint256 public immutable deploymentTime;
	bytes32 public immutable merkleRoot;
	mapping(address => UserInfo) public usersInfo;

	/*//////////////////////////////////////////////////////////////
                            Custom Errors
    //////////////////////////////////////////////////////////////*/

	error InvalidMerkleProof();
	error InitialClaimComplete();
	error InitialClaimIncomplete();
	error SweepDeadlineNotPassed();

	/*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

	event LogInitialClaim(address indexed user, uint256 totalClaim, uint256 claimAmount);
	event LogClaim(address indexed user, uint256 amount);

	/*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

	constructor(
		address _token,
		uint256 _vetingStartTime,
		bytes32 _merkleRoot
	) {
		token = _token;
		vestingStartTime = _vetingStartTime;
		merkleRoot = _merkleRoot;
		vestingEndTime = _vetingStartTime + VESTING_TIME;
		deploymentTime = block.timestamp;
	}

	/*//////////////////////////////////////////////////////////////
                            Core Logic
    //////////////////////////////////////////////////////////////*/

	/// @notice let's the user check if they are part of the merkle tree with their proof
	/// @param proof merkle proof to generate the leaf for the merkle tree
	/// @param amount the total amount the user can claim at the end of their vest
	/// @return boolean showing if a user can claim with their proof
	function canClaim(bytes32[] memory proof, uint256 amount) external view returns (bool) {
		// create leaf with user address and amount
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
		// verify valid proof
		return MerkleProof.verify(proof, merkleRoot, leaf);
	}

	/// @notice let's the user see what they can currently claim
	/// @param proof merkle proof to generate the leaf for the merkle tree
	/// @param  _totalClaim the total amount the user can claim at the end of their vest
	/// @param  _user address of the claimer
	/// @return The current vested amount a user can claim minus any amount claimed prior
	function getVestedAmount(
		bytes32[] memory proof,
		uint256 _totalClaim,
		address _user
	) external view returns (uint256) {
		// calculate how much user has vested accounting for claims already made
		UserInfo memory currentPosition = usersInfo[_user];

		uint256 currentClaimableAmount;
		// If user hasn't started a claim yet calculate vested amount
		if (currentPosition.claimedAmount == 0) {
			// create leaf with user address and amount
			bytes32 leaf = keccak256(abi.encodePacked(_user, _totalClaim));
			// verify valid proof
			if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidMerkleProof();

			// calculate how much user has vested that we can send on this inital claim
			if (block.timestamp < vestingEndTime) {
				currentClaimableAmount =
					(_totalClaim * (block.timestamp - vestingStartTime)) /
					(VESTING_TIME);
			} else {
				currentClaimableAmount = _totalClaim;
			}

			return currentClaimableAmount;
		}

		if (block.timestamp < vestingEndTime) {
			currentClaimableAmount =
				((currentPosition.totalClaim * (block.timestamp - vestingStartTime)) /
					(VESTING_TIME)) -
				currentPosition.claimedAmount;
		} else {
			currentClaimableAmount = currentPosition.totalClaim - currentPosition.claimedAmount;
		}

		return currentClaimableAmount;
	}

	/// @notice The function the user calls for their first claim to setup their vesting
	/// position and get their initial vested amount depending on when they claim
	/// @param proof merkle proof to generate the leaf for the merkle tree
	/// @param amount the total amount the user can claim at the end of their vest
	function initialClaim(bytes32[] memory proof, uint256 amount) external {
		// create leaf with user address and amount
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
		// verify valid proof
		if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidMerkleProof();

		// ensure user hasn't claimed already
		if (usersInfo[msg.sender].claimedAmount > 0) revert InitialClaimComplete();

		// calculate how much user has vested that we can send on this inital claim
		uint256 currentClaimableAmount;

		if (block.timestamp < vestingEndTime) {
			currentClaimableAmount =
				(amount * (block.timestamp - vestingStartTime)) /
				(VESTING_TIME);
		} else {
			currentClaimableAmount = amount;
		}

		// update usersInfo mapping
		// we can downcast safely as the max value of account is less than type(uint128).max
		usersInfo[msg.sender] = UserInfo(uint128(amount), uint128(currentClaimableAmount));

		// transfer funds to user
		IERC20(token).safeTransfer(msg.sender, currentClaimableAmount);

		// emit event
		emit LogInitialClaim(msg.sender, amount, currentClaimableAmount);
	}

	/// @notice The function a user should call when they are making ongoing claims
	/// after their intiial claim
	function claim() external {
		UserInfo memory currentPosition = usersInfo[msg.sender];
		if (currentPosition.claimedAmount == 0) revert InitialClaimIncomplete();

		// calculate how much user has vested that we can send on this inital claim
		uint256 currentClaimableAmount;

		if (block.timestamp < vestingEndTime) {
			currentClaimableAmount =
				((currentPosition.totalClaim * (block.timestamp - vestingStartTime)) /
					(VESTING_TIME)) -
				currentPosition.claimedAmount;
		} else {
			currentClaimableAmount = currentPosition.totalClaim - currentPosition.claimedAmount;
		}

		// update claimed amount for user in storage
		usersInfo[msg.sender].claimedAmount =
			uint128(currentPosition.claimedAmount) +
			uint128(currentClaimableAmount);

		// transfer funds to user
		IERC20(token).safeTransfer(msg.sender, currentClaimableAmount);

		// emit event
		emit LogClaim(msg.sender, currentClaimableAmount);
	}

	/// @notice Gives the ability for the owner to transfer themselves
	/// any amount of the distribution token the contract holds
	/// @param _amount amount of token to send to the owner
	function sweep(uint256 _amount) external onlyOwner {
		if (block.timestamp < deploymentTime + ONE_WEEK_SECONDS) {
			// transfer funds to owner
			IERC20(token).safeTransfer(owner(), _amount);
			return;
		}

		if (block.timestamp < vestingEndTime + ONE_WEEK_SECONDS) revert SweepDeadlineNotPassed();
		// transfer funds to owner
		IERC20(token).safeTransfer(owner(), _amount);
	}
}