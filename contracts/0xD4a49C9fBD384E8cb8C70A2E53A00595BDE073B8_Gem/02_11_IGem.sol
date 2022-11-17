// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IGem is IERC1155 {
    function setURI(string memory newURI) external;

    function mint(
        address recipient,
        uint256 tokenId,
        uint256 quantity
    ) external;

    function setOperators(address[] calldata users, bool removed) external;

    function setAllocations(uint256 tokenId, uint256 allocation) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}