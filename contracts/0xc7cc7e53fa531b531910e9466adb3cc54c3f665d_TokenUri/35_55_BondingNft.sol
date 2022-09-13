// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

/**
 * @dev Removes all the balanceOf parts for gas savings.
 */
contract BondingNft is ERC721, Owned {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Owned(msg.sender) {}

    function mint(address to, uint256 id) public onlyOwner {
        _mint(to, id);
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }

    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal override {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

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

    function balanceOf(address owner) public pure override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        return type(uint256).max - 1;
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return "";
    }
}