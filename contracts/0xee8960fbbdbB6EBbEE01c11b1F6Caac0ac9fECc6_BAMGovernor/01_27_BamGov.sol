// SPDX-License-Identifier: MIT
/*

 _______       __       ___      ___  _______   __          ______        __        ________  __    __   
|   _  "\     /""\     |"  \    /"  ||   _  "\ |" \        /" _  "\      /""\      /"       )/" |  | "\  
(. |_)  :)   /    \     \   \  //   |(. |_)  :)||  |      (: ( \___)    /    \    (:   \___/(:  (__)  :) 
|:     \/   /' /\  \    /\\  \/.    ||:     \/ |:  |       \/ \        /' /\  \    \___  \   \/      \/  
(|  _  \\  //  __'  \  |: \.        |(|  _  \\ |.  |       //  \ _    //  __'  \    __/  \\  //  __  \\  
|: |_)  :)/   /  \\  \ |.  \    /:  ||: |_)  :)/\  |\     (:   _) \  /   /  \\  \  /" \   :)(:  (  )  :) 
(_______/(___/    \___)|___|\__/|___|(_______/(__\_|_)     \_______)(___/    \___)(_______/  \__|  |__/  
       
       
       https://t.me/bambicash
       Twitter: @bambicashcrypto
    https://bambi.cash/
                                                                                                         

*/



pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract BAMGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes _token, TimelockController _timelock)
        Governor("BAMGovernor")
        GovernorSettings(1 /* 1 block */, 50400 /* 1 week */, 10000000000000e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}