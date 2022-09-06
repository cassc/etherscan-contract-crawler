// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/interface/IMultiMerkleStash.sol";
import "src/interface/IVeSDT.sol";

/// @notice Contract helper for bundle tx for claiming bribes and lock SDT for veSDT
contract ClaimAndLock {
	address public multiMerkleStash = address(0x03E34b085C52985F6a5D27243F20C84bDdc01Db4);
	address public constant VE_SDT = address(0x0C30476f66034E11782938DF8e4384970B6c9e8a);
	address public constant SDT = address(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);

	constructor() {
		IERC20(SDT).approve(VE_SDT, type(uint256).max);
	}

	/// @notice Bundle tx for Claiming (only) SDT from bribes and Lock it on veSDT
	/// @dev For locking SDT into veSDT, account should already have some veSDT
	/// @dev Can't lock SDT into veSDT for first time here
	/// @param index Index for the merkle tree
	/// @param amount Amount of bribes received
	/// @param merkleProof MerkleProof for this bribes session
	function claimAndLockSDT(
		uint256 index,
		uint256 amount,
		bytes32[] calldata merkleProof
	) external {
		//claim SDT from bribes
		IMultiMerkleStash(multiMerkleStash).claim(SDT, index, msg.sender, amount, merkleProof);
		// lock SDT
		IERC20(SDT).transferFrom(msg.sender, address(this), amount);
		IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
	}

	/// @notice Bundle tx for Claiming bribes and Lock SDT for veSDT
	/// @dev For locking SDT into veSDT, account should already have some veSDT
	/// @dev Can't lock SDT into veSDT for first time here
	/// @param claims List containing claimParam structure argument needed for claimMulti
	function claimAndLockMulti(IMultiMerkleStash.claimParam[] calldata claims) external {
		//claim all bribes token
		IMultiMerkleStash(multiMerkleStash).claimMulti(msg.sender, claims);
		// find amount of SDT claimed
		uint256 amountSDT = 0;
		for (uint256 i = 0; i < claims.length; ) {
			if (claims[i].token == SDT) {
				amountSDT = claims[i].amount;
				break;
			}
			unchecked {
				++i;
			}
		}
		// lock SDT
		IERC20(SDT).transferFrom(msg.sender, address(this), amountSDT);
		IVeSDT(VE_SDT).deposit_for(msg.sender, amountSDT);
	}
}