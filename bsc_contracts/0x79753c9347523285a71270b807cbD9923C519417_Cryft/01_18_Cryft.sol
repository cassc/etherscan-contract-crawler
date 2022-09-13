// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./utils/LPSwapSupportUpgradeable.sol";
import "./utils/AntiLPSniperUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./interfaces/ICryftReflector.sol";

contract Cryft is IERC20MetadataUpgradeable, LPSwapSupportUpgradeable, AntiLPSniperUpgradeable {
    using SafeMathUpgradeable for uint256;

    event Burn(address indexed burnAddress, uint256 tokensBurnt);

    struct TokenTracker {
        uint256 liquidity;
        uint256 growth;
        uint256 marketing;
        uint256 buyback;
    }

    struct Fees {
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
        uint256 growth;
        uint256 burn;
        uint256 buyback;
        uint256 divisor;
    }

    Fees public buyFees;
    Fees public sellFees;
    Fees public transferFees;
    TokenTracker public tokenTracker;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromReward;
    mapping (address => bool) public _isExcludedFromTxLimit;

    uint256 private _rCurrentExcluded;
    uint256 private _tCurrentExcluded;

    uint256 private MAX;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string public override name;
    string public override symbol;
    uint256 private _decimals;
    uint256 public _maxTxAmount;

    address public marketingWallet;
    address public growthWallet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _routerAddress, address _tokenOwner, address _marketing, address _growth) initializer public virtual {
        __Cryft_init(_routerAddress, _tokenOwner, _marketing, _growth);
        transferOwnership(_tokenOwner);
    }

    function __Cryft_init(address _routerAddress, address _tokenOwner, address _marketing, address _growth) internal onlyInitializing {
        __LPSwapSupport_init(_tokenOwner);
        __Cryft_init_unchained(_routerAddress, _tokenOwner, _marketing, _growth);
    }

    function __Cryft_init_unchained(address _routerAddress, address _tokenOwner, address _marketing, address _growth) internal onlyInitializing {
        MAX = ~uint256(0);
        name = "Cryft";
        symbol = "CRYFT";
        _decimals = 18;

        updateRouterAndPair(_routerAddress);

        antiSniperEnabled = true;

        _tTotal = 1650 * 10**6 * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        _maxTxAmount = 3 * 10 ** 6 * 10 ** _decimals; // 3 mil

        marketingWallet = _marketing;
        growthWallet = _growth;

        minTokenSpendAmount = 500 * 10 ** 3 * 10 ** _decimals; // 500k

        _rOwned[_tokenOwner] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_tokenOwner] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[growthWallet] = true;
        _isExcludedFromFee[buybackEscrowAddress] = true;
        _isExcludedFromTxLimit[buybackEscrowAddress] = true;

        buyFees = Fees({
            reflection: 0,
            liquidity: 0,
            marketing: 2,
            growth: 2,
            burn: 0,
            buyback: 2,
            divisor: 100
        });

        sellFees = Fees({
            reflection: 0,
            liquidity: 0,
            marketing: 2,
            growth: 2,
            burn: 0,
            buyback: 2,
            divisor: 100
        });

        transferFees = Fees({
            reflection: 0,
            liquidity: 0,
            marketing: 0,
            growth: 0,
            burn: 0,
            buyback: 0,
            divisor: 100
        });

        emit Transfer(address(this), _tokenOwner, _tTotal);
        excludeFromReward(address(this), true);
        excludeFromReward(buybackEscrowAddress, true);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function decimals() external view override returns(uint8){
        return uint8(_decimals);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf(account);
    }

    function _balanceOf(address account) internal view override returns (uint256) {
        if(_isExcludedFromReward[account]){
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    receive() external payable {}

    function _reflectFee(uint256 tFee, uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    // Modification to drop list and add variables for less storage reads
    // Should offer gas savings over safemoon algorithm given appropriate, contextual use
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        uint256 rCurrentExcluded = _rCurrentExcluded;
        uint256 tCurrentExcluded = _tCurrentExcluded;

        if (rCurrentExcluded > rSupply || tCurrentExcluded > tSupply) return (rSupply, tSupply);

        if (rSupply.sub(rCurrentExcluded) < rSupply.div(tSupply)) {
            return (_rTotal, _tTotal);
        }
        return (rSupply.sub(rCurrentExcluded), tSupply.sub(tCurrentExcluded));
    }

    function excludeFromFee(address account, bool exclude) public onlyOwner {
        _isExcludedFromFee[account] = exclude;
    }

    function excludeFromMaxTxLimit(address account, bool exclude) public onlyOwner {
        _isExcludedFromTxLimit[account] = exclude;
    }

    function excludeFromReward(address account, bool shouldExclude) public onlyOwner {
        require(_isExcludedFromReward[account] != shouldExclude, "Account is already set to this value");
        if(shouldExclude){
            _excludeFromReward(account);
        } else {
            _includeInReward(account);
        }
    }

    function _excludeFromReward(address account) private {
        uint256 rOwned = _rOwned[account];

        if(rOwned > 0) {
            uint256 tOwned = tokenFromReflection(rOwned);
            _tOwned[account] = tOwned;

            _tCurrentExcluded = _tCurrentExcluded.add(tOwned);
            _rCurrentExcluded = _rCurrentExcluded.add(rOwned);
        }
        _isExcludedFromReward[account] = true;
    }

    function _includeInReward(address account) private {
        uint256 rOwned = _rOwned[account];
        uint256 tOwned = _tOwned[account];

        if(tOwned > 0) {
            _tCurrentExcluded = _tCurrentExcluded.sub(tOwned);
            _rCurrentExcluded = _rCurrentExcluded.sub(rOwned);

            _rOwned[account] = tOwned.mul(_getRate());
            _tOwned[account] = 0;
        }
        _isExcludedFromReward[account] = false;
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) internal {
        if(tLiquidity > 0) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            tokenTracker.liquidity = tokenTracker.liquidity.add(tLiquidity);
            if(_isExcludedFromReward[address(this)]){
                _receiverIsExcluded(address(this), tLiquidity, rLiquidity);
            }
        }
    }

    function _takeBuyback(uint256 tBuyback, uint256 rBuyback) internal {
        if(tBuyback > 0) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rBuyback);
            tokenTracker.buyback = tokenTracker.buyback.add(tBuyback);
            if(_isExcludedFromReward[address(this)]){
                _receiverIsExcluded(address(this), tBuyback, rBuyback);
            }
        }
    }

    function freeStuckTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this token, only external tokens");
        IBEP20(tokenAddress).transfer(_msgSender(), IBEP20(tokenAddress).balanceOf(address(this)));
    }

    function _takeWalletFees(uint256 tMarketing, uint256 rMarketing, uint256 tGrowth, uint256 rGrowth) private {
        if(tMarketing > 0){
            tokenTracker.marketing = tokenTracker.marketing.add(tMarketing);
        }
        if(tGrowth > 0){
            tokenTracker.growth = tokenTracker.growth.add(tGrowth);
        }

        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing).add(rGrowth);
        if(_isExcludedFromReward[address(this)]){
            _receiverIsExcluded(address(this), tMarketing.add(tGrowth), rMarketing.add(rGrowth));
        }
    }

    function _takeBurn(uint256 tBurn, uint256 rBurn) private {
        if(tBurn > 0){
            _rOwned[deadAddress] = _rOwned[deadAddress].add(rBurn);
            _receiverIsExcluded(deadAddress, tBurn, rBurn);
            emit Burn(deadAddress, tBurn);
            emit Transfer(address(this), deadAddress, tBurn);
        }
    }

    function _approve(address holder, address spender, uint256 amount) internal override {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    // This function was so large given the fee structure it had to be subdivided as solidity did not support
    // the possibility of containing so many local variables in a single execution.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(from == buybackEscrowAddress){
            require(to == address(this), "Escrow address can only transfer tokens to Cryft address");
        }

        uint256 rAmount;
        uint256 tTransferAmount;
        uint256 rTransferAmount;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner()) {
            require(!isBlackListed[to] && !isBlackListed[from], "Address is blacklisted");

            if(!tradingOpen && isLPPoolAddress[from] && antiSniperEnabled){
                banHammer(to);
                to = address(this);
                (rAmount, tTransferAmount, rTransferAmount) = valuesForNoFees(amount);
                _transferFull(from, to, amount, rAmount, tTransferAmount, rTransferAmount);
                tokenTracker.liquidity = tokenTracker.liquidity.add(amount);
                return;
            } else {
                require(tradingOpen, "Trading not open");
            }

            if(!_isExcludedFromTxLimit[from] && !_isExcludedFromTxLimit[to])
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            if(!inSwap && !isLPPoolAddress[from] && swapsEnabled) {
                selectSwapEvent();
            }
            if(isLPPoolAddress[from]){ // Buy
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(from, amount, buyFees, gasWalletFees.buyFee, rewardDistributionFees.buyFee, stakingFees.buyFee);
            } else if(isLPPoolAddress[to]){ // Sell
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(from, amount, sellFees, gasWalletFees.sellFee, rewardDistributionFees.sellFee, stakingFees.sellFee);
            } else {
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(from, amount, transferFees, gasWalletFees.transferFee, rewardDistributionFees.transferFee, stakingFees.transferFee);
            }

        } else {
            (rAmount, tTransferAmount, rTransferAmount) = valuesForNoFees(amount);
        }

        _transferFull(from, to, amount, rAmount, tTransferAmount, rTransferAmount);
        rewardsDistributor.setShares(from, balanceOf(from), to, balanceOf(to));

        if(!isLPPoolAddress[from] && !_isExcludedFromFee[from] && !isProcessExcluded[from])
            rewardsDistributor.process();
    }

    function valuesForNoFees(uint256 amount) private view returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        rAmount = amount.mul(_getRate());
        tTransferAmount = amount;
        rTransferAmount = rAmount;
    }

    function pushSwap() external {
        if(!inSwap && tradingOpen && (swapsEnabled || owner() == _msgSender()))
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        TokenTracker memory _tokenTracker = tokenTracker;

        if(buybackAndLiquifyEnabled && address(this).balance >= minSpendAmount){
            tokenTracker.buyback = _tokenTracker.buyback.add(buybackAndLiquify(address(this).balance)); // LP

        } else if(_tokenTracker.liquidity >= minTokenSpendAmount){
            uint256 contractTokenBalance = _tokenTracker.liquidity;
            swapAndLiquify(contractTokenBalance); // LP
            tokenTracker.liquidity = _tokenTracker.liquidity.sub(contractTokenBalance);

        } else if(_tokenTracker.marketing >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.marketing, address(marketingWallet));
            tokenTracker.marketing = _tokenTracker.marketing.sub(tokensSwapped);

        } else if(_tokenTracker.growth >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.growth, address(growthWallet));
            tokenTracker.growth = _tokenTracker.growth.sub(tokensSwapped);

        } else if(_tokenTracker.buyback >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.buyback, address(this));
            tokenTracker.buyback = _tokenTracker.buyback.sub(tokensSwapped);

        } else if(gasWalletFeeTracker >= minTokenSpendAmount) {
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), gasWalletFeeTracker, address(gasWallet));
            gasWalletFeeTracker = gasWalletFeeTracker.sub(tokensSwapped);

        } else if(rewardDistributorFeeTracker >= minTokenSpendAmount) {
            uint256 currentBalance = address(this).balance;
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), rewardDistributorFeeTracker, address(this));
            rewardDistributorFeeTracker = rewardDistributorFeeTracker.sub(tokensSwapped);
            rewardsDistributor.deposit{value: address(this).balance.sub(currentBalance)}();


        } else if(stakingFeeTracker >= minTokenSpendAmount) {
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), stakingFeeTracker, address(stakingWallet));
            stakingFeeTracker = stakingFeeTracker.sub(tokensSwapped);
        }

    }

    function _transferFull(address sender, address recipient, uint256 amount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if(_isExcludedFromReward[sender]){
            _senderIsExcluded(sender, amount, rAmount);
        }


        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if(_isExcludedFromReward[recipient]){
            _receiverIsExcluded(recipient, tTransferAmount, rTransferAmount);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _senderIsExcluded(address sender, uint256 tAmount, uint256 rAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tCurrentExcluded = _tCurrentExcluded.sub(tAmount);
        _rCurrentExcluded = _rCurrentExcluded.sub(rAmount);
    }

    function _receiverIsExcluded(address receiver, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[receiver] = _tOwned[receiver].add(tTransferAmount);
        _tCurrentExcluded = _tCurrentExcluded.add(tTransferAmount);
        _rCurrentExcluded = _rCurrentExcluded.add(rTransferAmount);
    }

    function updateBuyFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        buyFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateSellFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        sellFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateTransferFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        transferFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function updateGrowthWallet(address _growthWallet) external onlyOwner {
        growthWallet = _growthWallet;
    }

    function updateMaxTxSize(uint256 maxTransactionAllowed) external onlyOwner {
        _maxTxAmount = maxTransactionAllowed.mul(10 ** _decimals);
    }

    function openTrading() external override onlyOwner {
        require(!tradingOpen, "Trading already enabled");
        tradingOpen = true;
        swapsEnabled = true;
    }

    function pauseTrading() external virtual onlyOwner {
        require(tradingOpen, "Trading already closed");
        tradingOpen = !tradingOpen;
    }

    function updateLPPoolList(address newAddress, bool _isPoolAddress) public virtual override onlyOwner {
        if(isLPPoolAddress[newAddress] != _isPoolAddress) {
            excludeFromReward(newAddress, _isPoolAddress);
            isLPPoolAddress[newAddress] = _isPoolAddress;
            rewardsDistributor.excludeFromReward(newAddress, _isPoolAddress);
        }
    }

    function batchAirdrop(address[] memory airdropAddresses, uint256[] memory airdropAmounts) external {

        require(airdropAddresses.length == airdropAmounts.length, "Addresses and amounts must have equal quantities of entries");
        if(!inSwap)
            if(_isExcludedFromFee[_msgSender()] || _msgSender() == owner()){
                _batchAirdrop(airdropAddresses, airdropAmounts);
            } else {
                require(!isBlackListed[_msgSender()] && tradingOpen, "Sender is not permitted to transfer at this time");
                _batchTransfer(airdropAddresses, airdropAmounts);
            }
    }

    // @dev For owner or excluded airdrops, recipients shares are not immediately eligible for external dividends
    // due to gas overheads in automation.
    function _batchAirdrop(address[] memory _addresses, uint256[] memory _amounts) private lockTheSwap {
        uint256 senderRBal = _rOwned[_msgSender()];
        uint256 currentRate = _getRate();
        uint256 tTotalSent;
        uint256 arraySize = _addresses.length;
        uint256 sendAmount;
        uint256 _decimalModifier = 10 ** uint256(_decimals);

        for(uint256 i = 0; i < arraySize; i++){
            sendAmount = _amounts[i].mul(_decimalModifier);
            tTotalSent = tTotalSent.add(sendAmount);
            _rOwned[_addresses[i]] = _rOwned[_addresses[i]].add(sendAmount.mul(currentRate));

            if(_isExcludedFromReward[_addresses[i]]){
                _receiverIsExcluded(_addresses[i], sendAmount, sendAmount.mul(currentRate));
            }

            emit Transfer(_msgSender(), _addresses[i], sendAmount);
        }
        uint256 rTotalSent = tTotalSent.mul(currentRate);
        if(senderRBal < rTotalSent)
            revert("Insufficient balance from airdrop instigator");
        _rOwned[_msgSender()] = senderRBal.sub(rTotalSent);

        rewardsDistributor.setShare(_msgSender(), balanceOf(_msgSender()));

        if(_isExcludedFromReward[_msgSender()]){
            _senderIsExcluded(_msgSender(), tTotalSent, rTotalSent);
        }
    }

    function _batchTransfer(address[] memory _addresses, uint256[] memory _amounts) private lockTheSwap {
        uint256 senderRBal = _rOwned[_msgSender()];
        uint256 currentRate = _getRate();
        uint256 tTotalSent;
        uint256 arraySize = _addresses.length;
        uint256 tTransferAmount;
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 _decimalModifier = 10 ** uint256(_decimals);

        for(uint256 i = 0; i < arraySize; i++){
            require(!isBlackListed[_addresses[i]]);
            if(!_isExcludedFromTxLimit[_msgSender()])
                require(_amounts[i] <= _maxTxAmount, "Transaction too large");

            (rAmount, tTransferAmount, rTransferAmount) = takeFees(_addresses[i], _amounts[i], transferFees, gasWalletFees.transferFee, rewardDistributionFees.transferFee, stakingFees.transferFee);
            tTransferAmount = _amounts[i].mul(_decimalModifier);
            tTotalSent = tTotalSent.add(tTransferAmount);
            _rOwned[_addresses[i]] = _rOwned[_addresses[i]].add(tTransferAmount.mul(currentRate));

            if(_isExcludedFromReward[_addresses[i]]){
                _receiverIsExcluded(_addresses[i], tTransferAmount, rAmount);
            }

            rewardsDistributor.setShare(_addresses[i], balanceOf(_addresses[i]));
            emit Transfer(_msgSender(), _addresses[i], tTransferAmount);
        }
        uint256 rTotalSent = tTotalSent.mul(currentRate);
        if(senderRBal < rTotalSent)
            revert("Insufficient balance from airdrop instigator");
        _rOwned[_msgSender()] = senderRBal.sub(rTotalSent);

        if(_isExcludedFromReward[_msgSender()]){
            _senderIsExcluded(_msgSender(), tTotalSent, rTotalSent);
        }

        rewardsDistributor.setShare(_msgSender(), balanceOf(_msgSender()));

        if(!isProcessExcluded[_msgSender()])
            try rewardsDistributor.process() {} catch {}
    }

    // @dev Version 2

    struct AdditionalFees {
        uint256 transferFee;
        uint256 buyFee;
        uint256 sellFee;
    }

    struct FeesExtended {
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
        uint256 growth;
        uint256 burn;
        uint256 buyback;
        uint256 gas;
        uint256 distributor;
        uint256 staking;
        uint256 divisor;
    }

    mapping(address => bool) isProcessExcluded;

    ICryftReflector public rewardsDistributor;
    address public gasWallet;
    address public stakingWallet;

    AdditionalFees public gasWalletFees;
    AdditionalFees public rewardDistributionFees;
    AdditionalFees public stakingFees;

    uint256 public gasWalletFeeTracker;
    uint256 public rewardDistributorFeeTracker;
    uint256 public stakingFeeTracker;

    function updateDistributorAddress(address _newDistributorAddress) external onlyOwner {
        rewardsDistributor = ICryftReflector(_newDistributorAddress);
    }

    function updateGasAndStakingWalletAddress(address _newGasWalletAddress, address _newStakingWalletAddress) external onlyOwner {
        gasWallet = _newGasWalletAddress;
        stakingWallet = _newStakingWalletAddress;
    }

    function updateExtendedFees(uint256 _gasTransferFee, uint256 _gasBuyFee, uint256 _gasSellFee,
                            uint256 _stakingTransferFee, uint256 _stakingBuyFee, uint256 _stakingSellFee,
                            uint256 _rewardDistributorTransferFee, uint256 _rewardDistributorBuyFee, uint256 _rewardDistributorSellFee) external onlyOwner {
        gasWalletFees.transferFee = _gasTransferFee;
        gasWalletFees.buyFee = _gasBuyFee;
        gasWalletFees.sellFee = _gasSellFee;

        stakingFees.transferFee = _stakingTransferFee;
        stakingFees.buyFee = _stakingBuyFee;
        stakingFees.sellFee = _stakingSellFee;

        rewardDistributionFees.transferFee = _rewardDistributorTransferFee;
        rewardDistributionFees.buyFee = _rewardDistributorBuyFee;
        rewardDistributionFees.sellFee = _rewardDistributorSellFee;
    }

    function takeFees(address from, uint256 amount, Fees memory _fees, uint256 _gasFee, uint256 _distributorFee, uint256 _stakingFee) private returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        FeesExtended memory tFees = FeesExtended({
            reflection: amount.mul(_fees.reflection).div(_fees.divisor),
            liquidity: amount.mul(_fees.liquidity).div(_fees.divisor),
            marketing: amount.mul(_fees.marketing).div(_fees.divisor),
            growth: amount.mul(_fees.growth).div(_fees.divisor),
            burn: amount.mul(_fees.burn).div(_fees.divisor),
            buyback: amount.mul(_fees.buyback).div(_fees.divisor),
            gas: amount.mul(_gasFee).div(_fees.divisor),
            distributor: amount.mul(_distributorFee).div(_fees.divisor),
            staking: amount.mul(_stakingFee).div(_fees.divisor),
            divisor: 0
        });

        FeesExtended memory rFees;
        (rFees, rAmount) = _getRValues(amount, tFees);

        _takeWalletFees(tFees.marketing, rFees.marketing, tFees.growth, rFees.growth);
        _takeBurn(tFees.burn, rFees.burn);
        _takeLiquidity(tFees.liquidity, rFees.liquidity);
        _takeBuyback(tFees.buyback, rFees.buyback);
        _takeGasFees(tFees.gas, rFees.gas);
        _takeDistributorFees(tFees.distributor, rFees.distributor);
        _takeStakingFees(tFees.staking, rFees.staking);

        tTransferAmount = amount.sub(tFees.growth).sub(tFees.liquidity).sub(tFees.marketing);
        tTransferAmount = tTransferAmount.sub(tFees.buyback).sub(tFees.burn);
        tTransferAmount = tTransferAmount.sub(tFees.gas).sub(tFees.distributor);
        tTransferAmount = tTransferAmount.sub(tFees.staking);

        if(amount != tTransferAmount){
            emit Transfer(from, address(this), amount.sub(tTransferAmount));
        }

        tTransferAmount = tTransferAmount.sub(tFees.reflection);

        rTransferAmount = rAmount.sub(rFees.reflection).sub(rFees.liquidity).sub(rFees.marketing);
        rTransferAmount = rTransferAmount.sub(rFees.growth).sub(rFees.burn);
        rTransferAmount = rTransferAmount.sub(rFees.buyback);
        rTransferAmount = rTransferAmount.sub(rFees.gas);
        rTransferAmount = rTransferAmount.sub(rFees.distributor);
        rTransferAmount = rTransferAmount.sub(rFees.staking);

        _reflectFee(tFees.reflection, rFees.reflection);

        return (rAmount, tTransferAmount, rTransferAmount);
    }

    function _getRValues(uint256 tAmount, FeesExtended memory tFees) private view returns(FeesExtended memory rFees, uint256 rAmount) {
        uint256 currentRate = _getRate();

        rFees = FeesExtended({
            reflection: tFees.reflection.mul(currentRate),
            liquidity: tFees.liquidity.mul(currentRate),
            marketing: tFees.marketing.mul(currentRate),
            growth: tFees.growth.mul(currentRate),
            burn: tFees.burn.mul(currentRate),
            buyback: tFees.buyback.mul(currentRate),
            gas: tFees.burn.mul(currentRate),
            distributor: tFees.buyback.mul(currentRate),
            staking: tFees.staking.mul(currentRate),
            divisor: 0
        });

        rAmount = tAmount.mul(currentRate);
    }

    function _takeGasFees(uint256 tGas, uint256 rGas) private {
        gasWalletFeeTracker = gasWalletFeeTracker.add(tGas);


        _rOwned[address(this)] = _rOwned[address(this)].add(rGas);
        if(_isExcludedFromReward[address(this)]){
            _receiverIsExcluded(address(this), tGas, rGas);
        }
    }

    function _takeStakingFees(uint256 tStaking, uint256 rStaking) private {
        stakingFeeTracker = stakingFeeTracker.add(tStaking);

        _rOwned[address(this)] = _rOwned[address(this)].add(rStaking);
        if(_isExcludedFromReward[address(this)]){
            _receiverIsExcluded(address(this), tStaking, rStaking);
        }
    }

    function _takeDistributorFees(uint256 tDistributor, uint256 rDistributor) private {
        rewardDistributorFeeTracker = rewardDistributorFeeTracker.add(tDistributor);

        _rOwned[address(this)] = _rOwned[address(this)].add(rDistributor);
        if(_isExcludedFromReward[address(this)]){
            _receiverIsExcluded(address(this), tDistributor, rDistributor);
        }
    }

    function isEnrolledForDistributor(address _user) external view returns(bool) {
        return rewardsDistributor.isEnrolled(_user);
    }

    function enrollInDistributions(address _user) external {
        rewardsDistributor.enroll(_user);
    }

    function excludeFromProcessingReflections(address _user, bool _shouldExclude) external onlyOwner {
        isProcessExcluded[_user] = _shouldExclude;
    }

}