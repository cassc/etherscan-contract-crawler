//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMiharaNFT.sol";
interface IMiharaLimitedNFT is IMiharaNFT {
    function remainingSales() external view returns (uint256);
}