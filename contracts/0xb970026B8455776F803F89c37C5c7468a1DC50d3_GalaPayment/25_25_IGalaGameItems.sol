// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Why? Gala's Items Contracts use a proprietary burn function signature
interface IGalaGameItems is IERC1155 {
    function burn(address _from, uint256[] calldata _ids, uint256[] calldata _values) external;
}