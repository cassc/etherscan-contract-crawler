// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/[email protected]/governance/Governor.sol";
import "@openzeppelin/[email protected]/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorVotesComp.sol";
import "@openzeppelin/[email protected]/governance/extensions/GovernorTimelockCompound.sol";

contract DopeDAO is Governor, GovernorCompatibilityBravo, GovernorVotesComp, GovernorTimelockCompound {
    constructor(ERC20VotesComp _token, ICompoundTimelock _timelock)
        Governor("DopeDAO")
        GovernorVotesComp(_token)
        GovernorTimelockCompound(_timelock)
    {}

    function votingDelay() public pure virtual override returns (uint256) {
        return 13091; // 2 days (in blocks)
    }

    function votingPeriod() public pure virtual override returns (uint256) {
        return 45818; // 1 week (in blocks)
    }

    function quorum(uint256 blockNumber) public pure virtual override returns (uint256) {
        return 500; // DOPE DAO NFT TOKENS
    }

    function proposalThreshold() public pure virtual override returns (uint256) {
        return 50; // DOPE DAO NFT TOKENS
    }

    // The following functions are overrides required by Solidity.

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesComp)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockCompound)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal override(Governor, GovernorTimelockCompound) {
        uint256 eta = proposalEta(proposalId);
        require(eta > 0, "GovernorTimelockCompound: proposal not yet queued");
        Address.sendValue(payable(timelock()), msg.value);
        for (uint256 i = 0; i < targets.length; ++i) {
            ICompoundTimelock(payable(timelock())).executeTransaction(targets[i], values[i], "", calldatas[i], eta);
        }
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockCompound) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockCompound) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, IERC165, GovernorTimelockCompound)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }
}