// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBaseOracle.sol";

interface IOracle {
    /// @param tokensInOrderOfDifficulty - tokens are sorted by 'difficulty'
    /// @dev which means that tokens from this array with a lower index are converted by oracles into tokens
    /// @dev from this array with a higher index
    /// @param tokenAmounts - requested number of tokens
    /// @param securityParams - additional security parameters for oracles for MEV protection
    /// @return uint256 - tvl calculated in the last token in tokensInOrderOfDifficulty array
    function quote(
        address[] calldata tokensInOrderOfDifficulty,
        uint256[] memory tokenAmounts,
        bytes[] calldata securityParams
    ) external view returns (uint256);
}