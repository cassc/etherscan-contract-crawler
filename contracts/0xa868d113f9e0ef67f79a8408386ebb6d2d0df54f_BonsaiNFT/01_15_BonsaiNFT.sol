//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "../abstract/ERC721EnumerableSimple.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721Mock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract BonsaiNFT is ERC721EnumerableSimple, Ownable{

    string private baseURI;

    constructor (string memory name, string memory symbol) ERC721(name, symbol) { }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0); // Return an empty array
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mint(address _to) public onlyOwner {
        uint _totalSupply = totalSupply();

        // require(_totalSupply <= MAX_NFTTOKEN_SUPPLY, "Exceeds maximum NFTToken supply");

        _safeMint(_to, _totalSupply);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }
}