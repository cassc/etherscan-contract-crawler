/**
 *Submitted for verification at Etherscan.io on 2023-01-04
*/

// 🦢GIFT OF DOGE🦢
// 🕊   https://twitter.com/GiftofDoge
// 📰  https://medium.com/@giftofdoge
// 🔵  https://t.me/GiftOfDoge
// 🌍  https://giftofdoge.com
// 💰  https://app.giftofdoge.com

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
        emit OwnershipTransferred(_owner, locker);
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

contract GiftOfDoge is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public taxAddress;
    address public devAddress;

    bool public swapEnabled = true;

    bool public marketingBuyFees = true;
    bool public devBuyFees = true;
    bool public marketingSellFees = true;
    bool public devSellFees = true;

    uint256 public maxWalletSize;

    uint256 public tradingActiveTime;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public pairs;

    event SetPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedTaxAddress(address indexed newWallet);
    event UpdatedDevAddress(address indexed newWallet);

    constructor() ERC20("Gift Of Doge", "GOD") {
        address newOwner = msg.sender;

        // initialize router
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        dexRouter = IDexRouter(routerAddress);

        _approve(newOwner, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 10_000_000_000 * _decimalFactor;
        maxWalletSize = totalSupply / 100;

        swapTokensAtAmount = (totalSupply * 1) / 10000; // 0.01 %

        taxAddress = 0x3D8FD4A40652efF02014d45E8D5514B224bd3CEc;
        devAddress = newOwner;

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _initialTransfer(newOwner, totalSupply / 2);
        _initialTransfer(address(0xdead), totalSupply / 2);

        transferOwnership(newOwner);
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

    function toggleMarketingFees(bool sellFee) external onlyOwner {
        if(sellFee)
            marketingSellFees = !marketingSellFees;
        else
            marketingBuyFees = !marketingBuyFees;
    }

    function toggleDevFees(bool sellFee) external onlyOwner {
        if(sellFee)
            devSellFees = !devSellFees;
        else
            devBuyFees = !devBuyFees;
    }

    function getSellFees() public view returns (uint256) {
        uint256 _sf = 0;
        if(marketingSellFees) _sf += 4;
        if(devSellFees) _sf += 1;
        return _sf;
    }

    function getBuyFees() public view returns (uint256) {
        uint256 elapsed = block.timestamp - tradingActiveTime;
        if(elapsed < 5 minutes) {
            uint256 taxReduced = (elapsed / 30) * 10;
            if (taxReduced < 90) 
                return 90 - taxReduced;
        }

        uint256 _bf = 0;
        if(marketingBuyFees) _bf += 4;
        if(devBuyFees) _bf += 1;
        return _bf;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
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
            super._transfer(from, to, amount);
        }
        else {
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

            super._transfer(from, to, amount);
        }
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

        uint256 _mkFee = (marketingBuyFees ? 4 : 0) + (marketingSellFees ? 4 : 0);
        uint256 _dvFee = (devBuyFees ? 1 : 0) + (devSellFees ? 1 : 0);
        uint256 _totalFees = _mkFee + _dvFee;

        bool success;
        swapTokensForEth(amountToSwap);

        uint256 ethBalance = address(this).balance;

        uint256 amountMarketing = (ethBalance * _mkFee) / _totalFees;

        if(amountMarketing > 0)
            (success, ) = taxAddress.call{value: amountMarketing}("");

        (success, ) = devAddress.call{value: address(this).balance}("");
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setTaxAddress(address _taxAddress) external onlyOwner {
        require(_taxAddress != address(0), "_taxAddress address cannot be 0");
        taxAddress = _taxAddress;
        emit UpdatedTaxAddress(_taxAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = _devAddress;
        emit UpdatedDevAddress(_devAddress);
    }

    function launch(uint256 tokens, uint256 toLP, address[] calldata _wallets, uint256[] calldata _tokens) external payable onlyOwner {
        require(tradingActiveTime == 0);
        require(msg.value >= toLP, "Insufficient funds");
        require(tokens > 0, "No LP tokens specified");
        bool purchasing = _wallets.length > 0;

        address ETH = dexRouter.WETH();

        lpPair = IDexFactory(dexRouter.factory()).createPair(ETH, address(this));
        pairs[lpPair] = true;

        super._transfer(msg.sender, address(this), tokens * _decimalFactor);

        dexRouter.addLiquidityETH{value: toLP}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        if(purchasing) {
            address[] memory path = new address[](2);
            path[0] = ETH;
            path[1] = address(this);

            if(_wallets.length > 0) {
                for(uint256 i = 0; i < _wallets.length; i++) {
                    dexRouter.swapETHForExactTokens{value: address(this).balance} (
                        _tokens[i] * _decimalFactor,
                        path,
                        _wallets[i],
                        block.timestamp
                    );
                }
            }
        }

        withdrawStuckETH();

        tradingActiveTime = block.timestamp;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - (balanceOf(address(0xdead)) + balanceOf(address(0)));
    }

    function setMaxWallet(uint256 percent) external onlyOwner() {
        require(percent > 0);
        maxWalletSize = (totalSupply() * percent) / 100;
    }
}