// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./helpers/DodoV1Helper.sol";
import "./helpers/HashflowHelper.sol";
import "./helpers/UniswapV2Helper.sol";

/**
 * @title ProtocolHelper
 * @notice Aggregated helper that includes all other helpers for simplicity sake
 */
// solhint-disable-next-line no-empty-blocks
contract ProtocolHelper is
    DodoV1Helper,
    UniswapV2Helper,
    HashflowHelper
{

}