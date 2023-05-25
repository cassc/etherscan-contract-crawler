/**
 *Submitted for verification at Etherscan.io on 2023-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LGEWhitelisted is Context {
    struct WhitelistRound {
        uint256 duration;
        uint256 amountMax;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }

    WhitelistRound[] public _lgeWhitelistRounds;

    uint256 public _lgeTimestamp;
    address public _lgePairAddress;

    address public _whitelister;

    event WhitelisterTransferred(address indexed previousWhitelister, address indexed newWhitelister);

    constructor() {
        _whitelister = _msgSender();
    }

    modifier onlyWhitelister() {
        require(_whitelister == _msgSender(), "Caller is not the whitelister");
        _;
    }

    function renounceWhitelister() external onlyWhitelister {
        emit WhitelisterTransferred(_whitelister, address(0));
        _whitelister = address(0);
    }

    function transferWhitelister(address newWhitelister) external onlyWhitelister {
        _transferWhitelister(newWhitelister);
    }

    function _transferWhitelister(address newWhitelister) internal {
        require(newWhitelister != address(0), "New whitelister is the zero address");
        emit WhitelisterTransferred(_whitelister, newWhitelister);
        _whitelister = newWhitelister;
    }

    /*
     * createLGEWhitelist - Call this after initial Token Generation Event (TGE)
     *
     * pairAddress - address generated from createPair() event on DEX
     * durations - array of durations (seconds) for each whitelist rounds
     * amountsMax - array of max amounts (TOKEN decimals) for each whitelist round
     *
     */

    function createLGEWhitelist(
        address pairAddress,
        uint256[] calldata durations,
        uint256[] calldata amountsMax
    ) external onlyWhitelister() {
        require(durations.length == amountsMax.length, "Invalid whitelist(s)");

        _lgePairAddress = pairAddress;

        if (durations.length > 0) {
            delete _lgeWhitelistRounds;

            for (uint256 i = 0; i < durations.length; i++) {
                WhitelistRound storage whitelistRound = _lgeWhitelistRounds.push();
                whitelistRound.duration = durations[i];
                whitelistRound.amountMax = amountsMax[i];
            }
        }
    }

    /*
     * modifyLGEWhitelistAddresses - Define what addresses are included/excluded from a whitelist round
     *
     * index - 0-based index of round to modify whitelist
     * duration - period in seconds from LGE event or previous whitelist round
     * amountMax - max amount (TOKEN decimals) for each whitelist round
     *
     */

    function modifyLGEWhitelist(
        uint256 index,
        uint256 duration,
        uint256 amountMax,
        address[] calldata addresses,
        bool enabled
    ) external onlyWhitelister() {
        require(index < _lgeWhitelistRounds.length, "Invalid index");
        require(amountMax > 0, "Invalid amountMax");

        if (duration != _lgeWhitelistRounds[index].duration) _lgeWhitelistRounds[index].duration = duration;

        if (amountMax != _lgeWhitelistRounds[index].amountMax) _lgeWhitelistRounds[index].amountMax = amountMax;

        for (uint256 i = 0; i < addresses.length; i++) {
            _lgeWhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }

    /*
     *  getLGEWhitelistRound
     *
     *  returns:
     *
     *  1. whitelist round number ( 0 = no active round now )
     *  2. duration, in seconds, current whitelist round is active for
     *  3. timestamp current whitelist round closes at
     *  4. maximum amount a whitelister can purchase in this round
     *  5. is caller whitelisted
     *  6. how much caller has purchased in current whitelist round
     *
     */

    function getLGEWhitelistRound()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        if (_lgeTimestamp > 0) {
            uint256 wlCloseTimestampLast = _lgeTimestamp;

            for (uint256 i = 0; i < _lgeWhitelistRounds.length; i++) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[i];

                wlCloseTimestampLast = wlCloseTimestampLast + wlRound.duration;
                if (block.timestamp <= wlCloseTimestampLast)
                    return (
                        i + 1,
                        wlRound.duration,
                        wlCloseTimestampLast,
                        wlRound.amountMax,
                        wlRound.addresses[_msgSender()],
                        wlRound.purchased[_msgSender()]
                    );
            }
        }

        return (0, 0, 0, 0, false, 0);
    }

    /*
     * _applyLGEWhitelist - internal function to be called initially before any transfers
     *
     */

    function _applyLGEWhitelist(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (_lgePairAddress == address(0) || _lgeWhitelistRounds.length == 0) return;

        if (_lgeTimestamp == 0 && sender != _lgePairAddress && recipient == _lgePairAddress && amount > 0)
            _lgeTimestamp = block.timestamp;

        if (sender == _lgePairAddress && recipient != _lgePairAddress) {
            //buying

            (uint256 wlRoundNumber, , , , , ) = getLGEWhitelistRound();

            if (wlRoundNumber > 0) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[wlRoundNumber - 1];

                require(wlRound.addresses[recipient], "LGE - Buyer is not whitelisted");

                uint256 amountRemaining = 0;

                if (wlRound.purchased[recipient] < wlRound.amountMax)
                    amountRemaining = wlRound.amountMax - wlRound.purchased[recipient];

                require(amount <= amountRemaining, "LGE - Amount exceeds whitelist maximum");
                wlRound.purchased[recipient] = wlRound.purchased[recipient] + amount;
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

contract FLEX is IERC20, Ownable, LGEWhitelisted {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    mapping(address => bool) public _feeExcluded;

	uint256 public _feeBurnPct;
	uint256 public _feeRewardPct;
	
	address public _feeRewardAddress;

	mapping(address => bool) public _pair;
	
	address public _router;
	
	address[] public _feeRewardSwapPath;

    constructor(uint256 feeBurnPct, uint256 feeRewardPct, address feeRewardAddress, address router) {

        _name = "FlexMeme";
        _symbol = "FLEX";

        _decimals = 18;
        _totalSupply = 1000000000000e18;

		IUniswapV2Router02 r = IUniswapV2Router02(router);
		IUniswapV2Factory f = IUniswapV2Factory(r.factory());
		
        setPair(f.createPair(address(this), r.WETH()), true);
        
        address[] memory feeRewardSwapPath = new address[](2);
            
        feeRewardSwapPath[0] = address(this);
        feeRewardSwapPath[1] = r.WETH();
		
		setFees(feeBurnPct, feeRewardPct, feeRewardSwapPath, feeRewardAddress);
		
		_router = router;
		
		setFeeExcluded(_msgSender(), true);
		setFeeExcluded(address(this), true);

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setRouter(address r) public onlyOwner {
        _router = r;
    }
    
    function setFees(uint256 feeBurnPct, uint256 feeRewardPct, address[] memory feeRewardSwapPath, address feeRewardAddress) public onlyOwner {
        require((feeBurnPct+feeRewardPct) <= 2000, "Fees must not total more than 20%");
        require(feeRewardSwapPath.length > 1, "Invalid path");
		require(feeRewardAddress != address(0), "Fee reward address must not be zero address");
		
		_feeBurnPct = feeBurnPct;
		_feeRewardPct = feeRewardPct;
		_feeRewardSwapPath = feeRewardSwapPath;
		_feeRewardAddress = feeRewardAddress;
		
    }

	function setPair(address a, bool pair) public onlyOwner {
        require(a != address(0), "Pair address must not be zero address");
        _pair[a] = pair;
    }

	function setFeeExcluded(address a, bool excluded) public onlyOwner {
        require(a != address(0), "Fee excluded address must not be zero address");
        _feeExcluded[a] = excluded;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal {
		LGEWhitelisted._applyLGEWhitelist(sender, recipient, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
	
	function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
		
        _beforeTokenTransfer(sender, recipient, amount);
		
		_balances[sender] -= amount;
		
		if(_pair[recipient] && !_feeExcluded[sender]) {
			
			uint256 feeBurnAmount = 0;
			
			if(_feeBurnPct > 0) {
			
				feeBurnAmount = (amount*_feeBurnPct)/10000;
				
				_totalSupply -= feeBurnAmount;
				emit Transfer(sender, address(0), feeBurnAmount);
				
			}
			
			uint256 feeRewardAmount = 0;
			
			if(_feeRewardPct > 0 && _feeRewardAddress != address(0))  {
			    
				feeRewardAmount = (amount*_feeRewardPct)/10000;
				
				if(_router != address(0)) {
				    
    				_balances[address(this)] += feeRewardAmount;
    				
    				emit Transfer(sender, address(this), feeRewardAmount);
    				
    				IUniswapV2Router02 r = IUniswapV2Router02(_router);
                    
                    _approve(address(this), _router, feeRewardAmount);
    
                    r.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        feeRewardAmount,
                        0,
                        _feeRewardSwapPath,
                        _feeRewardAddress,
                        block.timestamp
                    );
                
				} else {
				    _balances[_feeRewardAddress] += feeRewardAmount;
				    emit Transfer(sender, _feeRewardAddress, feeRewardAmount);
				}
				
			}
			
			amount -= (feeBurnAmount+feeRewardAmount);
			
		}

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

}