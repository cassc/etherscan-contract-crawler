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

    uint256 private _coeficient = 0.01 ether;
    mapping(address => bool) private _is_committee;

    mapping(address => uint256) private _dao_claim_timestamp;
    mapping(address => uint256) private _value_minted_by_user_address;
    mapping(address => uint256) private _value_for_mint_by_user_address;
    mapping(address => uint256) private _quantity_of_transaction_by_user_address;
    mapping(address => bool) private _is_voted;
    address[] private _voted;

    /**
    * @dev setup MetaUnit address and owner of this contract.
    */
    constructor(address owner_of_, address meta_unit_address_, address dao_factory_address_, address meta_unit_tracker_address_, address[] memory committee_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _dao_factory_address = dao_factory_address_;
        _contract_deployment_timestamp = block.timestamp;
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        for(uint256 i = 0; i < committee_.length; i++) {
            _is_committee[committee_[i]] = true;
        }
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

    function setCoeficient(uint256 coeficient_) public {
        require(msg.sender == _owner_of, "Permission denied");
        _coeficient = coeficient_;
    }

    function withdraw() public {
        require(_is_committee[msg.sender], "Permission denied");
        IERC20 metaunit = IERC20(_meta_unit_address);
        require(metaunit.balanceOf(address(this)) > 0, "Not enough");
        _voted.push(msg.sender);
        if (_voted.length == 3) {
            metaunit.transfer(_owner_of, metaunit.balanceOf(address(this)));
            delete _voted;
        }
    }
}