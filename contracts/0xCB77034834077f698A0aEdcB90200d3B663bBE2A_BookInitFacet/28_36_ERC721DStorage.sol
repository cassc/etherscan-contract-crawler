// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "solady/src/utils/LibString.sol";

struct ERC721DTokenData {
    address owner;
    uint96 extraData;
}

struct ERC721DAddressData {
    uint64 balance;
    uint64 numberMinted;
    uint64 numberBurned;
    uint64 extraData;
}

library ERC721DStorage {
    struct Layout {
        string _name;
        string _symbol;
        
        mapping(uint256 => ERC721DTokenData) _tokenData;
        mapping(address => ERC721DAddressData) _addressData;
        mapping(uint256 => address) _tokenApprovals;
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }
    
    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721D.contracts.storage.ERC721D');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}