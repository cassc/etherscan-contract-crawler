// SPDX-License-Identifier: MIT
/*

      ___           ___           ___           ___                     ___           ___           ___           ___     
     /  /\         /  /\         /  /\         /  /\      ___          /  /\         /  /\         /  /\         /  /\    
    /  /::\       /  /::|       /  /::\       /  /:/     /  /\        /  /::\       /  /::\       /  /::|       /  /::\   
   /__/:/\:\     /  /:|:|      /  /:/\:\     /  /:/     /  /::\      /  /:/\:\     /  /:/\:\     /  /:|:|      /__/:/\:\  
  _\_ \:\ \:\   /  /:/|:|__   /  /:/  \:\   /  /:/     /  /:/\:\    /  /::\ \:\   /  /::\ \:\   /  /:/|:|__   _\_ \:\ \:\ 
 /__/\ \:\ \:\ /__/:/_|::::\ /__/:/ \__\:\ /__/:/     /  /::\ \:\  /__/:/\:\_\:\ /__/:/\:\ \:\ /__/:/ |:| /\ /__/\ \:\ \:\
 \  \:\ \:\_\/ \__\/  /~~/:/ \  \:\ /  /:/ \  \:\    /__/:/\:\ \:\ \__\/~|::\/:/ \  \:\ \:\_\/ \__\/  |:|/:/ \  \:\ \:\_\/
  \  \:\_\:\         /  /:/   \  \:\  /:/   \  \:\   \__\/  \:\_\/    |  |:|::/   \  \:\ \:\       |  |:/:/   \  \:\_\:\  
   \  \:\/:/        /  /:/     \  \:\/:/     \  \:\       \  \:\      |  |:|\/     \  \:\_\/       |__|::/     \  \:\/:/  
    \  \::/        /__/:/       \  \::/       \  \:\       \__\/      |__|:|~       \  \:\         /__/:/       \  \::/   
     \__\/         \__\/         \__\/         \__\/                   \__\|         \__\/         \__\/         \__\/  M.H. 

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmolFrens is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public PROVENANCE;
  string private baseURI;
  uint256 public constant MAX_FRENS = 3500;
  uint256 public constant MAX_FREN_HED_SIZE = 3;
  uint256 public constant MAX_FAST_FINISHERS = 1000;
  bool public IS_PUBLIC = false;

  struct Smokable {
    string smokeType;
    uint256 strength;
    bool enabled;
    uint256 prevHolder;
  }
  
  mapping(address => uint256) private whiteList;
  mapping(uint256 => uint256) private frenHedSize;
  mapping(uint256 => Smokable) private smokables;
  mapping(uint256 => bool) public fastFinishers;
  uint256[] private fastFinishersArr;

  event NewSmolFren(address toAddress, uint256 tokenId);
  event NewSmolFrens(address toAddress, uint256 firstTokenId, uint256 lastTokenId);
  event SeshEvent(uint256 fromId, uint256 toId, string smokeType, uint256 timestamp);

  constructor() ERC721("SmolFrens", "SMOLFRENS") {
  }

  /* MODIFIERS */
  modifier hasAvailableFrens() {
    require(msg.sender == owner() || whiteList[msg.sender] > 0, 'No frens available fren');
    _;
  }

  /* REQUIRED OVERRIDES */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /* OWNER FUNCTIONS */
  function setProvenance(string calldata provenance) external onlyOwner {
    require(bytes(PROVENANCE).length == 0, 'Provenance is already set fren');
    PROVENANCE = provenance;
  }

  function setIsPublicMint(bool newVar) external onlyOwner {
    IS_PUBLIC = newVar;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /* WHITE LIST */
  function addFrensToWhiteList(address walletAddress, uint256 numTokens) external onlyOwner {
    uint256 ts = totalSupply();
    require(ts + numTokens <= MAX_FRENS, "Not enough available frens");
    whiteList[walletAddress] = whiteList[walletAddress] + numTokens;
  }

  function frensAvailableToMint(address walletAddress) external view returns (uint256) {
    return whiteList[walletAddress];
  }

  /* MINTING */
  function mintSmolFren() public payable hasAvailableFrens {
    uint256 ts = totalSupply();
    require(ts < MAX_FRENS, "All Frens Minted Fren");

    _safeMint(msg.sender, ts);

    if (msg.sender != owner()) {
      whiteList[msg.sender] -= 1;
    }
    
    frenHedSize[ts] = 0;
    emit NewSmolFren(msg.sender, ts);
  }

  function mintAllFrens() public payable hasAvailableFrens {
    uint256 ts = totalSupply();
    uint256 numFrens = whiteList[msg.sender];
    require(ts + numFrens <= MAX_FRENS, "Not enough available frens");
    
    for (uint256 i = 0; i < numFrens; i++) {
      _safeMint(msg.sender, ts + i);
      frenHedSize[ts + i] = 0;
    }

    if (msg.sender != owner()) {
      whiteList[msg.sender] = 0;
    }
    
    emit NewSmolFrens(msg.sender, ts, ts + numFrens - 1);
  }

  function publicMint() public payable {
    require(IS_PUBLIC, "Not available yet fren");
    uint256 ts = totalSupply();
    require(ts < MAX_FRENS, "All Frens Minted Fren");
    _safeMint(msg.sender, ts);
    frenHedSize[ts] = 0;
    emit NewSmolFren(msg.sender, ts);
  }

  /* HEAD SHIT */
  function getHeadSize(uint256 tokenId) external view returns (uint256) {
    return frenHedSize[tokenId];
  }

  function increaseHeadSize(uint256 tokenId) private {
    uint256 currentHeadSize = frenHedSize[tokenId];
    require(currentHeadSize + 1 <= MAX_FREN_HED_SIZE, "Head Already Maxxed Fren");
    frenHedSize[tokenId] += 1;
  }

  function changeHeadSize(uint256 tokenId, uint256 newHeadSize) private {
    require(newHeadSize <= MAX_FREN_HED_SIZE, "Too big fren");
    frenHedSize[tokenId] = newHeadSize;
    if (newHeadSize >= MAX_FREN_HED_SIZE && fastFinishersArr.length < MAX_FAST_FINISHERS) {
      fastFinishers[tokenId] = true;
      fastFinishersArr.push(tokenId);
    }
  }

  /* SMOKABLE SESH SHIT */
  function addSmokable(uint256 tokenId, string calldata smokeType, uint256 strength) external onlyOwner {
    smokables[tokenId] = Smokable(smokeType, strength, true, 100000);
  }

  function addSmokableData(uint256[] calldata tokenIds, string[] calldata smokeTypes, uint256[] calldata strengths) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      smokables[tokenIds[i]] = Smokable(smokeTypes[i], strengths[i], true, 100000);
    }
  }

  function getSmokable(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "That fren doesn't exist fren");
    string memory output;
    if (smokables[tokenId].enabled) {
      output = string(abi.encodePacked("{type: ", smokables[tokenId].smokeType, ", strength: ", smokables[tokenId].strength.toString(), ", prevHolder: ", smokables[tokenId].prevHolder.toString(), "}"));
    } else {
      output = "No current Smokable";
    }
    return output;
  }

  function timeToSesh(uint256 holder, uint256 toTokenId) external {
    require(_exists(holder), "Whut");
    require(_exists(toTokenId), "That fren doesn't exist fren");
    require(msg.sender == ownerOf(holder), "Not yours, fren");
    require(smokables[holder].enabled, "You got nothin, fren");
    require(!smokables[toTokenId].enabled, "Fren already has a smokable");
    require(ownerOf(holder) != ownerOf(toTokenId), "Puff puff give, fren");
    require(frenHedSize[toTokenId] < MAX_FREN_HED_SIZE, "That fren already has the biggest head fren");
    require(smokables[holder].prevHolder != toTokenId, "Share the love, fren");

    uint256 toHeadSize = Math.min(frenHedSize[holder] + smokables[holder].strength, MAX_FREN_HED_SIZE);
    changeHeadSize(holder, toHeadSize);
    smokables[holder].enabled = false;
    smokables[toTokenId] = Smokable(smokables[holder].smokeType, smokables[holder].strength, true, holder);

    emit SeshEvent(holder, toTokenId, smokables[holder].smokeType, block.timestamp);
  }

  /* FAST FINISHERS */
  function isFastFinisher(uint256 tokenId) public view returns (bool) {
    return fastFinishers[tokenId] == true;
  }

  /* DYNAMIC TOKEN URI OVERRIDE */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "That fren doesn't exist fren");
    uint256 currentHeadSize = frenHedSize[tokenId];
    string memory smokable;
    if (smokables[tokenId].enabled) { smokable = string(abi.encodePacked("-", smokables[tokenId].smokeType)); }
    string memory fastFinisherPath;
    fastFinisherPath = isFastFinisher(tokenId) ? "-Crown" : "";
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "/", currentHeadSize.toString(), smokable, fastFinisherPath)) : "";
  }
}