// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**
 * @title StakePool
 * @notice Represents a contract where a token owner has put her tokens up for others to stake and earn said tokens.
 */
contract MetropyToken is ERC20 {
  constructor(
    uint256 _supply
  ) ERC20("Tropy", "$TROPY") {
      _mint(msg.sender, _supply * (10 ** 18));
  } 
}