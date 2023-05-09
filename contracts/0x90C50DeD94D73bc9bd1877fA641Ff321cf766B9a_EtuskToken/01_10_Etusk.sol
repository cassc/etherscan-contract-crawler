// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract EtuskToken is Context, IERC20Metadata, ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private _feesWallet;
    bool private _tradingEnabled = false;
    bool private _isInFeeTransfer;
    uint256 private _maxEarlyWalletBag = 1_845_000_000_000 ether;

    mapping(address => uint256) private _walletLastTxBlock;
    mapping(address => bool) private _earlyWallets;

    event TradingEnabled(bool enabled);
    event EarlyWallet(address indexed wallet);

    constructor(address feesWallet, address routerWallet) ERC20("Elon Tusk", "ETUSK") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerWallet);
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Pair = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        _feesWallet = feesWallet;
        
        _earlyWallets[_msgSender()] = true;
        _earlyWallets[address(this)] = true;
        _earlyWallets[_feesWallet] = true;
        
        // // 369000000000000
        // 369_000_000_000_000
        // // 343539000000000 = Initial Liquidity
        // // 25461000000000 = CEX-Bridges-Stake
        _tradingEnabled = true;
        _mint(_msgSender(), 369_000_000_000_000 ether);
        _tradingEnabled = false;
    }

    function enableTrading() external onlyOwner {
        _tradingEnabled = true;
        emit TradingEnabled(true);
    }

    function setEarlyWallets(address[] memory addresses) public onlyOwner {
      for (uint i=0; i<addresses.length; i++) {
        _earlyWallets[addresses[i]] = true;
        emit EarlyWallet(addresses[i]);
      }
    }

    function isEarly(address account) public view returns (bool) {
        return _earlyWallets[account];
    }


    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) override internal virtual {
        require(isEarly(sender) || isEarly(recipient) || _tradingEnabled, "Trading has not started");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (isBuy(sender)) {
          _walletLastTxBlock[recipient] = block.number;
        } else if(isSale(recipient) && isSecondTxInSameBlock(sender)) {
          transferWithFees(sender, recipient, amount, 5);
          return;
        }
        super._transfer(sender, recipient, amount);
        if (!_tradingEnabled && recipient != uniswapV2Pair) {
          require(balanceOf(recipient) <= _maxEarlyWalletBag, "Max Wallet Hold reached");
        }
    }

    function transferWithFees(address sender, address recipient, uint amount, uint8 _percentage) internal {
        if (_isInFeeTransfer) {
          return;
        }
        uint256 tax = amount * _percentage / 100;
        uint256 netAmount = amount - tax;
        _isInFeeTransfer = true;
        super._transfer(sender, recipient, netAmount);
        super._transfer(sender, _feesWallet, tax);
        _isInFeeTransfer = false;
    }

    function isBuy(address _from) internal view returns(bool) {
        return uniswapV2Pair == _from;
    }

    function isSale(address _to) internal view returns(bool) {
        return uniswapV2Pair == _to;
    }

    function isSecondTxInSameBlock(address _from) internal view returns(bool) {
        return _walletLastTxBlock[_from] == block.number;
    }

}