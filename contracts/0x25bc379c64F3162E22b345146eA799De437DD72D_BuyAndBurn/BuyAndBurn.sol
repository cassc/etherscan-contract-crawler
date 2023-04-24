/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BuyAndBurn {

    address public token;
    address public owner;
    address public constant deadAddress = address(0xdead);
    IUniswapV2Router public uniswapRouter;
	
	event ownershipTransferred(address indexed from, address indexed too);

    constructor() {
        owner = msg.sender;        
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    function buytokens(uint _ethAmount) external onlyOwner {
        uint256 amountTobeSwapped = _ethAmount;
        require(amountTobeSwapped != 0, "ETH != 0");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        // swap tokens
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountTobeSwapped
        }(0, path, address(this), block.timestamp + 1800);
    }

    // burn token
    function burnTokens(IERC20 Tokens, uint256 _value) external onlyOwner {
        Tokens.transfer(deadAddress, _value);
    }

    // to draw out tokens
    function transferTokens(IERC20 Tokens, uint256 _value) external onlyOwner {
        Tokens.transfer(msg.sender, _value);
    }

    function withdrawEth(uint256 amountInWei) external onlyOwner {
        payable(msg.sender).transfer(amountInWei);
    }

    function updateTokenAddress(address newToken) external onlyOwner {
        token = newToken;
    }
	
	function setRouter(address _uniswapRouter) external onlyOwner {
		uniswapRouter = IUniswapV2Router(_uniswapRouter);
	}
	
	function transferOwnership(address _newOwner) external onlyOwner {
		address previous = owner;
		owner = _newOwner;
		emit ownershipTransferred(previous,_newOwner);
	}
}