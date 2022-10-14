// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GalaxyExplorers is Ownable, ERC721 {
    modifier contractIsNotFrozen() {
        require(_frozen == false, "This contract is frozen");

        _;
    }

    struct TokenData {
        uint256 totalTokens;
        uint256 nextToken;
    }

    TokenData private tokenData;
    bool private _frozen;
    string private baseURI = "ipfs://a-mysterious-base-uri/";

    constructor() ERC721("Galaxy: The Explorer Collection", "GTEC") {
        tokenData.totalTokens = 3210;
    }

    /**
     * @dev Sets the total token supply
     */
    function setTotalTokens(uint256 _totalTokens) external onlyOwner contractIsNotFrozen {
        tokenData.totalTokens = _totalTokens;
    }

    /**
     * @dev Sets the base URI
     */
    function setBaseURI(string memory _uri) external onlyOwner contractIsNotFrozen {
        baseURI = _uri;
    }

    /**
     * @dev Drop tokens to the provided addresses
     */
    function airdrop(address[] memory _addresses) external onlyOwner contractIsNotFrozen {
        uint256 nextToken = tokenData.nextToken;
        require(tokenData.totalTokens - nextToken >= _addresses.length, "No tokens left to be minted");
        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], uint256(nextToken));
            nextToken++;
        }
        tokenData.nextToken += _addresses.length;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeContract() external onlyOwner {
        _frozen = true;
    }

    /**
     * @dev Returns the current number of tokens
     */
    function getCurrentSupply() public view returns (uint256) {
        return tokenData.nextToken;
    }

    /**
     * @dev returns total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return uint256(tokenData.totalTokens);
    }

    // INTERNAL FUNCTIONS
    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}