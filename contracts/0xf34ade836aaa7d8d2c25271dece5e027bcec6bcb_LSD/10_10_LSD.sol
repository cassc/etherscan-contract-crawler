// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract LSD is ERC20, Ownable {
    address private constant DEAD = address(0xdead);
    bool private _addingLP;

    mapping(address => bool) private _isLimitless;

    uint256 public maxTx = 1;
    uint256 public maxWallet = 2;
    bool public enableLimits = true;

    uint256 public launchTime;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor() ERC20('LSD', 'LSD')  {
        _mint(address(this), 1_000_000_000 * 10 ** 18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniswapV2Router = _uniswapV2Router;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;
    }

    function launchAndBurnLp() external payable onlyOwner {
        require(launchTime == 0, 'already launched');
        _addingLP = true;
        _addLp(totalSupply(), msg.value);
        launchTime = block.timestamp;
        _addingLP = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 contractTokenBalance = balanceOf(address(this));

        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;

        if (_isSwap && enableLimits) {
            bool _skipCheck = _addingLP || _isLimitless[recipient] || _isLimitless[sender];
            uint256 _maxTx = totalSupply() * maxTx / 100;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / 100;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            DEAD,
            block.timestamp
        );
    }

    receive() external payable {}

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 1, 'max wallet cannot be below 1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 1, 'max tx cannot be below 1%');
        maxTx = _maxTx;
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

}