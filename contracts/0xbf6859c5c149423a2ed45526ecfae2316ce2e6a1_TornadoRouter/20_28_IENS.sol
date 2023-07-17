// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// Local imports

import { IENSResolver } from "./IENSResolver.sol";

interface IENS {
    function setOwner(bytes32 node, address owner) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (IENSResolver);
}