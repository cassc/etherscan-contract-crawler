// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitFund
 * @notice Manages token distribution to users 
 */
contract MetaUnitFund {
    enum ProposalType { transfer, destroy }
    struct Proposal { address eth_address; uint256 amount; uint256 start_time; bool resolved; ProposalType proposal_type; }
    struct Voice { address eth_address; bool voice; }

    address private _owner_of;
    address private _meta_unit_address;
    uint256 private _metaunit_supply = 4000000 ether;
    
    Proposal[] private _proposals;
    mapping (uint256 => mapping(address => bool)) private _is_voted;
    mapping (uint256 => Voice[]) private _voices;
    mapping (uint256 => uint256) private _submited;

    /**
     * @dev setup MetaUnit address and owner of this contract
     */
    constructor(address meta_unit_address_, address owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _owner_of = owner_of_;
    }

    /**
     * @dev emits when new propsal creates
     */
    event proposalCreated(uint256 uid, address eth_address, uint256 amount, ProposalType proposal_type);

    /**
     * @dev emits when new voice submites
     */
    event voiceSubmited(address eth_address, bool voice);

    /**
     * @dev emits when proposal resolves
     */
    event proposalResolved(uint256 uid, bool submited);
    event withdrawed(uint256 amount);


    /**
     * @dev allows to create new proposal
     * @param eth_address_ address of user who should receive metaunits via goverance
     * @param amount_ amount of metaunits which should transfers to eth_address_
     */
    function createProposal(address eth_address_, uint256 amount_, ProposalType proposal_type_) public {
        require(_submited[block.timestamp / 30 days] + amount_ <= (_metaunit_supply * 2) / 100, "Contract can't unlock more then 2% of metaunit supply");
        uint256 newProposalUid = _proposals.length;
        _proposals.push(Proposal(eth_address_, amount_, block.timestamp, false, proposal_type_));
        emit proposalCreated(newProposalUid, eth_address_, amount_, proposal_type_);
    }

    /**
     * @dev allows to submit voices
     * @param uid_ unique id of proposal
     * @param voice_ if `true` - means that user vote for, else means that user vote against
     */
    function vote(uint256 uid_, bool voice_) public {
        require(!_is_voted[uid_][msg.sender], "You vote has been submited already");
        Proposal memory proposal = _proposals[uid_];
        require(msg.sender != proposal.eth_address, "You can't vote for our proposal");
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        require(IERC20(_meta_unit_address).balanceOf(msg.sender) > 0, "Not enough metaunits for voting");
        _voices[uid_].push(Voice(msg.sender, voice_));
        emit voiceSubmited(msg.sender, voice_);
        _is_voted[uid_][msg.sender] = true;
    }

    /**
     * @dev calculate voices and transfer metaunits if voices for is greater than voices against
     * @param uid_ unique id of proposal
     */
    function resolve(uint256 uid_) public {
        Proposal memory proposal = _proposals[uid_];
        require(!_proposals[uid_].resolved, "Already resolved");
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        require(proposal.eth_address == msg.sender, "You can't claim reward");
        uint256 voices_for = 0;
        uint256 voices_against = 0;
        for (uint256 i = 0; i < _voices[uid_].length; i++) {
            Voice memory voice = _voices[uid_][i];
            uint256 balance = IERC20(_meta_unit_address).balanceOf(voice.eth_address);
            if (voice.voice) voices_for += balance;
            else voices_against += balance;
        }
        bool submited = voices_for > voices_against;
        if (submited) {
            if (proposal.proposal_type == ProposalType.transfer) {
                IERC20(_meta_unit_address).transfer(msg.sender, proposal.amount);
                _submited[block.timestamp / 30 days] += proposal.amount;
            }
            else if (proposal.proposal_type == ProposalType.destroy) {
                IERC20(_meta_unit_address).transfer(_owner_of, IERC20(_meta_unit_address).balanceOf(address(this)));
                selfdestruct(payable(_owner_of));
            }
        }
        emit proposalResolved(uid_, submited);
        _proposals[uid_].resolved = true;
        
    }

    function claim() public {
        require(msg.sender == _owner_of, "Permission denied");
        uint256 amount = (_metaunit_supply * 2) / 100 - _submited[block.timestamp / 30 days];
        IERC20(_meta_unit_address).transfer(msg.sender, amount);
        emit withdrawed(amount);
    }
}