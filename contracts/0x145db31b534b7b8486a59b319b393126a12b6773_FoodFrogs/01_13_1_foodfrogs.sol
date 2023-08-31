// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoodFrogs is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant MINT_LIMIT = 10;
  uint256 public constant COST_PER_FROG = 60000000000000000; // 0.06 ETH
  uint256 public constant PRESALE_LIMIT_PER_ADDRESS = 10;

  string public _uriPrefix;
  string public _uriSuffix;
  
  bool public _isPresaleActive = false;
  bool public _isPublicSaleActive = false;
  
  mapping(address => bool) public _presaleAddresses;
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function mint(uint256 quantity) public payable {
    require(quantity > 0, "quantity must be greater than 0");
    uint256 supply = totalSupply();
    require(supply + quantity <= MAX_SUPPLY, "quantity would exceed total supply");

    if (msg.sender != owner()) {
        require(_isPublicSaleActive || _isPresaleActive, "contract is closed");
        require(quantity <= MINT_LIMIT, "quantity must not be greater than 10");
        require(msg.value >= COST_PER_FROG * quantity, "insufficient funds");

        // Skip presale logic if the sale is public.
        if (!_isPublicSaleActive)
        {
            require(_presaleAddresses[msg.sender] == true, "address is not part of presale");
            uint256 ownerMintedCount = balanceOf(msg.sender);
            require(ownerMintedCount + quantity <= PRESALE_LIMIT_PER_ADDRESS, "per-address presale limit exceeded");
        }
    }

    for (uint256 i = 1; i <= quantity; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function setSaleState(bool presale, bool publicSale) public onlyOwner {
    require(!presale || !publicSale, "contract cannot simultaneously be in both a pre sale and public sale state");
    _isPresaleActive = presale;
    _isPublicSaleActive = publicSale;
  }

  function setPresaleAddressState(address[] calldata presaleAddresses, bool enable) public onlyOwner {
    for (uint256 i; i < presaleAddresses.length; i++) {
        address addr = presaleAddresses[i];
        _presaleAddresses[addr] = enable;
    }
  }
  
  function setURIPrefix(string memory uriPrefix) public onlyOwner {
    _uriPrefix = uriPrefix;
  }

  function setURISuffix(string memory uriSuffix) public onlyOwner {
    _uriSuffix = uriSuffix;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(_exists(tokenId), "token does not exist");
    string memory uriPrefix = _uriPrefix;
    if (bytes(uriPrefix).length == 0) {
        return "";
    }
    return string(abi.encodePacked(uriPrefix, tokenId.toString(), _uriSuffix));
  }
}