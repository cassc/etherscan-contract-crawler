// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Rebalancer {
    using SafeERC20 for IERC20;
    address public rebalanceManager;

    event NewRebalanceManagerSet(address newRebalanceManager);
    event RebalanceWithdrawn(address token, uint256 amount, uint256 timestamp);
    event RebalanceDeposit(address token, uint256 amount, uint256 timestamp);

    modifier onlyRebalanceManager() {
        require(msg.sender == rebalanceManager, "not allowed");

        _;
    }
    modifier assetsListHaveSameLength(address[] calldata _tokens, uint256[] calldata _amounts) {
        require(_tokens.length == _amounts.length, "incorrect params length");

        _;
    }

    constructor() {
        rebalanceManager = msg.sender;
    }

    /// @dev Withdraws tokens from the contract to the rebalance manager
    /// @param tokens Array of tokens to withdraw
    /// @param amounts Array of amounts to withdraw
    function _withdrawForRebalance(address[] calldata tokens, uint256[] calldata amounts)
        internal
        onlyRebalanceManager
        assetsListHaveSameLength(tokens, amounts)
    {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            IERC20(tokens[i]).safeTransfer(rebalanceManager, amounts[i]);

            emit RebalanceWithdrawn(tokens[i], amounts[i], block.timestamp);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Deposits tokens from the rebalance manager to the contract
    /// @param tokens Array of tokens to deposit
    /// @param amounts Array of amounts to deposit
    function _rebalance(address[] calldata tokens, uint256[] calldata amounts)
        internal
        onlyRebalanceManager
        assetsListHaveSameLength(tokens, amounts)
    {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            IERC20(tokens[i]).safeTransferFrom(rebalanceManager, address(this), amounts[i]);

            emit RebalanceDeposit(tokens[i], amounts[i], block.timestamp);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Sets new rebalance manager
    /// @param newRebalanceManager New rebalance manager address
    function setNewRebalanceManager(address newRebalanceManager) external onlyRebalanceManager {
        rebalanceManager = newRebalanceManager;

        emit NewRebalanceManagerSet(newRebalanceManager);
    }
}