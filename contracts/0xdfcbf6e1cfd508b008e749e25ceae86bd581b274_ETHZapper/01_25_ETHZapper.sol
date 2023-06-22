pragma solidity ^0.8.10;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { WETH as IWETH } from "solmate/tokens/WETH.sol";
import { MultiPoolStrategy as IMultiPoolStrategy } from "./MultiPoolStrategy.sol";

//// ERRORS
error StrategyPaused();
error StrategyAssetNotWETH();
error EmptyInput();
/**
 * @title ETHZapper
 * @dev This contract allows users to deposit, withdraw, and redeem into a MultiPoolStrategy contract using native ETH.
 * It wraps ETH into WETH and interacts with the MultiPoolStrategy contract to perform the operations.
 */

contract ETHZapper {
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() { }

    /**
     * @dev Deposits ETH into the MultiPoolStrategy contract.
     * @param receiver The address to receive the shares.
     * @param strategyAddress The address of the MultiPoolStrategy contract to deposit into .
     * @return shares The amount of shares received.
     */
    function depositETH(address receiver, address strategyAddress) public payable returns (uint256 shares) {
        if (msg.value == 0) revert EmptyInput();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        if (multipoolStrategy.paused()) revert StrategyPaused();
        uint256 assets = msg.value;
        // wrap ether and then call deposit
        IWETH(payable(multipoolStrategy.asset())).deposit{ value: msg.value }();
        //// we need to approve the strategy to spend our WETH
        IERC20(multipoolStrategy.asset()).approve(address(multipoolStrategy), 0);
        IERC20(multipoolStrategy.asset()).approve(address(multipoolStrategy), assets);
        shares = multipoolStrategy.deposit(assets, address(this));
        multipoolStrategy.transfer(receiver, shares);
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
        public
        returns (uint256)
    {
        if (assets == 0) revert EmptyInput();
        if (!strategyUsesWETH(strategyAddress)) revert StrategyAssetNotWETH();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        /// withdraw from strategy and get WETH
        uint256 shares = multipoolStrategy.withdraw(assets, address(this), msg.sender, minimumReceive);
        /// unwrap WETH to ETH and send to receiver
        IWETH(payable(multipoolStrategy.asset())).withdraw(assets);
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
        public
        returns (uint256)
    {
        if (shares == 0) revert EmptyInput();
        if (!strategyUsesWETH(strategyAddress)) revert StrategyAssetNotWETH();
        IMultiPoolStrategy multipoolStrategy = IMultiPoolStrategy(strategyAddress);
        // redeem shares and get WETH from strategy
        uint256 received = multipoolStrategy.redeem(shares, address(this), msg.sender, minimumReceive);
        // unwrap WETH to ETH and send to receiver
        IWETH(payable(multipoolStrategy.asset())).withdraw(received);
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

    receive() external payable { }
}