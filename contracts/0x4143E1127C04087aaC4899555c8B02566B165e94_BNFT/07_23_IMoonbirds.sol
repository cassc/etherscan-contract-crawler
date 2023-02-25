// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IMoonbirds {
  /**
    @notice Changes the Moonbirds' nesting statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the Moonbirds' nesting sheep (see @notice).
     */
  function toggleNesting(uint256[] calldata tokenIds) external;
}