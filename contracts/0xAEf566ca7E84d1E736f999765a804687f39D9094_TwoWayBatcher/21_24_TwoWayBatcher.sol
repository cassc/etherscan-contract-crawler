//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "@equilibria/root/control/unstructured/UReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ITwoWayBatcher.sol";
import "./Batcher.sol";

contract TwoWayBatcher is ITwoWayBatcher, UReentrancyGuard, Batcher, ERC20 {
    /**
     * @notice Initializes the TwoWayBatcher
     * @dev Called at implementation instantiate and constant for that implementation.
     * @param reserve EmptySet Reserve Aaddress
     * @param dsu DSU Token address
     * @param usdc USDC Token Address
     */
    constructor(IEmptySetReserve reserve, Token18 dsu, Token6 usdc)
    Batcher(reserve, dsu, usdc)
    ERC20("Batcher Deposit", "BDEP")
    {
        __UReentrancyGuard__initialize();
    }

    /**
     * @notice Deposits USDC for Batcher to use in unwrapping flows
     * @dev Reverts if `amount` has greater precision than 6 decimals
     * @param amount Amount of USDC to deposit
     */
    function deposit(UFixed18 amount) external nonReentrant {
        if (!_validToken6Amount(amount)) revert TwoWayBatcherInvalidTokenAmount(amount);

        rebalance();

        USDC.pull(msg.sender, amount, true);

        _mint(msg.sender, UFixed18.unwrap(amount));

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraws USDC from Batcher
     * @dev Reverts if `amount` has greater precision than 6 decimals
     * @param amount Amount of USDC to withdraw
     */
    function withdraw(UFixed18 amount) external nonReentrant {
        if (!_validToken6Amount(amount)) revert TwoWayBatcherInvalidTokenAmount(amount);

        rebalance();

        _burn(msg.sender, UFixed18.unwrap(amount));

        USDC.push(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Rebalances the Batcher to maintain a target balance of USDC and DSU
     * @dev Maintains a USDC balance of outstanding deposits. Excess USDC is minted as DSU
     * @param usdcBalance Current Batcher USDC balance
     */
    function _rebalance(UFixed18 usdcBalance, UFixed18) override internal {
        UFixed18 totalDeposits = UFixed18.wrap(totalSupply());
        uint256 balanceToTarget = usdcBalance.compare(totalDeposits);

        // totalDeposits == usdcBalance: Do nothing
        if (balanceToTarget == 1) return;

        // usdcBalance > totalDeposits: deposit excess USDC
        if (balanceToTarget == 2) return RESERVE.mint(usdcBalance.sub(totalDeposits));

        // usdcBalance < totalDeposits: pull out more USDC so we have enough to cover deposits
        if (balanceToTarget == 0) return RESERVE.redeem(totalDeposits.sub(usdcBalance));
    }

    /**
     * @notice Performs actions required to close the Batcher
     */
    function _close() override internal {
        rebalance();
    }

    /**
     * @notice Checks if the `amount` has a maximum precision of 6 decimals
     * @return true if the `amount` has a precision of 6 or less, otherwise false
     */
    function _validToken6Amount(UFixed18 amount) internal pure returns (bool) {
        return UFixed18.unwrap(amount) % 1e12 == 0;
    }
}