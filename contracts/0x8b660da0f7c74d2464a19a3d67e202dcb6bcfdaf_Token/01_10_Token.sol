// SPDX-License-Identifier: MIT

/**
FreedomDAO

Website: https://www.freedom22.io/
Twitter: https://twitter.com/freedom22dao
Telegram: https://t.me/Freedom22Portal
*/

pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;
import './external/IDividendDistributor.sol';
import './external/DividendDistributor.sol';
import './external/Address.sol';
import './external/Ownable.sol';
import './external/IERC20.sol';
import './external/SafeMath.sol';
import './external/Uniswap.sol';
import './external/ReentrancyGuard.sol';

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string public name;
    string public symbol;
    uint8 public constant decimals = 9;

    uint256 private _previousReflectionFee;
    uint256 private _previousTaxFee;
    IUniswapV2Router02 private uniswapRouter;
    address public uniswapPair;
    bool private tradingEnabled = false;
    bool private canSwap = true;
    bool private inSwap = false;

    uint256 public maxTxAmount;
    uint256 public maxAccountAmount;
    bool public isLaunchProtectionMode = true;
    mapping(address => bool) internal bots;

    event MaxBuyAmountUpdated(uint256 _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint256 _multiplier);
    event FeeRateUpdated(uint256 _rate);

    IDividendDistributor public distributor;

    struct TokenProperties {
        uint256 supply;
        uint256 taxFee;
        uint256 reflectionFee;
        uint256 liquidityFee;
        uint256 dividendFee;
        uint256 devFee;
        uint256 treasuryFee;
        uint256 maxTxAmount;
        uint256 maxAccountAmount;
        address uniswapRouterAddress;
        address payable liquidityWalletAddress;
        address payable devWalletAddress;
        address payable treasuryWalletAddress;
    }

    TokenProperties public properties;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        TokenProperties memory _properties
    ) public {
        properties = _properties;
        _tTotal = properties.supply * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));
        name = _name;
        symbol = _symbol;

        _previousReflectionFee = properties.reflectionFee;
        _previousTaxFee = properties.taxFee;
        maxTxAmount = properties.maxTxAmount;
        maxAccountAmount = properties.maxAccountAmount;

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[properties.liquidityWalletAddress] = true;
        _isExcludedFromFee[properties.devWalletAddress] = true;
        _isExcludedFromFee[properties.treasuryWalletAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(properties.uniswapRouterAddress);
        uniswapRouter = _uniswapV2Router;
        _approve(address(this), address(uniswapRouter), _tTotal);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint256).max);

        distributor = new DividendDistributor();
        _isExcludedFromFee[address(distributor)] = true;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setShare(address _shareholder, uint256 _amount)
        external
        onlyOwner
    {
        distributor.setShare( _shareholder, _amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length && recipients.length < 256, 'Incorrect lengths');
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
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
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, 'Amount must be less than total reflections');
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function setCanSwap(bool onoff) external onlyOwner {
        canSwap = onoff;
    }

    function setTradingEnabled() external onlyOwner {
        tradingEnabled = true;
    }

    function removeAllFee() private {
        if (properties.reflectionFee == 0 && properties.taxFee == 0) return;
        _previousReflectionFee = properties.reflectionFee;
        _previousTaxFee = properties.taxFee;
        properties.reflectionFee = 0;
        properties.taxFee = 0;
    }

    function restoreAllFee() private {
        properties.reflectionFee = _previousReflectionFee;
        properties.taxFee = _previousTaxFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        if (!tradingEnabled) {
            require(
                _isExcludedFromFee[from] || _isExcludedFromFee[to] || _isExcludedFromFee[tx.origin],
                'Trading is not live yet'
            );
        }
        require(!bots[from] && !bots[tx.origin], 'Bot blacklisted');

        if (isLaunchProtectionMode && !inSwap) {
            require(
                _isExcludedFromFee[from] || _isExcludedFromFee[to] || amount <= maxTxAmount,
                'Max Transfer Limit Exceeds!'
            );
            require(
                _isExcludedFromFee[from] ||
                    _isExcludedFromFee[to] ||
                    to == uniswapPair ||
                    balanceOf(to) + amount <= maxAccountAmount,
                'Max Account Amount Exceeds!'
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (!inSwap && from != uniswapPair && tradingEnabled && canSwap) {
            if (contractTokenBalance > 0) {
                if (contractTokenBalance > balanceOf(uniswapPair).div(100)) {
                    swapTokensForEth(contractTokenBalance);
                }
            }
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (from != uniswapPair && to != uniswapPair) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

        if (takeFee && from == uniswapPair) properties.taxFee = _previousTaxFee;
        if (takeFee && to == uniswapPair) properties.reflectionFee = _previousReflectionFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        uint256 totalFees = properties.devFee + properties.liquidityFee + properties.treasuryFee + properties.dividendFee;

        properties.devWalletAddress.transfer(amount.div(totalFees).mul(properties.devFee));
        properties.liquidityWalletAddress.transfer(amount.div(totalFees).mul(properties.liquidityFee));
        properties.treasuryWalletAddress.transfer(amount.div(totalFees).mul(properties.treasuryFee));
        try distributor.deposit{value: amount.div(totalFees).mul(properties.dividendFee)}() {} catch {}
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tReflect
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);


        if (!_isExcludedFromFee[sender]) {
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        }
        if (!_isExcludedFromFee[recipient]) {
            try distributor.setShare(recipient, balanceOf(recipient)) {} catch {}
        }

        _takeTeam(tReflect);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflect) = _getTValues(
            tAmount,
            properties.reflectionFee,
            properties.taxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tReflect, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tReflect);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 reflectionFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(reflectionFee).div(100);
        uint256 tReflect = tAmount.mul(taxFee).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tReflect);
        return (tTransferAmount, tFee, tReflect);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tReflect,
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
        uint256 rTeam = tReflect.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tReflect) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tReflect.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function setLiquidityWallet(address payable _liquidityWalletAddress) external onlyOwner {
        properties.liquidityWalletAddress = _liquidityWalletAddress;
        _isExcludedFromFee[properties.liquidityWalletAddress] = true;
    }

    function setTreasuryWallet(address payable _treasuryWalletAddress) external onlyOwner {
        properties.treasuryWalletAddress = _treasuryWalletAddress;
        _isExcludedFromFee[properties.treasuryWalletAddress] = true;
    }

    function excludeFromFee(address payable ad) external onlyOwner {
        _isExcludedFromFee[ad] = true;
    }

    function includeToFee(address payable ad) external onlyOwner {
        _isExcludedFromFee[ad] = false;
    }

    function setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee <= 250, 'Team fee must be less than 25%');
        properties.taxFee = taxFee;
    }

    function setReflectionFee(uint256 reflect) external onlyOwner {
        require(reflect <= 25, 'Tax fee must be less than 25%');
        properties.reflectionFee = reflect;
    }

    function manualSwap() external {
        require(
            _msgSender() == properties.liquidityWalletAddress ||
                _msgSender() == properties.devWalletAddress ||
                _msgSender() == properties.treasuryWalletAddress,
            'Not authorized'
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(
            _msgSender() == properties.liquidityWalletAddress ||
                _msgSender() == properties.devWalletAddress ||
                _msgSender() == properties.treasuryWalletAddress,
            'Not authorized'
        );
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function endLaunchProtection() external onlyOwner {
        isLaunchProtectionMode = false;
    }

    function setMaxTxAmount(uint256 percentage) external onlyOwner {
        maxTxAmount = _tTotal.mul(percentage).div(100);
    }

    function setBot(address bot, bool value) external onlyOwner {
        bots[bot] = value;
    }

    function setBotBatch(address[] memory _bots, bool value) external onlyOwner {
        require(_bots.length < 256, 'Incorrect lengths');
        for (uint256 i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = value;
        }
    }
}