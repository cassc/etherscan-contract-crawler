// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IWRLD_Token_Ethereum {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
}

contract WRLDMind_AllTerrain is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 100 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmount = 5;
  address public payoutWallet = 0x7CB4F0d468806ABa9c9506e47fEb46b5CeFe4108;

  bool public paused = true;
  IWRLD_Token_Ethereum public wrld;

  constructor() ERC721("WRLDMind - All Terrain", "WM") {
    setBaseURI("");
    wrld = IWRLD_Token_Ethereum(0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(!paused, "Minting is paused");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value == 0, "Minting is done via WRLD");
    require(cost * _mintAmount <= wrld.balanceOf(msg.sender), "Not enough WRLD");
    require(cost * _mintAmount <= wrld.allowance(msg.sender, address(this)), "Not enough WRLD allowance");

    wrld.transferFrom(msg.sender, address(this), cost * _mintAmount);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setPayoutWallet(address _wallet) public onlyOwner() {
    payoutWallet = _wallet;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
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

  function initialize() public onlyOwner {
    wrld.approve(address(this), 4500000000000000000000000);
  }

  function withdrawMoney() public onlyOwner nonReentrant {
    payable(payoutWallet).transfer(address(this).balance);
    wrld.transferFrom(address(this), payoutWallet, wrld.balanceOf(address(this)));
 }
}