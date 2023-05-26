// SPDX-License-Identifier: GPL-3.0
// TBILL Universal Oracle
// Based on ChainBridge voting.

pragma solidity 0.8.10; 

import "openzeppelin43/access/AccessControl.sol";
import "openzeppelin43/security/Pausable.sol";

/**
 * @title TBILL Universal Oracle
 * @notice Oracles vote on proposals using keccack256 data hash. 
 * @notice After vote threshold is met, execute should be called with the full data 
 * @notice within the expiration period to fire the onExecute function
 * @notice with the data less the proposalNumber header.
 */
abstract contract TOracle is Pausable, AccessControl {
    enum Vote {No, Yes}
    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}
    struct Proposal {
        ProposalStatus _status;
        bytes32 _dataHash;
        address[] _yesVotes;
        uint256 _proposedBlock;
    }


    event VoteThresholdChanged(uint256 indexed newThreshold);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event ProposalEvent(
        uint32 indexed proposalNumber,
        ProposalStatus indexed status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint32 indexed proposalNumber,
        ProposalStatus indexed status
    );


    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    uint256 public _voteThreshold; //number of votes required to pass a proposal
    uint256 public _expiry; //blocks after which to expire proposals
    uint256 public _totalOracles; //number of oracles
    uint256 public _executedCount;

    // proposalNumber => dataHash => Proposal, where proposalNumber is executedCount+1
    mapping(uint32 => mapping(bytes32 => Proposal)) public _proposals;
    // proposalNumber => dataHash => oracleAddress => bool, where proposalNumber is executedCount+1
    mapping(uint32 => mapping(bytes32 => mapping(address => bool))) public _hasVotedOnProposal;

    uint256[50] private ______gap; //leave space for upgrades;


    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }
    modifier onlyAdminOrOracle() {
        _onlyAdminOrOracle();
        _;
    }
    modifier onlyOracles() {
        _onlyOracles();
        _;
    }
    modifier onlySelf(){
        _onlySelf();
        _;
    }

    function _onlyAdminOrOracle() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(ORACLE_ROLE, msg.sender),
            "sender is not oracle or admin"
        );
    }
    function _onlyAdmin() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
    }
    function _onlyOracles() private view {
        require(hasRole(ORACLE_ROLE, msg.sender), "sender doesn't have oracle role");
    }
    function _onlySelf() private view {
        require(msg.sender == address(this), "Only self can call");
    }

    /**
        @notice Initializes oracle, creates and grants admin role, creates and grants oracle role.
        @param initialVoteThreshold Number of votes required to pass proposal.
        @param expiry Number of blocks after which an unexecuted proposal is cancelled.
        @param initialOracles Addresses that should be allowed to vote on proposals.
     */
    constructor(
        uint256 initialVoteThreshold,
        uint256 expiry,
        address[] memory initialOracles        
    ){
        _voteThreshold = initialVoteThreshold;
        _expiry = expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        for (uint256 i; i < initialOracles.length; i++){
            grantRole(ORACLE_ROLE, initialOracles[i]);
        }
        _totalOracles = initialOracles.length;
    }

    /**
        @notice Returns true if {checkAddress} has the oracle role.
        @param checkAddress Address to check.
     */
    function isOracle(address checkAddress) external view returns (bool) {
        return hasRole(ORACLE_ROLE, checkAddress);
    }

    /**
        @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
        @notice Only callable by an address that currently has the admin role.
        @param newAdmin Address that admin role will be granted to.
     */
    function renounceAdmin(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Pauses executions, proposal creation and voting.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPause() external onlyAdmin {
        _pause();
    }

    /**
        @notice Unpauses executions, proposal creation and voting.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpause() external onlyAdmin {
        _unpause();
    }

    /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param newThreshold Value {_voteThreshold} will be changed to.
        @notice Emits {VoteThresholdChanged} event.
     */
    function adminChangeVoteThreshold(uint256 newThreshold) external onlyAdmin {
        _voteThreshold = newThreshold;
        emit VoteThresholdChanged(newThreshold);
    }

    /**
        @notice Grants {oracleAddress} the oracle role and increases {_totalOracles} count.
        @notice Only callable by an address that currently has the admin role.
        @param oracleAddress Address of oracle to be added.
        @notice Emits {OracleAdded} event.
     */
    function adminAddOracle(address oracleAddress) external onlyAdmin {
        require(!hasRole(ORACLE_ROLE, oracleAddress), "addr already has oracle role!");
        grantRole(ORACLE_ROLE, oracleAddress);
        emit OracleAdded(oracleAddress);
        _totalOracles++;
    }

    /**
        @notice Removes oracle role for {oracleAddress} and decreases {_totalOracles} count.
        @notice Only callable by an address that currently has the admin role.
        @param oracleAddress Address of oracle to be removed.
        @notice Emits {OracleRemoved} event.
     */
    function adminRemoveOracle(address oracleAddress) external onlyAdmin {
        require(hasRole(ORACLE_ROLE, oracleAddress), "addr doesn't have oracle role!");
        revokeRole(ORACLE_ROLE, oracleAddress);
        emit OracleRemoved(oracleAddress);
        _totalOracles--;
    }
    
    /**
        @notice Returns a proposal.
        @param proposalNumber The number of proposals that will have been completed if this proposal is executed (_executedCount+1).
        @param dataHash Hash of data that will be provided when proposal is sent for execution.
        @return Proposal which consists of:
        - _dataHash Hash of data to be provided when deposit proposal is executed.
        - _yesVotes Number of votes in favor of proposal.
        - _proposedBlock
        - _status Current status of proposal.
     */
    function getProposal(
        uint32 proposalNumber,
        bytes32 dataHash
    ) external view returns (Proposal memory) {
        return _proposals[proposalNumber][dataHash];
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by oracles when is not paused.
        @param proposalNumber The number of proposals that will have been completed if this proposal is executed (_executedCount+1).
        @param dataHash Hash of encodePacked data that will be provided when proposal is sent for execution.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint32 proposalNumber, bytes32 dataHash) external onlyOracles whenNotPaused {
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        //proposal already passed/executed/cancelled
        if (proposal._status > ProposalStatus.Active) return;
        
        require(!_hasVotedOnProposal[proposalNumber][dataHash][msg.sender], "oracle already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            _proposals[proposalNumber][dataHash] = Proposal({
                _dataHash: dataHash,
                _yesVotes: new address[](1),
                _status: ProposalStatus.Active,
                _proposedBlock: block.number
            });
            proposal._yesVotes[0] = msg.sender;
            emit ProposalEvent(proposalNumber, ProposalStatus.Active, dataHash);
        } else {
            if (block.number - proposal._proposedBlock > _expiry) {
                // if the number of blocks that has passed since this proposal was
                // submitted exceeds the expiry threshold set, cancel the proposal
                proposal._status = ProposalStatus.Cancelled;
                emit ProposalEvent(
                    proposalNumber,
                    ProposalStatus.Cancelled,
                    dataHash
                );
            } else {
                require(dataHash == proposal._dataHash, "datahash mismatch");
                proposal._yesVotes.push(msg.sender);
            }
        }
        if (proposal._status != ProposalStatus.Cancelled) {
            _hasVotedOnProposal[proposalNumber][dataHash][msg.sender] = true;
            emit ProposalVote(proposalNumber, proposal._status);

            // If _depositThreshold is set to 1, then auto finalize
            // or if _relayerThreshold has been exceeded
            if (_voteThreshold <= 1 || proposal._yesVotes.length >= _voteThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(
                    proposalNumber,
                    ProposalStatus.Passed,
                    dataHash
                );
            }
        }
    }

    /**
        @notice Cancels an expired proposal that has not yet been marked as cancelled.
        @notice Only callable by oracles or admin.
        @param proposalNumber The number of proposal executions that would have been completed if this proposal had been executed (_executedCount+1).
        @param dataHash Hash of encodePacked data originally provided when proposal was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(
        uint32 proposalNumber,
        bytes32 dataHash
    ) public onlyAdminOrOracle {
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        require(proposal._status != ProposalStatus.Cancelled, "Proposal already cancelled");
        require(
            block.number - proposal._proposedBlock > _expiry,
            "Proposal not at expiry threshold"
        );

        proposal._status = ProposalStatus.Cancelled;
        emit ProposalEvent(
            proposalNumber,
            ProposalStatus.Cancelled,
            proposal._dataHash
        );
    }

    /**
        @notice Executes a proposal that is considered passed.
        @notice Only callable by oracles when not paused.
        @param proposalNumber The number of proposal executions that will have been completed when this proposal is executed (_executedCount+1).
        @param data abi-encode-packed resourceID, proposalNumber, and data to pass on to handler specified by resourceID lookup.
        @notice Proposal must have "Passed" status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        uint32 proposalNumber,
        bytes calldata data
    ) external onlyOracles whenNotPaused {
        bytes32 dataHash = keccak256(data);
        Proposal storage proposal = _proposals[proposalNumber][dataHash];

        require(proposal._status != ProposalStatus.Inactive, "proposal is not active");
        require(proposal._status == ProposalStatus.Passed, "proposal already executed, cancelled, or not yet passed");
        require(dataHash == proposal._dataHash, "data doesn't match datahash");

        require(proposalNumber == uint32(bytes4(data[:4])), "proposalNumber<>data mismatch");

        proposal._status = ProposalStatus.Executed;
        ++_executedCount;
        onExecute(data[4:]);

        emit ProposalEvent(
            proposalNumber,
            ProposalStatus.Executed,
            dataHash
        );
    }

    function onExecute(bytes calldata data) internal virtual;
    
    /**
        @notice Transfers native currency in the contract to the specified addresses. The parameters addrs and amounts are mapped 1:1.
        This means that the address at index 0 for addrs will receive the amount (in WEI/ticks) from amounts at index 0.
        @param addrs Array of addresses to transfer {amounts} to.
        @param amounts Array of amonuts to transfer to {addrs}.
     */
    function transferFunds(address payable[] calldata addrs, uint256[] calldata amounts)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i].transfer(amounts[i]);
        }
    }
}