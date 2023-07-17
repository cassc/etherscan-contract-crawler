// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./StakingRegistry.sol";

// https://docs.synthetix.io/contracts/Owned
abstract contract RollOwned {
	address public owner;
	address public nominatedOwner;
	IStakingRegistry public immutable registry;

	constructor(address _owner, address _registry) {
		require(_owner != address(0), "Owner address cannot be 0");
		owner = _owner;
		registry = IStakingRegistry(_registry);
		emit OwnerChanged(address(0), _owner);
	}

	function nominateNewOwner(address _owner) external onlyOwner {
		nominatedOwner = _owner;
		emit OwnerNominated(_owner);
	}

	function acceptOwnership() external {
		require(
			msg.sender == nominatedOwner,
			"You must be nominated before you can accept ownership"
		);
		emit OwnerChanged(owner, nominatedOwner);
		registry.assignOwnerToContract(address(this), nominatedOwner, owner);
		owner = nominatedOwner;
		nominatedOwner = address(0);
	}

	modifier onlyOwner {
		_onlyOwner();
		_;
	}

	function _onlyOwner() private view {
		require(
			msg.sender == owner,
			"Only the contract owner may perform this action"
		);
	}

	event OwnerNominated(address newOwner);
	event OwnerChanged(address oldOwner, address newOwner);
}