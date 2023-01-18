// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./INFT.sol";

interface INFTState is INFT {

    function mintAndDistribute(uint256[] memory tokenIds, address[] memory addresses) external;

}