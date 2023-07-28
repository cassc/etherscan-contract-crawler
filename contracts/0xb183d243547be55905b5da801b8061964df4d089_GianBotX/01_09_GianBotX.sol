/*
*   https://gianbot.xyz/
*   https://t.me/gianbotx_xyz
*   https://t.me/gianbotx_news
*   https://twitter.com/gianbot_x
*/

// SPDX-License-Identifier: MIT

import "./@openzeppelin-contracts/contracts/ERC20/ERC20.sol";
import "./@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./@uniswap/IUniswapV2Router02.sol";
import "./@uniswap/IUniswapV2Factory.sol";

pragma solidity ^0.8.19;

contract GianBotX is ERC20, Ownable {
    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    bool private _swappingBack;
    address private _marketingWallet = 0xbB82460aE32F45eEa72f7c046D2946a62B3ce194;
    uint256 public _maxTransactionAmount;
    uint256 public _maxWallet;
    bool public _limitsInEffect = true;
    uint256 public constant _tax = 2;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() payable ERC20("GianBotX", "GBOTX") {
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(_uniswapV2Pair), true);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uint256 totalSupply = 10_000_000 * 1e18;
        _maxTransactionAmount = (totalSupply * 2) / 100;
        _maxWallet = (totalSupply * 2) / 100;

        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(_marketingWallet, true);
        excludeFromMaxTransaction(address(0xdead), true);
        _mint(owner(), totalSupply);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    external
    onlyOwner
    {
        require(
            pair != _uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function removeLimits() external onlyOwner returns (bool) {
        _limitsInEffect = false;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        _maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        _maxWallet = newNum * 1e18;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
    public
    onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuy = from == _uniswapV2Pair &&
                !_isExcludedMaxTransactionAmount[to];
        bool isSell = to == _uniswapV2Pair &&
                !_isExcludedMaxTransactionAmount[from];

        bool isBurn = to == address(0) || to == address(0xdead);
        bool isSkipLimits = isBurn || _swappingBack;

        if (_limitsInEffect && !isSkipLimits) {
            if (isBuy) {
                require(
                    amount <= _maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= _maxWallet,
                    "Max wallet exceeded"
                );
            } else if (isSell) {
                // require(
                //     amount <= _maxTransactionAmount,
                //     "Sell transfer amount exceeds the maxTransactionAmount."
                // );
            } else if (
                !_isExcludedMaxTransactionAmount[to] &&
            !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount + balanceOf(to) <= _maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        transferInternal(from, to, amount);
    }

    function transferInternal(
        address from,
        address to,
        uint256 amount
    ) private {
        bool setFee = verifySetFee(from, to);

        if (_isExcludedFromFees[from]) {
            super._internalTransfer(from, to, amount);
            return;
        } else if (setFee) {
            uint256 fees = amount * _tax / 100;

            if (fees > 0) {
                super._transfer(from, _marketingWallet, fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function burn(uint256 _amount) external {
        super._burn(_msgSender(), _amount);
    }

    function verifySetFee(address from, address to) public view returns (bool) {
        bool isBuy = from == _uniswapV2Pair && to != address(_uniswapV2Router);
        bool isExcludedFromFee = _isExcludedFromFees[from] ||
                        _isExcludedFromFees[to];
        bool isSell = to == _uniswapV2Pair;
        bool isSwap = isBuy || isSell;

        return !_swappingBack && !isExcludedFromFee && isSwap;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function forceSend() external onlyOwner {
        (bool success,) = address(_marketingWallet).call{
                value: address(this).balance
            }("");
        require(success);
    }

    receive() external payable {}
}