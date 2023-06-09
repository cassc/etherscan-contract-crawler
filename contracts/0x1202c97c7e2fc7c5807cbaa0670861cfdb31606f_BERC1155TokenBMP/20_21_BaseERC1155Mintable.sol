// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

/// Local includes


abstract contract BaseERC1155Mintable is AccessControl, ERC1155 {

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');


    constructor() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }


    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {

        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        _mint(to, id, amount, data);
    }

    function mintBatch(address to,
                        uint256[] memory ids,
                        uint256[] memory amounts,
                        bytes memory data) public virtual {

        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        _mintBatch(to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(AccessControl, ERC1155) returns (bool) {

        return ERC1155.supportsInterface(interfaceId)
                || AccessControl.supportsInterface(interfaceId);
    }
}