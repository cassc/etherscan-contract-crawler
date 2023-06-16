/**
 *Submitted for verification at Etherscan.io on 2019-08-18
*/

pragma solidity 0.5.8;
// From: https://github.com/mixbytes/solidity/blob/master/contracts/ownership/multiowned.sol
// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

// Code taken from https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
// Audit, refactoring and improvements by github.com/Eenae

// @authors:
// Gav Wood <[email protected]>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyOwner (just own owned) or onlyManyOwners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.


/// note: during any ownership changes all pending operations (waiting for more signatures) are cancelled
// TODO acceptOwnership
contract multiowned {

	// TYPES

	// struct for the status of a pending operation.
	struct MultiOwnedOperationPendingState {
		// count of confirmations needed
		uint256 yetNeeded;

		// bitmap of confirmations where owner #ownerIndex's decision corresponds to 2**ownerIndex bit
		uint256 ownersDone;

		// position of this operation key in m_multiOwnedPendingIndex
		uint256 index;
	}

	// EVENTS

	event Confirmation(address owner, bytes32 operation);
	event Revoke(address owner, bytes32 operation);
	event FinalConfirmation(address owner, bytes32 operation);

	// some others are in the case of an owner changing.
	event OwnerChanged(address oldOwner, address newOwner);
	event OwnerAdded(address newOwner);
	event OwnerRemoved(address oldOwner);

	// the last one is emitted if the required signatures change
	event RequirementChanged(uint256 newRequirement);

	// MODIFIERS

	// simple single-sig function modifier.
	modifier onlyOwner {
		require(isOwner(msg.sender), "Auth");
		_;
	}
	// multi-sig function modifier: the operation must have an intrinsic hash in order
	// that later attempts can be realised as the same underlying operation and
	// thus count as confirmations.
	modifier onlyManyOwners(bytes32 _operation) {
		if (confirmAndCheck(_operation)) {
			_;
		}
		// Even if required number of confirmations has't been collected yet,
		// we can't throw here - because changes to the state have to be preserved.
		// But, confirmAndCheck itself will throw in case sender is not an owner.
	}

	modifier validNumOwners(uint256 _numOwners) {
		require(_numOwners > 0 && _numOwners <= c_maxOwners, "NumOwners OOR");
		_;
	}

	modifier multiOwnedValidRequirement(uint256 _required, uint256 _numOwners) {
		require(_required > 0 && _required <= _numOwners, "Req OOR");
		_;
	}

	modifier ownerExists(address _address) {
		require(isOwner(_address), "Auth");
		_;
	}

	modifier ownerDoesNotExist(address _address) {
		require(!isOwner(_address), "Is owner");
		_;
	}

	modifier multiOwnedOperationIsActive(bytes32 _operation) {
		require(isOperationActive(_operation), "NoOp");
		_;
	}

	// METHODS

	// constructor is given number of sigs required to do protected "onlyManyOwners" transactions
	// as well as the selection of addresses capable of confirming them (msg.sender is not added to the owners!).
	constructor (address[] memory _owners, uint256 _required)
		public
		validNumOwners(_owners.length)
		multiOwnedValidRequirement(_required, _owners.length)
	{
		assert(c_maxOwners <= 255);

		m_numOwners = _owners.length;
		m_multiOwnedRequired = _required;

		for (uint256 i = 0; i < _owners.length; ++i)
		{
			address owner = _owners[i];
			// invalid and duplicate addresses are not allowed
			require(address(0) != owner && !isOwner(owner), "Exists");  /* not isOwner yet! */

			uint256 currentOwnerIndex = checkOwnerIndex(i + 1);  /* first slot is unused */
			m_owners[currentOwnerIndex] = owner;
			m_ownerIndex[owner] = currentOwnerIndex;
		}

		assertOwnersAreConsistent();
	}

	/// @notice replaces an owner `_from` with another `_to`.
	/// @param _from address of owner to replace
	/// @param _to address of new owner
	// All pending operations will be canceled!
	function changeOwner(address _from, address _to)
		external
		ownerExists(_from)
		ownerDoesNotExist(_to)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
		m_owners[ownerIndex] = _to;
		m_ownerIndex[_from] = 0;
		m_ownerIndex[_to] = ownerIndex;

		assertOwnersAreConsistent();
		emit OwnerChanged(_from, _to);
	}

	/// @notice adds an owner
	/// @param _owner address of new owner
	// All pending operations will be canceled!
	function addOwner(address _owner)
		external
		ownerDoesNotExist(_owner)
		validNumOwners(m_numOwners + 1)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		m_numOwners++;
		m_owners[m_numOwners] = _owner;
		m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

		assertOwnersAreConsistent();
		emit OwnerAdded(_owner);
	}

	/// @notice removes an owner
	/// @param _owner address of owner to remove
	// All pending operations will be canceled!
	function removeOwner(address _owner)
		external
		ownerExists(_owner)
		validNumOwners(m_numOwners - 1)
		multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
		onlyManyOwners(keccak256(msg.data))
	{
		assertOwnersAreConsistent();

		clearPending();
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
		m_owners[ownerIndex] = address(0);
		m_ownerIndex[_owner] = 0;
		//make sure m_numOwners is equal to the number of owners and always points to the last owner
		reorganizeOwners();

		assertOwnersAreConsistent();
		emit OwnerRemoved(_owner);
	}

	/// @notice changes the required number of owner signatures
	/// @param _newRequired new number of signatures required
	// All pending operations will be canceled!
	function changeRequirement(uint256 _newRequired)
		external
		multiOwnedValidRequirement(_newRequired, m_numOwners)
		onlyManyOwners(keccak256(msg.data))
	{
		m_multiOwnedRequired = _newRequired;
		clearPending();
		emit RequirementChanged(_newRequired);
	}

	/// @notice Gets an owner by 0-indexed position
	/// @param ownerIndex 0-indexed owner position
	function getOwner(uint256 ownerIndex) public view returns (address) {
		return m_owners[ownerIndex + 1];
	}

	/// @notice Gets owners
	/// @return memory array of owners
	function getOwners() public view returns (address[] memory) {
		address[] memory result = new address[](m_numOwners);
		for (uint256 i = 0; i < m_numOwners; i++)
			result[i] = getOwner(i);

		return result;
	}

	/// @notice checks if provided address is an owner address
	/// @param _addr address to check
	/// @return true if it's an owner
	function isOwner(address _addr) public view returns (bool) {
		return m_ownerIndex[_addr] > 0;
	}

	/// @notice Tests ownership of the current caller.
	/// @return true if it's an owner
	// It's advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
	// addOwner/changeOwner and to isOwner.
	function amIOwner() external view onlyOwner returns (bool) {
		return true;
	}

	/// @notice Revokes a prior confirmation of the given operation
	/// @param _operation operation value, typically keccak256(msg.data)
	function revoke(bytes32 _operation)
		external
		multiOwnedOperationIsActive(_operation)
		onlyOwner
	{
		uint256 ownerIndexBit = makeOwnerBitmapBit(msg.sender);
		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];
		require(pending.ownersDone & ownerIndexBit > 0, "Auth");

		assertOperationIsConsistent(_operation);

		pending.yetNeeded++;
		pending.ownersDone -= ownerIndexBit;

		assertOperationIsConsistent(_operation);
		emit Revoke(msg.sender, _operation);
	}

	/// @notice Checks if owner confirmed given operation
	/// @param _operation operation value, typically keccak256(msg.data)
	/// @param _owner an owner address
	function hasConfirmed(bytes32 _operation, address _owner)
		external
		view
		multiOwnedOperationIsActive(_operation)
		ownerExists(_owner)
		returns (bool)
	{
		return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
	}

	// INTERNAL METHODS

	function confirmAndCheck(bytes32 _operation)
		internal
		onlyOwner
		returns (bool)
	{
		if (512 == m_multiOwnedPendingIndex.length)
			// In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
			// we won't be able to do it because of block gas limit.
			// Yes, pending confirmations will be lost. Dont see any security or stability implications.
			// TODO use more graceful approach like compact or removal of clearPending completely
			clearPending();

		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];

		// if we're not yet working on this operation, switch over and reset the confirmation status.
		if (! isOperationActive(_operation)) {
			// reset count of confirmations needed.
			pending.yetNeeded = m_multiOwnedRequired;
			// reset which owners have confirmed (none) - set our bitmap to 0.
			pending.ownersDone = 0;
			pending.index = m_multiOwnedPendingIndex.length++;
			m_multiOwnedPendingIndex[pending.index] = _operation;
			assertOperationIsConsistent(_operation);
		}

		// determine the bit to set for this owner.
		uint256 ownerIndexBit = makeOwnerBitmapBit(msg.sender);
		// make sure we (the message sender) haven't confirmed this operation previously.
		if (pending.ownersDone & ownerIndexBit == 0) {
			// ok - check if count is enough to go ahead.
			assert(pending.yetNeeded > 0);
			if (pending.yetNeeded == 1) {
				// enough confirmations: reset and run interior.
				delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
				delete m_multiOwnedPending[_operation];
				emit FinalConfirmation(msg.sender, _operation);
				return true;
			}
			else
			{
				// not enough: record that this owner in particular confirmed.
				pending.yetNeeded--;
				pending.ownersDone |= ownerIndexBit;
				assertOperationIsConsistent(_operation);
				emit Confirmation(msg.sender, _operation);
			}
		}
	}

	// Reclaims free slots between valid owners in m_owners.
	// TODO given that its called after each removal, it could be simplified.
	function reorganizeOwners() private {
		uint256 free = 1;
		uint256 numberOfOwners = m_numOwners;
		while (free < numberOfOwners)
		{
			// iterating to the first free slot from the beginning
			while (free < numberOfOwners && m_owners[free] != address(0)) free++;

			// iterating to the first occupied slot from the end
			while (numberOfOwners > 1 && m_owners[numberOfOwners] == address(0)) numberOfOwners--;

			// swap, if possible, so free slot is located at the end after the swap
			if (free < numberOfOwners && m_owners[numberOfOwners] != address(0) && m_owners[free] == address(0))
			{
				// owners between swapped slots should't be renumbered - that saves a lot of gas
				m_owners[free] = m_owners[numberOfOwners];
				m_ownerIndex[m_owners[free]] = free;
				m_owners[numberOfOwners] = address(0);
			}
		}
		m_numOwners = numberOfOwners;
	}

	function clearPending() private onlyOwner {
		uint256 length = m_multiOwnedPendingIndex.length;
		// TODO block gas limit
		for (uint256 i = 0; i < length; ++i) {
			if (m_multiOwnedPendingIndex[i] != 0)
				delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
		}
		delete m_multiOwnedPendingIndex;
	}

	function checkOwnerIndex(uint256 ownerIndex) internal pure returns (uint256) {
		assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
		return ownerIndex;
	}

	function makeOwnerBitmapBit(address owner) private view returns (uint256) {
		uint256 ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
		return 2 ** ownerIndex;
	}

	function isOperationActive(bytes32 _operation) private view returns (bool) {
		return 0 != m_multiOwnedPending[_operation].yetNeeded;
	}


	function assertOwnersAreConsistent() private view {
		assert(m_numOwners > 0);
		assert(m_numOwners <= c_maxOwners);
		assert(m_owners[0] == address(0));
		assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
	}

	function assertOperationIsConsistent(bytes32 _operation) private view {
		MultiOwnedOperationPendingState storage pending = m_multiOwnedPending[_operation];
		assert(0 != pending.yetNeeded);
		assert(m_multiOwnedPendingIndex[pending.index] == _operation);
		assert(pending.yetNeeded <= m_multiOwnedRequired);
	}


	// FIELDS

	uint256 constant c_maxOwners = 250;

	// the number of owners that must confirm the same operation before it is run.
	uint256 public m_multiOwnedRequired;


	// pointer used to find a free slot in m_owners
	uint256 public m_numOwners;

	// list of owners (addresses),
	// slot 0 is unused so there are no owner which index is 0.
	// TODO could we save space at the end of the array for the common case of <10 owners? and should we?
	address[256] internal m_owners;

	// index on the list of owners to allow reverse lookup: owner address => index in m_owners
	mapping(address => uint256) internal m_ownerIndex;


	// the ongoing operations.
	mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
	bytes32[] internal m_multiOwnedPendingIndex;
}


