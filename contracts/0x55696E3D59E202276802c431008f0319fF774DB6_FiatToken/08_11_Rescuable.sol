// SPDX-License-Identifier: MIT
// Forked from https://github.com/centrehq/centre-tokens/blob/master/contracts/v1/Ownable.sol

pragma solidity ^0.8.0;

import {Ownable} from "Ownable.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";

/**
 * @title Rescuable Contract
 * @dev Allows tokens to be rescued by a "rescuer" role
 */
contract Rescuable is Ownable {
    using SafeERC20 for IERC20;

    address public rescuer;

    event RescuerChanged(address indexed newRescuer);

    /**
     * @notice Revert if called by any account other than the rescuer.
     */
    modifier onlyRescuer() {
        require(msg.sender == rescuer, "Rescuable: caller is not the rescuer");
        _;
    }

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external onlyRescuer {
        tokenContract.safeTransfer(to, amount);
    }

    /**
     * @notice Assign the rescuer role to a given address.
     * @param newRescuer New rescuer's address
     */
    function updateRescuer(address newRescuer) external onlyOwner {
        require(
            newRescuer != address(0),
            "Rescuable: new rescuer is the zero address"
        );
        rescuer = newRescuer;
        emit RescuerChanged(newRescuer);
    }
}