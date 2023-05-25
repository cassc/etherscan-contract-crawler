//spdx-license-identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IClaim.sol";

contract HUMPToken is Ownable, ERC20 {
    IUniswapV2Router02 public uniswapV2Router;

    address public marketingWallet;
    address public claimContractAddress;
    address public uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public tradingEnabled;
    uint256 public marketingReserve;
    uint256 public maxTxAmount = 696969694 * 10 ** decimals(); //1.0% ~700M
    uint256 public maxWalletAmount = 696969694 * 10 ** decimals(); //1.0% ~700M
    uint256 public numTokensSellToAddToETH = 6969696 * 10 ** decimals(); //0.01% ~7M
    uint256 public numTokensSellToAddToLiquidity = 13939393 * 10 ** decimals(); //0.02% ~14M
    uint256 public claimReserve;
    uint256 private supply = 69696969420 * 10 ** decimals(); // ~70B
    uint256 public taxForLiquidity = 200;
    uint256 public taxForMarketing = 100;
    uint256 public taxForClaim = 100;

    mapping(address => bool) public isExcludedFromFee;

    error FailedETHSend();
    error InsufficientBalance();
    error LowerThanOnePercent();
    error MaxTxAmountExceeded();
    error MaxWalletAmountExceeded();
    error TradingNotEnabled();
    error ZeroAddress();

    event ExcludedFromFeeUpdated(
        address indexed owner,
        address indexed account,
        bool indexed isExcluded
    );
    event MaxAmountsUpdated(
        address indexed owner,
        uint256 indexed maxTx,
        uint256 indexed maxWallet
    );
    event SwapAndLiquify(
        uint256 indexed tokensSwapped,
        uint256 indexed ethReceived,
        uint256 indexed tokensIntoLiqudity
    );
    event TaxesUpdated(
        address indexed owner,
        uint256 indexed liquidity,
        uint256 indexed marketing,
        uint256 staking
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier NotZeroAddress(address value) {
        if (value == address(0)) revert ZeroAddress();
        _;
    }

    constructor(
        uint256 liquidityAmount,
        uint256 claimAmount,
        address _uniswapV2Router,
        address _marketingWallet,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        marketingWallet = _marketingWallet;

        isExcludedFromFee[address(uniswapV2Router)] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[marketingWallet] = true;

        //mint tokens
        _mint(_msgSender(), supply - liquidityAmount - claimAmount);
        _mint(address(this), liquidityAmount);
        _mint(address(this), claimAmount);
        claimReserve = claimAmount;

        //create pair
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
    }

    receive() external payable {}

    function addLiquidity(
        address recipient,
        uint256 amount
    ) external payable onlyOwner {
        amount = amount == 0 ? super.balanceOf(address(this)) : amount;
        _addLiquidity(recipient, amount, msg.value);
    }

    function burn(uint256 value) external {
        _burn(_msgSender(), value);
    }

    function distributeRewards() external onlyOwner {
        _distributeRewards();
    }

    function excludeFromFee(
        address _address,
        bool _status
    ) external onlyOwner NotZeroAddress(_address) {
        isExcludedFromFee[_address] = _status;
        emit ExcludedFromFeeUpdated(_msgSender(), _address, _status);
    }

    function setClaimContractAddress(
        address value
    ) external onlyOwner NotZeroAddress(value) {
        claimContractAddress = value;
    }

    function setMarketingWallet(
        address value
    ) external onlyOwner NotZeroAddress(value) {
        marketingWallet = value;
    }

    function setStakingAddrss(
        address value
    ) external onlyOwner NotZeroAddress(value) {
        claimContractAddress = value;
    }

    function setSwapThresholds(
        uint256 ethThreshold,
        uint256 liquidityThreshold
    ) external onlyOwner {
        numTokensSellToAddToETH = ethThreshold;
        numTokensSellToAddToLiquidity = liquidityThreshold;
    }

    function setTaxes(
        uint256 liquidity,
        uint256 marketing,
        uint256 staking
    ) external onlyOwner {
        taxForLiquidity = liquidity;
        taxForMarketing = marketing;
        taxForClaim = staking;
        emit TaxesUpdated(_msgSender(), liquidity, marketing, staking);
    }

    function setTradingEnabled(
        uint256 _maxTxAmount,
        uint256 _maxWalletAmount
    ) external onlyOwner {
        setMaxAmounts(_maxTxAmount, _maxWalletAmount);
        tradingEnabled = true;
    }

    //value should be wei
    function setMaxAmounts(uint256 maxTx, uint256 maxWallet) public onlyOwner {
        if (maxTx < supply / 100) revert LowerThanOnePercent();
        if (maxWallet < supply / 100) revert LowerThanOnePercent();
        maxTxAmount = maxTx;
        maxWalletAmount = maxWallet;
        emit MaxAmountsUpdated(_msgSender(), maxTx, maxWallet);
    }

    function _distributeRewards() private {
        uint256 amount = claimReserve;
        claimReserve = 0;
        address claimAddress = claimContractAddress;
        // Set allowance for the claim contract
        this.approve(claimAddress, amount);

        // Call receiveRewards function in the claim contract
        IClaim(claimAddress).addRewards(amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override NotZeroAddress(to) NotZeroAddress(from) {
        // sender has sufficient balance
        if (balanceOf(from) < amount) revert InsufficientBalance();

        // trading is enabled or sender is owner or sender is this contract
        if (!tradingEnabled && from != owner() && from != address(this))
            revert TradingNotEnabled();

        // buys and sells
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify
        ) {
            // create liqudity on sells only
            if (uniswapV2Pair != from) {
                uint256 reserves = marketingReserve + claimReserve;
                uint256 contractLiquidityBalance = balanceOf(address(this)) -
                    reserves;
                if (contractLiquidityBalance >= numTokensSellToAddToLiquidity) {
                    _swapAndLiquify(numTokensSellToAddToLiquidity);
                }
                uint256 _numTokensSellToAddToETH = numTokensSellToAddToETH;
                if (marketingReserve >= _numTokensSellToAddToETH) {
                    _distributeRewards();

                    marketingReserve -= _numTokensSellToAddToETH;
                    _swapTokensForEth(_numTokensSellToAddToETH);
                    (bool sent, ) = payable(marketingWallet).call{
                        value: address(this).balance
                    }("");
                    if (!sent) revert FailedETHSend();
                }
            }

            // take taxes
            if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
                if (amount > maxTxAmount) revert MaxTxAmountExceeded();
                if (uniswapV2Pair != to) {
                    if (amount + balanceOf(to) > maxWalletAmount)
                        revert MaxWalletAmountExceeded();
                }

                uint256 marketingTax = (amount * taxForMarketing) / 1e4;
                uint256 stakingTax = (amount * taxForClaim) / 1e4;
                uint256 liquidityTax = (amount * taxForLiquidity) / 1e4;
                uint256 totalTaxes = marketingTax + stakingTax + liquidityTax;

                marketingReserve += marketingTax;
                claimReserve += stakingTax;
                amount -= totalTaxes;

                super._transfer(from, address(this), totalTaxes);
            }
        }
        super._transfer(from, to, amount);
    }

    function _addLiquidity(
        address recipient,
        uint256 tokenAmount,
        uint256 ethAmount
    ) private lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            recipient,
            block.timestamp
        );
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        _addLiquidity(marketingWallet, otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
}