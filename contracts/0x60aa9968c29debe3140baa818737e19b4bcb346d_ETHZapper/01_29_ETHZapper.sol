// SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.19;

import { WETH as IWETH } from "solmate/tokens/WETH.sol";
import { MultiPoolStrategy as IMultiPoolStrategy } from "./MultiPoolStrategy.sol";
import { console2 } from "forge-std/console2.sol";
import { ReentrancyGuardUpgradeable } from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

//// ERRORS
error StrategyPaused();
error StrategyAssetNotWETH();
error EmptyInput();
/**
 * @title ETHZapper
 * @dev This contract allows users to deposit, withdraw, and redeem into a MultiPoolStrategy contract using native ETH.
 * It wraps ETH into WETH and interacts with the MultiPoolStrategy contract to perform the operations.
 */

contract ETHZapper is ReentrancyGuardUpgradeable{
    address constant public WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() { 
         // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Deposits ETH into the MultiPoolStrategy contract.
     * @param receiver The address to receive the shares.
     * @param strategyAddress The address of the MultiPoolStrategy contract to deposit into.
     * @return shares The amount of shares received.
     */
    function depositETH(address receiver, address strategyAddress) 
        external 
        nonReentrant 
        payable 
        returns (uint256 shares) 
    {
        if (!strategyUsesWETH(strategyAddress)) revert StrategyAssetNotWETH();
        if (msg.value == 0) revert EmptyInput();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        if (multipoolStrategy.paused()) revert StrategyPaused();
        
        uint256 amountETH = msg.value;
        
        // wrap ether and then call deposit
        IWETH(payable(WETH_ADDRESS)).deposit{ value: msg.value }();
        //// we need to approve the strategy to spend our WETH
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(multipoolStrategy.asset()), address(multipoolStrategy), 0);
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(multipoolStrategy.asset()), address(multipoolStrategy), amountETH);
        shares = multipoolStrategy.deposit(amountETH, address(this));
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(multipoolStrategy), receiver, shares);

        return shares;
    }
    /**
     * @dev Withdraws native ETH from the MultiPoolStrategy contract by assets.
     * @param assets The amount of ETH to withdraw.
     * @param receiver The address to receive the withdrawn native ETH.
     * @param minimumReceive The minimum amount of ETH to receive.
     * @param strategyAddress The address of the MultiPoolStrategy contract to withdraw from.
     * @return The amount of shares burned.
     * @notice to run this function user needs to approve the zapper to spend strategy token (shares)
     */

    function withdrawETH(
        uint256 assets,
        address receiver,
        uint256 minimumReceive,
        address strategyAddress
    )
        external
        nonReentrant 
        returns (uint256)
    {
        if (assets == 0) revert EmptyInput();
        require(receiver != address(0), "Receiver is zero address");

        if (!strategyUsesWETH(strategyAddress)) revert StrategyAssetNotWETH();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);

        /// get WETH balance before withdraw
        uint256 wethBalancePre = IWETH(payable(WETH_ADDRESS)).balanceOf(address(this));

        /// withdraw from strategy and get WETH
        uint256 shares = multipoolStrategy.withdraw(assets, address(this), msg.sender, minimumReceive);
        
        /// unwrap WETH to ETH and send to receiver
        console2.log("withdraw amount (param)", assets);
        console2.log("weth bal before", IWETH(payable(WETH_ADDRESS)).balanceOf(address(this)));

        // calculate actual withdraw amount (sometimes there's a few wei difference)
        assets = IWETH(payable(WETH_ADDRESS)).balanceOf(address(this)) - wethBalancePre;
        console2.log("withdraw amount (calculate)", assets);

        IWETH(payable(WETH_ADDRESS)).withdraw(assets);
        payable(address(receiver)).transfer(assets);
        return shares;
    }
    /**
     * @dev Withdraws native ETH from the MultiPoolStrategy contract by shares (redeem).
     * @param shares The amount of shares to redeem.
     * @param receiver The address to receive the redeemed ETH.
     * @param minimumReceive The minimum amount of ETH to receive.
     * @param strategyAddress The address of the MultiPoolStrategy contract to redeem from.
     * @return The amount of redeemed ETH received.
     * @notice to run this function user needs to approve the zapper to spend strategy token (shares)
     */

    function redeemETH(
        uint256 shares,
        address receiver,
        uint256 minimumReceive,
        address strategyAddress
    )
        external
        nonReentrant 
        returns (uint256)
    {
        if (shares == 0) revert EmptyInput();
        require(receiver != address(0), "Receiver is zero address");
        if (!strategyUsesWETH(strategyAddress)) revert StrategyAssetNotWETH();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        // redeem shares and get WETH from strategy
        uint256 received = multipoolStrategy.redeem(shares, address(this), msg.sender, minimumReceive);
        // unwrap WETH to ETH and send to receiver
        IWETH(payable(WETH_ADDRESS)).withdraw(received);
        payable(address(receiver)).transfer(received);
        return received;
    }

    /**
     * @dev Checks if the MultiPoolStrategy contract uses WETH as its asset.
     * @param strategyAddress The address of the MultiPoolStrategy contract to check.
     * @return True if the MultiPoolStrategy contract uses WETH as its asset, false otherwise.
     */
    function strategyUsesWETH(address strategyAddress) public view returns (bool) {
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        return multipoolStrategy.asset() == address(WETH_ADDRESS);
    }

    receive() external payable {
         // solhint-disable-previous-line no-empty-blocks
     }
}