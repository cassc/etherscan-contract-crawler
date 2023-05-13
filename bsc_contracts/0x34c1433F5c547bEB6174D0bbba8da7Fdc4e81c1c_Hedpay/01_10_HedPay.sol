// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Hedpay is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public g_buyFee = 0;
    uint256 public g_sellFee = 10;
    uint256 public g_transferFee = 3;
    address public g_devWallet = 0xD72193cCf685D468A3A5BC2af0A9A5845DD13C0B;
    address public g_liquidityWallet = 0x1573aC99dDb4c3b11d67828c65a503F1906e61C1;
    address public g_userWallet = 0x7d4E738477B6e8BaF03c4CB4944446dA690f76B5;
    uint256 public g_minAmount;
    uint256 public g_maxAmount;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public g_bscUsdt;
    bool public canTrade;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimit;
    mapping(address => bool) private _isExcludedFromLockTrading;
    mapping(address => bool) private _isblacklisted;

    constructor(address _bscUsdt) ERC20("HEdpAY", "Hdp-B") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _bscUsdt);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        
        g_bscUsdt = _bscUsdt;
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
    
        _isExcludedFromLimit[owner()] = true;
        _isExcludedFromLimit[address(this)] = true;

        _isExcludedFromLockTrading[owner()] = true;

        g_minAmount = 1000000000000000000; //1 Hdp
        g_maxAmount = 1000000000000000000000; // 1000 Hdp

        _mint(owner(), 1000000000 ether);
    }

    // receive() external payable {}

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function setPair(address _pair) public onlyOwner {
        uniswapV2Pair = _pair;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromLimit[account] != excluded, "Account is already the value of 'exclude'");
        _isExcludedFromLimit[account] = excluded;
    }

    function excludeFromLockTrading(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromLockTrading[account] != excluded, "Account is already the value of 'exclude'");
        _isExcludedFromLockTrading[account] = excluded;
    }

    function isExcludedFromFees(address _account) external view returns (bool) {
        return _isExcludedFromFees[_account];
    }

    function isExcludedFromLimit(address _account) external view returns (bool) {
        return _isExcludedFromLimit[_account];
    }

    function isExcludedFromLockTrading(address _account) external view returns (bool) {
        return _isExcludedFromLockTrading[_account];
    }

    function blackListAddress(address _account, bool _flag) external onlyOwner {
        _isblacklisted[_account] = _flag;
    }
    function isBlackListed(address _account) external view returns (bool) {
        return _isblacklisted[_account];
    }

    function toggleCanTrade() external onlyOwner {
        canTrade = canTrade ? false: true;
    }

    function updateDevWallet(address _newDevWallet) external onlyOwner {
        require(g_devWallet != _newDevWallet, "wallet is already that address");
        require(_newDevWallet != address(0), "wallet cannot be the zero address");
        require(!isContract(_newDevWallet), "wallet cannot be a contract");
        g_devWallet = _newDevWallet;

    }

    function updateUserWallet(address _newUserWallet) external onlyOwner {
        require(g_userWallet != _newUserWallet, "wallet is already that address");
        require(_newUserWallet != address(0), "wallet cannot be the zero address");
        require(!isContract(_newUserWallet), "wallet cannot be a contract");
        g_userWallet = _newUserWallet;
    }

    function updateLiquidityWallet(address _newLiquidityWallet) external onlyOwner {
        require(g_liquidityWallet != _newLiquidityWallet, "wallet is already that address");
        require(_newLiquidityWallet != address(0), "wallet cannot be the zero address");
        require(!isContract(_newLiquidityWallet), "wallet cannot be a contract");
        g_liquidityWallet = _newLiquidityWallet;
    }

    function updateRouterAddress(address _addr) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_addr);
    }

    function updateMinAmount(uint256 _amount) external onlyOwner {
        g_minAmount = _amount;
    }

    function updateMaxAmount(uint256 _amount) external onlyOwner {
        g_maxAmount = _amount;
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee, uint256 _transferFee) external onlyOwner {
        g_buyFee = _buyFee;
        g_sellFee = _sellFee;
        g_transferFee = _transferFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isblacklisted[to] && !_isblacklisted[from], "Black listed address!");

        if(!_isExcludedFromLockTrading[from]) {
            require(canTrade, "HedPay: trading is locked");
        }

        if(!_isExcludedFromLimit[from] && !_isExcludedFromLimit[to] && from != uniswapV2Pair) {
            require(amount >= g_minAmount && amount <= g_maxAmount, "insufficient amount");
        }
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 fees;
        uint256 feeAmount;

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if (from == uniswapV2Pair) {
                fees = g_buyFee;
            } else if (to == uniswapV2Pair) {
                fees = g_sellFee;
            } else {
                fees = g_transferFee;
            }
        
            if (fees > 0) {
                feeAmount = (amount.mul(fees)).div(100);
                super._transfer(from, address(this), feeAmount);
                sendFee(feeAmount);
            }
        }
        super._transfer(from, to, amount - feeAmount);
    }
    
    function sendFee(uint256 tokenAmount) private {
        uint256 devAmount = tokenAmount.div(3);
        uint256 userAmount = tokenAmount.div(3);
        uint256 liquidityAmount = tokenAmount - devAmount - userAmount;

        _transfer(address(this), g_devWallet, devAmount);
        _transfer(address(this), g_userWallet, userAmount);
        _transfer(address(this), g_liquidityWallet, liquidityAmount);
    }
}