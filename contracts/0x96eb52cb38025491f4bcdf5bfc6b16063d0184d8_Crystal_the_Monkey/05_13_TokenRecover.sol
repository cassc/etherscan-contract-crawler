// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract TokenRecover is Ownable {

    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "TokenRecover: Cannot recover this token");

        IERC20(tokenAddress).transfer(owner(), amount);
    }
}