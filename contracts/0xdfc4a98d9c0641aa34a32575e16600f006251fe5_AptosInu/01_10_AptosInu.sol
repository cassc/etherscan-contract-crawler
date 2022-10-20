pragma solidity >=0.8.10;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract AptosInu is Context, ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private TOTAL_SUPPLY = 10_000_000 * 10**18;
    address private WETH;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFee;
    uint256 public buyMarketingFee;
    uint256 public buyBurnFee;
    uint256 public sellMarketingFee;
    uint256 public sellBurnFee;
    address public marketingWallet;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    bool public tradingOpen = false;
    bool private inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20('Aptos Inu', '$Aptos') {
        // Init Uniswap
        initUniswap(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        // Init fee
        initFee();
        // Mint token
        _mint(owner(), TOTAL_SUPPLY);
    }

    function initFee() private {
        buyMarketingFee = 3; // 3% marketing buy fee
        buyBurnFee = 0; // 0% burn buy fee
        sellMarketingFee = 3; // 3% marketing sell fee
        sellBurnFee = 0; // 0% burn sell fee
        marketingWallet = owner();

        maxTxAmount = (TOTAL_SUPPLY / 1000) * 10; // 1% total supply
        maxWalletAmount = (TOTAL_SUPPLY / 1000) * 30; // 3% total supply

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
    }

    function initUniswap(address routerAddress) private {
        uniswapV2Router = IUniswapV2Router02(routerAddress);
        WETH = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        _approve(address(this), uniswapV2Pair, type(uint256).max);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        require(amount <= balanceOf(from), 'You are trying to transfer more than your balance');
        require(tradingOpen || from == owner() || to == owner(), 'Trading not enabled yet'); // Allow owner to add liquidity

        if (inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if (!_isExcludedFromFee[from] || !_isExcludedFromFee[to]) {
            require(amount <= maxTxAmount, 'Transfer amount must be less then or equal to maxTxAmount');
            // Check maxWalletAmount when Buy
            if (from == uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    'Transfer wallet amount must be less then or equal to maxTxAmount'
                );
            }
        }

        // Take tax fee
        uint256 burnFee;
        uint256 marketingFee;

        if (from == uniswapV2Pair) {
            // Buy Token
            burnFee = (amount * buyBurnFee) / 100;
            marketingFee = (amount * buyMarketingFee) / 100;
        } else if (to == uniswapV2Pair) {
            // Sell Token
            burnFee = (amount * sellBurnFee) / 100;
            marketingFee = (amount * sellMarketingFee) / 100;
        }

        if (burnFee > 0) {
            super._burn(from, burnFee);
        }

        if (marketingFee > 0) {
            super._transfer(from, address(this), marketingFee);
        }

        amount = amount - marketingFee - burnFee;

        super._transfer(from, to, amount);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function isExcludedFromFee(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function withdrawMarketingFee() public lockTheSwap onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        super._transfer(address(this), marketingWallet, contractTokenBalance);
    }

    function setBuyMarketingFee(uint256 fee) public onlyOwner {
        buyMarketingFee = fee;
    }

    function setBuyBurnFee(uint256 fee) public onlyOwner {
        buyBurnFee = fee;
    }

    function setSellMarketingFee(uint256 fee) public onlyOwner {
        sellMarketingFee = fee;
    }

    function setSellBurnFee(uint256 fee) public onlyOwner {
        sellBurnFee = fee;
    }

    function removeLimits() public onlyOwner {
        maxTxAmount = TOTAL_SUPPLY;
        maxWalletAmount = TOTAL_SUPPLY;
    }
}