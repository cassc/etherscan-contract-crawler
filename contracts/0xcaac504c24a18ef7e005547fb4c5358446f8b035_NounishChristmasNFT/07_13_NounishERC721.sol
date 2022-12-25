// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

abstract contract NounishERC721 is ERC721 {
    struct Info {
        uint8 character;
        uint8 tint;
        uint8 backgroundColor;
        uint8 noggleType;
        uint8 noggleColor;
        address owner;
    }

    mapping(uint256 => Info) public _nftInfo;

    function transferFrom(address from, address to, uint256 id) public virtual override {
        require(from == _nftInfo[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function approve(address spender, uint256 id) public override {
        address owner = _nftInfo[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    // function tokenURI(uint256 id) public view override returns (string memory) {
    //     return "";
    // }

    function ownerOf(uint256 id) public view override returns (address owner) {
        require((owner = _nftInfo[id].owner) != address(0), "NOT_MINTED");
    }

    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_nftInfo[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal override {
        address owner = _nftInfo[id].owner;

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _nftInfo[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}