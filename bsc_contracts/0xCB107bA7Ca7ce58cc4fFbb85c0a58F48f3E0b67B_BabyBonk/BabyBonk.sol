/**
 *Submitted for verification at BscScan.com on 2023-01-05
*/

// Baby Bonk
// Telegram: https://t.me/TheBabyBonk
// Twitter:  https://twitter.com/TheBabyBonk
// Website:  https://babybonk.org

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a CTransferU event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
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

    function _initialTransfer(address to, uint256 amount) internal virtual {
        _balances[to] = amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract Ownable is Context {
    address private _owner;
    uint256 public unlocksAt;
    address public locker;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function lockContract(uint256 _days) external onlyOwner {
        require(locker == address(0), "Contract already locked");
        require(_days > 0, "No lock period specified");
        unlocksAt = block.timestamp + (_days * 1 days);
        locker = owner();
        renounceOwnership();
    }

    function unlockContract() external {
        require(locker != address(0) && msg.sender == locker, "Caller is not authorized");
        require(unlocksAt <= block.timestamp, "Contract still locked");
        emit OwnershipTransferred(address(0), locker);
        _owner = locker;
        locker = address(0);
        unlocksAt = 0;
    }
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IAntiSnipe {
  function setTokenOwner(address owner, address pair) external;

  function onPreTransferCheck(
    address sender,
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract BabyBonk is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public taxAddress = 0x69e05212b15b1dC90468E6Ca196005ED542ea77A;
    address public lpAddress = 0x000000000000000000000000000000000000dEaD;
    address public commAddress = 0xcF3bdF60520a740b72bf00876E5ea48BF82E518d;

    bool public swapEnabled = true;

    uint256 public marketingBuyFees = 3;
    uint256 public liquidityBuyFees = 2;
    uint256 public commBuyFees = 1;
    uint256 public marketingSellFees = 3;
    uint256 public liquiditySellFees = 2;
    uint256 public commSellFees = 1;
    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;
    uint256 public maxWalletSize;

    uint256 public tradingActiveTime;
    mapping (address => bool) public whitelist1;
    mapping (address => bool) public whitelist2;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public pairs;

    IAntiSnipe public antisnipe;
    bool public protectionEnabled = false;
    bool public protectionDisabled = false;

    event SetPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TargetLiquiditySet(uint256 percent);
    event ProtectionSet(address indexed protection);
    event ProtectionToggle(bool isEnabled);
    event ProtectionDisabled();

    constructor() ERC20("Baby Bonk", "BBONK") {
        address newOwner = 0x8B09a6456Cab1c92592caE34f85bcF1585F9582f;

        // initialize router
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        dexRouter = IDexRouter(routerAddress);

        _approve(newOwner, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 1_000_000_000_000_000 * _decimalFactor;
        maxWalletSize = totalSupply / 100;

        swapTokensAtAmount = (totalSupply * 2) / 10000; // 0.02 %

        excludeFromFees(newOwner, true);
        excludeFromFees(taxAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        whitelist1[address(this)] = true;

        _initialTransfer(address(this), totalSupply / 2);
        _initialTransfer(address(0xdead), totalSupply / 2);

        transferOwnership(msg.sender);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 9;
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
        swapTokensAtAmount = newAmount;
    }

    function toggleSwap() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function setPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != lpPair,
            "The pair cannot be removed from pairs"
        );

        pairs[pair] = value;
        emit SetPair(pair, value);
    }

    function setMarketingFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        marketingSellFees = sellFee;
        marketingBuyFees = buyFee;
        require(getSellFees() + getBuyFees() <= 20, "Fees too high");
    }

    function setLiquidityFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        require(((buyFee + sellFee) / 2) * 2 == buyFee + sellFee, "Liquidity must be an even total");
        liquiditySellFees = sellFee;
        liquidityBuyFees = buyFee;
        require(getSellFees() + getBuyFees() <= 20, "Fees too high");
    }

    function setCommFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        commSellFees = sellFee;
        commBuyFees = buyFee;
        require(getSellFees() + getBuyFees() <= 20, "Fees too high");
    }

    function getSellFees() public view returns (uint256) {
        return marketingSellFees + liquiditySellFees + commSellFees;
    }

    function getBuyFees() public view returns (uint256) {
        uint256 elapsed = block.timestamp - tradingActiveTime;
        if(elapsed < 5 minutes) {
            uint256 taxReduced = (elapsed / 30) * 10;
            if (taxReduced < 90) 
                return 90 - taxReduced;
        }

        return marketingBuyFees + liquidityBuyFees + commBuyFees;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if(tradingActiveTime == 0 && whitelist2[recipient])
            require(balanceOf(recipient) + amount <= maxWalletSize / 2, "Transfer amount exceeds the bag size.");
        require(balanceOf(recipient) + amount <= maxWalletSize, "Transfer amount exceeds the bag size.");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(tradingActiveTime == 0) {
            require(whitelist1[from] || whitelist1[to] || whitelist2[from] || whitelist2[to], "Whitelist in effect");
            require(pairs[from] || pairs[to] || from == address(this) || to == address(this), "No transfers during whitelist period");
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if (!pairs[to] && to != address(0xdead)) {
                checkWalletLimit(to, amount);
            }

            uint256 fees = 0;
            uint256 _sf = getSellFees();
            uint256 _bf = getBuyFees();

            if (swapEnabled && !swapping && pairs[to] && _bf + _sf > 0) {
                swapping = true;
                swapBack(amount);
                swapping = false;
            }

            if (pairs[to] &&_sf > 0) {
                fees = (amount * _sf) / 100;
            }
            else if (_bf > 0 && pairs[from]) {
                fees = (amount * _bf) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        if (tradingActiveTime > 0 && protectionEnabled && !_isExcludedFromFees[from])
            antisnipe.onPreTransferCheck(msg.sender, from, to, amount);

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 amountToSwap = balanceOf(address(this));
        if (amountToSwap < swapTokensAtAmount) return;
        if (amountToSwap == 0) return;

        if (amountToSwap > swapTokensAtAmount * 10) amountToSwap = swapTokensAtAmount * 10;

        if(amountToSwap > amount) amountToSwap = amount;

        uint256 _lpFee = liquidityBuyFees + liquiditySellFees;
        uint256 _mkFee = marketingBuyFees + marketingSellFees;
        uint256 _chFee = commBuyFees + commSellFees;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : _lpFee;
        uint256 _totalFees = dynamicLiquidityFee + _mkFee + _chFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / _totalFees) / 2;
        amountToSwap -= amountToLiquify;

        bool success;
        swapTokensForEth(amountToSwap);

        uint256 ethBalance = address(this).balance;

        _totalFees -= dynamicLiquidityFee / 2;
        uint256 amountLiquidity = (ethBalance * dynamicLiquidityFee) / _totalFees / 2;
        uint256 amountComm = (ethBalance * _chFee) / _totalFees;

        if(amountLiquidity > 0) {
            //Guaranteed swap desired to prevent trade blockages, return values ignored
            dexRouter.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                lpAddress,
                block.timestamp
            );
        }

        if(amountComm > 0)
            (success, ) = commAddress.call{value: amountComm}("");

        (success, ) = taxAddress.call{value: address(this).balance}("");
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function launch() external payable onlyOwner {
        require(tradingActiveTime == 0);
        require(msg.value >= 10 ether, "Insufficient funds");

        address ETH = dexRouter.WETH();

        lpPair = IDexFactory(dexRouter.factory()).createPair(ETH, address(this));
        pairs[lpPair] = true;
        antisnipe.setTokenOwner(address(this), lpPair);

        dexRouter.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }

    function endWhitelist() external onlyOwner {
        require(tradingActiveTime == 0, "Whitelist already ended");
        tradingActiveTime = block.timestamp;
    }

    function updateWhitelist1(address[] calldata _addresses, bool _enabled) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist1[_addresses[i]] = _enabled;
        }
    }

    function updateWhitelist2(address[] calldata _addresses, bool _enabled) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist2[_addresses[i]] = _enabled;
        }
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit TargetLiquiditySet(_target * 100 / _denominator);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - (balanceOf(address(0xdead)) + balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(lpPair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function setMaxWallet(uint256 percent) external onlyOwner() {
        require(percent > 0);
        maxWalletSize = (totalSupply() * percent) / 100;
    }

    function setProtectionEnabled(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled, "Protection disabled");
        protectionEnabled = _protect;
        emit ProtectionToggle(_protect);
    }
    
    function setProtection(address _protection, bool _call) public onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled, "Protection disabled");
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(address(this), lpPair);
        
        emit ProtectionSet(_protection);
    }
    
    function disableProtection() external onlyOwner {
        protectionDisabled = true;
        emit ProtectionDisabled();
    }

    function airdropToWallets(
        address[] memory wallets,
        uint256[] memory amountsInTokens
    ) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "Arrays must be the same length");

        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(msg.sender, wallets[i], amountsInTokens[i]);
        }
    }
}