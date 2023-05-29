// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC2981.sol";

interface IMinitaurs {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract MinitaursReborn is Ownable, ERC721, ERC2981 {
  uint256 public constant supplyLimit = 3333;

  bool public publicSaleActive;

  uint256 public totalSupply;

  string public baseURI;

  IMinitaurs minitaurs = IMinitaurs(0x0222c3b9aF2653678ccab6ceD97E469a5DD39594);

  constructor(string memory inputBaseUri)
    ERC721("MinitaursReborn", "MINI")
  {
    baseURI = inputBaseUri;

    _setRoyalties(0x82B9176c6a906a3b782956d9e0EAD0EF98DF1Cca, 500); // 5% royalties
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function togglePublicSaleActive() external onlyOwner {
    publicSaleActive = !publicSaleActive;
  }

  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function mint(address to, uint256 numberOfTokens) external {
    if (!publicSaleActive) {
      require(minitaurs.balanceOf(msg.sender) > 0, "Original Minitaur Owners Only");
    }

    require(
      (totalSupply + numberOfTokens) <= supplyLimit,
      "Not enough tokens left"
    );

    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}