// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interfaces/IERC721x.sol";
import "./Interfaces/IError.sol";


/// @title Smol Snack Lock Registry (Upgrade Compatable)
/// @author Gearhart
/// @notice Functions responsible for staking functionality. 

abstract contract LockRegistryUpgradeable is Initializable, IERC721x, IError {

	mapping(address => bool) public override approvedContract;
	mapping(uint256 => uint256) public override lockCount;
	mapping(uint256 => mapping(uint256 => address)) public override lockMap;
	mapping(uint256 => mapping(address => uint256)) public override lockMapIndex;

	event TokenLocked(uint256 indexed tokenId, address indexed approvedContract);
	event TokenUnlocked(uint256 indexed tokenId, address indexed approvedContract);

	function __LockRegistryUpgradeable_init() internal onlyInitializing {
    }

	/// @dev Checks if lockCount for given token id is 0. If true, token is free to be transfered.
	/// @param _id Token id to be checked.
	function isUnlocked(uint256 _id) public view override returns(bool) {
		return lockCount[_id] == 0;
	}

	/// @dev Adds a lock to token id from an approved contract. Updates mappingings for lock tracking.
	function _lockId(uint256 _id) internal {
		if (!approvedContract[msg.sender]) revert NotFromApprovedContract();
		if (lockMapIndex[_id][msg.sender] != 0) revert TokenIdHasAlreadyBeenLockedByCaller();
		uint256 count = lockCount[_id] + 1;
		lockMap[_id][count] = msg.sender;
		lockMapIndex[_id][msg.sender] = count;
		lockCount[_id]++;
		emit TokenLocked(_id, msg.sender);
	}

	/// @dev Removes one lock applied to token id from an approved contract. Updates mappingings for lock tracking.
	function _unlockId(uint256 _id) internal {
		if (!approvedContract[msg.sender]) revert NotFromApprovedContract();
		uint256 index = lockMapIndex[_id][msg.sender];
		if (index == 0) revert TokenIdHasNotBeenLockedByCaller();
		uint256 last = lockCount[_id];
		if (index != last) {
			address lastContract = lockMap[_id][last];
			lockMap[_id][index] = lastContract;
			lockMap[_id][last] = address(0);
			lockMapIndex[_id][lastContract] = index;
		}
		else
			lockMap[_id][index] = address(0);
		lockMapIndex[_id][msg.sender] = 0;
		lockCount[_id]--;
		emit TokenUnlocked(_id, msg.sender);
	}

	/// @dev Allows token to be unlocked ONLY if contract that originally locked the token is no longer an approved contract. 
	function _freeId(uint256 _id, address _contract) internal {
		if (approvedContract[_contract]) revert ContractMustNoLongerBeApproved();
		uint256 index = lockMapIndex[_id][_contract];
		if (index == 0) revert TokenIdNotLockedByContract();
		uint256 last = lockCount[_id];
		if (index != last) {
			address lastContract = lockMap[_id][last];
			lockMap[_id][index] = lastContract;
			lockMap[_id][last] = address(0);
			lockMapIndex[_id][lastContract] = index;
		}
		else
			lockMap[_id][index] = address(0);
		lockMapIndex[_id][_contract] = 0;
		lockCount[_id]--;
		emit TokenUnlocked(_id, _contract);
	}

	/**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}