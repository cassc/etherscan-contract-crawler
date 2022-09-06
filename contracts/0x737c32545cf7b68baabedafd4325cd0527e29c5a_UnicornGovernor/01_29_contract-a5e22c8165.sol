// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/governance/GovernorUpgradeable.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/Initializable.sol";
import "@openzeppelin/[email protected]/access/OwnableUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";

contract UnicornGovernor is Initializable, GovernorUpgradeable, GovernorSettingsUpgradeable, GovernorCountingSimpleUpgradeable, GovernorVotesUpgradeable, GovernorVotesQuorumFractionUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IVotesUpgradeable _token) initializer public {
        __Governor_init("UnicornGovernor");
        __GovernorSettings_init(10 /* 10 block */, 183273 /* 4 week */, 1e18);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(4);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}