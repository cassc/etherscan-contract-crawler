// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TimeCatsLoveEmHateEm is ERC721, Ownable {
    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint256 public totalSupply = 0;
    string private baseURI =
        "https://time.mypinata.cloud/ipfs/QmddjeVtLts76NYNKDQPcP4YkgLj1iePKJH8S7K6wE6C1E";
    string private usedBaseURI =
        "https://time.mypinata.cloud/ipfs/QmUqKR8H4ry45V1wV2k5iACy6Q5fUkP9wRhJEjFge1Fgw6";
    address private redeemer;
    bool private isFrozen = false;
    mapping(uint256 => bool) private usedTokens;

    constructor() ERC721("TimeCatsLoveEmHateEm", "TCLH") {}

    // ONLY OWNER

    /**
     * @dev Sets the base URI that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }

    /**
     * @dev Sets the base URI that provides the NFT data once the token is used.
     */
    function setUsedBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        usedBaseURI = _uri;
    }

    /**
     * @dev gives tokens to the given addresses
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
        contractIsNotFrozen
    {
        uint256 tmpTotalMintedTokens = totalSupply;
        totalSupply += _addresses.length;

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    /**
     * @dev Sets the address that can use the tokens
     */
    function setRedeemer(address _redeemer) external onlyOwner {
        redeemer = _redeemer;
    }

    /**
     * @dev Flags the tokens as used
     */
    function setAsUsed(uint256 tokenId) external {
        require(msg.sender == redeemer, "Invalid caller");
        require(_exists(tokenId), "Nonexistent token");

        require(!usedTokens[tokenId], "Token has been used");

        usedTokens[tokenId] = true;
    }

    // END ONLY OWNER

    /**
     * @dev Returns wether a token has been used for a claim or not
     */
    function isUsed(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "Nonexistent token");

        return usedTokens[tokenId];
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (usedTokens[tokenId]) {
            return usedBaseURI;
        }

        return baseURI;
    }
}