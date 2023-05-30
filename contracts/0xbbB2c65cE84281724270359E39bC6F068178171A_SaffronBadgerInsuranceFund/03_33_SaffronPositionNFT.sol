// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SaffronPositionNFT is ERC721Enumerable {

  address public pool;           // Address of Saffron pool that owns this NFT
  address public insurance_fund; // Address of Saffron insurance fund
  uint256 public next_id = 1;    // NFT tokenId counter

  // Mapping tokenId to data
  mapping(uint256=>uint256) public tranche;       // Tranche
  mapping(uint256=>uint256) public balance;       // User's balance in this tranche LP
  mapping(uint256=>uint256) public principal;     // Principal when user enters pool
  mapping(uint256=>uint256) public expiration;    // Expiration date when NFT is unfrozen

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    pool = msg.sender;
  }

  function mint(address _to, uint256 _amount, uint256 _principal, uint256 _tranche) external returns (uint256) {
    require(msg.sender == pool || msg.sender == insurance_fund, "only pool or fund can mint");

    // Store value of user's deposit
    tranche[next_id] = _tranche;
    balance[next_id] = _amount;
    principal[next_id] = _principal;

    uint256 token_id = next_id;
    _safeMint(_to, next_id++);

    return token_id;
  }

  function burn(uint256 token_id) external {
    require(msg.sender == pool || msg.sender == insurance_fund, "only pool or fund can burn");
    require(expiration[token_id] > 0 && block.timestamp > expiration[token_id], "can't redeem NFT: too early");
    _burn(token_id);
  }

  // Begin to unfreeze the NFT. When unfreezing time expires the pool can burn the NFT and send assets back to the user
  function begin_unfreeze(address user, uint256 token_id) external {
    require(msg.sender == pool, "only pool can begin_unfreeze");
    require(this.ownerOf(token_id) == user, "only owner can unfreeze");
    require(expiration[token_id] == 0, "already unfreezing");
    expiration[token_id] = block.timestamp + 1 weeks;
  }

  function set_insurance_fund(address to) external {
    require(msg.sender == pool, "must be pool");
    require(to != address(0), "can't set to 0");
    insurance_fund = to;
  }

  function baseURI() public pure returns (string memory) {
    return "ipfs://QmVrcjjJfYHKhCG6uBZUgUMWRxw5XxVWNN71xzkuvDkNgW/";
  }

  function tokenURI(uint256 tokenId) public pure override returns (string memory) {
    return "ipfs://QmVrcjjJfYHKhCG6uBZUgUMWRxw5XxVWNN71xzkuvDkNgW/1";
  }

}