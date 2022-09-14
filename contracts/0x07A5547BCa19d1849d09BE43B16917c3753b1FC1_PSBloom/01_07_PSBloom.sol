// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface IWETH {
    function withdraw(uint256) external;

    function balanceOf(address) external returns (uint256);
}

contract PSBloom is PaymentSplitter {
    address[] private _distributions = [
        0x7812952e06B6D539CB4E6a6f72b2E2260AB950f9,
        0xA4D872934e813BD15b55C77BfD6da99Ff3e9C35e
    ];

    uint256[] private _Shares = [97, 3];

    event WETHconversion(uint256 amount, address caller);
    event ERC20conversion(uint256 amount, address caller);

    constructor() PaymentSplitter(_distributions, _Shares) {}

    function distributeAll() external {
        for (uint256 i = 0; i < _distributions.length; i++) {
            release(payable(_distributions[i]));
        }
    }

    function convertWETHintoETH() external {
        address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uint256 wethBalance = IWETH(wethAddress).balanceOf(address(this));
        IWETH(wethAddress).withdraw(wethBalance);
        emit WETHconversion(wethBalance, msg.sender);
    }

    function transferERC20Tokens(
        address erc20Address,
        address receiver,
        uint256 amount
    ) external {
        require(
            msg.sender == 0x7812952e06B6D539CB4E6a6f72b2E2260AB950f9 ||
                msg.sender == 0xA4D872934e813BD15b55C77BfD6da99Ff3e9C35e,
            "only team"
        );
        bool s = IERC20(erc20Address).transfer(receiver, amount);
        require(s, "tx failed");
        emit ERC20conversion(amount, msg.sender);
    }
}