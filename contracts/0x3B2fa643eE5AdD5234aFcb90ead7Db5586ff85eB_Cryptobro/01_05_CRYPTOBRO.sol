// contracts/Button.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Cryptobro is ERC20 {

  constructor() ERC20("Cryptobro", "CRYPTOBRO") {
    _mint(msg.sender, 696969696969696969 * 10 ** decimals());
  }

}