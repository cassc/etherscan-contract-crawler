// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "IAggregatorV3Interface.sol";
import "Merkle.sol";
import "GenesisPass.sol";

contract GenesisMint is Ownable, Merkle {
	uint256 immutable public MAX_MINT;
	uint256 immutable public MINT_PRICE;

	address payable public recipient;
	bool public whitelistMint;
	address public genesisPass;
	uint256 public currentPrio;
	uint256 public currentMint = 1;

	constructor(uint256 _max, uint256 _price, address _recipient) {
		require(_recipient != address(0), "GenesisMint: null");
		recipient = payable(_recipient);
		MAX_MINT = _max;
		MINT_PRICE = _price;
	}

	modifier onlyRecipient() {
		if (msg.sender != address(recipient)) revert("GenesisMint: !recipient");
		_;
	}

	function updateRecipient(address _newRecipient) external onlyRecipient {
		recipient = payable(_newRecipient);
	}

	function fetch() external onlyRecipient {
		(bool res, ) = recipient.call{value:address(this).balance}("");
		require(res);
	}

	function setGenPassAddress(address _gen) external onlyOwner {
		genesisPass = _gen;
	}

	function setPrio(uint256 _prio) external onlyOwner {
		currentPrio = _prio;
	}

	function udpateMerkleRoot(bytes32 _newRoot) external onlyOwner {
		if (whitelistMint) revert("GenesisMint: started");
		merkleRoot = _newRoot;
	}

	function setWhitelistMint(bool _val) external onlyOwner {
		whitelistMint = _val;
	}

	function reserveFor(address _to) external onlyOwner {
		uint256 current = currentMint;
		if (current > MAX_MINT) revert("GenesisMint: max"); 
		currentMint = current + 1;
		GenesisPass(genesisPass).mint(_to, current);
	}

	function mintPass(uint256 _index, uint256 _prio, bool _readTermOfServices, bytes32[] calldata _proof) external payable {
		if (!whitelistMint) revert("GenesisMint: Public mint has not started");
		if (msg.value != MINT_PRICE) revert("GenesisMint: Incorrect expected value");
		if (!_readTermOfServices) revert("GenesisMint: Did not accept terms and services");
		uint256 current = currentMint;
		if (current > MAX_MINT) revert("GenesisMint: max"); 
		if (_prio > currentPrio) revert("GenesisMint: prio");
		
		currentMint = current + 1;
		if (currentPrio < 10)
			_claim(_index, msg.sender, 1, _prio, _proof);
		else {
			_verify(_index, msg.sender, 1, _prio, _proof);
		}
		GenesisPass(genesisPass).mint(msg.sender, current);
	}
}