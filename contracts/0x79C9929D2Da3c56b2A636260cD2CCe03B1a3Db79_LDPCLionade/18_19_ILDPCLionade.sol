// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ILDPCLionade is IERC1155Upgradeable {
    function airdrop(address _toAddress, uint256[] calldata itemIds) external;

    function burnItemForOwnerAddress(
        address _materialOwnerAddress,
        uint256 _typeId,
        uint256 _quantity
    ) external;

    function mintItemToAddress(
        address _toAddress,
        uint256 _typeId,
        uint256 _quantity
    ) external;

    function mintBatchItemsToAddress(
        address _toAddress,
        uint256[] memory _typeIds,
        uint256[] memory _quantities
    ) external;

    function bulkSafeTransfer(
        address[] calldata recipients,
        uint256 _typeId,
        uint256 _quantityPerRecipient
    ) external;
}