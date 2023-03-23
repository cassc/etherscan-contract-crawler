// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {SupportsInterface} from '@ensdomains/ens-contracts/contracts/resolvers/SupportsInterface.sol';
import {IExtendedResolver} from './IExtendedResolver.sol';
import {SignatureVerifier} from './SignatureVerifier.sol';

interface IResolverService {
  function resolve(
    bytes calldata name,
    bytes calldata data
  ) external view returns (bytes memory result, uint64 expires, bytes memory sig);
}

/**
 * Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */
contract OffchainResolver is IExtendedResolver, SupportsInterface, OwnableUpgradeable {
  string public url;
  mapping(address => bool) public signers;
  error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

  /**
   * @dev Initializes the contract with the read gateway URL and the addresses of the signers.
   * @param _url the URL of the read gateway
   * @param _signers the addresses of the signers
   */
  function initialize(string memory _url, address[] memory _signers) public initializer {
    __Ownable_init();
    url = _url;
    for (uint i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = true;
    }
  }

  function makeSignatureHash(
    address target,
    uint64 expires,
    bytes memory request,
    bytes memory result
  ) external pure returns (bytes32) {
    return SignatureVerifier.makeSignatureHash(target, expires, request, result);
  }

  /**
   * Resolves a name, as specified by ENSIP 10.
   * @param name The DNS-encoded name to resolve.
   * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
   * @return The return data, ABI encoded identically to the underlying function.
   */
  function resolve(bytes calldata name, bytes calldata data) external view override returns (bytes memory) {
    bytes memory callData = abi.encodeWithSelector(IResolverService.resolve.selector, name, data);
    string[] memory urls = new string[](1);
    urls[0] = url;
    revert OffchainLookup(address(this), urls, callData, OffchainResolver.resolveWithProof.selector, callData);
  }

  /**
   * Callback used by CCIP read compatible clients to verify and parse the response.
   * @param response The response from the CCIP read gateway.
   * @param extraData The extra data passed to the CCIP read gateway.
   */
  function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
    (address signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
    require(signers[signer], 'SignatureVerifier: Invalid sigature');
    return result;
  }

  function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
    return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * Sets the URL of the CCIP read gateway.
   * @param _url The URL of the CCIP read gateway.
   */
  function setURL(string calldata _url) external onlyOwner {
    url = _url;
  }

  /**
   * Adds signers of the CCIP read gateway.
   * @param _signers Array of signers to add
   */
  function addSigners(address[] calldata _signers) external onlyOwner {
    for (uint i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = true;
    }
  }

  /**
   * Removes signers of the CCIP read gateway.
   * @param _signers Array of signers to remove
   */
  function removeSigners(address[] calldata _signers) external onlyOwner {
    for (uint i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = false;
    }
  }
}