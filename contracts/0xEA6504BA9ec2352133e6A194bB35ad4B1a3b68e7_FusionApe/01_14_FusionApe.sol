// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FusionApe is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Address for address;

  // Minting constants
    uint256 public constant MAX_MINT_PER_TRANSACTION = 10;
    uint256 public constant MAX_SUPPLY = 4200;
    uint256 public constant MAX_PRESALE_SUPPLY = 420;

    // Reserved for giveaways and promotions
    uint256 public constant MAX_RESERVED_SUPPLY = 20; 

    // 0.10 ETH
    uint256 public constant MINT_PRICE = 100000000000000000;
    
    bool public _isSaleActive = false;
    bool public _isPresaleActive = false;


    // Base URI for metadata to be accessed at.
    string private _uri;

    constructor() ERC721("FusionApe", "FAPE") {
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newURI New base URL of token's URI
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        _uri = _newURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

        // @dev Allows to enable/disable sale state
    function flipSaleState() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    // @dev Allows to enable/disable presale state
    function flipPresaleState() public onlyOwner {
        _isPresaleActive = !_isPresaleActive;
    }

    // @dev Reserves limited num of NFTs for giveaways and promotional purposes.
    function reserve() public onlyOwner {
      uint supply = totalSupply();
      require(supply < MAX_RESERVED_SUPPLY, "Too many have already been reserved");

        for(uint256 i = 0; i < (MAX_RESERVED_SUPPLY - supply); i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    function mintPresale(uint tokensCount) public nonReentrant payable {
      require(_isPresaleActive, "Presale is not active at the moment");
      require(totalSupply() < MAX_PRESALE_SUPPLY, "All presale tokens available have been minted");
      require(tokensCount > 0, "You must mint more than 0 tokens");
      require(tokensCount < MAX_MINT_PER_TRANSACTION, "Exceeds transaction limit");
      require((MINT_PRICE * tokensCount) <= msg.value, "The specified ETH value is incorrect");

    for (uint256 i = 0; i < tokensCount; i++) {
        _safeMint(msg.sender, totalSupply());
    }
  }

    function mintPublicSale(uint tokensCount) public nonReentrant payable {
      require(_isSaleActive, "Sale is not active at the moment");
      require(totalSupply() < MAX_SUPPLY, "All tokens available have been minted");
      require(tokensCount > 0, "You must mint more than 0 tokens");
      require(tokensCount < MAX_MINT_PER_TRANSACTION, "Exceeds transaction limit");
      require((MINT_PRICE * tokensCount) <= msg.value, "The specified ETH value is incorrect");

      for (uint256 i = 0; i < tokensCount; i++) {
          _safeMint(msg.sender, totalSupply());
      }
  }
}