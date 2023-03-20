// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract DejaVuUniverseComics is Ownable, ERC721Enumerable  {
    using Strings for uint256;

    uint public constant MAX_TOKENS = 3333;
    
    uint256 public PRICE = 0.0005 ether;
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

    constructor() ERC721("Deja Vu Universe Comics", "DJU") {}


    function mint(uint256 quantity) external payable onlyWhenNotPaused{
        require(quantity <= MAX_TOKENS, "Not enough tokens left");
        require(msg.value >= (PRICE * quantity), "Not enough ether sent");
        require(quantity > 0 && quantity <= MAX_PER_MINT, "Exceeded the limit per transaction");
        _safeMint(msg.sender, quantity);
    }



    function setPaused(bool val) public onlyOwner {
        _paused = val;
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
        function burn (uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner or approved");
        _burn(_tokenId);
    }
    function withdraw() public onlyOwner  {
        payable(owner()).transfer(address(this).balance);
    }

}