// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IColonistPowerup.sol";

contract Colonists is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public mintPrice = 0.025 ether;

    uint256 public rerollPrice = 0.0125 ether;

    uint256 public maxPresaleMintsPerWallet = 4;

    uint256 public mintsPerSpecies = 5000;

    bool public saleIsActive = false;

    bool public preSaleIsActive = false;

    bool public rerollIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address[7] private _shareholders;

    uint[7] private _shares;

    IColonistPowerup private powerupContractInstance;

    mapping (address => uint256) private _presaleMints;

    event PaymentReleased(address to, uint256 amount);

    event TraitRerolled(uint256 tokenId, string trait, uint256 powerupTokenId);

    constructor(string memory name, string memory symbol, uint256 maxColonistSupply) ERC721(name, symbol) {
        maxTokenSupply = maxColonistSupply;

        _shareholders[0] = 0x8c223D865Bc7Ff45757936325A992ec15d803FFD; // Hunter
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x77e04a00c36874aE346A5bEA2462CF4fBB45D0d1; // Camilla
        _shareholders[3] = 0x41Ea80aB06F477403dD7dD55D30F54cA25A47b5C; // Anthony
        _shareholders[4] = 0x230FcED7feAeD9DfFC256B93B8F0c9195a743c89; // Andy
        _shareholders[5] = 0x31Ed4b569Ab5F004A30761D166f608b6D24C34F5; // Christian
        _shareholders[6] = 0xE2419b85D9CB8a0e4c43F00AA2882AEA5587bAf3; // Ash

        _shares[0] = 5000;
        _shares[1] = 3000;
        _shares[2] = 500;
        _shares[3] = 500;
        _shares[4] = 400;
        _shares[5] = 400;
        _shares[6] = 200;
    }

    function setPowerupContractAddress(address powerupContractAddress) public onlyOwner {
        powerupContractInstance = IColonistPowerup(powerupContractAddress);
    }

    function setMaxTokenSupply(uint256 maxColonistSupply) public onlyOwner {
        maxTokenSupply = maxColonistSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setRerollPrice(uint256 newPrice) public onlyOwner {
        rerollPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function setMintsPerSpecies(uint256 newMintsPerSpecies) public onlyOwner {
        mintsPerSpecies = newMintsPerSpecies;
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
    * Pause rerolling if active, make active if paused.
    */
    function flipRerollState() public onlyOwner {
        rerollIsActive = !rerollIsActive;
    }

    function mintOneColonist() public payable {
        _mintColonists(1);
    }

    function mintTwoColonists() public payable {
        _mintColonists(2);
    }

    function mintThreeColonists() public payable {
        _mintColonists(3);
    }

    function mintFourColonists() public payable {
        _mintColonists(4);
    }

    function mintTenColonists() public payable {
        _mintColonists(10);
    }

    function mintTwentyColonists() public payable {
        _mintColonists(20);
    }

    /*
    * Mint Colonist NFTs, woot!
    */
    function _mintColonists(uint256 numberOfTokens) internal {
        require(saleIsActive || preSaleIsActive, "Sale must be active to mint colonists");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available colonists");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        if (! saleIsActive) {
            _validatePreSaleWalletLimit(numberOfTokens);
        }

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

    function _validatePreSaleWalletLimit(uint256 numberOfTokens) internal {
        // Validate that max per wallet pre-sale limit is not exceeded
        uint256 balance = balanceOf(msg.sender);

        if (balance > 0) {
            uint256 currentSpecies = _tokenIdCounter.current() / mintsPerSpecies;
            uint256 lastMintedSpecies = (tokenOfOwnerByIndex(msg.sender, balance - 1) - 1) / mintsPerSpecies;

            if (currentSpecies != lastMintedSpecies) {
                // reset pre-sale mints
                _presaleMints[msg.sender] = 0;
            }
        }

        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Max colonists per wallet limit exceeded");
        _presaleMints[msg.sender] += numberOfTokens;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function rerollTrait(uint256 tokenId, string memory trait, uint256 powerupTokenId) public payable {
        require(rerollIsActive, "Rerolling is not currently active");
        require(rerollPrice <= msg.value, "Ether value sent is not correct");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");

        if (powerupTokenId != 0) {
            require(powerupContractInstance.ownerOf(powerupTokenId) == msg.sender, "Caller is not owner of power up token ID");
            powerupContractInstance.burn(powerupTokenId);
        }

        emit TraitRerolled(tokenId, trait, powerupTokenId);
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