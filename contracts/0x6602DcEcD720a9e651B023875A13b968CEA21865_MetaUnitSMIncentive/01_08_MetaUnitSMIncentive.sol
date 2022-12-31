// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Pausable} from "../../../Pausable.sol";
import {IMetaUnitTracker} from "../Tracker/IMetaUnitTracker.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitSMIncentive
 */
contract MetaUnitSMIncentive is Pausable, ReentrancyGuard {
    struct Token { address token_address; uint256 token_id; bool is_single; }

    address private _meta_unit_address;
    address private _meta_unit_tracker_address;
    uint256 private _contract_deployment_timestamp;

    mapping(address => uint256) private _value_minted_by_user_address;

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
     * @return value multiplied by the time factor.
     */
    function getReducedValue(uint256 value) private view returns (uint256) {
        return (((value * _contract_deployment_timestamp) / (((block.timestamp - _contract_deployment_timestamp) * (_contract_deployment_timestamp / 547 days)) + _contract_deployment_timestamp)) * _coeficient);
    }
    

    /**
     * @dev manages secondary mint of MetaUnit token.
     */
    function secondaryMint() public notPaused nonReentrant {
        IMetaUnitTracker tracker = IMetaUnitTracker(_meta_unit_tracker_address);
        uint256 value_for_mint = tracker.getUserResalesSum(msg.sender);
        uint256 quantity_of_transaction = tracker.getUserTransactionQuantity(msg.sender);
        require(_value_minted_by_user_address[msg.sender] < value_for_mint * quantity_of_transaction, "Not enough tokens for mint");
        uint256 value = (value_for_mint * quantity_of_transaction) - _value_minted_by_user_address[msg.sender];
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _value_minted_by_user_address[msg.sender] += getReducedValue(value);
    }

    function setCoeficient(uint256 coeficient_) public {
        require(msg.sender == _owner_of, "Permission denied");
        _coeficient = coeficient_;
    }

    function withdraw(uint256 amount_) public {
        require(msg.sender == _owner_of, "Permission denied");
        IERC20(_meta_unit_address).transfer(_owner_of, amount_);
    }

    function withdraw() public {
        require(msg.sender == _owner_of, "Permission denied");
        IERC20 metaunit = IERC20(_meta_unit_address);
        metaunit.transfer(_owner_of, metaunit.balanceOf(address(this)));
    }

}