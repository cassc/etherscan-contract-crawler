// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface MetadataProvider {
  function tokenURI(uint256 id) external view returns (string memory);
}

contract SandwichMetadataProvider is Ownable, MetadataProvider {
  using Strings for uint256;

  string public prefix;
  string public suffix;

  constructor() {}

  function setPrefix(string memory _prefix) public onlyOwner {
    prefix = _prefix;
  }

  function setSuffix(string memory _suffix) public onlyOwner {
    suffix = _suffix;
  }

  function tokenURI(uint256 id) public override view returns (string memory) {
    return string(abi.encodePacked(prefix, id.toString(), suffix));
  }
}

contract Phrumps is ERC721A, Ownable {
  
  // Set up through https://thegivingblock.com/donate/homes-not-borders/
  address public recipient = 0x7f73811eD5f3754d15AA59F17a7063c774E10aFc;

  uint constant MAX_SUPPLY = 45000;

  uint public MIN_PRICE = 0.01 ether;

  uint public amountDonated = 0; 

  address public metadataProvider;

  constructor() ERC721A("Phrumps", "PHRUMPS") {}

  function _startTokenId() override internal view virtual returns (uint256) {
    return 1;
  }

  function setMetadataProvider(address _metadataProvider) public onlyOwner {
    metadataProvider = _metadataProvider;
  }

  function mint(uint amount) external payable {
    require(totalSupply() + amount <= MAX_SUPPLY, "Sold out");
    require(msg.value >= amount * MIN_PRICE, "Not enough ETH sent");
    _mint(msg.sender, amount);
  }

  function airdrop(address[] calldata owners, uint[] calldata amounts) external onlyOwner {
    if (owners.length != amounts.length) revert();

    for (uint256 i = 0; i < owners.length; i++) {
      uint256 amount = amounts[i];
      require(totalSupply() + amount <= MAX_SUPPLY, "Not enough tokens");
      _mint(owners[i], amount);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Cannot get tokenURI for nonexistant token");
    return MetadataProvider(metadataProvider).tokenURI(tokenId);
  }

  function donateBalance() public payable {
    amountDonated += address(this).balance;
    (bool os, ) = payable(recipient).call{value: address(this).balance}("");
    require(os);
  }

  receive() external payable {}
  fallback() external payable {}
}