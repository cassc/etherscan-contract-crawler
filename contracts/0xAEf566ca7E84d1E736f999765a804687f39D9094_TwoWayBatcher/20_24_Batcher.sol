//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "@equilibria/root/control/unstructured/UOwnable.sol";
import "../interfaces/IBatcher.sol";
import "../interfaces/IEmptySetReserve.sol";

abstract contract Batcher is IBatcher, UOwnable {
    /// @dev Reserve address
    IEmptySetReserve public immutable RESERVE; // solhint-disable-line var-name-mixedcase

    /// @dev DSU address
    Token18 public immutable DSU; // solhint-disable-line var-name-mixedcase

    /// @dev USDC address
    Token6 public immutable USDC; // solhint-disable-line var-name-mixedcase

    /**
     * @notice Initializes the Batcher
     * @dev Called at implementation instantiate and constant for that implementation.
     * @param reserve EmptySet Reserve Aaddress
     * @param dsu DSU Token address
     * @param usdc USDC Token Address
     */
    constructor(IEmptySetReserve reserve, Token18 dsu, Token6 usdc) {
        RESERVE = reserve;
        DSU = dsu;
        USDC = usdc;

        DSU.approve(address(RESERVE));
        USDC.approve(address(RESERVE));

        __UOwnable__initialize();
    }

    /**
     * @notice Total USDC and DSU balance of the Batcher
     * @return Balance of DSU + balance of USDC
     */
    function totalBalance() public view returns (UFixed18) {
        return DSU.balanceOf().add(USDC.balanceOf());
    }

    /**
     * @notice Wraps `amount` of USDC, returned DSU to `to`
     * @param amount Amount of USDC to wrap
     * @param to Receiving address of resulting DSU
     */
    function wrap(UFixed18 amount, address to) external {
        _wrap(amount, to);
        emit Wrap(to, amount);
    }

    /**
     * @notice Pulls USDC from the `msg.sender` and pushes DSU to `to`
     * @dev Rounds USDC amount up if `amount` exceeds USDC decimal precision. Overrideable by implementation
     * @param amount Amount of USDC to pull
     * @param to Receiving address of resulting DSU
     */
    function _wrap(UFixed18 amount, address to) virtual internal {
        USDC.pull(msg.sender, amount, true);
        DSU.push(to, amount);
    }

    /**
     * @notice Unwraps `amount` of DSU, returned USDC to `to`
     * @param amount Amount of DSU to unwrap
     * @param to Receiving address of resulting USDC
     */
    function unwrap(UFixed18 amount, address to) external {
        _unwrap(amount, to);
        emit Unwrap(to, amount);
    }

    /**
     * @notice Pulls DSU from the `msg.sender` and pushes USDC to `to`
     * @dev Rounds USDC amount down if `amount` exceeds USDC decimal precision. Overrideable by implementation
     * @param amount Amount of DSU to pull
     * @param to Receiving address of resulting USDC
     */
    function _unwrap(UFixed18 amount, address to) virtual internal {
        DSU.pull(msg.sender, amount);
        USDC.push(to, amount);
    }

    /**
     * @notice Rebalances the USDC and DSU in the Batcher to maintain target balances
     * @dev Reverts if the new total balance is less than before
     */
    function rebalance() public {
        (UFixed18 usdcBalance, UFixed18 dsuBalance) = (USDC.balanceOf(), DSU.balanceOf());

        _rebalance(usdcBalance, dsuBalance);

        UFixed18 newDsuBalance = DSU.balanceOf();
        (UFixed18 oldBalance, UFixed18 newBalance) = (usdcBalance.add(dsuBalance), totalBalance());
        if (oldBalance.gt(newBalance)) revert BatcherBalanceMismatchError(oldBalance, newBalance);

        emit Rebalance(
            newDsuBalance.gt(dsuBalance) ? newDsuBalance.sub(dsuBalance) : UFixed18Lib.ZERO,
            dsuBalance.gt(newDsuBalance) ? dsuBalance.sub(newDsuBalance) : UFixed18Lib.ZERO
        );
    }

    /// @dev Hook for implementation for custom rebalance logic
    function _rebalance(UFixed18 usdcBalance, UFixed18 dsuBalance) virtual internal;

    /**
     * @notice Closes the Batcher. Repaying debt to Reserve and returning excess USDC to owner.
     */
    function close() external onlyOwner {
        _close();

        UFixed18 dsuBalance = DSU.balanceOf();
        UFixed18 repayAmount = UFixed18Lib.min(RESERVE.debt(address(this)), dsuBalance);
        UFixed18 returnAmount = dsuBalance.sub(repayAmount);

        RESERVE.repay(address(this), repayAmount);

        // If there is any excess DSU, redeem it for USDC and send to the owner
        if (!returnAmount.isZero()) {
            RESERVE.redeem(returnAmount);
            USDC.push(owner(), returnAmount);
        }

        emit Close(dsuBalance);
    }

    /// @dev Hook for implementation for custom close logic
    function _close() virtual internal;
}