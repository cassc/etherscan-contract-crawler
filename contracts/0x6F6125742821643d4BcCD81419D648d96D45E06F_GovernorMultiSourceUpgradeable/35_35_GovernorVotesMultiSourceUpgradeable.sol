// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";

import "../claim/interfaces/IVotesLite.sol";

abstract contract GovernorVotesMultiSourceUpgradeable is GovernorUpgradeable, GovernorVotesUpgradeable {
	// IMPORTANT: voting source acccount balances must monotonically decrease to prevent double voting
	// primary use case: vesting contracts
	IVotesLite[] private voteSources;

	modifier validVoteSources(IVotesLite[] calldata _voteSources) {
		for (uint i = 0; i < _voteSources.length;) {
			require(_voteSources[i].getTotalVotes() > 0, "GovernorVotesMultiSourceUpgradeable: source has no votes");
			unchecked {
				++i;
			}
		}

		_;
    }

	function __GovernorVotesMultiSource_init(IVotesUpgradeable tokenAddress, IVotesLite[] calldata _voteSources) internal onlyInitializing {
		__GovernorVotesMultiSource_init__unchained(tokenAddress, _voteSources);
	}

	function __GovernorVotesMultiSource_init__unchained(IVotesUpgradeable tokenAddress, IVotesLite[] calldata _voteSources) internal onlyInitializing validVoteSources(_voteSources) {
		super.__GovernorVotes_init_unchained(tokenAddress);
		voteSources = _voteSources;
	}

	/**
	  Modified from open zeppelin defaults
	*/
    function _getVotes(address account, uint256 blockNumber, bytes memory _data)
        internal
        view
		virtual
        override(GovernorUpgradeable, GovernorVotesUpgradeable)
        returns (uint256 votes)
    {
		// get votes from the ERC20 token
		votes = super._getVotes(account, blockNumber, _data);

		// get votes from the distribution contracts
		IVotesLite[] memory _voteSources = voteSources;
		for (uint i = 0; i < _voteSources.length;) {
			votes+= _voteSources[i].getVotes(account);
			unchecked {
				++i;
			}
		}
    }


	/**
	  New function allowing the DAO to update its vote sources
	*/

	function setVoteSources(IVotesLite[] calldata _voteSources) public onlyGovernance validVoteSources(_voteSources) {
		voteSources = _voteSources;
	}

	function getVoteSources() public view returns (IVotesLite[] memory) {
		return voteSources;
	}

	// permit future upgrades
	uint256[10] private __gap;
}