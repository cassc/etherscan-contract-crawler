pragma solidity ^0.5.5;

import "@openzeppelin/contracts/ownership/Ownable.sol";

contract Minter is Ownable {

  mapping (address => bool) minters;

    function addMinter(address account) public onlyOwner {
      require(account != address(0), "Minter: zero address provided.");

      minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
      require(account != address(0), "Minter: zero address provided.");

      minters[account] = false;
    }

    function isMinter(address account) public view returns (bool) {
      return minters[account];
    }
}