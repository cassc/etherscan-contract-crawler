/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPancakeSwapRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function WETH() external pure returns (address);
}

contract TexasIKE {
    address public routerAddress;
    address public owner;
    mapping(address => bool) public isAllowed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(address _routerAddress) {
        routerAddress = _routerAddress;
        owner = msg.sender;
        isAllowed[owner] = true;
    }

    function setAllowed(address _address, bool _isAllowed) external onlyOwner {
        isAllowed[_address] = _isAllowed;
    }

    function buyToken(address _tokenAddress, uint256 _minimumAmount) external payable {
        require(isAllowed[msg.sender], "You are not allowed to call this function.");

        address[] memory path = new address[](2);
        path[0] = IPancakeSwapRouter(routerAddress).WETH();
        path[1] = _tokenAddress;

        uint256[] memory amounts = IPancakeSwapRouter(routerAddress).getAmountsOut(msg.value, path);
        uint256 tokenAmount = amounts[amounts.length - 1];

        require(tokenAmount >= _minimumAmount, "Received amount is less than minimum amount.");

        IPancakeSwapRouter(routerAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            _minimumAmount,
            path,
            address(this),
            block.timestamp + 3600
        );
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "Token balance is zero.");

        token.transfer(owner, tokenBalance);
    }

    function withdrawBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}