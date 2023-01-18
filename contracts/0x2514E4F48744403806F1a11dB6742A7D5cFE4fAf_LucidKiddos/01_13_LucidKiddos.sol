// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 < 0.9.0;



import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract LucidKiddos is Ownable, Pausable, ERC721A, ERC2981, ReentrancyGuard {
  using SafeMath for uint256;
  using Strings for uint256;

  uint public maxPerMint = 30;
  uint256 public  price = 0.023 ether;
  string private _baseTokenURI;
  uint256 public collectionSize = 4444;

  constructor() ERC721A("Lucid Kiddos", "LCDK") {
    _setDefaultRoyalty(msg.sender, 1000);
    _pause();
  }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


  function _startTokenId() internal view virtual override returns(uint256) {
    return 1;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }


  function mint(uint64 _quantity) external payable whenNotPaused nonReentrant callerIsUser {
    require(_quantity > 0, 'Quantity must be set greater than 0');
    require(totalSupply() + _quantity <= collectionSize, 'Exceeded maximum collection size');
    require(_quantity <= maxPerMint, 'Exceeded maximum ammount per mint');
    require(msg.value >= (_quantity * price), 'Not enough to buy nft');
    _mint(msg.sender, _quantity);

    //set royalty for each token
    for (uint64 i = 1; i <= _quantity; i++) {
      uint256 tokenID = (totalSupply() + 1) - i;
      _setTokenRoyalty(tokenID, msg.sender, 1000);
    }
  }


  function setPricing(uint256 _pricing) external nonReentrant onlyOwner returns(uint256) {
    price = _pricing;
    return price;
  }


  function devMint(uint64 _quantity) external nonReentrant callerIsUser onlyOwner {
    require(_quantity > 0, 'Quantity must be set greater than 0');
    require(totalSupply() + _quantity <= collectionSize, 'Exceeded maximum collection size');
    _mint(msg.sender, _quantity);
    
  }

  function pause() public onlyOwner nonReentrant {
    _pause();
  }

  function unpause() public onlyOwner nonReentrant {
    _unpause();
  }

//transferFrom update royatlties
  function transferFrom(address from, address to, uint256 tokenId) public payable override {
    _setTokenRoyalty(tokenId, to, 1000);
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
    _setTokenRoyalty(tokenId, to, 1000);
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override {
    _setTokenRoyalty(tokenId, to, 1000);
    super.safeTransferFrom(from, to, tokenId, _data);
  }

//set burn token royalties
  function burn(uint256 tokenId) public  onlyOwner {
    _resetTokenRoyalty(tokenId);
    super._burn(tokenId);
  }



  function setMaxPerMint(uint _maxPerMint) external onlyOwner {
    maxPerMint = _maxPerMint;
  }

  function setCollectionSize(uint _collectionSize) external onlyOwner {
    collectionSize = _collectionSize;
  }


  function withdrawAll(address _wallet) external  nonReentrant onlyOwner{
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance to withdraw");
    payable(_wallet).transfer(balance);
  }


  function _baseURI() internal view virtual override returns(string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }
}