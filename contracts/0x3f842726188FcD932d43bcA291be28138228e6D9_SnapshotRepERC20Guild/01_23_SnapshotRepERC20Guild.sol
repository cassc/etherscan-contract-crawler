// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import "../ERC20GuildUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../../utils/ERC20/ERC20SnapshotRep.sol";

/*
  @title SnapshotRepERC20Guild
  @author github:AugustoL
  @dev An ERC20Guild designed to work with a snapshotted voting token, no locking needed.
  When a proposal is created it saves the snapshot if at the moment of creation,
  the voters can vote only with the voting power they had at that time.
*/
contract SnapshotRepERC20Guild is ERC20GuildUpgradeable {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // Proposal id => Snapshot id
    mapping(bytes32 => uint256) public proposalsSnapshots;

    /// @dev Initializer
    /// @param _token The ERC20 token that will be used as source of voting power
    /// @param _proposalTime The amount of time in seconds that a proposal will be active for voting
    /// @param _timeForExecution The amount of time in seconds that a proposal option will have to execute successfully
    // solhint-disable-next-line max-line-length
    /// @param _votingPowerPercentageForProposalExecution The percentage of voting power in base 10000 needed to execute a proposal action
    // solhint-disable-next-line max-line-length
    /// @param _votingPowerPercentageForProposalCreation The percentage of voting power in base 10000 needed to create a proposal
    /// @param _name The name of the ERC20Guild
    /// @param _voteGas The amount of gas in wei unit used for vote refunds
    /// @param _maxGasPrice The maximum gas price used for vote refunds
    /// @param _maxActiveProposals The maximum amount of proposals to be active at the same time
    /// @param _lockTime The minimum amount of seconds that the tokens would be locked
    /// @param _permissionRegistry The address of the permission registry contract to be used
    function initialize(
        address _token,
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votingPowerPercentageForProposalExecution,
        uint256 _votingPowerPercentageForProposalCreation,
        string memory _name,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _maxActiveProposals,
        uint256 _lockTime,
        address _permissionRegistry
    ) public override initializer {
        super.initialize(
            _token,
            _proposalTime,
            _timeForExecution,
            _votingPowerPercentageForProposalExecution,
            _votingPowerPercentageForProposalCreation,
            _name,
            _voteGas,
            _maxGasPrice,
            _maxActiveProposals,
            _lockTime,
            _permissionRegistry
        );
        permissionRegistry.setETHPermission(address(this), _token, bytes4(keccak256("mint(address,uint256)")), 0, true);
        permissionRegistry.setETHPermission(address(this), _token, bytes4(keccak256("burn(address,uint256)")), 0, true);
    }

    /// @dev Set the voting power to vote in a proposal
    /// @param proposalId The id of the proposal to set the vote
    /// @param option The proposal option to be voted
    /// @param votingPower The votingPower to use in the proposal
    function setVote(
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower
    ) public virtual override {
        require(
            proposals[proposalId].endTime > block.timestamp,
            "SnapshotRepERC20Guild: Proposal ended, cannot be voted"
        );
        require(
            votingPowerOfAt(msg.sender, proposalsSnapshots[proposalId]) >= votingPower,
            "SnapshotRepERC20Guild: Invalid votingPower amount"
        );
        require(
            (proposalVotes[proposalId][msg.sender].option == 0 &&
                proposalVotes[proposalId][msg.sender].votingPower == 0) ||
                (proposalVotes[proposalId][msg.sender].option == option &&
                    proposalVotes[proposalId][msg.sender].votingPower < votingPower),
            "SnapshotRepERC20Guild: Cannot change option voted, only increase votingPower"
        );
        _setVote(msg.sender, proposalId, option, votingPower);
    }

    /// @dev Set the voting power to vote in a proposal using a signed vote
    /// @param proposalId The id of the proposal to set the vote
    /// @param option The proposal option to be voted
    /// @param votingPower The votingPower to use in the proposal
    /// @param voter The address of the voter
    /// @param signature The signature of the hashed vote
    function setSignedVote(
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower,
        address voter,
        bytes memory signature
    ) public virtual override {
        require(
            proposals[proposalId].endTime > block.timestamp,
            "SnapshotRepERC20Guild: Proposal ended, cannot be voted"
        );
        bytes32 hashedVote = hashVote(voter, proposalId, option, votingPower);
        require(!signedVotes[hashedVote], "SnapshotRepERC20Guild: Already voted");
        require(voter == hashedVote.toEthSignedMessageHash().recover(signature), "SnapshotRepERC20Guild: Wrong signer");
        signedVotes[hashedVote] = true;
        require(
            (votingPowerOfAt(voter, proposalsSnapshots[proposalId]) >= votingPower) &&
                (votingPower > proposalVotes[proposalId][voter].votingPower),
            "SnapshotRepERC20Guild: Invalid votingPower amount"
        );
        require(
            (proposalVotes[proposalId][voter].option == 0 && proposalVotes[proposalId][voter].votingPower == 0) ||
                (proposalVotes[proposalId][voter].option == option &&
                    proposalVotes[proposalId][voter].votingPower < votingPower),
            "SnapshotRepERC20Guild: Cannot change option voted, only increase votingPower"
        );
        _setVote(voter, proposalId, option, votingPower);
    }

    /// @dev Override and disable lock of tokens, not needed in SnapshotRepERC20Guild
    function lockTokens(uint256) external virtual override {
        revert("SnapshotRepERC20Guild: token vault disabled");
    }

    /// @dev Override and disable withdraw of tokens, not needed in SnapshotRepERC20Guild
    function withdrawTokens(uint256) external virtual override {
        revert("SnapshotRepERC20Guild: token vault disabled");
    }

    /// @dev Create a proposal with an static call data and extra information
    /// @param to The receiver addresses of each call to be executed
    /// @param data The data to be executed on each call to be executed
    /// @param value The ETH value to be sent on each call to be executed
    /// @param totalOptions The amount of options that would be offered to the voters
    /// @param title The title of the proposal
    /// @param contentHash The content hash of the content reference of the proposal for the proposal to be executed
    function createProposal(
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        uint256 totalOptions,
        string memory title,
        string memory contentHash
    ) public virtual override returns (bytes32) {
        bytes32 proposalId = super.createProposal(to, data, value, totalOptions, title, contentHash);
        proposalsSnapshots[proposalId] = ERC20SnapshotRep(address(token)).getCurrentSnapshotId();
        return proposalId;
    }

    /// @dev Executes a proposal that is not votable anymore and can be finished
    /// @param proposalId The id of the proposal to be executed
    function endProposal(bytes32 proposalId) public virtual override {
        require(!isExecutingProposal, "ERC20SnapshotRep: Proposal under execution");
        require(proposals[proposalId].state == ProposalState.Active, "ERC20SnapshotRep: Proposal already executed");
        require(proposals[proposalId].endTime < block.timestamp, "ERC20SnapshotRep: Proposal hasn't ended yet");

        uint256 winningOption = 0;
        uint256 highestVoteAmount = proposals[proposalId].totalVotes[0];
        uint256 i = 1;
        for (i = 1; i < proposals[proposalId].totalVotes.length; i++) {
            if (
                proposals[proposalId].totalVotes[i] >= getSnapshotVotingPowerForProposalExecution(proposalId) &&
                proposals[proposalId].totalVotes[i] >= highestVoteAmount
            ) {
                if (proposals[proposalId].totalVotes[i] == highestVoteAmount) {
                    winningOption = 0;
                } else {
                    winningOption = i;
                    highestVoteAmount = proposals[proposalId].totalVotes[i];
                }
            }
        }

        if (winningOption == 0) {
            proposals[proposalId].state = ProposalState.Rejected;
            emit ProposalStateChanged(proposalId, uint256(ProposalState.Rejected));
        } else if (proposals[proposalId].endTime.add(timeForExecution) < block.timestamp) {
            proposals[proposalId].state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, uint256(ProposalState.Failed));
        } else {
            proposals[proposalId].state = ProposalState.Executed;

            uint256 callsPerOption = proposals[proposalId].to.length.div(
                proposals[proposalId].totalVotes.length.sub(1)
            );
            i = callsPerOption.mul(winningOption.sub(1));
            uint256 endCall = i.add(callsPerOption);

            permissionRegistry.setERC20Balances();

            for (i; i < endCall; i++) {
                if (proposals[proposalId].to[i] != address(0) && proposals[proposalId].data[i].length > 0) {
                    bytes memory _data = proposals[proposalId].data[i];
                    bytes4 callDataFuncSignature;
                    assembly {
                        callDataFuncSignature := mload(add(_data, 32))
                    }
                    // The permission registry keeps track of all value transferred and checks call permission
                    try
                        permissionRegistry.setETHPermissionUsed(
                            address(this),
                            proposals[proposalId].to[i],
                            bytes4(callDataFuncSignature),
                            proposals[proposalId].value[i]
                        )
                    {} catch Error(string memory reason) {
                        revert(reason);
                    }

                    isExecutingProposal = true;
                    // We use isExecutingProposal variable to avoid re-entrancy in proposal execution
                    // slither-disable-next-line all
                    (bool success, ) = proposals[proposalId].to[i].call{value: proposals[proposalId].value[i]}(
                        proposals[proposalId].data[i]
                    );
                    require(success, "ERC20SnapshotRep: Proposal call failed");
                    isExecutingProposal = false;
                }
            }

            permissionRegistry.checkERC20Limits(address(this));

            emit ProposalStateChanged(proposalId, uint256(ProposalState.Executed));
        }
        activeProposalsNow = activeProposalsNow.sub(1);
    }

    /// @dev Get the voting power of multiple addresses at a certain snapshotId
    /// @param accounts The addresses of the accounts
    /// @param snapshotIds The snapshotIds to be used
    function votingPowerOfMultipleAt(address[] memory accounts, uint256[] memory snapshotIds)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory votes = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) votes[i] = votingPowerOfAt(accounts[i], snapshotIds[i]);
        return votes;
    }

    /// @dev Get the voting power of an address at a certain snapshotId
    /// @param account The address of the account
    /// @param snapshotId The snapshotId to be used
    function votingPowerOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        return ERC20SnapshotRep(address(token)).balanceOfAt(account, snapshotId);
    }

    /// @dev Get the voting power of an account
    /// @param account The address of the account
    function votingPowerOf(address account) public view virtual override returns (uint256) {
        return ERC20SnapshotRep(address(token)).balanceOf(account);
    }

    /// @dev Get the proposal snapshot id
    function getProposalSnapshotId(bytes32 proposalId) public view returns (uint256) {
        return proposalsSnapshots[proposalId];
    }

    /// @dev Get the totalLocked
    function getTotalLocked() public view virtual override returns (uint256) {
        return ERC20SnapshotRep(address(token)).totalSupply();
    }

    /// @dev Get minimum amount of votingPower needed for proposal execution
    function getSnapshotVotingPowerForProposalExecution(bytes32 proposalId) public view virtual returns (uint256) {
        return
            ERC20SnapshotRep(address(token))
                .totalSupplyAt(getProposalSnapshotId(proposalId))
                .mul(votingPowerPercentageForProposalExecution)
                .div(10000);
    }
}