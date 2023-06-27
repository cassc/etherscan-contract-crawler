/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// File: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol



pragma solidity >=0.5.0;

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

// File: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

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

// File: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.2;

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

// File: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.2;


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

// File: Cooldown.sol



pragma solidity ^0.8.0;




contract Cooldown {
    // Address to balance mapping
    mapping(address => uint256) private _balances; // Mapping to keep track of COOLness
    
    // Address to address to allowance mapping
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Address to last transfer timestamp mapping
    mapping(address => uint256) private _lastTransferTimestamp;
    
    // Total supply of tokens
    uint256 private _totalSupply; // Total supply of COOLness
    
    // Maximum wallet size allowed as a percentage of the total supply
    uint256 private _maxWalletPercentage = 5; // Initial maximum COOL wallet percentage (0.5%)
    
    // Cooldown duration in seconds
    uint256 private constant COOLDOWN_DURATION = 300; // Time it takes for COOLness to refresh
    
    // Number of buys counter
    uint256 private _numBuys; // Number of buys made
    
    // Liquidity pool address
    address private _liquidityPool; // Pool where COOLness swims
    
    // Uniswap V2 Router
    IUniswapV2Router02 private _uniswapRouter; // Router for exchanging COOLness
    
    // Uniswap V2 Factory
    IUniswapV2Factory private _uniswapFactory; // Factory for creating COOLness
    
    // Tax percentage on buys and sells
    uint256 private constant TAX_PERCENTAGE = 3; // Tax on COOLness transactions
    
    // Threshold percentage for liquidity pool distribution
    uint256 private constant LIQUIDITY_THRESHOLD_PERCENTAGE = 10; // Minimum COOLness for liquidity
    
    string private _name; // The name of our COOL Token
    string private _symbol; // The symbol of our COOL Token
    uint8 private _decimals; // Number of decimals for our COOL Token

    // Maximum wallet size allowed as a percentage of the adjusted total supply
    uint256 private _maxWalletSize; // Maximum COOLness wallet size
    
    // Array to store the token holders
    address[] private _holders;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value); // COOLness transfer event
    event Approval(address indexed owner, address indexed spender, uint256 value); // Approval event for spending COOLness
    
    // Constructor
    constructor() {
        _name = "Cooldown"; // Stay COOL!
        _symbol = "COOL"; // Stay COOL!
        _decimals = 18; // Stay COOL!
        _totalSupply = 1000000000 * (10**uint256(_decimals)); // Stay COOL!
        _balances[msg.sender] = _totalSupply; // Stay COOL!
        
        // Assign Ethereum Mainnet addresses for Uniswap V2
        _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Router
        _uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // Uniswap V2 Factory
        
        // Initialize the maximum wallet size based on the initial percentage
        _updateMaxWalletSize();
    }
    
    // Function to update the maximum wallet size based on the current total supply
    function _updateMaxWalletSize() private {
        _maxWalletSize = (_totalSupply * _maxWalletPercentage) / 1000; // Calculate the dynamic maximum wallet size
    }
    
    // Function to handle the burn of tokens
    function _burnTokens(address account, uint256 amount) private {
        require(account != address(0), "Invalid account address");
        require(amount > 0, "Invalid amount");

        // Perform the burn of tokens
        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount); // Emit the burn event

        // Update the maximum wallet size after the burn
        _updateMaxWalletSize();
    }
    
    // Function to handle buy transactions
    function _buy(address recipient, uint256 amount) private {
        require(amount > 0, "Invalid amount");

        // Calculate the tax amount
        uint256 taxAmount = (amount * TAX_PERCENTAGE) / 100; // Apply the tax percentage
        
        // Deduct the tax amount from the received amount
        uint256 receivedAmount = amount - taxAmount;

        // Transfer the received amount to the recipient
        _transfer(address(this), recipient, receivedAmount);

        // Handle the tax amount
        _handleTax(recipient, taxAmount);
    }

    // Function to handle sell transactions
    function _sell(address sender, uint256 amount) private {
        require(amount > 0, "Invalid amount");

        // Calculate the tax amount
        uint256 taxAmount = (amount * TAX_PERCENTAGE) / 100; // Apply the tax percentage

        // Transfer the amount to the contract
        _transfer(sender, address(this), amount);

        // Handle the tax amount
        _handleTax(sender, taxAmount);
    }

    // Function to handle tax distribution
    function _handleTax(address recipient, uint256 taxAmount) private {
        // Check if the liquidity pool has enough COOLness
        if (_balances[_liquidityPool] >= (_totalSupply * LIQUIDITY_THRESHOLD_PERCENTAGE) / 100) {
            // Burn the tax amount if the liquidity pool has enough COOLness
            _burnTokens(address(this), taxAmount);
        } else {
            // Add the tax amount to the liquidity pool if it doesn't have enough COOLness
            _transfer(address(this), _liquidityPool, taxAmount);
        }

        // Distribute the tax amount to other holders
        _distributeTax(recipient, taxAmount);
    }

    // Function to distribute the tax amount to other holders
    function _distributeTax(address recipient, uint256 taxAmount) private {
        uint256 totalHolders = _totalHolders();
        if (totalHolders > 1) {
            uint256 distributionAmount = taxAmount / (totalHolders - 1); // Exclude the recipient from distribution
            for (uint256 i = 0; i < totalHolders; i++) {
                address holder = _getHolderAtIndex(i);
                if (holder != recipient) {
                    _transfer(address(this), holder, distributionAmount);
                }
            }
        }
    }

    // Function to get the total number of token holders
    function _totalHolders() private view returns (uint256) {
        return _holders.length;
    }

    // Function to get the holder address at a specific index
    function _getHolderAtIndex(uint256 index) private view returns (address) {
        require(index < _holders.length, "Invalid index");
        return _holders[index];
    }

    // Function to add a new holder to the holders array
    function _addHolder(address holder) private {
        if (!_isHolder(holder)) {
            _holders.push(holder);
        }
    }

    // Function to check if an address is already a holder
    function _isHolder(address holder) private view returns (bool) {
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == holder) {
                return true;
            }
        }
        return false;
    }

    // Function to remove a holder from the holders array
    function _removeHolder(address holder) private {
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == holder) {
                // Swap the holder with the last element and remove it
                _holders[i] = _holders[_holders.length - 1];
                _holders.pop();
                break;
            }
        }
    }
    
    // Function to transfer tokens between addresses
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid amount");
        
        // Check if the sender is the creator or liquidity pool
        bool isCreatorOrLiquidityPool = (sender == msg.sender) || (sender == _liquidityPool);
        
        // Apply the max wallet and cooldown rules if not the creator or liquidity pool
        if (!isCreatorOrLiquidityPool) {
            require(amount <= _maxWalletSize, "Exceeded maximum wallet size");
            require(_lastTransferTimestamp[sender] + COOLDOWN_DURATION < block.timestamp, "Cooldown in progress");
        }

        require(_balances[sender] >= amount, "Insufficient balance");

        // Update the sender and recipient balances
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        // Update the last transfer timestamp for the sender
        _lastTransferTimestamp[sender] = block.timestamp;

        // Emit the transfer event
        emit Transfer(sender, recipient, amount);
    }
    
    // ... (Existing code)
}