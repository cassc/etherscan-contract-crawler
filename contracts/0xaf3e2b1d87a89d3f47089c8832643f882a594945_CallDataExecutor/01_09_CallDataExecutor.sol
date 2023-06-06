// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/UniversalERC20.sol";

contract CallDataExecutor is Ownable, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    event Received(address, uint);

    function execute(
        IERC20 token,
        address callTo,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    )
        external
        payable
        nonReentrant
    {
        uint256 ethAmount = 0;
        if (token.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmount = amount;
        } else {
            require(token.balanceOf(address(this)) >= amount, "ERC20 Token balance is insufficient");
            token.universalApprove(approveAddress, amount);
        }

        bool success;
        if (gasLimit > 0) {
            (success, ) = callTo.call{ value: ethAmount, gas: gasLimit }(payload);
        } else {
            (success, ) = callTo.call{ value: ethAmount }(payload);
        }

        require(success, " execution failed");
        if (contractOutputsToken != address(0)) {
            uint256 outputTokenAmount =  IERC20(contractOutputsToken).balanceOf(address(this));
            if (outputTokenAmount > 0) {
                IERC20(contractOutputsToken).universalTransfer(recipient, outputTokenAmount);
            }
        }

        // send the remain amount to the recipient.
        if (token.isETH()) {
            if (address(this).balance > 0)
                payable(recipient).transfer(address(this).balance);
        } else {
            if (token.balanceOf(address(this)) > 0)
                token.universalTransfer(recipient, token.balanceOf(address(this)));
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}