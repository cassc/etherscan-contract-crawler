//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../interfaces/drops/IDropsCompoundingVault.sol';
import '../../interfaces/drops/IDropsOracle.sol';

/**
 * @title compouding vault erc20 token's price oracle
 */
contract CompoudingVaultOracle is IDropsOracle {
    /// @notice address to the compouding vault
    IDropsCompoundingVault public immutable vault;

    /// @notice address to the oracle of balancer LP
    IDropsOracle public immutable oracle;

    constructor(IDropsCompoundingVault _vault, IDropsOracle _oracle) {
        vault = _vault;
        oracle = _oracle;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function latestAnswer() external view override returns (int256 answer) {
        return (oracle.latestAnswer() * int256(vault.getPricePerFullShare())) / 1e18;
    }
}