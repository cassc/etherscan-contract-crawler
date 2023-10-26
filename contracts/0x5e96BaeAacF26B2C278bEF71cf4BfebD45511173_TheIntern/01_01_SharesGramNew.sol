/**
                                   =+***========-----====*                                      
                             ####***+++==--------------------==+**                                  
                        ####***+======--------------------------=+*#                                
                     +*#*+=========*-:::::::::::::::::::-----------+##                              
                   **+============*-:::::::::::::::::::--==----------=*                             
                 #+==============+*:::::::::::::::::::-=-::-=-:::------*                            
                #+===============++::::::::::::::::::-==-.:.==-::::-----*                           
               #+================++:::::::::::::::::::==-.::==:::::::---+#                          
              #*=================++::::::::::::::::::::-====-::::::::::--*                          
              #+=================++::::::::::::::::::::::::::::::::::::--+#                         
              #===================*::::::::::::::::::::::::::::::--========+**                      
             #*===================*:::::::::::::::::::::-----================+*#                    
             #*===================+-:-------------=============================+*                   
             #+====================++++==========================================*#                 
             #*++===+++++****####*+===============================================+#                
              **#########*************+==============================++*********+==*                
              *******************+*+-+***++====================++*********      #***                
              ********************####**+*****+++========+==+#@%%#+*=:***                           
              ****************+**=::::::-++*+++=**++*+--+::=##*#%%%#=--:                            
               **************+::--:::=####%%%#*=--:::::::-*+*=:-***#%+::                            
               *************+:::::::*%#=-****+::=#--+*#**#:********++#+:                            
                ******++=--:-++::::*##*--+****+::-#-:::::#:#*******-:-#%                            
                ===--::::::::::=++#-*****+*****:::*::::::*-******+*::-=                             
               ::::::::::::::::::-+:+**********-::==:::::-+=+***++=-==:                             
               :::::::::::::::::::*::+******+=+:::-+::::::-==***#*==:::                             
                :::::::::::::::::::*::*****++*-::=-:::::::::::::::::::                              
                  :::::::::::::::==---=#%%#*+=-:::::::::::::::::::::::                              
                     ::::::::::::+*+++=*-::-:::::::::::::::::::::::::                               
                        ::::::::::-+++***#=+::::::::::::--::::::::::                                
                             :::::::::::-::::::::::::--==:::::::::                                  
                                 :::::::::::::::::::::::::::::::                                    
                                     ::::::::::::::::::::::::                                       
                                       ==--:::::::::::-:::                                          
                                      =-=----------::.=+                                            
                                 +++++-.:------::::...-+=++++                                       
                           ++++++++===+:....:-:-::...:==++=++=++++                                  
                          +==+==========...-:..::::..-==========++=+=                               
                       +==:-+=+======++=-.-=-.:.:-=:-============+=+==                              
                     ++=::=*++++++++++++============================+:=++                           
                    ++-:..*.........................................=.:-=+                          
                    +-....#..................::.....................=:..:=+                         
                   +=.....%................-=.:==---................=:...:==                        
                  +=:.....%................=+-=+:++.................=-....-=                        
                 ==:......%................=+==+--..................==....:=+                       
                 +-.......%.................::::-...................==.....=+    
 */


// TG: https://t.me/CoinTIntern
// Twitter: https://twitter.com/TheInterncoin_


// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TheIntern is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _buyerMap;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    bool public transferDelayEnabled = false;

    address payable private _taxWallet;

    uint256 private _initialBuyTax = 0;
    uint256 private _initialSellTax = 0;

    uint256 public _finalBuyTax = 0;
    uint256 public _finalSellTax = 0;

    uint256 private _preventSwapBefore = 1;
    uint256 private _buyCount = 0;

    bool private _isFinalFeeApplied = false;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 21_000_000 * 10 ** _decimals;
    string private constant _name = unicode"The Intern";
    string private constant _symbol = unicode"INT";
    uint256 public _maxTxAmount = _tTotal * 25 / 10000; // 0.25% of total supply
    uint256 public _maxWalletSize = _tTotal * 25 / 10000; // 0.25% of total supply
    uint256 public _taxSwapThreshold = _tTotal * 50 / 10000; // 0.5% of total supply
    uint256 public _maxTaxSwap = _tTotal * 50 / 10000; // 0.5% of total supply

    IUniswapV2Router02 private router;
    address public pair;
    bool public tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Launch limits functions

    /** @dev Remove tx cap and wallet cap.
      * @notice Can only be called by the current owner.
      */
    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    /** @dev Apply final taxes.
      * @notice Can only be called by the current owner.
      */
    function setFinalTax() external onlyOwner {
        _isFinalFeeApplied = true;
    }

    /** @dev Enable trading.
      * @notice Can only be called by the current owner.
      * @notice Can only be called once.
      */
    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    // Transfer functions

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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (!swapEnabled && from != owner()) {
            require(false, "Trading is not enabled");
        }
        if (from != owner() && to != owner()) {

            if (transferDelayEnabled) {
                if (
                    to != address(router) &&
                    to != address(pair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "Only one transfer per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == pair &&
                to != address(router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                if (_buyCount < _preventSwapBefore) {
                    require(!isContract(to));
                }
                _buyCount++;
                _buyerMap[to] = true;
            }

            taxAmount = amount
                .mul((_isFinalFeeApplied) ? _finalBuyTax : _initialBuyTax)
                .div(100);
            if (to == pair && from != address(this)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount
                    .mul((_isFinalFeeApplied) ? _finalSellTax : _initialSellTax)
                    .div(100);
                require(
                    _buyCount > _preventSwapBefore || _buyerMap[from],
                    "Seller is not buyer"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        if (!tradingOpen) {
            return;
        }
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

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    // Threshold management functions

    /** @dev Set a new threshold to trigger swapBack.
      * @notice Can only be called by the current owner.
      */
    function setTaxSwapThreshold(uint256 newTax) external onlyOwner {
        _taxSwapThreshold = newTax;
    }

    /** @dev Set a new max amount to swap back.
      * @notice Can only be called by the current owner.
      */
    function setMaxTaxSwap(uint256 newTax) external onlyOwner {
        _maxTaxSwap = newTax;
    }

    // Internal functions

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    receive() external payable {}

        function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}