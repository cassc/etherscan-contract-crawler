/*
* $$$$$$$\  $$\   $$\ $$\      $$\ $$$$$$$\        $$$$$$\ $$$$$$$$\ 
* $$  __$$\ $$ |  $$ |$$$\    $$$ |$$  __$$\       \_$$  _|\__$$  __|
* $$ |  $$ |$$ |  $$ |$$$$\  $$$$ |$$ |  $$ |        $$ |     $$ |   
* $$$$$$$  |$$ |  $$ |$$\$$\$$ $$ |$$$$$$$  |        $$ |     $$ |   
* $$  ____/ $$ |  $$ |$$ \$$$  $$ |$$  ____/         $$ |     $$ |   
* $$ |      $$ |  $$ |$$ |\$  /$$ |$$ |              $$ |     $$ |   
* $$ |      \$$$$$$  |$$ | \_/ $$ |$$ |            $$$$$$\    $$ |   
* \__|       \______/ \__|     \__|\__|            \______|   \__|  
* 
* An experimental coin that doubles in price daily.
* NFA DYOR
*
* simplypumpit.com
* t.me/pumperc
* twitter.com/simplypumpit
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
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
        return msg.data;
    }
}

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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IUniswapV2Factory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
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

contract PumpToken is IERC20, Ownable {
    string public name = "Pump";
    string public symbol = "PUMP";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) isExcludedFromTax;
    uint256 maxWallet;
    bool pumpStarted;

    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable treasury = payable(0xb5d8dae8E8045463Ad55ee27Ef5De8857A927b7f);

    uint256 public sellTax = 420;
    uint256 public lastPumpedTimestamp;

    constructor() {
        totalSupply = 69_000_000e18;
        balanceOf[msg.sender] = totalSupply;
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[treasury] = true;
        isExcludedFromTax[address(uniswapV2Router)] = true;
        maxWallet = totalSupply / 50;
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );
    }

    event Pump(uint256 prevReserve, uint256 newReserve);

    bool inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        if (sender == address(uniswapV2Pair) && !isExcludedFromTax[recipient]) {
            require(amount + balanceOf[recipient] <= maxWallet, "Transfer amount exceeds the maxWallet");
        }

        if (recipient == address(uniswapV2Pair) && !isExcludedFromTax[sender]) {
            uint256 tax = (amount * sellTax) / 10000;
            amount -= tax;
            balanceOf[address(this)] += tax;
            balanceOf[sender] -= tax;
        }

        uint256 contractTokenBalance = balanceOf[address(this)];
        bool canSwap = contractTokenBalance > 0;

        if (
            canSwap && !inSwap && sender != address(uniswapV2Pair) && !isExcludedFromTax[sender]
                && !isExcludedFromTax[recipient]
        ) {
            swapTokensForEth(contractTokenBalance);
        }

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
    }

    bool isReserve0;

    function pump() public {
        require(pumpStarted, "Pump not started");
        require(lastPumpedTimestamp != block.timestamp, "Pump cooldown");

        (uint112 reserve0, uint112 reserve1,) = uniswapV2Pair.getReserves();
        uint112 reserve = isReserve0 ? reserve0 : reserve1;

        uint256 timePassed = viewTimePassed();
        uint256 toBurn;

        toBurn = (reserve * timePassed) / (2 * 86400);
        lastPumpedTimestamp = block.timestamp;

        burnFrom(address(uniswapV2Pair), toBurn);

        uniswapV2Pair.sync();

        emit Pump(reserve, reserve - toBurn);
    }

    function startZePump() public onlyOwner {
        require(!pumpStarted, "Pump already started");
        pumpStarted = true;
        lastPumpedTimestamp = block.timestamp;
        maxWallet = totalSupply;
    }

    function setReserve(bool _isReserve0) public onlyOwner {
        isReserve0 = _isReserve0;
    }

    function viewTimePassed() public view returns (uint256) {
        uint256 timePassed;
        if (block.timestamp - lastPumpedTimestamp > 86400) {
            timePassed = 86400;
        } else {
            timePassed = block.timestamp - lastPumpedTimestamp;
        }
        return timePassed;
    }

    function burnFrom(address account, uint256 amount) private {
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, treasury, block.timestamp
        );
    }
}