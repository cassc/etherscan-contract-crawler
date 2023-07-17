// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./libraries/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

contract Robotikz is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  
  uint256 public maxSupply = 4242;
  uint256 public price = 10000 ether;
  string public constant BASE_URI = "ipfs://QmWE6CWWJzrCzdaxyHXWTo8b2arAWyTJKfaYQb1DG3V6SU/";
  address public metaRageAddress;
  IToken public metapondContract;
  
  constructor() ERC721A("Robotikz", "TIKZ") {}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMetapondContract(address _address) public onlyOwner {
    metapondContract = IToken(_address);
  }

  function setMetaRageAddress(address _address) public onlyOwner {
    metaRageAddress = _address;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json"));
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);

    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    
    return tokenIds;
  }

  function mint(uint256 quantity) external nonReentrant {
    require (address(metapondContract) != address(0), "Undefined Metapond Token Contract");
    require ((quantity > 0) && (quantity <= 20), "Invalid quantity");
    require (totalSupply() + quantity <= maxSupply, "Distribution closed");
    
    uint256 fee;

    unchecked {
      fee = price * quantity;
    }

    require (metapondContract.balanceOf(msg.sender) >= fee, "Not enough funds");

    metapondContract.burn(msg.sender, fee);

    _safeMint(msg.sender, quantity);
  }

  function mintFromMetaRage(address recipient) external returns (bool) {
    if (msg.sender != address(metaRageAddress)) {
      return false;
    }

    if ((totalSupply() + 1) > maxSupply) {
      return false;
    }

    _safeMint(recipient, 1);

    return true;
  }
}