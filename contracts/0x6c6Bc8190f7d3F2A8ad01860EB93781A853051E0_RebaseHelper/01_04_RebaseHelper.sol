// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./OperatorManager.sol";

interface IUFragmentsPolicy {
    function rebase() external;
}

interface IUniswapV2Pair {
    function sync() external;
}

/**
 * @title RebaseHelper
 *
 * @notice Rebase helper will run policy.rebase and sync all pools in one tx
 */
contract RebaseHelper is OperatorManager {
    IUFragmentsPolicy public policy;

    IUniswapV2Pair[] public pairs;

    uint256 public lastRebaseCalledTimestamp;

    function getPairs() external view returns (IUniswapV2Pair[] memory) {
        return pairs;
    }

    function setPolicy(IUFragmentsPolicy _policy) external onlyOwner {
        policy = _policy;
    }

    function setPairs(IUniswapV2Pair[] calldata _pairs) external onlyOwner {
        for (uint256 index = 0; index < pairs.length; index += 1) {
            pairs.pop();
        }

        for (uint256 index = 0; index < _pairs.length; index += 1) {
            pairs.push(_pairs[index]);
        }
    }

    function rebase() external onlyOperator {
        policy.rebase();
        for (uint256 index = 0; index < pairs.length; index++) {
            pairs[index].sync();
        }
        lastRebaseCalledTimestamp = block.timestamp;
    }
}