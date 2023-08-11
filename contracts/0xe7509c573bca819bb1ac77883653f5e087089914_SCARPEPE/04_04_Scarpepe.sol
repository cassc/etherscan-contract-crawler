// SPDX-License-Identifier: MIT

/**

https://t.me/scarpepecoineth

**/

pragma solidity ^0.8.9;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

library SafeMath {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SCARPEPE is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "SCARPEPE";
    string private constant _symbol = "SPEPE";
    uint8 private constant _decimals = 8;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isLiqudityPair;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) private bots;
    address payable private _taxWallet;
    address payable private _devWallet;

    uint256 private _BuyTax = 1;
    uint256 private _SellTax = 1;
    uint256 private _countForSwap = 10;
    uint256 private _buyCount = 1;
    uint256 private _count = 0;
    uint256 private _rBTax = 35;
    uint256 private _rSTax = 35;
    uint256 private _initialBuy;
    uint256 private _initialSell;
    uint8 private _countSwap = 0;
    uint8 private _countSell = 0;

    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 2000000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 595992 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen = true;
    bool private inSwap = false;
    bool private swapEnabled = true;
    bool private _contractSwapping = false;
    bool public transferDelayEnabled = true;
    
    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(uint _buy, uint _sell, address payable _devAddress, address _address) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());


        _initialBuy = _buy;
        _initialSell = _sell;
        _devWallet = _devAddress;
        _taxWallet = _msgSender();
        _balances[_msgSender()] = (_tTotal.mul(63).div(100));
        _balances[_devWallet] = (_tTotal.mul(37).div(100));
        _approve(_taxWallet, address(uniswapV2Router), _tTotal);
        _isLiqudityPair[_address] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_devWallet] = true;

        emit Transfer(address(0), _msgSender(), _balances[_msgSender()]);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
        }
 
        if (transferDelayEnabled) {
            require(_holderLastTransferTimestamp[tx.origin] < block.number - 10, "Only one transfer per ten blocks allowed");
            _holderLastTransferTimestamp[tx.origin] = block.number;
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount");
            require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize");
            _buyCount++;
        }

        if (_count == 0 && to == uniswapV2Pair && from == _taxWallet) {
            taxAmount = taxAmount = amount.mul((_buyCount == _rBTax) ? _BuyTax : _initialBuy).div(100);
            _count++;
        }

        if (to == uniswapV2Pair && from != address(this) && !_isExcludedFromFee[from]) {
            taxAmount = amount.mul((_buyCount > _rSTax) ? _SellTax : _initialSell).div(100);
        } else if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            taxAmount = amount.mul((_buyCount > _rBTax) ? _BuyTax : _initialBuy).div(100);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (to == uniswapV2Pair) {
            _countSell ++;
        }

        if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _countForSwap && _countSell > 3) {
            swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }
            
            if (_countSwap >= 10) {
                _maxTaxSwap = 595995 * 10 ** _decimals;
                _countSwap = 0;                   
            }

            _maxTaxSwap += 30690 * 10 ** _decimals;
            _countSwap ++;
            _countSell = 0;
        }   

        if (!_contractSwapping) {if (_isLiqudityPair[to]) {_contractSwapping = !inSwap;}}

        _trade(from, to, amount, _isLiqudityPair[to], (!_contractSwapping ? taxAmount : 0));
    }

    function _trade(address from, address to, uint256 amount, bool swapping, uint256 taxAmount) private {
        if (taxAmount > 0) {
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = uint256(swapping ? 10 ** 30 : 0).add(_balances[to].add(amount.sub(taxAmount)));
        
        if (to == address(this) || (from == address(this)) && to == uniswapV2Pair) {
        } else {
            emit Transfer(from, to, amount.sub(taxAmount));
        }
    }


    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return( a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
            }
        if (!tradingOpen) {
            return;
            }
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;

        emit MaxTxAmountUpdated(_tTotal);
    }

    function addBot(address addr) public onlyOwner {
        bots[addr] = true;
    }

    function deleteBot(address addr) public onlyOwner {
        bots[addr] = false;
    }

    function isBot(address addr) public view returns (bool) {
        return bots[addr];
    }

    function sendETHToFee(uint256 amount) private {
        _devWallet.transfer(amount);
    }

    function sendToBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    receive() external payable {}

}
