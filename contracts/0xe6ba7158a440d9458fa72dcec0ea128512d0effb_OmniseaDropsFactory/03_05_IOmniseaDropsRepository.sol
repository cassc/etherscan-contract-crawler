// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaDropsRepository {
    function create(CreateParams calldata params, address creator) external;
    function collections(address collection) external returns (bool);
}