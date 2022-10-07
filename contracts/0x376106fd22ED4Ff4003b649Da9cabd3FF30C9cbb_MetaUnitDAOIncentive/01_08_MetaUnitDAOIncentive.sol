// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IDAO} from "../../DAO/interfaces/IDAO.sol";
import {IMetaUnitTracker} from "../Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitDAOIncentive
 * @notice Manages token distribution to DAO 
 */
contract MetaUnitDAOIncentive is Pausable {
    struct OwnerShip { address dao_address; address owner_of; }
    struct Token { address token_address; uint256 token_id; bool is_single; }

    address private _meta_unit_address;
    address private _meta_unit_tracker_address;
    address private _dao_factory_address;
    uint256 private _contract_deployment_timestamp;

    enum ProposalType { change_value, destroy }
    struct Proposal { uint256 value; uint256 start_time; bool resolved; ProposalType proposal_type; }
    struct Voice { address eth_address; bool voice; }
    Proposal[] private _proposals;
    mapping (uint256 => mapping(address => bool)) private _is_voted;
    mapping (uint256 => Voice[]) private _voices;
    mapping (uint256 => uint256) private _submited;
    address[] private _tokens;
    uint256 private _coeficient = 0.01 ether;

    mapping(address => uint256) private _dao_claim_timestamp;
    mapping(address => uint256) private _value_minted_by_user_address;
    mapping(address => uint256) private _value_for_mint_by_user_address;
    mapping(address => uint256) private _quantity_of_transaction_by_user_address;

    mapping(uint256 => mapping(address => bool)) private _is_in_list;

    /**
    * @dev setup MetaUnit address and owner of this contract.
    */
    constructor(address owner_of_, address meta_unit_address_, address dao_factory_address_, address meta_unit_tracker_address_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _dao_factory_address = dao_factory_address_;
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
        return (((value * _contract_deployment_timestamp) / (((block.timestamp - _contract_deployment_timestamp) * (_contract_deployment_timestamp / 547 days)) + _contract_deployment_timestamp)) * _coeficient / 1 ether);
    }

    /**
     * @dev helps get coverage ratio of dao by address.
     * @param dao_address address of dao, which coverage ratio should be calculated.
     * @return value coverage ratio.
     */
    function getCoverageByDaoAddress(address dao_address) public view returns (uint256) {
        uint256 value = 0;
        IMetaUnitTracker tracker = IMetaUnitTracker(_meta_unit_tracker_address);
        address[] memory addresses;
        uint256[] memory values;
        (addresses, values) = tracker.getTransactionsForPeriod(block.timestamp - 30 days, block.timestamp);
        uint256 addresses_len = addresses.length;
        uint256 quantity = 0;
        for (uint256 i = 0; i < addresses_len; i++) {
            if (IERC20(dao_address).balanceOf(addresses[i]) > 0) {
                value += values[i];
            }
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 j = 0; j < addresses.length; j++) {
                if (i != j && addresses[i] == addresses[j] && addresses[i] != address(0)) {
                    addresses[i] = address(0);
                }
            }
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                quantity++;
            }
        }
        return getReducedValue(value * quantity);
    }


    /**
     * @dev manages mint of MetaUnit token for DAOs.
     */
    function claim() public {
        IDAO daos = IDAO(_dao_factory_address);
        address[] memory daos_addresses = daos.getDaosByOwner(msg.sender);
        uint256 dao_len = daos_addresses.length;
        require(dao_len > 0, "You had no DAO on MetaPlayerOne");
        uint256 current_timestamp = block.timestamp;
        require(_dao_claim_timestamp[msg.sender] + 30 days <= current_timestamp, "You already claim metaunit in this month");
        uint256 value = 0;
        for (uint256 i = 0; i < dao_len; i++) {
             value += getCoverageByDaoAddress(daos_addresses[i]);
        }
        _dao_claim_timestamp[msg.sender] = current_timestamp;
        IERC20(_meta_unit_address).transfer(msg.sender, value);
    }


    function setTokens(address[] memory tokens_) public {
        require(msg.sender == _owner_of, "Permission denied");
        for (uint256 i = 0; i < tokens_.length; i ++) {
            _tokens.push(tokens_[i]);
        }
    }
}