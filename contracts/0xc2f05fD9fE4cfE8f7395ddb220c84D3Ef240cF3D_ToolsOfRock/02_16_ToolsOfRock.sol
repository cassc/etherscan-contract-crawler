// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IMintTicket.sol";

/*
              ________________       _,.......,_        
          .nNNNNNNNNNNNNNNNNP’  .nnNNNNNNNNNNNNnn..
         ANNC*’ 7NNNN|’’’’’’’ (NNN*’ 7NNNNN   `*NNNn.
        (NNNN.  dNNNN’        qNNN)  JNNNN*     `NNNn
         `*@*’  NNNNN         `*@*’  dNNNN’     ,ANNN)
               ,NNNN’  ..-^^^-..     NNNNN     ,NNNNN’
               dNNNN’ /    .    \   .NNNNP _..nNNNN*’
               NNNNN (    /|\    )  NNNNNnnNNNNN*’
              ,NNNN’ ‘   / | \   ’  NNNN*  \NNNNb
              dNNNN’  \  \'.'/  /  ,NNNN’   \NNNN.
              NNNNN    '  \|/  '   NNNNC     \NNNN.
            .JNNNNNL.   \  '  /  .JNNNNNL.    \NNNN.             .
          dNNNNNNNNNN|   ‘. .’ .NNNNNNNNNN|    `NNNNn.          ^\Nn
                           '                     `NNNNn.         .NND
                                                  `*NNNNNnnn....nnNP’
                                                     `*@NNNNNNNNN**’
*/

contract ToolsOfRock is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    IMintTicket private mintTicketContractInstance;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public maxTokensPerTicket;

    uint256 public constant MAX_MINTS_PER_TXN = 16;

    uint256 public mintPrice = 69000000 gwei; // 0.069 ETH

    bool public preSaleIsActive = false;

    bool public saleIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address[5] private _shareholders;

    uint[5] private _shares;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxTorSupply, address mintTicketContractAddress) ERC721(name, symbol) {
        maxTokenSupply = maxTorSupply;

        _shareholders[0] = 0x689018A9e2073d9A8530dA969B735F313636553b; // JJ
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x7Dcb39fe010A205f16ee3249F04b24d74C4f44F1; // Belfort
        _shareholders[3] = 0x74a2acae9B92781Cbb1CCa3bc667c05313e14850; // Cam
        _shareholders[4] = 0xD9D2E67b1695492B870165FD852CF07576f911B3; // Jagger

        _shares[0] = 6270;
        _shares[1] = 1250;
        _shares[2] = 1180;
        _shares[3] = 650;
        _shares[4] = 650;

        mintTicketContractInstance = IMintTicket(mintTicketContractAddress);

        maxTokensPerTicket = 4;
    }

    function setMaxTokenSupply(uint256 maxTorSupply) public onlyOwner {
        maxTokenSupply = maxTorSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxTokensPerTicket(uint256 maxTokensPerMintTicket) public onlyOwner {
        maxTokensPerTicket = maxTokensPerMintTicket;
    }

    function setTicketContractAddress(address mintTicketContractAddress) public onlyOwner {
        mintTicketContractInstance = IMintTicket(mintTicketContractAddress);
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
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
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    * Mint TOR NFTs, woo!
    */
    function mintTOR(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint TOR NFTs");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can only mint 16 TOR NFTs at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /*
    * Mint TOR NFTs using tickets
    */
    function mintUsingTicket(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Pre-sale must be active to mint TOR NFTs using tickets");

        uint256 numberOfPassesNeeded = ((numberOfTokens + maxTokensPerTicket - 1) / maxTokensPerTicket);

        require(mintPrice * (numberOfTokens - numberOfPassesNeeded)  <= msg.value, "Ether value sent is not correct");
        require(numberOfPassesNeeded <= mintTicketContractInstance.balanceOf(msg.sender), "You do not have enough passes to mint these many tokens");

        for(uint256 i = 0; i < numberOfPassesNeeded; i++) {
            // First, burn all passes to avoid re-entrancy attacks
            uint256 tokenIdToBurn = mintTicketContractInstance.tokenOfOwnerByIndex(msg.sender, 0);
            mintTicketContractInstance.burn(tokenIdToBurn);
        }

        for(uint256 i = 0; i < numberOfTokens; i++) {
            // Now, mint the required number of tokens
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
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
}