// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

interface IERC1155Mintable {
    function mint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;
}