/**
 *Submitted for verification at BscScan.com on 2022-05-29
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./TokenLib.sol";

contract GatsbyInu is IGatsbyInu, Initializable, ContextUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    struct FeeTier {
        uint256 ecoSystemFee;
        uint256 liquidityFee;
        uint256 taxFee;
        uint256 ownerFee;
        uint256 burnFee;
        address ecoSystem;
        address owner;
    }

    struct FeeValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tEchoSystem;
        uint256 tLiquidity;
        uint256 tFee;
        uint256 tOwner;
        uint256 tBurn;
    }

    struct tFeeValues {
        uint256 tTransferAmount;
        uint256 tEchoSystem;
        uint256 tLiquidity;
        uint256 tFee;
        uint256 tOwner;
        uint256 tBurn;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => uint256) private _accountsTier;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private _maxFee;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    FeeTier public _defaultFees;
    FeeTier private _previousFees;
    FeeTier private _emptyFees;

    FeeTier[] private feeTiers;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public WBNB;
    address private migration;
    address private _initializerAccount;
    address public _burnAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    uint256 public _maxTxAmount;
    uint256 private numTokensSellToAddToLiquidity;

    bool private _upgraded;

    uint256 public numTokensToCollectBNB;
    uint256 public numOfBnbToSwapAndEvolve;

    bool inSwapAndEvolve;
    bool public swapAndEvolveEnabled;
    bool public isTakeFee;

    uint256 private _rTotalExcluded;
    uint256 private _tTotalExcluded;
    uint256 public totalDevFeeAmount;
    uint256 public totalMarketingFeeAmount;
    bool public unlockBuySell;
    mapping(address => bool) public whitelistBuySell;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);

    event SwapAndEvolveEnabledUpdated(bool enabled);
    event SwapAndEvolve(uint256 bnbSwapped, uint256 tokenReceived, uint256 bnbIntoLiquidity);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier checkTierIndex(uint256 _index) {
        require(feeTiers.length > _index, "Gatsby: Invalid tier index");
        _;
    }

    modifier preventBlacklisted(address _account, string memory errorMsg) {
        require(!_isBlacklisted[_account], errorMsg);
        _;
    }

    function initialize(
        address _router,
        address _dev,
        address _marketing
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Token_v2_init_unchained(_router, _dev, _marketing);
    }

    function __Token_v2_init_unchained(
        address _router,
        address _dev,
        address _marketing
    ) internal initializer {
        _name = "Gastby Inu";
        _symbol = "GATSBY";
        _decimals = 9;

        _tTotal = 100000000000000000 * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));
        _maxFee = 10000;

        swapAndLiquifyEnabled = true;

        _maxTxAmount = 100000000000000000 * 10**9;
        numTokensSellToAddToLiquidity = 5000000000000000 * 10**9;

        _burnAddress = 0x000000000000000000000000000000000000dEaD;
        _initializerAccount = _msgSender();

        _rOwned[_initializerAccount] = _rTotal;
        whitelistBuySell[msg.sender] = true;

        uniswapV2Router = IUniswapV2Router02(_router);
        WBNB = uniswapV2Router.WETH();
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WBNB);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burnAddress] = true;
        //        //
        __Token_tiers_init(_dev, _marketing);
        _transfer(_initializerAccount, _burnAddress, 50000000000000000 * 10**9);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function isNotLockBuySell(address _user) public view returns (bool){
        return whitelistBuySell[_user] || unlockBuySell;
    }

    function __Token_tiers_init(address _dev, address _marketing) private {
        _defaultFees = _addTier(300, 0, 500, 200, 0, _marketing, _dev);
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromTokenInTiers(
        uint256 tAmount,
        uint256 _tierIndex,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            FeeValues memory _values = _getValues(tAmount, _tierIndex);
            return _values.rAmount;
        } else {
            FeeValues memory _values = _getValues(tAmount, _tierIndex);
            return _values.rTransferAmount;
        }
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        return reflectionFromTokenInTiers(tAmount, 0, deductTransferFee);
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function setTakeFee(bool _isTakeFee) public onlyOwner {
        isTakeFee = _isTakeFee;
    }

    function setWhitelistBuySell(address _user, bool _wl) public onlyOwner {
        whitelistBuySell[_user] = _wl;
    }

    function setUnLockBuySell(bool value) public onlyOwner {
        unlockBuySell = value;
    }

    function excludeFromReward(address account) public onlyOwner {
        if (!_isExcluded[account] || account == address(0)) {
            return;
        }
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
            _tTotalExcluded = _tTotalExcluded.add(_tOwned[account]);
            _rTotalExcluded = _rTotalExcluded.add(_rOwned[account]);
        }

        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        //        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tTotalExcluded = _tTotalExcluded.sub(_tOwned[account]);
                _rTotalExcluded = _rTotalExcluded.sub(_rOwned[account]);
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function whitelistAddress(address _account, uint256 _tierIndex) public onlyOwner {
        require(_account != address(0), "Gatsby: Invalid address");
        _accountsTier[_account] = _tierIndex;
    }

    function excludeWhitelistedAddress(address _account) public onlyOwner {
        require(_account != address(0), "Gatsby: Invalid address");
        require(_accountsTier[_account] > 0, "Gatsby: Account is not in whitelist");
        _accountsTier[_account] = 0;
    }

    function accountTier(address _account) public view returns (FeeTier memory) {
        return feeTiers[_accountsTier[_account]];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return _accountsTier[_account] > 0;
    }

    function checkFees(FeeTier memory _tier) internal view returns (FeeTier memory) {
        uint256 _fees = _tier.ecoSystemFee.add(_tier.liquidityFee).add(_tier.taxFee).add(_tier.ownerFee).add(
            _tier.burnFee
        );
        require(_fees <= _maxFee, "Gatsby: Fees exceeded max limitation");

        return _tier;
    }

    function checkFeesChanged(
        FeeTier memory _tier,
        uint256 _oldFee,
        uint256 _newFee
    ) internal view {
        uint256 _fees = _tier
            .ecoSystemFee
            .add(_tier.liquidityFee)
            .add(_tier.taxFee)
            .add(_tier.ownerFee)
            .add(_tier.burnFee)
            .sub(_oldFee)
            .add(_newFee);

        require(_fees <= _maxFee, "Gatsby: Fees exceeded max limitation");
    }

    function setEcoSystemFeePercent(uint256 _tierIndex, uint256 _ecoSystemFee)
        external
        onlyOwner
        checkTierIndex(_tierIndex)
    {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.ecoSystemFee, _ecoSystemFee);
        feeTiers[_tierIndex].ecoSystemFee = _ecoSystemFee;
        if (_tierIndex == 0) {
            _defaultFees.ecoSystemFee = _ecoSystemFee;
        }
    }

    function setLiquidityFeePercent(uint256 _tierIndex, uint256 _liquidityFee)
        external
        onlyOwner
        checkTierIndex(_tierIndex)
    {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.liquidityFee, _liquidityFee);
        feeTiers[_tierIndex].liquidityFee = _liquidityFee;
        if (_tierIndex == 0) {
            _defaultFees.liquidityFee = _liquidityFee;
        }
    }

    function setTaxFeePercent(uint256 _tierIndex, uint256 _taxFee) external onlyOwner checkTierIndex(_tierIndex) {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.taxFee, _taxFee);
        feeTiers[_tierIndex].taxFee = _taxFee;
        if (_tierIndex == 0) {
            _defaultFees.taxFee = _taxFee;
        }
    }

    function setOwnerFeePercent(uint256 _tierIndex, uint256 _ownerFee) external onlyOwner checkTierIndex(_tierIndex) {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.ownerFee, _ownerFee);
        feeTiers[_tierIndex].ownerFee = _ownerFee;
        if (_tierIndex == 0) {
            _defaultFees.ownerFee = _ownerFee;
        }
    }

    function setBurnFeePercent(uint256 _tierIndex, uint256 _burnFee) external onlyOwner checkTierIndex(_tierIndex) {
        FeeTier memory tier = feeTiers[_tierIndex];
        checkFeesChanged(tier, tier.burnFee, _burnFee);
        feeTiers[_tierIndex].burnFee = _burnFee;
        if (_tierIndex == 0) {
            _defaultFees.burnFee = _burnFee;
        }
    }

    function setEcoSystemFeeAddress(uint256 _tierIndex, address _ecoSystem)
        external
        onlyOwner
        checkTierIndex(_tierIndex)
    {
        require(_ecoSystem != address(0), "Gatsby: Address Zero is not allowed");
        excludeFromReward(_ecoSystem);
        feeTiers[_tierIndex].ecoSystem = _ecoSystem;
        if (_tierIndex == 0) {
            _defaultFees.ecoSystem = _ecoSystem;
        }
    }

    function setOwnerFeeAddress(uint256 _tierIndex, address _owner) external onlyOwner checkTierIndex(_tierIndex) {
        require(_owner != address(0), "Gatsby: Address Zero is not allowed");
        excludeFromReward(_owner);
        feeTiers[_tierIndex].owner = _owner;
        if (_tierIndex == 0) {
            _defaultFees.owner = _owner;
        }
    }

    function addTier(
        uint256 _ecoSystemFee,
        uint256 _liquidityFee,
        uint256 _taxFee,
        uint256 _ownerFee,
        uint256 _burnFee,
        address _ecoSystem,
        address _owner
    ) public onlyOwner {
        _addTier(_ecoSystemFee, _liquidityFee, _taxFee, _ownerFee, _burnFee, _ecoSystem, _owner);
    }

    function _addTier(
        uint256 _ecoSystemFee,
        uint256 _liquidityFee,
        uint256 _taxFee,
        uint256 _ownerFee,
        uint256 _burnFee,
        address _ecoSystem,
        address _owner
    ) internal returns (FeeTier memory) {
        FeeTier memory _newTier = checkFees(
            FeeTier(_ecoSystemFee, _liquidityFee, _taxFee, _ownerFee, _burnFee, _ecoSystem, _owner)
        );
        excludeFromReward(_ecoSystem);
        excludeFromReward(_owner);
        excludeFromFee(_ecoSystem);
        excludeFromFee(_owner);
        feeTiers.push(_newTier);

        return _newTier;
    }

    function feeTier(uint256 _tierIndex) public view checkTierIndex(_tierIndex) returns (FeeTier memory) {
        return feeTiers[_tierIndex];
    }

    function blacklistAddress(address account) public onlyOwner {
        _isBlacklisted[account] = true;
        _accountsTier[account] = 0;
    }

    function unBlacklistAddress(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    function updateRouterAndPair(address _uniswapV2Router, address _uniswapV2Pair) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        uniswapV2Pair = _uniswapV2Pair;
        WBNB = uniswapV2Router.WETH();
    }

    function setDefaultSettings() external onlyOwner {
        swapAndLiquifyEnabled = false;
        swapAndEvolveEnabled = true;
    }

    function excludeAddressFromFeeAndReward(address _user) public onlyOwner {
        excludeFromReward(_user);
        excludeFromFee(_user);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**4);
    }

    function setSwapAndEvolveEnabled(bool _enabled) public onlyOwner {
        swapAndEvolveEnabled = _enabled;
        emit SwapAndEvolveEnabledUpdated(_enabled);
    }

    //to receive BNB from uniswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, uint256 _tierIndex) private view returns (FeeValues memory) {
        tFeeValues memory tValues = _getTValues(tAmount, _tierIndex);
        uint256 tTransferFee = tValues.tLiquidity.add(tValues.tEchoSystem).add(tValues.tOwner).add(tValues.tBurn);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tValues.tFee,
            tTransferFee,
            _getRate()
        );
        return
            FeeValues(
                rAmount,
                rTransferAmount,
                rFee,
                tValues.tTransferAmount,
                tValues.tEchoSystem,
                tValues.tLiquidity,
                tValues.tFee,
                tValues.tOwner,
                tValues.tBurn
            );
    }

    function _getTValues(uint256 tAmount, uint256 _tierIndex) private view returns (tFeeValues memory) {
        FeeTier memory tier = feeTiers[_tierIndex];
        tFeeValues memory tValues = tFeeValues(
            0,
            calculateFee(tAmount, tier.ecoSystemFee),
            calculateFee(tAmount, tier.liquidityFee),
            calculateFee(tAmount, tier.taxFee),
            calculateFee(tAmount, tier.ownerFee),
            calculateFee(tAmount, tier.burnFee)
        );

        tValues.tTransferAmount = tAmount
            .sub(tValues.tEchoSystem)
            .sub(tValues.tFee)
            .sub(tValues.tLiquidity)
            .sub(tValues.tOwner)
            .sub(tValues.tBurn);

        return tValues;
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTransferFee,
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
        uint256 rTransferFee = tTransferFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTransferFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        if (_rTotalExcluded > _rTotal || _tTotalExcluded > _tTotal) {
            return (_rTotal, _tTotal);
        }
        uint256 rSupply = _rTotal.sub(_rTotalExcluded);
        uint256 tSupply = _tTotal.sub(_tTotalExcluded);

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if (_fee == 0) return 0;
        return _amount.mul(_fee).div(10**4);
    }

    function removeAllFee() private {
        _previousFees = feeTiers[0];
        feeTiers[0] = _emptyFees;
    }

    function restoreAllFee() private {
        feeTiers[0] = _previousFees;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        private
        preventBlacklisted(_msgSender(), "Gatsby: Address is blacklisted")
        preventBlacklisted(from, "Gatsby: From address is blacklisted")
        preventBlacklisted(to, "Gatsby: To address is blacklisted")
    {
        require(isNotLockBuySell(from), "Gatsby: Lock");
        require(from != address(0), "BEP20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        //        // is the token balance of this contract address over the min number of
        //        // tokens that we need to initiate a swap + liquidity lock?
        //        // also, don't get caught in a circular liquidity event.
        //        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

//        bool overMinTokenBalance = contractTokenBalance >= numTokensToCollectBNB;
//        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndEvolveEnabled) {
//            contractTokenBalance = numTokensToCollectBNB;
//            collectBNB(contractTokenBalance);
//        }

        //indicates if fee should be deducted from transfer
        bool takeFee = isTakeFee;
        //
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 tierIndex = 0;

        if (takeFee) {
            tierIndex = _accountsTier[from];

            if (_msgSender() != from) {
                tierIndex = _accountsTier[_msgSender()];
            }
        }
        //
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, tierIndex, takeFee);
        //        if (lastMarketingFeeAmount != 0) {
        //            _takeFeeBNB(lastMarketingFeeAmount, feeTiers[tierIndex].ecoSystem);
        //        }
        //        if (lastDevFeeAmount != 0) {
        //            _takeFeeBNB(lastDevFeeAmount, feeTiers[tierIndex].owner);
        //        }
        if (from != uniswapV2Pair && to != uniswapV2Pair && swapAndEvolveEnabled) {
            _takeBNBFees();
        }
    }

    function _takeBNBFees() private {
        if (totalDevFeeAmount != 0) {
            _takeFeeBNB(totalDevFeeAmount, feeTiers[0].owner);
            totalDevFeeAmount = 0;
        }
        if (totalMarketingFeeAmount != 0) {
            _takeFeeBNB(totalMarketingFeeAmount, feeTiers[0].ecoSystem);
            totalMarketingFeeAmount = 0;
        }
    }

    function adminTakeBnbFee() public onlyOwner {
        _takeBNBFees();
    }

    function collectBNB(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForBnb(contractTokenBalance);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function _takeFeeBNB(uint256 tokenAmount, address _receiver) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            _receiver,
            block.timestamp
        );
    }

    function swapAndEvolve() public onlyOwner lockTheSwap {
        // split the contract balance into halves
        uint256 contractBnbBalance = address(this).balance;
        require(contractBnbBalance >= numOfBnbToSwapAndEvolve, "BNB balance is not reach for S&E Threshold");

        contractBnbBalance = numOfBnbToSwapAndEvolve;

        uint256 half = contractBnbBalance.div(2);
        uint256 otherHalf = contractBnbBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = IGatsbyInu(address(this)).balanceOf(msg.sender);
        // swap BNB for Tokens
        swapBnbForTokens(half);

        // how much BNB did we just swap into?
        uint256 newBalance = IGatsbyInu(address(this)).balanceOf(msg.sender);
        uint256 swapeedToken = newBalance.sub(initialBalance);

        _approve(msg.sender, address(this), swapeedToken);
        IGatsbyInu(address(this)).transferFrom(msg.sender, address(this), swapeedToken);
        // add liquidity to uniswap
        addLiquidity(swapeedToken, otherHalf);
        emit SwapAndEvolve(half, swapeedToken, otherHalf);
    }

    function swapBnbForTokens(uint256 bnbAmount) private {
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        _approve(owner(), address(uniswapV2Router), bnbAmount);
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(
            0, // accept any amount of Token
            path,
            owner(),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{ value: bnbAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tierIndex,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, tierIndex);
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, tierIndex);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, tierIndex);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, tierIndex);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 tierIndex
    ) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(_values.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(_values.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_values.rTransferAmount);

        if (_values.tTransferAmount > tAmount) {
            uint256 tmpAmount = _values.tTransferAmount - tAmount;
            _tTotalExcluded = _tTotalExcluded.add(tmpAmount);
        } else {
            uint256 tmpAmount = tAmount - _values.tTransferAmount;
            _tTotalExcluded = _tTotalExcluded.sub(tmpAmount);
        }

        if (_values.rTransferAmount > _values.rAmount) {
            uint256 tmpAmount = _values.rTransferAmount - _values.rAmount;
            _rTotalExcluded = _rTotalExcluded.add(tmpAmount);
        } else {
            uint256 tmpAmount = _values.rAmount - _values.rTransferAmount;
            _rTotalExcluded = _rTotalExcluded.sub(tmpAmount);
        }

        _takeFees(sender, _values, tierIndex);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 tierIndex
    ) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _rOwned[sender] = _rOwned[sender].sub(_values.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_values.rTransferAmount);
        _takeFees(sender, _values, tierIndex);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 tierIndex
    ) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _rOwned[sender] = _rOwned[sender].sub(_values.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(_values.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_values.rTransferAmount);

        _tTotalExcluded = _tTotalExcluded.add(_values.tTransferAmount);
        _rTotalExcluded = _rTotalExcluded.add(_values.rTransferAmount);

        _takeFees(sender, _values, tierIndex);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 tierIndex
    ) private {
        FeeValues memory _values = _getValues(tAmount, tierIndex);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(_values.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(_values.rTransferAmount);
        _tTotalExcluded = _tTotalExcluded.sub(tAmount);
        _rTotalExcluded = _rTotalExcluded.sub(_values.rAmount);

        _takeFees(sender, _values, tierIndex);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    function _takeFees(
        address sender,
        FeeValues memory values,
        uint256 tierIndex
    ) private {
        _takeFee(sender, values.tLiquidity, address(this));
        _takeFee(sender, values.tEchoSystem, address(this));
        _takeFee(sender, values.tOwner, address(this));
        _takeBurn(sender, values.tBurn);
        totalDevFeeAmount += values.tOwner;
        totalMarketingFeeAmount += values.tEchoSystem;
//        uint256 lastDevFeeAmount = values.tOwner;
//        uint256 lastMarketingFeeAmount = values.tEchoSystem;
//        if (lastMarketingFeeAmount != 0) {
//            _takeFeeBNB(lastMarketingFeeAmount, feeTiers[tierIndex].ecoSystem);
//        }
//        if (lastDevFeeAmount != 0) {
//            _takeFeeBNB(lastDevFeeAmount, feeTiers[tierIndex].owner);
//        }
    }

    function _takeFee(
        address sender,
        uint256 tAmount,
        address recipient
    ) private {
        if (recipient == address(0)) return;
        if (tAmount == 0) return;

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _tTotalExcluded = _tTotalExcluded.add(tAmount);
            _rTotalExcluded = _rTotalExcluded.add(rAmount);
        }

        emit Transfer(sender, recipient, tAmount);
    }

    function _takeBurn(address sender, uint256 _amount) private {
        if (_amount == 0) return;
        _tOwned[_burnAddress] = _tOwned[_burnAddress].add(_amount);
        if (_isExcluded[_burnAddress]) {
            _tTotalExcluded = _tTotalExcluded.add(_amount);
        }

        emit Transfer(sender, _burnAddress, _amount);
    }

    function feeTiersLength() public view returns (uint256) {
        return feeTiers.length;
    }

    function updateBurnAddress(address _newBurnAddress) external onlyOwner {
        _burnAddress = _newBurnAddress;
        excludeFromReward(_newBurnAddress);
    }

    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        IGatsbyInu(_token).transfer(msg.sender, _amount);
    }

    function setNumberOfTokenToCollectBNB(uint256 _numToken) public onlyOwner {
        numTokensToCollectBNB = _numToken;
    }

    function setNumOfBnbToSwapAndEvolve(uint256 _numBnb) public onlyOwner {
        numOfBnbToSwapAndEvolve = _numBnb;
    }

    function getContractBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function getBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBnb(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
}