// SPDX-License-Identifier: MIT
// Special thanks to Pagzi Tech for letting us use their Pagzi protocol to reduce gas fees. pagzi.ca
pragma solidity ^0.8.10;

import "./ERC721Enum.sol";
import "./SB.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Imps contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract IMPS is ERC721Enum, Ownable, ReentrancyGuard {
    using Strings for uint256;

    Superballs private immutable SBalls = Superballs(0xCDc587359C62140fe4Bd1764011643131A980d2f);
    string public ImpsPROVENANCE;
    uint256 constant public maxImps = 10000;
    uint256 constant public MaxMintedImps = 10;
    uint256 public collectionStartingIndex;
    bool public PreSaleIsActive = false;
    bool public PublicSaleIsActive = false;

    // presale price 0.03 ETH and public sale price 0.05 ETH
    uint256 public ImpsPreSalePRICE = 30000000000000000;
    uint256 public ImpsPublicSalePRICE = 50000000000000000;
    string private baseURI;
    mapping(address => uint256) public MintedWallets;
    mapping(uint256 => bool) public SuperballPresaleMinted;
    mapping(uint256 => bool) public FloatingHeadClaimed;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721P(name, symbol){

    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        ImpsPROVENANCE = provenanceHash;
     }

     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
     }

     function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
     }
    
     function flipPreSaleState() external onlyOwner {
        PreSaleIsActive = !PreSaleIsActive;
     }

     function flipPublicSaleState() external onlyOwner {
        PublicSaleIsActive = !PublicSaleIsActive;
     }

      // for emergencies only
     function setPublicSalePrice(uint256 newPrice) external onlyOwner {
         ImpsPublicSalePRICE = newPrice;
     }

      // for emergencies only
     function setPreSalePrice(uint256 newPrice) external onlyOwner {
         ImpsPreSalePRICE = newPrice;
     }

     function setStartingIndex() external onlyOwner {
        collectionStartingIndex = block.timestamp % maxImps ;

        if (collectionStartingIndex == 0) {
            collectionStartingIndex = collectionStartingIndex + 1;
         }
     }

     function PublicMintImps(uint256 numImps) external payable nonReentrant {
        require(PublicSaleIsActive, "Sale isn't active yet!");
        require(numImps + totalSupply() <= maxImps, "Purchase would exceed max supply of Imps.");
        require(MintedWallets[msg.sender] + numImps <= MaxMintedImps, "Each wallet can only mint 10 Imps.");
        uint costToMint = ImpsPublicSalePRICE * numImps;
        require(costToMint == msg.value, "Eth value incorrect.");

        for(uint256 i=0; i < numImps; i++ ) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        MintedWallets[msg.sender] = MintedWallets[msg.sender] + numImps;
     }

     function PreSuperballMintImps(uint256[] memory SBs) external payable nonReentrant {
        require(PreSaleIsActive, "PreSale isn't active yet!");
        require(SBs.length + totalSupply() <= maxImps, "Purchase would exceed max supply of Imps.");
        for (uint256 j=0; j<SBs.length;j++){
         require(SBalls.ownerOf(SBs[j]) == msg.sender, "You don't own one of the SuperBalls");
         require(!SuperballPresaleMinted[SBs[j]], "The IMP for a SuperBall has been claimed");
        }       
        uint costToMint = ImpsPreSalePRICE * SBs.length;
        require(costToMint == msg.value, "Eth value incorrect.");

        for(uint256 i=0; i < SBs.length; i++ ) {
            require(!SuperballPresaleMinted[SBs[i]], "The IMP for a SuperBall has been claimed");
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            SuperballPresaleMinted[SBs[i]] = true;
        }
     }
    
      function PreFloatingHeadMintImps(uint256[] memory FHs) external nonReentrant {
        require(PreSaleIsActive, "PreSale isn't active yet!");
        require(FHs.length + totalSupply() <= maxImps, "Purchase would exceed max supply of Imps.");
        for (uint256 j=0; j<FHs.length;j++){
         require(SBalls.checkBalance(FHs[j],msg.sender) == 1, "You are not the owner of this head.");
         require(!FloatingHeadClaimed[FHs[j]], "The IMP for a FH has been claimed");
        }       

        for(uint256 i=0; i < FHs.length; i++ ) {
            require(!FloatingHeadClaimed[FHs[i]], "The IMP for a FH has been claimed");
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            FloatingHeadClaimed[FHs[i]] = true;
        }
     }

     function ImpsGiveaway(uint256 amount, address reciever) external onlyOwner {
        require(totalSupply()+amount <= maxImps, "Giveaway would exceed max supply of Imps");
        
        for(uint256 i=0; i < amount; i++ ) {
            uint256 mintIndex = totalSupply();
            _safeMint(reciever, mintIndex);
        }
     }

     function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
     }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

}