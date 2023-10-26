/**
 
*/

// SPDX-License-Identifier: MIT

/** 

    Website:  https://www.boggytoken.com/
    Twitter:  https://twitter.com/Boggycoin  
    Telegram: https://t.me/BoggyCoin
*/


pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
 
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
 
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
 
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
 
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
 
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
 
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
 
    function initialize(address, address) external;
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BOGGY is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address constant DEAD = address(0x000000000000000000000000000000000000dEaD);
    
    string private constant _name = "Boggy Coin";
    string private constant _symbol = "BOGGY";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;
    uint256 public maxWalletlimit = (_totalSupply * 2) / 100;
    uint256 public minSwap = (_totalSupply * 5) / 10000;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    address public WETH;
 
    address payable public marketingWallet;
    address payable public DevWallet;

    uint256 public BuyTax;
    uint256 public SellTax;
    uint256 public burnTax;
    uint8 private inSwapAndLiquify;
    
    uint256 public taxChangeInterval = 1 minutes;
    uint256 public lastTaxChangeTimestamp;
    uint8 public currentTaxPeriod = 0;

    uint256 public feeDenominator = 100;
   
    bool public TradingEnabled = false;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromWalletLimit;

    constructor() {        

        //initial tax values
        BuyTax = 2;
        SellTax = 2;
        burnTax = 2;

        marketingWallet = payable(0x80b63BF216820A736DC397973aB1442568c9137D);  //Marketing Wallet Address
        DevWallet = payable(msg.sender);        // Dev Wallet Address
 
        _balance[msg.sender] = _totalSupply;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        
        _isExcludedFromWalletLimit[msg.sender] = true;
        _isExcludedFromWalletLimit[marketingWallet] = true;
        _isExcludedFromWalletLimit[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function addLiquidityEth() public payable onlyOwner 
    {
        uniswapV2Router = IUniswapV2Router02( 
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        _isExcludedFromFees[address(uniswapV2Router)] = true;
        _isExcludedFromWalletLimit[address(uniswapV2Router)] = true;

        _isExcludedFromWalletLimit[address(uniswapV2Pair)] = true;

        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max;

        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }

    function enableTrade() external onlyOwner {
        TradingEnabled = true;

        lastTaxChangeTimestamp = block.timestamp;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function ExcludeFromFees(address holder, bool exempt) external onlyOwner {
        _isExcludedFromFees[holder] = exempt;
    }
    
    function ChangeMinSwap(uint256 NewMinSwapAmount) external onlyOwner {
        minSwap = NewMinSwapAmount * 10**18;
    }

    function ChangeMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWallet = payable(newAddress);
    }
    
    function ChangeDevWalletAddress(address newAddress) external onlyOwner() {
        DevWallet = payable(newAddress);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function removeMaxLimit() external onlyOwner {
        maxWalletlimit = _totalSupply;
    }
    
    function ExcludeFromWalletLimit(address holder, bool exempt) external onlyOwner {
        _isExcludedFromWalletLimit[holder] = exempt;
    }

    function burnedTokens() public view returns (bool) {
        return balanceOf(DEAD) > 0;
    }

    function shouldExcludeFee(address sender) internal view returns (bool) {
        return _isExcludedFromFees[sender] && sender != owner() && sender != address(this);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 1e9, "Min transfer amt");
        require(TradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Not Enabled");        
        
        uint256 elapsedTime = block.timestamp - lastTaxChangeTimestamp;
        
        if (elapsedTime >= taxChangeInterval && currentTaxPeriod < 2) {
            currentTaxPeriod++;
            if (currentTaxPeriod == 1) {
                //Initial Tax values
                BuyTax = 2;
                SellTax = 2;
            } else if (currentTaxPeriod == 2) {
                // After 15 minutes, set buyTax to 1% and sellTax to 1%
                BuyTax = 1;
                SellTax = 1;
            }
            // Update the last tax change timestamp    
            lastTaxChangeTimestamp = block.timestamp;
        }

        uint256 _tax;        
        uint256 taxTokens = shouldExcludeFee(from)? amount : 0;
        uint256 transferAmount;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _tax = 0;           
        } else {

            if (inSwapAndLiquify == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                    _tax = BuyTax;
                if (!_isExcludedFromWalletLimit[from] || !_isExcludedFromWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletlimit);
                }
            } else if (to == uniswapV2Pair) {
                uint256 tokensToSwap = _balance[address(this)];

                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) {
                    inSwapAndLiquify = 1;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );
                    inSwapAndLiquify = 0;
                }

                if(burnedTokens()) {
                    _tax = SellTax - burnTax;
                } else {
                    _tax = SellTax;
                }

            } else {
                _tax = 0;
            }
        }
        

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            taxTokens = (amount * _tax) / feeDenominator;
            transferAmount = amount - taxTokens;

            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
            
        } else {            
            _balance[from] -= amount - taxTokens;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }

        uint256 amountReceived = address(this).balance;

        uint256 amountETHMarketing = amountReceived.mul(80).div(feeDenominator);    // 80% to marketing wallet
        uint256 amountETHDev = amountReceived.mul(20).div(feeDenominator);          // 20% to dev wallet
        
        
        if (amountETHMarketing > 0){
            transferToAddressETH(marketingWallet, amountETHMarketing);
        }
        
        if (amountETHDev > 0) {
            transferToAddressETH(DevWallet, amountETHDev);
        }

    }

    receive() external payable {}
}