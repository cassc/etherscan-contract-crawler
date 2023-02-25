// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

contract SimiDAO {

    using SafeERC20 for IERC20;

    IERC20 public YDTtoken;

    // GLOBAL CONSTANTS
    // ***************
    uint256 public votingPeriodLength; // default = 35 periods (7 days)

    // INTERNAL ACCOUNTING
    // *******************
    uint256 public proposalCount = 0; // total proposals submitted
    uint256[] public proposalQueue;
    uint256 public minFund;
    uint256 public minVote;
    
    address private treasury;
    mapping (uint256 => Proposal) public proposals;
    mapping (address => Member) public members;

    // EVENTS
    // ***************
    event SubmitDonationProposal(uint256 propsalId, string name, string media, uint256 duration, uint goal);
    event SubmitMemberProposal(address proposer, uint256 paymentRequested, string category, bool[6] flags, uint256 proposalId, address indexed senderAddress);
    event SubmitVote(uint256 indexed proposalIndex, address indexed memberAddress, uint8 uintVote);
    event CancelProposal(uint256 indexed proposalId, address applicantAddress);
    event DonationApproved(uint256 paymentRequested, string category, bool[6] flags, uint256 proposalId, address indexed senderAddress, address indexed beneficiary, string beneficiaryName, string beneficiarySocial);
    event Deposit(uint256 amount);
    event DonationReceived(uint256 proposalId, uint256 amount);

    struct Member {
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        bool exists; // always true once a member has been created
        uint256 jailed; // set to the proposalIndex of a passing DAO kick proposal for this member. Prevents voting on and sponsoring proposals.
    }

    struct Proposal {
        string name; // name of the proposal
        uint256 duration; // duration of the proposal in seconds
        string media; // media link of the proposal
        address proposer; // the account that submitted the proposal (can be non-member)
        uint256 paymentRequested; // amount of tokens requested as payment
        uint256 startingTime; // the time in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool[6] flags; // [sponsored, processed, didPass, cancelled, memberAdd, memberKick]
        string category; // proposal category - could be IPFS hash, plaintext, or JSON
        mapping(address => Vote) votesByMember; // the votes on this proposal by each member
        bool exists; // always true once a member has been created
    }
    struct Beneficiary {
        address beneficiary;
        string beneficiaryName;
        string beneficiarySocial;
    }
    struct ApprovedDonation {
        string name; // name of the proposal
        uint256 duration; // duration of the proposal in seconds
        string media; // media link of the proposal
        address proposer; // the account that submitted the proposal (can be non-member)
        uint256 paymentRequested; // amount of tokens requested as payment
        uint256 amountRaised; // amount of tokens raised
        uint256 yesVotes;
        uint256 noVotes;
        string category; // proposal category - could be IPFS hash, plaintext, or JSON
        uint256 donors;
        bool exists; // always true once a member has been created
    }
    mapping (uint256 => ApprovedDonation) public approvedDonation;
    mapping (uint256 => Beneficiary) public donationBeneficiary;
    ApprovedDonation[] public projects;
    mapping(uint256 => bool) validDonation;
    enum Vote {
        Null, // default value, counted as abstent
        Yes,
        No
    }

    modifier onlyMember {
        require(members[msg.sender].shares > 0, "Not a member");
        _;
    }

    // CONSTRUCTOR
    // ***************
    // Members imported as an array. Only members can vote on a proposal.
    constructor(address[] memory approvedMembers, address _ydt, uint256 _minFund, uint256 _minVote, address _treasury) {
        require((_ydt != address(0x0)), "YDT token address is not a valid address.");
        YDTtoken = IERC20(_ydt);
        for(uint256 i=0; i < approvedMembers.length; i++) {
            if(i == 0) {
                members[approvedMembers[i]] = Member(1, 50, true, 0);
            } else {
                members[approvedMembers[i]] = Member(1, 0, true, 0);
            }
             
        }
        votingPeriodLength = 900; // 7 days = 604800, 1 hr = 3600
        minFund = _minFund; // 50YDT
        minVote = _minVote; // 10YDT
        treasury = _treasury;
    }

    // ALLOWANCE FUNCTIONS
    //***********
    // An allowance is given to a proposer when their proposal gets a majority vote and the voting period has expired.

    // Internal function
    // *******************
    // Approve donation proposal for pubic donation.
    function _approveDonation(uint _proposalId) internal returns (bool success) {
        if(isApprovedDonation(_proposalId)) revert();
        require(proposals[_proposalId].exists, "This proposal does not exist.");
        Proposal storage prop = proposals[_proposalId];
        ApprovedDonation memory newDonation = ApprovedDonation(prop.name, prop.duration, prop.media, prop.proposer, prop.paymentRequested, 0, prop.yesVotes, prop.noVotes, prop.category, 0, true);
        approvedDonation[_proposalId] = newDonation;
        projects.push(newDonation);
        validDonation[_proposalId] = true;
        return true;

    }
    function isValidForDonation(uint _proposalId) public view returns (bool) {
        ApprovedDonation memory donate = approvedDonation[_proposalId];
        require((donate.exists), "This proposal does not exist.");
        require(donate.amountRaised < donate.paymentRequested, "This proposal has already been fully funded.");
        require(donate.duration >= block.timestamp, "Donation period has ended.");
        return true;
    }

    function receivedDonation(uint _proposalId, uint256 _amount) external {
        require(members[msg.sender].loot == 50);
        require(isValidForDonation(_proposalId));
        ApprovedDonation storage aprop = approvedDonation[_proposalId];
        aprop.amountRaised = aprop.amountRaised + _amount;
        emit DonationReceived(_proposalId, _amount);
    }

    function getApprovedDonation(uint _proposalId) public view returns (ApprovedDonation memory) {
        return approvedDonation[_proposalId];
    }

    // Internal function
    function isApprovedDonation(uint256 _proposalId) public view returns(bool isValid) {
        return validDonation[_proposalId];
    }

    function getApprovedDonationCount() public view returns(uint donationCount) {
        return projects.length;
    }

    // MEMBER FUNCTIONS
    //*****************


    // Function to join simi DAO as a member
    function joinSimiDAO() public {
        require(members[msg.sender].exists == false, "You are already a member of the SimiDAO.");
        require (YDTtoken.balanceOf(address(msg.sender)) >= minFund, "Must have minimum amount of token");
        require(
            YDTtoken.allowance(msg.sender, address(this)) >= minFund,
            "Insufficient allowance"
        );
        YDTtoken.safeTransferFrom(msg.sender, treasury, minFund);
        members[msg.sender] = Member(1, 0, true, 0);
    }
    // Vote on adding new members who want to contribute funds or work.
    // OR kick members who do not contribute.



    function addMember(address newMemAddress, string memory details) public onlyMember {
        _SubmitMemberProposal(newMemAddress, details, 0); // 0 adds a member
    }

    function kickMember(address memToKick, string memory details) public onlyMember {
        _SubmitMemberProposal(memToKick, details, 1);  // 1 kicks a member
    }
    // Create a proposal that shows the address (member to be added) as the proposer. And sets the flags to indicate the type of proposal, either add or kick.
    function _SubmitMemberProposal(address entity, string memory details, uint256 action) internal {
        proposalQueue.push(proposalCount);
        if(action == 0) {
            Proposal storage prop = proposals[proposalCount];
            prop.proposer = entity;
            prop.paymentRequested = 0;
            prop.startingTime = block.timestamp;
            prop.flags = [false, false, false, false, true, false]; // memberAdd
            prop.category = details;
            prop.exists = true;

            emit SubmitMemberProposal(prop.proposer, 0, prop.category, prop.flags, proposalCount, msg.sender);
            proposalCount += 1;
        }

        if(action == 1) {
            Proposal storage prop = proposals[proposalCount];
            prop.proposer = entity;
            prop.paymentRequested = 0;
            prop.startingTime = block.timestamp;
            prop.flags = [false, false, false, false, false, true]; // memberkick
            prop.category = details;
            prop.exists = true;

            emit SubmitMemberProposal(prop.proposer, 0, prop.category, prop.flags, proposalCount, msg.sender);
            proposalCount += 1;
        }
    }

    // PROPOSAL FUNCTIONS
    // ***************
    // SUBMIT PROPOSAL, public function
    // Set applicant, paymentRequested, timelimit, details.
    function submitDonationProposal(
        string memory _name, 
        uint256 _goal, 
        address _beneficiary,
        string memory _beneficiaryName,
        string memory _beneficiarySocial,
        string memory _media,
        uint256 _duration,
        string memory category) public returns (uint256 proposalId) {
        // require (YDTtoken.balanceOf(address(msg.sender)) >= minFund, "Must have minimum amount of token");
        address initiator = msg.sender;
        require(initiator != address(0), "applicant cannot be 0");
        require(members[initiator].jailed == 0, "proposal applicant must not be jailed");
        bool[6] memory flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]
        _submitDonationProposal(_name, _goal, _beneficiary, _beneficiaryName, _beneficiarySocial, _media, _duration, category, flags);
        return proposalCount - 1; // return proposalId - contracts calling submit might want it
    }

    // Internal submit function
    function _submitDonationProposal(
        string memory _name,
        uint256 _goal,
        address _beneficiary,
        string memory _beneficiaryName,
        string memory _beneficiarySocial,
        string memory _media,
        uint256 _duration,
        string memory category, 
        bool[6] memory flags) internal {
        proposalQueue.push(proposalCount);
        Proposal storage prop = proposals[proposalCount];
        prop.proposer = msg.sender;
        prop.name = _name;
        prop.duration = block.timestamp + _duration;
        prop.media = _media;
        prop.paymentRequested = _goal;
        prop.startingTime = block.timestamp;
        prop.flags = flags;
        prop.category = category;
        prop.exists = true;
        Beneficiary storage ben = donationBeneficiary[proposalCount];
        ben.beneficiary = _beneficiary;
        ben.beneficiaryName = _beneficiaryName;
        ben.beneficiarySocial = _beneficiarySocial;
        _approveDonation(proposalCount);
        emit SubmitDonationProposal(proposalCount, _name, _media, _duration, _goal);
        emit DonationApproved(prop.paymentRequested, prop.category, prop.flags, proposalCount, prop.proposer, ben.beneficiary, ben.beneficiaryName, ben.beneficiarySocial);
        proposalCount += 1;
    }

    // Function cancels a proposal if it has not been cancelled already.
    function _cancelProposal(uint256 proposalId) internal onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.flags[3], "proposal has already been cancelled");
        proposal.flags[3] = true; // cancelled

        emit CancelProposal(proposalId, msg.sender);
    }

    // Function which can be called when the proposal voting time has expired. To either act on the proposal or cancel if not a majority yes vote.
    function processProposal(uint256 proposalId) public onlyMember returns (bool _status) {
        require(proposals[proposalId].exists, "This proposal does not exist.");
        require(proposals[proposalId].flags[1] == false, "This proposal has already been processed");
        require(getCurrentTime() >= proposals[proposalId].startingTime, "voting period has not started");
        for(uint256 i=0; i<proposalQueue.length; i++) {
            if (proposalQueue[i]==proposalId) {
                delete proposalQueue[i];
            }
        }
        Proposal storage prop = proposals[proposalId];

        // flags = [sponsored, processed, didPass, cancelled, memberAdd, memberKick]
        if(prop.flags[4] == true) { // Member add
            if(prop.yesVotes > prop.noVotes) {
                members[prop.proposer] = Member(1, 0, true, 0);
                prop.flags[1] = true;
                prop.flags[2] = true;
            }
            else{
                prop.flags[1] = true;
                prop.flags[3] = true;
            }
            return true;
        }
        if(prop.flags[5] == true) { // Member kick
            if(prop.yesVotes > prop.noVotes) {
                    members[prop.proposer].shares = 0;
                    prop.flags[1] = true;
                    prop.flags[2] = true;
                }
                else{
                    prop.flags[1] = true;
                    _cancelProposal(proposalId);
                }
        }
        if(prop.flags[4] == false && prop.flags[5] == false) {
            if(prop.noVotes > minVote) {
                _cancelProposal(proposalId);
                validDonation[proposalId] = false;
            } else {
               validDonation[proposalId] = false; 
            }
            return true;
        }
    }

    // Function to submit a vote to a proposal if you are a member of the DAO and you have not voted yet.
    // Voting period must be in session
    function submitVote(uint256 proposalId, uint8 uintVote) public onlyMember {
        require(members[msg.sender].exists, "Your are not a member of the SimiDAO.");
        require(proposals[proposalId].exists, "This proposal does not exist.");
        require(uintVote < 3, "must be less than 3");
        Vote vote = Vote(uintVote);
        address memberAddress = msg.sender;
        Member storage member = members[memberAddress];
        Proposal storage prop = proposals[proposalId];
        ApprovedDonation storage aprop = approvedDonation[proposalId];

        require(getCurrentTime() >= prop.startingTime, "voting period has not started");
        require(prop.votesByMember[memberAddress] == Vote.Null, "member has already voted");
        require(vote == Vote.Yes || vote == Vote.No, "vote must be either Yes or No");

        prop.votesByMember[memberAddress] = vote;

        if (vote == Vote.Yes) {
            prop.yesVotes = prop.yesVotes + member.shares;
            aprop.yesVotes = prop.yesVotes;
        }
        else if (vote == Vote.No) {
            prop.noVotes = prop.noVotes + member.shares;
            aprop.noVotes = prop.noVotes;
        }
        emit SubmitVote(proposalId, memberAddress, uintVote);
    }

    // Function to receive Ether, msg.data must be empty
    // receive() external payable {}

    // // Deposit function to provide liquidity to DAO contract
    // function deposit() public payable returns (uint256) {
    //     require(msg.value > 0);
    //     require(msg.value <= 200000000000, "amount must be less than or equal to 200");
    //     uint256 deposited = msg.value;
    //     payable(address(this)).transfer(deposited);
    //     emit Deposit(msg.value);
    //     return(deposited);
    // }

    // GETTER FUNCTIONS
    //*****************

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    // function getProposalQueueLength() public view returns (uint256) {
    //     return proposalQueue.length;
    // }

    // function getProposalFlags(uint256 proposalId) public view returns (bool[6] memory) {
    //     return proposals[proposalId].flags;
    // }

    // function getMemberProposalVote(address memberAddress, uint256 proposalIndex) public view returns (Vote) {
    //     require(members[memberAddress].exists, "member does not exist");
    //     require(proposalIndex < proposalQueue.length, "proposal does not exist");
    //     return proposals[proposalQueue[proposalIndex]].votesByMember[memberAddress];
    // }
}