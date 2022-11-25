// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.0;

import { ERC721 } from "./openzeppelin-solidity/token/ERC721/ERC721.sol";
import { Auth } from "tinlake-auth/auth.sol";

contract Title is Auth, ERC721 {
    // --- Data ---
    uint public count;

    constructor (string memory name, string memory symbol) ERC721(name, symbol) {
        wards[msg.sender] = 1;
        count = 1;
    }

    // --- Title ---
    function issue (address usr) public auth returns (uint) {
        return _issue(usr);
    }

    function _issue (address usr) internal returns (uint) {
        _mint(usr, count);
        count += 1; // can't overflow, not enough gas in the world to pay for 2**256 nfts.
        return count-1;
    }

    function close (uint tkn) public auth {
        _burn(tkn);
    }
}

interface TitleLike {
    function issue(address) external returns (uint);
    function close(uint) external;
    function ownerOf (uint) external view returns (address);
    function count () external view returns (uint);
}

contract TitleOwned {
    TitleLike title;
    constructor (address title_) {
        title = TitleLike(title_);
    }

    modifier owner (uint loan) { require(title.ownerOf(loan) == msg.sender); _; }
}