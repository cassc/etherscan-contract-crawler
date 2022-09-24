// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721B.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

  /*Mint Info:
  One Free Mint per Wallet
  Price for any mints after: 0.03 eth
  Max Mints Per Wallet: 5
  Supply: 5555
  */
  contract LucidDreamers is ERC721B, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI = "";
    bool public isSaleActive = false;
    mapping(address => uint256) private _mintsClaimed;
    uint256 public constant MAX_TOKENS = 5555;
    uint256 public tokenPrice = 30000000000000000;
    uint256 public constant maxPerWallet = 25;
    uint256 public constant maxPerTX = 5;
    using SafeMath for uint256;
    using Strings for uint256;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("LucidDreamerz", "LD") {}
     
     function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }
      
      function _price() internal view virtual returns (uint256) {
        return tokenPrice;
      }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
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
    
    function withdraw() public payable onlyOwner nonReentrant {
        address fundsOneAddress = 0xc9a2d1CB428cB49418055f018F05D53F01DFF6b5;
        uint256 contractAmount = address(this).balance;
        uint256 fundsOne = contractAmount/uint256(100)*(30);
        uint256 fundsTwo = contractAmount/uint256(100)*(70);
        payable(fundsOneAddress).transfer(fundsOne);
        payable(msg.sender).transfer(fundsTwo);
    }

    function reserveTokens(address dev, uint256 reserveAmount)
    external
    onlyOwner
      {
        _mint(dev, reserveAmount);
      }
    function Mint(uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxPerTX,
          "Can Mint only 5 Per TX"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over max per transaction"
        );
        require(msg.value >= tokenPrice.mul(quantity),
         "0.03 eth per token"
        );
        require(
          _mintsClaimed[msg.sender].add(quantity) <= maxPerWallet,
          "Only 25 mints per wallet, priced at 0.03 eth"
        );
        _mintsClaimed[msg.sender] += quantity;
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

        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : ""; 
            
            
      }
  }