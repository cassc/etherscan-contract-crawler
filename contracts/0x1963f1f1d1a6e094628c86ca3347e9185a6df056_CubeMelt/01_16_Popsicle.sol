//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%%                          ......................... %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%                     ..................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%                   ....................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%            / /........................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%          ../ /........................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%     /....../ /........................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@% ...//.................................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@% ...//.................................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%..../ ,.//.............................................%@@@@@%%%@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@%..../    //....%%%......,......%.....#%%...............(@@@@@%%@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@,.../   / /..............%%%%%.........................*@@@@@%@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%....///......%,........................................%%%%%@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%............%%%.............................../  ......%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%.....%......%%................................/  ......%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%......%%%%%,................................../ ..../..%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%..............................................* /*////.%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%...............................................///////.%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@%............................................//////////.%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@,........... ............................//////////*..,%@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@%(/////////  /////////((##%%%%%%%%%%%%%%%%%%%%%//////%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@%(/////  /////////%(///////%///////////////(%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@////........../...%%........%%.........///..../@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@/////////////@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@*.........%@@@@@@@@@@%...,@@@@@@@@@@@@@@@@@@@@%[email protected]@@%.......%@@@@@@@@@@%...%@@%...%@@@@@@@@@@@@
//@....%@%...% [email protected]@%...%...,@@@@@@@@@@........./%[email protected]#........%%.........%...%[email protected]@@@@@@@@
//@....&@@@@@%[email protected]@%...%............%%...#@@@...%............%,...%[email protected]@@%..%...%@@%...%@@@@@@@@@@@@
//@[email protected]@@@@@%[email protected]@%...%...*@@@@@%...%..........%...%/......&@....%..........%...%@@%...%@@@@@@@@@@@@
//%[email protected]@@@@@%[email protected]@%...%...,@@@@@%...%...%%%%%%@%...%%[email protected]@@....%....%%%%%@%...%@@%...#@@@@@@@@@@@@
//%[email protected]@@%%%@[email protected]@%...%...,@@@@@%...%...%@@@//%%...%@%*[email protected]@@@....%[email protected]@@#/(%...%@@%...#,[email protected]@@@@@@@@
//%..........%/.........%............*%.........#%...%@@@@@@@@@....%..........%...%@@%[email protected]@@@@@@@@
//@%%%%%%%%%%@%%%%%%%%%@%...%%%%%%%%@@%%%%%%%%%%@%%%%@@@@@@@@@@%%%%@%%%%%%%%%@%%%%@@@@%%%%%%@@@@@@@@@@

pragma solidity ^0.8.4;

interface IIP {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
    function mint(address _to, uint256 _mintAmount) external;
    function getAvailability() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//Standard NFT
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Proof of Signature
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//Royalty
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CubeMelt is ERC721, ERC721Holder, Ownable, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;
  IIP public ipContract;
  
  uint256 public constant MAXSUPPLY = 8888;
  uint256 public constant ALCOSTM1 = 0.05 ether;
  uint256 public constant ALCOSTM2 = 0.04 ether;
  uint256 public constant ALCOSTM3 = 0.033 ether;
  uint256 public constant COSTM1 = 0.08 ether;
  uint256 public constant COSTM2 = 0.065 ether;
  uint256 public constant COSTM3 = 0.05 ether;
  uint256 public constant RESERVED = 792;
  uint256 public constant LEGENDARYRESERVED = 15;
  uint256 public constant MAXMINTAMOUNT = 3;

  Counters.Counter private supply;
  uint256 public firstIndex = 1;
  uint256 public lastIndex = MAXSUPPLY;

  address private t1 = 0x2283BF4705A9D4E850a4C8dEF2aAe9Ac98F4c495;
  string private _contractURI = "https://cubemelt.mypinata.cloud/ipfs/QmTBVBxseHCDq7186xWqixE5m3pJKbKXCfqc1qsCXB5jfn";

  string public baseURI = "https://cubemelt.mypinata.cloud/ipfs/QmRot4WiYmkJpfxzKm8NbADxNTmDvhH33pYvhdH7vkHh3A";
  bool public reveal = false;
  bool public paused = false;

  enum MintStatus {
    CLOSED,
    AL,
    PUBLIC
  }
  MintStatus public mintStatus = MintStatus.CLOSED;

  //Allowlist
  bytes32 public alMerkleRoot = 0x8f62519c00abe7499eeafaf92c56836beb2ef37ced9dbd029db4018d538dedb1;
  mapping(address => bool) public alClaimed;

  constructor(address _nftContractAddress) ERC721("CubeMelt", "CM") {
    //Contract interprets 10,000 as 100%.
    setDefaultRoyalty(t1, 500); //5%
    ipContract = IIP(_nftContractAddress);
   }

//*** INTERNAL FUNCTION ***//
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, firstIndex);
      firstIndex++;
    }
  }

  function _reverseMintLoop(address _receiver, uint256 _mintAmount) internal {
    for(uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, lastIndex);
      lastIndex--;
    }
  }

