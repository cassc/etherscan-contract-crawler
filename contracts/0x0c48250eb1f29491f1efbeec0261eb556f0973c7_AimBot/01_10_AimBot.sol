// https://aim-bot.app/
// https://t.me/Aimbotportal
// https://twitter.com/aimbot_coin

// SPDX-License-Identifier: MIT

import "./AimBotDividends.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

pragma solidity ^0.8.19;

contract AimBot is Ownable, ERC20 {
    uint256 public maxWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 immutable router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    AimBotDividends public dividends;

    uint256 SUPPLY = 1000000 * 10**18;

    uint256 snipeFee = 30; 
    uint256 totalFee = 5; 
    uint256 botFee = 3; 

    bool private inSwap = false;
    address public marketingWallet;
    address public devWallet;
    address public botWallet;

    uint256 public openTradingBlock;

    mapping (address => uint256) public receiveBlock;

    uint256 public swapAt = SUPPLY / 1000; //0.1%

    constructor() ERC20("AimBot", "AIMBOT") payable {
        _mint(msg.sender, SUPPLY * 23 / 1000);
        _mint(address(this), SUPPLY * 977 / 1000);

        maxWallet = SUPPLY;
        marketingWallet = 0x3be53c7D961F3595515E9905E7507b33A5DC7c5A;
        devWallet = 0x092A071a3322166A840B06Ace845761f98FbBAa0;
        botWallet = 0x88054E4FF95395d43286b52D97451C71a974D8c9;

        dividends = new AimBotDividends();

        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(owner());
    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function updateBotWallet(address _botWallet) external onlyOwner {
        botWallet = _botWallet;
    }

    function updateDividends(address _dividends) external onlyOwner {
        dividends = AimBotDividends(payable(_dividends));

        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(owner());
        dividends.excludeFromDividends(uniswapV2Pair);
        dividends.excludeFromDividends(address(router));
    }

    function updateFee(uint256 _totalFee, uint256 _botFee) external onlyOwner {
        require(_totalFee <= 5 && _botFee <= _totalFee);
        totalFee = _totalFee;
        botFee = _botFee;
    }

    function updateMaxHoldingPercent(uint256 percent) public onlyOwner {
        require(percent >= 1 && percent <= 100, "invalid percent");
        maxWallet = SUPPLY * percent / 100;
    }

    function updateSwapAt(uint256 value) external onlyOwner() {
        require(value <= SUPPLY / 50);
        swapAt = value;
    }

    function stats(address account) external view returns (uint256 withdrawableDividends, uint256 totalDividends) {
        (,withdrawableDividends,totalDividends) = dividends.getAccount(account);
    }

    function claim() external {
		dividends.claim(msg.sender);
    }

    function openTrading() external onlyOwner {

        address pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), balanceOf(address(this)));
        router.addLiquidityETH{
            value: address(this).balance
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        uniswapV2Pair = pair;
        openTradingBlock = block.number;
        dividends.excludeFromDividends(address(router));
        dividends.excludeFromDividends(pair);

        updateMaxHoldingPercent(1);

    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(uniswapV2Pair == address(0)) {
            require(from == address(this) || from == address(0) || from == owner() || to == owner(), "Not started");
            super._transfer(from, to, amount);
            return;
        }

        if(from == uniswapV2Pair && to != address(this) && to != owner() && to != address(router)) {
            require(super.balanceOf(to) + amount <= maxWallet, "max wallet");
        }

        uint256 swapAmount = balanceOf(address(this));

        if(swapAmount > swapAt) {
            swapAmount = swapAt;
        }

        if(
            swapAt > 0 &&
            swapAmount == swapAt &&
            !inSwap &&
            from != uniswapV2Pair) {

            inSwap = true;

            swapTokensForEth(swapAmount);

            uint256 balance = address(this).balance;

            if(balance > 0) {
                withdraw(balance);
            }

            inSwap = false;
        }

        uint256 fee;

        if(block.number <= openTradingBlock + 4 && from == uniswapV2Pair) {
            require(!isContract(to));
            fee = snipeFee;
        }
        else if(totalFee > 0) {
            fee = totalFee;
        }
            
        if(
            fee > 0 &&
            from != address(this) &&
            from != owner() &&
            from != address(router)
        ) {
            uint256 feeTokens = amount * fee / 100;
            amount -= feeTokens;

            super._transfer(from, address(this), feeTokens);
        }

        super._transfer(from, to, amount);

        dividends.updateBalance(payable(from));
        dividends.updateBalance(payable(to));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function sendFunds(address user, uint256 value) private {
        if(value > 0) {
            (bool success,) = user.call{value: value}("");
            success;
        }
    }

    function withdraw(uint256 amount) private {
        uint256 botShare = totalFee > 0 ? botFee * 10000 / totalFee : 0;

        uint256 toBot = amount * botShare / 10000;
        uint256 toMarketing = (amount - toBot) / 2;
        uint256 toDev = toMarketing;

        sendFunds(marketingWallet, toMarketing);
        sendFunds(devWallet, toDev);
        sendFunds(botWallet, toBot);
    }
}