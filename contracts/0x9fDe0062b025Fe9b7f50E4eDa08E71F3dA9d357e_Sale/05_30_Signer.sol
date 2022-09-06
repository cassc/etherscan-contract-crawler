//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Error.sol";

contract Signer is Ownable {
  using Address for address;
  using ECDSA for bytes32;

  // signer wallet for signature verification
  address public signer;

  // address => nonce starting from 1; against replay attack
  mapping(address => uint256) public nonces;

  event LogSignerSet(address signer);

  /**
   * @param _signer signer wallet
   */
  constructor(address _signer) {
    _setSigner(_signer);
  }

  /**
   * See {_setSigner}
   *
   * Requirements:
   * - Only contract owner can call
   */
  function setSigner(address _signer) external onlyOwner {
    _setSigner(_signer);
  }

  /**
   * @dev Set signer wallet address
   * @param _signer new signer wallet; must not be the same as before; must not be zero address nor contract address
   */
  function _setSigner(address _signer) internal {
    if (signer == _signer) revert NoChangeToTheState();
    if (_signer == address(0) || _signer.isContract()) revert InvalidAddress();

    signer = _signer;
    emit LogSignerSet(_signer);
  }

  /**
   * @dev Verify signature signed off signer wallet
   * @param _hash verifying message hash
   * @param _sig signature
   * @return verified status
   */
  function _verify(
    bytes32 _hash,
    bytes memory _sig
  ) internal view returns (bool) {
    bytes32 h = _hash.toEthSignedMessageHash();
    return h.recover(_sig) == signer;
  }

  /**
   * @dev Return the chain id
   * @return chainId chain id
   */
  function _chainId() internal view returns (uint256 chainId) {
    assembly {
      chainId := chainid()
    }
  }
}