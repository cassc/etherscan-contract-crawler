// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TRVL is ERC20PresetMinterPauser {
  using SafeMath for uint256;

  string private constant NAME = "TRVL";
  string private constant SYMBOL = "TRVL";
  uint8 private constant DECIMALS = 18;

  // Token amount must be multiplied by this const to reflect decimals
  uint256 private constant E18 = 10**DECIMALS;

  uint256 private constant MAX_SUPPLY = 1000000000 * E18; // 1,000,000,000 tokens (1 billion)
  uint256 private immutable _cap;

  constructor() ERC20PresetMinterPauser(NAME, SYMBOL) {
    _cap = MAX_SUPPLY;
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  function mint(address to, uint256 amount) public override {
    require(
      ERC20.totalSupply().add(amount) <= cap(),
      "ERC20Capped: cap exceeded"
    );
    super.mint(to, amount);
  }

  function mintBatch(address[] calldata to, uint256[] calldata amount)
    external
  {
    require(
      to.length == amount.length,
      "TRVL: mintBatch inputs do not have same length"
    );
    for (uint256 i = 0; i < to.length; i++) {
      mint(to[i], amount[i]);
    }
  }
}