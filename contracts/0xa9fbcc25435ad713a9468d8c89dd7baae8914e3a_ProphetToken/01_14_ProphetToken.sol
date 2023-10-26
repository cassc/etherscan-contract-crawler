// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ProphetDividends.sol";

contract ProphetToken is Ownable, ERC20 {
    uint256 public maxWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 immutable router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ProphetDividends public dividends;

    uint256 totalFee = 5;
    uint256 operationsFee = 5;

    bool private inSwap = false;
    address public operationsWallet;

    mapping(address => uint256) public receiveBlock;

    uint256 public swapBackAt;

    constructor(address _owner) ERC20("Prophet", "PROPHET") {
        uint256 totalSupply = 1_000_000 ether;

        swapBackAt = (totalSupply * 1) / 1000; //0.1%

        maxWallet = totalSupply;

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        dividends = new ProphetDividends();

        dividends.excludeFromDividends(owner());
        dividends.excludeFromDividends(_owner);
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(router));
        dividends.excludeFromDividends(uniswapV2Pair);
        dividends.excludeFromDividends(address(0xdead));
        dividends.excludeFromDividends(address(0));

        operationsWallet = 0x1b62bC39AE9b1e85c5B926a5Ea0396151B3991A7;

        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        dividends.updateBalance(payable(msg.sender));
    }

    function updateOperationsWallet(address _operationsWallet)
        external
        onlyOwner
    {
        operationsWallet = _operationsWallet;
    }

    function updateDividends(address _dividends) external onlyOwner {
        dividends = ProphetDividends(payable(_dividends));

        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(owner());
        dividends.excludeFromDividends(uniswapV2Pair);
        dividends.excludeFromDividends(address(router));
    }

    function updateFee(uint256 _totalFee, uint256 _operationsFee)
        external
        onlyOwner
    {
        require(_totalFee <= 5 && _operationsFee <= _totalFee);
        totalFee = _totalFee;
        operationsFee = _operationsFee;
    }

    function updateMaxHoldingPercent(uint256 percent) public onlyOwner {
        require(percent >= 1 && percent <= 100, "invalid percent");
        maxWallet = (totalSupply() * percent) / 100;
    }

    function updateSwapBackAt(uint256 value) external onlyOwner {
        require(value <= totalSupply() / 50);
        swapBackAt = value;
    }

    function stats(address account)
        external
        view
        returns (uint256 withdrawableDividends, uint256 totalDividends)
    {
        (, withdrawableDividends, totalDividends) = dividends.getAccount(
            account
        );
    }

    function claim() external {
        dividends.claim(msg.sender);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == address(this) ||
                    from == address(0) ||
                    from == owner() ||
                    to == owner(),
                "Not started"
            );
            super._transfer(from, to, amount);
            return;
        }

        if (
            from == uniswapV2Pair &&
            to != address(this) &&
            to != owner() &&
            to != address(router)
        ) {
            require(super.balanceOf(to) + amount <= maxWallet, "max wallet");
        }

        uint256 swapAmount = balanceOf(address(this));

        if (swapAmount > swapBackAt) {
            swapAmount = swapBackAt;
        }

        if (
            swapBackAt > 0 &&
            swapAmount == swapBackAt &&
            !inSwap &&
            from != uniswapV2Pair
        ) {
            inSwap = true;

            swapTokensForEth(swapAmount);

            uint256 balance = address(this).balance;

            if (balance > 0) {
                withdraw(balance);
            }

            inSwap = false;
        }

        if (
            totalFee > 0 &&
            from != address(this) &&
            from != owner() &&
            from != address(router)
        ) {
            uint256 feeTokens = (amount * totalFee) / 100;
            amount -= feeTokens;

            super._transfer(from, address(this), feeTokens);
        }

        super._transfer(from, to, amount);

        dividends.updateBalance(payable(from));
        dividends.updateBalance(payable(to));
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendFunds(address user, uint256 value) internal {
        if (value > 0) {
            (bool success, ) = user.call{value: value}("");
            success;
        }
    }

    function withdraw(uint256 amount) internal {
        uint256 operationsShare = totalFee > 0
            ? (operationsFee * 10000) / totalFee
            : 0;

        uint256 toOperations = (amount * operationsShare) / 10000;
        uint256 toRevShare = (amount - toOperations);

        sendFunds(operationsWallet, toOperations);
        sendFunds(address(dividends), toRevShare);
    }
}