// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract GCToken is ERC20Pausable, AccessControl, Ownable {
  using SafeMath for uint256;

  uint256 public constant TOTAL_TOKENS = 1 * (10**9) * (10**18);

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  constructor() ERC20("Game Changer Token", "GC") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyOwnerOrOperator() {
    require(
      hasRole(OPERATOR_ROLE, msg.sender) || msg.sender == owner(),
      "Function can only be called by owner or operator"
    );
    _;
  }

  modifier canMintMore(uint256 amount) {
    (bool success, uint256 sum) = totalSupply().tryAdd(amount);
    require(
      success && sum <= TOTAL_TOKENS,
      "Exceed maximum supply"
    );
    _;
  }

  function mint(address to, uint256 amount)
    external
    onlyOwnerOrOperator
    canMintMore(amount)
  {
    _mint(to, amount);
  }

  function burn(address account, uint256 amount)
    external
    onlyOwnerOrOperator
  {
    _burn(account, amount);
  }

  function pause() external onlyOwnerOrOperator {
    _pause();
  }

  function unpause() external onlyOwnerOrOperator {
    _unpause();
  }
}