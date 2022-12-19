// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract TwitFi is ERC20, Pausable, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => bool) private pairs;
    uint8 private constant _decimals = 9;
    bool private inSwap = false;
    bool private tradingOpen = false;
    address private uniswapV2Pair;

    uint256 public _burnFee = 25;
    uint256 public _liquidityFee = 20;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }

    function decimals() public override pure returns (uint8) {
        return _decimals;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function addPairs(address toPair, bool _enable) public onlyOwner {
        require(!pairs[toPair], "This pair is already excluded");

        pairs[toPair] = _enable;
    }

    function pair(address _pair) public view virtual onlyOwner returns (bool) {
        return pairs[_pair];
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setBurnFee(uint256 burnFee) external onlyOwner {
        _burnFee = burnFee;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual whenNotPaused override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(from != address(this) && pairs[to]) {
            uint256 burnAmount = amount.mul(_burnFee).div(10**3);
            uint256 liquidityAmount = amount.mul(_liquidityFee).div(10**3);
            if(liquidityAmount > 0) {
                _swapTransfer(from, address(this), liquidityAmount);
            }
            if(burnAmount > 0) {
                _swapBurn(from, burnAmount);
            }
            if(!inSwap && liquidityAmount > 0) {
                swapAndLiquify(liquidityAmount);
            }
            super._transfer(from, to, amount.sub(burnAmount).sub(liquidityAmount));
        } else {
            super._transfer(from, to, amount);
        }
    }

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualBurn(uint256 amount) public virtual onlyOwner {
        _burn(address(this), amount);
    }
    
    function swapAndLiquify(uint256 _tokenBalance) private lockTheSwap {
        uint256 half = _tokenBalance.div(2);
        uint256 otherHalf = _tokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        addLiquidity(otherHalf, address(this).balance.sub(initialBalance));
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override{
        super._beforeTokenTransfer(from, to, amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        tradingOpen = true;
        pairs[uniswapV2Pair] = true;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = payable(owner()).call {
            value: amount
        }("");

        require(success, "Failed to send Ether");
    }

    receive() external payable {}
}