// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IERC1155Burn is IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}