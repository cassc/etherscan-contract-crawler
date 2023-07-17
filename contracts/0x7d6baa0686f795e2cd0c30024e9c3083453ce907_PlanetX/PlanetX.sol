/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

/**
Telegram: https://t.me/planetX_love
Website: https://www.planetx.love/
Twitter: https://twitter.com/Planet_Save_X
Medium: https://medium.com/@planetx.save
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _tokengeneration(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: transfer to the zero address");
        _totalSupply = amount;
        _balances[account] = amount;
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

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface uniswapV2Router {
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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PlanetX is ERC20, Ownable {
    using Address for address payable;
    uniswapV2Router public IUniswapV2Router02;
    address public uniswapV2Pair;
    bool private _inSwap = false;
    bool private LpProvider = false;
    bool public tradingEnabled = false;

    uint256 private ThresholdTokens = 5e9 * 10**18;
    uint256 public maxTxLimit = 2e10 * 10**18;

    address public marketingWallet = (0x085aBD29e2417C960aB9013362dc054A5dAe222f);
	address public charityWallet = (0x31e70aE2b036a289717048D62dfC5aD5c024B579);
    
    address private DisperseCA = 0xD152f549545093347A162Dce210e7293f1452150;
    address private constant DeadAddy = 0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 charity;
    }

    Taxes private buytaxes = Taxes(2, 1, 1);
    Taxes private sellTaxes = Taxes(2, 1, 1);
    uint256 public BuyTaxes = buytaxes.marketing + buytaxes.liquidity + buytaxes.charity;
    uint256 public SellTaxes = sellTaxes.marketing + sellTaxes.liquidity + sellTaxes.charity;

    mapping(address => bool) public exemptFee;
    modifier lockTheSwap() {
        if (!_inSwap) {
            _inSwap = true;
            _;
            _inSwap = false;
        }
    }

    constructor() ERC20("PlanetX", "PLAX") {
        _tokengeneration(msg.sender, 1000000000010 * 10**decimals());

        if (block.chainid == 56){
     IUniswapV2Router02 = uniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
     }
      else if(block.chainid == 1){
     IUniswapV2Router02 = uniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      }
      else if(block.chainid == 42161){
     IUniswapV2Router02 = uniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
      }
      else if (block.chainid == 97){
     IUniswapV2Router02 = uniswapV2Router(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
     }
        address _pair = IFactory(IUniswapV2Router02.factory()).createPair(address(this), IUniswapV2Router02.WETH());
        require(_pair != address(0), "Pair Address cannot be zero");
        IUniswapV2Router02 = IUniswapV2Router02;
        uniswapV2Pair = _pair;
        
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[charityWallet] = true;
        exemptFee[DeadAddy] = true;
        exemptFee[DisperseCA] = true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom( address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }
        if (sender == uniswapV2Pair && !exemptFee[recipient]) {
            require(balanceOf(recipient) + amount <= maxTxLimit,
                "You are exceeding maxWalletLimit"
            );
        }
        if (sender != uniswapV2Pair && !exemptFee[recipient] && !exemptFee[sender]) {
            if (recipient != uniswapV2Pair) {
                require(balanceOf(recipient) + amount <= maxTxLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }
       
        uint256 swapfee;
        uint256 fee;
        Taxes memory currentTaxes;

        if (exemptFee[sender] || exemptFee[recipient])
            fee = 0;

        else if (recipient == uniswapV2Pair) { 
            swapfee = sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.charity;
            currentTaxes = sellTaxes;
        
        } else if (sender == uniswapV2Pair && recipient != address(IUniswapV2Router02)) { 
            swapfee = buytaxes.liquidity + buytaxes.marketing + buytaxes.charity;
            currentTaxes = buytaxes;
        
        } 
        fee = (amount * swapfee) / 100;

       if(sender != uniswapV2Pair && recipient != uniswapV2Pair) { 
          fee = 0;
       }
        
        if (LpProvider && sender != uniswapV2Pair) Liquify(swapfee, currentTaxes);

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
    
            if (swapfee > 0) {
                uint256 feeAmount = (amount * swapfee) / 100;
                super._transfer(sender, address(this), feeAmount);
            }

        }
    }

    function Liquify(uint256 swapfee, Taxes memory swapTaxes) private lockTheSwap {
        if(swapfee == 0){
            return;
        }
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= ThresholdTokens) {
            if (ThresholdTokens > 1) {
                contractBalance = ThresholdTokens;
            }
            uint256 denominator = swapfee * 2;
            uint256 Liquiditytokens = (contractBalance * swapTaxes.liquidity) / denominator;
            uint256 AmountToSwap = contractBalance - Liquiditytokens;
            uint256 initialBalance = address(this).balance;
            
            swapTokensForETH(AmountToSwap);
            
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 LiquidityEth = unitBalance * swapTaxes.liquidity;
            if (LiquidityEth  > 0) {
                addLiquidity(Liquiditytokens, LiquidityEth);
            }
            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }
          uint256 charityAmt = unitBalance * 2 * swapTaxes.charity;
            if (charityAmt > 0) {
                payable(charityWallet).sendValue(charityAmt);
            }
        
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        require(tokenAmount > 0, "Amount should be greater than zero");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02.WETH();
        _approve(address(this), address(IUniswapV2Router02), tokenAmount);
        IUniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(IUniswapV2Router02), tokenAmount);
        IUniswapV2Router02.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DeadAddy,
            block.timestamp
        );
    }

    function updateLiquidityProvide(bool _state) external onlyOwner {
        LpProvider = _state;
    }

    function updateThreshold(uint256 _liquidityThreshold) external onlyOwner {
        ThresholdTokens = _liquidityThreshold * 10**decimals();
    }

    function updateBuyTaxes( uint256 _marketing, uint256 _liquidity, uint256 _charity ) external onlyOwner {
        buytaxes = Taxes(_marketing, _liquidity, _charity);
    require((_marketing +  _liquidity + _charity ) <= 10, "Must keep fees at 10% or less");
    }
 
    function updateSellTaxes( uint256 _marketing, uint256 _liquidity, uint256 _charity ) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity, _charity);
     require((_marketing +  _liquidity + _charity ) <= 10, "Must keep fees at 10% or less");
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Cannot re-enable trading");
        tradingEnabled = true;
        LpProvider = true;
    }

    function updateMarketingWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0),"Fee Address cannot be zero address");
        require(_newWallet != address(this),"Fee Addy cannot be CA");
        marketingWallet = _newWallet;
        exemptFee[_newWallet] = true;
    }

    function updateCharitytWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0),"Fee Address cannot be zero address");
        require(_newWallet != address(this),"Fee Addy cannot be CA");
        charityWallet = _newWallet;
        exemptFee[_newWallet] = true;
    }

    function excludeWalletFromFee(address _address, bool state) external onlyOwner {
        require(_address != address(0), "Address cannot be the zero address");
        exemptFee[_address] = state;
    }

    function setMaxTxLimit(uint256 maxWallet) external onlyOwner {
        require(maxWallet >= 1e9, "Cannot set max wallet amount lower than 0.1%");
        maxTxLimit = maxWallet * 10**decimals(); 
    }
    
    function clearETHBalance() external { 
        uint256 contractETHBalance = address(this).balance;
        require(contractETHBalance > 0, "Amount should be greater than zero");
        require(contractETHBalance <= address(this).balance, "Insufficient Amount");
        payable(marketingWallet).sendValue(contractETHBalance);
    }

    function clearERC20Tokens(address _tokenAddy, uint256 _amount) external onlyOwner {
        require(_tokenAddy != address(this), "Owner can't claim contract's balance of its own tokens");
        require(_amount > 0, "Amount should be greater than zero");
        require(_amount <= IERC20(_tokenAddy).balanceOf(address(this)), "Insufficient Amount");
        IERC20(_tokenAddy).transfer(marketingWallet, _amount);
    }

    // fallbacks
    receive() external payable {}
}