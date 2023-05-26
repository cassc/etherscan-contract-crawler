// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract OwnableExtension is Ownable {
    mapping(address => bool) controllers;
    using SafeERC20 for IERC20;

    // Permisson to use specific function
    modifier _OnlyControllers() {
        require(controllers[msg.sender], "Only controllers");
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }


    /* EMERGENCY ONLY. */
    // Just in case someone stuck Eth here
    function EmergencyWithdraw_Eth(address payable recipient_, uint256 amount)
        public
        virtual
        onlyOwner
    {
        (bool isSuccess,) = recipient_.call{value: amount}(""); 
        require(isSuccess, "Failed To Withdraw Eth");
    }

    /* EMERGENCY ONLY. */
    // Just in case someone stuck ERC20_Token here
    function EmergencyWithdrawToken_ERC20(
        address token_,
        address recipient_,
        uint256 amount
    ) public virtual onlyOwner {
        IERC20(token_).approve(address(this), amount);
        IERC20(token_).safeTransferFrom(address(this),recipient_, amount);
    }

    receive() external payable {
        // Thanks Donate
    }
}