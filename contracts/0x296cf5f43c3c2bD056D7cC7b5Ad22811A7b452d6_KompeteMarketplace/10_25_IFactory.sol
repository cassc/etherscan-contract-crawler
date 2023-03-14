// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFactory {
    function canMint(
        address collection,
        address account
    ) external view returns (bool);
}

interface IERC721Factory {
    function mint(
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) external;
}

interface IERC1155Factory {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}