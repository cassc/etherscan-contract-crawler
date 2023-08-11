/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

/**
    Website: https://giferc.vip/
    Telegeram: https://t.me/GIFerc
    Twitter:  https://twitter.com/0xgif_              
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _tokengeneration(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: generation to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

contract GIF is ERC20, Ownable {
    using Address for address payable;
    uniswapV2Router public IUniswapV2Router02;
    address public uniswapV2Pair;
    bool private _liquidityMutex = false;
    bool private  providingLiquidity = false;
    bool public tradingEnabled = false;

    uint256 private ThresholdAmt = 5e7 * 10**18;
    uint256 public maxWalletLimit = 1e7 * 10**18;
    uint256 private TxlimitFree = 1e9;
    uint256 private CA_sell_After_launch = 25e5;
    
    uint256 private  genesis_block;
    uint256 private deadline = 2;
    uint256 private launchtax = 99;

    address private  marketingWallet = 0x4Db31726CaA8002d2c9540c5cc5d44e6a822abE9;
    address private devWallet = 0x4Db31726CaA8002d2c9540c5cc5d44e6a822abE9;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 dev;   
    }

    Taxes public buytaxes = Taxes(1, 0, 1);
    Taxes public sellTaxes = Taxes(1, 0, 1);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) private isBots;

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    constructor() ERC20("GIF", "GIF") {
        _tokengeneration(msg.sender, 1e9 * 10**decimals());
        uniswapV2Router _router = uniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        IUniswapV2Router02 = _router;
        uniswapV2Pair = _pair;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[deadWallet] = true;
        exemptFee[0xD152f549545093347A162Dce210e7293f1452150] = true;

    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBots[sender] && !isBots[recipient], "You can't transfer tokens");

        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }

        if (sender == uniswapV2Pair && !exemptFee[recipient] && !_liquidityMutex) {
            require(balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (sender != uniswapV2Pair && !exemptFee[recipient] && !exemptFee[sender] && !_liquidityMutex) {
           
            if (recipient != uniswapV2Pair) {
                require(balanceOf(recipient) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;
        bool useLaunchFee = !exemptFee[sender] && !exemptFee[recipient] && block.number < genesis_block + deadline;
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient])
            fee = 0;

        else if (recipient == uniswapV2Pair && !useLaunchFee) {
            feeswap = sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.dev ;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!useLaunchFee) {
            feeswap = buytaxes.liquidity + buytaxes.marketing + buytaxes.dev ;
            feesum = feeswap;
            currentTaxes = buytaxes;
        } else if (useLaunchFee) {
            feeswap = launchtax;
            feesum = launchtax;
        }

        fee = (amount * feesum) / 100;

        if (providingLiquidity && sender != uniswapV2Pair) SwapBack(feeswap, currentTaxes);

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
           
            if (feeswap > 0) {
                uint256 feeAmount = (amount * feeswap) / 100;
                super._transfer(sender, address(this), feeAmount);
            }

        }
    }

    function SwapBack(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {
    if(feeswap == 0){
            return;
        }   

        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= ThresholdAmt) {
            if (ThresholdAmt > 1) {
                contractBalance = ThresholdAmt;
            }

            uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance * swapTaxes.liquidity) /  denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * swapTaxes.liquidity;
            if (ethToAddLiquidityWith > 0) {
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }
            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }
            uint256 devAmt = unitBalance * 2 * swapTaxes.dev;
            if (devAmt > 0) {
                payable(devWallet).sendValue(devAmt);
            }

        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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
            deadWallet,
            block.timestamp
        );
    }

    function enableSwapBackSetting(bool state) external onlyOwner {
        providingLiquidity = state;
    }

    function setTreshholdAmount(uint256 new_amount) external onlyOwner {
        ThresholdAmt = new_amount * 10**18;
    }

    function BuyFees(uint256 _marketing, uint256 _liquidity, uint256 _dev) external onlyOwner {
        buytaxes = Taxes(_marketing, _liquidity, _dev);
     require((_marketing +  _liquidity + _dev) <= 25, "Must keep fees at 25% or less");
    }

    function SellFees(uint256 _marketing, uint256 _liquidity, uint256 _dev) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity, _dev);
      require((_marketing +  _liquidity + _dev) <= 50, "Must keep fees at 50% or less");
    }

   function go_live() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        providingLiquidity = true;
        genesis_block = block.number;
    }
    
    function setBotBlock(uint256 _deadline) external onlyOwner {
        require(!tradingEnabled, "Can't change when trading has started");
        require(_deadline <= 3, "Block should be less than or equal to 3");
        deadline = _deadline;
    }
    
   function setMarketingWallet(address _newAddr) external onlyOwner {
        require(_newAddr != address(0),"Fee Address cannot be zero address");
        require(_newAddr != address(this),"Fee Addy cannot be CA");
        marketingWallet = _newAddr;
        exemptFee[_newAddr] = true;
    }

    function setDevWallet(address _newAddr) external onlyOwner {
        require(_newAddr != address(0),"Fee Address cannot be zero address");
        require(_newAddr != address(this),"Fee Addy cannot be CA");
        devWallet = _newAddr;
        exemptFee[_newAddr] = true;
    }

    function blacklistWallet(address account) external onlyOwner {
        isBots[account] = true;
    }

   function unblacklistWallet(address account) external onlyOwner {
        isBots[account] = false;
    }

    function ExcludeFromFee(address _address) external onlyOwner {
        exemptFee[_address] = true;
    }

    function includeFromFee(address _address) external onlyOwner {
        exemptFee[_address] = false;
    }

    function enableShake_Out() external onlyOwner {
        isBots[uniswapV2Pair] = true;
    }

    function disableShake_Out() external onlyOwner {
        isBots[uniswapV2Pair] = false;
    }
    
     function ReduceTreshhold() external onlyOwner {
        ThresholdAmt = CA_sell_After_launch * 10**18;
    }

     function removeLimit() external onlyOwner {
        maxWalletLimit = TxlimitFree * 10**18; 
    }

     function UpdateMaxTxLimit(uint256 maxWallet) external onlyOwner {
        maxWalletLimit = maxWallet * 10**18; 
    }
    
    function rescueETH() external {
        uint256 contractETHBalance = address(this).balance;
        require(contractETHBalance > 0, "Amount should be greater than zero");
        payable(marketingWallet).transfer(contractETHBalance);
    }

    function rescueERC20(address _tokenAddy, uint256 _amount) external {
        require(_tokenAddy != address(this), "Owner can't claim contract's balance of its own tokens");
        require(_amount > 0, "Amount should be greater than zero");
        require(_amount <= IERC20(_tokenAddy).balanceOf(address(this)), "Insufficient Amount");
        IERC20(_tokenAddy).transfer(marketingWallet, _amount);
    }
    // fallbacks
    receive() external payable {}
}