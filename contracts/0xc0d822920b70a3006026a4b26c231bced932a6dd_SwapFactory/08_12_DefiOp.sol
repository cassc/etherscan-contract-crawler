// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./errors.sol";
import {IDefiOp} from "./interfaces/IDefiOp.sol";

abstract contract DefiOp is IDefiOp {
    using SafeERC20 for IERC20;

    address public owner;
    address public factory;

    function init(address owner_) external {
        if (owner != address(0)) {
            revert AlreadyInitialised();
        }
        owner = owner_;
        factory = msg.sender;

        _postInit();
    }

    function _postInit() internal virtual {}

    /**
     * @notice Withdraw ERC20 to owner
     * @dev This function withdraw all token amount to owner address
     * @param token ERC20 token address
     */
    function withdrawERC20(address token) external onlyOwner {
        _withdrawERC20(IERC20(token));
    }

    /**
     * @notice Withdraw native coin to owner (e.g ETH, AVAX, ...)
     * @dev This function withdraw all native coins to owner address
     */
    function withdrawNative() public onlyOwner {
        _withdrawETH();
    }

    receive() external payable {}

    // internal functions
    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
}