// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import './Utilities.sol';

/// @notice ERC-20 contract with support for EIP-2612 and other niceties.
contract HabitatToken is Utilities {
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowances;
  mapping (address => uint256) _nonces;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor () {
    _balances[msg.sender] = totalSupply();
  }

  /// @notice Returns the name of token.
  function name () public virtual view returns (string memory) {
    return 'Habitat Token';
  }

  /// @notice Returns the symbol of the token.
  function symbol () public virtual view returns (string memory) {
    return 'HBT';
  }

  /// @notice Returns the number of decimals the token uses.
  function decimals () public virtual view returns (uint8) {
    return 10;
  }

  /// @notice Returns the DOMAIN_SEPARATOR. See EIP-2612.
  function DOMAIN_SEPARATOR () public virtual view returns (bytes32 ret) {
    assembly {
      // load free memory ptr
      let ptr := mload(64)
      // keep a copy to calculate the length later
      let start := ptr

      // keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)')
      mstore(ptr, 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866)
      ptr := add(ptr, 32)

      // keccak256(bytes('Habitat Token'))
      mstore(ptr, 0x825a5bd2b322b183692110889ab8fda39cd7c633901fc90cea3ce579a5694e95)
      ptr := add(ptr, 32)

      // store chainid
      mstore(ptr, chainid())
      ptr := add(ptr, 32)

      // store address(this)
      mstore(ptr, address())
      ptr := add(ptr, 32)

      // hash
      ret := keccak256(start, sub(ptr, start))
    }
  }

  /// @notice Returns the total supply of this token.
  function totalSupply () public virtual view returns (uint256) {
    return 1000000000000000000;
  }

  /// @notice Returns the balance of `account`.
  function balanceOf (address account) public virtual view returns (uint256) {
    return _balances[account];
  }

  /// @notice Returns the allowance for `spender` of `account`.
  function allowance (address account, address spender) public virtual view returns (uint256) {
    return _allowances[account][spender];
  }

  /// @notice Returns the nonce of `account`. Used in `permit`. See EIP-2612.
  function nonces (address account) public virtual view returns (uint256) {
    return _nonces[account];
  }

  /// @notice Approves `amount` from sender to be spend by `spender`.
  /// @param spender Address of the party that can draw from msg.sender's account.
  /// @param amount The maximum collective amount that `spender` can draw.
  /// @return (bool) Returns True if approved.
  function approve (address spender, uint256 amount) public virtual returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @dev The concrete implementation of `approve`.
  function _approve (address owner, address spender, uint256 value) internal virtual {
    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /// @dev The concrete implementation of `transfer` and `transferFrom`.
  function _transferFrom (address from, address to, uint256 value) internal virtual returns (bool) {
    uint256 balance = _balances[from];
    require(balance >= value, 'BALANCE');

    if (from != to) {
      _balances[from] = balance - value;
      balance = _balances[to];
      uint256 newBalance = balance + value;
      // overflow check, also reverts if `value` is zero
      require(newBalance > balance, 'OVERFLOW');
      _balances[to] = newBalance;
    }

    emit Transfer(from, to, value);

    return true;
  }

  /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
  /// @param to The address to move the tokens.
  /// @param amount of the tokens to move.
  /// @return (bool) Returns True if succeeded.
  function transfer (address to, uint256 amount) public virtual returns (bool) {
    return _transferFrom(msg.sender, to, amount);
  }

  /// @notice Transfers `amount` tokens from `from` to `to`. Caller may need approval if `from` is not `msg.sender`.
  /// @param from Address to draw tokens from.
  /// @param to The address to move the tokens.
  /// @param amount The token amount to move.
  /// @return (bool) Returns True if succeeded.
  function transferFrom (address from, address to, uint256 amount) public virtual returns (bool) {
    uint256 _allowance = _allowances[from][msg.sender];
    require(_allowance >= amount, 'ALLOWANCE');

    if (_allowance != uint256(-1)) {
      _allowances[from][msg.sender] = _allowance - amount;
    }

    return _transferFrom(from, to, amount);
  }

  /// @notice Approves `value` from `owner` to be spend by `spender`.
  /// @param owner Address of the owner.
  /// @param spender The address of the spender that gets approved to draw from `owner`.
  /// @param value The maximum collective amount that `spender` can draw.
  /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
  function permit (
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'OWNER');
    require(block.timestamp < deadline, 'EXPIRED');

    uint256 nonce = _nonces[owner]++;
    bytes32 domainSeparator = DOMAIN_SEPARATOR();
    bytes32 digest;
    assembly {
      // ptr to free memory
      let ptr := mload(64)
      // keep a copy to calculate the length later
      let start := ptr

      // keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
      mstore(ptr, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
      ptr := add(ptr, 32)

      // copy (owner, spender, value) from calldata in one go
      calldatacopy(ptr, 4, 96)
      ptr := add(ptr, 96)

      // store nonce
      mstore(ptr, nonce)
      ptr := add(ptr, 32)
      // store deadline
      mstore(ptr, deadline)
      ptr := add(ptr, 32)

      // Permit struct hash
      let permitStructHash := keccak256(start, sub(ptr, start))
      // reset ptr
      ptr := start
      // add 30 bytes to align correctly (0x1901)
      start := add(ptr, 30)

      // preamble
      mstore(ptr, 0x1901)
      ptr := add(ptr, 32)

      // DOMAIN_SEPARATOR
      mstore(ptr, domainSeparator)
      ptr := add(ptr, 32)

      // from above
      mstore(ptr, permitStructHash)
      ptr := add(ptr, 32)

      // hash it
      digest := keccak256(start, sub(ptr, start))
    }

    require(ecrecover(digest, v, r, s) == owner, 'SIG');
    _approve(owner, spender, value);
  }

  /// @dev Helper function for wrapping calls. Reverts on a call to 'self'.
  function _callWrapper (address to, bytes calldata data) internal returns (bytes memory) {
    require(to != address(this));
    (bool success, bytes memory ret) = to.call(data);
    require(success);
    return ret;
  }

  /// @notice Transfers `amount` from `msg.sender` to `to` and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function transferAndCall (address to, uint256 amount, bytes calldata data) external returns (bytes memory) {
    _transferFrom(msg.sender, to, amount);
    return _callWrapper(to, data);
  }

  /// @notice Approves `amount` from `msg.sender` to be spend by `to` and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function approveAndCall (address to, uint256 amount, bytes calldata data) external returns (bytes memory) {
    _approve(msg.sender, to, amount);
    return _callWrapper(to, data);
  }

  /// @notice Redeems a permit for this contract (`permitData`) and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function redeemPermitAndCall (address to, bytes calldata permitData, bytes calldata data) external returns (bytes memory) {
    Utilities._maybeRedeemPermit(address(this), permitData);
    return _callWrapper(to, data);
  }

  /// @notice Allows to recover `token`.
  /// Transfers `token` to `msg.sender`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    Utilities._safeTransfer(token, msg.sender, Utilities._safeBalance(token, address(this)));
  }
}