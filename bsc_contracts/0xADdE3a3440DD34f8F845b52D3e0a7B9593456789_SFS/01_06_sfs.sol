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
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}

contract SFS is ERC20, Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address private constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public marketingWallet = 0xD7dd1A0A190f2bE3d3482a991adA468F08c375F5;
    address public nodeWallet = 0xb4855A3269b5f136C0Ed77978b871e0832720Abb;

    uint256 public numTokensSellToSwap = 10000 * 1e18;

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
    mapping (address => bool) public _isExcludedFromDividend;
    mapping (address => bool) public _isLPHolderExist;

    TokenReceiver public _tokenReceiver;

    bool public enableAirdrop = true;
    bool private distributing;
    bool private swapping;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    modifier lockTheDividend {
        distributing = true;
        _;
        distributing = false;
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

        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

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

    function setEnableAirdrop(bool _enableAirdrop) external onlyOwner { 
        enableAirdrop = _enableAirdrop;
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

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 100000 && newValue <= 250000, "ETHBack: gasForProcessing must be between 100,000 and 250,000");
        require(newValue != gasForProcessing, "ETHBack: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromDividend(address account, bool excluded) public onlyOwner {
        _isExcludedFromDividend[account] = excluded;
    }

    function excludeMultipleAccountsFromDividend(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromDividend[accounts[i]] = excluded;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "wrong amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToSwap;

        if( overMinTokenBalance &&
            !swapping &&
            from != uniswapV2Pair
        ) {
            swapAndDividend(numTokensSellToSwap);
        }

        if (!distributing) {
            dividendToLPHolders(gasForProcessing);
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
            if (enableAirdrop && balanceOf(address(this)) >= 3 * 1e10) {       
                for(uint i = 0; i < 3 ; i++){
                    super._transfer(address(this), address(uint160(uint(keccak256(abi.encodePacked(block.number, balanceOf(address(this))))))), 1e10);
                }
            }
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
    }

    function dividendToLPHolders(uint256 gas) private lockTheDividend {
        uint256 numberOfTokenHolders = lpHolders.length;

        if (numberOfTokenHolders == 0) {
            return;
        }

        uint256 totalRewards = IERC20(USDT).balanceOf(address(this));
        if (totalRewards < 10 * 1e18) {
            return;
        }

        uint256 _lastProcessedIndex = lastProcessedIndexForLPDividend;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        IERC20 pairContract = IERC20(uniswapV2Pair);
        uint256 totalLPAmount = pairContract.totalSupply();

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= lpHolders.length) {
                _lastProcessedIndex = 0;
            }

            address cur = lpHolders[_lastProcessedIndex];
            if (_isExcludedFromDividend[cur]) {
                iterations++;
                continue;
            }
            uint256 LPAmount = pairContract.balanceOf(cur);
            if (LPAmount >= minAmountForLPDividend) {
                uint256 dividendAmount = totalRewards * LPAmount / totalLPAmount;
                if (dividendAmount > 0) {
                    uint256 balanceOfThis = IERC20(USDT).balanceOf(address(this));
                    if (balanceOfThis < dividendAmount)
                        return;
                    IERC20(USDT).transfer(cur, dividendAmount);
                }
                
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed += gasLeft - newGasLeft;
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndexForLPDividend = _lastProcessedIndex;
    }
}