/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* See https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	/*
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return a / b;
	}
	*/

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


/**
* @title Basic token
* @dev Basic version of StandardToken, with no allowances.
*/
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev Transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0), "Self");
		require(_value <= balances[msg.sender], "NSF");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

}


/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);

	function transferFrom(address from, address to, uint256 value) public returns (bool);

	function approve(address spender, uint256 value) public returns (bool);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}


/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* https://github.com/ethereum/EIPs/issues/20
* Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;


	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
	public
	returns (bool)
	{
		require(_to != address(0), "Invl");
		require(_value <= balances[_from], "NSF");
		require(_value <= allowed[_from][msg.sender], "NFAllowance");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	* Beware that changing an allowance with this method brings the risk that someone may use both the old
	* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	* race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function to check the amount of tokens that an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* @return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(
		address _owner,
		address _spender
	)
	public
	view
	returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	/**
	* @dev Increase the amount of tokens that an owner allowed to a spender.
	* approve should be called when allowed[_spender] == 0. To increment
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _addedValue The amount of tokens to increase the allowance by.
	*/
	function increaseApproval(
		address _spender,
		uint256 _addedValue
	)
	public
	returns (bool)
	{
		allowed[msg.sender][_spender] = (
		allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	* @dev Decrease the amount of tokens that an owner allowed to a spender.
	* approve should be called when allowed[_spender] == 0. To decrement
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _subtractedValue The amount of tokens to decrease the allowance by.
	*/
	function decreaseApproval(
		address _spender,
		uint256 _subtractedValue
	)
	public
	returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

contract SparksterTokenSwap is StandardToken, multiowned {
	using SafeMath for uint256;
	struct Member {
		mapping(uint256 => uint256) weiBalance; // How much wei has this member contributed for this group?
		uint256[] groups; // A list of groups this member belongs to.
		// Used to see how many locked tokens this user has so we don't have to iterate over all groups;
		// we can just iterate over the groups this user belongs to.
	}

	enum GroupStates {
		none,
		distributing,
		distributed,
		unlocked // This value is only set for groups that don't define an unlock time.
		// For groups that define an unlock time, the group is unlocked if Group.state == GroupStates.distributed and the unlock time has elapsed; the GroupStates.unlocked state will be ignored.
	}

	struct Group {
		GroupStates state; // Indicates whether the group is distributed or unlocked.
		mapping(address => bool) exists; // If exists[address] is true, this address has made a purchase on this group before.
		string name;
		uint256 ratio; // 1 eth:ratio tokens. This amount represents the decimal amount. ratio*10**decimal = ratio sparks.
		uint256 unlockTime; // The timestamp after which tokens in this group are unlocked.
		// If set to a truthy value, the group will be considered unlocked after this time elapses and the group is distributed.
		uint256 startTime; // Epoch of crowdsale start time.
		uint256 phase1endTime; // Epoch of phase1 end time.
		uint256 phase2endTime; // Epoch of phase2 end time.
		uint256 deadline; // No contributions allowed after this epoch.
		uint256 max2; // cap of phase2
		uint256 max3; // Total ether this group can collect in phase 3.
		uint256 weiTotal; // How much ether has this group collected?
		uint256 cap; // The hard ether cap.
		uint256 nextDistributionIndex; // The next index to start distributing at.
		address[] addresses; // List of addresses that have made a purchase on this group.
	}

	address[] internal initialSigners = [0xCdF06E2F49F7445098CFA54F52C7f43eE40fa016, 0x0D2b5b40F88cCb05e011509830c2E5003d73FE92, 0x363d591196d3004Ca708DB2049501440718594f5];
	address public oracleAddress;
	address constant public oldSprkAddress = 0x971d048E737619884f2df75e31c7Eb6412392328;
	address public owner; // We call this the owner simply because so many ERC-20 contracts have an owner variable,
	// so if an API implements getting the balance of the original token holder by querying balanceOf(owner()), this contract won't break the API.
	// But in our implementation, the contract is multiowned so this owner field has no owning significance besides being the token generator.
	bool public transferLock = true; // A Global transfer lock. Set to lock down all tokens from all groups.
	bool public allowedToBuyBack = false;
	bool public allowedToPurchase = false;
	string public name;									 // name for display
	string public symbol;								 //An identifier
	uint8 public decimals;							//How many decimals to show.
	uint8 constant internal maxGroups = 100; // Total number of groups we are allowed to create.
	uint256 public penalty;
	uint256 public maxGasPrice; // The maximum allowed gas for the purchase function.
	uint256 internal nextGroupNumber;
	uint256 public sellPrice; // sellPrice wei:1 spark token; we won't allow to sell back parts of a token.
	uint256 public minimumRequiredBalance; // How much wei is required for the contract to hold that will cover all refunds.
	// Owners must leave this much in the contract.
	uint256 public openGroupNumber;
	mapping(address => Member) internal members; // For reverse member lookup.
	mapping(uint256 => Group) internal groups; // For reverse group lookup.
	mapping(address => uint256) internal withdrawableBalances; // How much wei is this address allowed to withdraw?
	ERC20 oldSprk; // The old Sparkster token contract
	event WantsToPurchase(address walletAddress, uint256 weiAmount, uint256 groupNumber, bool inPhase1);
	event PurchasedCallbackOnAccept(uint256 groupNumber, address[] addresses);
	event WantsToDistribute(uint256 groupNumber);
	event NearingHardCap(uint256 groupNumber, uint256 remainder);
	event ReachedHardCap(uint256 groupNumber);
	event DistributeDone(uint256 groupNumber);
	event DistributedBatch(uint256 groupNumber, uint256 howMany);
	event ShouldCallDoneDistributing();
	event AirdroppedBatch(address[] addresses);
	event RefundedBatch(address[] addresses);
	event AddToGroup(address walletAddress, uint256 groupNumber);
	event ChangedTransferLock(bool transferLock);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedAllowedToBuyBack(bool allowedToBuyBack);
	event SetSellPrice(uint256 sellPrice);

	modifier onlyOwnerOrOracle() {
		require(isOwner(msg.sender) || msg.sender == oracleAddress, "Auth");
		_;
	}

	modifier onlyManyOwnersOrOracle(bytes32 _operation) {
		if (confirmAndCheck(_operation) || msg.sender == oracleAddress)
			_;
		// Don't throw here since confirmAndCheck needs to preserve state.
	}

	modifier canTransfer() {
		if (!isOwner(msg.sender)) { // Owners are immuned from the transfer lock.
			require(!transferLock, "Locked");
		}
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase, "Disallowed");
		_;
	}

	modifier canSell() {
		require(allowedToBuyBack, "Denied");
		_;
	}

	function() external payable {
		purchase();
	}

	constructor()
	multiowned( initialSigners, 2) public {
		require(isOwner(msg.sender), "NaO");
		oldSprk = ERC20(oldSprkAddress);
		owner = msg.sender;
		name = "Sparkster";									// Set the name for display purposes
		decimals = 18;					 // Amount of decimals for display purposes
		symbol = "SPRK";							// Set the symbol for display purposes
		maxGasPrice = 40 * 10**9; // Set max gas to 40 Gwei to start with.
		uint256 amount = 435000000;
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = decimalAmount;
		balances[msg.sender] = decimalAmount;
		emit Transfer(address(0), msg.sender, decimalAmount); // Per erc20 standards-compliance.
	}

	function swapTokens() public returns(bool) {
		require(msg.sender != address(this), "Self"); // Don't let this contract swap tokens with itself.
		// First, find out how much the sender has allowed us to spend. This is the amount of Sprk we're allowed to move.
		// Sender can set this value by calling increaseApproval on the old contract.
		uint256 amountToTransfer = oldSprk.allowance(msg.sender, address(this));
		require(amountToTransfer > 0, "Amount==0");
		// However many tokens we took away from the user in the old contract, give that amount in our new contract.
		balances[msg.sender] = balances[msg.sender].add(amountToTransfer);
		balances[owner] = balances[owner].sub(amountToTransfer);
		// Finally, transfer the old tokens away from the sender and to our address. This will effectively freeze the tokens because no one can transact on this contract's behalf except the contract.
		require(oldSprk.transferFrom(msg.sender, address(this), amountToTransfer), "Transfer");
		emit Transfer(owner, msg.sender, amountToTransfer);
		return true;
	}

	function setOwnerAddress(address newAddress) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		require(newAddress != address(0), "Invl");
		require(newAddress != owner, "Self");
		uint256 oldOwnerBalance = balances[owner];
		balances[newAddress] = balances[newAddress].add(oldOwnerBalance);
		balances[owner] = 0;
		emit Transfer(owner, newAddress, oldOwnerBalance);
		owner = newAddress;
		return true;
	}

	function setOracleAddress(address newAddress) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		oracleAddress = newAddress;
		return true;
	}

	function removeOracleAddress() public onlyOwner returns(bool) {
		oracleAddress = address(0);
		return true;
	}

	function setMaximumGasPrice(uint256 gweiPrice) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		maxGasPrice = gweiPrice.mul(10**9); // Convert the gwei value to wei.
		return true;
	}

	function purchase() public canPurchase payable returns(bool) {
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0, "Not initialized"); // Group must be initialized.
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline, "OOR");
		// The timestamp must be greater than or equal to the start time and less than or equal to the deadline time
		require(openGroup.state == GroupStates.none, "State");
		// Don't allow to purchase if we're in the middle of distributing, have already distributed, or have unlocked.
		require(tx.gasprice <= maxGasPrice, "Gas price"); // Restrict maximum gas this transaction is allowed to consume.
		uint256 weiAmount = msg.value;																		// The amount purchased by the current member
		// Updated in purchaseCallbackOnAccept.
		require(weiAmount >= 0.1 ether, "Amount<0.1 ether");
		uint256 weiTotal = openGroup.weiTotal.add(weiAmount); // Calculate total contribution of all members in this group.
		// WeiTotals are updated in purchaseCallbackOnAccept
		require(weiTotal <= openGroup.cap, "Cap exceeded");														// Check to see if accepting these funds will put us above the hard ether cap.
		uint256 userWeiTotal = memberRecord.weiBalance[openGroupNumber].add(weiAmount); // Calculate the total amount purchased by the current member
		if (!openGroup.exists[msg.sender]) { // Has this person not purchased on this group before?
			openGroup.addresses.push(msg.sender);
			openGroup.exists[msg.sender] = true;
			memberRecord.groups.push(openGroupNumber);
		}
		if(currentTimestamp <= openGroup.phase1endTime){																			 // whether the current timestamp is in the first phase
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, true);
			return true;
		} else if (currentTimestamp <= openGroup.phase2endTime) { // Are we in phase 2?
			require(userWeiTotal <= openGroup.max2, "Phase2 cap exceeded"); // Allow to contribute no more than max2 in phase 2.
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		} else { // We've passed both phases 1 and 2.
			require(userWeiTotal <= openGroup.max3, "Phase3 cap exceeded"); // Don't allow to contribute more than max3 in phase 3.
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		}
	}

	function purchaseCallbackOnAccept(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool success) {
		return accept(groupNumber, addresses, weiAmounts);
	}

	// Base function for accepts.
	// Calling functions should be multisig.
	function accept(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	private onlyOwnerOrOracle returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
		Group storage theGroup = groups[groupNumber];
		uint256 weiTotal = theGroup.weiTotal;
		for (uint256 i = 0; i < n; i++) {
			Member storage memberRecord = members[addresses[i]];
			uint256 weiAmount = weiAmounts[i];
			weiTotal = weiTotal.add(weiAmount);								 // Calculate the total amount purchased by all members in this group.
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);
			// Record the total amount purchased by the current member
		}
		theGroup.weiTotal = weiTotal;
		if (getHowMuchUntilHardCap_(groupNumber) <= 100 ether) {
			emit NearingHardCap(groupNumber, getHowMuchUntilHardCap_(groupNumber));
			if (weiTotal >= theGroup.cap) {
				emit ReachedHardCap(groupNumber);
			}
		}
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		return true;
	}

	function insertAndApprove(uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
		Group storage theGroup = groups[groupNumber];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
				members[theAddress].groups.push(groupNumber);
			}
		}
		return accept(groupNumber, addresses, weiAmounts);
	}

	function callbackInsertApproveAndDistribute(
		uint256 groupNumber, address[] memory addresses, uint256[] memory weiAmounts)
	public onlyManyOwnersOrOracle(keccak256(msg.data)) returns(bool) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Length");
		require(getGroupState(groupNumber) != GroupStates.unlocked, "Unlocked");
		Group storage theGroup = groups[groupNumber];
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			Member storage memberRecord = members[theAddress];
			uint256 weiAmount = weiAmounts[i];
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);
			// Record the total amount purchased by the current member
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
				memberRecord.groups.push(groupNumber);
			}
			uint256 additionalBalance = weiAmount.mul(theGroup.ratio); // Don't give cumulative tokens; one address can be distributed multiple times.
			if (additionalBalance > 0) {
				balances[theAddress] = balances[theAddress].add(additionalBalance);
				newOwnerSupply = newOwnerSupply.sub(additionalBalance); // Update the available number of tokens.
				emit Transfer(owner, theAddress, additionalBalance); // Notify exchanges of the distribution.
			}
		}
		balances[owner] = newOwnerSupply;
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		if (getGroupState(groupNumber) != GroupStates.distributed)
			theGroup.state = GroupStates.distributed;
		return true;
	}

	function getWithdrawableAmount() public view returns(uint256) {
		return withdrawableBalances[msg.sender];
	}

	function withdraw() public returns (bool) {
		uint256 amount = withdrawableBalances[msg.sender];
		require(amount > 0, "NSF");
		withdrawableBalances[msg.sender] = 0;
		minimumRequiredBalance = minimumRequiredBalance.sub(amount);
		msg.sender.transfer(amount);
		return true;
	}

	function refund(address[] memory addresses, uint256[] memory weiAmounts) public onlyManyOwners(keccak256(msg.data)) returns(bool success) {
		uint256 n = addresses.length;
		require (n == weiAmounts.length, "Length");
		uint256 thePenalty = penalty;
		uint256 totalRefund = 0;
		for(uint256 i = 0; i < n; i++) {
			uint256 weiAmount = weiAmounts[i];
			address payable theAddress = address(uint160(address(addresses[i])));
			if (thePenalty < weiAmount) {
				weiAmount = weiAmount.sub(thePenalty);
				totalRefund = totalRefund.add(weiAmount);
				withdrawableBalances[theAddress] = withdrawableBalances[theAddress].add(weiAmount);
			}
		}
		require(address(this).balance >= minimumRequiredBalance + totalRefund, "NSF"); // The contract must have enough to refund these addresses.
		minimumRequiredBalance = minimumRequiredBalance.add(totalRefund);
		emit RefundedBatch(addresses);
		return true;
	}

	function signalDoneDistributing(uint256 groupNumber) public onlyManyOwnersOrOracle(keccak256(msg.data)) {
		Group storage theGroup = groups[groupNumber];
		theGroup.state = GroupStates.distributed;
		emit DistributeDone(groupNumber);
	}

	function drain(address payable to) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		uint256 amountAllowedToDrain = address(this).balance.sub(minimumRequiredBalance);
		require(amountAllowedToDrain > 0, "NSF");
		to.transfer(amountAllowedToDrain);
		return true;
	}

	function setPenalty(uint256 newPenalty) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		penalty = newPenalty;
		return true;
	}

	function buyback(uint256 amount) public canSell {
		require(sellPrice>0, "sellPrice==0");
		uint256 decimalAmount = amount.mul(uint(10)**decimals); // convert the full token value to the smallest unit possible.
		require(balances[msg.sender].sub(decimalAmount) >= getLockedTokens_(msg.sender), "NSF"); // Don't allow to sell locked tokens.
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount);
		// Amount is considered to be how many full tokens the user wants to sell.
		uint256 totalCost = amount.mul(sellPrice); // sellPrice is the per-full-token value.
		minimumRequiredBalance = minimumRequiredBalance.add(totalCost);
		require(address(this).balance >= minimumRequiredBalance, "NSF"); // The contract must have enough funds to cover the selling.
		balances[owner] = balances[owner].add(decimalAmount); // Put these tokens back into the available pile.
		withdrawableBalances[msg.sender] = withdrawableBalances[msg.sender].add(totalCost); // Pay the seller for their tokens.
		emit Transfer(msg.sender, owner, decimalAmount); // Notify exchanges of the sell.
	}

	function fundContract() public onlyOwnerOrOracle payable { // For the owner to put funds into the contract.
	}

	function setSellPrice(uint256 thePrice) public onlyManyOwners(keccak256(msg.data)) returns (bool) {
		sellPrice = thePrice;
		emit SetSellPrice(thePrice);
		return true;
	}

	function setAllowedToBuyBack(bool value) public onlyManyOwners(keccak256(msg.data)) {
		allowedToBuyBack = value;
		emit ChangedAllowedToBuyBack(value);
	}

	function setAllowedToPurchase(bool value) public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(value);
		return true;
	}

	function createGroup(
		string memory groupName, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch,
		uint256 unlockAfterEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public
	onlyManyOwners(keccak256(msg.data)) returns (bool success, uint256 createdGroupNumber) {
		require(nextGroupNumber < maxGroups, "Too many groups");
		createdGroupNumber = nextGroupNumber;
		Group storage theGroup = groups[createdGroupNumber];
		theGroup.name = groupName;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.unlockTime = unlockAfterEpoch;
		theGroup.max2 = phase2weiCap;
		theGroup.max3 = phase3weiCap;
		theGroup.cap = hardWeiCap;
		theGroup.ratio = ratio;
		nextGroupNumber++;
		success = true;
	}

	function getGroup(uint256 groupNumber) public view returns(string memory groupName, string memory status, uint256 phase2cap,
	uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline,
	uint256 weiTotal) {
		require(groupNumber < nextGroupNumber, "OOR");
		Group storage theGroup = groups[groupNumber];
		groupName = theGroup.name;
		GroupStates state = getGroupState(groupNumber);
		status = (state == GroupStates.none)? "none"
		:(state == GroupStates.distributing)? "distributing"
		:(state == GroupStates.distributed)? "distributed":"unlocked";
		phase2cap = theGroup.max2;
		phase3cap = theGroup.max3;
		cap = theGroup.cap;
		ratio = theGroup.ratio;
		startTime = theGroup.startTime;
		phase1endTime = theGroup.phase1endTime;
		phase2endTime = theGroup.phase2endTime;
		deadline = theGroup.deadline;
		weiTotal = theGroup.weiTotal;
	}

	function getGroupUnlockTime(uint256 groupNumber) public view returns(uint256) {
		require(groupNumber < nextGroupNumber, "OOR");
		Group storage theGroup = groups[groupNumber];
		return theGroup.unlockTime;
	}

	function getHowMuchUntilHardCap_(uint256 groupNumber) internal view returns(uint256) {
		Group storage theGroup = groups[groupNumber];
		if (theGroup.weiTotal > theGroup.cap) { // calling .sub in this situation will throw.
			return 0;
		}
		return theGroup.cap.sub(theGroup.weiTotal);
	}

	function getHowMuchUntilHardCap() public view returns(uint256) {
		return getHowMuchUntilHardCap_(openGroupNumber);
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool) {
		emit AddToGroup(walletAddress, groupNumber);
		return true;
	}

	function instructOracleToDistribute(uint256 groupNumber) public onlyOwnerOrOracle returns(bool) {
		require(groupNumber < nextGroupNumber && getGroupState(groupNumber) < GroupStates.distributed, "Dist");
		emit WantsToDistribute(groupNumber);
		return true;
	}

	function distributeCallback(uint256 groupNumber, uint256 howMany) public onlyManyOwnersOrOracle(keccak256(msg.data)) returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		GroupStates state = getGroupState(groupNumber);
		require(state < GroupStates.distributed, "Dist");
		if (state != GroupStates.distributing) {
			theGroup.state = GroupStates.distributing;
		}
		uint256 n = theGroup.addresses.length;
		uint256 nextDistributionIndex = theGroup.nextDistributionIndex;
		uint256 exclusiveEndIndex = nextDistributionIndex + howMany;
		if (exclusiveEndIndex > n) {
			exclusiveEndIndex = n;
		}
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = nextDistributionIndex; i < exclusiveEndIndex; i++) {
			address theAddress = theGroup.addresses[i];
			uint256 balance = getUndistributedBalanceOf_(theAddress, groupNumber);
			if (balance > 0) { // No need to waste ticks if they have no tokens to distribute
				balances[theAddress] = balances[theAddress].add(balance);
				newOwnerSupply = newOwnerSupply.sub(balance); // Update the available number of tokens.
				emit Transfer(owner, theAddress, balance); // Notify exchanges of the distribution.
			}
		}
		balances[owner] = newOwnerSupply;
		if (exclusiveEndIndex < n) {
			emit DistributedBatch(groupNumber, howMany);
		} else { // We've finished distributing people
			// However, signalDoneDistributing needs to be manually called since it's multisig. So if we're calling this function from multiple owners then calling signalDoneDistributing from here won't work.
			emit ShouldCallDoneDistributing();
		}
		theGroup.nextDistributionIndex = exclusiveEndIndex; // Usually not necessary if we've finished distribution,
		// but if we don't update this, getHowManyLeftToDistribute will never show 0.
		return true;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		return theGroup.addresses.length - theGroup.nextDistributionIndex;
	}

	function unlock(uint256 groupNumber) public onlyManyOwners(keccak256(msg.data)) returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(getGroupState(groupNumber) == GroupStates.distributed, "Undist"); // Distribution must have occurred first.
		require(theGroup.unlockTime == 0, "Unlocktime");
		// If the group has set an explicit unlock time, the admins cannot force an unlock and the unlock will happen automatically.
		theGroup.state = GroupStates.unlocked;
		return true;
	}

	function liftGlobalLock() public onlyManyOwners(keccak256(msg.data)) returns(bool) {
		transferLock = false;
		emit ChangedTransferLock(transferLock);
		return true;
	}

	function airdrop( address[] memory addresses, uint256[] memory tokenDecimalAmounts) public onlyManyOwnersOrOracle(keccak256(msg.data))
	returns (bool) {
		uint256 n = addresses.length;
		require(n == tokenDecimalAmounts.length, "Length");
		uint256 newOwnerBalance = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			uint256 airdropAmount = tokenDecimalAmounts[i];
			if (airdropAmount > 0) {
				uint256 currentBalance = balances[theAddress];
				balances[theAddress] = currentBalance.add(airdropAmount);
				newOwnerBalance = newOwnerBalance.sub(airdropAmount);
				emit Transfer(owner, theAddress, airdropAmount);
			}
		}
		balances[owner] = newOwnerBalance;
		emit AirdroppedBatch(addresses);
		return true;
	}

	function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		require(balances[msg.sender].sub(_value) >= getLockedTokens_(msg.sender), "Not enough tokens");
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		require(balances[_from].sub(_value) >= getLockedTokens_(_from), "Not enough tokens");
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyManyOwners(keccak256(msg.data)) returns (bool) {
		require(groupNumber < nextGroupNumber, "OOR");
		openGroupNumber = groupNumber;
		return true;
	}

	function getGroupState(uint256 groupNumber) public view returns(GroupStates) {
		require(groupNumber < nextGroupNumber, "out of range"); // Must have created at least one group.
		Group storage theGroup = groups[groupNumber];
		if (theGroup.state < GroupStates.distributed)
			return theGroup.state;
		// Here, we have two cases.
		// If this is a time-based group, tokens will only unlock after a certain time. Otherwise, we depend on the group's state being set to unlock.
		if (block.timestamp < theGroup.unlockTime)
			return GroupStates.distributed;
		else if (theGroup.unlockTime > 0) // Here, blocktime exceeds the group unlock time, and we've set an unlock time explicitly
			return GroupStates.unlocked;
		return theGroup.state;
	}

	function getLockedTokensInGroup_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (getGroupState(groupNumber) == GroupStates.unlocked) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(groups[groupNumber].ratio);
	}

	function getLockedTokens_(address walletAddress) internal view returns(uint256 balance) {
		uint256[] storage memberGroups = members[walletAddress].groups;
		uint256 n = memberGroups.length;
		for (uint256 i = 0; i < n; i++) {
			balance = balance.add(getLockedTokensInGroup_(walletAddress, memberGroups[i]));
		}
		return balance;
	}

	function getLockedTokens(address walletAddress) public view returns(uint256 balance) {
		return getLockedTokens_(walletAddress);
	}

	function getUndistributedBalanceOf_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		if (getGroupState(groupNumber) > GroupStates.distributing) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(theGroup.ratio);
	}

	function getUndistributedBalanceOf(address walletAddress, uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(walletAddress, groupNumber);
	}

	function checkMyUndistributedBalance(uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(msg.sender, groupNumber);
	}
	
	function burn(uint256 amount) public onlyManyOwners(keccak256(msg.data)) {
		balances[owner] = balances[owner].sub(amount);
		totalSupply_ = totalSupply_.sub(amount);
		emit Transfer(owner, address(0), amount);
	}
}