pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./interface/IDarwinCommunity.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IDarwin {
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DarwinCommunity is OwnableUpgradeable, IDarwinCommunity, UUPSUpgradeable {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Queued,
        Expired,
        Executed
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted;
        bool inSupport;
        uint256 darwinAmount;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 darwinAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
    }

    struct CommunityFundCandidate {
        uint256 id;
        address valueAddress;
        bool isActive;
    }

    modifier isProposalIdValid(uint256 _id) {
        require(_id > 0 && _id <= _lastProposalId, "DC::isProposalIdValid invalid id");
        _;
    }

    modifier onlyDarwinCommunity() {
        require(_msgSender() == address(this), "DC::onlyDarwinCommunity: only DarwinCommunity can access");

        _;
    }

    mapping(uint256 => CommunityFundCandidate) private communityFundCandidates;
    uint256[] private activeCommunityFundCandidateIds;

    /// @notice week => address => % distribution()
    mapping(uint256 => mapping(address => Receipt)) private voteReceipts;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) private proposals;

    /// @notice Restricted proposal actions, only owner can create proposals with these signature
    mapping(uint256 => bool) private restrictedProposalActionSignature;

    mapping(address => uint256[]) private usersVotes;

    uint256 public _lastCommunityFundCandidateId;
    uint256 public _lastProposalId;

    uint256 public minDarwinTransferToAccess;

    uint256 public proposalMinVotesCountForAction;
    uint256 public proposalMaxOperations;
    uint256 public minVotingDelay;
    uint256 public minVotingPeriod;
    uint256 public maxVotingPeriod;
    uint256 public gracePeriod;

    // For backend purpose
    string[] private _initialFundProposalStrings;

    IDarwin public darwin;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __DarwinCommunity_init_unchained();
    }

    function __DarwinCommunity_init_unchained() private initializer {
        /* require(
            fundProposals.length == fundAddress.length,
            "DC::__DarwinCommunity_init_unchained: invalid fund candidate lists"
        ); */

        // FUND ADDRESSES
        address[10] memory fundAddress = [
            0x0bF1C4139A6168988Fe0d1384296e6df44B27aFd,
            0x0bF1C4139A6168988Fe0d1384296e6df44B27aFd,
            0x0bF1C4139A6168988Fe0d1384296e6df44B27aFd,
            0xf74Fb0505f868961f8da7e423d5c8A1CC5c2C162,
            0x33149c1CB70262E29bF7adde4aA79F41a2fd0c39,
            0x33149c1CB70262E29bF7adde4aA79F41a2fd0c39,
            0xD8F251F13eaf05C7D080F917560eB884FEd4227b,
            0x2d73fE5B2eEFa7d4878F75cB05a86aedfef88054,
            0x3Cc90773ebB2714180b424815f390D937974109B,
            address(this)
        ];

        // FUND PROPOSALS
        _initialFundProposalStrings = [
            "Marketing",
            "Product development",
            "Operations",
            "Charity",
            "Egg hunt",
            "Giveaways",
            "Bounties",
            "Burn",
            "Reflections",
            "Save to Next Week"
        ];

        // RESTRICTED SIGNATURES
        string[7] memory restrictedProposalSignatures = [
            "upgradeTo(address)",
            "upgradeToAndCall(address,bytes)",
            "setMinter(address,bool)",
            "setReceiveRewards(address,bool)",
            "setHoldingLimitWhitelist(address,bool)",
            "setSellLimitWhitelist(address,bool)",
            "registerPair(address)"
        ];

        proposalMaxOperations = 1;
        minVotingDelay = 24 hours;
        minVotingPeriod = 24 hours;
        maxVotingPeriod = 1 weeks;
        gracePeriod = 72 hours;
        proposalMinVotesCountForAction = 1;

        minDarwinTransferToAccess = 1e18; // 1 darwin

        for (uint256 i = 0; i < restrictedProposalSignatures.length; i++) {
            uint256 signature = uint256(keccak256(bytes(restrictedProposalSignatures[i])));
            restrictedProposalActionSignature[signature] = true;
        }

        for (uint256 i = 0; i < _initialFundProposalStrings.length; i++) {
            uint256 id = _lastCommunityFundCandidateId + 1;

            communityFundCandidates[id] = CommunityFundCandidate({
                id: id,
                valueAddress: fundAddress[i],
                isActive: true
            });

            activeCommunityFundCandidateIds.push(id);
            _lastCommunityFundCandidateId = id;
        }
    }

    // This is only for backend purposes
    function emitInitialFundsEvents() external onlyOwner {
        for (uint256 i = 0; i < _initialFundProposalStrings.length; i++) {
            uint id = i + 1;
            emit NewFundCandidate(id, communityFundCandidates[id].valueAddress, _initialFundProposalStrings[i]);
        }
    }

    function setDarwinAddress(address account) public override {
        if (address(darwin) == address(0)) {
            require(msg.sender == owner(), "DC::setDarwinAddress: only owner initialize");
        } else {
            require(msg.sender == address(this), "DC::setDarwinAddress: private access only");
        }
        darwin = IDarwin(account);
    }

    function randomBoolean() private view returns (bool) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 2 > 0;
    }

    function deactivateFundCandidate(uint256 _id) public onlyDarwinCommunity {
        require(communityFundCandidates[_id].isActive, "DC::deactivateFundCandidate: not active");

        communityFundCandidates[_id].isActive = false;

        for (uint256 i = 0; i < activeCommunityFundCandidateIds.length; i++) {
            if (activeCommunityFundCandidateIds[i] == _id) {
                activeCommunityFundCandidateIds[i] = activeCommunityFundCandidateIds[
                    activeCommunityFundCandidateIds.length - 1
                ];
                activeCommunityFundCandidateIds.pop();
                break;
            }
        }

        emit FundCandidateDeactivated(_id);
    }

    function newFundCandidate(address valueAddress, string calldata proposal) public onlyDarwinCommunity {
        uint256 id = _lastCommunityFundCandidateId + 1;

        communityFundCandidates[id] = CommunityFundCandidate({ id: id, valueAddress: valueAddress, isActive: true });

        activeCommunityFundCandidateIds.push(id);
        _lastCommunityFundCandidateId = id;

        emit NewFundCandidate(id, valueAddress, proposal);
    }

    function getCommunityTokens(
        uint256[] memory candidates,
        uint256[] memory votes,
        uint256 totalVoteCount,
        uint256 tokensToDistribute
    )
        private
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        address[] memory allTokenRecepients = new address[](candidates.length);
        uint256[] memory allTokenDistribution = new uint256[](candidates.length);
        uint256 validRecepientsCount = 0;

        bool[] memory isValid = new bool[](candidates.length);

        uint256 _totalVoteCount = 0;

        for (uint256 i = 0; i < candidates.length; ) {
            allTokenRecepients[i] = communityFundCandidates[candidates[i]].valueAddress;
            allTokenDistribution[i] = (tokensToDistribute * votes[i]) / totalVoteCount;

            if (
                allTokenRecepients[i] != address(0) &&
                allTokenRecepients[i] != address(this) &&
                allTokenDistribution[i] > 0
            ) {
                validRecepientsCount += 1;
                isValid[i] = true;
            } else {
                isValid[i] = false;
            }

            _totalVoteCount += votes[i];

            unchecked {
                i++;
            }
        }

        address[] memory _recepients = new address[](validRecepientsCount);
        uint256[] memory _tokens = new uint256[](validRecepientsCount);

        uint256 index = 0;

        for (uint256 i = 0; i < candidates.length; ) {
            if (isValid[i]) {
                _recepients[i] = allTokenRecepients[i];
                _tokens[i] = allTokenDistribution[i];

                unchecked {
                    index++;
                }
            }

            unchecked {
                i++;
            }
        }

        return (allTokenDistribution, _recepients, _tokens);
    }

    function distributeCommunityFund(
        uint256 fundWeek,
        uint256[] calldata candidates,
        uint256[] calldata votes,
        uint256 totalVoteCount,
        uint256 tokensToDistribute
    ) public onlyOwner {
        require(candidates.length == votes.length, "DC::distributeCommunityFund: candidates and votes length mismatch");
        require(candidates.length > 0, "DC::distributeCommunityFund: empty candidates");

        uint256 communityTokens = darwin.balanceOf(address(this));

        require(communityTokens >= tokensToDistribute, "DC::distributeCommunityFund: not enough tokens");

        (
            uint256[] memory allTokenDistribution,
            address[] memory recipientsToTransfer,
            uint256[] memory tokenAmountToTransfer
        ) = getCommunityTokens(candidates, votes, totalVoteCount, tokensToDistribute);

        darwin.bulkTransfer(recipientsToTransfer, tokenAmountToTransfer);

        emit CommunityFundDistributed(fundWeek, candidates, allTokenDistribution);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory title,
        string memory description,
        string memory other,
        uint256 endTime
    ) public returns (uint256) {
        require(darwin.transferFrom(msg.sender, address(this), minDarwinTransferToAccess), "DC::propose: not enough $DARWIN in wallet");

        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "DC::propose: proposal function information arity mismatch"
        );

        require(targets.length <= proposalMaxOperations, "DC::propose: too many actions");

        {
            uint256 earliestEndTime = block.timestamp + minVotingDelay + minVotingPeriod;
            uint256 furthestEndDate = block.timestamp + minVotingDelay + maxVotingPeriod;

            require(endTime >= earliestEndTime, "DC::propose: too early end time");
            require(endTime <= furthestEndDate, "DC::propose: too late end time");
        }

        uint256 startTime = block.timestamp + minVotingDelay;

        uint256 proposalId = _lastProposalId + 1;

        for (uint256 i = 0; i < signatures.length; i++) {
            uint256 signature = uint256(keccak256(bytes(signatures[i])));

            if (restrictedProposalActionSignature[signature]) {
                require(msg.sender == owner(), "DC::propose:Proposal signature restricted");
            }
        }

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targets: targets,
            values: values,
            darwinAmount: minDarwinTransferToAccess,
            signatures: signatures,
            calldatas: calldatas,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        _lastProposalId = proposalId;
        proposals[newProposal.id] = newProposal;

        emit ProposalCreated(newProposal.id, msg.sender, startTime, endTime, title, description, other);
        return newProposal.id;
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view isProposalIdValid(proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes < proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.endTime + gracePeriod) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external isProposalIdValid(proposalId) {
        require(state(proposalId) != ProposalState.Executed, "DC::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];

        require(_msgSender() == proposal.proposer || _msgSender() == owner(), "DC::cancel: cannot cancel proposal");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param inSupport The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(
        uint256 proposalId,
        bool inSupport,
        uint256 darwinAmount
    ) external {
        require(minDarwinTransferToAccess <= darwinAmount, "DC::castVote: not enough $DARWIN sent");

        require(darwin.transferFrom(msg.sender, address(this), darwinAmount), "DC::castVote: not enough $DARWIN in wallet");

        castVoteInternal(_msgSender(), proposalId, darwinAmount, inSupport);
        emit VoteCast(_msgSender(), proposalId, inSupport);
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param inSupport The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint256 darwinAmount,
        bool inSupport
    ) private {
        require(state(proposalId) == ProposalState.Active, "DC::castVoteInternal: voting is closed");

        Receipt storage receipt = voteReceipts[proposalId][voter];
        Proposal storage proposal = proposals[proposalId];

        require(receipt.hasVoted == false, "DC::castVoteInternal: voter already voted");

        usersVotes[voter].push(proposalId);

        receipt.hasVoted = true;
        receipt.inSupport = inSupport;
        receipt.darwinAmount = darwinAmount;

        if (inSupport) {
            proposal.forVotes += 1;
        } else {
            proposal.againstVotes += 1;
        }
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external payable onlyOwner {
        Proposal storage proposal = proposals[proposalId];

        require(
            state(proposalId) == ProposalState.Queued,
            "DC::execute: proposal can only be executed if it is queued"
        );

        require(
            proposal.forVotes + proposal.againstVotes >= proposalMinVotesCountForAction,
            "DC::execute: not enough votes received"
        );

        proposal.executed = true;

        if (
            proposal.forVotes != proposal.againstVotes ||
            (proposal.forVotes == proposal.againstVotes && randomBoolean())
        ) {
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                executeTransaction(
                    proposal.id,
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i]
                );
            }
        }

        emit ProposalExecuted(proposalId);
    }

    function executeTransaction(
        uint256 id,
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) private {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returndata) = target.call{ value: value }(callData);

        require(success, extractRevertReason(returndata));

        emit ExecuteTransaction(id, txHash, target, value, signature, data);
    }

    function extractRevertReason(bytes memory revertData) internal pure returns (string memory reason) {
        uint256 length = revertData.length;
        if (length < 68) return "";
        uint256 t;
        assembly {
            revertData := add(revertData, 4)
            t := mload(revertData) // Save the content of the length slot
            mstore(revertData, sub(length, 4)) // Set proper length
        }
        reason = abi.decode(revertData, (string));
        assembly {
            mstore(revertData, t) // Restore the content of the length slot
        }
    }

    function setProposalMaxOperations(uint256 count) public onlyDarwinCommunity {
        proposalMaxOperations = count;
    }

    function setMinVotingDelay(uint256 delay) public onlyDarwinCommunity {
        minVotingDelay = delay;
    }

    function setMinVotingPeriod(uint256 value) public onlyDarwinCommunity {
        minVotingPeriod = value;
    }

    function setMaxVotingPeriod(uint256 value) public onlyDarwinCommunity {
        maxVotingPeriod = value;
    }

    function setGracePeriod(uint256 value) public onlyDarwinCommunity {
        gracePeriod = value;
    }

    function setProposalMinVotesCountForAction(uint256 count) public onlyDarwinCommunity {
        proposalMinVotesCountForAction = count;
    }

    function getActiveFundCandidates() public view returns (CommunityFundCandidate[] memory) {
        CommunityFundCandidate[] memory candidates = new CommunityFundCandidate[](
            activeCommunityFundCandidateIds.length
        );
        for (uint256 i = 0; i < activeCommunityFundCandidateIds.length; i++) {
            candidates[i] = communityFundCandidates[activeCommunityFundCandidateIds[i]];
        }
        return candidates;
    }

    function getActiveFundDandidateIds() public view returns (uint256[] memory) {
        return activeCommunityFundCandidateIds;
    }

    function getProposal(uint256 id) public view isProposalIdValid(id) returns (Proposal memory) {
        return proposals[id];
    }

    function getVoteReceipt(uint256 id) public view isProposalIdValid(id) returns (DarwinCommunity.Receipt memory) {
        return voteReceipts[id][_msgSender()];
    }

    function isProposalSignatureRestricted(string calldata signature) public view returns (bool) {
        return restrictedProposalActionSignature[uint256(keccak256(bytes(signature)))];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyDarwinCommunity {}
}