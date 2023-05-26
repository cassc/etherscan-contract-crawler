//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721AFixedSale} from "../presets/ERC721AFixedSale.sol";

contract Lunatics is ERC721AFixedSale {
    constructor(
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256 _royalty,
        uint256 _initial
    ) ERC721AFixedSale(_name, _symbol, _recipient, _royalty) {
        _safeMint(_recipient, _initial);
        _setInitialSupply(_initial);
    }

    function refreshMetadata() public {
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function reveal(string memory baseURI) public onlyOwner {
        _setRevealed();
        _setBaseURI(baseURI);
        _setStartTime(block.timestamp);
    }
}