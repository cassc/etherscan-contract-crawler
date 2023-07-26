// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//Standard NFT
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

//Royalty
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CubeMeltInstagramCollection is ERC721, Ownable, Pausable, ERC721Burnable, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;
  
  uint256 public constant MAXSUPPLY = 300;
  Counters.Counter private supply;

  address private t1 = 0x2283BF4705A9D4E850a4C8dEF2aAe9Ac98F4c495;
  string public baseURI = "https://ipfs.filebase.io/ipfs/Qmes7aGvXTC6aZMJyLAF34VfxDkZ1drVhhR7XRUWC6Di8d/";

  constructor() ERC721("CubeMelt Instagram Collection", "CMIC") {
    setDefaultRoyalty(t1, 500); //5%
  }

//*** INTERNAL FUNCTION ***//
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

//*** PUBLIC FUNCTION ***//
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

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

//*** ONLY OWNER FUNCTION **** //
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner whenNotPaused {
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function airDropService(address[] calldata _airDropAddresses) public onlyOwner whenNotPaused {
    require(supply.current() + _airDropAddresses.length <= MAXSUPPLY, "Out of supply.");

    for (uint256 i = 0; i < _airDropAddresses.length; i++) {
      supply.increment();
      _safeMint(_airDropAddresses[i], supply.current());
    }
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(t1).call{value: address(this).balance}("");
    require(os);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function burn(uint256 _index) public onlyOwner override(ERC721Burnable) {
    _burn(_index);
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