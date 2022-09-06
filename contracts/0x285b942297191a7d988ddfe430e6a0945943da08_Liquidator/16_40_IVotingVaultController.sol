// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IERC20Metadata.sol";

interface IVotingVaultController {

    function _CappedToken_underlying(address capToken) external view returns (address underlying);


}