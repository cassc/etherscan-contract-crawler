pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Miragrow is IERC20, Ownable {
    string private constant _name         = "Miragrow";
    string private constant _symbol       = "MIRA";
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address payable private constant _walletMarketing = payable(0xb0D4501B57467c1Aa13708808333dbCEB2D41b02);

    mapping (address => bool) private _noFees;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP = address(0);

    uint256 public startTime;       // Reward Start Time
    uint256 public weekTime;        // Reward Weekly Time

    address public latest_1 = address(0);
    address public latest_2 = address(0);
    address public latest_3 = address(0);

    address[] public buyers;        //For weekly reward
    mapping (address => uint256) lastBuyTime;
    
    uint256 public randomResult;    //For Random Generator
    uint256 private nonce = 0;

    uint256 _taxEth = 0;

    IWETH constant private weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Address of WETH contract on Goerli network
    
    function convertEthToWeth() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        weth.deposit{value: msg.value}();
    }

    constructor() {
        _balances[owner()] = _totalSupply * 99 / 100;
        _balances[_walletMarketing] = _totalSupply * 1 / 100;
        
        _noFees[owner()] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;

        startTime = block.timestamp;
        weekTime = block.timestamp;

        _approveRouter();
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _approveRouter() internal {
        _allowances[owner()][_swapRouterAddress] = type(uint256).max;
        _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
    }

    function addLiquidity() external payable onlyOwner {
        require(_primaryLP == address(0), "LP exists");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        // If not adding liqudity
        if(sender == _swapRouterAddress || sender == _primaryLP) {
            if(amount > 1000 * (10 ** _decimals)) {
                latest_3 = latest_2;
                latest_2 = latest_1;
                latest_1 = recipient;
            }
            
            //If token amount of buyer is more than 0.25% of total supply
            if(indexOf(recipient) == type(uint256).max && _balances[recipient] > _totalSupply * 25 / 10000)
                buyers.push(recipient);
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        
        _balances[sender] -= amount;
        _balances[recipient] += _transferAmount;

        uint256 _lastPotEth = address(this).balance;

        if ( _taxAmount > 0 ) {
            _balances[address(this)] += _taxAmount;
            _swapTaxTokensForEth(_balances[address(this)]);
            _taxEth = address(this).balance - _lastPotEth;  // For sending 1% to marketing wallet
            rewardLatestPlayers();
        }

        return true;
    }

    function rewardLatestPlayers() public payable {
        // transfer 1% tax to marketing wallet
        _walletMarketing.transfer(_taxEth * 1 / 5);
        _taxEth = 0;

        uint256 potBalance = address(this).balance;

        // Every week
        if(block.timestamp > 604800 + weekTime) 
            payable(buyers[getRandomNumber()]).transfer(potBalance / 2);

        // Every 12 hours
        else if (block.timestamp > 42300 + startTime) {
            payable(latest_1).transfer(potBalance * 5 / 100);
            payable(latest_2).transfer(potBalance * 3 / 100);
            payable(latest_3).transfer(potBalance * 2 / 100);
        }

        weekTime += ((block.timestamp - weekTime) / 604800) * 604800;
        startTime += ((block.timestamp - startTime) / 42300) * 42300;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount = 0;
        
        if ( !_noFees[sender] && !_noFees[recipient] ) {    
            if ( sender == _swapRouterAddress || recipient == _swapRouterAddress ) {
                taxAmount = amount * 5 / 100;
            }
        }

        return taxAmount;
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter();
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _transferProfit(uint256 tokenAmount) external payable onlyOwner {
        payable(owner()).transfer(tokenAmount);
    }
 
    function indexOf(address target) internal view returns (uint) {
        for (uint i = 0; i < buyers.length; i++) {
            if (buyers[i] == target) {
                return i;
            }
        }

        return type(uint256).max;
    }

    function getRandomNumber() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        nonce++;
        randomResult = randomNumber;
        return randomNumber;
    }
}