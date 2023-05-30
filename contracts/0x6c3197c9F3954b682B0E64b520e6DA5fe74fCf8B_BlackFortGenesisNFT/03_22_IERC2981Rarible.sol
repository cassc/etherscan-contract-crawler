// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./LibPart.sol";


interface IERC2981Rarible is IERC165 {
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}