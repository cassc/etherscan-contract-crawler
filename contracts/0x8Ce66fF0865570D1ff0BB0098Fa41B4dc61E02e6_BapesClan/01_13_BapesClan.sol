// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BapesClan is ERC721, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private supply;

  uint256 private maxSupplyTotal = 10000;
  uint256 private maxSupplyPrivate = 8000;
  uint256 private constant price = 0.3 ether;
  uint256 private constant maxPerMint = 1;
  uint256 private maxPerWallet = 1;
  bool private paused = true;
  bool private revealed = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  mapping(address => bool) private whitelistedWallets;
  mapping(address => uint256) private mintedWallets;
  address private withdrawWallet;

  constructor(string memory _hiddenMetadataURI) ERC721("Bapes Clan", "BAPE") {
    setHiddenMetadataURI(_hiddenMetadataURI);

    withdrawWallet = address(0x4Fc034B5C673d59887eDA707ae2ca2446067890F);
  }

  function setHiddenMetadataURI(string memory _hiddenMetadataURI) private {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.`");

    if (revealed == false) {
      return hiddenMetadataURI;
    }

    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function mintBape() public payable {
    uint256 totalMinted = totalSupply();

    // checks
    require(whitelistedWallets[msg.sender], "This wallet is not authorized to mint.");
    require(!paused, "Minting is paused.");
    require((totalMinted + maxPerMint) <= maxSupplyPrivate, "Not enough Bapes.");
    require(msg.value >= price, "Insufficient balance to mint.");
    require(
      mintedWallets[msg.sender] < maxPerWallet,
      "The number of minted Bapes will exceed the maximum amount of allowed per wallet."
    );

    // update mapping
    uint256 minted = mintedWallets[msg.sender];

    mintedWallets[msg.sender] = minted + 1;

    // mint
    mintSingle();
  }

  function mintSingle() private {
    uint256 newTokenID = totalSupply();

    _safeMint(msg.sender, newTokenID);

    supply.increment();
  }

  function isWhitelisted(address _wallet) external view returns (bool) {
    return whitelistedWallets[_wallet];
  }

  function getBalanceOf(address _wallet) external view returns (uint256) {
    return mintedWallets[_wallet];
  }

  function getMaxAllowed() external view returns (uint256) {
    return maxPerWallet;
  }

  // only owner
  function whitelistWallets(address[] calldata _wallets) public onlyOwner {
    require(_wallets.length <= maxSupplyTotal, "Limit exceeded, use lesser number of wallets.");

    for (uint256 i = 0; i < _wallets.length; i++) {
      whitelistedWallets[_wallets[i]] = true;
    }
  }

  function blacklistWallets(address[] calldata _wallets) public onlyOwner {
    require(_wallets.length <= maxSupplyTotal, "Limit exceeded, use lesser number of wallets.");

    for (uint256 i = 0; i < _wallets.length; i++) {
      whitelistedWallets[_wallets[i]] = false;
    }
  }

  function reserveBapes(uint256 _count) public onlyOwner {
    uint256 totalMinted = totalSupply();

    require((totalMinted + _count) <= maxSupplyTotal, "Not enough Bapes.");

    for (uint256 i = 0; i < _count; i++) {
      mintSingle();
    }
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) public onlyOwner {
    withdrawWallet = _withdrawWallet;
  }

  function updateMaxSupplyTotal(uint256 _number) public onlyOwner {
    maxSupplyTotal = _number;
  }

  function updateMaxSupplyPrivate(uint256 _number) public onlyOwner {
    require(_number <= maxSupplyTotal, "Private supply can not exceed total supply.");

    maxSupplyPrivate = _number;
  }

  function updateMaxPerWallet(uint256 _number) public onlyOwner {
    maxPerWallet = _number;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function updateURIPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
}