//*** PUBLIC FUNCTION ***//
  function alSaleMintWithIP(bytes32[] calldata _merkleProof) public payable {
    uint256 _mintAmount = 3;
    require(!paused);
    require(mintStatus == MintStatus.AL, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");
    require(ipContract.getAvailability(), "Out of IP supply");

    require(!alClaimed[msg.sender], "Address has already claimed.");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, alMerkleRoot, leaf), "Invalid proof.");
    
    alClaimed[msg.sender] = true;
      
    require(msg.value >= ALCOSTM3 * _mintAmount, "Insufficient Eth.");

    ipContract.mint(msg.sender, 1);
    _mintLoop(msg.sender, _mintAmount);
  }

  function alSaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(!paused);
    require(mintStatus == MintStatus.AL, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    require(!alClaimed[msg.sender], "Address has already claimed.");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, alMerkleRoot, leaf), "Invalid proof.");
    
    alClaimed[msg.sender] = true;

    if(_mintAmount == 1)
      require(msg.value >= ALCOSTM1 * _mintAmount, "Insufficient Eth.");
    else if(_mintAmount == 2)
      require(msg.value >= ALCOSTM2 * _mintAmount, "Insufficient Eth.");
    else if(_mintAmount == 3)
      require(msg.value >= ALCOSTM3 * _mintAmount, "Insufficient Eth.");

    _mintLoop(msg.sender, _mintAmount);
  }

  function publicSaleMintWithIP() public payable {
    uint256 _mintAmount = 3;
    require(!paused);
    require(mintStatus == MintStatus.PUBLIC, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");
    require(ipContract.getAvailability(), "Out of IP supply");

    require(msg.value >= COSTM3 * _mintAmount, "Insufficient Eth.");

    ipContract.mint(msg.sender, 1);
    _mintLoop(msg.sender, _mintAmount);
  }

  function publicSaleMint(uint256 _mintAmount) public payable {
    require(!paused);
    require(mintStatus == MintStatus.PUBLIC, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    if(_mintAmount == 1)
      require(msg.value >= COSTM1 * _mintAmount, "Insufficient Eth.");
    else if(_mintAmount == 2)
      require(msg.value >= COSTM2 * _mintAmount, "Insufficient Eth.");
    else if(_mintAmount == 3)
      require(msg.value >= COSTM3 * _mintAmount, "Insufficient Eth.");

    _mintLoop(msg.sender, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXSUPPLY) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

    if(reveal)
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
    else
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
  }

  // Returns the URI for the contract-level metadata of the contract.
  function contractURI() public view returns (string memory) {
      return _contractURI;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function getAvailability() public view returns (bool) {
    if(supply.current() < MAXSUPPLY)
      return true;

    return false;
  }

//*** ONLY OWNER FUNCTION **** //
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setReveal(bool _reveal) public onlyOwner {
    reveal = _reveal;
  }

  function setMintStatus(uint256 status) public onlyOwner {
    require(status <= uint256(MintStatus.PUBLIC), "CP: Out of bounds.");

    mintStatus = MintStatus(status);
  }

  function setALMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    alMerkleRoot = _merkleRoot;
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    require(!paused);
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function airDropService(address[] calldata _airDropAddresses) public onlyOwner {
    require(!paused);
    require(supply.current() + _airDropAddresses.length <= MAXSUPPLY, "Out of supply.");

    for (uint256 i = 0; i < _airDropAddresses.length; i++) {
      supply.increment();
      _safeMint(_airDropAddresses[i], lastIndex);
      lastIndex--;
    }
  }

  function mintUnsettledSupply() public onlyOwner {
    require(!paused);

    uint256 _mintAmount = MAXSUPPLY - supply.current();
    require(_mintAmount > 0, "Invalid mint amount.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function mintUnsettledReserved() public onlyOwner {
    require(!paused);

    uint256 _mintAmount = lastIndex - (MAXSUPPLY - RESERVED);
    require(_mintAmount > 0, "Invalid mint amount.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _reverseMintLoop(t1, _mintAmount);
  }

  function mintInitialLegendary() public onlyOwner {
    require(!paused);

    uint256 _mintAmount = LEGENDARYRESERVED;
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(t1).call{value: address(this).balance}("");
    require(os);
  }

  function setIPContract(address _contractAddress) public onlyOwner {
      ipContract = IIP(_contractAddress);
  }

  // Sets contract URI for the contract-level metadata of the contract.
  function setContractURI(string calldata _URI) public onlyOwner {
      _contractURI = _URI;
  }

  function setDefaultRoyalty(address _receiver, uint96 _royaltyPercent) public onlyOwner {
      _setDefaultRoyalty(_receiver, _royaltyPercent);
  }

//REQUIRED OVERRIDE FOR ERC721 & ERC2981
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}