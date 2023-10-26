/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

/**

Spectrum is a decentralized, private and secure marketplace where everyone has the opportunity to contribute, transact, and interact without compromising on privacy or security.

- No Registration Required
- Product-Based KYC
- Safeguarding Funds
- Pay with Cryptocurrency

Website: https://www.spectrummarket.io
X.com: https://x.com/Spectrum_Market
Telegram: https://t.me/Spectrum_Market
Linktree: https://linktr.ee/spectrummarket

*/

pragma solidity ^0.8.17;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SPECTRUM is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
    }

    uint256 private constant _totalSupply = 1e7 * 1e18;

    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    Tax public buyTaxes = Tax(20);
    Tax public sellTaxes = Tax(40);
    Tax public transferTaxes = Tax(0);

    mapping(address => bool) private whitelisted;

    uint256 public startBlock = 0;
    uint256 public deadBlocks = 5;
    uint256 public maxWallet = _totalSupply * 2 / 100;
    mapping(address => bool) public isBlacklisted;

    uint256 public swapTokensAtAmount = _totalSupply / 100000;
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    address public marketingWallet = 0x91b12fdD0dCDD2F7d09Be69bE5F2C9CB4DA0000f;

    event marketingWalletChanged(address indexed _trWallet);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);

    bool public tradingEnabled = false;

    constructor() ERC20("Spectrum", "SPEC") {
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());

        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;

        _mint(msg.sender, _totalSupply);
    }

    function setmarketingWallet(address _newmarketing) external onlyOwner {
        require(_newmarketing != address(0), "can not set marketing to dead wallet");
        marketingWallet = _newmarketing;
        emit marketingWalletChanged(_newmarketing);
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0 && _newAmount <= (_totalSupply * 1) / 100,
            "Minimum swap amount must be greater than 0 and less than 0.5% of total supply!"
        );
        swapTokensAtAmount = _newAmount;
        emit SwapThresholdUpdated(swapTokensAtAmount);
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled) ? false : true;
    }

    function setWhitelistStatus(address _wallet, bool _status) external onlyOwner {
        whitelisted[_wallet] = _status;
        emit Whitelist(_wallet, _status);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function blacklistAddress(address _target, bool _status) external onlyOwner {
        if (_status) {
            require(_target != pairAddress, "Can't blacklist liquidity pool");
            require(_target != address(this), "Can't blacklisted the token");
        }
        isBlacklisted[_target] = _status;
    }

    function blacklistAddresses(address[] memory _targets, bool[] memory _status) external onlyOwner {
        for (uint256 i = 0; i < _targets.length; i++) {
            if (_status[i]) {
                require(_targets[i] != pairAddress, "Can't blacklist liquidity pool");
                require(_targets[i] != address(this), "Can't blacklisted the token");
            }
            isBlacklisted[_targets[i]] = _status[i];
        }
    }

    function startTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        startBlock = block.number;
    }

    function pauseTrading() external onlyOwner {
        tradingEnabled = false;
    }

    function updateBuyTax(uint256 marketingTax) external onlyOwner {
        require(marketingTax <= 10, "can't set buy tax over 10%");
        buyTaxes.marketingTax = marketingTax;
    }

    function updateSellTax(uint256 marketingTax) external onlyOwner {
        require(marketingTax <= 40, "can't set buy tax over 40%");
        sellTaxes.marketingTax = marketingTax;
    }

    function _takeTax(address _from, address _to, uint256 _amount) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }

        require(!isBlacklisted[_from] && !isBlacklisted[_to], "You are blocked from buy/sell/transfers");

        require(tradingEnabled, "Trading not enabled yet!");

        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = sellTaxes.marketingTax;
        } else if (_from == pairAddress) {
            totalTax = buyTaxes.marketingTax;
        }

        if (_to != pairAddress) {
            require(_amount + balanceOf(_to) <= maxWallet, "can't buy more than max wallet");
        }

        _antiBot(_from, _to);

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled && pairAddress == _to && canSwap && !whitelisted[_from] && !whitelisted[_to]
                && !isSwapping
        ) {
            isSwapping = true;
            internalSwap(swapTokensAtAmount);
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }

    function internalSwap(uint256 swapAmount) internal {
        uint256 taxAmount = swapAmount;
        if (taxAmount == 0 || swapAmount == 0) {
            return;
        }
        swapToETH(balanceOf(address(this)));
        (bool success,) = marketingWallet.call{value: address(this).balance}("");
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount, 0, path, address(this), block.timestamp
        );
    }

    function adjustDeadBlock(uint256 db) external onlyOwner {
        require(!tradingEnabled, "This function is disabled after launch");
        require(db <= 5, "cant set deadblock count to more than 5");
        deadBlocks = db;
    }

    function removeLimits() external onlyOwner {
        maxWallet = _totalSupply;
        buyTaxes.marketingTax = 5;
        sellTaxes.marketingTax = 5;
    }

    function _antiBot(address from, address to) internal {
        if (block.number <= startBlock + deadBlocks) {
            if (from == pairAddress) {
                isBlacklisted[to] = true;
            }
            if (to == pairAddress) {
                isBlacklisted[from] = true;
            }
        }
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transferring ETH failed");
    }

    function withdrawStuckTokens(address ERC20_token) external onlyOwner {
        bool success = IERC20(ERC20_token).transfer(msg.sender, IERC20(ERC20_token).balanceOf(address(this)));
        require(success, "trasfering tokens failed!");
    }

    receive() external payable {}
}