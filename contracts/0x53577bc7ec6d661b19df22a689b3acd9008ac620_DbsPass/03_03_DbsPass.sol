// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title DBS Discord Pass
/// @author 0xArbiter orignally, minor additions by 0xffff
/// @author Andreas Bigger <https://github.com/abigger87>
/// @dev An ERC721 that DBS can use to grant access to the Discord server in special cases
contract DbsPass is ERC721, Owned {
    // Custom SBT error for if users try to transfer
    error TokenIsSoulbound();

    /// @dev Put your NFT's name and symbol here
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Owned(msg.sender)
    {}

    /// @notice Prevent Non-soulbound transfers
    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }

    /// @notice Override token transfers to prevent sending tokens
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }

    function mint(address to, uint256 id) public onlyOwner {
        _mint(to, id);
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            "ipfs://bafyreibdz2iwbggdtaitjujf35h4gjgko52vvkqybgkd3gxnxt6frrfcje/metadata.json";
    }
}