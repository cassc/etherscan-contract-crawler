// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "solmate/tokens/ERC721.sol";

// removes balanceOf modifications
// questionable tradeoff but given our use-case it's reasonable
abstract contract PuttyV2Nft is ERC721("Putty", "OPUT") {
    // remove balanceOf modifications
    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    // remove balanceOf modifications
    function transferFrom(address from, address to, uint256 id) public override {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );

        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    // set balanceOf to max for all users
    function balanceOf(address owner) public pure override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        return type(uint256).max;
    }
}