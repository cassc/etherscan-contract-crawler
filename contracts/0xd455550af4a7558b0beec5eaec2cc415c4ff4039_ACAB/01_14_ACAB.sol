// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// 💦

contract ACAB is ERC721Enumerable, ReentrancyGuard, Ownable {
  string baseTokenURI;
  bool public tokenURIFrozen = false;
  address public payoutAddress = 0x955B6F06981d77f947F4d44CA4297D2e26a916d7;
  uint256 public totalTokens = 333;

  uint256 public startPresaleDate = 1632931200;
  uint256 public startMintDate = 1632952800;
  uint256 public mintPrice = 0.1312 ether;
  mapping(address => bool) private presaleList;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _totalTokens,
    uint256 _startPresaleDate,
    uint256 _startMintDate,
    address _payoutAddress
  ) ERC721(name, symbol) {
    baseTokenURI = 'ipfs://QmfM2Gvu5UPoci9PZSoS2fujAZB52QvVSFT4kdBYA9JVm3/';
    totalTokens = _totalTokens;
    startPresaleDate = _startPresaleDate;
    startMintDate = _startMintDate;
    payoutAddress = _payoutAddress;
    for (uint256 i = 0; i < 36; i++) {
      _safeMint(payoutAddress, nextTokenId());
    }
  }

  function nextTokenId() internal view returns (uint256) {
    return totalSupply() + 1;
  }

  function addToAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "ERR:0");
      presaleList[addresses[i]] = true;
    }
  }

  function withdraw() external onlyOwner {
    payable(payoutAddress).transfer(address(this).balance);
  }

  function mint() external payable nonReentrant {
    require(startMintDate <= block.timestamp, "ERR:1");
    require(msg.value >= mintPrice, "ERR:2");
    require(totalSupply() < totalTokens, "ERR:3");
    require(balanceOf(_msgSender()) == 0, "ERR:7");
    _safeMint(_msgSender(), nextTokenId());
  }

  function mintPresale() external payable nonReentrant {
    require(startPresaleDate <= block.timestamp, "ERR:5");
    require(msg.value >= mintPrice, 'ERR:2');
    require(totalSupply() < totalTokens, "ERR:3");
    require(presaleList[_msgSender()] == true, "ERR:4");
    require(balanceOf(_msgSender()) == 0, "ERR:7");
    presaleList[_msgSender()] = false;
    _safeMint(_msgSender(), nextTokenId());
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function freezeBaseURI() public onlyOwner {
    tokenURIFrozen = true;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    require(tokenURIFrozen == false, 'ERR:6');
    baseTokenURI = baseURI;
  }

  function setPayoutAddress(address _payoutAddress) public onlyOwner {
    payoutAddress = _payoutAddress;
  }

  function setStartPresaleDate(uint256 _startPresaleDate) public onlyOwner {
    startPresaleDate = _startPresaleDate;
  }

  function setStartMintDate(uint256 _startMintDate) public onlyOwner {
    startMintDate = _startMintDate;
  }

  /**
   * ERRORS
   * ERR:0 - Can't mint to the null address
   * ERR:1 - Sale hasn't started yet
   * ERR:2 - More eth required
   * ERR:3 - Sold Out!
   * ERR:4 - Not on presale list
   * ERR:5 - Presale hasn't started
   * ERR:6 - Token URIs are frozen
   * ERR:7 - Only 1 per wallet allowed
   *
   * [email protected]
   **/
}