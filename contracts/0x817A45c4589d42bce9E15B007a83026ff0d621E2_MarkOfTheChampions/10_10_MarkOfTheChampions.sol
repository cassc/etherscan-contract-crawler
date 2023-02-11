// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { ERC1155 } from "openzeppelin/token/ERC1155/ERC1155.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

contract MarkOfTheChampions is ERC1155, Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrSBTNoSetApprovalForAll();
    error ErrSBTNoIsApprovedForAll();
    error ErrSBTNoSafeTransferFrom();
    error ErrSBTNoSafeBatchTransferFrom();

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    bool public operatorFilteringEnabled;
    mapping(uint256 => uint256) public minted;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(string memory uri_) ERC1155(uri_) {
    }

    /* -------------------------------------------------------------------------- */
    /*                                  overrides                                 */
    /* -------------------------------------------------------------------------- */
    // erc1155
    function setApprovalForAll(address operator, bool approved) override public pure {
        revert ErrSBTNoSetApprovalForAll();
    }

    function isApprovedForAll(address account, address operator) override public view returns (bool) {
        revert ErrSBTNoIsApprovedForAll();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) override public virtual {
        revert ErrSBTNoSafeTransferFrom();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) override public virtual {
        revert ErrSBTNoSafeBatchTransferFrom();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    struct Staker { 
        address addr;
        uint256 amount;
    }

    // airdrop
    function airdrop(Staker[] memory stakers_) external onlyOwner {
        uint256 __total = 0;
        for (uint i = 0; i < stakers_.length; i++) {
            Staker memory __staker = stakers_[i];
            _mint(__staker.addr, 1, __staker.amount, "");
            __total += __staker.amount;
        }
        minted[1] = minted[1] + __total;
    }

    // setURI
    function setURI(string memory newuri_) external onlyOwner {
        _setURI(newuri_);
    }
}