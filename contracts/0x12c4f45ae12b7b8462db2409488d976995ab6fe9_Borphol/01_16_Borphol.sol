// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Borpacasso {
  function balanceOf(address owner) public view virtual returns(uint256) {
  }
}

contract Borphol is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
      string private _baseURIPrefix;

  mapping(address => uint) public whitelist;
  mapping(address => uint) public claimed;
    uint256 private constant nftsPublicNumber = 2250;
    address private constant borpFanOne = 0xb0e7d87fCB3d146d55EB694f9851833f18a7dB11;
    address private constant borpFanTwo = 0xCd2732220292022cC8Ab82173D213f4F51F99f76;
    bool public whitelistSaleActive = false;
    bool public uriUnlocked = true;
    bool public supplyCapped = false;

  Counters.Counter private _tokenIdCounter;

  constructor() ERC721("Andy Borphol", "BORPS1") {
    _tokenIdCounter.increment();
  }
  function setBaseURI(string memory baseURIPrefix) public onlyOwner {
    require(uriUnlocked, "Not happening.");
    _baseURIPrefix = baseURIPrefix;
  }
  function _baseURI() internal view override returns(string memory) {
    return _baseURIPrefix;
  }

  function borpacassoBalance(address owner) public view virtual returns(uint256) {
        Borpacasso sd = Borpacasso(0x370108CF39555e561353B20ECF1eAae89bEb72ce);
    return sd.balanceOf(owner);
  }

  function lockURI() public onlyOwner {
    uriUnlocked = false;
  }
  function capSupply() public onlyOwner {
    supplyCapped = true;
  }
  function safeMint(address to) public onlyOwner {
    require(!supplyCapped, "The supply has been capped");
    _safeMint(to, _tokenIdCounter.current());
    _tokenIdCounter.increment();
  }
  function howManyBorp() public view returns(uint256 a){
    return Counters.current(_tokenIdCounter);
  }
  function allotmentOf(address _a) public view returns(uint a){
    return whitelist[_a];
  }
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal
      override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
      function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }
  function tokenURI(uint256 tokenId)
  public
  view
  override(ERC721, ERC721URIStorage)
  returns(string memory)
  {
    return super.tokenURI(tokenId);
  }
  function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(2);
    payable(borpFanOne).transfer(cut);
    payable(borpFanTwo).transfer(cut);
  }

  function addToWhitelist(address[] memory _address, uint32[] memory _amount)public onlyOwner {
    for (uint i = 0; i < _address.length; i++) {
      whitelist[_address[i]] = _amount[i];
    }
  }

  function removeFromWhitelist(address[] memory _address)public onlyOwner {
    for (uint i = 0; i < _address.length; i++) {
      whitelist[_address[i]] = 0;
    }
  }

  function flipWhitelistSale() public onlyOwner {
    whitelistSaleActive = !whitelistSaleActive;
  }

  function buyWhitelistBorp(uint tokensNumber) public payable {
    require(!supplyCapped, "The supply has been capped");
    require(whitelistSaleActive, "Maybe later");
    require(tokensNumber > 0, "U cant mint zero borps bro");
    require(tokensNumber <= whitelist[msg.sender], "You can't claim more than your allotment");
   require(claimed[msg.sender].add(tokensNumber) <= borpacassoBalance(msg.sender), "You're not holding enough borpacassos to claim the rest of your allotment");
    require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "Sry I dont have enough left for that ;(");

    for (uint i = 0; i < tokensNumber; i++) {
    require(whitelist[msg.sender] >= 1, "You don't have any more Borphols to claim");
    require(tokensNumber.sub(i) <= whitelist[msg.sender], "You can't claim more than your allotment");
    require(claimed[msg.sender] < borpacassoBalance(msg.sender), "You're not holding enough borpacassos to claim the rest of your allotment");
    require(_tokenIdCounter.current()<= nftsPublicNumber + 1, "Sry I dont have enough left ;(");
      claimed[msg.sender] += 1;
      whitelist[msg.sender] =whitelist[msg.sender].sub(1);
      _safeMint(msg.sender, _tokenIdCounter.current());
      _tokenIdCounter.increment();
    }

  }
}