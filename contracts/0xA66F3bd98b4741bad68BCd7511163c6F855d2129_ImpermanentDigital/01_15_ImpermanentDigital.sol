// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
                                                                                                                                                                                                   @*   
                                 @@@@@                                                                                                                                                         /@@@@@@@@
               @@               @@@@@@@                                                                    [email protected]@@@@@@@@@@                                                 @@@@@@@@@@             @@@@@@@@@
     @@@@@@@@@ @@@@             @@@@@@@   @@@@@                      @@@@@@@@@@@@@@@@@@&    @@@    @@@@  @@@@@@*     @@@,        @@@@      @@@@@                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@ [email protected]@@@           @@@@@ ,@@@@@@@@@@@@@@@                @@@@@@@@@,@@   @@@@  @@@@   @@@@@              @@@@       @@@@@    @@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
    @@@@@@@@@@@    @@@@       @@@@@  (@@@@@(     @@@@@@                 @@@@@@@@      @@@% @@@@@ @@@ @@    @@@@@@@@@@@@@@       @@@@@@   @@@@@@                          @@@@@@@     @@@@@@@      @#    
     @@@@@@@        @@@@@@@@@@@@@@@   @@@@@@    %@@@@@@                  @@@@@@@@@@   @@@& @@@@@@@@  @@   [email protected]@@@  @@@@@ @        @@@@@@  @@@@@                                        @@@@@              
       @@@@         @@@    @@@ @@@@    @@@@@@@@@@@@        @@@@@*        @@@@@ /@@@@ @@@@( @@ @@@@    @    @@@@ ,@@@@ ,@        @@ @@@@@@@  @@@@@@@@@@@@@@@      @@@@     &@@@@@@@   #@@@.              
        @@@,        @@@     @@ @@@(    @@@@      @@@@@@@@@@@@@@@@@@.    @@@@@@@  @@@@@@@   @. @@@@     @     @@@@@@   @@@@@@@@  @@ @@@@@@   @@@@@@    @@@@       @@@@@@@@@@@@@@@@@@  &@@@               
        @@@@      @@@@@@       @@@@    @@@@    @@@@@@@@@@@@@@@@@@@@  @@@@@@  @@@@         @@           @@@@*           @@@@@@   @@ [email protected]@@@@,  @@@@@                @@@@@@@@@@@    @@@&  @@@@              
       @@@@@   @@@@@@@@@         @@@@  @@@@      @@@@@@               @@@@@  @@@@      /@@@@            @@@@@@@                ,@@  @@@@@    @@@@@@@              @@@@@@@   @@@@@@@   @@@@@             
      #@@@@    @@@@@@@@           @@@@  @@@       @@@@@    .#@@@@@@@@@       @@@@     @@@@@              %@@@@@                @@@          @@@@@@@@@@@@@@@        @@@@@@   @@@@@@   @@@@@@@@@@         
  @@@@@@@@@@                           @@@@@@     @@@@@@@@@@@@@@@@@@@@      @@@@@@@@%                                        @@@@,          &@@@                  @@@@@      @@@&   @@@@@@@@@@@@@       
 @@@@@@@@@@@@                       @@@@@@@@@@     @@@@@(  &@               @@@@@@@@@@@                                   @@@@@@@          @@@@@                 @@@@@      @@@@    #@@@@@@@@@@@@       
 @@@@@@@@@@@@                      @@@@@@@@@@@@    @@@@@ ,@@@@                @@@@@@@@@                                   @@@@@          @@@@@@@@@@@@@@@@@@@@@   @@@@@@     @@@@@@     @@@@@@@          
    @@@@@@                          %@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@                                                                   (@@@@@     [email protected]@@@@@@@   @@@@@@     @@@@@@                      
                                       [email protected]@@@       @@@@@@                                                                                                         @@@@@      @@@@@                      

*/

contract ImpermanentDigital is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 8;

    uint256 public mintPrice = 0.1 ether;

    uint256 public maxPresaleMintsPerWallet = 4;

    bool public preSaleIsActive = false;

    bool public saleIsActive = false;

    bool public evolutionIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address public afterlifeContractAddress;

    address public auraContractAddress;

    mapping (address => uint256) private _presaleMints;

    address[6] private _shareholders;

    uint[6] private _shares;

    event PaymentReleased(address to, uint256 amount);

    event IterationEvolved(uint256 tokenId, uint256 startingIterationNumber, uint256 endingIterationNumber);

    constructor(string memory name, string memory symbol, uint256 maxImpermanentSupply) ERC721(name, symbol) {
        maxTokenSupply = maxImpermanentSupply;

        _shareholders[0] = 0xFb728a85e05b74EA63243E8108080aA9bbc595E8; // Glassface
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x7f73422854dD9727858bE39E86C1AD8B6bCA89d4; // Wolfbear
        _shareholders[3] = 0x93a0AA2CEd962A4BBBC8FA37b0b8d8885c595417; // Gowens
        _shareholders[4] = 0x1d14d9e297DfbcE003f5A8EbcF8cBa7fAEe70B91; // Yuri
        _shareholders[5] = 0xaf6c9fA6a10DCcBCC636F15E365c8A0aD7fcaB99; // Dedz

        _shares[0] = 5350;
        _shares[1] = 2500;
        _shares[2] = 2000;
        _shares[3] = 50;
        _shares[4] = 50;
        _shares[5] = 50;
    }

    function setMaxTokenSupply(uint256 maxImpermanentSupply) public onlyOwner {
        maxTokenSupply = maxImpermanentSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function setAfterlifeContractAddress(address newAfterlifeContractAddress) public onlyOwner {
        afterlifeContractAddress = newAfterlifeContractAddress;
    }

    function setAuraContractAddress(address newAuraContractAddress) public onlyOwner {
        auraContractAddress = newAuraContractAddress;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 6; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
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
    * Pause evolution if active, make active if paused.
    */
    function flipEvolutionState() public onlyOwner {
        evolutionIsActive = !evolutionIsActive;
    }

    /*
    * Mint Impermanent Digital NFTs, woot!
    */
    function mintImpermanentDigitals(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can mint a max of 8 NFTs at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /*
    * Mint Impermanent Digital NFTs during pre-sale
    */
    function presaleMint(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Pre-sale is not live yet");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Max mints per wallet limit exceeded");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    function burnForAfterlife(uint256 tokenId) external {
        require(evolutionIsActive, "Burning is not live yet");
        require(_isApprovedOrOwner(tx.origin, tokenId) && (msg.sender == afterlifeContractAddress || msg.sender == auraContractAddress), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function evolve(uint256 tokenId, uint256 startingIterationNumber, uint256 endingIterationNumber) external {
        require(evolutionIsActive, "Evolution is not live yet");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");

        emit IterationEvolved(tokenId, startingIterationNumber, endingIterationNumber);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
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