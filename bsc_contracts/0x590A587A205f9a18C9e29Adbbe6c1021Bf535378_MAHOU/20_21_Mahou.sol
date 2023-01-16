// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

/**
 * @title token
 */
contract MAHOU is Initializable, ERC20PresetMinterPauser {
  using SafeMath for uint256;

  constructor() ERC20PresetMinterPauser("MahouCoin", "MAHOU") {}
}