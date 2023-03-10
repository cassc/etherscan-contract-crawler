// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ORDINALGOBLIN is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint public constant MAX_TOKENS = 5000;
    
    uint256 public PRICE = 0.005 ether;
    uint public perAddressLimit = 100;
    uint public constant MAX_PER_MINT = 100;

    
    bool public saleIsActive = true;
    bool public revealed = true;
    bool public paused = false;

    string private _baseTokenURI;
    string public notRevealedUri;


    bool public _paused;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    mapping(address => uint) public addressMintedBalance;
    // mapping(address => bool) public whitelistClaimed;

    constructor() ERC721A("ORDINAL GOBLIN", "OG") {}
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function mint(uint256 quantity) external payable onlyWhenNotPaused{
        require(totalSupply() + quantity <= MAX_TOKENS, "Not enough tokens left");
        require(quantity + _numberMinted(msg.sender) <= perAddressLimit, "Exceeded the limit per wallet");
        require(msg.value >= (PRICE * quantity), "Not enough ether sent");
        require(quantity > 0 && quantity <= MAX_PER_MINT, "Exceeded the limit per transaction");
        _safeMint(msg.sender, quantity);
    }



    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    
    
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
    }
    
    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  function setPUBLIC_SALE_PRICE(uint256 _newCost) public onlyOwner {
    PRICE = _newCost;
  }
  
     function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
    function withdraw() public onlyOwner  {
        payable(owner()).transfer(address(this).balance);
    }

}