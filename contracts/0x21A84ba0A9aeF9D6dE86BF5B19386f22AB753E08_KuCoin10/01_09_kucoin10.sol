// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract KuCoin10 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) public _lastTrade;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) private _isExcludedFromRewards;

    address[] private _excludedFromRewards;

    uint8 private _decimals = 18;
    uint8 private _reflectionFee;
    uint8 private _liquidityFee;
    uint8 private _vaultFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**(_decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _maxTxAmount = _tTotal.div(1000).mul(10);
    uint256 public _maxWalletSize = _tTotal.div(1000).mul(10);
    uint256 private numTokensSellToAddToLiquidity = _tTotal.div(50000).mul(1);
    uint256 public deadBlocks = 2;
    uint256 public launchedAt = 0;

    address payable private _vaultAddress;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    address public immutable uniswapV2Pair;

    string private _name = "KuCoin 10";
    string private _symbol = "K10";

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;
    bool public feesEnabled = true;

    struct BuyFee {
        uint8 reflection;
        uint8 liquidity;
        uint8 vault;
    }

    struct SellFee {
        uint8 reflection;
        uint8 liquidity;
        uint8 vault;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    IUniswapV2Router02 public immutable uniswapV2Router;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _vaultAddress = payable(_msgSender());
        _rOwned[_msgSender()] = _rTotal;

        buyFee.reflection = 1;
        buyFee.liquidity = 2;
        buyFee.vault = 3;

        sellFee.reflection = 1;
        sellFee.liquidity = 2;
        sellFee.vault = 3;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[DEAD] = true;

        excludeFromReward(address(this));
        excludeFromReward(DEAD);
        excludeFromReward(uniswapV2Pair);

        emit Transfer(ZERO, _msgSender(), _tTotal);
    }

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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromRewards[sender],
            "Excluded addresses cannot call this function"
        );

        (
            ,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, , ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        (
            ,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        if (!deductTransferFee) {
            return rAmount;
        } else {
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }


    function updatevaultAddress(address payable newAddress) public onlyOwner {
        require(newAddress != ZERO, "vaultWallet address cannot be 0");
        _isExcludedFromFees[_vaultAddress] = false;
        _isExcludedFromLimits[_vaultAddress] = false;
        _vaultAddress = newAddress;
        _isExcludedFromFees[_vaultAddress] = true;
        _isExcludedFromLimits[_vaultAddress] = true;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromRewards[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excludedFromRewards.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (_excludedFromRewards[i] == account) {
                _excludedFromRewards[i] = _excludedFromRewards[_excludedFromRewards.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excludedFromRewards.pop();
                break;
            }
        }
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        _isExcludedFromFees[account] = isExcluded;
    }

    function multipleExcludeFromFees(address[] memory accounts, bool isExcluded) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isExcluded;
        }
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        _isExcludedFromLimits[account] = isExcluded;
    }

    function multipleExcludeFromLimits(address[] memory accounts, bool isExcluded) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromLimits[accounts[i]] = isExcluded;
        }
    }

    function setSellFee(
        uint8 reflection,
        uint8 liquidity,
        uint8 vault
    ) public onlyOwner {
        sellFee.reflection = reflection;
        sellFee.vault = vault;
        sellFee.liquidity = liquidity;
        require(reflection + liquidity + vault <= 30, "Must keep taxes below 30%");
    }

    function setBuyFee(
        uint8 reflection,
        uint8 liquidity,
        uint8 vault
    ) public onlyOwner {
        buyFee.reflection = reflection;
        buyFee.vault = vault;
        buyFee.liquidity = liquidity;
        require(reflection + liquidity + vault <= 20, "Must keep taxes below 20%");
    }

    function setBothFees(
        uint8 buy_reflection,
        uint8 buy_liquidity,
        uint8 buy_vault,
        uint8 sell_reflection,
        uint8 sell_liquidity,
        uint8 sell_vault
    ) public onlyOwner {
        buyFee.reflection = buy_reflection;
        buyFee.vault = buy_vault;
        buyFee.liquidity = buy_liquidity;
        require(buy_reflection + buy_vault + buy_liquidity <= 20, "Must buy keep taxes below 20%");

        sellFee.reflection = sell_reflection;
        sellFee.vault = sell_vault;
        sellFee.liquidity = sell_liquidity;
        require(sell_reflection + sell_vault + sell_liquidity <= 30, "Must sell keep taxes below 30%");
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokens) public onlyOwner {
        numTokensSellToAddToLiquidity = numTokens;
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        require(maxTxPercent > 0, "Percent must be above 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**3);
    }

    function _setMaxWalletSizePercent(uint256 maxWalletSize)
        external
        onlyOwner
    {
        require(maxWalletSize > 0, "Percent must be above 0");
        _maxWalletSize = _tTotal.mul(maxWalletSize).div(10**3);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    receive() external payable {}
    fallback() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tWallet = calculatevaultFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tWallet);

        return (tTransferAmount, tFee, tLiquidity, tWallet);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tWallet,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rWallet = tWallet.mul(currentRate);
        uint256 rTransferAmount = rAmount
            .sub(rFee)
            .sub(rLiquidity)
            .sub(rWallet);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (
                _rOwned[_excludedFromRewards[i]] > rSupply ||
                _tOwned[_excludedFromRewards[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromRewards[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromRewards[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromRewards[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeWalletFee(uint256 tWallet) private {
        uint256 currentRate = _getRate();
        uint256 rWallet = tWallet.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rWallet);
        if (_isExcludedFromRewards[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tWallet);
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculatevaultFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_vaultFee).div(10**2);
    }

   
    function removeAllFee() private {
        _reflectionFee = 0;
        _liquidityFee = 0;
        _vaultFee = 0;
     
    }

    function setBuy() private {
        _reflectionFee = buyFee.reflection;
        _liquidityFee = buyFee.liquidity;
        _vaultFee = buyFee.vault;
      
    }

    function setSell() private {
        _reflectionFee = sellFee.reflection;
        _liquidityFee = sellFee.liquidity;
        _vaultFee = sellFee.vault;
      
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromLimit(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if ( from != owner() && to != owner() ) require(tradingOpen, "Trading not yet enabled.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
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

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if (takeFee) {
            if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
                if (to != uniswapV2Pair) {
                    require(
                        amount + balanceOf(to) <= _maxWalletSize,
                        "Recipient exceeds max wallet size."
                    );
                }

              
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator = (buyFee.liquidity + sellFee.liquidity + buyFee.vault + sellFee.vault) * 2;
        uint256 tokensToAddLiquidityWith = (tokens * (buyFee.liquidity + sellFee.liquidity)) / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - (buyFee.liquidity + sellFee.liquidity));
        uint256 ethToAddLiquidityWith = unitBalance * (buyFee.liquidity + sellFee.liquidity);

        if (ethToAddLiquidityWith > 0) {
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        uint256 vaultAmt = unitBalance * 2 * (buyFee.vault + sellFee.vault);
       

        if (vaultAmt > 0) {
            payable(_vaultAddress).transfer(vaultAmt);
        }

    
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _vaultAddress.transfer(amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            removeAllFee();
            if (sender == uniswapV2Pair) {
                setBuy();
            }
            if (recipient == uniswapV2Pair) {
                setSell();
            }
        }

        if (_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        removeAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeWalletFee(tWallet);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeWalletFee(tWallet);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeWalletFee(tWallet);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tWallet
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tWallet,
            _getRate()
        );

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeWalletFee(tWallet);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function openTrading() public onlyOwner {
        require(!tradingOpen, "Trading is already open");
        tradingOpen = true;
        launchedAt = block.number;
    }
    
    function unclog() external {
        require(msg.sender == _vaultAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    function distributeFees() external {
        require(msg.sender == _vaultAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function rescueStuckETH() external {
        require(msg.sender == _vaultAddress);
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function rescueStuckTokens(address tkn) external {
        require(msg.sender == _vaultAddress);
        require(tkn != address(this), "Cannot withdraw this token");
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }
}