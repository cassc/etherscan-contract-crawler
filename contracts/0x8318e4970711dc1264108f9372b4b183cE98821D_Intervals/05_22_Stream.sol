// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Pausable } from "../utils/Pausable.sol";
import { Ownable } from "../utils/Ownable.sol";

import { IStream } from "./interfaces/IStream.sol";
import { VersionedContract } from "../VersionedContract.sol";

/// @title Stream
/// @author Matthew Harrison
/// @notice The base contract for all streams
abstract contract Stream is IStream, VersionedContract, Pausable, Ownable {
    using SafeERC20 for address;

    /// @notice The token used for stream payments
    address public token;
    /// @notice The address of the botDAO
    address public botDAO;
    /// @notice The recipient address
    address public recipient;

    /// @notice Withdraw funds from smart contract, only the owner can do this.
    function withdraw() external onlyOwner {
        uint256 bal;
        if (token == address(0)) {
            bal = address(this).balance;
            (bool success, ) = address(owner()).call{ value: bal }("");
            if (!success) {
                revert TRANSFER_FAILED();
            }
        } else {
            bal = IERC20(token).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(token), owner(), bal);
        }

        emit Withdraw(address(this), bal);
    }

    /// @notice Pause the whole contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Pause the whole contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the balance of the contract
    /// @return The balance of the contract
    function balance() external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /// @notice Change the recipient address
    /// @param newRecipient The new recipient address
    function changeRecipient(address newRecipient) external {
        if (msg.sender == recipient) {
            recipient = newRecipient;
            emit RecipientChanged(msg.sender, newRecipient);
        } else {
            revert ONLY_RECIPIENT();
        }
    }

    /// @notice Distribute payout
    /// @param _to Account receieve transfer
    /// @param _amount Amount to transfer
    function _distribute(address _to, uint256 _amount) internal {
        if (token != address(0)) {
            /// ERC20 transfer
            SafeERC20.safeTransfer(IERC20(token), _to, _amount);
        } else {
            (bool success, ) = address(_to).call{ value: _amount }("");
            if (!success) {
                revert TRANSFER_FAILED();
            }
        }
    }

    receive() external payable {
        if (token != address(0)) {
            revert NO_ETHER();
        }
    }
}