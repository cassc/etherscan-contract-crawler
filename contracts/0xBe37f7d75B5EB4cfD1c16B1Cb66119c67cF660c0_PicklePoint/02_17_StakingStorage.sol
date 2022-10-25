// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library StakingStorage {
    struct Layout {
        uint256 collectionsCount;
        mapping(address => IERC721) collections;
        mapping(uint256 => address) collectionsByIndex;
        mapping(address => mapping(address => mapping(uint256 => uint256))) stakingStart;
        mapping(address => mapping(address => mapping(uint256 => bool))) staking;
        mapping(address => mapping(address => uint256)) stakingCount;
        mapping(address => mapping(address => mapping(uint256 => uint256))) tokensByIndex;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("NiftyKit.contracts.Staking");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}