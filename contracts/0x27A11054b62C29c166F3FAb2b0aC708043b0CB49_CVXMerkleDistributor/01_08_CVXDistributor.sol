// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "GenericDistributor.sol";
import "IPirexCVX.sol";

contract CVXMerkleDistributor is GenericDistributor {
    using SafeERC20 for IERC20;

    address private constant PIREX_CVX =
        0x35A398425d9f1029021A92bc3d2557D42C8588D7;

    constructor(
        address _vault,
        address _depositor,
        address _token
    ) GenericDistributor(_vault, _depositor, _token) {}

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external override onlyAdmin {
        IERC20(token).safeApprove(vault, 0);
        IERC20(token).safeApprove(vault, type(uint256).max);
        IERC20(token).safeApprove(PIREX_CVX, 0);
        IERC20(token).safeApprove(PIREX_CVX, type(uint256).max);
    }

    /// @notice Stakes the contract's entire CVX balance in the Vault
    function stake() external override onlyAdminOrDistributor {
        IPirexCVX(PIREX_CVX).deposit(
            IERC20(token).balanceOf(address(this)),
            address(this),
            true,
            address(0)
        );
    }
}