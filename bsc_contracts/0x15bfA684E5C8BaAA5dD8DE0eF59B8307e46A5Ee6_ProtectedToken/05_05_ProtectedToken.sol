// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ERC20.sol";

contract ProtectedToken is ERC20 {
  constructor() ERC20("IRAN SWAP", "IRS") {
        _mint(msg.sender, 1000000000 ether);
  }
}