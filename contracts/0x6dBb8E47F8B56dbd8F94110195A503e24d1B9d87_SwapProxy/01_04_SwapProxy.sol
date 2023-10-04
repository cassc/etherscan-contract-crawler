// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SwapProxy is Ownable, ReentrancyGuard {
    address public immutable CLIPPER_POOL;

    receive() external payable {}

    constructor(address pool) {
        CLIPPER_POOL = pool;
    }

    function execute(bytes calldata data, address tokenAddress, uint256 amount) external payable onlyOwner nonReentrant {
        if (tokenAddress != address(0) && amount > 0) {
            require(IERC20(tokenAddress).transferFrom(msg.sender, address(CLIPPER_POOL), amount), "Token transfer failed");
        }
        
        (bool success, bytes memory returnData) = address(CLIPPER_POOL).call{value: msg.value}(data);
        if (!success) {
            if (returnData.length > 0) {
                // Decoding the revert reason from the error bytes
                string memory reason = abi.decode(returnData, (string));
                revert(reason);
            } else {
                revert("Unknown error");
            }
        }
    }

    function withdraw(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            payable(owner()).transfer(address(this).balance);
        } else {
            // Withdraw tokens
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No tokens to withdraw");
            require(token.transfer(owner(), balance), "Token transfer failed");
        }
    }
}