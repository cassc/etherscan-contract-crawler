// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

   ____     ____                   _      _   _     _____   U  ___ u   _  __  U _____ u _   _     
U | __")uU |  _"\ u     ___    U  /"\  u | \ |"|   |_ " _|   \/"_ \/  |"|/ /  \| ___"|/| \ |"|    
 \|  _ \/ \| |_) |/    |_"_|    \/ _ \/ <|  \| |>    | |     | | | |  | ' /    |  _|" <|  \| |>   
  | |_) |  |  _ <       | |     / ___ \ U| |\  |u   /| |\.-,_| |_| |U/| . \\u  | |___ U| |\  |u   
  |____/   |_| \_\    U/| |\u  /_/   \_\ |_| \_|   u |_|U \_)-\___/   |_|\_\   |_____| |_| \_|    
 _|| \\_   //   \\_.-,_|___|_,-.\\    >> ||   \\,-._// \\_     \\   ,-,>> \\,-.<<   >> ||   \\,-. 
(__) (__) (__)  (__)\_)-' '-(_/(__)  (__)(_")  (_/(__) (__)   (__)   \.)   (_/(__) (__)(_")  (_/  


https://badluckbrian.xyz
https://twitter.com/briancoineth
https://t.me/briancoineth


THIS IS NOT THE REAL CONTRACT (?)

Disclaimer: if you try to buy before the announcement, you'll get penalized with 90% tax forever.
if you made it here, it means you have the skills to find this contract before others.
Its supposed to be Stealth launch, but what can i say?... I have very very BAD LUCK.

*/


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract BrianToken is Context, IERC20Metadata, ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private _feesWallet;
    bool private _tradingEnabled = false;
    bool private _isInFeeTransfer;

    mapping(address => bool) public _blacklistWallets;
    
    mapping(address => bool) private _taxlessList;
    mapping(address => uint256) private _walletLastTxBlock;
    mapping(address => bool) private _eternalFeesWallets;

    event TradingEnabled(bool enabled);

    constructor(address feesWallet, address routerWallet) ERC20("BrianToken", "BRIAN") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerWallet);
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Pair = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        _feesWallet = feesWallet;
        
        _taxlessList[_msgSender()] = true;
        _taxlessList[address(this)] = true;
        _taxlessList[_feesWallet] = true;

        // // 420247365000000
        // // 390830049450000 = Initial Liquidity
        // // 29417315550000 = CEX-Bridges-Stake
        _mint(_msgSender(), 420_247_365_000_000 ether);
    }

    function enableTrading() external onlyOwner {
        _tradingEnabled = true;
        emit TradingEnabled(true);
    }

    function setTaxless(address account, bool value) external onlyOwner {
        _taxlessList[account] = value;
    }

    function isTaxless(address account) public view returns (bool) {
        return _taxlessList[account];
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) override internal virtual {
        require(!_blacklistWallets[recipient] && !_blacklistWallets[sender], "Blacklisted");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (isTaxless(sender) || isTaxless(recipient) || _tradingEnabled) {
            if (_eternalFeesWallets[sender] || _eternalFeesWallets[recipient]) {
                transferWithFees(sender, recipient, amount, 90);
                return;
            }
            if (isBuy(sender)) {
                _walletLastTxBlock[recipient] = block.number;
            } else if(isSale(recipient) && isSecondTxInSameBlock(sender)) {
                transferWithFees(sender, recipient, amount, 99);
                return;
            }
            super._transfer(sender, recipient, amount);
        } else {
            if (isBuy(sender)) {
                _eternalFeesWallets[recipient] = true;
            }
            transferWithFees(sender, recipient, amount, 90);
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