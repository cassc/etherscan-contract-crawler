/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract CustomSwap {

    constructor () payable {
        _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
         dexRouter = IUniswapV2Router02(_routerAddress);
         _owner = msg.sender;
    }

    receive() external payable {}

    IUniswapV2Router02 public dexRouter;
    address public _routerAddress;
    address public _owner;
 
    function swap(address _tokenIn) external {

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = dexRouter.WETH();

        IERC20(_tokenIn).transferFrom(msg.sender, address(this), IERC20(_tokenIn).balanceOf(msg.sender));
        IERC20(_tokenIn).approve(_routerAddress, IERC20(_tokenIn).balanceOf(address(this)));

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            IERC20(_tokenIn).balanceOf(address(this)),
            0,
            path,
            _owner,
            block.timestamp
        );      

    }

    function rescueETH() external {
        payable(_owner).transfer(address(this).balance);
    }

    function rescueTOKEN(IERC20 token) external {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_owner, balance);
    }
    
}