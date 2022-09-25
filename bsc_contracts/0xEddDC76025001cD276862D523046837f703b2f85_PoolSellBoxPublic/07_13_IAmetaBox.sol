// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAmetaBox is IERC721Enumerable {
    function mint(address _to, uint256 _boxType) external returns (uint256);

    function mintBatch(
        address _to,
        uint256 _qty,
        uint256 _boxType
    ) external returns (uint256[] memory tokenIds);

    function tokenIdsOfOwner(address _owner)
        external
        view
        returns (uint256[] memory tokenIds);

    function openBox(uint256 _boxId) external;

    function openBoxs(uint256[] memory _boxIds) external;

    function viewListBoxType() external view returns (uint256[] memory);

    function validateBoxType(uint256 _boxType) external view returns (bool);
}