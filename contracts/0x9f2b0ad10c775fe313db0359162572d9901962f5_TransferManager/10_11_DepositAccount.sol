// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @title DepositAccount
 * @dev A contract that represents a deposit account for ETH and ERC20 tokens.
 * It allows the owner to transfer the ETH and ERC20 tokens to other addresses.
 */
contract DepositAccount is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    error SendingAmountError(uint256 available, uint256 required);
    constructor() {
        _disableInitializers();
    }

    function initializeDepositAccount(address owner) external initializer {
        __Ownable_init();
        transferOwnership(owner);
    }

    /**
     * @dev Transfers ETH from the contract to the specified address.
     * Only the owner can call this function.
     * @param to Address to transfer the ETH to.
     */

    function transferETH(
        address payable to,
        uint256 amount
    ) external onlyOwner {
        // onlyOwner prevents reentrancy
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) 
            revert SendingAmountError({
                    available: to.balance,
                    required: amount
                });
    }

    /**
     * @dev Transfers ERC20 tokens from the contract to the specified address.
     * Only the owner can call this function.
     * @param tokenAddress Address of the ERC20 token contract.
     * @param to Address to transfer the ERC20 tokens to.
     */

    function transferERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        // onlyOwner prevents reentrancy
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    receive() external payable {}
}