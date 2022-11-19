// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../storage/ERC2612Storage.sol";
import "../utils/SignatureVerification.sol";
import "../interfaces/IERC2612.sol";
import "./ERC20.sol";

contract ERC2612 is ERC2612Storage, ERC20, SignatureVerification, IERC2612 {
  /*//////////////////////////////////////////////////////////////
                             Constructor
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _proxyContract,
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    string memory _version
  )
    ERC20(_name, _symbol, _decimals)
    SignatureVerification(_proxyContract, _name, _version)
  {}

  /*//////////////////////////////////////////////////////////////
                               Queries
  //////////////////////////////////////////////////////////////*/

  function DOMAIN_SEPARATOR() external view override returns (bytes32) {
    return getDomainSeparator();
  }

  function nonces(address account) external view override returns (uint256) {
    return _nonces[account];
  }

  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8,
    bytes32,
    bytes32
  ) external virtual override {
    if (deadline < block.timestamp) {
      revert PermitDeadlineExpired(deadline, block.timestamp);
    }
    _verifyPermitSignature(owner, _nonces[owner]++, deadline);

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      _allowance[owner][spender] = value;
    }

    emit Approval(owner, spender, value);
  }
}