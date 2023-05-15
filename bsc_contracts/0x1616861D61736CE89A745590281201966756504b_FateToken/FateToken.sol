/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

/*
Fate Token Verion 3
Created by FateLabz

ALWAYS VERIFY

Website: https://fatelabz.com 
Telegram: https://t.me/fatelabz
Discord: https://discord.gg/V6JRTNuU3T
Twitter: https://twitter.com/fatelabz
Instagram: https://instagram.com/fatelabz 
TikTok: https://tiktok.com/@fatelabz
Facebook: https://facebook.com/fatelabz 
Medium: https://medium.com/@fatelabz
Twitch: https://twitch.tv/fatelabz 
Youtube: https://youtube.com/@fatelabz
Linkedin: https://linkedin.com/company/fatelabz/  
*/  

//SPDX-License-Identifier: MIT     
pragma solidity ^0.8.17; 
 
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
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        return 18;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline 
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IFateIVN {
    function distribute() external payable;
} 

contract FateToken is ERC20, Ownable{
    using Address for address payable;

    IRouter public router;
    address public pair;
    address public ROUTER;

    IFateIVN _IVN;
    address public IVN;
    bool public ivn = false;

    uint256 public supply;
    uint256 public liquidate;
    uint256 public maxBuy;
    uint256 public maxSell;
    uint256 public maxBal;

    bool private autoLiquidity;
    bool public providingLiquidity;
    bool public enabled;

    struct Taxes {
        uint256 ivn;
        uint256 lp; 
    }

    Taxes public taxTX;
    Taxes public taxBuy; 
    Taxes public taxSell;

    mapping (address => bool) public blacklisted; 
    mapping (address => bool) public exempt;
    mapping (address => bool) public locked; 
    mapping (address => bool) public frozen;

    bool private _liquidityMutex = false; 
    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        } 
    } 
 
    //Events
    event FateEnabled(string message);
    event FateEvent(uint256 value, string message);
    event FateTaxEvent(uint256 indexed transferTaxRate, uint256 indexed maxTransferTax, string message);
    event FateAddressEvent(address addr, string message);
    event FateLiquidationEvent(string message);
    event FateIVNEvent(string message);
    

    constructor() ERC20("Fate Token", "FATE") payable {
        supply = num(100_000_000_000);
        liquidate = num(100_000);
        maxBuy = num(250_000_000);
        maxSell = num(100_000_000);
        maxBal = num(500_000_000);
        autoLiquidity = true;
        providingLiquidity = false;
        enabled = false;
        _liquidityMutex = false; 

        taxTX   = Taxes(0, 10);
        taxBuy  = Taxes(40, 10);
        taxSell = Taxes(40, 10);

        ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        IRouter _router = IRouter(ROUTER);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;

        exempt[address(this)] = true;
        exempt[msg.sender] = true;
        _mint(msg.sender,supply);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blacklisted[sender] && !blacklisted[recipient], "Tokens cannot be transfered.");
        if(!exempt[sender] && !exempt[recipient]){require(enabled, "Trading not enabled");}
        if(sender == pair && !exempt[recipient] && !_liquidityMutex){
            require(amount <= maxBuy, "You are exceeding max buy amount.");
            require(balanceOf(recipient) + amount <= maxBal, "Cannot exceed max balance.");
        }
        if(sender != pair && !exempt[recipient] && !exempt[sender] && !_liquidityMutex){
            require(!locked[sender] && !frozen[sender], "Tokens are locked");
            require(amount <= maxSell, "You are exceeding the max sell amount.");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxBal, "Cannot exceed max balance.");
            }
        }

        uint256 feeswap;
        uint256 fee;
        Taxes memory currentTaxes;

        if (_liquidityMutex || exempt[sender] || exempt[recipient]) fee = 0;
        else if(recipient == pair){
            require(!locked[sender] && !frozen[sender], "Tokens are locked");
            feeswap = taxSell.lp + taxSell.ivn;
            currentTaxes = taxSell;
        }
        else if(sender == pair){
            feeswap = taxBuy.lp + taxBuy.ivn;
            currentTaxes = taxBuy;
        }
        else{
            require(!locked[sender] && !frozen[sender], "Tokens are locked");
            feeswap =  taxTX.lp + taxTX.ivn;
            currentTaxes = taxTX;
        }
 
        fee = amount * feeswap / 1000;

        if (providingLiquidity && sender != pair && feeswap > 0 && !exempt[sender] && !exempt[recipient]) process(feeswap, currentTaxes);
        super._transfer(sender, recipient, amount - fee);
        if(fee > 0){
            super._transfer(sender, address(this), fee);
        }
    }
    function process(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {
        uint256 tokens = balanceOf(address(this));
        if (tokens >= liquidate) {
            if(liquidate > 1){
                tokens = liquidate;
            }

            uint256 denom = feeswap * 2;
            uint256 LP_TOKENS = tokens * swapTaxes.lp / denom;
            uint256 toSwap = tokens - LP_TOKENS;

            uint256 initialBalance = address(this).balance;

            liquify(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denom - swapTaxes.lp);
            uint256 PAIR_TOKENS = unitBalance * swapTaxes.lp; 

            if(autoLiquidity){
                if(PAIR_TOKENS > 0){
                    addLiquidity(LP_TOKENS, PAIR_TOKENS);
                }
            }

            uint256 IVNamount = unitBalance * 2 * swapTaxes.ivn;
            if(IVNamount > 0){
                if(ivn){
                    divvy(IVNamount); 
                }else{
                    payable(owner()).sendValue(IVNamount);
                }
            }
        }  
    }  
    function divvy(uint256 amount) private {  
        _IVN.distribute{value: amount}();
        emit FateLiquidationEvent("IVN Distribution");
    }
    function liquify(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp) {
            emit FateLiquidationEvent("Liquidation Suceeded");
        } catch (bytes memory /* revertReason */) {
            emit FateLiquidationEvent("Liquidation Failed");
        }
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0, owner(),block.timestamp);
    }
    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        liquidate = new_amount;
        emit FateEvent(new_amount, "Update Liquidate Threshold");
    }
    function taxLimit(Taxes memory taxes) internal pure returns(bool){
        //Cannot exceed 25% Total
        require(taxes.lp <= 125, "Cannot exceed 12.5%");
        require(taxes.ivn <= 125, "Cannot exceed 12.5%");
        return true;
    }
    function updateTaxes(Taxes memory taxes) external onlyOwner {
        if(taxLimit(taxes)){
            taxTX = taxes;
            emit FateTaxEvent(taxes.ivn,taxes.lp, "Updated Transfer Tax");
        }
    }
    function updateSellTaxes(Taxes memory taxes) external onlyOwner{
        if(taxLimit(taxes)){
            taxSell = taxes;
            emit FateTaxEvent(taxes.ivn,taxes.lp, "Updated Sell Tax");
        }
    }
    function updateBuyTaxes(Taxes memory taxes) external onlyOwner{
        if(taxLimit(taxes)){
            taxBuy = taxes;
            emit FateTaxEvent(taxes.ivn,taxes.lp, "Updated Buy Tax");
        }
    } 
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
        emit FateAddressEvent(newPair, "Updated Router & Pair");
    }
    function updateTradingEnabled() external onlyOwner{
        enabled = true;
        providingLiquidity = true;
        emit FateEnabled("Trading Enabled");
    }
    function updateIsBlacklisted(address account, bool state) external onlyOwner{
        blacklisted[account] = state;
        emit FateAddressEvent(account, "Updated Blacklist");
    }
    function bulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            blacklisted[accounts[i]] = state;
        }
    }
    function updateExemptFee(address _address, bool state) external onlyOwner {
        exempt[_address] = state;
        emit FateAddressEvent(_address, "Updated Excemption");
    }
    function updateMaxTxLimit(uint256 buy, uint256 sell) external onlyOwner {
        require(buy >= supply/1000, "Buy limit limit must exceed 0.1% of total supply");
        require(sell >= supply/1000, "Sell limit must exceed 0.1% of total supply");
        maxBuy = buy;
        maxSell = sell;
    }
    function updateMaxWalletlimit(uint256 amount) external onlyOwner{
        require(amount >= supply/1000, "Buy limit limit must exceed 0.1% of total supply");
        maxBal = num(amount);
    }
    function updateRouter(address newRouter) external onlyOwner{
        router = IRouter(newRouter);
    }
    function updatePair(address newPair) external onlyOwner{
        pair = newPair;
    }
    function num(uint256 _int) internal view returns (uint256 _num){
       return _int * (10 ** decimals());
    }
    function setIVN(address addr) external onlyOwner {
        ivn=true;
        IVN = addr;
        _IVN = IFateIVN(IVN);
        exempt[addr] = true;
        emit FateAddressEvent(addr, "IVN Updated");
    }
    function disableIVN() external onlyOwner {
        exempt[IVN] = false;
        ivn=false;
        _IVN = IFateIVN(address(0));
        IVN = address(0);
        emit FateAddressEvent(address(0), "IVN Disabled");
    }
    function lock() external {
        if(!locked[msg.sender]){
            locked[msg.sender] = true;
        }
    }
    function unlock() external {
        if(locked[msg.sender]){
            locked[msg.sender] = false;
        }
    }
    function freeze() external {
        if(!frozen[msg.sender]){
            frozen[msg.sender] = true;
        }
    }
    function unfreeze(address account) external onlyOwner{
        frozen[account] = false;
    }
    // fallbacks
    receive() external payable {}

}