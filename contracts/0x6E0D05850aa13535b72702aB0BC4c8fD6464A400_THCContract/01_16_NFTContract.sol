// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

//@author: 0xshahroz
//constructor arguments treasury address & base URI


error NoSaleStarted();

error YouHaveAldreadyMintedNFT();
error NotEnoughAmount();
error allNftsMinted();
error withdrawFailed();

contract THCContract is ERC721, Pausable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    bool public sale;
    bool public preSale;
    string _baseTokenURI;
    uint256 private PreSaleEndTime;
    uint256 public totalSupply = 1000;
    uint256 public tokenIDs = 251;
    uint256 public preSalePrice = 0.66 ether;
    uint256 public salePrice = 0.75 ether;
    
  
   
    constructor(
        address _treasuryAddr,
        string memory baseURI
    ) ERC721("The High Club", "THC") {
        for (uint256 i = 0; i < 200; i++) {
            _mint(_treasuryAddr, (i + 1));
        }
        _baseTokenURI = baseURI;
    }

 // start presale for minting for 4 days 
    function mintNFT() public payable {
        require(preSale == true || sale == true, "no sale has started");
        if ( block.timestamp > PreSaleEndTime) {
            preSale = false;
            sale = true;
            
        }
        if (preSale) {
             if (tokenIDs > 1000) {
                revert allNftsMinted();
            }

            if (msg.value < preSalePrice) {
                revert NotEnoughAmount();
            }

            _mint(msg.sender, tokenIDs);

            tokenIDs++;
        } else if (sale) {
            if (tokenIDs > 1000) {
                revert allNftsMinted();
            }
            if (msg.value < salePrice) {
                revert NotEnoughAmount();
            }
   
            _mint(msg.sender, tokenIDs);
       
            tokenIDs++;
        } 

    }   
    // airdrop NFTs to user addresses 
    //@params array of 50 addresses
        function airDrop (address _recipients) public onlyOwner {
             for (uint256 i = 0; i < 50; i++) {
            _mint(_recipients, (i + 201));  
        }
        }

        function tokenURI( uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // start presale
       function startPreSale() public onlyOwner {
        preSale = true;
         PreSaleEndTime =  block.timestamp + 4 days; 
        
    }
    
       function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    //withdraw amount
    function withdrawAmount() external onlyOwner returns (bool) {
     uint256 temp = address(this).balance;
     (bool success,) =  payable(owner()).call{value: temp}("");
    if(!success) {
        revert withdrawFailed();
    }
        return true;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}