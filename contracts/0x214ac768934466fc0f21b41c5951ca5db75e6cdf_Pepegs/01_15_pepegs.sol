// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721A, ERC721A} from "ERC721A/ERC721A.sol";
import {ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import {OperatorFilterer} from "OperatorFilter/OperatorFilterer.sol";

error ExceedingMaxSupply();
error ExceedingMaxMint();
error SaleNotActive();
error Unauthorized();
error InvalidETHSent();

contract Pepegs is ERC721AQueryable, ERC2981, OperatorFilterer, Ownable, ReentrancyGuard {   
    uint256 public MAX_NFT_WALLET = 5;    
    uint256 public NFT_PRICE = 6900000000000000;  
    uint256 public MAX_SUPPLY = 6969;  
    uint256 public FREE_SUPPLY = 969;    
    uint256 public RESERVED_AMOUNT = 100;  
    uint256 public totalFreeMinted = 0; 
    
    bool public operatorFilteringEnabled;
    bool public collectionRevealed = false;    
    bool public saleEnabled = false;  
    string private _baseTokenURI;     

    mapping(address => uint256) private walletMinted;   
    mapping(address => bool) private freeMinted;     
    
    constructor() ERC721A("PEPEGSNFT","PEPEGS") {   
        _registerForOperatorFiltering();  
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
        _safeMint(msg.sender, RESERVED_AMOUNT);        
    }    

    //===============================================================
    //                        Mint
    //===============================================================    

    function mint(uint256 quantity) public payable nonReentrant { 
        if (!saleEnabled) 
            revert SaleNotActive();  

        if((totalSupply() + quantity) > MAX_SUPPLY) 
            revert ExceedingMaxSupply(); 

        if((walletMinted[msg.sender] + quantity) > MAX_NFT_WALLET) 
            revert ExceedingMaxMint(); 

        if(freeMinted[msg.sender] == false && totalFreeMinted < FREE_SUPPLY) {
            if (msg.value != (NFT_PRICE * (quantity - 1))) 
                revert InvalidETHSent();
            
            freeMinted[msg.sender] = true;  
            totalFreeMinted++;
        }
        else {
            if (msg.value != (NFT_PRICE * quantity)) 
                revert InvalidETHSent();
        }    

        walletMinted[msg.sender] += quantity;        
        _mint(msg.sender, quantity);  
    }    
    
    //===============================================================
    //                      Setters
    //===============================================================
    
    function setPublicSale(bool isEnabled) public onlyOwner {
        saleEnabled = isEnabled;
    }

    function setReveal(bool isRevealed) public onlyOwner {
        collectionRevealed = isRevealed;
    }
    
    function setSalePrice(uint256 price) external onlyOwner {
        NFT_PRICE = price;
    }

    function setMaxPerWallet(uint256 max) public onlyOwner {
        MAX_NFT_WALLET = max;
    }     

    function setMaxSupply(uint256 max) public onlyOwner {
        MAX_SUPPLY = max;
    } 

    function setFreeSupply(uint256 free) public onlyOwner {
        FREE_SUPPLY = free;
    } 
	
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;        
    }   

    //===============================================================
    //                      Getters
    //===============================================================

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {  
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );      
        if(!collectionRevealed)
            return _baseTokenURI;
            
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function totalInfo() public view returns (uint256[2] memory) {        
        return [totalSupply(), totalFreeMinted];
    }

    //===============================================================
    //                      Withdraw
    //===============================================================
    
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }       

    //===============================================================
    //                  OperatorFilter Overrides
    //===============================================================

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    

    //===============================================================
    //                  OperatorFilter Implementation
    //===============================================================

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    //===============================================================
    //                  ERC2981 Royalty Implementation
    //===============================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}