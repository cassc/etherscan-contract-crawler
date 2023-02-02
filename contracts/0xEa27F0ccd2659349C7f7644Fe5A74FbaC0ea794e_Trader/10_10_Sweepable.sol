// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Sweepable is Ownable {
    using SafeERC20 for IERC20;

    event SetSweepRecipient(address recipient);
    event SweepToken(address indexed token, uint256 amount);
    event SweepNative(uint256 amount);

    address payable private recipient;

    constructor(address payable _recipient) {
        _setSweepRecipient(_recipient);
    }

    // Sweep an ERC20 token to the owner
    function sweepToken(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(recipient, amount);
        emit SweepToken(address(token), amount);
    }

    function sweepToken(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(recipient, amount);
        emit SweepToken(address(token), amount);
    }

    // sweep native token to the recipient (public function)
    function sweepNative() external {
        uint256 amount = address(this).balance;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
        emit SweepNative(amount);
    }

    function sweepNative(uint256 amount) external onlyOwner {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
        emit SweepNative(amount);
    }

    function getSweepRecipient() public view returns (address payable) {
        return recipient;
    }

    function _setSweepRecipient(address payable _recipient) internal {
        recipient = _recipient;
        emit SetSweepRecipient(recipient);
    }
}