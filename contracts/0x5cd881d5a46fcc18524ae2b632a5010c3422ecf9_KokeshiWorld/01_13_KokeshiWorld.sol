// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////
//    _  __     U  ___ u    _  __    U _____ u   ____       _   _                 //
//   |"|/ /      \/"_ \/   |"|/ /    \| ___"|/  / __"| u   |'| |'|       ___      //
//   | ' /       | | | |   | ' /      |  _|"   <\___ \/   /| |_| |\     |_"_|     //
// U/| . \\u .-,_| |_| | U/| . \\u    | |___    u___) |   U|  _  |u      | |      //
//   |_|\_\   \_)-\___/    |_|\_\     |_____|   |____/>>   |_| |_|     U/| |\u    //
// ,-,>> \\,-.     \\    ,-,>> \\,-.  <<   >>    )(  (__)  //   \\  .-,_|___|_,-. //
//  \.)   (_/     (__)    \.)   (_/  (__) (__)  (__)      (_") ("_)  \_)-' '-(_/  //
//                         U  ___ u    ____        _        ____                  //
//         __        __     \/"_ \/ U |  _"\ u    |"|      |  _"\                 //
//         \"\      /"/     | | | |  \| |_) |/  U | | u   /| | | |                //
//         /\ \ /\ / /\ .-,_| |_| |   |  _ <     \| |/__  U| |_| |\               //
//        U  \ V  V /  U \_)-\___/    |_| \_\     |_____|  |____/ u               //
//        .-,_\ /\ /_,-.      \\      //   \\_    //  \\    |||_                  //
//         \_)-'  '-(_/      (__)    (__)  (__)  (_")("_)  (__)_)                 //
////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KokeshiWorld is ERC721Enumerable, Ownable {
  uint public constant MAX_KOKESHI = 10001;
  uint _reserved = 400;
  string _baseTokenURI = "https://api.kokeshi.world/meta/";
  bool public isActive = false;

  constructor(address _to, uint _count) ERC721("Kokeshi World", "KOKESHI")  {
    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function mintKokeshi(address _to, uint _count) public payable {
    require(isActive, "Paused");
    require(_count <= 20, "Exceeds 20");
    require(totalSupply() < MAX_KOKESHI, "Sale end");
    require(totalSupply() + _count <= MAX_KOKESHI, "Max limit");
    require(msg.value >= price(_count), "Value below price");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function reserveKokeshi(address _to, uint _count) public onlyOwner{
    require(totalSupply() < MAX_KOKESHI, "Sale end");
    require(totalSupply() + _count <= MAX_KOKESHI, "Max limit");
    require(_reserved != 0, "Max limit reserved");
    require(_reserved >= _count, "Max limit reserved");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }

    _reserved = _reserved - _count;
  }

  function price(uint _count) public pure returns (uint256) {
    return _count * 80000000000000000;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensIds;
  }

  function toggleActiveState() public onlyOwner {
    isActive = !isActive;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}