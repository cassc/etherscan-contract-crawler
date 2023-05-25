// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../external-lib/Counters.sol";
import "../external-lib/EIP712.sol";
import "./interfaces/IERC20Permit.sol";

/**
 * @dev Wrapper implementation for ERC20 Permit extension allowing approvals
 * via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612.
 */
contract ERC20PermitUpgradeable is
  IERC20Permit,
  Initializable,
  ERC20Upgradeable
{
  using Counters for Counters.Counter;

  bytes32 private constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  bytes32 internal _domainSeparator;

  mapping(address => Counters.Counter) private _nonces;

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20Permit_init_unchained(
    string memory domainName,
    string memory version
  ) internal initializer {
    _domainSeparator = EIP712.domainSeparatorV4(domainName, version);
  }

  /// @inheritdoc IERC20Permit
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR()
    external
    view
    override(IERC20Permit)
    returns (bytes32)
  {
    return _domainSeparator;
  }

  /**
   * @dev See {IERC20Permit-permit}.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override(IERC20Permit) {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "ERC20Permit/ExpiredDeadline");

    bytes32 structHash =
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          owner,
          spender,
          value,
          _useNonce(owner),
          deadline
        )
      );

    bytes32 hash = EIP712.hashTypedDataV4(_domainSeparator, structHash);

    address signer = ECDSA.recover(hash, v, r, s);
    require(signer == owner, "ERC20Permit/InvalidSignature");

    _approve(owner, spender, value);
  }

  /// @inheritdoc IERC20Permit
  function nonces(address owner)
    external
    view
    virtual
    override(IERC20Permit)
    returns (uint256)
  {
    return _nonces[owner].current();
  }

  /**
   * @dev "Consume a nonce": return the current value and increment.
   */
  function _useNonce(address owner) internal virtual returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  uint256[48] private __gap;
}