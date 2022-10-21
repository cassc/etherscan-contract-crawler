// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LegendaryMuseum is ERC721A, Ownable {
    string private baseURI;

    constructor(string memory uri) ERC721A("LegendaryMuseum", "LegendaryMuseum") {
        baseURI = uri;

        // mint 900 tokens
        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);
        
        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);

        _mintERC2309(msg.sender, 50);
        _mintERC2309(msg.sender, 50);
    }

    function mint(address _to, uint256 _quantity) external onlyOwner {
        _mint(_to, _quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}