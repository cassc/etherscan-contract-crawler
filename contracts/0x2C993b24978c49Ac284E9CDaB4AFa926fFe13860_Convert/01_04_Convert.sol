// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Convert is Ownable {
    // the old non-upgradable token used for the conversion
    IERC20 public immutable oldToken;

    // the new upgradable token used for the conversion
    IERC20 public immutable newToken;

    // whether the contract is closed (converting is not possible anymore when the contract is closed)
    bool public closed = false;

    error AlreadyClosed();
    error NotClosed();
    error NotEnoughOldTokenBalance();
    error NotEnoughReserves();
    error OldTokenTransferFailed();
    error ZeroAddress();

    event Closed();
    event Converted(address indexed account, uint256 amount);

    /**
     * @param oldToken_ old token address
     * @param newToken_ new token address
     */
    constructor(IERC20 oldToken_, IERC20 newToken_) {
        if (address(oldToken_) == address(0) || address(newToken_) == address(0)) {
            revert ZeroAddress();
        }
        oldToken = oldToken_;
        newToken = newToken_;
    }

    /**
     * @notice Converts the old tokens to the new ones by transferring the old tokens
     *         to the contract, and then the contract will send the new tokens back.
     * @param amount amount of tokens to convert
     */
    function convert(uint256 amount) external {
        if (closed) {
            revert AlreadyClosed();
        }
        if (oldToken.balanceOf(msg.sender) < amount) {
            revert NotEnoughOldTokenBalance();
        }
        if (newToken.balanceOf(address(this)) < amount) {
            revert NotEnoughReserves();
        }
        if (!oldToken.transferFrom(msg.sender, address(this), amount)) {
            revert OldTokenTransferFailed();
        }
        require(newToken.transfer(msg.sender, amount), "transfer failed");
        emit Converted(msg.sender, amount);
    }

    /**
     * @notice Closes the contract. The closed contract does not accept conversions anymore and allows a full
     *         withdrawal by the owner. Only the owner is allowed to close the contract.
     */
    function close() external onlyOwner {
        if (!closed) {
            closed = true;
            emit Closed();
        }
    }

    /**
     * @notice Transfers the remaining tokens balance to the owner when the contract is closed.
     *         Only the owner is allowed to withdraw.
     */
    function withdraw() external onlyOwner {
        if (!closed) {
            revert NotClosed();
        }
        uint256 reserves = newToken.balanceOf(address(this));
        newToken.transfer(owner(), reserves);
    }
}