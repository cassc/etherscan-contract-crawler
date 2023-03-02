// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWA is ERC20, Pausable, Ownable {

  constructor() ERC20("RWA.ai", "RWA") {
    _mint(
      address(0xa4F4f221b0b46CF40B55845Bf3759705CE7886bd), 
      100_000_000_000 ether
    );

    transferOwnership(0xa4F4f221b0b46CF40B55845Bf3759705CE7886bd);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}