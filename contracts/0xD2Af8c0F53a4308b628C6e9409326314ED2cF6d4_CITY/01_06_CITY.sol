// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CITY is ERC20, Ownable {

  uint256 public constant MAXIMUM_SUPPLY = 1000000000 ether;
  mapping(address => bool) minters;
  
  constructor() ERC20("MetaCity", "CITY") { }

  /**
   * mints $CITY to a recipient
   * @param to the recipient of the $CITY
   * @param amount the amount of $CITY to mint
   */
  function mint(address to, uint256 amount) external {
    require(minters[msg.sender], "Only minters can mint");
    require(totalSupply() + amount <= MAXIMUM_SUPPLY, "Can't go above Max supply");
    _mint(to, amount);
  }

  /**
   * enables an address to mint / burn
   * @param minter the address to enable
   */
  function addMinter(address minter) external onlyOwner {
    minters[minter] = true;
  }

  /**
   * disables an address from minting / burning
   * @param minter the address to disbale
   */
  function removeMinter(address minter) external onlyOwner {
    minters[minter] = false;
  }
}