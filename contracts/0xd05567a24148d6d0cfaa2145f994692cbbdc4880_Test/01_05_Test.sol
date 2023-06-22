// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface USDTInterface {
    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Test {

    ERC20 public usdtERC20 = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    USDTInterface public usdtInt = USDTInterface(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    function testERC20(uint256 _amount) external {
        require(usdtERC20.transferFrom(msg.sender, address(this), _amount), "pay error");
    }

    function testInterface(uint256 _amount) external {
        require(usdtInt.transferFrom(msg.sender, address(this), _amount), "pay error");
    }

    function withdrawERC20() external {
        require(usdtERC20.transfer(msg.sender, usdtERC20.balanceOf(address(this))), "ERC20 transfer failed");
    }

    function withdrawUSDTInt() external {
        require(usdtInt.transfer(msg.sender, usdtInt.balanceOf(address(this))), "ERC20 transfer failed");
    }

}