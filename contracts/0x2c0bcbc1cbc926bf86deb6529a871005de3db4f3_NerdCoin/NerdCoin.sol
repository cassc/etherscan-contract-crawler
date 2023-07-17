/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// SPDX-License-Identifier: Unlicensed

// Website: https://nerdcoin.net
// DApp: https://app.nerdcoin.net
// Twitter: https://twitter.com/nerdcoinerc
// Telegram: https://t.me/nerdcoinportal

pragma solidity ^0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract NerdCoin {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeAndMaxTx;
    mapping(address => bool) private _isAutomatedMarketMaker;

    mapping(address => uint256) private tokenAmountVotedForBuyFee;
    mapping(address => uint256) private votedForBuyFee;
    mapping(uint256 => uint256) private totalVotedAmountForBuyFee;

    mapping(address => uint256) private tokenAmountVotedForSellFee;
    mapping(address => uint256) private votedForSellFee;
    mapping(uint256 => uint256) private totalVotedAmountForSellFee;

    address private _owner;

    address public wallet;
    address public uniswapV2Pair;
    IUniswapV2Router public uniswapV2Router;

    uint256 private _totalSupply;

    bool public tradingActive;

    uint256 public maxTransaction;
    uint256 public maxContractSwap;

    uint256 public denominator = 1000;
    uint256 public buyFee;
    uint256 public sellFee;

    uint256 private _decimals = 9;

    string private _name;
    string private _symbol;

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    event Approval(
        address indexed from,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address owner_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[owner_] = totalSupply_;
        emit Transfer(address(0), owner_, totalSupply_);
        _owner = owner_;
        wallet = owner_;
        buyFee = 300;
        sellFee = 350;
        maxTransaction = (totalSupply_ / 100) * 3;
        maxContractSwap = (totalSupply_ / 100) * 1;
        uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            address(this)
        );
        _isAutomatedMarketMaker[uniswapV2Pair] = true;
        _isExcludedFromFeeAndMaxTx[address(this)] = true;
        _isExcludedFromFeeAndMaxTx[owner_] = true;
    }

    receive() external payable {}

    fallback() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function allowance(address from, address to) public view returns (uint256) {
        return _allowances[from][to];
    }

    function isAutomatedMarketMaker(address _address)
        public
        view
        returns (bool)
    {
        return _isAutomatedMarketMaker[_address];
    }

    function isExcludedFromFeeAndMaxTx(address _address)
        public
        view
        returns (bool)
    {
        return _isExcludedFromFeeAndMaxTx[_address];
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal {
        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(_balances[from] >= amount);
        uint256 fee;
        if(!tradingActive){
            require(_isExcludedFromFeeAndMaxTx[from] || _isExcludedFromFeeAndMaxTx[to]);
        }
        if (
            !_isExcludedFromFeeAndMaxTx[from] &&
            !_isExcludedFromFeeAndMaxTx[to]
        ) {
            require(amount < maxTransaction);
            if (_isAutomatedMarketMaker[from]) {
                _balances[address(this)] += (amount / denominator) * buyFee;
                emit Transfer(from, address(this), (amount / denominator) * buyFee);
                fee = buyFee;
            }
            if (_isAutomatedMarketMaker[to]) {
                if (_balances[address(this)] > 0) {
                    if (_balances[address(this)] > maxContractSwap) {
                        contractBalanceRealization(maxContractSwap);
                    } else {
                        contractBalanceRealization(_balances[address(this)]);
                    }
                }
                _balances[address(this)] += (amount / denominator) * sellFee;
                emit Transfer(from, address(this), (amount / denominator) * sellFee);
                fee = sellFee;
            }
        }
        if(tokenAmountVotedForBuyFee[from] > 0){
            totalVotedAmountForBuyFee[votedForBuyFee[from]] -= amount;
            tokenAmountVotedForBuyFee[from] -= amount;
            if(tokenAmountVotedForBuyFee[from] == 0){
                votedForBuyFee[from] = 0;
            }
            validateBuyFee();
        }
        if(tokenAmountVotedForSellFee[from] > 0){
            totalVotedAmountForSellFee[votedForSellFee[from]] -= amount;
            tokenAmountVotedForSellFee[from] -= amount;
            if(tokenAmountVotedForSellFee[from] == 0){
                votedForSellFee[from] = 0;
            }
            validateSellFee();
        }
        uint256 feeAmount = (amount / denominator) * fee;
        uint256 finalAmount = amount - feeAmount;
        _balances[from] -= amount;
        _balances[to] += finalAmount;
        emit Transfer(from, to, finalAmount);
    }

    function contractBalanceRealization(uint256 amount) internal {
        swapTokensForETH(amount);
        wallet.call{value: address(this).balance}("");
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function reduceFeesAndRemoveLimits() external onlyOwner {
        buyFee = 20; // 20 / 1000 = 2%
        sellFee = 20; // 20 / 1000 = 2%
        maxTransaction = _totalSupply;
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function validateBuyFee() internal {
        uint256 biggestVotedAmount;
        uint256 biggestVotedAmountFee;
        for(uint256 i = 1; i <= 50; i++){
            if(totalVotedAmountForBuyFee[i] > biggestVotedAmount){
                biggestVotedAmount = totalVotedAmountForBuyFee[i];
                biggestVotedAmountFee = i;
            }
        }
        if(buyFee != biggestVotedAmountFee){
            buyFee = biggestVotedAmountFee;
        }
    }

    function validateSellFee() internal {
        uint256 biggestVotedAmount;
        uint256 biggestVotedAmountFee;
        for(uint256 i = 1; i <= 50; i++){
            if(totalVotedAmountForSellFee[i] > biggestVotedAmount){
                biggestVotedAmount = totalVotedAmountForSellFee[i];
                biggestVotedAmountFee = i;
            }
        }
        if(sellFee != biggestVotedAmountFee){
            sellFee = biggestVotedAmountFee;
        }
    }

    function voteForBuyFee(uint256 _buyFee) external {
        if(tokenAmountVotedForBuyFee[msg.sender] > 0){
            totalVotedAmountForBuyFee[votedForBuyFee[msg.sender]] -= tokenAmountVotedForBuyFee[msg.sender];
        }
        require(_buyFee <= 50 && _buyFee > 0); // 50 / 1000 = 5% || 1 / 1000 = 0.1%
        uint256 voteAmount = _balances[msg.sender];
        votedForBuyFee[msg.sender] = _buyFee;
        tokenAmountVotedForBuyFee[msg.sender] = voteAmount;
        totalVotedAmountForBuyFee[_buyFee] += voteAmount;
        validateBuyFee();
    }

    function voteForSellFee(uint256 _sellFee) external {
        if(tokenAmountVotedForSellFee[msg.sender] > 0){
            totalVotedAmountForSellFee[votedForSellFee[msg.sender]] -= tokenAmountVotedForSellFee[msg.sender];
        }
        require(_sellFee <= 50 && _sellFee > 0); // 50 / 1000 = 5% || 1 / 1000 = 0.1%
        uint256 voteAmount = _balances[msg.sender];
        votedForSellFee[msg.sender] = _sellFee;
        tokenAmountVotedForSellFee[msg.sender] = voteAmount;
        totalVotedAmountForSellFee[_sellFee] += voteAmount;
        validateSellFee();
    }
}