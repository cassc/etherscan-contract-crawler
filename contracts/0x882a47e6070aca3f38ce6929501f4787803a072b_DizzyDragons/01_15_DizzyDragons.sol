// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DizzyDragons is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 25000000 gwei; // 0.025 ETH

    uint256 public fusionPrice = 25000000 gwei; // 0.025 ETH

    bool public saleIsActive = false;

    bool public fusionIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address[7] private _shareholders;

    uint[7] private _shares;

    event DragonsFused(uint256 firstTokenId, uint256 secondTokenId, uint256 fusedDragonTokenId);
    
    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxDragonSupply) ERC721(name, symbol) {
        maxTokenSupply = maxDragonSupply;

        _shareholders[0] = 0x1EfC0E664fAe4D145Be8599d980CB0a5D7BB3c7A; // Rob
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0xA41A4b84D74E085bd463386d55c3b6dDe6aa2759; // Ben
        _shareholders[3] = 0x364E6a561879e5B2254F4Aa540f8B03d7DA94689; // Oliver
        _shareholders[4] = 0xbfeaF79CC5741Ae4D330a4E201f1DB99B7C49f26; // Matt
        _shareholders[5] = 0x25aA0cA7D31e401c0343B90817D8635698465B7b; // Giveaway wallet
        _shareholders[6] = 0xa22c29fbe82646868960fE0cEDf20317d7a04a24; // Community wallet

        _shares[0] = 3000;
        _shares[1] = 1750;
        _shares[2] = 1750;
        _shares[3] = 1500;
        _shares[4] = 1000;
        _shares[5] = 500;
        _shares[6] = 500;
    }

    function setMaxTokenSupply(uint256 maxDragonSupply) public onlyOwner {
        maxTokenSupply = maxDragonSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setFusionPrice(uint256 newPrice) public onlyOwner {
        fusionPrice = newPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 7; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause fusion if active, make active if paused.
    */
    function flipFusionState() public onlyOwner {
        fusionIsActive = !fusionIsActive;
    }

    /*
    * Mint Dizzy Dragon NFTs, woo!
    */
    function adoptDragons(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to adopt dragons");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can only adopt 15 dragons at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available dragons");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function fuseDragons(uint256 firstTokenId, uint256 secondTokenId) public payable {
        require(fusionIsActive && !saleIsActive, "Either sale is currently active or fusion is inactive");
        require(fusionPrice <= msg.value, "Ether value sent is not correct");
        require(_isApprovedOrOwner(_msgSender(), firstTokenId) && _isApprovedOrOwner(_msgSender(), secondTokenId), "Caller is not owner nor approved");
        
        // burn the 2 tokens
        _burn(firstTokenId);
        _burn(secondTokenId);

        // mint new token
        uint256 fusedDragonTokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, fusedDragonTokenId);
        _tokenIdCounter.increment();

        // fire event in logs
        emit DragonsFused(firstTokenId, secondTokenId, fusedDragonTokenId);
    }
}