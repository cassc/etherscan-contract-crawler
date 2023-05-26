// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IAddressProvider } from "@gearbox-protocol/core-v2/contracts/interfaces/IAddressProvider.sol";
import { IContractsRegister } from "@gearbox-protocol/core-v2/contracts/interfaces/IContractsRegister.sol";

import { IPoolService } from "@gearbox-protocol/core-v2/contracts/interfaces/IPoolService.sol";

import { IwstETH } from "../../integrations/lido/IwstETH.sol";
import { IwstETHGateWay } from "../../integrations/lido/IwstETHGateway.sol";
import { ZeroAddressException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title WstETHGateway
/// @notice Used for converting stETH <> WstETH
contract WstETHGateway is IwstETHGateWay {
    using SafeERC20 for IERC20;
    using Address for address payable;

    IwstETH public immutable wstETH;
    address public immutable stETH;

    address public immutable pool;

    // Contract version
    uint256 public constant version = 1;

    //
    // CONSTRUCTOR
    //

    /// @dev Constructor
    /// @param _pool wstETH pool address
    constructor(address _pool) {
        if (_pool == address(0)) revert ZeroAddressException(); // F:[WSTGV1-2]

        IContractsRegister contractsRegister = IContractsRegister(
            IAddressProvider(IPoolService(_pool).addressProvider())
                .getContractsRegister()
        ); // F:[WSTGV1-2]

        if (!contractsRegister.isPool(_pool)) revert NonRegisterPoolException(); // F:[WSTGV1-2]

        pool = _pool; // F:[WSTGV1-1]

        wstETH = IwstETH(IPoolService(_pool).underlyingToken()); // F:[WSTGV1-1]

        stETH = wstETH.stETH(); // F:[WSTGV1-1]

        IERC20(wstETH.stETH()).approve(address(wstETH), type(uint256).max); // F:[WSTGV1-1]
    }

    /**
     * @dev Adds stETH liquidity to wstETH pool
     * - transfers the underlying to the pool
     * - mints Diesel (LP) tokens to onBehalfOf
     * @param amount Amount of tokens to be deposited
     * @param onBehalfOf The address that will receive the dToken
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without a facilitator.
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external override {
        IERC20(stETH).safeTransferFrom(msg.sender, address(this), amount); // F:[WSTGV1-3]

        uint256 amountWstETH = wstETH.wrap(amount); // F:[WSTGV1-3]

        _checkAllowance(address(wstETH), amountWstETH);
        IPoolService(pool).addLiquidity(amountWstETH, onBehalfOf, referralCode); // F:[WSTGV1-3]
    }

    /// @dev Removes liquidity from pool
    ///  - burns LP's Diesel (LP) tokens
    ///  - returns the equivalent amount of underlying to 'to'
    /// @param amount Amount of Diesel tokens to burn
    /// @param to Address to transfer the underlying to
    function removeLiquidity(uint256 amount, address to)
        external
        override
        returns (uint256 amountGet)
    {
        address dieselToken = IPoolService(pool).dieselToken(); // F:[WSTGV1-3]
        IERC20(dieselToken).safeTransferFrom(msg.sender, address(this), amount); // F:[WSTGV1-3]

        _checkAllowance(dieselToken, amount); // F:[WSTGV1-3]
        uint256 amountWstETH = IPoolService(pool).removeLiquidity(
            amount,
            address(this)
        ); // F:[WSTGV1-3]

        amountGet = wstETH.unwrap(amountWstETH); // F:[WSTGV1-3]
        IERC20(stETH).safeTransfer(to, amountGet); // F:[WSTGV1-3]
    }

    /// @dev Checks that the allowance is sufficient before a transaction, and sets to max if not
    /// @param token Token to approve for pool
    /// @param amount Amount to compare allowance with
    function _checkAllowance(address token, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), pool) < amount) {
            IERC20(token).safeApprove(pool, type(uint256).max);
        }
    }
}