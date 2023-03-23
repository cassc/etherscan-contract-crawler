/// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MLTToken is ERC20 {
	/********
	* INDEX *
	*********/
	// 1. Type declarations.
	// 2. Constants and variables.
	// 3. Mappings.
	// 4. Modifiers.
	// 5. Events.
	// 6. Functions.

	/***********************
	* 1. TYPE DECLARATIONS *
	************************/
	struct VestingData {
		address beneficiary;
		uint256 amount;
		uint256 cliff;
		bytes32[] proof;
	}

	struct Allocation {
		uint256 unlocking;
		uint256[] monthly;
		uint256[] months;
		uint256 cliff;
	}

	/*****************************
	* 2. CONSTANTS AND VARIABLES *
	******************************/
	uint256 public VESTING_START_TIMESTAMP;

	/// @dev of URIs for all the Merkle trees added to the contract.
	string[] public rootURIs;

	/**************
	* 3. MAPPINGS *
	***************/
	/**
	 * Mapping of URIs to IPFS storing the data of a vestingTree.
	 * root => URI (IPFS)
	**/
	mapping(bytes32 => string) public mapRootURIs;

	/**
	 * @dev Record of user withdrawals by cliff.
	 * leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff))
	 * leaf => claimed
	**/
	mapping(bytes32 => bool) public vestingClaimed;

	/**
	 * @dev Total balance of vesting tree by root hash
	 * Root hash => balance
	**/
	mapping(bytes32 => uint256) public balanceByRootHash;

	/**
	 * @dev Root hash record of valid vesting trees
	 * Root hash => valid
	**/
	mapping(bytes32 => bool) public rootWhitelist;

	/**
	 * @dev Treasurer mapping. A treasurer is an address which has the possibility of generating
	 * new TGE with the tokens that are assigned to it at the time of contract deployment.
	 * address => isTreasurer
	**/
	mapping(address => bool) private _treasurers;

	/***************
	* 4. MODIFIERS *
	****************/
	/**
	 * @dev Throws if root no valid
	**/
	modifier validRoot(bytes32 _root) {
		require(rootWhitelist[_root], "Root no valid");
		_;
	}

	/************
	* 5. EVENTS *
	*************/
	event AddedRoot(bytes32 indexed root);
	event VestedTokenGrant(bytes32 indexed leafHash);

	/***************
	* 6. FUNCTIONS *
	****************/
	/**
	 * @param name_ Name of ERC20 token
	 * @param symbol_ Symbol of ERC20 token
	 * @param supply_ Supply of ERC20 token
	 * @param uriIPFS_ IPFS URI for the initial vesting tree data.
	 * @param vestingTreeRoot_ Vesting tree root hash
	 * @param vestingStartTimestamp_ Timestamp of vesting start as seconds since the Unix epoch
	 * @param proofBalance_ Proof of total balance
	 * @param treasurers_ Addresses of authorized treasurers
	 **/
	constructor(
		string memory name_,
		string memory symbol_,
		uint256 supply_,
		string memory uriIPFS_,
		bytes32 vestingTreeRoot_,
		uint256 vestingStartTimestamp_,
		bytes32[] memory proofBalance_,
		address[] memory treasurers_
	) ERC20(name_, symbol_) {
		uint256 supply = supply_ * uint256(10)**decimals();

		/**
		 * @dev
		 * A validation of the supply registered in the merkle tree is made to verify that it
		 * matches the supply that the contract will have and to ensure that sufficient funds
		 * are available to comply with all the TGE assignments.
		**/
		require(
			MerkleProof.verify(proofBalance_, vestingTreeRoot_, keccak256(abi.encodePacked(supply))),
			'The total supply of the contract does not match that of the merketree'
		);

		for(uint256 i = 0; i < treasurers_.length; i++) _treasurers[treasurers_[i]] = true;

		rootWhitelist[vestingTreeRoot_] = true;
		balanceByRootHash[vestingTreeRoot_] = supply;
		VESTING_START_TIMESTAMP = vestingStartTimestamp_;

		emit AddedRoot(vestingTreeRoot_);

		rootURIs.push(uriIPFS_);
		mapRootURIs[vestingTreeRoot_] = uriIPFS_;

		_mint(address(this), supply);
	}

	/**
	 * @dev Verify if an address is a treasury address.
	 * @param t_ Address of treasurer.
	**/
	function isTreasurer(address t_) view public returns(bool) {
		return _treasurers[t_];
	}

	/**
	 * @dev Verify the validity of merkle proof associated with an address.
	 * @param beneficiary_ Address of beneficiary.
	 * @param amount_ Amount vested tokens to be released.
	 * @param cliff_ Lock delay for release.
	 * @param root_ Merkle tree root.
	 * @param proof_ Merkle proof.
	**/
	function verifyProof(
		address beneficiary_,
		uint256 amount_,
		uint256 cliff_,
		bytes32 root_,
		bytes32[] calldata proof_
	) external view returns(bool) {
		if(!rootWhitelist[root_]) return false;
		bytes32 _leaf = keccak256(abi.encodePacked(beneficiary_, amount_, cliff_));
		return MerkleProof.verify(proof_, root_, _leaf);
	}

	/**
	 * @dev Add a new merkle tree hash. Only addresses registered in the initial Merkle tree as
	 * treasurers have the possibility of adding new Merkle trees, and they are only allowed to
	 * add batches of users that belong to the same group (pool) and with the same allocation date.
	 * @param root_ Merkle tree root of treasurer.
	 * @param newRoot_ New merkle tree root.
	 * @param amount_ Balance that is assigned to new merkle tree.
	 * @param uriIPFS_ IPFS URI for the initial vesting tree data.
	 * @param allocation_ treasurer allocation
	 * @param balanceProof_ Merkle proof of balance.
	 * @param initialAllocationProof_ Merkle proof initial allocation.
	 * @param newAllocationProof_ Merkle proof new allocation.
	 * @param allocationQuantityProof_ Merkle proof allocation quantity.
	 * @param vestingSchedules_ Array of vestingData.
	**/
	function addRoot(
		bytes32 root_,
		bytes32 newRoot_,
		uint256 amount_,
		string memory uriIPFS_,
		Allocation memory allocation_,
		bytes32[] memory balanceProof_,
		bytes32[] memory initialAllocationProof_,
		bytes32[] memory newAllocationProof_,
		bytes32[] memory allocationQuantityProof_,
		VestingData[] calldata vestingSchedules_
	) external validRoot(root_) {
		require(isTreasurer(msg.sender), 'Caller is not a treasurer');

		require(MerkleProof.verify(
			allocationQuantityProof_,
			newRoot_,
			keccak256(abi.encodePacked('ALLOCATION_QUANTITY', uint256(1)))
		), 'The quantity of the allocation of the new Merkle tree is invalid');

		/// @dev the allocation dates of the treasurer who is adding a new merkle tree must match
		// the one assigned in the original merkle tree
		require(
			MerkleProof.verify(
				initialAllocationProof_,
				root_,
				keccak256(abi.encodePacked(
					msg.sender,
					allocation_.unlocking,
					allocation_.monthly,
					allocation_.months,
					allocation_.cliff
				))
			)
			&&
			MerkleProof.verify(
				newAllocationProof_,
				newRoot_,
				keccak256(abi.encodePacked(
					msg.sender,
					allocation_.unlocking,
					allocation_.monthly,
					allocation_.months,
					allocation_.cliff
				))
			),
			'Allocation type of the new Merkle tree is invalid'
		);

		require(
			MerkleProof.verify(balanceProof_, newRoot_, keccak256(abi.encodePacked(amount_))),
			'The supply sent does not match that of the merketree'
		);

		bytes32 r = root_;
		uint256 balance = 0;

		for(uint256 i = 0; i < vestingSchedules_.length; i++) {
			(
				address beneficiary,
				uint256 amount,
				uint256 cliff,
				bytes32[] calldata proof
			) = _splitVestingSchedule(vestingSchedules_[i]);

			require(beneficiary == msg.sender, 'You cannot claim tokens from another user');

			bytes32 leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff));

			if(!vestingClaimed[leaf]) {
				require(
					MerkleProof.verify(proof, r, leaf), 'Invalid merkle proof'
				);

				require(balanceByRootHash[r] >= amount, 'Supply is not enough to claim allocation');

				vestingClaimed[leaf] = true;
				balanceByRootHash[r] -= amount;
				balance += amount;

				emit VestedTokenGrant(leaf);
			}
		}

		require(!rootWhitelist[newRoot_], 'Root hash already exists');
		require(amount_ == balance, 'Amount is different from balance');

		rootWhitelist[newRoot_] = true;
		balanceByRootHash[newRoot_] = amount_;

		rootURIs.push(uriIPFS_);
		mapRootURIs[newRoot_] = uriIPFS_;

		emit AddedRoot(newRoot_);
	}

	/**
	 * @dev Release vesting in batches
	 * @param vestingSchedules_ Array of vesting schedule
	 * @param root_ Merkle tree root
	**/
	function batchReleaseVested(VestingData[] calldata vestingSchedules_, bytes32 root_) external {
		for(uint256 i = 0; i < vestingSchedules_.length; i++) {
			(
				address beneficiary,
				uint256 amount,
				uint256 cliff,
				bytes32[] calldata proof
			) = _splitVestingSchedule(vestingSchedules_[i]);

			bytes32 _leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff));
			if(!vestingClaimed[_leaf]) _releaseVested(beneficiary, amount, cliff, root_, proof);
		}
	}

	/**
	 * @dev Release vesting associated with an address
	 * @param _beneficiary Address of beneficiary
	 * @param _amount Amount vested tokens to be released
	 * @param _cliff Lock delay for release
	 * @param _root Merkle tree root
	 * @param _proof Merkle proof
	**/
	function releaseVested(
		address _beneficiary,
		uint256 _amount,
		uint256 _cliff,
		bytes32 _root,
		bytes32[] calldata _proof
	) external {
		_releaseVested(_beneficiary, _amount, _cliff, _root, _proof);
	}

	/**
	 * @dev Release vesting associated with an address
	 * @param beneficiary_ Address of beneficiary
	 * @param amount_ Amount vested tokens to be released
	 * @param cliff_ Lock delay for release
	 * @param root_ Merkle tree root
	 * @param proof_ Merkle proof
	**/
	function _releaseVested(
		address beneficiary_,
		uint256 amount_,
		uint256 cliff_,
		bytes32 root_,
		bytes32[] calldata proof_
	) internal validRoot(root_) {
		bytes32 leaf = keccak256(abi.encodePacked(beneficiary_, amount_, cliff_));

		require(
			MerkleProof.verify(proof_, root_, leaf), 'Invalid merkle proof'
		);

		require(!vestingClaimed[leaf], 'Tokens already claimed');
		require(balanceByRootHash[root_] >= amount_, 'Supply is not enough to claim allocation');
		require(
			block.timestamp >= VESTING_START_TIMESTAMP + cliff_,
			"The release date has not yet arrived"
		);

		require(!isTreasurer(beneficiary_), "Treasury addresses cannot claim tokens");

		vestingClaimed[leaf] = true;
		balanceByRootHash[root_] -= amount_;
		_transfer(address(this), beneficiary_, amount_);

		emit VestedTokenGrant(leaf);
	}

	function _splitVestingSchedule(VestingData calldata _user) internal pure returns(
		address beneficiary,
		uint256 amount,
		uint256 cliff,
		bytes32[] calldata proof
	) {
		return (_user.beneficiary, _user.amount, _user.cliff, _user.proof);
	}
}