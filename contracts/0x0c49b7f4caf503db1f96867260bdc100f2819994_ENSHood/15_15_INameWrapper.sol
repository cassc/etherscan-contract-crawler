//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";

interface INameWrapper is IERC1155 {
    function names(bytes32) external view returns (bytes memory);

    function name() external view returns (string memory);

    function ownerOf(uint256 id) external view returns (address owner);

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external returns (bytes32);
}