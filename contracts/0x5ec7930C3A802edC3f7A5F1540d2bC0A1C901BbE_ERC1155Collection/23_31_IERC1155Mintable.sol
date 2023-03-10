// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../libs/LibERC1155MintData.sol";

interface IERC1155Mintable {
    function mint(LibERC1155MintData.MintData calldata mintData) external;

    function mintBatch(LibERC1155MintData.MintBatchData calldata mintData) external;
}