//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface ILibertiVault is IERC4626 {
    function other() external view returns (address);
}