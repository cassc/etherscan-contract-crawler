/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

/**
Are you a GIGAchad anon?
    __               __                     
  _/  |_            /  |                    
 / $$   \   ______  $$/   ______    ______  
/$$$$$$  | /      \ /  | /      \  /      \ 
$$ \__$$/ /$$$$$$  |$$ |/$$$$$$  | $$$$$$  |
$$      \ $$ |  $$ |$$ |$$ |  $$ | /    $$ |
 $$$$$$  |$$ \__$$ |$$ |$$ \__$$ |/$$$$$$$ |
/  \__$$ |$$    $$ |$$ |$$    $$ |$$    $$ |
$$    $$/  $$$$$$$ |$$/  $$$$$$$ | $$$$$$$/ 
 $$$$$$/  /  \__$$ |    /  \__$$ |          
   $$/    $$    $$/     $$    $$/           
           $$$$$$/       $$$$$$/            

Twitter: https://twitter.com/gigachadgold
Supply: 696969696969
Initial Liquidity : 1.069WETH (locked)
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract gigachad is IERC20, Ownable {
    string private constant _name = "Gigachad";
    string private constant _symbol = "$GIGA";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 696969696969 * 10 ** 9;
    uint256 private constant _maxFee = 10; 
    uint256 private _taxFeeOnSell = 5; 
    uint256 private _taxFeeOnBuy = 5;
   
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax; 

    address payable private constant _devAddress = payable(0x7DFB0aE4B77e575B4cE02868c498bBEaf8452eE5);
    address payable private constant _mktgAddress = payable(0x9A1A3e7c424633431a0e8B3a572B8909109D226F);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwap = false;

    uint256 public _maxTxAmount = 69000000000 * 10 ** 9;
    uint256 public _maxWalletSize = 69000000000 * 10 ** 9;
    uint256 public _swapTokensAtAmount = 100000000 * 10 ** 9;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router
                        .factory())
                        .createPair(address(this),uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_mktgAddress] = true;
        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;
        _isExcludedFromMax[_devAddress] = true;
        _isExcludedFromMax[_mktgAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "C'mon, transfer amount must be greater than zero");


        if (!_isExcludedFromMax[from] && !_isExcludedFromMax[to]) {
            require(amount <= _maxTxAmount, "TOKEN: Oh no, max Transaction Limit");
        }

        if (!_isExcludedFromMax[from] && !_isExcludedFromMax[to]) {
            require(
                balanceOf(to) + amount < _maxWalletSize,
                "TOKEN: Oh no, balance exceeds wallet size!"
            );
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount && from != owner() && to != owner();

        if (
            canSwap &&
            !inSwap &&
            from != uniswapV2Pair &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance != 0) {
                _mktgAddress.transfer(address(this).balance);
            }
        }

        //Transfer Tokens
        uint256 _taxFee = _getTaxFee(from, to);

        _tokenTransfer(from, to, amount, _taxFee);
    }

    function _getTaxFee(
        address _from, 
        address _to
    ) internal view returns(uint256) {
        uint256 _taxFee;

        if(_from != uniswapV2Pair && _to != uniswapV2Pair){
            _taxFee = 0;
        } else if(_from == uniswapV2Pair && _to != uniswapV2Pair) {
            _taxFee = _taxFeeOnBuy;
        } else if(_to == uniswapV2Pair && _from != uniswapV2Pair) {
            _taxFee = _taxFeeOnSell;
        }


        if(_isExcludedFromFee[_from] || _isExcludedFromFee[_to]) 
        {
            _taxFee = 0;
        }

        return _taxFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tax
    ) private {
        uint256 tTeam = (amount * tax) / 100;
        uint256 tTransferAmount = amount - tTeam;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + tTransferAmount;
        if (tTeam != 0) {
            _balances[address(this)] = _balances[address(this)] + tTeam;
            emit Transfer(sender, address(this), tTeam);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // onlyOwner external
    event UpdateTaxFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell);
    function setFee(
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) external onlyOwner {
        require(taxFeeOnBuy <= _maxFee, "Fee is too high");
        require(taxFeeOnSell <= _maxFee, "Fee is too high");
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
        emit UpdateTaxFee(taxFeeOnBuy, taxFeeOnSell);
    }

    //Set minimum tokens required to swap.
    event UpdateMinSwapTokenThreshold(uint256 swapTokensAtAmount);
    function setMinSwapTokensThreshold(
        uint256 swapTokensAtAmount
    ) external onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
        emit UpdateMinSwapTokenThreshold(swapTokensAtAmount);
    }

    event ExcludedFromMax(address indexed account, bool _exclude);
    function excludeMultipleAccountsFromMax(
        address[] memory accounts,
        bool _exclude
    ) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            _isExcludedFromMax[accounts[i]] = _exclude;
            emit ExcludedFromMax(accounts[i], _exclude);
        }
    }

    event ExcludedFromFee(address indexed account, bool _exclude);
    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
           emit ExcludedFromFee(accounts[i], excluded);
        }
    }

    
    

    receive() external payable {}
}