// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IBreedingManagerContract.sol";
import "./ITokenContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract RoaringRoccstars is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _mintCounter;

    string public baseURI;

    ITokenContract private roarTokenContractInstance;
    IBreedingManagerContract private breedingManagerContractInstance;

    uint256 public mintRoarPrice = 600;
    uint256 public cooldownPillPrice = 300;
    uint256 public signatureMultiplier = 10;
    
    uint256 public mintPrice = 0.11 ether;

    uint256 public maxMintSupply = 5000;

    bool public saleIsActive = false;

    bool public preSaleIsActive = false;

    bool public breedingIsActive = false;

    mapping (address => uint256) private _presaleMints;

    uint256 public maxPresaleMintsPerWallet = 3;

    event CubMinted(uint256 tokenId);

    event CubBorn(uint256 tokenId, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown);

    event CubBornViaMarketplace(uint256 tokenId, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, address renter, bool acceptorIsMaleOwner, uint256 rentalFee, uint256 expiry);

    constructor(string memory name, string memory symbol, address roarTokenAddress, address breedingManagerAddress) ERC721(name, symbol) {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        breedingManagerContractInstance = IBreedingManagerContract(breedingManagerAddress);
    }

    function setStates(bool newSaleIsActive, bool newBreedingIsActive) public onlyOwner {
        saleIsActive = newSaleIsActive;
        breedingIsActive = newBreedingIsActive;
    }

    function setAddresses(address roarTokenAddress, address breedingManagerAddress) public onlyOwner {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        breedingManagerContractInstance = IBreedingManagerContract(breedingManagerAddress);
    }

    function setPricesAndSupply(uint256 newPrice, uint256 newRoarPrice, uint256 maxCubMintSupply, uint256 newCooldownPillPrice, uint256 newSignatureMultiplier) public onlyOwner {
        mintPrice = newPrice;
        mintRoarPrice = newRoarPrice;
        maxMintSupply = maxCubMintSupply;
        cooldownPillPrice = newCooldownPillPrice;
        signatureMultiplier = newSignatureMultiplier;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function withdraw(uint256 amount) public onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
            emit CubMinted(_tokenIdCounter.current());
        }
    }

    function currentMintCount() external view returns (uint256) {
        return _mintCounter.current();
    }

    /*
    * Mint Roaring Roccstars, woot!
    */
    function mintCubs(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not live");
        require(_mintCounter.current() + numberOfTokens <= maxMintSupply, "Max supply");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _mintCounter.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
            emit CubMinted(_tokenIdCounter.current());
        }
    }

    /*
    * Mint Roaring Roccstar NFTs during pre-sale
    */
    function presaleMint(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Presale not live");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Presale limit");
        require(_mintCounter.current() + numberOfTokens <= maxMintSupply, "Max supply");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _mintCounter.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
            emit CubMinted(_tokenIdCounter.current());
        }
    }

    /*
    * Breed Roaring Leaders - both need to be owned by caller
    */
    function breedOwnLeaders(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) public {
        require(breedingIsActive, "Breeding not live");
        
        breedingManagerContractInstance.breedOwnLeaders(msg.sender, maleTokenId, femaleTokenId, hasSignature, instantCooldown, signature);

        roarTokenContractInstance.burnFrom(msg.sender, (mintRoarPrice + (instantCooldown ? cooldownPillPrice : 0)) * (hasSignature ? signatureMultiplier : 1) * 10 ** 18);
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());

        emit CubBorn(_tokenIdCounter.current(), maleTokenId, femaleTokenId, hasSignature, instantCooldown);
    }

    /*
    * Breed Roaring Leaders via the marketplace. One of the Leaders is owned by "renter", who is paid a fee by the caller
    */
    function breedUsingMarketplace(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, address renter, bool acceptorIsMaleOwner, uint256 rentalFee, uint256 expiry, bytes memory cooldownSignature, bytes memory listingSignature) public {
        require(breedingIsActive, "Breeding not live");
        
        breedingManagerContractInstance.breedUsingMarketplace(msg.sender, maleTokenId, femaleTokenId, hasSignature, instantCooldown, renter, acceptorIsMaleOwner, rentalFee, expiry, cooldownSignature, listingSignature);

        roarTokenContractInstance.burnFrom(msg.sender, (mintRoarPrice + (instantCooldown ? cooldownPillPrice : 0)) * (hasSignature ? signatureMultiplier : 1) * 10 ** 18);
        roarTokenContractInstance.transferFrom(msg.sender, renter, rentalFee * 10 ** 18);
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());

        emit CubBornViaMarketplace(_tokenIdCounter.current(), maleTokenId, femaleTokenId, hasSignature, instantCooldown, renter, acceptorIsMaleOwner, rentalFee, expiry);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}