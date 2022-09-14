// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyUpgrades
 * @author Jeremy Guyet (@jguyet)
 * @dev Provides a library allowing the management of updates.
 * Library usable for proxies.
 */
library ProxyUpgrades {

    struct Upgrade {
        uint256 id;
        address submitedNewFunctionalAddress;
        bytes   initializationData;
        uint256 utcStartVote;
        uint256 utcEndVote;
        uint256 totalApproved;
        uint256 totalUnapproved;
        bool isFinished;
    }

    struct Upgrades {
        mapping(uint256 => Upgrade) upgrades;
        mapping(uint256 => mapping(address => address)) participators;
        uint256 counter;
    }

    struct UpgradesSlot {
        Upgrades value;
    }

    /////////
    // Upgrades View
    /////////

    function isEmpty(Upgrades storage upgrades) internal view returns (bool) {
        return upgrades.counter == 0;
    }

    function current(Upgrades storage upgrades) internal view returns (Upgrade storage) {
        return upgrades.upgrades[upgrades.counter - 1];
    }

    function all(Upgrades storage upgrades) internal view returns (Upgrade[] memory) {
        uint256 totalUpgrades = upgrades.counter;
        Upgrade[] memory results = new Upgrade[](totalUpgrades);
        uint256 index = 0;

        for (index; index < totalUpgrades; index++) {
            Upgrade storage upgrade = upgrades.upgrades[index];

            results[index].id = upgrade.id;
            results[index].submitedNewFunctionalAddress = upgrade.submitedNewFunctionalAddress;
            results[index].initializationData = upgrade.initializationData;
            results[index].utcStartVote = upgrade.utcStartVote;
            results[index].utcEndVote = upgrade.utcEndVote;
            results[index].totalApproved = upgrade.totalApproved;
            results[index].totalUnapproved = upgrade.totalUnapproved;
            results[index].isFinished = upgrade.isFinished;
        }
        return results;
    }

    function getLastUpgrade(Upgrades storage upgrades) internal view returns (Upgrade memory) {
        Upgrade memory result;
        Upgrade storage upgrade = upgrades.upgrades[upgrades.counter - 1];
                    
        result.id = upgrade.id;
        result.submitedNewFunctionalAddress = upgrade.submitedNewFunctionalAddress;
        result.initializationData = upgrade.initializationData;
        result.utcStartVote = upgrade.utcStartVote;
        result.utcEndVote = upgrade.utcEndVote;
        result.totalApproved = upgrade.totalApproved;
        result.totalUnapproved = upgrade.totalUnapproved;
        result.isFinished = upgrade.isFinished;
        return result;
    }

    /////////
    // Upgrade View
    /////////

    function hasVoted(Upgrade storage upgrade, Upgrades storage upgrades, address _checkAddress) internal view returns (bool) {
        return upgrades.participators[upgrade.id][_checkAddress] == _checkAddress;
    }

    function voteInProgress(Upgrade storage upgrade) internal view returns (bool) {
        return upgrade.utcStartVote < block.timestamp
            && upgrade.utcEndVote > block.timestamp;
    }

    function voteFinished(Upgrade storage upgrade) internal view returns (bool) {
        return upgrade.utcStartVote < block.timestamp
            && upgrade.utcEndVote < block.timestamp;
    }

    /////////
    // Upgrades Functions
    /////////

    function add(Upgrades storage upgrades, address _submitedNewFunctionalAddress, bytes memory _initializationData, uint256 _utcStartVote, uint256 _utcEndVote) internal {
        unchecked {
            uint256 id = upgrades.counter++;
            
            upgrades.upgrades[id].id = id;
            upgrades.upgrades[id].submitedNewFunctionalAddress = _submitedNewFunctionalAddress;
            upgrades.upgrades[id].initializationData = _initializationData;
            upgrades.upgrades[id].utcStartVote = _utcStartVote;
            upgrades.upgrades[id].utcEndVote = _utcEndVote;
            upgrades.upgrades[id].totalApproved = 0;
            upgrades.upgrades[id].totalUnapproved = 0;
            upgrades.upgrades[id].isFinished = false;
        }
    }

    /////////
    // Upgrade Functions
    /////////

    function vote(Upgrade storage upgrade, Upgrades storage upgrades, address _from, uint256 _votes, bool _approved) internal {
        unchecked {
            if (_approved) {
                upgrade.totalApproved += _votes;
            } else {
                upgrade.totalUnapproved += _votes;
            }
            upgrades.participators[upgrade.id][_from] = _from;
        }
    }

    function setFinished(Upgrade storage upgrade, bool _finished) internal {
        unchecked {
            upgrade.isFinished = _finished;
        }
    }

    /**
     * @dev Returns an `UpgradesSlot` with member `value` located at `slot`.
     */
    function getUpgradesSlot(bytes32 slot) internal pure returns (UpgradesSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}