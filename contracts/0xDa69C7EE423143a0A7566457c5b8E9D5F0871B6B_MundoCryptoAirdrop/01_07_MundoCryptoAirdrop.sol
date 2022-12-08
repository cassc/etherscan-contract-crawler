// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title   MundoCryptoAirdrop
 * @notice  MundoCryptoAirdrop allows the owner to distribute reward tokens to different addresses.
 *          It also allows to reclaim tokens from the contract to avoid locking of the tokens
 *          inside the contract.
 */
contract MundoCryptoAirdrop is Ownable {
    // using SafeERC20 library to handle token transfer.
    using SafeERC20 for IERC20;

    // Token used for airdrop.
    IERC20 public immutable airdroppingToken;

    /**
     * @dev Revert with an error when the address is the zero address.
     */
    error ZeroAddress();
    /**
     * @dev Revert if the length of two arrays are not same.
     */
    error ParamslengthMismatch();
    /**
     * @dev Revert with an error when the param is zero valued.
     * @param paramName The parameter which is zero valued.
     */
    error ZeroValuedParam(string paramName);

    /**
     * @notice Set the ERC20 token which will be distributed.
     * @param _token The ERC20 token which will be distributed.
     */
    constructor(IERC20 _token) {
        if (address(_token) == address(0)) {
            revert ZeroAddress();
        }

        airdroppingToken = _token;
    }

    /**
     * @dev External function to distribute tokens from the contract.
     *      Only the caller with owner access can call the function.
     *
     * @param _recipients   The recipients addresses to which the tokens are being distributed.
     * @param _amounts      The token amounts to send to each recipient addresses.
     *
     */
    function distributeRewards(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyOwner {
        // if the lengths of both the arrays are different
        // then revert.
        if (_recipients.length != _amounts.length) {
            revert ParamslengthMismatch();
        }

        uint256 len = _recipients.length;
        for (uint256 i = 0; i < len; ) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];

            // if the recipient is zero address, revert.
            if (recipient == address(0)) {
                revert ZeroAddress();
            }
            // if the amount is zero, revert.
            if (amount == 0) {
                revert ZeroValuedParam("amount");
            }

            // transfer the tokens.
            airdroppingToken.safeTransfer(recipient, amount);

            // increment the loop counter
            unchecked {
                ++i;
            }
        }
    }
}