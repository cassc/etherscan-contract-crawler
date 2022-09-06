// SPDX-License-Identifier: MIT

/**
<name>

Website: https://flube.io
Twitter: https://twitter.com/Flubecoin
Telegram: https://t.me/FlubeEth
*/

pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;
import './external/Address.sol';
import './external/Ownable.sol';
import './external/IERC20.sol';
import './external/SafeMath.sol';
import './external/Uniswap.sol';
import './external/ReentrancyGuard.sol';
import './external/IBotChecker.sol';

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
    bool private inSwap = false;

    uint256 public maxTxAmount;
    uint256 public maxAccountAmount;
    uint256 public cooldown;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) internal bots;

    IBotChecker private antibotChecker;
    bool public enhancedBotCheck = false;

    struct TokenProperties {
        uint256 supply;
        uint256 taxFee;
        uint256 reflectionFee;
        uint256 marketingFee;
        uint256 devFee;
        uint256 treasuryFee;
        uint256 maxTxAmount;
        uint256 maxAccountAmount;
        uint256 cooldown;
        address uniswapRouterAddress;
        address payable marketingWalletAddress;
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
        TokenProperties memory _properties,
        address _antibotChecker
    ) public {
        antibotChecker = IBotChecker(_antibotChecker);
        if (_antibotChecker != address(0)) {
            enhancedBotCheck = true;
        }

        properties = _properties;
        _tTotal = properties.supply * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));
        name = _name;
        symbol = _symbol;

        _previousReflectionFee = properties.reflectionFee;
        _previousTaxFee = properties.taxFee;
        maxTxAmount = properties.maxTxAmount;
        maxAccountAmount = properties.maxAccountAmount;
        cooldown = properties.cooldown;

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[properties.marketingWalletAddress] = true;
        _isExcludedFromFee[properties.devWalletAddress] = true;
        _isExcludedFromFee[properties.treasuryWalletAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(properties.uniswapRouterAddress);
        uniswapRouter = _uniswapV2Router;
        _approve(address(this), address(uniswapRouter), _tTotal);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint256).max);
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

        if (!inSwap) {
            if (enhancedBotCheck && address(antibotChecker) != address(0) && from == uniswapPair) {
                antibotChecker.checkBots(from, to, amount);
            }

            if (maxTxAmount != 0) {
                require(
                    _isExcludedFromFee[from] || _isExcludedFromFee[to] || amount <= maxTxAmount,
                    'Max Transfer Limit Exceeds!'
                );
            }

            if (maxAccountAmount != 0) {
                require(
                    _isExcludedFromFee[from] ||
                        _isExcludedFromFee[to] ||
                        to == uniswapPair ||
                        balanceOf(to) + amount <= maxAccountAmount,
                    'Max Account Amount Exceeds!'
                );
            }

            if (cooldown != 0) {
                require(
                    to == uniswapPair || _holderLastTransferTimestamp[to] < block.timestamp - cooldown,
                    'Cooldown timer hit!'
                );
                _holderLastTransferTimestamp[to] = block.timestamp;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (!inSwap && from != uniswapPair && tradingEnabled) {
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

        if (from == uniswapPair) {
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
        uint256 totalFees = properties.devFee + properties.marketingFee + properties.treasuryFee;

        properties.devWalletAddress.transfer(amount.div(totalFees).mul(properties.devFee));
        properties.marketingWalletAddress.transfer(amount.div(totalFees).mul(properties.marketingFee));
        properties.treasuryWalletAddress.transfer(amount.div(totalFees).mul(properties.treasuryFee));
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
        uint256 tReflect = tAmount.mul(taxFee).div(10000);
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

    function setMarketingWallet(address payable _marketingWalletAddress) external onlyOwner {
        properties.marketingWalletAddress = _marketingWalletAddress;
        _isExcludedFromFee[properties.marketingWalletAddress] = true;
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
        require(taxFee <= 2500, 'Team fee must be less than 25%');
        properties.taxFee = taxFee;
    }

    function setReflectionFee(uint256 reflect) external onlyOwner {
        require(reflect <= 25, 'Reflection fee must be less than 25%');
        properties.reflectionFee = reflect;
    }

    function manualSwap() external {
        require(
            _msgSender() == properties.marketingWalletAddress ||
                _msgSender() == properties.devWalletAddress ||
                _msgSender() == properties.treasuryWalletAddress,
            'Not authorized'
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(
            _msgSender() == properties.marketingWalletAddress ||
                _msgSender() == properties.devWalletAddress ||
                _msgSender() == properties.treasuryWalletAddress,
            'Not authorized'
        );
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function setMaxAccountAmount(uint256 _maxAccountAmount) external onlyOwner {
        maxAccountAmount = _maxAccountAmount;
    }

    function setBotCheck(bool _enhancedBotCheck) external onlyOwner {
        enhancedBotCheck = _enhancedBotCheck;
    }

    function setCooldown(uint256 _cooldown) external onlyOwner {
        cooldown = _cooldown;
    }

    function setLaunchAmounts(
        uint256 _maxTxAmount,
        uint256 _maxAccountAmount,
        uint256 _cooldown
    ) external onlyOwner {
        maxTxAmount = _maxTxAmount;
        maxAccountAmount = _maxAccountAmount;
        cooldown = _cooldown;
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