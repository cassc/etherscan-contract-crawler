// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract HeelNFT is ERC721AQueryable {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 300;
  uint256 public constant WALLET_MINT_LIMIT = 5;
  address public constant owner = 0x1Af73CA2e9bf3A138f0FA24C3Cc59Ae24C13A565;

  bool public mintOpen = false;
  uint256 public mintPrice = 0.0285 ether;
  address public deployer;
  string private _metadataBaseURI;

  modifier isAuthorized() {
    require(msg.sender == owner || msg.sender == deployer, 'Not authorized');
    _;
  }

  constructor(string memory metadataUri) ERC721A("HEEL NFT", "HEEL") {
    deployer = msg.sender;
    _metadataBaseURI = metadataUri;
  }

  function mint(uint256 qty) external payable {
    require(tx.origin == msg.sender, "Smart contract mints not allowed");
    require(mintOpen, "Mint not open");
    require(_totalMinted() + qty <= MAX_SUPPLY, "Sold out!");
    require(balanceOf(msg.sender) + qty <= WALLET_MINT_LIMIT, "Wallet limit exceeded!");

    uint256 total = qty * mintPrice;
    require(msg.value >= total, "Insufficient funds!");

    _mint(msg.sender, qty);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    return string(abi.encodePacked(_metadataBaseURI, tokenId.toString(), ".json"));
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  // ADMIN STUFF

  function mintFor(uint256 qty, address addr) external isAuthorized {
    require(_totalMinted() + qty <= MAX_SUPPLY, "Sold out!");

    _safeMint(addr, qty);
  }

  function ownerWithdraw() external {
    require(address(this).balance > 0, "Nothing to withdraw!");
    (bool sent,) = owner.call{value : address(this).balance}("");
    require(sent, "Can't withdraw");
  }

  function ownerWithdrawToken(address token) external {
    IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
  }

  function setMetadataBaseUri(string memory uri) external isAuthorized {
    _metadataBaseURI = uri;
  }

  function toggleOpenMint() external isAuthorized {
    mintOpen = !mintOpen;
  }

  function updatePrice(uint256 price) external isAuthorized {
    mintPrice = price;
  }
}