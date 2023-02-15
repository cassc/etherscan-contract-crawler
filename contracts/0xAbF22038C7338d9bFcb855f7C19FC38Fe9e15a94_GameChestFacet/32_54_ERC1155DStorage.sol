// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ERC1155DStorage {
    struct Layout {
        string _name;
        string _symbol;
        
        mapping(uint256 => mapping(address => uint256)) _balances;
        mapping(address => mapping(address => bool)) _operatorApprovals;
        mapping(uint256 => uint256) _totalSupply;

        string _uri;
    }
    
    bytes32 internal constant STORAGE_SLOT = keccak256('ERC1155D.contracts.storage.ERC1155D');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}