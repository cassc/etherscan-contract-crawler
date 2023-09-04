/**
 *Submitted for verification at Etherscan.io on 2023-07-22
*/

// SPDX-License-Identifier: MIT

// RICHPEPE is here to unleash the tsunami of wealth for it's believers and only for it's believers.
// Old Records will be broken, New WHALES will be created, New Millionaires will be made.
// RICHPEPE magic will shine everywhere.

// RICHPEPE IS HERE TO MAKE EVERY BELIEVER RICH.
// JUST BUY AND HODL. YOU MIGHT BECOME A MILLIONAIRE.
// WHO KNOWS ?

// Next Sensation: RICHPEPE NFTs with RICHPEPE NFT REWARDS and RICHPEPE MATRIX REWARDS

// These rewards will redefine the whole NFT MARKET and NFT REWARD TOKENOMICS

// RICHPEPE NFTs : Total Supply : 10000

// Top 5000 RICHPEPE token holders will each get 1 RICHPEPE NFT absolutely FREE.

// RICHPEPE NFT REWARDS - a dramatic twist - will redefine the whole NFT market
// 50% of the RICHPEPE tokens collected as Buy - Sell taxes on RICHPEPE token transfers will be swaped for ETH
// and distributed to all RICHPEPE NFT holders as RICHPEPE NFT REWARDS
// All RICHPEPE NFT holders will regularly earn RICHPEPE NFT REWARDS according to their RICHPEPE token holdings
// and that too in ETH

// RICHPEPE MATRIX REWARDS - another dramatic twist - will be revealed at the time of RICHPEPE NFT launch
// All RICHPEPE NFT holders will also earn RICHPEPE MATRIX REWARDS regularly according to their RICHPEPE token holdings
// and that too in ETH

// After Liquidity is added and Trading is Enabled, Contract will be renounced and LP will be locked for 3 years.

// Website: https://richpepe.vip

// Telegram: https://t.me/richpepevip

// Twitter: https://twitter.com/richpepevip

// Linktree: https://linktr.ee/richpepevip

pragma solidity ^0.8.0;

// Dependency file: contracts/interfaces/IUniswapV2Factory.sol

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// Dependency file: contracts/interfaces/IUniswapV2Router02.sol

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// Dependency file: contracts/interfaces/IERC20Extended.sol

// pragma solidity =0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RICHPEPE is IERC20, Ownable {
    uint8 private constant _decimals = 18;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    IUniswapV2Router02 public router;
    mapping(address => bool) public pairAddress;
    mapping (address => bool) public _isExcluded;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address payable public _NFTRewardWallet; // Tokens collected through Buy - Sell Tax will be swapped for ETH
    // and 50% of this ETH will be deposited in this _NFTRewardWallet to be distributed to RICHPEPE NFT holders 
    // as RICHPEPE NFT REWARDS according to their RICHPEPE token holdings.
   
    address payable public _devWallet;

    uint256 public _initialBuyTax=20; // For Initial 100 Buy Transactions, Buy Tax will be 20%
    uint256 public _initialSellTax=30; // Till the first 300 Buy Transactions are completed, the Sell Tax will be 30%
    uint256 public _finalBuyTax=5; // After initial 100 Buy Transactions, Buy Tax will be reduced to _finalBuyTax amount
    uint256 public _finalSellTax=5; // After initial 300 Buy Transactions, Sell Tax will be reduced to _finalSellTax amount
    uint256 public _reduceBuyTaxAt=100; // After initial 100 Buy Transactions, Buy Tax will be reduced to _finalBuyTax amount
    uint256 public _reduceSellTaxAt=300; // After initial 300 Buy Transactions, Sell Tax will be reduced to _finalSellTax amount
    uint256 public _preventSwapBefore=500; // Tokens collected for Tax can be swapped only after 500 Buy Transactions. Not before that.
    uint256 public _buyCount=0;

    
    uint256 public _maxTxAmount =   4206900000000 ether; // 1% of Total Supply till first 100 Buy Transactions, thereafter = Total Supply
    uint256 public _maxWalletSize = 4206900000000 ether; // 1% of Total Supply till first 100 Buy Transactions, thereafter = Total Supply
    uint256 public _taxSwapThreshold = 10000 ether;
    uint256 public _maxTaxSwap = 1000000000000 ether;

    bool public tradingOpen;
    bool private inSwap;
    bool private swapEnabled;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor(
        string memory name_,
        string memory symbol_,
        address NFTRewardWallet
    ){
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 420690000000000 ether;
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address pairrAddress = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        pairAddress[pairrAddress] = true;

        _NFTRewardWallet = payable(NFTRewardWallet);
        _devWallet = payable(msg.sender);

        _isExcluded[address(msg.sender)] = true;
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;
        _isExcluded[address(_NFTRewardWallet)] = true;
        _isExcluded[address(_devWallet)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

     function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(amount > 0, "Amount needs to be > 0");

        if(!tradingOpen){
            require(_isExcluded[sender], "Trading not open yet");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (!inSwap && pairAddress[recipient] && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                uint256 tokensForSwap;
                if(contractTokenBalance > _maxTaxSwap){
                    tokensForSwap = _maxTaxSwap;
                }else{
                    tokensForSwap = contractTokenBalance;
                }
                swapTokensForEth(tokensForSwap);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETH();
            }
        }

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

// After initial 100 Buy Transactions all limits will be automatically removed
// After initial 100 Buy Transactions the maxTxAmount will be equal to Total Supply
// After initial 100 Buy Transactions the maxWalletSize will be equal to Total Supply
        if(_buyCount > 100){ 
                _maxTxAmount = _totalSupply;
                _maxWalletSize = _totalSupply;
        }

        uint256 taxAmount;

        if(pairAddress[sender] && !_isExcluded[recipient]){              
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(recipient) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            _buyCount++;               
            taxAmount = amount * ((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax)/(100);
        }

        if(pairAddress[recipient] && !_isExcluded[sender]){
            taxAmount = amount * ((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax)/(100);
        }

        amount = amount -= taxAmount;

        _balances[address(this)] += taxAmount;

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approval from zero address");
        require(spender != address(0), "Approval to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(!tradingOpen){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETH() private {
        uint256 amountEthToSend = address(this).balance;
        uint256 amountForNFTRewards = amountEthToSend/2;
        uint256 amountForDev = amountEthToSend - amountForNFTRewards;
        _NFTRewardWallet.transfer(amountForNFTRewards);
        _devWallet.transfer(amountForDev);
    }

// After liquidity is added, trading will be enabled
// Once Trading is enabled, it can not be paused or stopped.

    function enableTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function manualSwap() external {
        require(_msgSender()==_devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETH();
        }
    }

    function removeAllTaxes() external { // Afterwards all taxes will be removed.
        require(_msgSender() == _devWallet); //  Once the taxes are removed
        _finalBuyTax=0; // the taxes can not be restored
        _finalSellTax=0; // Thus taxes will permanently remain zero.
    }

    function exclude(address account) external {
        require(_msgSender() == _devWallet);
        _isExcluded[account] = true;
    }

    function setNewNFTRewardWallet(address newNFTRewardWallet) external {
        require(_msgSender() == _devWallet);
        _NFTRewardWallet = payable(newNFTRewardWallet);
    }

    function rescueETH() external {
        require(_msgSender() == _devWallet);
        payable(_msgSender()).transfer(address(this).balance);
    }

    function rescueERC20(address _token) external {
        require(_msgSender() == _devWallet);
        transfer(_msgSender(), IERC20(address(_token)).balanceOf(address(this)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

}