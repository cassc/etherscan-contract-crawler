// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface ICvg is IERC20Metadata {
    function mintBond(address account, uint256 amount) external;

    function mintStaking(address account, uint256 amount) external;
}