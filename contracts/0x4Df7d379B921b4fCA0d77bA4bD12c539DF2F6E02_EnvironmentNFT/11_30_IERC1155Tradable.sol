// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Tradable is IERC1155, IERC2981 {
    function getCreator(uint256 id) external view
    virtual
    returns (address sender);
}