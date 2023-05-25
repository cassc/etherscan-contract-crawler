// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";
import "./FrenshipToken.sol";

contract ZooFrenzToken is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    FrenshipToken FSToken;

    string public baseURI;
    string public unrevealURI;
    uint256 public price = 0.15 ether;
    uint256 public presaleEndDate;
    uint256 public claimStartTime;
    uint256 public claimCooldown = 1 days;
    uint256 public frenz3dNumber = 1;
    uint16 public claim3dModelCost = 400;
    bool public enableClaim;

    address private signer;

    mapping(uint256=>uint256) public randomResults;
    mapping(uint256=>uint8) public frenzRarities;
    mapping(uint256=>bool) public claimedFrenz3d;
    mapping(uint256=>uint256) public numberOf3dFrenz;
    mapping(uint8=>uint8) public FSTClaimNumber;
    mapping(uint256=>uint256) public tokenClaimedTime;
    mapping(address=>uint64) public whitelistMinted;
    mapping(address=>uint8) public allowlist;
    mapping(string => bool) private ticketUsed;

    constructor(address initSigner, address initFSTAddress, uint256 maxAmountPerMint, uint256 maxCollection) ERC721A("ZooFrenzToken", "ZFT", maxAmountPerMint, maxCollection) {

        signer = initSigner;
        
        FSToken = FrenshipToken(initFSTAddress);

        initFSTClaimNumber();
    }

    function initFSTClaimNumber () private {
        FSTClaimNumber[1] = 8;
        FSTClaimNumber[2] = 9;
        FSTClaimNumber[3] = 10;
        FSTClaimNumber[4] = 11;
        FSTClaimNumber[5] = 12;
    }

    function setPresaleEndDate(uint256 newDate) public onlyOwner {
        presaleEndDate = newDate;
    }

    function setEnableClaim(bool enable) public onlyOwner {
        enableClaim = enable;
        claimStartTime = block.timestamp;
    }

    function setClaimNumbers(uint8[] calldata rarities, uint8[] calldata amounts) public onlyOwner {
        require(rarities.length == amounts.length, "rarities does not match amounts length");
        
        for (uint256 i = 0; i < rarities.length; i++) {
            FSTClaimNumber[rarities[i]] = amounts[i];
        }
    }

    function setClaimCooldown(uint256 cooldown) public onlyOwner{
        claimCooldown = cooldown;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setClaim3dModelCost(uint16 newCost) public onlyOwner {
        claim3dModelCost = newCost;
    }

    function setRarities(uint256[] calldata tokenIds, uint8[] calldata ratities) external onlyOwner {
        require(tokenIds.length == ratities.length, "tokenIds does not match ratities length");
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            frenzRarities[tokenIds[i]] = ratities[i];
        }
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function setAllowlist(address[] calldata addresses, uint8[] calldata mintAmount) external onlyOwner
    {
        require(addresses.length == mintAmount.length, "addresses does not match numSlots length");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = mintAmount[i];
        }
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
	}

    function recycleToken(address to, uint256 amount) external onlyOwner {
        FSToken.transfer(to, amount);
	}

    function isWhitelistAuthorized(
        address sender, 
        string memory ticket,
        uint8 allowAmount,
        uint64 exipreTime,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hashMsg = keccak256(abi.encodePacked(sender, ticket, allowAmount, exipreTime));
        bytes32 ethHashMessage = hashMsg.toEthSignedMessageHash();

        return ethHashMessage.recover(signature) == signer;
    }

    function isAuthorized(
        address sender, 
        string memory ticket,
        uint64 exipreTime,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hashMsg = keccak256(abi.encodePacked(sender, ticket, exipreTime));
        bytes32 ethHashMessage = hashMsg.toEthSignedMessageHash();

        return ethHashMessage.recover(signature) == signer;
    }

    function mint(uint8 amount, uint8 allowAmount, string calldata ticket, uint64 exipreTime, bytes calldata signature) external payable callerIsUser nonReentrant {
        
        require(amount > 0, "You can get no fewer than 1");

        require(amount <= maxBatchSize, "too much");
        
        uint256 supply = totalSupply();

        require(supply + amount <= collectionSize, "reached max supply");

        require(!ticketUsed[ticket], "ticket used");

        require(block.timestamp <= exipreTime, "ticket expired");
        
        if(block.timestamp <= presaleEndDate) {
            require(whitelistMinted[msg.sender] + amount <= allowAmount, "exceed mint number");
            require(isWhitelistAuthorized(msg.sender, ticket, allowAmount, exipreTime, signature), "auth failed");
            whitelistMinted[msg.sender] += amount;
        } else {
            require(isAuthorized(msg.sender, ticket, exipreTime, signature), "auth failed");
        }

        uint256 finalPrice = price.mul(amount);

        require(msg.value >= finalPrice, "not enough!");
        
        ticketUsed[ticket] = true;

        mintFrenz(amount, supply, ticket, msg.sender);
    }

    function devMint(uint256 amount, string calldata ticket, address to) external nonReentrant onlyOwner{
        uint256 supply = totalSupply();
        
        require(supply + amount <= collectionSize, "reached max supply");

        mintFrenz(amount, supply, ticket, to);
    }

    function allowlistMint(uint8 amount, string calldata ticket, uint64 exipreTime, bytes calldata signature) external nonReentrant callerIsUser {
        
        require(allowlist[msg.sender] >= amount, "not eligible for allowlist mint");

        require(totalSupply() + amount <= collectionSize, "reached max supply");

        require(isAuthorized(msg.sender, ticket, exipreTime, signature), "auth failed");

        require(block.timestamp <= exipreTime, "ticket expired");

        allowlist[msg.sender] -= amount;
        
        uint256 supply = totalSupply();

        mintFrenz(amount, supply, ticket, msg.sender);
    }

    function mintFrenz(uint256 _amount, uint256 lastTokenId, string calldata seed, address to) private {
        
        _safeMint(to, _amount);

        uint256 total = lastTokenId + _amount;

        for(; lastTokenId < total; lastTokenId++) {
            
            uint256 tokenId = lastTokenId;
            
            randomResults[tokenId] = uint256(keccak256(abi.encodePacked(seed, tokenId, blockhash(block.number - 1), block.timestamp))) % 10000000000000;
        }
    }

    function getRandomResult(uint256 tokenId) external view returns(uint256) {
        return randomResults[tokenId];
    }

    function claim(uint256 tokenId) external callerIsUser nonReentrant {

        require(enableClaim, "not started yet");

        uint256 claimAmount = getRewardCountOfOwner(tokenId);

        FSToken.mint(msg.sender, claimAmount);

        tokenClaimedTime[tokenId] = block.timestamp;
    }

    function getRewardCountOfOwner(uint256 tokenId) public view returns (uint256) {

        require(ownerOf(tokenId) == msg.sender, "not token owner");

        require (frenzRarities[tokenId] > 0, "not revealed");

        uint256 claimedTime = tokenClaimedTime[tokenId];
    
        if (claimedTime == 0) 
            claimedTime = claimStartTime;

        uint256 count = uint256((block.timestamp - claimedTime) / claimCooldown);
        
        require (count > 0, "no reward yet");

        return count * FSTClaimNumber[frenzRarities[tokenId]];
    }

    function getTokenClaimTime(uint256 tokenId) private view returns (uint256) {
        
        require(ownerOf(tokenId) == msg.sender, "not owner");

        return tokenClaimedTime[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if(frenzRarities[tokenId] == 0) {
            return unrevealURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function claim3DFrenz(uint256 tokenId) external callerIsUser nonReentrant {
        require(!claimedFrenz3d[tokenId], "3d model claimed");

        require(ownerOf(tokenId) == msg.sender, "not owner");

        require(FSToken.balanceOf(msg.sender) >= claim3dModelCost, "not enough");

        FSToken.transferFrom(msg.sender, address(this), claim3dModelCost);
        
        claimedFrenz3d[tokenId] = true;

        numberOf3dFrenz[tokenId] = frenz3dNumber;

        frenz3dNumber++;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}