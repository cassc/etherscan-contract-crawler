// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureErc20Payable is
Ownable
{
    receive() external payable {}

    function withdrawEther(uint256 amount)
    external
    payable
    onlyOwner
    {
        sendEtherTo(payable(msg.sender), amount);
    }

    function withdrawErc20(address tokenAddress, uint256 amount)
    external
    onlyOwner
    {
        sendErc20FromThisTo(tokenAddress, msg.sender, amount);
    }

    //    function transferErc20(address tokenAddress, address from, address to, uint256 amount)
    //    external
    //    onlyOwner
    //    {
    //        transferErc20FromTo(tokenAddress, from, to, amount);
    //    }
    //
    //    // transfer ERC20 from `from` to `to` with allowance `address(this)`
    //    function transferErc20FromTo(address tokenAddress, address from, address to, uint256 amount)
    //    internal
    //    {
    //        bool isSucceed = IERC20(tokenAddress).transferFrom(from, to, amount);
    //        require(isSucceed, "Failed to transfer token");
    //    }

    // send ERC20 from `address(this)` to `to`
    function sendErc20FromThisTo(address tokenAddress, address to, uint256 amount)
    internal
    {
        bool isSucceed = IERC20(tokenAddress).transfer(to, amount);
        require(isSucceed, "Failed to send token");
    }

    // send ether from `msg.sender` to payable `to`
    function sendEtherTo(address payable to, uint256 amount)
    internal
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool isSucceed, /* bytes memory data */) = to.call{value : amount}("");
        require(isSucceed, "Failed to send Ether");
    }
}