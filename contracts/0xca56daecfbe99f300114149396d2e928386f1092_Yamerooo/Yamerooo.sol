/**
 *Submitted for verification at Etherscan.io on 2023-09-16
*/

// SPDX-License-Identifier: MIT
/**

https://yamero.club
https://twitter.com/0x_yamero_x0
__   _____  ___  ___ ___________ _____  _____  _____ _ _ _ 
\ \ / / _ \ |  \/  ||  ___| ___ \  _  ||  _  ||  _  | | | |
 \ V / /_\ \| .  . || |__ | |_/ / | | || | | || | | | | | |
  \ /|  _  || |\/| ||  __||    /| | | || | | || | | | | | |
  | || | | || |  | || |___| |\ \\ \_/ /\ \_/ /\ \_/ /_|_|_|
  \_/\_| |_/\_|  |_/\____/\_| \_|\___/  \___/  \___/(_|_|_)

       :&@@@@@@@@B7                                         
       YPPG#@@@@@@@5~                                       
      ~P????5B@@@@@@@P7:                         :!J55^     
     :#5??????Y&@@@@@@@&5!                    ^JG&@@@5.     
    .P&J???????Y@@@@@@@@@@B55yamero.clubJG&@@@@@?       
    !@G????????Y@@@@@@@@@@@@@@@@@@@@@&GYYB&@@@@@@@G5        
    !@P???????Y#@@@@@@@@@@@@@@@@@@&#BPY&@@@@@@@@@#5^        
    ~@GGBYJY5B@@@@@@@@@#BPPYYYYY5YJJ?~:7PBGPGBGB@&?         
   ~G@@@@&&@@@@@@@@@@@P???YPGPP5???J?^^^7?J###&B5#^         
 !G@@@@@@@@@@@@@@@@@@B??JB@@G#@@G?JJ!^^^~?#BBB@@BJG~        
G@@@@@@@@@@@@@@@&&@@@&G?JB@&#B&&P?7~^^^^^~PGB&#PJ5@#.       
@@@@@@@yamero.club&##GPPYJJP5GG5?!^^^^^^^~^^!??J5#@@!        
@@@@@@@@@@@@@@@@@@&#BG55J??J?!~^^^^^^~7?777!~~P@@@G         
@@@@@@@@@@@@@@@@@@@@@@#BG5?~^^^^^^^^^^^!7777~^^?B&J         
@@@@@@@@@@@@@######BGGPPPY7^^^^^^^^^^^~!7!~^^^^:YBP?:       
@@@@@@@@@@@@@@@@@@@@@&&&#5?7!~^^^^^^!JYPJ!^^^^^~5#J.        
@@@yamero.club@@@@@@@&&&GJ?JYYPGG#JY@@@@@#7~~!75#G?~        
@@@&#@@@@@@@@@@&PY55?7~!?JG&&@@@@@@@@@@@@#JYP&@&#~          
@@@B?G@@@@@@@@5~^^^^^^^^^?##BBBBBGB#@@@@@@@@@#57:           
@@@5??YGBBGPJ!^^^^^^^^^^^^JBBGYJJJPP5#J!~JP?^.              
@@B???????^^^^^^^^^^^^^^^^^7JYY77J?7J7^:                    
@@5??????J7~^^^^^^^^^~~^^^^^~!77777J?^:                     
@@BJ??????J?!~^^^^^~7J?^^^^^75!~~!!Y!:                      
@@@#P??????JJ??7777JJJ?7^^^^Y&GP5JJ?.                       
@@@@@B??JJJ??JJJJJyamero.club&@@@@:                       
@@@@@@GJ???JJJJJ????????JJ??J#@@@@@&:                       
@@@@@@@&Y~^~~!7?J?????????YP&@@@@@@5                        
@@@@@@@@@#J^^^^~7J???????Y@@@@@@@@@~                        

*/

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// Dex Factory contract interface
interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// Dex Router contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Yamerooo is Context, IERC20, Ownable {
    
    string private _name = "Yamerooo";
    string private _symbol = "YMR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 420_690_000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTxn;
    mapping(address => bool) public isExcludedFromMaxHolding;

    uint256 public minTokenToSwap = (_totalSupply * 5) / (1000); // this amount will trigger swap and distribute
    uint256 public maxHoldLimit = (_totalSupply * 2) / (100); // this is the max wallet holding limit
    uint256 public maxTxnLimit = (_totalSupply * 2) / (100); // this is the max transaction limit
    uint256 public percentDivider = 100;
    uint256 public launchedAt;

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public feesStatus; // enable by default
    bool public trading; // once enable can't be disable afterwards
    bool public limitsRemoved;

    IDexRouter public dexRouter; // router declaration
    address public dexPair; // pair address declaration
    
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    address private marketingWallet; // marketing address declaration
    uint256 public marketingFeeOnBuy = 10;
    uint256 public marketingFeeOnSell = 15;

    event SwapBack(uint256 tokensSwapped);

    constructor(address _marketingWallet) {
        _balances[owner()] = _totalSupply;

        marketingWallet = _marketingWallet;
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[address(dexRouter)] = true;

        isExcludedFromMaxTxn[owner()] = true;
        isExcludedFromMaxTxn[address(this)] = true;
        isExcludedFromMaxTxn[marketingWallet] = true;
        isExcludedFromMaxTxn[address(dexRouter)] = true;

        isExcludedFromMaxHolding[owner()] = true;
        isExcludedFromMaxHolding[address(this)] = true;
        isExcludedFromMaxHolding[marketingWallet] = true;
        isExcludedFromMaxHolding[address(dexRouter)] = true;
        isExcludedFromMaxHolding[dexPair] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive ETH from dexRouter when swapping
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function includeOrExcludeFromFee(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTxn(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromMaxTxn[account] = value;
    }

    function includeOrExcludeFromMaxHolding(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromMaxHolding[account] = value;
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount * 1e18;
    }

    function setMaxHoldLimit(uint256 _amount) external onlyOwner {
        maxHoldLimit = _amount * 1e18;
    }

    function setMaxTxnLimit(uint256 _amount) external onlyOwner {
        maxTxnLimit = _amount * 1e18;
    }

    function setMarketingBuyFeePercent(uint256 _marketingFee) external onlyOwner {
        marketingFeeOnBuy = _marketingFee;
    }

    function setMarketingSellFeePercent(uint256 _marketingFee) external onlyOwner {
        marketingFeeOnSell = _marketingFee;
    }

    function setSwapAndLiquifyEnabled(bool _value) public onlyOwner {
        swapAndLiquifyEnabled = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateMarketingWalletAddress(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
        excludeWallet(_marketingWallet);
    }

    function excludeWallet(address wallet) internal {
        isExcludedFromFee[wallet] = true;
        isExcludedFromMaxTxn[wallet] = true;
        isExcludedFromMaxHolding[wallet] = true;
    }

    function enableTrading() external onlyOwner {
        require(!trading, ": already enabled");
        trading = true;
        feesStatus = true;
        swapAndLiquifyEnabled = true;
        launchedAt = block.timestamp;
    }

    function limitBreak() external onlyOwner {
        require(!limitsRemoved, ": already removed");
        limitsRemoved = true;
        maxHoldLimit = _totalSupply;
        maxTxnLimit = _totalSupply;
    }

    function totalMarketingBuyFeePerTx(uint256 amount) public view returns (uint256) {
        return (amount * marketingFeeOnBuy) / (percentDivider);
    }

    function totalMarketingSellFeePerTx(uint256 amount) public view returns (uint256) {
        return (amount * marketingFeeOnSell) / (percentDivider);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), " approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        if (!isExcludedFromMaxTxn[from] && !isExcludedFromMaxTxn[to]) {
            require(amount <= maxTxnLimit, " max txn limit exceeds");

            if (!trading) {
                require(
                    dexPair != from && dexPair != to,
                    ": trading is disabled"
                );
            }
        }

        if (!isExcludedFromMaxHolding[to]) {
            require(
                (balanceOf(to) + amount) <= maxHoldLimit,
                ": max hold limit exceeded"
            );
        }

        swapAndLiquify(from, to);

        bool takeFee = true;

        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (dexPair == sender && takeFee) {

            uint256 allFee = totalMarketingBuyFeePerTx(amount);

            uint256 tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        }
        else if (dexPair == recipient && takeFee) {

            uint256 allFee = totalMarketingSellFeePerTx(amount);

            uint256 tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        }
        else {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);
        emit Transfer(sender, address(this), amount);
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));

        _approve(address(this), address(dexRouter), contractBalance);

        Utils.swapTokensForEth(address(dexRouter), contractBalance);
        uint256 ethForMarketing = address(this).balance;

        if (ethForMarketing > 0) {
            payable(marketingWallet).transfer(ethForMarketing);
        }

        emit SwapBack(contractBalance);
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool shouldSell = contractTokenBalance >= minTokenToSwap;
        if (
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == dexPair)
        ) {
            swapBack();
        }
    }

    function manualUnclog() external {
        if (swapAndLiquifyEnabled) {
            swapBack();
        }
    }

    function rescueEth() external {
        require(address(this).balance > 0, "Invalid Amount");
        payable(marketingWallet).transfer(address(this).balance);
    }

    function rescueToken(IERC20 _token) external {
        require(_token.balanceOf(address(this)) > 0, "Invalid Amount");
        _token.transfer(marketingWallet, _token.balanceOf(address(this)));
    }

}

library Utils {
    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }
}