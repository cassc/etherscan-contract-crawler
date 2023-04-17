/**
 *Submitted for verification at Etherscan.io on 2023-04-16
*/

// SPDX-License-Identifier: Unlicensed

    pragma solidity ^0.8.4;

    interface IERC20 {
        
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    library SafeMath {
        
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            return a + b;
        }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return a - b;
        }
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            return a * b;
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return a / b;
        }
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            unchecked {
                require(b <= a, errorMessage);
                return a - b;
            }
        }
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a / b;
            }
        }
        
    }

    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }

    abstract contract Ownable is Context {
        address internal _owner;
        address private _previousOwner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        constructor () {
            _owner = _msgSender();
            emit OwnershipTransferred(address(0), _owner);
        }
        
        function owner() public view virtual returns (address) {
            return _owner;
        }
        
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
        
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }

    interface IERC20Metadata is IERC20 {
       function name() external view returns (string memory);
       function symbol() external view returns (string memory);
       function decimals() external view returns (uint8);
    }
    contract ERC20 is Context,Ownable, IERC20, IERC20Metadata {
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
            return 9;
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

    interface IUniswapV2Pair {
        function factory() external view returns (address);
    }

    interface IUniswapV2Router01 {
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

    interface IUniswapV2Router02 is IUniswapV2Router01 {     
       function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

    contract TOKEN is ERC20 {
        
        using SafeMath for uint256;

        mapping (address => bool) private _isExcludedFromFee;
        mapping(address => bool) private _isExcludedFromMaxWallet;


        address public _marketingWalletAddress;
        address public _devWalletAddress;    
        address public _donationWalletAddress;
        address public _giveawayWallet;
        address private _teamWalletOne;
        address private _teamWalletTwo;
        address constant _burnAddress = 0x000000000000000000000000000000000000dEaD;


        uint256 public _buyLiquidityFee = 15;  
        uint256 public _buyMarketingFee = 20;  
        uint256 public _buyDonationFee = 15;  
        uint256 public _buyBurnFee = 5;  

        uint256 public _sellLiquidityFee = 15; 
        uint256 public _sellMarketingFee = 20; 
        uint256 public _sellDonationFee = 15;
        uint256 public _sellBurnFee = 5;  


        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;
        bool inSwapAndLiquify;
        bool public swapAndLiquifyEnabled = true;
        uint256 public _maxWalletBalance;
        uint256 public numTokensSellToAddToLiquidity;
        event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
        event SwapAndLiquifyEnabledUpdated(bool enabled);
        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
        );
        
        modifier lockTheSwap {
            inSwapAndLiquify = true;
            _;
            inSwapAndLiquify = false;
        }
        
        constructor () ERC20("1776", "merica"){

            numTokensSellToAddToLiquidity = 1000000 * 10 ** decimals();
            _marketingWalletAddress = 0xd83f597Cfbec869647b89AA6E7A673E53774ba62;
            _donationWalletAddress = 0x2D226B259D93E69D5EE3b9E556b066D4cc7E327c;
            _devWalletAddress = 0x57D74a1e656DD7FB04423F91112D9524E337F6Fd;
            _giveawayWallet = 0x630E56C57Ef9FDcEA9BeB01B8c015B917F8Af73b;
            _teamWalletOne = 0x9A1baf5548E6Fa99ada6e8FbC2261eBb75556015;
            _teamWalletTwo = 0x189CaF4B993F3DA46f1Dda78FD5B522f891c6D4c;

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            uniswapV2Router = _uniswapV2Router;
            
            _isExcludedFromFee[_msgSender()] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[_marketingWalletAddress] = true;
            _isExcludedFromFee[_donationWalletAddress] = true;
            _isExcludedFromFee[_devWalletAddress] = true;
            _isExcludedFromFee[_giveawayWallet] = true;
            _isExcludedFromFee[_teamWalletOne] = true;
            _isExcludedFromFee[_teamWalletTwo] = true;

            _isExcludedFromMaxWallet[owner()] = true;
            _isExcludedFromMaxWallet[address(this)] = true;
            _isExcludedFromMaxWallet[_marketingWalletAddress] = true;
            _isExcludedFromMaxWallet[_donationWalletAddress] = true;
            _isExcludedFromMaxWallet[_devWalletAddress] = true;
            _isExcludedFromMaxWallet[_giveawayWallet] = true;
            _isExcludedFromMaxWallet[_teamWalletOne] = true;
            _isExcludedFromMaxWallet[_teamWalletTwo] = true;

            _mint(owner(), 1500000000 * 10 ** decimals());
            _mint(_marketingWalletAddress,1500000000 * 10 ** decimals());
            _mint(_devWalletAddress,500000000 * 10 ** decimals());
            _mint(_giveawayWallet,2500000000 * 10 ** decimals());
            _mint(_teamWalletOne,2000000000 * 10 ** decimals());
            _mint(_teamWalletTwo,2000000000 * 10 ** decimals());

            _maxWalletBalance = (totalSupply() * 1 ) / 100;
            
        }

        function burn(uint tokens) external onlyOwner {
            _burn(msg.sender, tokens * 10 ** decimals());
        }

        function excludeFromFee(address account) public onlyOwner {
            _isExcludedFromFee[account] = true;
        }
        
        function includeInFee(address account) public onlyOwner {
            _isExcludedFromFee[account] = false;
        }

          function includeAndExcludedFromMaxWallet(address account, bool value) public onlyOwner {
            _isExcludedFromMaxWallet[account] = value;
        }

         function isExcludedFromMaxWallet(address account) public view returns(bool){
            return _isExcludedFromMaxWallet[account];
         }

        function setSellFeePercent(
            uint256 lFee,
            uint256 mFee,
            uint256 doFee,
            uint256 deFee
        ) external onlyOwner {
            _sellLiquidityFee = lFee;
            _sellMarketingFee = mFee;
            _sellDonationFee = doFee;
            _sellBurnFee = deFee;
        }

        function setBuyFeePercent(
            uint256 lFee,
            uint256 mFee,
            uint256 doFee,
            uint256 deFee
        ) external onlyOwner {
            _buyLiquidityFee = lFee;
            _buyMarketingFee = mFee;
            _buyDonationFee = doFee;
            _buyBurnFee = deFee;
        }

        function setMarketingWalletAddress(address _addr) external onlyOwner {
            _marketingWalletAddress = _addr;
        }  

        function setDonationWalletAddress(address _addr) external onlyOwner {
            _donationWalletAddress = _addr;
        }

        function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner {
            numTokensSellToAddToLiquidity = amount * 10 ** decimals();
        }

         function setMaxWalletBalance(uint256 maxBalancePercent) external onlyOwner {
        _maxWalletBalance = maxBalancePercent * 10** decimals();
        }


        function setRouterAddress(address newRouter) external onlyOwner {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            uniswapV2Router = _uniswapV2Router;
        }

        function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
            swapAndLiquifyEnabled = _enabled;
            emit SwapAndLiquifyEnabledUpdated(_enabled);
        }
        
        receive() external payable {}

        function withdrawStuckedETH(uint amount) external onlyOwner{
            (bool sent,) = _owner.call{value: amount}("");
            require(sent, "Failed to send ETH");    
            }

        function isExcludedFromFee(address account) public view returns(bool) {
            return _isExcludedFromFee[account];
        }

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
         
             if (
            from != owner() &&
            to != address(this) &&
            to != _burnAddress &&
            to != uniswapV2Pair ) 
            {
            uint256 currentBalance = balanceOf(to);
            require(_isExcludedFromMaxWallet[to] || (currentBalance + amount <= _maxWalletBalance),
                    "ERC20: Reached max wallet holding");
            }

            uint256 contractTokenBalance = balanceOf(address(this)); 
            bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }

            bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super._transfer(from, to, amount);
            takeFee = false;
        } else {

            if (from == uniswapV2Pair) {
                // Buy
                uint256 liquidityTokens = amount.mul(_buyLiquidityFee).div(1000);
                uint256 marketingTokens = amount.mul(_buyMarketingFee).div(1000);
                uint256 donationTokens = amount.mul(_buyDonationFee).div(1000);
                uint256 burnTokens = amount.mul(_buyBurnFee).div(1000);
                amount= amount.sub(liquidityTokens.add(marketingTokens).add(donationTokens).add(burnTokens));
                super._transfer(from, address(this), liquidityTokens);
                super._transfer(from, _marketingWalletAddress,marketingTokens);
                super._transfer(from, _donationWalletAddress, donationTokens);
                super._transfer(from, _burnAddress,burnTokens);
                super._transfer(from, to, amount);

            } else if (to == uniswapV2Pair) {
                // Sell
                uint256 liquidityTokens = amount.mul(_sellLiquidityFee).div(1000);
                uint256 marketingTokens = amount.mul(_sellMarketingFee).div(1000);
                uint256 donationTokens = amount.mul(_sellDonationFee).div(1000);
                uint256 burnTokens = amount.mul(_sellBurnFee).div(1000);
                amount= amount.sub(liquidityTokens.add(marketingTokens).add(donationTokens).add(burnTokens));
                super._transfer(from, address(this), liquidityTokens);
                super._transfer(from, _marketingWalletAddress,marketingTokens);
                super._transfer(from, _donationWalletAddress, donationTokens);
                super._transfer(from, _burnAddress,burnTokens);
                super._transfer(from, to, amount);
            } else {
                // Transfer
                super._transfer(from, to, amount);
            }
        
        }

        }

        function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
            uint256 half = contractTokenBalance.div(2);
            uint256 otherHalf = contractTokenBalance.sub(half);
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half); 
            uint256 newBalance = address(this).balance.sub(initialBalance);
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }

        function swapTokensForEth(uint256 tokenAmount) private {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }

        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
    }