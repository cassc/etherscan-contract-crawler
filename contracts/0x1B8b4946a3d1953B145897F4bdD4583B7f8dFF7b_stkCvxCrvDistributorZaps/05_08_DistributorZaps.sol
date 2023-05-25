// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "IStrategyZaps.sol";
import "IGenericDistributor.sol";

contract DistributorZaps {
    using SafeERC20 for IERC20;

    address public immutable zaps;
    address public vault;
    IGenericDistributor public distributor;

    constructor(
        address _strategyZaps,
        address _distributor,
        address _vault
    ) {
        zaps = _strategyZaps;
        distributor = IGenericDistributor(_distributor);
        vault = _vault;
    }

    function setApprovals() external {
        IERC20(vault).safeApprove(zaps, 0);
        IERC20(vault).safeApprove(zaps, type(uint256).max);
    }

    /// @notice Claim from distributor and transfer back tokens to zap
    function _claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        distributor.claim(index, account, amount, merkleProof);
        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Claim from distributor as either FXS or cvxFXS
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param assetIndex - asset to withdraw (0: FXS, 1: cvxFXS)
    /// @param minAmountOut - minimum amount of underlying tokens expected
    /// @param to - address to send withdrawn underlying to
    /// @return amount of underlying withdrawn
    function claimFromDistributorAsUnderlying(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 assetIndex,
        uint256 minAmountOut,
        address to
    ) external returns (uint256) {
        _claim(index, account, amount, merkleProof);
        return
            IStrategyZaps(zaps).claimFromVaultAsUnderlying(
                amount,
                assetIndex,
                minAmountOut,
                to
            );
    }

    /// @notice Claim from distributor as USDT.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the USDT
    /// @return amount of USDT obtained
    function claimFromDistributorAsUsdt(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external returns (uint256) {
        _claim(index, account, amount, merkleProof);
        return
            IStrategyZaps(zaps).claimFromVaultAsUsdt(amount, minAmountOut, to);
    }

    /// @notice Claim to any token via a univ2 router
    /// @notice Use at your own risk
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - min amount of output token expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param outputToken - address of the token to swap to
    /// @param to - address of the final recipient of the swapped tokens
    function claimFromDistributorViaUniV2EthPair(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) external {
        _claim(index, account, amount, merkleProof);
        IStrategyZaps(zaps).claimFromVaultViaUniV2EthPair(
            amount,
            minAmountOut,
            router,
            outputToken,
            to
        );
    }

    /// @notice Claim from distributor as ETH.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - min amount of ETH expected
    /// @param to - address to lock on behalf of
    function claimFromDistributorAsEth(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to
    ) external {
        _claim(index, account, amount, merkleProof);
        IStrategyZaps(zaps).claimFromVaultAsEth(amount, minAmountOut, to);
    }

    /// @notice Claim from distributor as CVX and optionally lock.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    /// @param minAmountOut - min amount of CVX expected
    /// @param to - address to lock on behalf of
    /// @param lock - whether to lock the Cvx or not
    function claimFromDistributorAsCvx(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 minAmountOut,
        address to,
        bool lock
    ) external {
        _claim(index, account, amount, merkleProof);
        IStrategyZaps(zaps).claimFromVaultAsCvx(amount, minAmountOut, to, lock);
    }
}