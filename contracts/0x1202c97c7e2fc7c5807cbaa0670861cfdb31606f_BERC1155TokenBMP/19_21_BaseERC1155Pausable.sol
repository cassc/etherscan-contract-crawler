// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';

/// Local includes


abstract contract BaseERC1155Pausable is AccessControl, ERC1155Pausable {


    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    constructor() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(AccessControl, ERC1155) returns (bool) {

        return ERC1155.supportsInterface(interfaceId)
                || AccessControl.supportsInterface(interfaceId);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }
}