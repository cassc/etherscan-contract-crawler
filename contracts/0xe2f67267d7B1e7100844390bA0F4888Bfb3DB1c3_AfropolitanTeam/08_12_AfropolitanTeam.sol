// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { MetacryptERC721 } from "@metacrypt/contracts/erc721/MetacryptERC721.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC721 Contract for Afropolitan Team PFPs
/// @author [email protected]
contract AfropolitanTeam is MetacryptERC721, Ownable {
    constructor()
        MetacryptERC721(
            "Afropolitan Team",
            "AFRO-TEAM",
            "https://afropolitan-drops.metacrypt.org/api/metadata/team-pfp/",
            address(1),
            0
        )
    // solhint-disable no-empty-blocks
    {

    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function mintTeamTokens(address[] calldata targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        require(from == address(0), "SBT");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}