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
 * @title MetaUnitFMIncentive
 */
contract MetaUnitFMIncentive is Pausable, ReentrancyGuard {
    struct Token {
        address token_address;
        uint256 token_id;
        bool is_single;
    }

    address private _meta_unit_address;
    uint256 private _contract_deployment_timestamp;

    mapping(address => bool) private _is_first_mint_resolved;
    mapping(address => mapping(uint256 => bool)) private _is_nft_registered;

    uint256 private _coeficient = 2;

    /**
     * @dev setup MetaUnit address and owner of this contract.
     */
    constructor(address owner_of_, address meta_unit_address_)
        Pausable(owner_of_)
    {
        _meta_unit_address = meta_unit_address_;
        _contract_deployment_timestamp = block.timestamp;
    }

    /**
     * @return value multiplied by the time factor.
     */
    function getReducedValue(uint256 value) private view returns (uint256) {
        return (((value * _contract_deployment_timestamp) /
            (((block.timestamp - _contract_deployment_timestamp) *
                (_contract_deployment_timestamp / 547 days)) +
                _contract_deployment_timestamp)) * _coeficient);
    }

    /**
     * @dev manages first mint of MetaUnit token.
     * @param tokens_ list of user's tokens.
     */
    function firstMint(Token[] memory tokens_) public notPaused nonReentrant {
        require(
            !_is_first_mint_resolved[msg.sender],
            "You have already performed this action"
        );
        uint256 value = 0;
        for (uint256 i = 0; i < tokens_.length; i++) {
            Token memory token = tokens_[i];
            if (token.is_single)
                require(
                    IERC721(token.token_address).ownerOf(token.token_id) ==
                        msg.sender,
                    "You are not an owner of token"
                );
            else
                require(
                    IERC1155(token.token_address).balanceOf(
                        msg.sender,
                        token.token_id
                    ) > 0,
                    "You are not an owner of token"
                );
            if (!_is_nft_registered[token.token_address][token.token_id]) {
                value += 1 ether;
                _is_nft_registered[token.token_address][token.token_id] = true;
            }
        }
        IERC20(_meta_unit_address).transfer(msg.sender, getReducedValue(value));
        _is_first_mint_resolved[msg.sender] = true;
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