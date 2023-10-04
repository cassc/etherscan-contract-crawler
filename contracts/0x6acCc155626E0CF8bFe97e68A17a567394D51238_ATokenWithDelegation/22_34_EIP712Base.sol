// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
import {EIP712} from 'aave-token-v3/utils/EIP712.sol';

/**
 * @title EIP712Base
 * @author Aave
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base is EIP712 {
  // Map of address nonces (address => nonce)
  mapping(address => uint256) internal _nonces;

  bytes32 private _______DEPRECATED_DOMAIN_SEPARATOR;

  /**
   * @dev Constructor.
   */
  constructor() EIP712('Aave Ethereum AAVE', '2') {}

  /// @dev maintained for backwards compatibility. See EIP712 _EIP712Version
  function EIP712_REVISION() external returns (bytes memory) {
    return bytes(_EIP712Version());
  }

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return _domainSeparatorV4();
  }

  /**
   * @notice Returns the nonce value for address specified as parameter
   * @param owner The address for which the nonce is being returned
   * @return The nonce value for the input address`
   */
  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner];
  }

  /**
   * @notice Returns the user readable name of signing domain (e.g. token name)
   * @return The name of the signing domain
   */
  function _EIP712BaseId() internal view virtual returns (string memory);
}