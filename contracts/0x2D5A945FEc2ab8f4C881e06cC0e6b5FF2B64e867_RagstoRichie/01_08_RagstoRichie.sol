// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721B.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './ReentrancyGuard.sol';


  
  contract RagstoRichie is ERC721B, Ownable, ReentrancyGuard{
    using Strings for uint256;
    string public baseURI = "";
    string public hiddenURI = ""; 
    bool public isSaleActive = false;
    uint256 public constant MAX_TOKENS = 6500;
    uint256 public tokenPrice = 0.5 ether; 
    uint256 public constant maxPerTX = 3;
    bool public isRevealed = false;

    using SafeMath for uint256;
    using Strings for uint256;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("Rags to Richie by Alec Monopoly Official", "RTR") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }
      function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenURI;
      }
      
      function _price() internal view virtual returns (uint256) {
        return tokenPrice;
      }
      

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
      }
      function setHiddenURI(string memory _newHiddenURI) public onlyOwner {
        hiddenURI = _newHiddenURI;
      }

      function setPrice(uint256 _newTokenPrice) public onlyOwner {
      tokenPrice = _newTokenPrice;
      }

    function activateSale() external onlyOwner {
        isSaleActive = !isSaleActive;
      }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function Withdraw() public payable onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
      }

    function VIPMint(address dev, uint256 reserveAmount)
    external
    onlyOwner
      {
        _mint(dev, reserveAmount);
      }
    function PublicMint(uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxPerTX,
          "Can Mint only 3 per wallet"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over Max Supply"
        );
        require(
        msg.value >= tokenPrice.mul(quantity),
         "Public Mint is 0.069 eth per token"
        );
        _mint(msg.sender, quantity);
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
        string memory currentHiddenURI = _hiddenURI();

        if (isRevealed == false) {
          return
            currentHiddenURI;
        }

        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
            
      }
  }