//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface FreeMintProjectsInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MetaId is ERC721, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string public metadataFolderURI;
  mapping(address => uint256) public minted;
  bool public mintActive;
  uint256 public mintsPerAddress;
  string public openseaContractMetadataURL;
  address[] public freeMintProjects;

  uint256 public price = 0.02 ether;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _metadataFolderURI,
    uint256 _mintsPerAddress,
    string memory _openseaContractMetadataURL,
    bool _mintActive,
    address[] memory _freeMintProjects
  ) ERC721(_name, _symbol) {
    metadataFolderURI = _metadataFolderURI;
    mintsPerAddress = _mintsPerAddress;
    openseaContractMetadataURL = _openseaContractMetadataURL;
    mintActive = _mintActive;
    freeMintProjects = _freeMintProjects;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: token DNI");
    return string(abi.encodePacked(metadataFolderURI, Strings.toString(tokenId)));
  }

  function contractURI() public view returns (string memory) {
    return openseaContractMetadataURL;
  }

  function mint(address minter) public payable nonReentrant returns (uint256) {
    require(mintActive == true, "mint is not active rn..");
    require(minter == msg.sender, "you have to mint for yourself");
    require(minted[msg.sender] < mintsPerAddress, "only 1 mint per wallet address");
    require(msg.value == price, "Incorrect mint price");

    _tokenIds.increment();

    minted[msg.sender]++;

    uint256 tokenId = _tokenIds.current();
    _safeMint(msg.sender, tokenId);
    return tokenId;
  }

  function ownsFreeMintProject(
    address minter,
    address projectContract,
    uint256 projectTokenId
  ) internal view returns (bool) {
    bool isValidProject = false;
    for (uint j = 0; j < freeMintProjects.length; j++) {
      if(freeMintProjects[j] == projectContract) {
        isValidProject = true;
      }
    }

    if(isValidProject) {
      return FreeMintProjectsInterface(projectContract).ownerOf(projectTokenId) == minter;
    }
    
    return false;
  }

  function mintFree(
    address minter,
    address freeMintProjectContract,
    uint256 freeMintProjectTokenID
  ) public payable nonReentrant returns (uint256) {
    require(mintActive == true, "mint is not active rn..");
    require(minter == msg.sender, "you have to mint for yourself");
    require(minted[msg.sender] < mintsPerAddress, "only 1 mint per wallet address");
    require(ownsFreeMintProject(minter, freeMintProjectContract, freeMintProjectTokenID), "Do not own free mint project");

    _tokenIds.increment();

    minted[msg.sender]++;

    uint256 tokenId = _tokenIds.current();
    _safeMint(msg.sender, tokenId);
    return tokenId;
  }

  function mintedCount() external view returns (uint256) {
    return _tokenIds.current();
  }

  function setMintActive(bool _mintActive) public onlyOwner {
    mintActive = _mintActive;
  }

  function setPrice(uint256 _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function withdraw() public onlyOwner {
    uint256 _each = address(this).balance / 4;
    payable(msg.sender).transfer(_each * 3);

    // Donate 25% of all mint fees collected to GiveDirectly
    // https://www.givedirectly.org/crypto/
    address giveDirectly = 0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C;
    payable(giveDirectly).transfer(_each);
  }

  function setMetadataFolderURI(string calldata folderUrl) public onlyOwner {
    metadataFolderURI = folderUrl;
  }

  function setContractURI(string calldata folderUrl) public onlyOwner {
    openseaContractMetadataURL = folderUrl;
  }

  function addFreeMintProject(address freeMintProject) public onlyOwner {
    // For a project to be added to this list, it must include the ownerOf function in its contract
    // This is standard for ERC721 contracts
    freeMintProjects.push(freeMintProject);
  }

  function getPrice() external view returns (uint256) {
    return price;
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getAddress() external view returns (address) {
    return address(this);
  }
}