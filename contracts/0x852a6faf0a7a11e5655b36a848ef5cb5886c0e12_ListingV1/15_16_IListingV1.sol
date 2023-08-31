// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IListingV1 is IERC721Metadata {
    event ItemAdded(
        address indexed owner,
        uint256 itemId,
        uint256 categoryId,
        uint256 expireAt,
        string title,
        string uri
    );
    event ItemUpdated(
        uint256 itemId,
        uint256 expireAt,
        string title,
        string uri
    );
    event ItemRemoved(uint256 itemId);

    struct Item {
        uint256 categoryId;
        uint256 expireAt;
        string title;
        string uri;
    }

    function category() external view returns (address);
    function guardian() external view returns (address);
    function displayDuration() external view returns (uint256);
    function idCounter() external view returns (uint256);
    function getItem(uint256) external view returns (
        uint256 categoryId,
        uint256 expireAt,
        string memory title,
        string memory uri
    );

    function changeGuardian(address newGuardian) external;
    function post(
        uint256 categoryId,
        string calldata title,
        string calldata uri
    ) external returns (uint256 itemId);
    function update(
        uint256 itemId,
        string calldata title_,
        string calldata uri_
    ) external;
    function remove(uint256 itemId) external;
    function batchRemove(uint256[] memory itemIds) external;
}