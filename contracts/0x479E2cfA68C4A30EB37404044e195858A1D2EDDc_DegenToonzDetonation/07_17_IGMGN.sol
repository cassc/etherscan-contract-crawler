//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IGMGN is IERC1155 {
    function burn(address _owner, uint256 _id, uint256 _amount) external;
}