// SPDX-License-Identifier: GPL-3.0
//
//        /m  MNmho-         sMMMMMMMMMM/   :MMN`    .MMM. `MMMN`    mMM+  dMMo     sMMy    NMMMMMMMM+ 
//     hNNMM  MM/odNm+`      oMMm+++++yMho  -MMN`    .MMM.  MMMMs`   dMM/  hMMo    +dMh:  :sMm+++++yMho
//  :NN  /MM  MM`  -hMd-     sMMh     /MMm  :MMN`    .MMM.  MMMMM:`  mMM/  dMMo  .-dmd+   oMMd     :ddd
//   NMNddMM  MM`    sMm`    sMMh     +MMm  :MMN`    .MMM. `MMMMMM/  mMM/  dMMo `NMM-     oMMd         
// dyo/    hMNMM`    `MM/    oMMNhhhhhmMo-  :MMN`    .MMM.  MMM+sMdy mMM/  hMMmhdMo:`     .:MNhhhhhhh: 
// hdyo    dMmMM`    .MM/    oMMNyyyyyyy-   :MMN`    .MMM.  MMM-:yNm/mMM/  hMMdyyMs/`       yyyyyyydMy/
//   NMmhhMM  MM`   `hMd`    sMMh           :MMN`    .MMM. `MMM:  dMMMMM/  dMMo `NNM:`     ```     /MMN
//  -Nm  +MM  MM` `/dMh.     sMMh           :MMN`    .MMM. `MMM:  `dMMMM/  dMMo  ..dNmo   +mmh     /MMN
//     hNmNM  MMoymNh/       oMMh           .+mNssssssMd+`  MMM-   /oNMM/  hMMo    /dMd/  -+MmssssshMy+
//        -h  mdhs/`         ommy             ymmmmmmmms    mmm-     hmm/  ymm+     omms    mmmmmmmmm/ 
//
// Created by @madeinusmate
// The DeFiChain Punks Reloaded
// by interacting with the smart contract you accept the terms & conditions: defichainpunks.madeinusmate.com/terms


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeFiChainPunksReloaded is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  uint256 public cost = 0.02 ether;
  bool public paused = true;

  constructor(
    string memory _initBaseURI
  ) ERC721("DeFiChain Punks Reloaded", "DEFICHAINPUNKSRELOADED") {
    setBaseURI(_initBaseURI);
    mint(msg.sender, 25);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(supply + _mintAmount <= 500);

    if (msg.sender != owner()) {
          require(!paused, "Sale is paused");
          require(msg.value >= cost * _mintAmount);
          require(_mintAmount <= 3, "Minting Limit is 3");
    }

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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}