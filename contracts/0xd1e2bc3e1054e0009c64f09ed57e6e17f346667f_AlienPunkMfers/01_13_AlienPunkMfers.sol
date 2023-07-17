// SPDX-License-Identifier: MIT

/*******************************************************************************
       _ _                                _                 __              
      | (_)                              | |               / _|             
  __ _| |_  ___ _ __    _ __  _   _ _ __ | | __  _ __ ___ | |_ ___ _ __ ___ 
 / _` | | |/ _ \ '_ \  | '_ \| | | | '_ \| |/ / | '_ ` _ \|  _/ _ \ '__/ __|
| (_| | | |  __/ | | | | |_) | |_| | | | |   <  | | | | | | ||  __/ |  \__ \
 \__,_|_|_|\___|_| |_| | .__/ \__,_|_| |_|_|\_\ |_| |_| |_|_| \___|_|  |___/
                       | |                                                  
                       |_|    

 "we all mfers. there is no king, ruler, or defined roadmap -- and mfers can 
        build whatever they can think of with these mfers." -a mfer   
                            alienpunkmfers.com                                           
*******************************************************************************/

pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721 {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
}

abstract contract DROOL {
  function burnFrom(address _from, uint256 _amount) external virtual;
}

contract AlienPunkMfers is Ownable, ERC721ABurnable {
    
    struct TokenData {
        uint gene;
        uint generation;
        uint parentGene;
        uint parentHead;
        uint lastEvoTime;
        uint shedCount;
    }

    // Public properties
    string public baseURI = "";
    uint public txnLimit = 100;
    uint public mintPrice = 0.0069 ether;
    uint public max = 10000;
    uint public pluckPrice = 0 ether;
    uint public shedPrice = 0 ether;
    bool public pluckingEnabled = false;
    bool public shedingEnabled = false;
    bool public saleIsActive = false;
    uint public pluckCooldown = 0;
    mapping(uint => bool) public mferClaimed;
    mapping(uint => bool) public aptClaimed;
    DROOL public drool;
    
    // Private properties
    uint private lastRandomForGene;
    mapping(uint => TokenData) private tokenData;
    ERC721 private alienPunkThings;
    ERC721 private mfers;

    // Events
    event Evolved(uint indexed _tokenId, bool plucked);
    
    constructor() 
        ERC721A("Alien Punk Mfers", "AlienPunkMfers")
         {
        alienPunkThings = ERC721(0x5B98Ab35514C1C91F33ba12E0778D53E1eBDb106);
        mfers = ERC721(0x79FCDEF22feeD20eDDacbB2587640e45491b757f);
    }

    // Mint functions
    function mint(uint total) external payable {
        require(total > 0, "No 0 txns");
        require(total <= txnLimit, "Over txn limit");
        require(saleIsActive, "Paused");
        require(mintPrice * total <= msg.value, "Not enough eth");  
        require(max >= totalSupply() + total, "Exceeds max supply");

        _safeMint(msg.sender, total);
    }

    function aptClaim(uint[] calldata aptTokenIds) external {
        uint total = aptTokenIds.length;
        require(max >= totalSupply() + total, "Exceeds max supply");
        for(uint i=0; i < total; i++) {
            uint tokenId = aptTokenIds[i];
            require(!aptClaimed[tokenId], "Already claimed");
            require(alienPunkThings.ownerOf(tokenId) == msg.sender, "Not yours");
            aptClaimed[tokenId] = true;
        }
        _safeMint(msg.sender, total);
    }

    function mferClaim(uint[] calldata mferTokenIds) external {
        uint total = mferTokenIds.length;
        require(max >= totalSupply() + total, "Exceeds max supply");
        for(uint i=0; i < total; i++) {
            uint tokenId = mferTokenIds[i];
            require(!mferClaimed[tokenId], "Already claimed");
            require(mfers.ownerOf(tokenId) == msg.sender, "Not yours");
            mferClaimed[tokenId] = true;
        }
        _safeMint(msg.sender, total);
    }

    // Evolution functions
    function shedHeads(uint tokenId) external {
        require(shedingEnabled, "Paused");
        require(hasHead(tokenId, 1) || hasHead(tokenId,2), "No head");
        require(ownerOf(tokenId) == msg.sender, "Not your token"); 

        // Make sure cooldown has passed
        uint time = block.timestamp;
        uint lastEvoTime = tokenData[tokenId].lastEvoTime;
        require(lastEvoTime == 0 || time - lastEvoTime >= pluckCooldown, "Head is not ripe");

        if(shedPrice > 0) {
            // Sacrifices must be made
            drool.burnFrom(msg.sender, shedPrice);
        }
        tokenData[tokenId].shedCount += 1;
        tokenData[tokenId].lastEvoTime = time;
        emit Evolved(tokenId, false);
    }
    
    function pluckHead(uint tokenId, uint head) external {
        require(pluckingEnabled, "Paused");
        require(hasHead(tokenId, 1) && head == 1 || hasHead(tokenId,2) && head == 2 , "No head");
        require(ownerOf(tokenId) == msg.sender, "Not your token");
        
        // Make sure cooldown has passed
        uint time = block.timestamp;
        uint lastEvoTime = tokenData[tokenId].lastEvoTime;
        require(lastEvoTime == 0 || time - lastEvoTime >= pluckCooldown, "Head is not ripe");

        // Create ancestry data for new token
        TokenData storage data = tokenData[tokenId];
        uint parentGene = geneOf(tokenId);
        data.generation += 1;
        data.parentGene = parentGene;
        data.parentHead = head;
        data.gene = randomGene();
        data.lastEvoTime = time;
        
        if(pluckPrice > 0) {
            // Sacrifices must be made
            drool.burnFrom(msg.sender, pluckPrice);
        }

        emit Evolved(tokenId, true);
    }
    
    // Public ancestry and gene functions
    function geneOf(uint tokenId) public view virtual returns (uint gene) {
        require(_exists(tokenId), "Token does not exist.");
        TokenData memory data = tokenData[tokenId];
        return data.generation > 0 ? data.gene : uint256(keccak256(abi.encodePacked(string(toString(tokenId)))));
    }

    function parentGeneOf(uint tokenId) external view virtual returns (uint parentTokenId) {
        require(_exists(tokenId), "Token does not exist.");
        require(tokenData[tokenId].generation > 0, "Has no parent");
        return tokenData[tokenId].parentGene;
    }

    function parentHeadOf(uint tokenId) external view virtual returns (uint parentHead) {
        require(_exists(tokenId), "Token does not exist.");
        require(tokenData[tokenId].generation > 0, "Has no parent");
        return tokenData[tokenId].parentHead;
    }
    
    function generationOf(uint tokenId) external view virtual returns (uint generation) {
        require(_exists(tokenId), "Token does not exist.");
        return tokenData[tokenId].generation;
    }

    function shedCountOf(uint tokenId) external view virtual returns (uint shedCount) {
        require(_exists(tokenId), "Token does not exist.");
        return tokenData[tokenId].shedCount;
    }

    function hasHead(uint tokenId, uint head) public view virtual returns (bool) {
        require(_exists(tokenId), "Token does not exist.");
        require(head == 1 || head == 2, "Invalid head");
        bool result = false;
        uint rnd  = random(string(abi.encodePacked(tokenData[tokenId].shedCount, toString(geneOf(tokenId))))) % 500;
        if(rnd >= 75 && rnd < 375) {
            // This mfer only has the left growth
            result = head == 1;
        }
        if(rnd >= 375 && rnd < 475) {
            // This mfer only has the right growth
            result = head == 2;
        }
        if(rnd >= 475 && rnd < 500) {
            // This mfer has both growths
            result = true;
        }
        // This mfer has no growths
        return result;
    }

    function lastEvoTimeOf(uint tokenId) external view virtual returns(uint birthBlockTime) {
        require(_exists(tokenId), "Token does not exist.");
        return tokenData[tokenId].lastEvoTime;
    }

    // Public admin functions
    function flipSaleState() external {
        checkOwner();
        saleIsActive = !saleIsActive;
    }

    function setPluckData(address droolAddr, bool enablePlucking, uint pluckCost, bool enableShedding, uint shedCost, uint cooldown) external {
        checkOwner();
        drool = DROOL(droolAddr);
        pluckPrice = pluckCost;
        pluckCooldown = cooldown;
        pluckingEnabled = enablePlucking;
        shedPrice = shedCost;
        shedingEnabled = enableShedding;
    }

    function setBaseURI(string memory baseURI_) external {
        checkOwner();
        baseURI = baseURI_;
    }

    function releaseAll() external {
        uint balance = address(this).balance;
        uint charity = balance / 100 * 10;
        uint artist = balance / 100 * 45;
        uint dev = balance / 100 * 45;
        Address.sendValue(payable(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C), charity);
        Address.sendValue(payable(0x0beAF25a1De14FAF9DB5BA0bad13B70267e3D01e), artist);
        Address.sendValue(payable(0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7), dev);
    }

    // Utility functions
    function checkOwner() internal view {
        require(owner() == _msgSender(), "Not owner");
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function randomGene() internal returns (uint256) {
        unchecked {
            lastRandomForGene = uint256(keccak256(abi.encode(keccak256(abi.encodePacked(msg.sender, tx.origin, gasleft(), lastRandomForGene, block.timestamp, block.number, blockhash(block.number), blockhash(block.number-100))))));
        }
        return lastRandomForGene;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // overrides
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }
}