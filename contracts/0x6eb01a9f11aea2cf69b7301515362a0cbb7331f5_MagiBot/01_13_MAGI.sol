// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/*

  __  __           _   ___      _   
 |  \/  |__ _ __ _(_) | _ ) ___| |_ 
 | |\/| / _` / _` | | | _ \/ _ \  _|
 |_|  |_\__,_\__, |_| |___/\___/\__|
             |___/                  

 Twitter : https://twitter.com/MagiBOT_
 Website : https://magibot.app/
 Telegram : https://t.me/MagiBotPortal

*/

contract MagiBot is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public teamWallet;

    uint256 public maxTradingAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public blacklistRenounced = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) blacklisted;

    uint256 public buyFees; // buy fee
    uint256 public sellFees; // sell fee

    uint256 public endHighFeesBlock; // block number at which high buy / sell fees become normal (before 20/20)
    bool private normalFees;

    uint256 private FEE_BASE = 1000;

    uint256 public tokensForTeam;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTradingAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event teamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor(
        string memory name,
        string memory symbol,
        uint256 sellFee_,
        uint256 buyFee_
    ) ERC20(name, symbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTrading(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTrading(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 10_000_000 * 1e18;

        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%: 5000
        maxTradingAmount = (totalSupply * 200) / 10000; // 2%: 200.000
        maxWallet = (totalSupply * 100) / 10000; // 1%: 100.000

        // 5% fee for buy/sell
        buyFees = buyFee_;
        sellFees = sellFee_;

        teamWallet = msg.sender;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTrading(owner(), true);
        excludeFromMaxTrading(address(this), true);
        excludeFromMaxTrading(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function startNow() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;

        endHighFeesBlock = block.number + 2; // higher tax for bots
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTradingAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTradingAmount lower than 0.1%"
        );
        maxTradingAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1.0%"
        );
        maxWallet = newNum * (10 ** 18);
    }

    function excludeFromMaxTrading(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTradingAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function getSwapFees(bool isBuying) public view returns (uint) {
        if (endHighFeesBlock != 0 && endHighFeesBlock < block.number) {
            if (isBuying) return buyFees;
            return sellFees;
        }
        return 200; // 20% fees at the beginning
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        emit teamWalletUpdated(newWallet, teamWallet);
        teamWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "Sender blacklisted");
        require(!blacklisted[to], "Receiver blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTradingAmount[to]
                ) {
                    //when buy
                    require(
                        amount <= maxTradingAmount,
                        "Buy transfer amount exceeds the maxTradingAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                } else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTradingAmount[from]
                ) {
                    //when sell
                    require(
                        amount <= maxTradingAmount,
                        "Sell transfer amount exceeds the maxTradingAmount."
                    );
                } else if (!_isExcludedMaxTradingAmount[to]) {
                    //when transfer
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            uint _sellFees = getSwapFees(false);
            uint _buyFees = getSwapFees(true);

            // on sell
            if (automatedMarketMakerPairs[to] && _sellFees > 0) {
                fees = amount.mul(_sellFees).div(FEE_BASE);
                tokensForTeam += fees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && _buyFees > 0) {
                fees = amount.mul(_buyFees).div(FEE_BASE);
                tokensForTeam += fees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0 || tokensForTeam == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(tokensForTeam);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        tokensForTeam = 0;

        (success, ) = address(teamWallet).call{value: ethBalance}("");
    }

    function withdrawStuckUnibot() external onlyOwner {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }

    // @dev team renounce blacklist commands
    function renounceBlacklist() public onlyOwner {
        blacklistRenounced = true;
    }

    function blacklist(address _addr) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(
            _addr != address(uniswapV2Pair) &&
                _addr != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
            "Cannot blacklist token's v2 router or v2 pool."
        );
        blacklisted[_addr] = true;
    }

    // @dev blacklist v3 pools; can unblacklist() down the road to suit project and community
    function blacklistLiquidityPool(address lpAddress) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(
            lpAddress != address(uniswapV2Pair) &&
                lpAddress !=
                address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
            "Cannot blacklist token's v2 router or v2 pool."
        );
        blacklisted[lpAddress] = true;
    }

    // @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
    function unblacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
    }
}