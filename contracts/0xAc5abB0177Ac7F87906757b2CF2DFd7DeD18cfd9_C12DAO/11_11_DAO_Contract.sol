// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract C12DAO is Initializable, ERC1155HolderUpgradeable {
    
    address public DAONFT;
    address public owner;
    bool public pauseDao;
    uint16 public proposalId;  

    enum Status { Open, Closed, Cancelled }

    struct Proposal {
        uint16 id;
        address author;
        string proposalHash;
        uint createdAt;
        uint[] votes;
        string[] options;
        Status status;
        string selectedOption;
        mapping(address=>bool) voted;
    }

    uint256[] public votingWeights;
    mapping (uint => Proposal) public proposals;    

    event ProposalCreated(uint proposalId, address author, uint createdAt);
    event voteCast(uint proposalId, address voter, uint weight, uint timestamp);

    // modifier onlyAdvisorOrF12() {
    //     require(containsToken(msg.sender, 0) || containsToken(msg.sender, 1),"C12DAO: Not Holding Advisor or F12 Token");
    //     _;
    // }

    modifier onlyOwner() {
        require(msg.sender == owner,"Error: Caller Must be Ownable!");
        _;
    }

    modifier onlyF12() {
        require(containsToken(msg.sender,0), "C12DAO: Not holding F12 Token");
        _;
    }

    function initialize() public initializer {
        __ERC1155Holder_init();
        owner = msg.sender;
        DAONFT = address(0x82BeEc866ae3A1a5FC1f8bB7A3DCCD17E223C949);
        votingWeights = [300,100,1];
    }

    // @title createProposal
    // @dev Creates a new proposal
    // @param proposalHash - Hash of the proposal string
    // @param options - Array of options as strings. Eg. ["Yes", "No", "No Preference", "Strongly Opposed"]
    // @dev Only available to advisors and F12 members, as determined by the onlyF12 modifier
    function createProposal(string memory proposalHash, string[] memory options) public onlyF12 {

        uint[] memory votes = new uint[](options.length);

        proposalId++;

        proposals[proposalId].id = proposalId;
        proposals[proposalId].author = msg.sender;
        proposals[proposalId].proposalHash = proposalHash;
        proposals[proposalId].createdAt = block.timestamp;
        proposals[proposalId].votes = votes;
        proposals[proposalId].options = options;
        proposals[proposalId].status = Status.Open;
        
        emit ProposalCreated(proposalId, msg.sender, block.timestamp);
    }

    function castVote(uint _proposalId, uint option) public {
        require(!pauseDao,"C12DAO: Voting Paused!");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Open,"C12DAO: Proposal Already Evaluated!");
        require(proposal.voted[msg.sender]==false, "C12DAO: Already Voted");

        proposal.voted[msg.sender] = true;
        uint votingWeight = getVotingWeight(msg.sender);
        proposal.votes[option] += votingWeight;
        
        emit voteCast( _proposalId, msg.sender, votingWeight, block.timestamp);
    }

    function evaluateProposal(uint _proposalId) public onlyF12 {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Open,"C12DAO: Proposal Already Evaluated!");

        uint[] memory votes = proposal.votes;
        uint maxVotes = 0;
        uint maxVotesIndex = 0;
        for(uint i = 0; i < proposal.options.length; i++){
            if(votes[i] > maxVotes) {
                maxVotes = votes[i];
                maxVotesIndex = i;
            }
        }
        proposal.selectedOption = proposal.options[maxVotesIndex];
        proposal.status = Status.Closed;
    }

    function cancelProposal(uint _proposalId) public onlyF12 {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Open,"C12DAO: Proposal Already Evaluated!");
        proposal.status = Status.Cancelled;
    }

    function getVotingWeight(address voter) public view returns(uint) {
        uint votingWeight = 0;
        IERC1155 NFT = IERC1155(DAONFT);
        for(uint i=0; i<votingWeights.length; i++) {
            votingWeight += votingWeights[i] * NFT.balanceOf(voter, i);
        }
        return votingWeight;
    }

    function containsToken(address addr, uint id) internal view returns (bool) {
        IERC1155 NFT = IERC1155(DAONFT);
        return (NFT.balanceOf(addr, id) > 0);
    }

    function setVotingWeight(uint32[] calldata newVotingWeights) public onlyF12 {
        votingWeights = newVotingWeights;
    }

    function disableVoting(bool _status) public onlyF12 {
        pauseDao = _status;
    }

    function setNft(address _nft) public onlyOwner() {
        DAONFT = _nft;
    }

    function rescueNft1155(address _token,uint _id) public onlyF12 {
        uint balance = IERC1155(_token).balanceOf(address(this), _id);
        IERC1155(_token).safeTransferFrom(address(this), msg.sender, _id, balance, "");
    }

    function rescueToken(address _token) public onlyF12 {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }

    function rescueFunds() public onlyF12 {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!");
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getVotingWeightLength() public view returns (uint256) {
        return votingWeights.length;
    }

    function getPower() public view returns (uint256[] memory) {
        return votingWeights;
    }

    function getProposalOptions(uint ids) public view returns (string[] memory) {
        return proposals[ids].options;
    }

    function getProposalVotes(uint ids) public view returns (uint[] memory) {
        return proposals[ids].votes;
    }

    function getProposalUserVote(uint ids,address _user) public view returns (bool) {
        return proposals[ids].voted[_user];
    }

}