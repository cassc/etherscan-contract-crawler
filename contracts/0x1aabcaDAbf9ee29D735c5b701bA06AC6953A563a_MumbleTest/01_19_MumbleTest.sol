// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721psi/contracts/ERC721Psi.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract MumbleTest is
    ERC721Psi,
    OperatorFilterer,
    Ownable
{
    bool public operatorFilteringEnabled;

    constructor() ERC721Psi() {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        _safeMint(msg.sender, 100);
    }

    function mint(uint256 _amount) external payable {
        _safeMint(msg.sender, _amount);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is zero.");
        payable(owner()).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
}