// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721B.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

  contract SimplyPossessed is ERC721B, Ownable {
    using Strings for uint256;
    string public baseURI = "";
    string public unrevealedURI = ""; 
    bool public isRevealed = false;
    bool public isSaleActive = false;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant FREE_MINTS = 1000;
    uint256 public tokenPrice = 9000000000000000;
    uint256 public constant maxTokenPurchase = 15;

    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public devReserve = 5;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("Simply Possessed", "SP") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }
       function _unrevealedURI() internal view virtual returns (string memory) {
        return unrevealedURI;
      }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
      }
      function setUnrevealedURI(string memory _newUnrevealedURI) public onlyOwner {
        unrevealedURI = _newUnrevealedURI;
      }
      
    function reveal() public onlyOwner {
        isRevealed = true;
      }

      function _tokenPrice() internal view virtual returns (uint256) {
        return tokenPrice;
      }

       function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
      }

    function activateSale() external onlyOwner {
        isSaleActive = !isSaleActive;
      }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function Withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
      }

    function reserveTokens(address dev, uint256 reserveAmount)
    external
    onlyOwner
      {
        require(
        reserveAmount > 0 && reserveAmount <= devReserve,
          "Dev reserve empty"
        );
        totalSupply().add(1);
        _mint(dev, reserveAmount);
      }
    function mintNFT(address to, uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxTokenPurchase,
          "Nothing Selected to Mint"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over max per transaction"
        );
        if(totalSupply()<=FREE_MINTS){
           _mint(to, quantity);
        }else{
          require(
          msg.value >= tokenPrice.mul(quantity),
          "Invalid amount sent"
        );
        _mint(to, quantity);
        }
    }
     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
    
        string memory currentBaseURI = _baseURI();
        string memory currentUnrevealed = _unrevealedURI();
    
        if (isRevealed == false) {
          return
            currentUnrevealed;
        }
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
            
      }
}