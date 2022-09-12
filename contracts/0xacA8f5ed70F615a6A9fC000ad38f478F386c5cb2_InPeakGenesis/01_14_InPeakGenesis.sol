// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "hardhat/console.sol";

contract InPeakGenesis is ERC721, Ownable, ReentrancyGuard {

    error Overflow(uint256 z, uint256 x);

    enum Stage {
        Inactive,
        AllowList,
        WaitList,
        Public
    }
    
    using MerkleProof for bytes32[];

    uint256 public mintStart;
    uint256 public publicPrice = 0.3 ether;


    uint256 public maxSupply = 0;
    uint256 public tokenCounter = 0;
    uint256 public pendingReservedSupply;
    uint32 public stageDuration = 3 hours;
    uint8 public activeList;

    mapping(Stage => bytes32) public rootByStage;
    mapping(uint8 => string) public tokenURIByLevel;
    mapping(uint256 => uint8) public tokenLevelOf;
    mapping(address => bool) public minted;

     constructor(uint256 pMaxSupply, uint256 pPendingReservedSupply, uint256 pMintStart, uint32 pStageDuration, uint256 pPublicPrice) ERC721("Inpeak Genesis", "IPGEN") {
        maxSupply = pMaxSupply;
        pendingReservedSupply = pPendingReservedSupply;
        mintStart = pMintStart;
        stageDuration = pStageDuration;
        publicPrice =pPublicPrice;
     }

    /// @dev Mint 1 token to `recipient`. The `price` parameter is used to validate the proof. Incorrect price reverts the tx.
    function mint(address recipient, uint256 price, bytes32[] memory proof) nonReentrant external payable {
        Stage curStage = getCurrentStage();

        require(minted[recipient] == false, 'already minted');
        require(curStage != Stage.Inactive, 'not started');
        require(getPublicRemainingSupply() > 0, "max supply reached");
        
        // Price is checked either from the proof or from public price (if on Public Stage)
        if(curStage == Stage.Public) {
            price = publicPrice;
        } else {
            require(rootByStage[curStage] != 0, "root not set for stage");// Check merkle root for stage
            require(proof.verify(rootByStage[curStage], keccak256(abi.encodePacked(recipient, price))), "invalid proof");
        } 

        require(msg.value == price, "invalid price paid");

        tokenCounter += 1;        
        minted[recipient] = true;
        _mint(recipient, tokenCounter);
    }
    
    /// @dev Mint 1 token to each `recipient` of `recipients`.
    function mintReserved(address[] memory recipients) onlyOwner external {
        require(recipients.length > 0, "invalid number of recipients");
        require(pendingReservedSupply >= recipients.length, "not enough reserved supply");
        require(maxSupply -tokenCounter > 0, "max supply reached");

        for(uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenCounter + i + 1);
        }
        tokenCounter += recipients.length;
        pendingReservedSupply -= recipients.length;
    }

    function withdraw() nonReentrant public {
        require(address(this).balance > 0, "no balance to withdraw");
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }

    /*** SETTERS ***/

    function setTokenURI(uint8 level, string memory pURI) onlyOwner public {
        tokenURIByLevel[level] = pURI;
    }

    function setStageDuration(uint32 pDuration) onlyOwner public {
        stageDuration = pDuration;
    }

    function setTokenLevel(uint256 pTokenId, uint8 pLevel) onlyOwner public {
        tokenLevelOf[pTokenId] = pLevel;
    }

    function setTokensLevel(uint256[] calldata pTokenIds, uint8 pLevel) onlyOwner public {
        for(uint256 i; i < pTokenIds.length; i++) {
            tokenLevelOf[pTokenIds[i]] = pLevel;
        }
    }

    function setTokensLevels(uint256[] calldata pTokenIds, uint8[] calldata pLevels) onlyOwner public {
        require(pTokenIds.length == pLevels.length, "invalid array lengths");
        for(uint256 i; i < pTokenIds.length; i++) {
            tokenLevelOf[pTokenIds[i]] = pLevels[i];
        }
    }

    function setMerkleRoot(Stage pStage, bytes32 pRoot) onlyOwner public {
        rootByStage[pStage] = pRoot;
    }

    function setMaxSupply(uint256 pMaxSupply) onlyOwner public {
        require(pMaxSupply - tokenCounter - pendingReservedSupply > 0, "invalid max supply");
        maxSupply = pMaxSupply;
    }

    /// @dev Set the reserved supply for marketing.
    function setPendingReservedSupply(uint256 pPendingReservedSupply) onlyOwner public {
        require(tokenCounter + pPendingReservedSupply <= maxSupply, "cant reserve more than maximum supply");
        pendingReservedSupply = pPendingReservedSupply;
    }

    /// @dev Set the mint start date
    function setMintStart(uint256 pMintStart) onlyOwner public {
        require(pMintStart > block.timestamp, "mint start must be in the future");
        require(mintStart == 0 || mintStart > block.timestamp, "mint already started");
        mintStart = pMintStart;
    }

    /// @dev Set the price for Public Stage minting
    function setPublicPrice(uint256 pPublicPrice) onlyOwner public {
        publicPrice = pPublicPrice;
    }
    
    /*** VIEWS ***/

       /// @dev Returns the URI of a token.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "invalid token id");
        return tokenURIByLevel[tokenLevelOf[tokenId]];
    }

    /// @dev Returns the current stage of minting.
    function getCurrentStage() public view returns(Stage stage) {
        if(mintStart == 0 || block.timestamp < mintStart) return Stage.Inactive;
        if(block.timestamp < mintStart + stageDuration) return Stage.AllowList;
        if(block.timestamp < mintStart + (stageDuration * 2)) return Stage.WaitList;
        if(block.timestamp >= mintStart + (stageDuration * 2)) return Stage.Public;
    }

    function timeUntilStage(Stage pStage) public view returns (uint256 timeRemaining) {
        if(pStage == Stage.Inactive) return 0;
        if(pStage == Stage.AllowList) return block.timestamp > mintStart ? 0 : mintStart - block.timestamp;
        if(pStage == Stage.WaitList) return block.timestamp > (mintStart + stageDuration) ? 0 : mintStart + stageDuration - block.timestamp;
        if(pStage == Stage.Public) return block.timestamp > mintStart + (stageDuration * 2) ? 0 : mintStart + (stageDuration *  2) - block.timestamp;   
    }

    /// @dev Returns the remaining supply for public mints
    function getPublicRemainingSupply() public view returns (uint256) {
        return maxSupply - tokenCounter - pendingReservedSupply;
    }

    /// @dev Returns the remaining real remaining supply without considering pending reserved
    function getRemainingSupply() public view returns (uint256) {
        return maxSupply - tokenCounter;
    }
}