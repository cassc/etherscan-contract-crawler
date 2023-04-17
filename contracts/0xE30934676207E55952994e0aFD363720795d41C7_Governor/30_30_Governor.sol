// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Governor is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    UUPSUpgradeable
{
    //*********************************************************************//
    // ----------------------- public constants -------------------------- //
    //*********************************************************************//

    uint256 private constant BLOCK_TIME = 12 seconds;
    uint256 private constant ONE_WEEK = 1 weeks / BLOCK_TIME;

    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, IVotesUpgradeable _votes) public initializer {
        __Governor_init(_name);
        __GovernorSettings_init(ONE_WEEK, ONE_WEEK, 0);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_votes);
        __GovernorVotesQuorumFraction_init(55);
        __UUPSUpgradeable_init();
    }

    //*********************************************************************//
    // ------------------------ internal overrides ----------------------- //
    //*********************************************************************//

    /**
     * Makes it so the only address that can upgrade the proxy is the Governor address (aka this contract itself)
     * @param newImplementation the address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}

    //*********************************************************************//
    // ------------------------ public overrides ------------------------- //
    //*********************************************************************//

    /**
     * @return the voting delay in number of blocks
     */
    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /**
     * @return the voting period in number of blocks
     */
    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /**
     * @param blockNumber the block number to get the quorum for
     * @return the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /**
     * @return The number of votes required in order for a voter to become a proposer
     */
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}