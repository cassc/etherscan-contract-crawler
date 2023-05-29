// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "GenericDistributor.sol";
import "ICurveV2Pool.sol";
import "IStrategyZaps.sol";

interface IVaultZaps {
    function depositFromFxs(
        uint256 amount,
        uint256 minAmountOut,
        address to,
        bool lock
    ) external;
}

contract stkCvxFxsMerkleDistributor is GenericDistributor {
    using SafeERC20 for IERC20;

    address public vaultZap;

    address private constant FXS_TOKEN =
        0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    address private constant CURVE_CVXFXS_FXS_POOL =
        0xd658A338613198204DCa1143Ac3F01A722b5d94A;

    // 1.5% slippage tolerance by default
    uint256 public slippage = 9850;
    uint256 private constant DECIMALS = 10000;

    ICurveV2Pool private cvxFxsPool = ICurveV2Pool(CURVE_CVXFXS_FXS_POOL);

    // This event is triggered whenever the zap contract is updated.
    event ZapUpdated(address indexed oldZap, address indexed newZap);

    constructor(
        address _vault,
        address _depositor,
        address _zap
    ) GenericDistributor(_vault, _depositor, FXS_TOKEN) {
        require(_zap != address(0));
        vaultZap = _zap;
    }

    /// @notice Set the acceptable level of slippage for LP deposits
    /// @dev As percentage of the ETH value of original amount in BIPS
    /// @param _slippage - the acceptable slippage threshold
    function setSlippage(uint256 _slippage) external onlyAdmin {
        slippage = _slippage;
    }

    /// @notice Changes the Zap for deposits
    /// @param newZap - address of the new zap
    function updateZap(address newZap)
        external
        onlyAdmin
        notToZeroAddress(newZap)
    {
        address oldZap = vaultZap;
        vaultZap = newZap;
        emit ZapUpdated(oldZap, vaultZap);
    }

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external override onlyAdmin {
        IERC20(token).safeApprove(vaultZap, 0);
        IERC20(token).safeApprove(vaultZap, type(uint256).max);
    }

    /// @notice Stakes the contract's entire cvxCRV balance in the Vault
    function stake() external override onlyAdminOrDistributor {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            uint256 price = cvxFxsPool.price_oracle();
            uint256 minAmountOut = (balance * price) / 1e18;
            minAmountOut = ((minAmountOut * slippage) / DECIMALS);
            IVaultZaps(vaultZap).depositFromFxs(
                balance,
                minAmountOut,
                address(this),
                (price > 1 ether)
            );
        }
    }
}