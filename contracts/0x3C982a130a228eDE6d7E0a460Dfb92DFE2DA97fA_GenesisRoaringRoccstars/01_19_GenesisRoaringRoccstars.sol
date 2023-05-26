// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IStakingContract.sol";
import "./ITokenContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract GenesisRoaringRoccstars is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    ITokenContract public roarTokenContractInstance;

    IStakingContract public genesisRoarStakingContractInstance;

    uint256 public mintRoarPrice = 6000;

    uint256 public cooldownPillPrice = 3000;
    
    uint256 public maxTokenSupply = 100;

    uint256 public cooldown = 28 * 24 * 3600;

    bool public breedingIsActive = false;

    // Used to validate authorized mint addresses
    address private signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    // Mapping of token numbers to last timestamp bred
    mapping(uint256 => uint256) public lastTimestamps;

    event CubBorn(uint256 tokenId, uint256 firstTokenId, uint256 secondTokenId, bool instantCooldown);
    event CubBornUsingMarketplace(uint256 tokenId, uint256 firstTokenId, uint256 secondTokenId, bool instantCooldown, address renter, bool acceptorIsFirstOwner, uint256 rentalFee, uint256 expiry);

    constructor(string memory name, string memory symbol, address roarTokenAddress, address roarStakingAddress) ERC721(name, symbol) {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        genesisRoarStakingContractInstance = IStakingContract(roarStakingAddress);
    }

    function setAddresses(address roarTokenAddress, address roarStakingAddress, address newSignerAddress) public onlyOwner {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        genesisRoarStakingContractInstance = IStakingContract(roarStakingAddress);
        signerAddress = newSignerAddress;
    }

    function flipBreedingState() public onlyOwner {
        breedingIsActive = !breedingIsActive;
    }

    function setVariables(uint256 newRoarPrice, uint256 maxCubSupply, uint256 newCooldown, uint256 newCooldownPillPrice) public onlyOwner {
        mintRoarPrice = newRoarPrice;
        maxTokenSupply = maxCubSupply;
        cooldown = newCooldown;
        cooldownPillPrice = newCooldownPillPrice;
    }

    function hashListing(uint256 tokenId, uint256 rentalFee, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            tokenId,
            rentalFee,
            expiry
        ));
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
    * Breed Genesis Roaring Leaders - both need to be owned by caller
    */
    function breedGenesisLeaders(uint256 firstTokenId, uint256 secondTokenId, bool instantCooldown) public {
        require(_tokenIdCounter.current() < maxTokenSupply, "Max supply");
        require(breedingIsActive, "Breeding not live");
        require(firstTokenId != secondTokenId, "Tokens not unique");

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = firstTokenId;
        tokenIds[1] = secondTokenId;
        require(genesisRoarStakingContractInstance.hasDepositsOrOwns(msg.sender, tokenIds), "Not owner");

        _verifyCooldowns(firstTokenId, secondTokenId, instantCooldown);

        roarTokenContractInstance.burnFrom(msg.sender, instantCooldown ? (mintRoarPrice + cooldownPillPrice) * 10 ** 18 : mintRoarPrice * 10 ** 18);
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());

        emit CubBorn(_tokenIdCounter.current(), firstTokenId, secondTokenId, instantCooldown);
    }

    /*
    * Breed Genesis Roaring Leaders - both need to be owned by caller
    */
    function breedUsingMarketplace(uint256 firstTokenId, uint256 secondTokenId, bool instantCooldown, address renter, bool acceptorIsFirstOwner, uint256 rentalFee, uint256 expiry, bytes memory listingSignature) public {
        require(_tokenIdCounter.current() < maxTokenSupply, "Max supply");
        require(breedingIsActive, "Breeding not live");
        require(expiry > block.timestamp, "Listing has expired");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = firstTokenId;
        require(genesisRoarStakingContractInstance.hasDepositsOrOwns(acceptorIsFirstOwner ? msg.sender : renter, tokenIds), "Not owner");
        tokenIds[0] = secondTokenId;
        require(genesisRoarStakingContractInstance.hasDepositsOrOwns(acceptorIsFirstOwner ? renter : msg.sender, tokenIds), "Not owner");

        _verifyCooldowns(firstTokenId, secondTokenId, instantCooldown);

        bytes32 hashToVerify = hashListing(acceptorIsFirstOwner ? secondTokenId : firstTokenId, rentalFee, expiry);
        require(renter == hashToVerify.toEthSignedMessageHash().recover(listingSignature), "Invalid listing signature");

        roarTokenContractInstance.burnFrom(msg.sender, instantCooldown ? (mintRoarPrice + cooldownPillPrice) * 10 ** 18 : mintRoarPrice * 10 ** 18);
        roarTokenContractInstance.transferFrom(msg.sender, renter, rentalFee * 10 ** 18);
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());

        emit CubBornUsingMarketplace(_tokenIdCounter.current(), firstTokenId, secondTokenId, instantCooldown, renter, acceptorIsFirstOwner, rentalFee, expiry);
    }

    function _verifyCooldowns(uint256 firstTokenId, uint256 secondTokenId, bool instantCooldown) internal {
        if (!instantCooldown) {
            require((lastTimestamps[firstTokenId] + cooldown < block.timestamp) && (lastTimestamps[secondTokenId] + cooldown < block.timestamp), "Cooldown not expired");
        }

        lastTimestamps[firstTokenId] = block.timestamp;
        lastTimestamps[secondTokenId] = block.timestamp;
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