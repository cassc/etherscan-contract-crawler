// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "DistributorZaps.sol";
import "IGenericVault.sol";

contract stkCvxCrvDistributorZaps is DistributorZaps {
    using SafeERC20 for IERC20;

    constructor(
        address _strategyZaps,
        address _distributor,
        address _vault
    ) DistributorZaps(_strategyZaps, _distributor, _vault) {}

    /// @notice Claim from distributor as cvxCrv
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param to - address to send withdrawn underlying to
    /// @return amount of underlying withdrawn
    function claimFromDistributorAsUnderlying(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        address to
    ) external returns (uint256) {
        _claim(index, account, amount, merkleProof);
        return IGenericVault(vault).withdrawAll(to);
    }

    /// @notice Claim from distributor as CRV.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - min amount of CRV expected
    /// @param to - address to lock on behalf of
    function claimFromDistributorAsCrv(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external {
        _claim(index, account, amount, merkleProof);
        IStrategyZaps(zaps).claimFromVaultAsCrv(amount, minAmountOut, to);
    }

    /// @notice Claim from the distributor, unstake and deposits in 3pool.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - minimum amount of 3CRV (NOT USDT!)
    /// @param to - address on behalf of which to stake
    function claimFromDistributorAndStakeIn3PoolConvex(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external {
        _claim(index, account, amount, merkleProof);
        IStrategyZaps(zaps).claimFromVaultAndStakeIn3PoolConvex(
            amount,
            minAmountOut,
            to
        );
    }
}