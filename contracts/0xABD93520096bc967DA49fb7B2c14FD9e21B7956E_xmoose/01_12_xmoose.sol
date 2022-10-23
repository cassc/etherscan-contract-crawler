// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract xmoose is ERC721, Ownable, ReentrancyGuard {

using Strings for uint256;

  string public uriPrefix = "https://metadata.mooselands.io/";
  string public uriSuffix = ".json";

  uint256 public immutable maxSupply = 1111;
  uint256 public minted = 1111;
  
  constructor() ERC721("X-Moose", "XMS") {}

  function mooseAirdrop(address[] calldata _to, uint256[] calldata _id) public onlyOwner {
    require(_to.length == _id.length, "Receivers and IDs are different length");

    for (uint256 i = 0; i < _to.length; i++) {
      require(_id[i] <= maxSupply);
      _safeMint(_to[i], _id[i]);
    }
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function totalSupply() external view returns (uint256) {
    return minted;
  }

}