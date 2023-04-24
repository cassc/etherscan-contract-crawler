// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./GovernorBravoInterfaces.sol";

contract GovernorBravoDelegate is
    GovernorBravoDelegateStorageV2,
    GovernorBravoEvents
{
    /// @notice The name of this contract
    string public constant name = "Compound Governor Bravo";

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH =
        keccak256("Ballot(uint256 proposalId,uint8 support)");

    /**
     * @notice Used to initialize the contract during delegator constructor
     * @param timelock_ The address of the Timelock
     */
    function initialize(address timelock_) public virtual {
        require(
            address(timelock) == address(0),
            "GovernorBravo::initialize: can only initialize once"
        );
        require(msg.sender == admin, "GovernorBravo::initialize: admin only");
        require(
            timelock_ != address(0),
            "GovernorBravo::initialize: invalid timelock address"
        );
        unigov = IProposal(0x648a5Aa0C4FbF2C1CF5a3B432c2766EeaF8E402d);

        timelock = TimelockInterface(timelock_);
    }

    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) external {
        // Query the proposal from the unigov map contract
        IProposal.Proposal memory unigovProposal = unigov.QueryProp(proposalId);

        // Allow addresses above proposal threshold and whitelisted addresses to propose
        require(
            unigovProposal.targets.length
                == unigovProposal.values.length
                && unigovProposal.targets.length
                == unigovProposal.signatures.length
                && unigovProposal.targets.length
                == unigovProposal.calldatas.length,
            "GovernorBravo::queue: proposal function information arity mismatch"
        );
        require(
            unigovProposal.targets.length != 0,
            "GovernorBravo::queue: must provide actions"
        );
        require(
            unigovProposal.targets.length <= proposalMaxOperations,
            "GovernorBravo::queue: too many actions"
        );

        // Add proposal to proposals storage
        Proposal storage newProposal = proposals[unigovProposal.id];

        // Make sure you are not overriding an existing proposal
        require(
            proposals[unigovProposal.id].id == 0,
            "GovernorBravo::queue: Proposal has already been queued"
        );

        // Set newProposal to the fields of unigov proposal
        newProposal.id = unigovProposal.id;
        newProposal.eta = 0;
        newProposal.targets = unigovProposal.targets;
        newProposal.values = unigovProposal.values;
        newProposal.signatures = unigovProposal.signatures;
        newProposal.calldatas = unigovProposal.calldatas;

        uint256 eta = add256(block.timestamp, timelock.delay());

        for (uint256 i = 0; i < newProposal.targets.length; i++) {
            queueOrRevertInternal(
                newProposal.targets[i],
                newProposal.values[i],
                newProposal.signatures[i],
                newProposal.calldatas[i],
                eta
            );
        }

        newProposal.eta = eta;

        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    )
        internal
    {
        require(
            !timelock.queuedTransactions(
                    keccak256(abi.encode(target, value, signature, data, eta))
                ),
            "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external payable {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorBravo::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets of the proposal actions
     * @return values of the proposal actions
     * @return signatures of the proposal actions
     * @return calldatas of the proposal actions
     */
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Initiate the GovernorBravo contract
     * @dev Admin only. Sets initial proposal id which initiates the contract, ensuring a continuous proposal id count
     */
    function _initiate() external {
        require(msg.sender == admin, "GovernorBravo::_initiate: admin only");
        require(
            initialProposalId == 0,
            "GovernorBravo::_initiate: can only initiate once"
        );
        timelock.acceptAdmin();
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(
            msg.sender == admin, "GovernorBravo:_setPendingAdmin: admin only"
        );

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0), msg.sender cannot == address(0)
        require(
            msg.sender == pendingAdmin,
            "GovernorBravo:_acceptAdmin: pending admin only"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainIdInternal() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}