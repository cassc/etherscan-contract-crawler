//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Kenshi
 * @notice This is a basic implementation of the ERC20 protocol.
 * It includes an ownable feature, which allows for a recovery mechanism
 * for tokens that are accidentally sent to the contract address.
 * Only the owner of the contract can retrieve these tokens to prevent
 * unauthorized access.
 * @dev See https://eips.ethereum.org/EIPS/eip-20 for details
 */
contract Kenshi is ERC20, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Constructor to deploy the Kenshi token with `totalSupply`
     * tokens minted.
     * @dev Mints the total supply of tokens and assigns them to the owner of
     * the contract. Token name is "Kenshi" and token symbol is "KNS".
     * @param totalSupply The number of tokens to initially mint.
     */
    constructor(uint256 totalSupply) ERC20("Kenshi", "KNS") {
        _mint(msg.sender, totalSupply);
    }

    /**
     * @dev Sends `amount` of ERC20 `token` from contract address
     * to `recipient`
     *
     * Useful if someone sent ERC20 tokens to the contract address by mistake.
     *
     * @param token The address of the ERC20 token contract.
     * @param recipient The address to which the tokens should be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function recoverERC20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
    }
}