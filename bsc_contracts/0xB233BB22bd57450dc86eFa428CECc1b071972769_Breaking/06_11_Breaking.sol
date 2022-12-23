// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IUniswapV2Router02 } from "./../interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "./../interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./../interfaces/IUniswapV2Pair.sol";

import "hardhat/console.sol";

contract Breaking is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _receiveReflections;
    address[] private _reflectionWallets;

    mapping(address => bool) private _isBlackListed;
    address[] private _blackList;

    uint256 private _taxFee = 5;
    uint256 private _previousTaxFee;
    uint256 private _reflectionSplit = 40; // % of taxes going to reflection wallets
    uint256 private _reflectionCap = 2500; // max in $ for reflections
    uint256 public _totalSupply;

    string private constant _name = "Breaking";
    string private constant _symbol = "BREAK";
    uint8 private constant _decimals = 18;

    address payable public _treasuryWalletAddress;
    uint256 private _transferThreshold = 50000 * 10**18;

    address public immutable usdcTokenAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public immutable usdcEthUniswapV2Pair = 0xd99c7F6C65857AC913a8f880A4cb84032AB2FC5b;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwap = false;
    bool public swapEnabled = true;
    bool public taxEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable treasuryWalletAddress) public {
        _treasuryWalletAddress = treasuryWalletAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;

        _balances[msg.sender] += 500000 * 10**18;
        _totalSupply += 500000 * 10**18;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function uniswapPair() public view returns (address) {
        return uniswapV2Pair;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isReflectionWallet(address account) public view returns (bool) {
        return _receiveReflections[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setExcludeUserFromTax(address account, bool excluded) external onlyOwner {
        _isExcludedFromTax[account] = excluded;
    }

    function mintAdditional(uint256 quantity) external onlyOwner {
        _balances[msg.sender] += quantity;
        _totalSupply += quantity;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(sender) > amount, "User does not have enough funds");
        require(!_isBlackListed[sender], "You are blacklisted");
        require(!_isBlackListed[msg.sender], "You are blacklisted");
        require(!_isBlackListed[tx.origin], "You are blacklisted");

        // sell eth for usdc
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _transferThreshold;

        if (!inSwap && swapEnabled && overMinTokenBalance && sender != uniswapV2Pair) {
            _swapTokensForUSDC(contractTokenBalance);
        }

        bool takeFee = false;

        // only take taxes if selling/buying
        if (sender == address(uniswapV2Pair) || recipient == address(uniswapV2Pair)) {
            takeFee = true;
        }

        // remove taxes if sender/recipient excluded
        if (_isExcludedFromTax[sender] || _isExcludedFromTax[recipient]) {
            takeFee = false;
        }

        // transfer amount to calculate taxes
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function addToBlacklist(address account) external onlyOwner {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "We cannot blacklist UniSwap router");
        require(!_isBlackListed[account], "Account is already blacklisted");
        _isBlackListed[account] = true;
        _blackList.push(account);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(_isBlackListed[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackList.length; i++) {
            if (_blackList[i] == account) {
                _blackList[i] = _blackList[_blackList.length - 1];
                _isBlackListed[account] = false;
                _blackList.pop();
                break;
            }
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal {
        if (taxEnabled) {
            if (!takeFee) _removeTax();
            uint256 taxAmount = (amount * _taxFee) / 100;
            uint256 transferAmount = amount - taxAmount;
            _balances[sender] -= amount;
            _balances[recipient] += transferAmount;
            _takeTaxes(taxAmount);

            emit Transfer(sender, recipient, transferAmount);

            if (!takeFee) _restoreTax();
        } else {
            _balances[sender] -= amount;
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
    }

    function _removeTax() internal {
        if (_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function _restoreTax() internal {
        _taxFee = _previousTaxFee;
    }

    function _takeTaxes(uint256 amount) internal {
        uint256 reflectionAmount = (amount * _reflectionSplit) / 100;

        // distribute reflections
        // note: add in check for if there are no reflection wallets
        if (reflectionAmount > 0) {
            uint256 numReflectionWallets = _reflectionWallets.length;
            uint256 reflectionPerWallet = reflectionAmount / numReflectionWallets;
            uint256 totalReflections = 0;
            uint256 titsPriceUSD = titsPrice();
            for (uint256 i = 0; i < _reflectionWallets.length; i++) {
                // check if wallet has reached max reflections
                uint256 reflectionWalletBalance = balanceOf(_reflectionWallets[i]) * titsPriceUSD;
                if (reflectionWalletBalance < _reflectionCap) {
                    _balances[_reflectionWallets[i]] += reflectionPerWallet;
                    totalReflections += reflectionPerWallet;
                }
            }
            // distribute treasury
            uint256 treasuryAmount = amount - totalReflections;
            _balances[address(this)] += treasuryAmount;
        } else {
            _balances[address(this)] += amount;
        }
    }

    function titsPrice() public view returns (uint112) {
        IUniswapV2Pair titsEthPair = IUniswapV2Pair(uniswapV2Pair);
        (uint112 titsBalance, uint112 ethBalance, ) = titsEthPair.getReserves();
        return ethPriceUsd() / (titsBalance / ethBalance);
    }

    function ethPriceUsd() public view returns (uint112) {
        IUniswapV2Pair usdcEthPair = IUniswapV2Pair(usdcEthUniswapV2Pair);
        (uint112 usdcBalance, uint112 ethBalance, ) = usdcEthPair.getReserves();
        return (usdcBalance / 1e6) / (ethBalance / 1e18);
    }

    function _swapTokensForUSDC(uint256 quantity) private lockTheSwap {
        address weth = uniswapV2Router.WETH();
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(this);

        _approve(address(this), address(uniswapV2Router), quantity);

        uint256 approvedAmount = allowance(address(this), address(uniswapV2Router));

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            quantity,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;

        // generate uniswap pair path of weth => usdc
        address[] memory path2 = new address[](2);
        path2[0] = usdcTokenAddress;
        path2[1] = weth;

        uniswapV2Router.swapExactETHForTokens{ value: ethBalance }(0, path2, _treasuryWalletAddress, block.timestamp);
    }

    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee >= 0 && taxFee <= 25, "taxFee should be between 0 - 25");
        _taxFee = taxFee;
    }

    function setReflectionSplit(uint256 reflectionSplit) external onlyOwner {
        require(reflectionSplit >= 0 && reflectionSplit <= 100, "reflectionSplit should be between 0 - 100");
        _reflectionSplit = reflectionSplit;
    }

    function setReflectionCap(uint256 reflectionCap) external onlyOwner {
        _reflectionCap = reflectionCap;
    }

    function setTreasuryWallet(address payable treasuryWallet) external onlyOwner {
        _treasuryWalletAddress = treasuryWallet;
    }

    function addReflectionWallet(address account) external onlyOwner {
        require(!_receiveReflections[account], "Account is already receiving reflection");
        _receiveReflections[account] = true;
        _reflectionWallets.push(account);
    }

    function removeReflectionWallet(address account) external onlyOwner {
        require(_receiveReflections[account], "Account is not receiving reflection");
        for (uint256 i = 0; i < _reflectionWallets.length; i++) {
            if (_reflectionWallets[i] == account) {
                _reflectionWallets[i] = _reflectionWallets[_reflectionWallets.length - 1];
                _receiveReflections[account] = false;
                _reflectionWallets.pop();
                break;
            }
        }
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function setExcludeFromFee(address account, bool excluded) external onlyOwner {
        _isExcludedFromTax[account] = excluded;
    }

    function setTransferThreshold(uint256 threshold) external onlyOwner {
        _transferThreshold = threshold;
    }

    function setTaxEnabled(bool _taxEnabled) external onlyOwner {
        taxEnabled = _taxEnabled;
    }
}