// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

import "./NonFungibleSoup.sol";


// Mondrian
contract Mondrian is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    NonFungibleSoup private _nfs;

    // Keep track of minted NFT indexes and respective token Ids (and vice-versa)
    mapping (uint256 => uint256) tokenIdsByIndex;
    mapping (uint256 => uint256) tokenIndexesById;

    // Keep track of wallet mints to limit wallets loading up
    mapping (address => uint256) phaseOneMondrianBalanceByAddress;
    mapping (address => uint256) phaseTwoMondrianBalanceByAddress;

    // Keep track of senders and soup balances
    mapping (address => uint256) soupBalanceByAddress;
    mapping (uint256 => address) soupAddressByTokenId;

    // Define starting values for contract
    bool public salesActive = false;
    bool public soupHodlersMode = true;
    bool public maxItemsEnforced = true;
    string public baseURI = "ipfs://QmezMRKpwQvYMaBoJBCmjD58f7RkYQvirKUccsCN7U7Ksg/";
    uint256 public RAND_PRIME;
    uint256 public TIMESTAMP;
    uint256 public constant maxItemPurchase = 3;
    uint256 public constant MAX_ITEMS = 4096;

    // Instantiate NFS so we can check for soup hodlers
    constructor(NonFungibleSoup nfs) ERC721("Mondrian", "MND") {
        _nfs = nfs;
    }

    // Get balances from the tally and not necessarily balanceOf
    function getMondrianBalance(bool phaseTwo, address _a) public view returns(uint256) {
        if (phaseTwo) {
            return phaseTwoMondrianBalanceByAddress[_a];
        } else {
            return phaseOneMondrianBalanceByAddress[_a];
        }
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

    // Check if a given Non-Fungible Soup tokenId has been minted already
    function checkSoupTokenIsClaimed(uint256 tokenId) public view returns(bool) {
        require(tokenId > 0 && tokenId <= 2048, "Provided tokenId is not allowed");
        if (soupAddressByTokenId[tokenId] == address(0x0)) {
            return false;
        } else {
            return true;
        }
    }

    // bool toggles

    function toggleSale() external onlyOwner {
        if (salesActive) {
            salesActive = false;
        } else {
            salesActive = true;
        }
    }

    function toggleMaxEnforced() external onlyOwner {
        if (maxItemsEnforced) {
            maxItemsEnforced = false;
        } else {
            maxItemsEnforced = true;
        }
    }

    function toggleSHM() external onlyOwner {
        if (soupHodlersMode) {
            soupHodlersMode = false;
        } else {
            soupHodlersMode = true;
        }
    }

    // Specify a randomly generated prime number (off-chain), only once
    function setRandPrime(uint256 randPrime) public onlyOwner {
        if (RAND_PRIME == 0) {
            RAND_PRIME = randPrime;
        }
    }

    // Set a new base metadata URI to be used for all NFTs
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    // Mint N number of items when invoked
    // include tokenIds for soup hodlers as well
    function mintItem(
      uint256 numberOfTokens,
      uint256[] memory tokenIds
    ) public payable {
        // First do "soup hodler" mode check
        // Ensure sender is a soup hodler and save tokens to prevent reuse
        if (soupHodlersMode) {
            require(tokenIds.length > 0, "Must provide at least 1 token id");
            require(tokenIds.length == numberOfTokens, "Number of tokens requested must be equal to number of soup token Ids provided");
            // Loop through the provided tokens to ensure the sender owns them
            for(uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                require(_nfs.ownerOf(tokenId) == msg.sender, "Sender is not the owner of provided soup");
                // Lock in token Id to sender's address and update soup balance
                if (soupAddressByTokenId[tokenId] == address(0x0)) {
                    soupAddressByTokenId[tokenId] = msg.sender;
                    soupBalanceByAddress[msg.sender] = soupBalanceByAddress[msg.sender].add(1);
                } else {
                    require(soupAddressByTokenId[tokenId] == msg.sender, "Token already associated with another sender");
                }
                require(totalSupply().add(numberOfTokens) <= _nfs.totalSupply(), "Cannot mint more Mondrians than Soups that exist");
            }

            uint256 allottedMints = soupBalanceByAddress[msg.sender] - phaseOneMondrianBalanceByAddress[msg.sender];
            require(numberOfTokens <= allottedMints, "Minting would exceed allowance set in contract based upon your balance of Soups (NFS)");
        } else {
            if (maxItemsEnforced) {
                require(phaseTwoMondrianBalanceByAddress[msg.sender].add(numberOfTokens) <= maxItemPurchase, "Minting would exceed allowance set in contract since the max is being enforced");
            }
        }

        // Ensure other conditions are met before proceeding
        require(RAND_PRIME > 0, "Random prime number has not been defined");
        require(salesActive, "Sale must be active");
        require(numberOfTokens <= maxItemPurchase, "Can only mint 3 items at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_ITEMS, "Minting would exceed max supply");

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

                // Tally mints per address - SHM toggle allows for reset to 0 for hodlers
                if (soupHodlersMode) {
                    phaseOneMondrianBalanceByAddress[msg.sender] = phaseOneMondrianBalanceByAddress[msg.sender].add(1);
                } else {
                    phaseTwoMondrianBalanceByAddress[msg.sender] = phaseTwoMondrianBalanceByAddress[msg.sender].add(1);
                }

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