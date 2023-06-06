// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IOGToken is IERC165 {
    function redeem(address to, uint256 sugarcaneTokenId) external; // redeem
}