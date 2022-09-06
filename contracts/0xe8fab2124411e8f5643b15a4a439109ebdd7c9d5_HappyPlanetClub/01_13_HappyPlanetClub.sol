// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Presalable.sol";

contract HappyPlanetClub is ERC721AQueryable, Ownable, Pausable, Presalable, ReentrancyGuard {
  using SafeMath for uint;
  using ECDSA for bytes32;

  string public baseTokenURI;

  uint256 public price = 0.009 ether;
  uint256 public presalePrice = 0.006 ether;
  uint256 public maxTotalSupply = 3000;

  mapping(address => uint256) public tokenOwnersCounter;

  address t1 = 0x402351069CFF2F0324A147eC0a138a1C21491591;
  address t2 = 0xe6Fa2a32A99ad27Cd21A9E740405DBA7e0C6e3f3;

  constructor(string memory _baseTokenURI) ERC721A("Happy Planet Club", "HPC")  {
    setBaseURI(_baseTokenURI);
    presale();
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function totalBurned() public view returns (uint256) {
    return _totalBurned();
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function mint(uint256 _amount, bytes memory _signature) public payable whenAllowedPublic whenNotPaused {
    address signer = _recoverSigner(msg.sender, _signature);
    
    require(signer == owner(), "Not authorized to mint");
    require(tokenOwnersCounter[msg.sender] + _amount <= 3, "Can only mint 3 tokens at address");
    require(_totalMinted() + _amount <= maxTotalSupply, "Exceeds maximum supply");

    (, uint256 _nonFreeAmount) = tokenOwnersCounter[msg.sender] == 2 
                                 ? (true, 1) : (tokenOwnersCounter[msg.sender] + _amount).trySub(1);

    require(_nonFreeAmount == 0 || msg.value >= price * _nonFreeAmount, "Ether value sent is not correct");

    _safeMint(msg.sender, _amount);

    tokenOwnersCounter[msg.sender] += _amount;
  }

  function presaleMint(uint256 _amount, bytes memory _signature) public payable whenPresaled whenNotPaused {        
    address signer = _recoverSigner(msg.sender, _signature);

    require(signer == owner(), "Not authorized to mint");
    require(tokenOwnersCounter[msg.sender] + _amount <= 4, "Can only mint 4 tokens at address");
    require(_totalMinted() + _amount <= maxTotalSupply, "Exceeds maximum supply");

    (, uint256 _nonFreeAmount) = tokenOwnersCounter[msg.sender] == 3 
                                 ? (true, 1) : (tokenOwnersCounter[msg.sender] + _amount).trySub(2);

    require(_nonFreeAmount == 0 || msg.value >= presalePrice * _nonFreeAmount, "Ether value sent is not correct");

    _safeMint(msg.sender, _amount);

    tokenOwnersCounter[msg.sender] += _amount;
  }

  function airdrop(address _owner, uint256 _amount) public onlyOwner {
    require(_totalMinted() + _amount <= maxTotalSupply, "Exceeds maximum supply");

    _safeMint(_owner, _amount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setPrice(uint256 _newPrice) public onlyOwner{
    price = _newPrice;
  }

  function setPresalePrice(uint256 _newPrice) public onlyOwner{
    presalePrice = _newPrice;
  }

  function setMaxTotalSupply(uint256 _count) public onlyOwner{
    maxTotalSupply = _count;
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance / 100;

    require(payable(t1).send(_balance * 12));
    require(payable(t2).send(_balance * 88));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function presale() public onlyOwner {
    _presale();
  }

  function unpresale() public onlyOwner {
    _unpresale();
  }

  function allowPublic() public onlyOwner {
    _allowPublic();
  }

  function disallowPublic() public onlyOwner {
    _disallowPublic();
  }

  function _recoverSigner(address _wallet, bytes memory _signature) private pure returns (address){
    return keccak256(abi.encodePacked(_wallet)).toEthSignedMessageHash().recover(_signature);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}