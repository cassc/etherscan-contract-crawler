// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../utils/CompactStrings.sol";
import "../storage/ERC20Storage.sol";
import "../interfaces/IERC20.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Zero Protocol
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 is ERC20Storage, CompactStrings, IERC20 {
  /*//////////////////////////////////////////////////////////////
                             Immutables
  //////////////////////////////////////////////////////////////*/

  bytes32 private immutable _packedName;

  bytes32 private immutable _packedSymbol;

  uint8 public immutable override decimals;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    _packedName = packString(_name);
    _packedSymbol = packString(_symbol);
    decimals = _decimals;
  }

  /*//////////////////////////////////////////////////////////////
                               Queries
  //////////////////////////////////////////////////////////////*/

  function name() external view override returns (string memory) {
    return unpackString(_packedName);
  }

  function symbol() external view override returns (string memory) {
    return unpackString(_packedSymbol);
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowance[owner][spender];
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balanceOf[account];
  }

  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 amount)
    external
    virtual
    override
    returns (bool)
  {
    _allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount)
    external
    virtual
    override
    returns (bool)
  {
    _balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external virtual override returns (bool) {
    uint256 allowed = _allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max) {
      _allowance[from][msg.sender] = allowed - amount;
    }

    _balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /*//////////////////////////////////////////////////////////////
                       Internal State Handlers
  //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 amount) internal virtual {
    _totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    _balanceOf[from] -= amount;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
      _totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    _balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);
  }
}