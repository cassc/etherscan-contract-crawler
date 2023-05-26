//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Collection9022 is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _counter;

  mapping(address => uint) private whitelist;
  mapping(address => uint) private amountMinted;
  uint public MAX_SUPPLY = 2209;
  uint256 public price = 1400 ether;
  bool public saleIsActive = false;
  uint public constant maxPassTxn = 10;
  string public baseURI;
  address private manager;
  IERC20 private iAI;

  constructor(address _tokenAddress) ERC721('9022 Collection', '9022') Ownable() {
    iAI = IERC20(_tokenAddress);
  }

  modifier onlyOwnerOrManager() {
    require(owner() == _msgSender() || manager == _msgSender(), 'Caller is not the owner or manager');
    _;
  }

  function setManager(address _manager) external onlyOwner {
    manager = _manager;
  }

  function getManager() external view onlyOwnerOrManager returns (address) {
    return manager;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwnerOrManager {
    baseURI = newBaseURI;
  }

  function setMaxSupply(uint _maxSupply) external onlyOwnerOrManager {
    MAX_SUPPLY = _maxSupply;
  }

  function setPrice(uint256 _price) external onlyOwnerOrManager {
    price = _price;
  }

  function checkWhitelist(address _address) external view returns (uint) {
    return whitelist[_address];
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function totalToken() public view returns (uint256) {
    return _counter.current();
  }

  function flipSale() public onlyOwnerOrManager {
    saleIsActive = !saleIsActive;
  }

  function getAmountMinted(address _address) external view returns (uint) {
    return amountMinted[_address];
  }

  function addToWhitelist(address[] calldata _addresses, uint[] calldata _amounts) external onlyOwnerOrManager {
    require(_addresses.length == _amounts.length, 'Address and amounts not equals');
    for (uint i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = _amounts[i];
    }
  }

  function withdrawAll(address _address) public onlyOwnerOrManager {
    uint256 balance = address(this).balance;
    require(balance > 0, 'Balance is zero');
    (bool success, ) = _address.call{value: balance}('');
    require(success, 'Transfer failed.');
  }

  function widthdrawiAI(address _address, uint256 _amount) public onlyOwnerOrManager {
    iAI.transfer(_address, _amount);
  }

  function reserveMintNFT(uint256 reserveAmount, address mintAddress) external onlyOwnerOrManager {
    require(totalSupply() + reserveAmount <= MAX_SUPPLY, '9022 Collection Sold Out');
    for (uint256 i = 0; i < reserveAmount; i++) {
      _safeMint(mintAddress, _counter.current() + 1);
      _counter.increment();
    }
  }

  function whitelistMintNFT(uint32 numberOfTokens) external {
    require(saleIsActive, 'Sale is not active.');
    require(whitelist[msg.sender] != 0, 'Not authorized for whitelist');
    require(numberOfTokens >= 1, 'You must at least mint 1 Token');
    require(numberOfTokens <= whitelist[msg.sender], 'Exceeds whitelist limit');
    require(totalSupply() + numberOfTokens <= MAX_SUPPLY, '9022 Collection Sold Out');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = _counter.current() + 1;
      if (mintIndex <= MAX_SUPPLY) {
        _safeMint(msg.sender, mintIndex);
        _counter.increment();
      }
    }
    whitelist[msg.sender] -= numberOfTokens;
  }

  function mintNFT(uint32 numberOfTokens) external payable {
    require(saleIsActive, 'Sale is not active.');
    require(numberOfTokens >= 1, 'You must at least mint 1 Token');
    require(amountMinted[msg.sender] + numberOfTokens <= maxPassTxn, 'Exceeds max amount per wallet');
    require(totalSupply() + numberOfTokens <= MAX_SUPPLY, '9022 Collection Sold Out');

    iAI.transferFrom(msg.sender, address(this), price * numberOfTokens);

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = _counter.current() + 1;
      if (mintIndex <= MAX_SUPPLY) {
        _safeMint(msg.sender, mintIndex);
        _counter.increment();
        amountMinted[msg.sender] += 1;
      }
    }
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}