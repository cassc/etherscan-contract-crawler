/*
*   https://troncn.ink/
*   https://twitter.com/TronCnERC
*   https://t.me/TronCnErc
*/

// SPDX-License-Identifier: MIT

import "./@openzeppelin-contracts/contracts/ERC20/ERC20.sol";
import "./@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./@uniswap/IUniswapV2Router02.sol";
import "./@uniswap/IUniswapV2Factory.sol";

pragma solidity ^0.8.21;

contract TRONCN is ERC20, Ownable {
    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    address private _marketingWallet;
    uint256 public _maxTransactionAmount;
    uint256 public _maxWallet;
    bool public _limitsInEffect = true;
    uint256 public constant _tax = 1;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    constructor() payable ERC20(unicode"Tron | 波场", unicode"波场") {
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uint256 totalSupply = 1_000_000_000 * 1e18;
        _maxTransactionAmount = (totalSupply * 2) / 100;
        _maxWallet = (totalSupply * 2) / 100;

        _marketingWallet = _msgSender();

        _isExcludedMaxTransactionAmount[address(_uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[_marketingWallet] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_marketingWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _mint(owner(), totalSupply);
    }


    function disableLimitAmounts() external onlyOwner returns (bool) {
        _limitsInEffect = false;
        return true;
    }

    function setMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        _maxTransactionAmount = newNum * 1e18;
    }

    function setMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        _maxWallet = newNum * 1e18;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuy = from == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[to];
        bool isSell = to == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[from];

        uint256 fee;

        if ((isBuy || isSell) && !_isExcludedFromFees[from]) {
            fee = amount * _tax / 100;
        }

        bool isBurn = to == address(0) || to == address(0xdead);

        if (_limitsInEffect && !isBurn) {
            if (isBuy) {
                require(amount <= _maxTransactionAmount, 'Buy transfer amount exceeds the maxTransactionAmount.');
                require(amount + balanceOf(to) <= _maxWallet, 'Max wallet exceeded');
            }
            if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount + balanceOf(to) <= _maxWallet, 'Max wallet exceeded');
            }
        }

        if (fee > 0) {
            super._transfer(from, _marketingWallet, fee);
            amount = amount - fee;
        }

        super._transfer(from, to, amount);
    }

    function burn(uint256 _amount) external {
        super._burn(_msgSender(), _amount);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function SendETH() external onlyOwner {
        (bool success,) = address(_marketingWallet).call{
                value: address(this).balance
            }("");
        require(success);
    }

    receive() external payable {}
}