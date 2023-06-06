/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_,uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);


}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}

contract usdtReceiver {
    address public usdt;
    address public owner;
    constructor(address _u) {
        usdt = _u;
        owner = msg.sender;
        IERC20(usdt).approve(msg.sender,~uint256(0));
    }
}

contract Token is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapPair;

    bool private swapping;

    uint256 public swapTokensAtAmount;

    uint256 public buyTokenRewardsFee;
    uint256 public sellTokenRewardsFee;

    uint256 public buyLiquidityFee;
    uint256 public sellLiquidityFee;

    uint256 public buyMarketingFee;
    uint256 public sellMarketingFee;

    uint256 public buyDeadFee;
    uint256 public sellDeadFee;

    uint256 public AmountLiquidityFee;
    uint256 public AmountTokenRewardsFee;
    uint256 public AmountMarketingFee;

    uint256 public addLiquidityFee;
    uint256 public removeLiquidityFee;


    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public usdtAddress;
    address public _marketingWalletAddress;
    address public rewardsAddress;
    uint256 public gasForProcessing;
    bool public swapAndLiquifyEnabled = true;
    uint256 currentIndex;
    uint256 public LPFeeRewardsTimes;
    uint256 public minLPFeeRewards;
    uint256 public first;
    uint256 public kill = 0;
    uint256 public airdropNumbs;
    usdtReceiver public _usdtReceiver;
    uint256 public processRewardWaitBlock = 20;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 public _maxTxAmount;
    uint256 public _walletMax;
    bool public checkWalletLimit = true;
    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    // Whether to distribute dividends in local currency
    bool public currencyFlag;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;


    mapping(address => bool) private _updated;
    address[] public shareholders;
    mapping(address => uint256) shareholderIndexes;


    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        address[4] memory addrs, // router,markting,usdtAddress,rewardsAddress
        uint256[4] memory buyFeeSetting_, // rewards,lp,market,dead
        uint256[4] memory sellFeeSetting_, // rewards,lp,market,dead
        bool flag,
        address service
    ) payable ERC20(name_, symbol_,decimals_)  {
        _marketingWalletAddress = addrs[1];
        usdtAddress = addrs[2];
        _usdtReceiver = new usdtReceiver(usdtAddress);
        currencyFlag = flag;
        if(currencyFlag){
          rewardsAddress = address(this);
        }else{
          rewardsAddress = addrs[3];
        }
        buyTokenRewardsFee = buyFeeSetting_[0];
        buyLiquidityFee = buyFeeSetting_[1];
        buyMarketingFee = buyFeeSetting_[2];
        buyDeadFee = buyFeeSetting_[3];

        sellTokenRewardsFee = sellFeeSetting_[0];
        sellLiquidityFee = sellFeeSetting_[1];
        sellMarketingFee = sellFeeSetting_[2];
        sellDeadFee = sellFeeSetting_[3];

        require(buyTokenRewardsFee.add(buyLiquidityFee).add(buyMarketingFee).add(buyDeadFee) <= 100, "Total buy fee is over 100%");
        require(sellTokenRewardsFee.add(sellLiquidityFee).add(sellMarketingFee).add(sellDeadFee) <= 100, "Total sell fee is over 100%");

        uint256 totalSupply = totalSupply_ * (10 ** decimals_);
        swapTokensAtAmount = totalSupply.mul(2).div(10**6); // 0.002%
        _maxTxAmount = totalSupply;
        _walletMax = totalSupply;
        if(currencyFlag){
          minLPFeeRewards = (10 ** decimals_); // min Lp Rewards Dividend
        }else{
          minLPFeeRewards = (10 ** IERC20(rewardsAddress).decimals()); // min Lp Rewards Dividend
        }


        // use by default 300,000 gas to process auto-claiming dividends
        gasForProcessing = 300000;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addrs[0]);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), usdtAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapPair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);


        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[deadWallet] = true;
        isWalletLimitExempt[_marketingWalletAddress] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[deadWallet] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_marketingWalletAddress] = true;

        _mint(owner(), totalSupply);
        payable(service).transfer(msg.value);
    }
    receive() external payable {}



    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
        uniswapPair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        isWalletLimitExempt[address(uniswapPair)] = true;
    }
    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if (_isExcludedFromFees[account] != excluded) {
            _isExcludedFromFees[account] = excluded;
            emit ExcludeFromFees(account, excluded);
        }
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
        _isExcludedFromFees[_marketingWalletAddress] = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapPair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }


    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function swapManual() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance > 0, "token balance zero");
        swapping = true;
        if (AmountMarketingFee > 0) swapAndSendMarketing(AmountMarketingFee);
        if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
        if (AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
        swapping = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }


    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setRewardsAddr(address _addr) public onlyOwner {
        if(_addr == address(this)){
            currencyFlag = true;
        }else{
            currencyFlag = false;
        }
        rewardsAddress = _addr;
    }

    function setBuyTaxes(uint256 liquidity, uint256 rewardsFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
        require(rewardsFee.add(liquidity).add(marketingFee).add(deadFee) <= 100, "Total buy fee is over 100%");
        buyTokenRewardsFee = rewardsFee;
        buyLiquidityFee = liquidity;
        buyMarketingFee = marketingFee;
        buyDeadFee = deadFee;

    }

    function setSelTaxes(uint256 liquidity, uint256 rewardsFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
        require(rewardsFee.add(liquidity).add(marketingFee).add(deadFee) <= 100, "Total sel fee is over 100%");
        sellTokenRewardsFee = rewardsFee;
        sellLiquidityFee = liquidity;
        sellMarketingFee = marketingFee;
        sellDeadFee = deadFee;
    }
    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        require(newValue <= 3, "newValue must <= 3");
        airdropNumbs = newValue;
    }

    function setKing(uint256 newValue) public onlyOwner {
        require(newValue <= 100, "newValue must <= 100");
        kill = newValue;
    }

    function setAddLiquidityFee(uint256 fee) external onlyOwner {
        require(fee <= 25, "Total sel fee is over 25%");
        addLiquidityFee = fee;
    }

    function setRemoveLiquidityFee(uint256 fee) external onlyOwner {
        require(fee <= 25, "Total sel fee is over 25%");
        removeLiquidityFee = fee;
    }

    function setRewardsInfo(uint256 minLpRewards,uint256 waitBlock) public onlyOwner {
        minLPFeeRewards = minLpRewards;
        processRewardWaitBlock = waitBlock;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax  = newLimit;
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

        if(automatedMarketMakerPairs[to] && balanceOf(address(uniswapPair)) == 0){
            first = block.number;
        }
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            if(automatedMarketMakerPairs[from] && block.number < first + kill){
                return super._transfer(from, _marketingWalletAddress, amount);
            }
        }

        if(!isTxLimitExempt[from] && !isTxLimitExempt[to]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner() &&
            swapAndLiquifyEnabled &&
            !_isAddLiquidity()
        ) {
            swapping = true;
            if (AmountMarketingFee > 0) swapAndSendMarketing(AmountMarketingFee);
            if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
            if (AmountTokenRewardsFee > 0) swapAndSendDividends(AmountTokenRewardsFee);
            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }


        if(takeFee) {
            uint256 fees;
            uint256 LFee; // Liquidity
            uint256 RFee; // Rewards
            uint256 MFee; // Marketing
            uint256 DFee; // Dead

            bool isRemove;
            bool isAdd;
            if (automatedMarketMakerPairs[to]) {
                isAdd = _isAddLiquidity();
            } else if (automatedMarketMakerPairs[from]) {
                isRemove = _isRemoveLiquidity();
            }

            if(isAdd){
                RFee = amount.mul(addLiquidityFee).div(100);
                AmountTokenRewardsFee += RFee;
                fees = RFee;
            }else if(isRemove){
                RFee = amount.mul(removeLiquidityFee).div(100);
                AmountTokenRewardsFee += RFee;
                fees = RFee;
            }else if(automatedMarketMakerPairs[from]){
                LFee = amount.mul(buyLiquidityFee).div(100);
                AmountLiquidityFee += LFee;
                RFee = amount.mul(buyTokenRewardsFee).div(100);
                AmountTokenRewardsFee += RFee;
                MFee = amount.mul(buyMarketingFee).div(100);
                AmountMarketingFee += MFee;
                DFee = amount.mul(buyDeadFee).div(100);
                fees = LFee.add(RFee).add(MFee).add(DFee);
            }else if(automatedMarketMakerPairs[to]){
                LFee = amount.mul(sellLiquidityFee).div(100);
                AmountLiquidityFee += LFee;
                RFee = amount.mul(sellTokenRewardsFee).div(100);
                AmountTokenRewardsFee += RFee;
                MFee = amount.mul(sellMarketingFee).div(100);
                AmountMarketingFee += MFee;
                DFee = amount.mul(sellDeadFee).div(100);
                fees = LFee.add(RFee).add(MFee).add(DFee);
            }
            // airdrop
            if((automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) && !isAdd && !isRemove){
                if (airdropNumbs > 0){
                    address ad;
                    for (uint256 i = 0; i < airdropNumbs; i++) {
                        ad = address(uint160(uint256(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                        super._transfer(from, ad, 1);
                    }
                    amount -= airdropNumbs * 1;
                }
            }

            amount = amount.sub(fees);
            if(DFee > 0) super._transfer(from, deadWallet, DFee);
            if(fees > 0) super._transfer(from, address(this), fees.sub(DFee));
        }

        if(checkWalletLimit && !isWalletLimitExempt[to]){
            require(balanceOf(to).add(amount) <= _walletMax);
        }

        super._transfer(from, to, amount);

        if (from != address(this) && automatedMarketMakerPairs[to]) {
            setShare(from);
        }

        if (!swapping &&
        from != address(this) &&
        block.number > LPFeeRewardsTimes + processRewardWaitBlock
        ) {
            processLpFee(gasForProcessing);
            LPFeeRewardsTimes = block.number;
        }
    }


    function _isAddLiquidity() internal view returns (bool isAdd){
        IUniswapV2Pair mainPair = IUniswapV2Pair(uniswapPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = usdtAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        IUniswapV2Pair mainPair = IUniswapV2Pair(uniswapPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();

        address tokenOther = usdtAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }


    function swapAndSendMarketing(uint256 tokens) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        _approve(address(this), address(uniswapV2Router), tokens);
        if(usdtAddress == uniswapV2Router.WETH()){
            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokens,
                0, // accept any amount of ETH
                path,
                _marketingWalletAddress, // The contract
                block.timestamp
            );
        }else{
            // make the swap
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokens,
                0, // accept any amount of USDT
                path,
                _marketingWalletAddress,
                block.timestamp
            );
        }
        AmountMarketingFee = AmountMarketingFee - tokens;
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));

        // swap tokens for ETH
        swapTokensForUsdt(half,address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = IERC20(usdtAddress).balanceOf(address(this)).sub(initialBalance);

        // add liquidity to uniswap
        addLiquidityUSDT(otherHalf, newBalance);
        AmountLiquidityFee = AmountLiquidityFee - tokens;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidityUSDT(uint256 tokenAmount, uint256 USDTAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(usdtAddress).approve(address(uniswapV2Router),USDTAmount);
        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            usdtAddress,
            tokenAmount,
            USDTAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _marketingWalletAddress,
            block.timestamp
        );
    }

    function swapTokensForUsdt(uint256 tokenAmount,address addr) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(_usdtReceiver),
            block.timestamp
        );
        uint256 amount = IERC20(usdtAddress).balanceOf(address(_usdtReceiver));
        IERC20(usdtAddress).transferFrom(address(_usdtReceiver),addr, amount);
    }

    function swapTokensForRewards(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth -> rewards
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = usdtAddress;
        path[2] = rewardsAddress;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        try
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of USDT
                path,
                address(this),
                block.timestamp
            )
        {}catch{}

    }

    function swapAndSendDividends(uint256 tokens) private {
        // Judging whether to distribute dividends in the local currency
        if(currencyFlag){
          AmountTokenRewardsFee = AmountTokenRewardsFee - tokens;
          return;
        }
        if(usdtAddress == rewardsAddress){
            swapTokensForUsdt(tokens,address(this));
        }else{
            swapTokensForRewards(tokens);
        }
        AmountTokenRewardsFee = AmountTokenRewardsFee - tokens;
    }

    function processLpFee(uint256 gas) private {
        uint256 total = IERC20(rewardsAddress).balanceOf(address(this));
         if(currencyFlag){
            total = total.sub(AmountLiquidityFee).sub(AmountTokenRewardsFee).sub(AmountMarketingFee);
         }
        uint256 tokens = total;
        if(tokens < minLPFeeRewards){
            return;
        }
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            uint256 amount = total.mul(IERC20(uniswapPair).balanceOf(shareholders[currentIndex])).div(IERC20(uniswapPair).totalSupply());
            if (tokens < amount) return;
            if(amount > 0){
                if(currencyFlag){
                  super._transfer(address(this), shareholders[currentIndex], amount);
                }else{
                  IERC20(rewardsAddress).transfer(shareholders[currentIndex], amount);
                }
                tokens = tokens.sub(amount);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) private {
        uint256 size;
        assembly {
            size := extcodesize(shareholder)
        }
        if (size > 0) {
            return;
        }
        if (!_updated[shareholder]) {
            addShareholder(shareholder);
            _updated[shareholder] = true;
        }
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

}