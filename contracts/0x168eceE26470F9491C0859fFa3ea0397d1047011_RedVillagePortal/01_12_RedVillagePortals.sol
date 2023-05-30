// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155, ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { TokenHolder } from "./PortalHelpers.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2022
//

contract RedVillagePortal is ERC1155Supply, Ownable {
  using TokenHolder for TokenHolder.Holders;

  struct TokenBalance {
    uint16[] paymentRatios;
    address[] paymentWallets;
  }

  struct TokenConfig {
    address TEAM_WALLET;
    uint256 MAX_PUBLIC_SALE_SUPPLY;
    uint256 MAX_PRESALE_SUPPLY;
    uint256 MAX_TEAM_SUPPLY;
    uint256 MAX_PUBLIC_PER_WALLET;
    uint256 MAX_PUBLIC_PER_TXN;
    uint256 MAX_PRESALE_PER_WALLET;
    uint256 MAX_PRESALE_PER_TXN;
    uint256 PRICE;
    string baseURI;
  }

  struct TokenWhitelist {
    uint8[] standards; // 0 -> 721, 1 -> 1155
    uint256[] erc1155Ids;
    address[] contracts; // external contracts
    mapping(address => uint256) allocated;
  }

  struct TokenInfo {
    bool salesActive;
    bool presalesActive;
    bool teamClaimed;
    uint256 presaleClaimed;
    uint256 publicClaimed;
    TokenConfig config;
  }

  // variables
  mapping(uint256 => bool) public tradingPaused;
  mapping(uint256 => TokenInfo) public tokens;
  mapping(uint256 => TokenWhitelist) whitelists;
  mapping(uint256 => TokenHolder.Holders) holders;
  mapping(uint256 => TokenBalance) tokenBalances;

  constructor() ERC1155("") {
    TokenConfig storage config = tokens[1].config;
    config.MAX_PUBLIC_SALE_SUPPLY = 5965; // MAX_PUBLIC_SALE_SUPPLY + MAX_TEAM_SUPPLY = MAX_SUPPLY
    config.MAX_PRESALE_SUPPLY = 2000;
    config.MAX_TEAM_SUPPLY = 35;
    config.MAX_PUBLIC_PER_WALLET = 28;
    config.MAX_PUBLIC_PER_TXN = 14;
    config.MAX_PRESALE_PER_WALLET = 0;
    config.MAX_PRESALE_PER_TXN = 0;
    config.PRICE = 0.1 ether;
    config.TEAM_WALLET = 0xCD38B6d9c4b12654aD06Aae2842a0FC3D861188b;
    config.baseURI = "";

    tokenBalances[1].paymentRatios = [900, 100];
    tokenBalances[1].paymentWallets = [0xCBf7f6b967c2314Ed0694D39512AA18AD4d01878, 0x909680a5E46a3401D4dD75148B61E129451fa266];
  }

  /* User */
  function presaleClaim(uint256 _tokenId, uint16 _amount) external payable {
    TokenInfo storage token = tokens[_tokenId];
    TokenConfig memory config = token.config;
    require(token.presalesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Not allowed");
    require(tokenEligible(_tokenId, msg.sender) || whitelistAllocated(_tokenId, msg.sender) >= _amount, "Not eligible");
    require(whitelistAllocated(_tokenId, msg.sender) == 0 || whitelistAllocated(_tokenId, msg.sender) >= _amount, "Exceed max");
    require(config.MAX_PRESALE_PER_TXN == 0 || _amount <= config.MAX_PRESALE_PER_TXN, "Exceed max");
    require(config.MAX_PRESALE_PER_WALLET == 0 || balanceOf(msg.sender, _tokenId) + _amount <= config.MAX_PRESALE_PER_WALLET, "Exceed max");
    require(token.presaleClaimed + _amount <= config.MAX_PRESALE_SUPPLY, "Exceed total");
    require(msg.value >= (_amount * config.PRICE), "Ether value incorrect");

    if (whitelistAllocated(_tokenId, msg.sender) >= _amount) {
      whitelists[_tokenId].allocated[msg.sender] -= _amount;
    }
    _mint(msg.sender, _tokenId, _amount, "");
    tokens[_tokenId].presaleClaimed += _amount;
  }

  function claim(uint256 _tokenId, uint16 _amount) external payable {
    TokenInfo storage token = tokens[_tokenId];
    TokenConfig memory config = token.config;
    require(token.salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Not allowed");
    require(_amount <= config.MAX_PUBLIC_PER_TXN, "Exceed max");
    require(balanceOf(msg.sender, _tokenId) + _amount <= config.MAX_PUBLIC_PER_WALLET, "Exceed max");
    require(token.publicClaimed + token.presaleClaimed + _amount <= config.MAX_PUBLIC_SALE_SUPPLY, "Exceed total");
    require(msg.value >= (_amount * config.PRICE), "Ether value incorrect");

    _mint(msg.sender, _tokenId, _amount, "");
    token.publicClaimed += _amount;
  }

  /* View */
  function whitelistAllocated(uint256 _tokenId, address _account) public view returns (uint256) {
    return whitelists[_tokenId].allocated[_account];
  }

  function tokenEligible(uint256 _tokenId, address _account) public view returns (bool) {
    uint256 size = whitelists[_tokenId].standards.length;

    for (uint256 i = 0; i < size; i++) {
      if (whitelists[_tokenId].standards[i] == 0 && IERC721(whitelists[_tokenId].contracts[i]).balanceOf(_account) > 0) {
        return true;
      }
      else if (whitelists[_tokenId].standards[i] == 1 && IERC1155(whitelists[_tokenId].contracts[i]).balanceOf(_account, whitelists[_tokenId].erc1155Ids[i]) > 0) {
        return true;
      }
    }
    return false;
  }

  function getHoldersLength(uint256 _tokenId) public view returns (uint256) {
    return holders[_tokenId].accounts.length;
  }

  function getHolders(
    uint256 _tokenId,
    uint256 _start,
    uint256 _end
  ) external view returns (address[] memory, uint256[] memory) {
    uint256 maxSize = getHoldersLength(_tokenId);
    _end = _end > maxSize ? maxSize : _end;

    uint256 size = _end - _start;
    address[] memory accounts = new address[](size);
    uint256[] memory balances = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      address holder = holders[_tokenId].accounts[_start + i];
      accounts[i] = holder;
      balances[i] = balanceOf(holder, _tokenId);
    }
    return (accounts, balances);
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(exists(_tokenId), "Non exists token");
    return tokens[_tokenId].config.baseURI;
  }

  function getPaymentDetail(uint256 _tokenId) public view returns (uint16[] memory, address[] memory) {
    return (tokenBalances[_tokenId].paymentRatios, tokenBalances[_tokenId].paymentWallets);
  }

  /* Admin */
  function setTokenInfo(
    uint256 _tokenId,
    uint256 _maxPublicSale,
    uint256 _maxPresale,
    uint256 _maxTeamSupply,
    uint256 _maxPerAccount,
    uint256 _maxPerTxn,
    uint256 _maxPresalePerAccount,
    uint256 _maxPresalePerTxn,
    address _teamWallet,
    uint256 _price
  ) external onlyOwner {
    require(!exists(_tokenId), "Token exist");
    TokenConfig storage config = tokens[_tokenId].config;
    config.MAX_PUBLIC_SALE_SUPPLY = _maxPublicSale;
    config.MAX_PRESALE_SUPPLY = _maxPresale;
    config.MAX_TEAM_SUPPLY = _maxTeamSupply;
    config.MAX_PUBLIC_PER_WALLET = _maxPerAccount;
    config.MAX_PUBLIC_PER_TXN = _maxPerTxn;
    config.MAX_PRESALE_PER_WALLET = _maxPresalePerAccount;
    config.MAX_PRESALE_PER_TXN = _maxPresalePerTxn;
    config.PRICE = _price;
    config.TEAM_WALLET = _teamWallet;
  }

  function setExternalContract(
    uint256 _tokenId,
    uint8[] calldata _standards,
    address[] calldata _contracts,
    uint256[] calldata _ids
  ) external onlyOwner {
    require(_standards.length == _contracts.length, "Input mismatch");
    require(_ids.length == _contracts.length, "Input mismatch");
    for (uint256 i = 0; i < _standards.length; i++) {
      require(_standards[i] == 0 || _standards[i] == 1, "Incorrect value");
    }
    whitelists[_tokenId].standards = _standards;
    whitelists[_tokenId].contracts = _contracts;
    whitelists[_tokenId].erc1155Ids = _ids;
  }

  function setBaseURI(uint256[] calldata _tokenIds, string[] calldata _baseURI) external onlyOwner {
    require(_tokenIds.length == _baseURI.length, "Input mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].config.baseURI = _baseURI[i];
    }
  }

  function setTradingPause(uint256[] calldata _tokenIds, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tradingPaused[_tokenIds[i]] = _status;
    }
  }

  function togglePresaleActive(uint256[] calldata _tokenIds, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].presalesActive = _status;
    }
  }

  function toggleSaleActive(uint256[] calldata _tokenIds, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].salesActive = _status;
    }
  }

  function addWhitelist(
    uint256 _tokenId,
    address[] calldata _accounts,
    uint256[] calldata _amount
  ) external onlyOwner {
    require(_accounts.length == _amount.length, "Input mismatch");
    for (uint256 i = 0; i < _accounts.length; i++) {
      whitelists[_tokenId].allocated[_accounts[i]] = _amount[i];
    }
  }

  function teamClaim(uint256 _tokenId) external onlyOwner {
    TokenInfo storage token = tokens[_tokenId];
    TokenConfig memory config = token.config;
    require(!token.teamClaimed, "Team claimed");

    _mint(config.TEAM_WALLET, _tokenId, config.MAX_TEAM_SUPPLY, "");
    token.teamClaimed = true;
  }

  function updatePayment(
    uint256 _tokenId,
    uint16[] calldata _ratios,
    address[] calldata _accounts
  ) external onlyOwner {
    require(_ratios.length == _accounts.length, "Input mismatch");
    uint256 percentage = 0;
    for (uint256 i = 0; i < _ratios.length; i++) {
      percentage += _ratios[i];
    }
    require(percentage == 1000, "Invalid percentage");

    tokenBalances[_tokenId].paymentRatios = _ratios;
    tokenBalances[_tokenId].paymentWallets = _accounts;
  }

  function withdraw(uint256 _tokenId) public onlyOwner {
    TokenBalance storage tokenBalance = tokenBalances[_tokenId];
    uint256 maxBalance = address(this).balance;
    for (uint256 i = 0; i < tokenBalance.paymentRatios.length; i++) {
      uint256 balance = (maxBalance * tokenBalance.paymentRatios[i]) / 1000;
      payable(tokenBalance.paymentWallets[i]).transfer(balance);
    }
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 tokenId = ids[i];
      require(from == address(0) || !tradingPaused[tokenId], "Token paused");
      if (amounts[i] == 0) continue;
      if (from != address(0) && balanceOf(from, tokenId) == amounts[i]) {
        holders[tokenId].removeHolder(from);
      }
      if (to != address(0)) {
        holders[tokenId].addHolder(to);
      }
    }
  }
}

interface IERC721 {
  function balanceOf(address) external view returns (uint256);
}

interface IERC1155 {
  function balanceOf(address, uint256) external view returns (uint256);
}