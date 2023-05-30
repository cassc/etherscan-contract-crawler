// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721B.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

  /*Mint Info:
  One Free Mint per Wallet
  Price for any mints after: 0.0005 eth
  Max Mints Per Wallet: 5
  Supply: 10000
  */
  contract TheMuslims is ERC721B, Ownable {
    using Strings for uint256;
    string public baseURI = "";
    bool public isSaleActive = false;
    mapping(address => bool) private _freeMintClaimed;
    mapping(address => uint256) private _mintsClaimed;
    uint256 public constant MAX_TOKENS = 5000;
    uint256 public tokenPrice = 500000000000000;
    uint256 public constant maxPerWallet = 5;

    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public devReserve = 5;
    event NFTMINTED(uint256 tokenId, address owner);

    constructor() ERC721B("TheMuslims", "MSL") {}
     
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
    function mintMultiplePublic(address to, uint256 quantity) external payable {
        require(isSaleActive, "Sale not Active");
        require(
          quantity > 0 && quantity <= maxPerWallet,
          "Can Mint only 5 per Wallet"
        );
        require(
          totalSupply().add(quantity) <= MAX_TOKENS,
          "Mint is going over max per transaction"
        );
        require(msg.value >= tokenPrice.mul(quantity),
         "0.0005 eth per token"
        );
        require(
          _mintsClaimed[msg.sender].add(quantity) <= maxPerWallet,
          "Only 5 mints per wallet, priced at 0.0005 eth"
        );
        _mintsClaimed[msg.sender] += quantity;
        _mint(to, quantity);
        }

    function freeMintClaim(address to) external payable {
      require(isSaleActive, "Sale not Active");
      require(
      totalSupply().add(1) <= MAX_TOKENS,
      "Mint is going Supply"
      );
        require(
        _freeMintClaimed[msg.sender] != true,
        "Only one Free Mint per Wallet"
      );
      _freeMintClaimed[msg.sender] = true;
      _mint(to, 1);
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