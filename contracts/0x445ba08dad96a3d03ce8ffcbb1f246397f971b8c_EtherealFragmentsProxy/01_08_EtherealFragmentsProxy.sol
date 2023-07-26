// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "contracts/EtherealFragmentsStorage.sol";

contract EtherealFragmentsProxy is EtherealFragmentsStorage, Proxy {
	event MainContractUpdated(address indexed _oldContract, address indexed _newContract);

	constructor(address _contract, address _few, address _fews) {
		_mainContract = _contract;
		worldsContract = IEtherealWorlds(_few);
		specialWorldsContract = IEtherealWorlds(_fews);

		_mint(0x17020cBf555670aB1c7f3e64a80dA61b0B4990c0, 2500 ether);

		uint256 _rewards = (BASE_RATE * (block.timestamp - 1643533200) / 86400) + BASE_RATE;

		for(uint256 i = 0; i < 345; i++) {
			lastUpdate[i] = block.timestamp;
			_mint(worldsContract.ownerOf(i), _rewards);
		}

		lastUpdate[345] = 1645606800;
		lastUpdate[346] = 1645606800;
		lastUpdate[347] = 1645606800;
		lastUpdate[348] = 1645606800;
		lastUpdate[349] = 1645606800;
	}

	function _implementation() internal view override returns (address) {
		return _mainContract;
	}

	// Needed so etherscan can verify the contract as a proxy
	function proxyType() external pure returns (uint256) {
		return 2;
	}

	// Needed so etherscan can verify the contract as a proxy
	function implementation() external view returns (address) {
		return _implementation();
	}

	function setMainContracts(address _newContract, address _few, address _fews) public onlyOwner {
		address _oldContract = _newContract;
		_mainContract = _newContract;
		worldsContract = IEtherealWorlds(_few);
		specialWorldsContract = IEtherealWorlds(_fews);

		emit MainContractUpdated(_oldContract, _newContract);
	}
}