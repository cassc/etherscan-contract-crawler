// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


contract NonFungibleSoup is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    // Keep track of minted NFT indexes and respective token Ids (and vice-versa)
    mapping (uint256 => uint256) tokenIdsByIndex;
    mapping (uint256 => uint256) tokenIndexesById;

    // Define starting values for contract
    bool public saleIsActive = true;
    string public baseURI = "ipfs://QmajxdsaVsSAxUXBfkcYriznVzVGyVjxFZKYqHqPHYcGap/";
    uint256 public RAND_PRIME;
    uint256 public TIMESTAMP;
    uint256 public constant maxItemPurchase = 3;
    uint256 public constant MAX_ITEMS = 2048;

    constructor() ERC721("Non-Fungible Soup", "NFS") {}

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Return tokenId based upon provided index
    function getTokenId(uint256 index) public view returns(uint256) {
        require(index > 0 && index <= MAX_ITEMS, "Provided token index is not allowed");
        return tokenIdsByIndex[index];
    }

    // Return token index based upon provided tokenId
    function getTokenIndex(uint256 tokenId) public view returns(uint256) {
        require(tokenId > 0 && tokenId <= MAX_ITEMS, "Provided tokenId is not allowed");
        return tokenIndexesById[tokenId];
    }

    // Check if a given index has been minted already
    function checkIndexIsMinted(uint256 index) public view returns(bool) {
        require(index > 0 && index <= MAX_ITEMS, "Provided token index is not allowed");
        return tokenIdsByIndex[index] > 0;
    }

    // Check if a given tokenId has been minted already
    function checkTokenIsMinted(uint256 tokenId) public view returns(bool) {
        require(tokenId > 0 && tokenId <= MAX_ITEMS, "Provided tokenId is not allowed");
        return tokenIndexesById[tokenId] > 0;
    }

    // Explicit functions to pause or resume the sale of Good Boi NFTs
    function pauseSale() external onlyOwner {
        if (saleIsActive) {
            saleIsActive = false;
        }
    }

    function resumeSale() external onlyOwner {
        if (!saleIsActive) {
            saleIsActive = true;
        }
    }

    // Specify a randomly generated prime number (off-chain), only once
    function setRandPrime(uint256 randPrime) public onlyOwner {
        if (RAND_PRIME == 0) {
            RAND_PRIME = randPrime;
        }
    }

    // Set a new base metadata URI to be used for all NFTs in case of emergency
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    // Mint N number of items when invoked along with specified ETH
    function mintItem(uint256 numberOfTokens) public payable {
        // Ensure conditions are met before proceeding
        require(RAND_PRIME > 0, "Random prime number has not been defined in the contract");
        require(saleIsActive, "Sale must be active to mint items");
        require(numberOfTokens <= maxItemPurchase, "Can only mint 3 items at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_ITEMS, "Purchase would exceed max supply");

        // Specify the block timestamp of the first mint to define NFT distribution
        if (TIMESTAMP == 0) {
            TIMESTAMP = block.timestamp;
        }

        // Mint i tokens where i is specified by function invoker
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 index = totalSupply() + 1; // Start at 1
            uint256 seq = RAND_PRIME * index;
            uint256 seqOffset = seq + TIMESTAMP;
            uint256 tokenId = (seqOffset % MAX_ITEMS) + 1; // Prevent tokenId 0
            if (totalSupply() < MAX_ITEMS) {
                // Add some "just in case" checks to prevent collisions
                require(!checkIndexIsMinted(index), "Index has already been used to mint");
                require(!checkTokenIsMinted(tokenId), "TokenId has already been minted and transferred");

                // Mint and transfer to buyer
                _safeMint(msg.sender, tokenId);

                // Save the respective index and token Id for future reference
                tokenIdsByIndex[index] = tokenId;
                tokenIndexesById[tokenId] = index;
            }
        }
    }



    // Override the below functions from parent contracts

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}