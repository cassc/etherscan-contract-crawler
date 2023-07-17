// SPDX-License-Identifier: MIT
/*  
    HSH Honorary Members COLLECTION / 2022 
*/

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract HyperSenseHumansHonoraryMembers is ERC721, ERC721Enumerable, Ownable {

  using SafeMath for uint256;
  using Strings for uint256;

  uint256 public offsetIndex = 0;
  uint256 public MAX_SUPPLY = 8888;
  string private _baseURIExtended;
  
  address private s1 = 0x07E6550526b9117AD9070FA2a8249dF34E838613;

  modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Oops. Something went wrong !");
    _;
  }
  
  event TokenMinted(uint256 supply);

  constructor() ERC721('HyperSenseHumansHonoraryMembers', 'HSHHM') { }

  function withdraw() public onlyOwner {
    require(payable(s1).send(address(this).balance), "Send Failed");
  }
  
  function getTotalSupply() public view returns (uint256) {
    return totalSupply();
  }

  function getTokenByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function reserve(uint256 num) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function airdrop(uint256 num, address recipient) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, recipient);
    emit TokenMinted(totalSupply());
  }

  function airdropToMany(address[] memory recipients) external onlyOwner {
    require(totalSupply().add(recipients.length) <= MAX_SUPPLY, "Exceeding max supply");
    for (uint256 i = 0; i < recipients.length; i++) {
      airdrop(1, recipients[i]);
    }
  }

  function _mint(uint256 num, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= num; i++) {
      _safeMint(recipient, supply + i);
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      if (tokenId < MAX_SUPPLY+1) {
        uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(MAX_SUPPLY);
        if (offsetId == 0 ) {
          offsetId = 8888;
        }
        return string(abi.encodePacked(_baseURI(), offsetId.toString(), ".json"));
      }  
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}