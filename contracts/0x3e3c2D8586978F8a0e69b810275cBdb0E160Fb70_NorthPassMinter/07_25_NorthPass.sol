// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "../../lib/ERC721/ERC721Preset.sol";

/**
 * @title Founders by North
 * @dev ERC721 contract serving as a lifetime access pass for https://northapp.com
 * @author North Technologies
 * @custom:version v1.0
 * @custom:date 20 December 2022
 */
contract NorthPass is ERC721Preset {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() ERC721Preset("Founders by North", "FBN") {
        _grantRole(MINT_ROLE, msg.sender);
    }

    function safeMint(address to) external onlyRole(MINT_ROLE) returns (uint256 tokenId) {
        tokenId = _safeMint(to);
        return tokenId;
    }
}