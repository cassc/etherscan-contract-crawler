// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoFoxes is ERC721Enumerable, Ownable {

  uint public constant MAX_FOXES = 11111;
  string _baseTokenURI;
  mapping (uint => address) private _foxesV1Owners;
  uint[1001] private _foxesV1;
  bool paused = true;

  constructor(string memory baseTokenURI) ERC721("CryptoFoxes", "CFXS") {
    _baseTokenURI = baseTokenURI;
  }

  modifier saleIsOpen{
    require(totalSupply() < MAX_FOXES, "Sale end");
    _;
  }

  function isAuthClaim(address _to, uint _foxV1Id) public view returns(bool) {
    return _foxesV1Owners[_foxV1Id] == _to;
  }

  function authClaim(address _to, uint[] memory _foxesV1Id) public onlyOwner{
    for(uint i = 0; i < _foxesV1Id.length; i++){
      _foxesV1Owners[_foxesV1Id[i]] = _to;
    }
  }

  function claimTicket(address _to, uint[] memory _foxesV1Id) public saleIsOpen {
    require(!paused, "Pause");
    require(totalSupply() < MAX_FOXES, "Sale end");
    require(totalSupply() + _foxesV1Id.length <= MAX_FOXES - 1, "Max limit");

    for(uint i = 0; i < _foxesV1Id.length; i++){
      require(_foxesV1Owners[_foxesV1Id[i]] == _to, "Bad owner");

      _safeMint(_to, totalSupply());
      _foxesV1[_foxesV1Id[i]] = 1;
    }
  }

  function buyTicket(address _to, uint _count) public payable saleIsOpen {
    uint nb = 0;
    if(_msgSender() != owner()){
      require(!paused, "Pause");
      nb = 1;
    }
    require(totalSupply() + _count <= (MAX_FOXES - nb), "Max limit");
    require(totalSupply() < MAX_FOXES, "Sale end");
    require(_count <= 20, "Exceeds 20");
    require(msg.value >= price(_count), "Value below price");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function price(uint _count) public view returns (uint256) {

    uint _id = totalSupply();

    if(_msgSender() == owner()){
      if(_id <= 29 || _id == MAX_FOXES - 1){
          return 0;
      }
    }

    if (_id <= 299 ){
        return   20000000000000000 * _count; // 51-300 : 0.02 ETH
    } else if (_id <= 599 ){
        return   30000000000000000 * _count; // 301-600 : 0.03 ETH
    } else if (_id <= 1199 ){
        return   40000000000000000 * _count; // 601-1200 : 0.04 ETH
    } else if (_id <= 2399 ){
        return   60000000000000000 * _count; // 1201-2400 : 0.06 ETH
    } else if (_id <= 4799 ){
        return   80000000000000000 * _count; // 2401-4800 : 0.08 ETH
    } else if (_id <= 7199 ){
        return   100000000000000000 * _count; // 4801-7200 : 0.10 ETH
    } else if (_id <= 8999 ){
        return   150000000000000000 * _count; // 7201-9000 : 0.15 ETH
    } else if (_id <= 9999 ){
        return   200000000000000000 * _count; // 9001-10000 : 0.20 ETH
    } else if (_id <= 10899 ){
        return   400000000000000000 * _count; // 10001-10900 : 0.40 ETH
    } else if (_id <= 11109 ){
        return   600000000000000000 * _count; // 10901-11110 : 0.60 ETH
    }

    return 6000000000000000000; // 0.60 ETH cas impossible
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function foxesV1exist(uint foxId) public view returns (bool){
    return _foxesV1[foxId] > 0 ;
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {

    uint tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function pause(bool val) public onlyOwner {
    paused = val;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(_msgSender()).send(address(this).balance));
  }
}