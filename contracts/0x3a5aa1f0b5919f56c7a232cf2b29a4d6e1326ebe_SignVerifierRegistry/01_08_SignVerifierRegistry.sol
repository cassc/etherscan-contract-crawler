// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ISignVerifierRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract SignVerifierRegistry is ERC165, AccessControl, ISignVerifierRegistry {
  mapping(bytes32 => address) signVerifiers;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function register(bytes32 id, address signVerifier) public {
    require(id != DEFAULT_ADMIN_ROLE, "SignVerifierRegistry: id cannot match the admin role");
    require(signVerifiers[id] == address(0), "SignVerifierRegistry: id is already registered");
    signVerifiers[id] = signVerifier;
    _grantRole(id, _msgSender());

    emit Register(id, signVerifier);
  }

  function update(bytes32 id, address signVerifier) public onlyRole(id) {
    address oldSignVerifier = signVerifiers[id];
    signVerifiers[id] = signVerifier;

    emit Update(id, signVerifier, oldSignVerifier);
  }

  function get(bytes32 id) public view returns (address) {
    require(signVerifiers[id] != address(0), "id has not been registered yet");
    return signVerifiers[id];
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC165, AccessControl)
    returns (bool)
  {
    return interfaceId == type(ISignVerifierRegistry).interfaceId || super.supportsInterface(interfaceId);
  }
}