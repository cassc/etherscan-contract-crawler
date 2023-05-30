//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract EarlyWAGMAM is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// @dev Total number of minted tokens
    uint256 public tokenCounter = 0;
    string public baseURI = "";

    /// @dev Stores the url of the contract level metadata
    string _contractURI;

    constructor() ERC721("I was WAGMAM before...", "OGWAGMAM") {
    }

    /// @dev mints tokens to a list of owners
    function mint(address[] calldata recipients) public onlyOwner {
        for(uint256 i = 1; i <= recipients.length; i++) {
            _safeMint(recipients[i-1], tokenCounter + i);
        }
        tokenCounter += recipients.length;
    }

    /// @dev Gets the base URI of the tokens
    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }

    /// @dev sets the base URI of the tokens
    function setBaseURI(string memory pBaseURI) public onlyOwner {
        baseURI = pBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @dev Sets the contract level metadata
    function setContractURI(string memory pContractUri) external onlyOwner {
        _contractURI = pContractUri;
    }

    /// @dev Gets the contract metadata URI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
}