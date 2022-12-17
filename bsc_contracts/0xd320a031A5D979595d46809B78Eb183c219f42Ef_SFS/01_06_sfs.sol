pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract TokenReceiver {
    constructor(address token) {
        IERC20(token).approve(msg.sender,~uint256(0));
    }
}

contract SFS is ERC20, Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address private constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public marketingWallet = 0xD7dd1A0A190f2bE3d3482a991adA468F08c375F5;
    address public nodeWallet = 0x8e12B1abA0bC3aDa6bc0fB8d635415027af7d761;

    uint256 public numTokensSellToSwap = 20000 * 1e18;

    uint256 public buyMarketingFee = 2;
    uint256 public buyNodeFee = 2;
    uint256 public buyLpFee = 2;

    uint256 public sellLpFee = 2;
    uint256 public sellMarketingFee = 2;
    uint256 public sellNodeFee = 2;

    address public lastPotentialLPHolder;
    address[] public lpHolders;
    uint256 public minAmountForLPDividend;

    // use by default 150,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 150000;

    uint256 public lastProcessedIndexForLPDividend;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public _isLPHolderExist;

    TokenReceiver private _tokenReceiver;

    bool private swapping;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() ERC20("Super For Speed", "SFS") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), USDT);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);

        _tokenReceiver = new TokenReceiver(USDT);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (1e18));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function setMarketingAddr(address _marketingWallet) external onlyOwner { 
        marketingWallet = _marketingWallet;
    }

    function setNodeAddr(address _nodeWallet) external onlyOwner { 
        nodeWallet = _nodeWallet;
    }

    function setBuyMarketingFee(uint256 _buyMarketingFee) external onlyOwner { 
        buyMarketingFee = _buyMarketingFee;
    }

    function setBuyNodeFee(uint256 _buyNodeFee) external onlyOwner { 
        buyNodeFee = _buyNodeFee;
    }

    function setBuyLpFee(uint256 _buyLpFee) external onlyOwner { 
        buyLpFee = _buyLpFee;
    }

    function setSellLpFee(uint256 _sellLpFee) external onlyOwner { 
        sellLpFee = _sellLpFee;
    }

    function setSellNodeFee(uint256 _sellNodeFee) external onlyOwner { 
        sellNodeFee = _sellNodeFee;
    }

    function setSellMarketingFee(uint256 _sellMarketingFee) external onlyOwner { 
        sellMarketingFee = _sellMarketingFee;
    }

    function setMinAmountForLPDividend(uint256 value) external onlyOwner {
        minAmountForLPDividend = value;
    }

    function setNumTokensSellToSwap(uint256 value) external onlyOwner {
        numTokensSellToSwap = value;
    }

    function exactTokens(address token, uint amount) external onlyOwner {
        uint balanceOfThis = IERC20(token).balanceOf(address(this));
        require(balanceOfThis > amount, 'no balance');
        IERC20(token).transfer(msg.sender, amount);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 100000 && newValue <= 250000, "ETHBack: gasForProcessing must be between 100,000 and 250,000");
        require(newValue != gasForProcessing, "ETHBack: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "wrong amount");

        uint256 maxTxAmount = balanceOf(from) * 99 / 100;
        if (!_isExcludedFromFees[from] 
            && !_isExcludedFromFees[to] 
            && amount > maxTxAmount) 
        {
            amount = maxTxAmount;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToSwap;

        if( overMinTokenBalance &&
            !swapping &&
            from != uniswapV2Pair
        ) {
            swapAndDividend(numTokensSellToSwap);
        } 

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        if(lastPotentialLPHolder != address(0) && !_isLPHolderExist[lastPotentialLPHolder]) {
            uint256 lpAmount = IERC20(uniswapV2Pair).balanceOf(lastPotentialLPHolder);
            if(lpAmount > 0) {
                lpHolders.push(lastPotentialLPHolder);
                _isLPHolderExist[lastPotentialLPHolder] = true;
            }
        }
        if(to == uniswapV2Pair && from != address(this)) {
            lastPotentialLPHolder = from;
        } 

    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(takeFee) {
            uint256 totalFee;
            if(sender == uniswapV2Pair) { //buy
                totalFee = buyLpFee + buyNodeFee + buyMarketingFee;
            } else if (recipient == uniswapV2Pair) {
                totalFee = sellLpFee + sellNodeFee + sellMarketingFee;
            } 

            if(totalFee > 0) {
                uint256 feeAmount = amount * totalFee / 100;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }
        }
        
        super._transfer(sender, recipient, amount);
    }

    function swapAndDividend(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256 initialBalance = IERC20(USDT).balanceOf(address(_tokenReceiver));
        // make the swap
        uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(_tokenReceiver),
            block.timestamp
        );

        uint256 newBalance = IERC20(USDT).balanceOf(address(_tokenReceiver)) - initialBalance;

        uint256 totalBuyShare = buyMarketingFee + buyLpFee + buyNodeFee;
        uint256 totalSellShare = sellMarketingFee + sellLpFee + sellNodeFee;
        uint256 balanceToMarketing = newBalance * (buyMarketingFee + sellMarketingFee) / (totalBuyShare + totalSellShare);
        IERC20(USDT).transferFrom(address(_tokenReceiver), marketingWallet, balanceToMarketing);
        uint256 balanceToNode = newBalance * (buyNodeFee + sellNodeFee) / (totalBuyShare + totalSellShare);
        IERC20(USDT).transferFrom(address(_tokenReceiver), nodeWallet, balanceToNode);
        IERC20(USDT).transferFrom(address(_tokenReceiver), address(this), newBalance - balanceToMarketing - balanceToNode);
        
        dividendToLPHolders();
    }

    function dividendToLPHolders() private {
        uint totalRewards = IERC20(USDT).balanceOf(address(this));
        if(totalRewards == 0) return;
        uint256 numberOfTokenHolders = lpHolders.length;	
        if(numberOfTokenHolders == 0) return;
        IERC20 pairContract = IERC20(uniswapV2Pair);
        uint256 gas = gasForProcessing;
        uint256 _lastProcessedIndex = lastProcessedIndexForLPDividend;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 totalLPAmount = pairContract.totalSupply();

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= lpHolders.length) {
                _lastProcessedIndex = 0;
            }

            address account = lpHolders[_lastProcessedIndex];
            uint256 LPAmount = pairContract.balanceOf(account); 
            if(LPAmount >= minAmountForLPDividend) {
                uint256 reward = totalRewards * LPAmount / totalLPAmount;
                if(reward == 0) {
                    iterations++;
                    continue;
                }
                IERC20(USDT).transfer(account, reward);
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed += (gasLeft - newGasLeft);
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndexForLPDividend = _lastProcessedIndex;
    }
}