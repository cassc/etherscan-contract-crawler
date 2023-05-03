// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IFormatter} from "./IFormatter.sol";

interface IERC721Formatter is IFormatter {
    function name(uint64 _id) external view returns (string memory);

    function symbol(uint64 _id) external view returns (string memory);

    function tokenURI(
        uint64 _id,
        uint _tokenId
    ) external view returns (string memory);

    function contractURI(uint64 _id) external view returns (string memory);
}