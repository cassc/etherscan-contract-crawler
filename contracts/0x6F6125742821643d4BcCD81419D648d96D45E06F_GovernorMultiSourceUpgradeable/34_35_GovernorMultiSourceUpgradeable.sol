// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./GovernorVotesMultiSourceUpgradeable.sol";
import "../claim/interfaces/IVotesLite.sol";

contract GovernorMultiSourceUpgradeable is Initializable, GovernorUpgradeable, GovernorCountingSimpleUpgradeable, GovernorVotesMultiSourceUpgradeable, GovernorVotesQuorumFractionUpgradeable, GovernorTimelockControlUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /**
    This contract modifies OpenZeppelin's Governor to tally votes from multiple sources:
    - the ERC20 voting token
    - other contracts where voting power for each account monotonically decreases

    Because GovernorVotesQuorumFractionUpgradeable functionality is unchanged and vote sources may apply a voting factor other than one,
    the percentage of total voting power required to reach quorum may differ somewhat from the value specified
    (e.g. a 5% quorum of 1B votes is 50m votes, but if total voting power is 2B due to tokens in voting sources, the actual quorum of total voting power required to pass a proposal will be 2.5%)
    */

	/// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IVotesUpgradeable _token, TimelockControllerUpgradeable _timelock, IVotesLite[] calldata _voteSources)
        initializer public virtual
    {
        __Governor_init("Governor");
        __GovernorCountingSimple_init();
        __GovernorVotesMultiSource_init(_token, _voteSources);
        __GovernorVotesQuorumFraction_init(5); // the quorum numerator (5%)
        __GovernorTimelockControl_init(_timelock);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function NAME() external pure returns (string memory) {
        return 'GovernorMultiSourceUpgradeable';
    }
    
    function VERSION() external pure returns (uint) {
        return 1;
    }

    function votingDelay() public pure virtual override returns (uint256) {
        return 6545; // 1 day at 12 seconds per block
    }

    function votingPeriod() public pure virtual override returns (uint256) {
        return 50400; // 1 week at 12 seconds per block
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 100000000000000000000000; // 0.01% of 1B token supply (100,000 tokens)
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    function _getVotes(address account, uint256 blockNumber, bytes memory _data)
        internal
        view
        // THIS LINE IS MODIFIED FROM OZ DEFAULTS
        override(GovernorUpgradeable, GovernorVotesUpgradeable, GovernorVotesMultiSourceUpgradeable)
        returns (uint256 votes)
    {
        return super._getVotes(account, blockNumber, _data);
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(GovernorUpgradeable, IGovernorUpgradeable)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId) 
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}