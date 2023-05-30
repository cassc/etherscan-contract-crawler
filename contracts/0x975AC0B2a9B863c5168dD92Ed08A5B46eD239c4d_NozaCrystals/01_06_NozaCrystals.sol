// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { ERC721A } from "erc721a/ERC721A.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { INozaCrystals } from "./INozaCrystals.sol";

contract NozaCrystals is INozaCrystals, ERC721A, Ownable {
    /// @dev IPFS base URI storage.
    string private _baseTokenURI;

    /// @inheritdoc INozaCrystals
    uint256 public constant MAX_SUPPLY = 200;

    /// @dev Constructor to initialize ERC-721A contract with name and symbol.
    constructor() ERC721A("Cornerstone Noza Crystals", "NOZA") { }

    /// @inheritdoc INozaCrystals
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @inheritdoc INozaCrystals
    function mint(address[] calldata recipients, uint256 quantity) external onlyOwner {
        uint256 recipientsLength = recipients.length;
        if (_totalMinted() + recipientsLength * quantity > MAX_SUPPLY) revert MaxSupplyReached();

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], quantity);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}