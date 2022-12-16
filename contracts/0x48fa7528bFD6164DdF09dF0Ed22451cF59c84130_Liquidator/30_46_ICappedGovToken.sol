// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IERC20Metadata.sol";

interface ICappedGovToken {

    function _underlying() external view returns (IERC20Metadata _underlying);


}