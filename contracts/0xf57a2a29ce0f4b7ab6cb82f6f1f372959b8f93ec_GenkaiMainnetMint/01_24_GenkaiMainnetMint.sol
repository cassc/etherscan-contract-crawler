// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "MerkleMainnet.sol";
import "GenkaiRonin.sol";
import "Ownable.sol";
import "IERC20.sol";

error IncorrectMintValue();
error IncorrectMintAmount();
error TooManyMintedAtOnce();
error TooManyMintedPerWallet();
error MintEnded();
error IncorrectPrio();


contract GenkaiMainnetMint is MerkleMainnet, Ownable {
	uint256 immutable public QUANTITY;
	uint256 immutable public MAX_PER_TX;
	uint256 immutable public MAX_PER_WALLET;
	uint256 immutable public PRICE;

	uint256 public prioAndCommitted;
	mapping(address => uint256) public orders;

	constructor(uint256 _quantity, uint256 _max_per_tx, uint256 _max_per_wallet, uint256 _price, uint256 _committed) {
		QUANTITY = _quantity;
		MAX_PER_TX = _max_per_tx;
		MAX_PER_WALLET = _max_per_wallet;
		PRICE = _price;
		prioAndCommitted = _committed;
	}

	event Committed(address user);

	function get() external {
		get(address(this).balance);
	}

	function get(uint256 _amount) public onlyOwner {
		(bool res,) = msg.sender.call{value:_amount}("");
		require (res);
	}

	function stop() external onlyOwner {
		merkleRoot = bytes32(0);
		setPrio(0);
	}

	function updateMerkleRoot(bytes32 _root) external onlyOwner {
		merkleRoot = _root;
	}

	function setCommitted(uint256 _comm) public onlyOwner {
		prioAndCommitted = _comm;
	}

	function setPrio(uint256 _prio) public onlyOwner {
		uint256 blob = prioAndCommitted;
		blob = ((blob << 2) >> 2) | (_prio << 254);
		prioAndCommitted = blob;
	}

	function committed() external view returns(uint256) {
		uint256 blob = prioAndCommitted;
		return (blob << 2) >> 2;
	}

	function currentPrio() external view returns(uint256) {
		uint256 blob = prioAndCommitted;
		return blob >> 254;
	}

	function mint(
		uint256 _amount,
		uint256 _index,
		uint256 _prio,
		uint256 _eligibleAmount,
		bytes32[] calldata _proof) external payable {
		(uint256 current, uint256 committedAmount) = getPrioAndCommitment();
		if (_prio > current) revert IncorrectPrio();
		if (_amount == 0) revert IncorrectMintAmount();
		if (_amount * PRICE != msg.value) revert IncorrectMintValue();
		if (_amount + committedAmount > QUANTITY) revert MintEnded();

		if (_prio == 0 && current == 0) {
			_verify(_index, msg.sender, _eligibleAmount, _prio, _proof);
			if (orders[msg.sender] + _amount > _eligibleAmount) revert IncorrectMintAmount();
			unchecked {
				orders[msg.sender] += _amount;	
			}
		}
		else if (_prio == 1 && current == 1) {
			if (_amount != 1) revert IncorrectMintAmount();
			_claim(_index, msg.sender, 1, _prio, _proof);
			unchecked {
				++orders[msg.sender];
			}
		}
		else if (current == 2) {
			if (_amount > MAX_PER_TX) revert TooManyMintedAtOnce();
			if (_amount + orders[msg.sender] > MAX_PER_WALLET) revert TooManyMintedPerWallet();
			unchecked {
				orders[msg.sender] += _amount;	
			}
		}
		unchecked {
			prioAndCommitted += _amount;
		}
		emit Committed(msg.sender);
	}

	function getPrioAndCommitment() internal view returns(uint256, uint256) {
		uint256 blob = prioAndCommitted;
		return (blob >> 254, (blob << 2) >> 2);
	}

	// function testMint(
	// 	address _user,
	// 	uint256 _amount,
	// 	uint256 _index,
	// 	uint256 _prio,
	// 	uint256 _eligibleAmount,
	// 	bytes32[] calldata _proof) external payable {
	// 	(uint256 current, uint256 committed) = getPrioAndCommitment();
	// 	if (_prio > current) revert IncorrectPrio();
	// 	if (_amount == 0) revert IncorrectMintAmount();
	// 	if (_amount * PRICE != msg.value) revert IncorrectMintValue();
	// 	if (_amount + committed > QUANTITY) revert MintEnded();

	// 	if (_prio == 0 && current == 0) {
	// 		_verify(_index, _user, _eligibleAmount, _prio, _proof);
	// 		if (orders[_user] + _amount > _eligibleAmount) revert IncorrectMintAmount();
	// 		unchecked {
	// 			orders[_user] += _amount;	
	// 		}
	// 	}
	// 	else if (_prio == 1 && current == 1) {
	// 		if (_amount != 1) revert IncorrectMintAmount();
	// 		_claim(_index, _user, 1, _prio, _proof);
	// 		unchecked {
	// 			++orders[_user];
	// 		}
	// 	}
	// 	else if (current == 2) {
	// 		if (_amount > MAX_PER_TX) revert TooManyMintedAtOnce();
	// 		if (_amount + orders[_user] > MAX_PER_WALLET) revert TooManyMintedPerWallet();
	// 		unchecked {
	// 			orders[_user] += _amount;	
	// 		}
	// 	}
	// 	unchecked {
	// 		prioAndCommitted += _amount;
	// 	}
	// 	emit Committed(_user);
	// }
}