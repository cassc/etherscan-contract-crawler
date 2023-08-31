// SPDX-License-Identifier: MIT

/*
STAY AHEAD IN THE GAME
Meet DexLions, the elite DeFi traders, and access their signals to boost your trading skills and outpace the market.

Website: https://dexlions.com
White paper: https://premium.dexlions.com
Telegram: https://t.me/dexlions
Twitter: https://twitter.com/dexlionscom
*/

pragma solidity ^0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract DEXLIONS is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    IDexRouter public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private _swapping;
    uint256 public swapTokensAtAmount;

    address public MarketingAddress;

    uint256 public tradingActiveBlock = 0; 
    uint256 public deadBlocks = 2;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public sniperManagementEnabled = true;

    uint256 public buyFee;

    uint256 public sellFee;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedFromLimits;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public isSniper;

    constructor() ERC20("DEXLIONS", "LION") {

        address newOwner = msg.sender; 

        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _excludeFromLimits(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        address tokenA = address(this);
        address tokenB = _uniswapV2Router.WETH();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        uniswapV2Pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            _uniswapV2Router.factory(),
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 100000000  * 1e18;

        maxBuyAmount = totalSupply * 2 / 100;
        maxSellAmount = totalSupply *  2 / 100;
        maxWalletAmount = totalSupply * 4 / 100;
        swapTokensAtAmount = totalSupply * 50 / 100000; 

        buyFee = 5;
        sellFee = 20;

        _excludeFromLimits(newOwner, true);
        _excludeFromLimits(address(this), true);

        MarketingAddress = address(0x8866214224889999716908e2c1663bb355ee3BBa);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function createPair() external onlyOwner {
        IDexFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function updateMaxBuyAmount(uint256 newAmount) external onlyOwner {
        require(newAmount * 1e18 >= (totalSupply() * 1 / 100), "DEXLIONS: new max buy amount less than 1% of total supply");
        maxBuyAmount = newAmount * 1e18;
    }

    function updateMaxSellAmount(uint256 newAmount) external onlyOwner {
        require(newAmount * 1e18 >= (totalSupply() * 1 / 100), "DEXLIONS: new max sell amount less than 1% of total supply");
        maxSellAmount = newAmount * 1e18;
    }

    function updateMaxWalletAmount(uint256 newAmount) external onlyOwner {
        require(newAmount * 1e18 >= (totalSupply() * 2 / 100), "DEXLIONS: new max wallet amount less than 2% of total supply");
        maxWalletAmount = newAmount * 1e18;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount * 1e18 >= totalSupply() * 1 / 100000, "DEXLIONS: new swap amount less than 0.001% of total supply");
        require(newAmount <= totalSupply() * 1 / 1000, "DEXLIONS: new Swap amount exceeds 0.1% of total supply");
        swapTokensAtAmount = newAmount * 1e18;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function _excludeFromLimits(address account, bool isExcluded) private {
        isExcludedFromLimits[account] = isExcluded;
    }

    function excludeFromLimits(address account, bool isExcluded) external onlyOwner {
        if (!isExcluded) {
            require(account != uniswapV2Pair, "DEXLIONS: account to be exscluded is pair address");
        }
        _excludeFromLimits(account, isExcluded);
    }

    function updateBuyFee(uint256 newBuyFee) external onlyOwner {
        require(newBuyFee <= 5, "DEXLIONS: new buy fee exceeds 5%");
        buyFee = newBuyFee;
    }

    function updateSellFee(uint256 newSellFee) external onlyOwner {
        if (sellFee > 5) {
            require(newSellFee <= sellFee, "DEXLIONS: new sell fee exceeds current sell fee");
        } else {
            require(sellFee <= 5, "DEXLIONS: new sell fee exceeds 5%");
        }
        sellFee = newSellFee;
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "DEXLIONS: amount is zero");
        require(!isSniper[from], "DEXLIONS: sender marked as sniper");
        require(!isSniper[to], "DEXLIONS: recipient marked as sniper");
 
        if (limitsInEffect) {
            if (from != owner() && to != owner() && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
                require(tradingActive, "DEXLIONS: trading is not active");
                if (tradingActiveBlock > 0 && block.number < (tradingActiveBlock + deadBlocks) ) {
                    isSniper[to] = true;
                }
                // buy
                if (automatedMarketMakerPairs[from] && !isExcludedFromLimits[to]) {
                    require(amount <= maxBuyAmount, "DEXLIONS: transfer amount exceeds max buy amount");
                    require(amount + balanceOf(to) <= maxWalletAmount, "DEXLIONS: balance exceeds max wallet amount");
                }
                // sell
                else if (automatedMarketMakerPairs[to] && !isExcludedFromLimits[from]) {
                    require(amount <= maxSellAmount, "DEXLIONS: transfer amount exceeds max sell amount");
                }
                else if (!isExcludedFromLimits[to]) {
                    require(amount + balanceOf(to) <= maxWalletAmount, "DEXLIONS: balance exceeds max wallet amount");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(canSwap && swapEnabled && !_swapping && !automatedMarketMakerPairs[from] && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            _swapping = true;
            _swapBack();
            _swapping = false;
        }

        uint256 fee = 0;
        uint256 penaltyAmount = 0;
        if(!isExcludedFromFees[from] && !isExcludedFromFees[to]){
            // sniper penalty
            if (tradingActiveBlock > 0 && block.number < (tradingActiveBlock + deadBlocks) ) {
                penaltyAmount = amount * 98 / 100;
                super._transfer(from, MarketingAddress, penaltyAmount);
            }
            // sell
            else if (automatedMarketMakerPairs[to] && sellFee > 0){
                fee = amount * sellFee / 100;
            }
            // buy
            else if(automatedMarketMakerPairs[from] && buyFee > 0) {
                fee = amount * buyFee / 100;
            }
            if(fee > 0){
                super._transfer(from, address(this), fee);
            }
            amount -= fee + penaltyAmount;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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

    function setAutomatedMarketMakerPair(address pair, bool isAMM) external onlyOwner {
        if(!isAMM) {
            require(pair != uniswapV2Pair, "DEXLIONS: automated market maker pair is uniswap V2 pair");
        }
        _setAutomatedMarketMakerPair(pair, isAMM);
    }

    function _setAutomatedMarketMakerPair(address pair, bool isAMM) private {
        automatedMarketMakerPairs[pair] = isAMM;
        _excludeFromLimits(pair, isAMM);
    }

    // once enabled, can never be turned off
    function enableTrading(bool _status, uint256 _deadBlocks) external onlyOwner {
        require(!tradingActive, "DEXLIONS: trading is already active");
        require(_deadBlocks <= 5, "DEXLIONS: deadblocks amount exceeds 5");
        tradingActive = _status;
        swapEnabled = true;

        if (tradingActive && tradingActiveBlock == 0) {
            tradingActiveBlock = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function setMarketingAddress(address newMarketingAddress) external onlyOwner {
        require(newMarketingAddress != address(0), "DEXLIONS: new marketing address is the zero address");
        MarketingAddress = payable(newMarketingAddress);
    }

    function manageSniper(address sniperAddress, bool status) external onlyOwner {
        require(sniperManagementEnabled, "DEXLIONS: sniper management permanently disabled");
        isSniper[sniperAddress] = status;
    }

    function manageSnipers(address[] calldata addresses, bool status) external onlyOwner {
        require(sniperManagementEnabled, "DEXLIONS: snipers management permanently disabled");
        for (uint256 i; i < addresses.length; ++i) {
            isSniper[addresses[i]] = status;
        }
    }

    // permanently disable sniper management
    function disableSniperManagement() external onlyOwner {
        sniperManagementEnabled = false;
    }

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }
        _swapTokensForEth(contractBalance);
        bool success;
        (success,) = address(MarketingAddress).call{value: address(this).balance}("");
    }

    function transferForeignToken(address token, address to) external onlyOwner returns (bool) {
        require(token != address(0), "DEXLIONS: token is the zero address");
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, _contractBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

}