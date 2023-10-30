/**
 *Submitted for verification at Etherscan.io on 2023-10-13
*/

// SPDX-License-Identifier: Unlicensed

    pragma solidity ^0.8.15;

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
            return 14;
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

    contract OMEGA is ERC20 {
        
        using SafeMath for uint256;

        mapping (address => bool) private _isExcludedFromFee;
        mapping(address => bool) private _isExcludedFromMaxWallet;

        address public devWallet;
        address constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

        uint256 public buyLiquidityFee = 4;  
        uint256 public buyMarketingFee = 4;  

        uint256 public sellLiquidityFee = 10; 
        uint256 public sellMarketingFee = 15; 

        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;
        bool inSwapAndLiquify;
        bool public swapAndLiquifyEnabled = true;
        bool public tradingEnabled = false;
        uint256 public numTokensSellToAddToLiquidity;
        uint256 public maxWalletBalance;
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
        
        constructor () ERC20("OMEGA", "OMEGA"){

            numTokensSellToAddToLiquidity = 5000000000000 * 10 ** decimals();
            devWallet = 0xC723F9E63c6ce0910EE3d99A8b2767bCF4154B72;
            
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());

            uniswapV2Router = _uniswapV2Router;
            
            _isExcludedFromFee[_msgSender()] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[devWallet] = true;

            _isExcludedFromMaxWallet[owner()] = true;
            _isExcludedFromMaxWallet[address(this)] = true;
            _isExcludedFromMaxWallet[_burnAddress] = true;
            _isExcludedFromMaxWallet[devWallet] = true;

            _mint(owner(), 500000000000000 * 10 ** decimals());
            maxWalletBalance = 45000000000000  * 10 ** decimals();
        }

        function enableTrading() external onlyOwner {
             tradingEnabled = true;
        }

        function includeAndExcludeFromFee(
        address account,
        bool value
        ) public onlyOwner {
            _isExcludedFromFee[account] = value;
        }

        function isExcludedFromFee(address account) public view returns (bool) {
            return _isExcludedFromFee[account];
        }

        function includeAndExcludedFromMaxWallet(address account, bool value) public onlyOwner {
            _isExcludedFromMaxWallet[account] = value;
        }

        function isExcludedFromMaxWallet(address account) public view returns(bool){
            return _isExcludedFromMaxWallet[account];
        }

        function setSellFeePercent(
            uint256 lFee,
            uint256 mFee
        ) external onlyOwner {
            sellLiquidityFee = lFee;
            sellMarketingFee = mFee;
        }

        function setBuyFeePercent(
            uint256 lFee,
            uint256 mFee
        ) external onlyOwner {
            buyLiquidityFee = lFee;
            buyMarketingFee = mFee;
        }

        function setDevWallet(address _addr) external onlyOwner {
            devWallet = _addr;
        }  

        function setMaxWalletBalance(uint256 maxBalancePercent) external onlyOwner {
             maxWalletBalance = maxBalancePercent * 10** decimals();
        }

        function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner {
            numTokensSellToAddToLiquidity = amount * 10 ** decimals();
        }

        function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
            swapAndLiquifyEnabled = _enabled;
            emit SwapAndLiquifyEnabledUpdated(_enabled);
        }
        
        receive() external payable {}

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "ERC20: transfer amount must be greater than zero");

            if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "ERC20: trading is not enabled yet");
            }

            if (
            from != owner() &&
            to != address(this) &&
            to != _burnAddress &&
            to != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(to);
            require(
                _isExcludedFromMaxWallet[to] ||
                    (currentBalance + amount <= maxWalletBalance),
                "ERC20: Reached Max wallet holding"
            );
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
                swapBack(contractTokenBalance);
            }

            bool takeFee = true;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                super._transfer(from, to, amount);
                takeFee = false;
            } else {

                if (from == uniswapV2Pair) {
                uint256 liquidityTokens = amount.mul(buyLiquidityFee).div(100);
                uint256 marketingTokens = amount.mul(buyMarketingFee).div(100);
                amount= amount.sub(liquidityTokens.add(marketingTokens));
                super._transfer(from, address(this), liquidityTokens.add(marketingTokens));
                super._transfer(from, to, amount);

            } else if (to == uniswapV2Pair) {
                uint256 liquidityTokens = amount.mul(sellLiquidityFee).div(100);
                uint256 marketingTokens = amount.mul(sellMarketingFee).div(100);
                amount= amount.sub(liquidityTokens.add(marketingTokens));
                super._transfer(from, address(this), liquidityTokens.add(marketingTokens));
                super._transfer(from, to, amount);
            } else {
                super._transfer(from, to, amount);
            }
        }
        }

        function swapBack(uint256 contractBalance) private lockTheSwap {

                uint256 tokensForLiquidity = contractBalance.mul(sellLiquidityFee).div(100);
                uint256 marketingTokens = contractBalance.mul(sellMarketingFee).div(100);

                uint256 totalTokensToSwap = tokensForLiquidity + marketingTokens;
                
                if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

                bool success;
                
                uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
                
                swapTokensForEth(contractBalance - liquidityTokens); 
                
                uint256 ethBalance = address(this).balance;
                uint256 ethForLiquidity = ethBalance;

                uint256 ethForMarketing = ethBalance * marketingTokens / (totalTokensToSwap - (tokensForLiquidity/2));

                ethForLiquidity -= ethForMarketing;
                                
                if(liquidityTokens > 0 && ethForLiquidity > 0){
                    addLiquidity(liquidityTokens, ethForLiquidity);

                }

                (success,) = address(devWallet).call{value: ethForMarketing}("");
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

        function airdrop(address[] memory wallets, uint256[] memory amounts) external onlyOwner {
            require(wallets.length == amounts.length, "ERC20: Arrays must be the same length");
            require(wallets.length <= 200, "ERC20: 200 wallets per txn is allowed due to gas limits"); 
                for (uint i=0; i<wallets.length; i++) {
                    address wallet = wallets[i];
                    uint256 amount = amounts[i] * 10 ** decimals();
                    transfer(wallet, amount);
                }
        }
    }