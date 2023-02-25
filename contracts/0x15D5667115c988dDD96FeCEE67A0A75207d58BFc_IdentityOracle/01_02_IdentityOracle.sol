// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

import "@yield-protocol/vault-v2/contracts/interfaces/IOracle.sol";

contract IdentityOracle is IOracle {
    function peek(
        bytes32,
        bytes32,
        uint256 amountBase
    ) external view virtual override returns (uint256, uint256) {
        return (amountBase, block.timestamp);
    }

    function get(
        bytes32,
        bytes32,
        uint256 amountBase
    ) external virtual override returns (uint256, uint256) {
        return (amountBase, block.timestamp);
    }
}