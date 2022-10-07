// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Pausable} from "../../../Pausable.sol";
import {IMetaUnitTracker} from "../Tracker/IMetaUnitTracker.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitNFTIncentive
 * @notice Manages token distribution to users 
 */
contract MetaUnitNFTIncentive is Pausable {
    enum ProposalType { change_value, destroy }
    struct Proposal { uint256 value; uint256 start_time; bool resolved; ProposalType proposal_type; }
    struct Voice { address eth_address; bool voice; }

    struct Token { address token_address; uint256 token_id; bool is_single; }

    address private _meta_unit_address;
    address private _meta_unit_tracker_address;
    uint256 private _contract_deployment_timestamp;

    Proposal[] private _proposals;
    mapping (uint256 => mapping(address => bool)) private _is_voted;
    mapping (uint256 => Voice[]) private _voices;
    mapping (uint256 => uint256) private _submited;
    mapping(address => bool) private _is_first_mint_resolved;
    mapping(address => mapping(uint256 => bool)) private _is_nft_registered;
    mapping(address => uint256) private _value_minted_by_user_address;

    address[] private _tokens;
    uint256 private _coeficient = 2;

    /**
    * @dev setup MetaUnit address and owner of this contract.
    */
    constructor(address owner_of_, address meta_unit_address_, address meta_unit_tracker_address_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _contract_deployment_timestamp = block.timestamp;
        _meta_unit_tracker_address = meta_unit_tracker_address_;
    }

    /**
     * @dev emits when new propsal creates
     */
    event proposalCreated(uint256 uid, uint256 value, uint256 start_time, ProposalType proposal_type);

    /**
     * @dev emits when new voice submites
     */
    event voiceSubmited(address eth_address, bool voice);

    /**
     * @dev emits when proposal resolves
     */
    event proposalResolved(uint256 uid, bool submited);

    /**
     * @dev allows to create new proposal
     * @param value_ niew coeficient
     */
    function createProposal(uint256 value_, ProposalType proposal_type_) public {
        uint256 newProposalUid = _proposals.length;
        _proposals.push(Proposal(value_, block.timestamp, false, proposal_type_));
        emit proposalCreated(newProposalUid, value_, block.timestamp, proposal_type_);
    }

    /**
     * @dev allows to submit voices
     * @param uid_ unique id of proposal
     * @param voice_ if `true` - means that user vote for, else means that user vote against
     */
    function vote(uint256 uid_, bool voice_) public {
        require(!_is_voted[uid_][msg.sender], "You vote has been submited already");
        Proposal memory proposal = _proposals[uid_];
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
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
        uint256 voices_for = 0;
        uint256 voices_against = 0;
        for (uint256 i = 0; i < _voices[uid_].length; i++) {
            Voice memory voice = _voices[uid_][i];
            
            uint256 balance = 0;
            for (uint256 k = 0; k < _tokens.length; k++) {
                balance += IERC721(_tokens[k]).balanceOf(voice.eth_address);
            }
            if (voice.voice) voices_for += balance;
            else voices_against += balance;
        }
        bool submited = voices_for > voices_against;
        if (submited) {
            if (proposal.proposal_type == ProposalType.change_value) {
                _coeficient = proposal.value;
            }
            else if (proposal.proposal_type == ProposalType.destroy) {
                IERC20(_meta_unit_address).transfer(_owner_of, IERC20(_meta_unit_address).balanceOf(address(this)));
                selfdestruct(payable(_owner_of));
            }
        }
        emit proposalResolved(uid_, submited);
        _proposals[uid_].resolved = true;
        
    }

    /**
     * @return value multiplied by the time factor.
     */
    function getReducedValue(uint256 value) private view returns (uint256) {
        return (((value * _contract_deployment_timestamp) / (((block.timestamp - _contract_deployment_timestamp) * (_contract_deployment_timestamp / 547 days)) + _contract_deployment_timestamp)) * _coeficient);
    }
    

    /**
     * @dev manages first mint of MetaUnit token.
     * @param tokens_ list of user's tokens.
     */
    function firstMint(Token[] memory tokens_) public notPaused {
        require(!_is_first_mint_resolved[msg.sender], "You have already performed this action");
        uint256 value = 0;
        for (uint256 i = 0; i < tokens_.length; i++) {
            Token memory token = tokens_[i];
            if (token.is_single) require(IERC721(token.token_address).ownerOf(token.token_id) == msg.sender, "You are not an owner of token");
            else require(IERC1155(token.token_address).balanceOf(msg.sender, token.token_id) > 0, "You are not an owner of token");
            if (!_is_nft_registered[token.token_address][token.token_id]) {
                value += 1 ether;
                _is_nft_registered[token.token_address][token.token_id] = true;
            }
        }
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _is_first_mint_resolved[msg.sender] = true;
    }

    /**
     * @dev manages secondary mint of MetaUnit token.
     */
    function secondaryMint() public notPaused {
        IMetaUnitTracker tracker = IMetaUnitTracker(_meta_unit_tracker_address);
        uint256 value_for_mint = tracker.getUserResalesSum(msg.sender);
        uint256 quantity_of_transaction = tracker.getUserTransactionQuantity(msg.sender);
        require(_value_minted_by_user_address[msg.sender] < value_for_mint * quantity_of_transaction, "Not enough tokens for mint");
        uint256 value = (value_for_mint * quantity_of_transaction) - _value_minted_by_user_address[msg.sender];
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _value_minted_by_user_address[msg.sender] += getReducedValue(value);
    }

    function setTokens(address[] memory tokens_) public {
        require(msg.sender == _owner_of, "Permission denied");
        for (uint256 i = 0; i < tokens_.length; i ++) {
            _tokens.push(tokens_[i]);
        }
    }
}