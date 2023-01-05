pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract CEYT is Ownable, ERC20 {

    address public constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public marketingWallet = 0x0Ba7C8F0F20Ccb21E275C4eEd26548DCf50a539F;
    address public tokenWallet = 0x593b6085689839C5aB58E32D8C1035E961c539DF;
    address public immutable uniswapV2Pair;

    uint256 public numTokensSellToMarketing = 300 * 1e18;
    uint256 public maxAmountPerTx = 1000 * 1e18;

    uint256 public burnFee;
    uint256 public marketingFee;

    mapping (address => bool) public exemptFee;
    mapping (address => bool) public isPair;
    bool public enableTxLimit = true;
    bool public adjustFees = true;


    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() ERC20("CEYT", "CEYT") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(router);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), USDT);
        isPair[_uniswapV2Pair] = true;
        uniswapV2Pair = _uniswapV2Pair;
        
        exemptFee[owner()] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[tokenWallet] = true;
        exemptFee[address(this)] = true;
       
        _approve(address(this), router, ~uint(0));
        _mint(tokenWallet, 3000000 * 1e18); 
    }

    function setNumTokensSellToMarketing(uint256 value) external onlyOwner { 
        numTokensSellToMarketing = value;
    }

    function setMarketingAddr(address _marketingWallet) external onlyOwner { 
        marketingWallet = _marketingWallet;
    }

    function setMarketingFee(uint256 _marketingFee) external onlyOwner { 
        marketingFee = _marketingFee;
    }

    function setBurnFee(uint256 _burnFee) external onlyOwner { 
        burnFee = _burnFee;
    }

    function setExemptFee(address[] memory account, bool flag) external onlyOwner {
        require(account.length > 0, "no account");
        for(uint256 i = 0; i < account.length; i++) {
            exemptFee[account[i]] = flag;
        }
    }

    function setPair(address pair, bool flag) external onlyOwner { 
        isPair[pair] = flag;
    }

    function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner { 
        maxAmountPerTx = _maxAmountPerTx;
    }

    function setEnableTxLimit(bool _enableTxLimit) external onlyOwner { 
        enableTxLimit = _enableTxLimit;
    }

    function setAdjustFees(bool _adjustFees) external onlyOwner { 
        adjustFees = _adjustFees;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "ERC20: wrong amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToMarketing;
        if (
            overMinTokenBalance &&
            !inSwap &&
            !isPair[sender]
        ) {
            swapAndDividend(numTokensSellToMarketing);
        }
        
        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(exemptFee[sender] || exemptFee[recipient]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(sender, recipient, amount, takeFee);

        setTxLimitAndFees();

        if (enableTxLimit && takeFee) {
            require(amount <= maxAmountPerTx, "max amount limit per tx");
        }
    }

    function setTxLimitAndFees() private {
        uint price = getPrice();
        if (enableTxLimit && price >= 1e17) {
            enableTxLimit = false;
        } 

        if (!adjustFees) {
            return;
        }

        if (price >= 1e18 && burnFee != 5) {
            burnFee = 5;
            marketingFee = 25;
        } else if (price >= 1e17 && burnFee != 10) {
            burnFee = 10;
            marketingFee = 90;
        } else if (burnFee != 30) {
            burnFee = 30;
            marketingFee = 270;
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(takeFee) {
            uint _marketingFee = marketingFee;
            uint _burnFee = burnFee;
            uint originalAmount = amount;
            if (_marketingFee > 0) {
                uint256 feeAmount = originalAmount * _marketingFee / 1000;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }

            if (_burnFee > 0) {
                uint256 feeAmount = originalAmount * _burnFee / 1000;
                super._burn(sender, feeAmount);
                amount -= feeAmount;
            }
        } 
        super._transfer(sender, recipient, amount);
    }

    function swapAndDividend(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        // make the swap
        IUniswapV2Router(router).swapExactTokensForTokens(
            amount,
            0, // accept any amount of usdt
            path,
            marketingWallet,
            block.timestamp
        );
    }

    function getPrice() public view returns (uint) {
        address pair = uniswapV2Pair;
        uint tokenAmountOfPair = IERC20(address(this)).balanceOf(pair);
        uint usdtAmountOfPair = IERC20(USDT).balanceOf(pair);
        if (tokenAmountOfPair == 0 || usdtAmountOfPair == 0) {
            return 0;
        } else {
            return usdtAmountOfPair * 1e18 / tokenAmountOfPair;
        }
    }
}