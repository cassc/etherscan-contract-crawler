// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaperChasers is ERC721, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 2021;
  uint256 public maxMintAmount = 5;
  uint256 public maxPerAddress = 20;
  uint256 public maxPerWhitelist = 1;
  uint256 public totalSupply;
  bool public paused = false;
  bool public whitelistOn = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  address payable private dev = payable(0xB7ec69A5e0640f3b0445EBfcC9D1573d23B4737c);
  address payable private marketing = payable(0xE810AdaaFD0079252495a71930f58AF21388209f);
  address payable private community = payable(0x1ed56307238F5Ce968dD7f5dEd5F84627BfD2FDf);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "sale is not active");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(totalSupply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      uint256 ownerMintCount = addressMintedBalance[msg.sender];
      require(ownerMintCount + _mintAmount <= maxPerAddress, "max nft per address reached");
      if (!isWhitelisted(msg.sender)) {
        require(msg.value >= cost * _mintAmount, "insufficient funds");
      } else {
        if (whitelistOn) {
          require(ownerMintCount + _mintAmount <= maxPerWhitelist, "whitelist only allowed to mint 1");
        } else {
          require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, totalSupply + i);
      addressMintedBalance[msg.sender]++;
    }

    totalSupply += _mintAmount;

    if (totalSupply == maxSupply) {
      pause(true);
    }
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i <whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  //only owner
  function setMaxPerAddress(uint256 _limit) public onlyOwner {
    maxPerAddress = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setWhitelistOn(bool _state) public onlyOwner {
    whitelistOn = _state;
  }
 
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

    function accountBalance() public onlyOwner view returns(uint) {
      return address(this).balance;
  }

  function withdrawFunds() public onlyOwner {
    uint256 balance = accountBalance();
    require(balance > 0, "No funds to retrieve");

    _withdraw(community, (balance * 340)/1000);
    _withdraw(dev, (balance * 330)/1000);
    _withdraw(marketing, (balance * 330)/1000);
  }

  function _withdraw(address payable account, uint256 amount) internal {
    (bool sent, ) = account.call{value: amount}("");
    require(sent, "Failed to withdraw Ether");
  }

  function withdrawToOwner() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}