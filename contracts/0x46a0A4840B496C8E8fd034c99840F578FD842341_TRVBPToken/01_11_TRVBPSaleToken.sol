// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2021
//

contract TRVBPToken is ERC1155Supply, Ownable {
  // constants
  address payable private ownerA = payable(0xCBf7f6b967c2314Ed0694D39512AA18AD4d01878);
  address payable private ownerB = payable(0x89b07CD8eA7b04b5009cbf54D9EcB0df15d1d6E2);
  address payable private ownerC = payable(0x2159CF9c872578ae2B722a3433D9Bb865113Aff7);
  address payable private ownerD = payable(0x909680a5E46a3401D4dD75148B61E129451fa266);

  uint256 public constant TOKEN_ID = 1;
  uint256 public constant BUY_PRICE = 0.1 ether;
  uint16 public constant MAX_PRESALE_SUPPLY = 2000;
  uint16 public constant MAX_PRESALE_PER_ACCOUNT = 2;
  uint16 public constant MAX_SUPPLY = 4970;
  uint16 public constant MAX_SUPPLY_TEAM = 30;
  address public constant TEAM_ADDRESS = 0xCD38B6d9c4b12654aD06Aae2842a0FC3D861188b;
  uint16 public constant MAX_PER_ACCOUNT = 28;
  uint16 public constant MAX_PER_TXN = 14;

  string public constant name = 'TRVBPToken';
  string public constant symbol = 'TRVBP';

  // variables
  string public baseURI = 'ipfs://QmeZtBQy6U7HxnrjW3C7H9sBFEiGfi7gBnegykhBKjeGdk';
  bool public salesActive = false;
  bool public presalesActive = false;
  bool public specialSalesActive = false;
  bool public teamClaimed = false;
  mapping(address => bool) public whitelist;
  mapping(address => bool) public specialList;
  mapping(uint256 => address) public holders;
  mapping(address => uint256) public marks;
  uint256 public claimed = 0;
  uint256 public counter = 1;

  constructor() ERC1155("") {}

  function togglePresaleActive() external onlyOwner {
    presalesActive = !presalesActive;
  }

  function toggleSpecialSalesActive() external onlyOwner {
    specialSalesActive = !specialSalesActive;
  }

  function toggleActive() external onlyOwner {
    salesActive = !salesActive;
  }

  function addWhitelist(address[] calldata _accounts, bool status) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      whitelist[_accounts[i]] = status;
    }
  }

  function addSpecialList(address[] calldata _accounts, bool status) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      specialList[_accounts[i]] = status;
    }
  }

  function presaleClaim(uint16 amount) external payable {
    require(presalesActive, "Claim is not active.");
    require(whitelist[msg.sender], "Claim: Not allowed.");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require(balanceOf(msg.sender, TOKEN_ID) + amount <= MAX_PRESALE_PER_ACCOUNT, "Claim: Can not claim that many.");
    require(claimed + amount <= MAX_PRESALE_SUPPLY, "Claim: Cannot exceed total presale supply.");
    require(msg.value >= (amount * BUY_PRICE), "Claim: Ether value incorrect.");

    _mint(msg.sender, TOKEN_ID, amount, '');
    claimed += amount;
  }

  function specialListClaim(uint16 amount) external payable {
    require(specialSalesActive, "Claim is not active.");
    require(specialList[msg.sender], "Claim: Not allowed.");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require(claimed + amount <= MAX_SUPPLY, "Claim: Cannot exceed total supply.");
    require(msg.value >= (amount * BUY_PRICE), "Claim: Ether value incorrect.");

    _mint(msg.sender, TOKEN_ID, amount, '');
    claimed += amount;
  }

  function claim(uint16 amount) external payable {
    require(salesActive, "Claim is not active.");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require(amount <= MAX_PER_TXN, "TXN Claim: Can not claim that many.");
    require(balanceOf(msg.sender, TOKEN_ID) + amount <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");
    require(claimed + amount <= MAX_SUPPLY, "Claim: Cannot exceed total supply.");
    require(msg.value >= (amount * BUY_PRICE), "Claim: Ether value incorrect.");

    _mint(msg.sender, TOKEN_ID, amount, '');
    claimed += amount;
  }

  function teamClaim() external onlyOwner {
    require(!teamClaimed, "Team Claim: Already claimed.");

    _mint(TEAM_ADDRESS, TOKEN_ID, MAX_SUPPLY_TEAM, '');
    teamClaimed = true;
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
      if (ids[i] == TOKEN_ID && amounts[i] > 0) {
        addHolder(to);
      }
    }
  }

  function getHolders() external view returns (address[] memory) {
    address[] memory accounts = new address[](counter);
    uint256 j = 0;
    for (uint256 i = 1; i <= counter; i++) {
      address account = holders[i];
      if (account != address(0) && balanceOf(account, TOKEN_ID) > 0) {
        accounts[j] = account;
        j += 1;
      }
    }
    return accounts;
  }

  function addHolder(address account) private {
    if (marks[account] > 0) return;
    holders[counter] = account;
    marks[account] = counter;
    counter += 1;
  }

  function setBaseURI(string calldata baseUri) external onlyOwner {
    baseURI = baseUri;
  }

  function uri(uint256) public view override returns (string memory) {
    return baseURI;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    uint balanceA = (balance * 490) / 1000;
    uint balanceB = (balance * 230) / 1000;
    uint balanceC = (balance * 230) / 1000;
    uint balanceD = balance - (balanceA + balanceB + balanceC);

    ownerA.transfer(balanceA);
    ownerB.transfer(balanceB);
    ownerC.transfer(balanceC);
    ownerD.transfer(balanceD);
  }
}