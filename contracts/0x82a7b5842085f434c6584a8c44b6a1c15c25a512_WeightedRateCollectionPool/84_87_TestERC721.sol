// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Test ERC721 Token
 */
contract TestERC721 is ERC721, Ownable {
    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    string private _baseTokenURI;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice TestERC721 constructor
     * @notice name Token name
     * @notice symbol Token symbol
     * @notice baseURI Token base URI
     */
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseTokenURI = baseURI;
    }

    /**************************************************************************/
    /* Overrides */
    /**************************************************************************/

    /**
     * @inheritdoc ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**************************************************************************/
    /* Privileged API */
    /**************************************************************************/

    /**
     * @notice Set token base URI
     * @param baseURI Token base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mint token to account
     * @param to Recipient account
     * @param tokenId Token ID
     */
    function mint(address to, uint256 tokenId) external virtual onlyOwner {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Burn token
     * @param tokenId Token ID
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}