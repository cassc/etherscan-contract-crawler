/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract LYF is ERC20, Ownable {
    using SafeMath for uint256;


    uint256 private constant _totalSupply = 120_000_000 * 1e18;

    //Router
    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    //Buy Taxes
    uint256 public BuyFinanceTax = 20;
    uint256 public BuyTreasury = 13;
    uint256 public BuyFoundation = 17;
    uint256 public BuyRewards = 10;
    uint256 public BuyAutoLiquidity = 0;

    uint256 public buyTaxes = BuyFinanceTax + BuyTreasury + BuyFoundation+ BuyRewards + BuyAutoLiquidity;

    //Sell Taxes
    uint256 public SellFinanceTax = 25;
    uint256 public SellTreasury = 15;
    uint256 public SellFoundation = 20;
    uint256 public SellRewards = 10;
    uint256 public SellAutoLiquidity = 10;

    uint256 public sellTaxes = SellFinanceTax + SellTreasury + SellFoundation + SellRewards + SellAutoLiquidity;

    //Transfer Taxes
    uint256 public transferTaxes = 0;

    //Whitelisting from taxes and trading limits
    mapping(address => bool) private whitelisted;

    //Blacklist wallets
    mapping(address => bool) private blacklisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //Collect 0.001% of total supply to swap to taxes
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingEnabled = false;
    uint256 public startTradingBlock;

    //Wallets

    address payable public FinanceAddress = payable(0x313DF74b4C441c1aD253D89Bb172141B8bA213b1);
    address payable public TreasuryAddress = payable(0x92C2a076680c0B47f717ac587bf0b895Dde3B252);
    address payable public FoundationAddress = payable(0xE4752A7EBC1948Cb8E01234df49e6e576e1931e3);
    address payable public RewardsAddress = payable(0x16dDbD8D5C7E11Fb7a819B55D6A78E03A909d828);

    //Events
    event FinanceAddressChanged(address indexed _trWallet); 
    event TreasuryAddressChanged(address indexed _trWallet);
    event FoundationAddressChanged(address indexed _trWallet);
    event RewardsAddressChanged(address indexed _trWallet);
    event BuyFeesUpdated(uint256 indexed newBuyFinanceTax, uint256 newBuyTreasury, uint256 newBuyFoundation, uint256 newBuyRewards, uint256 newBuyAutoLiquidity);
    event SellFeesUpdated(uint256 indexed newSellFinanceTax, uint256 newSellTreasury, uint256 newSellFoundation, uint256 newSellRewards, uint256 newSellAutoLiquidity);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);
    event Blacklist(address indexed _target, bool indexed _status);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("Lillian Token", "LYF") {

        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[FoundationAddress] = true;
        whitelisted[TreasuryAddress] = true;
        whitelisted[FinanceAddress] = true;
        whitelisted[RewardsAddress] = true;
        whitelisted[address(this)] = true;       
        _mint(0xeCe1129c4518dA93C802648d5220D34Bcc7e9AC0, _totalSupply);

    }

    function setFinanceAddress(address _newaddress) external onlyOwner {
        require(_newaddress != address(0), "can not set marketing to dead wallet");
        FinanceAddress = payable(_newaddress);
        emit FinanceAddressChanged(_newaddress);
    }

    function setTreasuryAddress(address _newaddress) external onlyOwner {
        require(_newaddress != address(0), "can not set marketing to dead wallet");
        TreasuryAddress = payable(_newaddress);
        emit TreasuryAddressChanged(_newaddress);
    }

    function setFoundationAddress(address _newaddress) external onlyOwner {
        require(_newaddress != address(0), "can not set marketing to dead wallet");
        FoundationAddress = payable(_newaddress);
        emit FoundationAddressChanged(_newaddress);
    }

    function setRewardsAddress(address _newaddress) external onlyOwner {
        require(_newaddress != address(0), "can not set marketing to dead wallet");
        RewardsAddress = payable(_newaddress);
        emit RewardsAddressChanged(_newaddress);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        startTradingBlock = block.number;
    }

    function disableTrading() external onlyOwner {
        require(tradingEnabled, "Trading is already disabled");
        tradingEnabled = false;
    }

    function setBuyTaxes(uint256 _newBuyFinanceTax, uint256 _newBuyTreasury, uint256 _newBuyFoundation, uint256 _newBuyRewards, uint256 _newBuyAutoLiquidity) external onlyOwner {
        BuyFinanceTax = _newBuyFinanceTax;
        BuyTreasury = _newBuyTreasury;
        BuyFoundation = _newBuyFoundation;
        BuyRewards = _newBuyRewards;
        BuyAutoLiquidity = _newBuyAutoLiquidity;
        buyTaxes = BuyFinanceTax.add(BuyTreasury).add(BuyFoundation).add(BuyRewards).add(BuyAutoLiquidity);
        emit BuyFeesUpdated(BuyFinanceTax, BuyTreasury, BuyFoundation, BuyRewards, BuyAutoLiquidity);
    }

    function setSellTaxes(uint256 _newSellFinanceTax, uint256 _newSellTreasury, uint256 _newSellFoundation, uint256 _newSellRewards, uint256 _newSellAutoLiquidity) external onlyOwner {
        SellFinanceTax = _newSellFinanceTax;
        SellTreasury = _newSellTreasury;
        SellFoundation = _newSellFoundation;
        SellRewards = _newSellRewards;
        SellAutoLiquidity = _newSellAutoLiquidity;
        sellTaxes = SellFinanceTax.add(SellTreasury).add(SellFoundation).add(SellRewards).add(SellAutoLiquidity);
        emit SellFeesUpdated(SellFinanceTax, SellTreasury, SellFoundation, SellRewards, SellAutoLiquidity);
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0 && _newAmount <= (_totalSupply * 5) / 1000, "Minimum swap amount must be greater than 0 and less than 0.5% of total supply!");
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

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklisted[_address] = _isBlacklisted;
        emit Blacklist(_address, _isBlacklisted);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function checkBlacklist(address _address) external view returns (bool) {
        return blacklisted[_address];
    }

    // this function is reponsible for managing tax, if _from or _to is whitelisted, we simply return _amount and skip all the limitations
    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        uint256 totalTax = transferTaxes;

        if (_to == pairAddress) {
            totalTax = sellTaxes;
        } else if (_from == pairAddress) {
            totalTax = buyTaxes;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 1000;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

function _transfer(
    address _from,
    address _to,
    uint256 _amount
) internal virtual override {
    require(_from != address(0), "transfer from address zero");
    require(_to != address(0), "transfer to address zero");
    require(_amount > 0, "Transfer amount must be greater than zero");
    require(!blacklisted[_from], "Transfer from blacklisted address");
    require(!blacklisted[_to], "Transfer to blacklisted address");
    uint256 toTransfer = _takeTax(_from, _to, _amount);

    bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
    if (
        !whitelisted[_from] &&
        !whitelisted[_to] &&
        !blacklisted[_from] &&
        !blacklisted[_to] 
    ) {
        require(tradingEnabled, "Trading not active");
        if (
            pairAddress == _to &&
            swapAndLiquifyEnabled &&
            canSwap &&
            !isSwapping
        ) {
            internalSwap();
        }
    }
    super._transfer(_from, _to, toTransfer);
}

    function internalSwap() internal {
    isSwapping = true;
    uint256 taxAmount = balanceOf(address(this)); 
    if (taxAmount == 0) {
        return;
    }

    uint256 totalFee = (buyTaxes).add(sellTaxes);

    uint256 FinanceShare =(BuyFinanceTax).add(SellFinanceTax);
    uint256 TreasuryShare = (BuyTreasury).add(SellTreasury);
    uint256 FoundationShare =(BuyFoundation).add(SellFoundation);
    uint256 RewardsShare =(BuyRewards).add(SellRewards);
    uint256 LiquidityShare =(BuyAutoLiquidity).add(SellAutoLiquidity);

    if (LiquidityShare == 0) {
        totalFee = FinanceShare.add(TreasuryShare).add(FoundationShare).add(RewardsShare);
    }

    uint256 halfLPTokens = 0;
    if (totalFee > 0) {
        halfLPTokens = taxAmount.mul(LiquidityShare).div(totalFee).div(2);
    }
    uint256 swapTokens = taxAmount.sub(halfLPTokens);
    uint256 initialBalance = address(this).balance;
    swapToETH(swapTokens);
    uint256 newBalance = address(this).balance.sub(initialBalance);

    uint256 ethForLiquidity = 0;
    if (LiquidityShare > 0) {
        ethForLiquidity = newBalance.mul(LiquidityShare).div(totalFee).div(2);
    
    addLiquidity(halfLPTokens, ethForLiquidity);
    emit SwapAndLiquify(halfLPTokens, ethForLiquidity, halfLPTokens);
    }
    uint256 ethForFinance = newBalance.mul(FinanceShare).div(totalFee);
    uint256 ethForTreasury = newBalance.mul(TreasuryShare).div(totalFee);
    uint256 ethForFoundation = newBalance.mul(FoundationShare).div(totalFee);
    uint256 ethForRewards = newBalance.mul(RewardsShare).div(totalFee);

    transferToAddressETH(FinanceAddress, ethForFinance);
    transferToAddressETH(TreasuryAddress, ethForTreasury);
    transferToAddressETH(FoundationAddress, ethForFoundation);
    transferToAddressETH(RewardsAddress, ethForRewards);

    isSwapping = false;
}

    function transferToAddressETH(address payable recipient, uint256 amount) private 
    {
        recipient.transfer(amount);
    }    

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function withdrawStuckETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH available to withdraw");

        (bool success, ) = address(msg.sender).call{value: balance}("");
        require(success, "transferring ETH failed");
    }

    function withdrawStuckTokens(address ERC20_token) external onlyOwner {
        require(ERC20_token != address(this), "Owner cannot claim native tokens");

        uint256 tokenBalance = IERC20(ERC20_token).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens available to withdraw");

        bool success = IERC20(ERC20_token).transfer(msg.sender, tokenBalance);
        require(success, "transferring tokens failed!");
    }

    receive() external payable {}
}