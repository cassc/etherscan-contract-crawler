/**
 *Submitted for verification at Etherscan.io on 2022-12-12
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;


//Interface of the ERC20 standard.
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


//Interface for the optional metadata functions from the ERC20 standard.
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
        return msg.data;
    }
}

// Contract module which provides a basic access control mechanism
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


//Implementation of the {IERC20} interface.
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _createTotalSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract Televerse is ERC20, Ownable, LockToken {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public liquidityFee = 4;
    uint256 public marketingFee = 2; 
    uint256 public burnOnBuy = 3; 
    uint256 public burnOnSell = 4; 

    uint256 public maxTransactionAmount = 3500 * (10**18);
    uint256 public swapTokensAtAmount = 200 * (10**18);
    uint256 public maxWalletToken = 3500 * (10**18);

    mapping (address => bool) private bots;

    address public marketingWallet = 0xC8Fc5389F6aF0537eD99742b136c5095255ABCC0;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
  
    // exlcude from fees
    mapping (address => bool) private _isExcludedFromFees;
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MaxWalletAmountUpdated(uint256 prevValue, uint256 newValue);
     event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapEthForTokens(uint256 amountIn, address[] path);
    event SwapAndLiquify(uint256 tokensIntoLiqudity, uint256 ethReceived);

     modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("Televerse", "$OneTele") {
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;


        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        
        /*
            internal function  that is only called here,
            and CANNOT be called ever again
        */
        _createTotalSupply(owner(), 350000 * (10**18));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal open(from, to) override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
        }

        if (from==uniswapV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount.");
        }

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            require(amount <= maxTransactionAmount, "amount exceeds the maxTransactionAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
    
        if(overMinTokenBalance &&
            !inSwapAndLiquify &&
            to==uniswapV2Pair && 
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = swapTokensAtAmount;
            swapAndLiquify(contractTokenBalance);
            uint256 contractETHBalance = address(this).balance;
            //remove stuck balance and send to marketing wallet
            if(contractETHBalance > 0) {
                payable(marketingWallet).transfer(address(this).balance);
            }
        }
             

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 liqTokens = amount.mul(liquidityFee).div(100);
            uint256 markTokens = amount.mul(marketingFee).div(100);
            uint256 burnTokens;
            
            if(from==uniswapV2Pair || to==uniswapV2Pair) {
                
                if(liquidityFee > 0) {
                    super._transfer(from, address(this), liqTokens);
                }

                 if(marketingFee > 0) {
                    super._transfer(from, marketingWallet, markTokens);
                }

                if(burnOnBuy > 0 && from==uniswapV2Pair) {
                    burnTokens = amount.mul(burnOnBuy).div(100);
                    super._burn(from, burnTokens);
                }

                if(burnOnSell > 0 && to==uniswapV2Pair) {
                    burnTokens = amount.mul(burnOnSell).div(100);
                    super._burn(from, burnTokens);
                }

            }

            amount = amount.sub(liqTokens.add(markTokens).add(burnTokens));

        }

        super._transfer(from, to, amount);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half, address(this));

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount, address _to) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
          _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
        
    }

    function removeFee(uint256 _liqFee, uint256 _markFee, uint256 _burnBuy, uint256 _burnSell) public onlyOwner() {
        require(_liqFee.add(_markFee).add(_burnBuy) <= 9, "tax too high");
        require(_burnSell <= 4, "_burnSell fee too high");
        liquidityFee = _liqFee;
        marketingFee = _markFee; 
        burnOnBuy = _burnBuy; 
        burnOnSell = _burnSell; 
    }

    function updateMarketingWallet(address payable _markWallet) public onlyOwner {  
        marketingWallet = _markWallet;
    }

    function setMaxTransactionAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTransactionAmount = _maxTxAmount;
        require(maxTransactionAmount >= totalSupply().div(200), "value too low");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function SetSwapTokensAtAmount(uint256 newLimit) external onlyOwner {
        swapTokensAtAmount = newLimit;
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxWalletToken(uint256 _newValue) external onlyOwner {
        uint256 prevValue = maxWalletToken;
  	    maxWalletToken = _newValue;
        require(maxWalletToken >= totalSupply().div(200), "value too low");
        emit MaxWalletAmountUpdated(prevValue, _newValue);
  	}

      function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }

    }

    function burn(uint256 amount) external onlyOwner {
        super._burn(_msgSender(), amount);
    }

    receive() external payable {

    }


}