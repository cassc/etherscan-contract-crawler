// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract InspirationWhiteBorder is ERC721, Ownable {
    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint16 public totalTokens = 4625;
    uint16 public totalSupply = 0;
    string private baseURI =
        "https://time.mypinata.cloud/ipfs/QmTfEF7WNLkkD51vGY4Yrj77p3aBjGf15gRcuQzWXMUCC8/";
    bool private isFrozen = false;
    mapping(uint16 => uint16) private tokenMatrix;

    constructor() ERC721("InspirationWhiteBorder", "IWB") {}

    // ONLY OWNER

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }

    /**
     * @dev Gives a random token to the provided address
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        require(_addresses.length > 0, "At least one token should be minted");

        require(
            getAvailableTokens() >= _addresses.length,
            "No tokens left to be minted"
        );

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += uint16(_addresses.length);

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], _getTokenToBeMinted(tmpTotalMintedTokens));
            tmpTotalMintedTokens++;
        }
    }

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens)
        external
        onlyOwner
        contractIsNotFrozen
    {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    // END ONLY OWNER

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev returns the amount of available tokens
     */
    function getAvailableTokens() private view returns (uint16) {
        return totalTokens - totalSupply;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}