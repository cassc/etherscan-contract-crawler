// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }
    
    function mint(address _recipient) public {
        require(
            _recipient != address(0),
            "recipient is zero address"
        );
        uint256 _tokenId = totalSupply() + 1;
        _mint(_recipient, _tokenId);
    }

    function batchMint(address[] memory _recipients) external {
        for (uint256 i = 0; i != _recipients.length; i++) {
            mint(_recipients[i]);
        }
    }

    function setBaseURI(string memory baseUri) external {
        _setBaseURI(baseUri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }
}