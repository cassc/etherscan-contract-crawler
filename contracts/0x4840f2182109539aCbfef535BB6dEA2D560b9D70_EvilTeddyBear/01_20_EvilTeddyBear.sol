//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract EvilTeddyBear is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) {}

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "StrayCat: must have admin role"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "StrayCat: must have admin role"
        );
        super._setBaseURI(baseURI_);
    }
}