pragma solidity ^0.6.12;

import "./libraries/ReflectToken.sol";
import "./libraries/Percent.sol";
import "./libraries/Set.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILedgity.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/ILedgityPriceOracle.sol";

// SPDX-License-Identifier: Unlicensed
contract Ledgity is ILedgity, ReflectToken {
    using SafeMath for uint256;
    using Percent for Percent.Percent;
    using Set for Set.AddressSet;

    uint256 public constant initialTotalSupply = 2760000000 * 10**18;

    uint256 public numTokensToSwap;
    bool public inSwapAndLiquify;
    enum FeeDestination {
        Liquify,
        Collect
    }
    FeeDestination public feeDestination = FeeDestination.Liquify;
    Percent.Percent public sellAccumulationFee = Percent.encode(6, 100);
    Percent.Percent public initialSellAccumulationFee = sellAccumulationFee;
    Percent.Percent public sellAtSmallPriceAccumulationFee = Percent.encode(6 + 15, 100);
    Percent.Percent public initialSellAtSmallPriceAccumulationFee = sellAtSmallPriceAccumulationFee;
    Percent.Percent public sellReflectionFee = Percent.encode(4, 100);
    Percent.Percent public initialSellReflectionFee = sellReflectionFee;
    Percent.Percent public buyAccumulationFee = Percent.encode(4, 100);
    Percent.Percent public initialBuyAccumulationFee = buyAccumulationFee;
    Set.AddressSet private _dexes;
    Set.AddressSet private _excludedFromDexFee;

    Set.AddressSet private _excludedFromLimits;
    mapping(address => uint256) public soldPerPeriod;
    mapping(address => uint256) public firstSellAt;
    Percent.Percent public maxTransactionSizePercent = Percent.encode(5, 10000);

    IUniswapV2Pair public uniswapV2Pair;
    IReserve public reserve;
    ILedgityPriceOracle public priceOracle;
    uint256 public initialPrice;

    constructor() public ReflectToken("Ledgity", "LTY", initialTotalSupply) {
        numTokensToSwap = totalSupply().mul(15).div(10000);
        setIsExcludedFromDexFee(owner(), true);
        setIsExcludedFromDexFee(address(this), true);
        setIsExcludedFromLimits(owner(), true);
        setIsExcludedFromLimits(address(this), true);
        excludeAccount(address(this));
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function initializeReserve(address reserveAddress) external onlyOwner {
        reserve = IReserve(reserveAddress);
        setIsExcludedFromDexFee(address(reserve), true);
        setIsExcludedFromLimits(address(reserve), true);
        excludeAccount(address(reserve));
        uniswapV2Pair = reserve.uniswapV2Pair();
        setDex(address(uniswapV2Pair), true);
    }

    function initializePriceOracle(address priceOracleAddress) external onlyOwner {
        priceOracle = ILedgityPriceOracle(priceOracleAddress);
        if (initialPrice == 0) {
            initialPrice = _getPrice();
        }
    }

    function totalBurn() external view returns (uint256) {
        return initialTotalSupply - totalSupply();
    }

    function setDex(address target, bool dex) public onlyOwner {
        if (dex) {
            _dexes.add(target);
            if (!isExcluded(target)) {
                excludeAccount(target);
            }
        } else {
            _dexes.remove(target);
            if (isExcluded(target)) {
                includeAccount(target);
            }
        }
    }

    function setFeeDestination(FeeDestination fd) public onlyOwner {
        feeDestination = fd;
    }

    function setIsExcludedFromDexFee(address account, bool isExcluded) public onlyOwner {
        if (isExcluded) {
            _excludedFromDexFee.add(account);
        } else {
            _excludedFromDexFee.remove(account);
        }
    }

    function setIsExcludedFromLimits(address account, bool isExcluded) public onlyOwner {
        if (isExcluded) {
            _excludedFromLimits.add(account);
        } else {
            _excludedFromLimits.remove(account);
        }
    }

    function setNumTokensToSwap(uint256 _numTokensToSwap) external onlyOwner {
        numTokensToSwap = _numTokensToSwap;
    }

    function setMaxTransactionSizePercent(uint128 numerator, uint128 denominator) external onlyOwner {
        maxTransactionSizePercent = Percent.encode(numerator, denominator);
    }

    function setSellAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellAccumulationFee = Percent.encode(numerator, denominator);
        require(sellAccumulationFee.lte(initialSellAccumulationFee), "Ledgity: fee too high");
    }

    function setSellAtSmallPriceAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellAtSmallPriceAccumulationFee = Percent.encode(numerator, denominator);
        require(sellAtSmallPriceAccumulationFee.lte(initialSellAtSmallPriceAccumulationFee), "Ledgity: fee too high");
    }

    function setSellReflectionFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellReflectionFee = Percent.encode(numerator, denominator);
        require(sellReflectionFee.lte(initialSellReflectionFee), "Ledgity: fee too high");
    }

    function setBuyAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        buyAccumulationFee = Percent.encode(numerator, denominator);
        require(buyAccumulationFee.lte(initialBuyAccumulationFee), "Ledgity: fee too high");
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function getDexes() external view returns (address[] memory) {
        return _dexes.values;
    }

    function getExcludedFromDexFee() external view returns (address[] memory) {
        return _excludedFromDexFee.values;
    }

    function getExcludedFromLimits() external view returns (address[] memory) {
        return _excludedFromLimits.values;
    }

    function isDex(address account) public view returns (bool) {
        return _dexes.has(account);
    }

    function isExcludedFromDexFee(address account) public view returns (bool) {
        return _excludedFromDexFee.has(account);
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _excludedFromLimits.has(account);
    }

    function _calculateReflectionFee(address sender, address recipient, uint256 amount) internal override view returns (uint256) {
        if (isDex(recipient) && !isExcludedFromDexFee(sender)) {
            return sellReflectionFee.mul(amount);
        }
        return 0;
    }

    function _calculateAccumulationFee(address sender, address recipient, uint256 amount) internal override view returns (uint256) {
        if (isDex(sender) && !isExcludedFromDexFee(recipient)) {
            return buyAccumulationFee.mul(amount);
        }
        if (isDex(recipient) && !isExcludedFromDexFee(sender)) {
            if (_getPrice() >= initialPrice.mul(10)) {
                return sellAccumulationFee.mul(amount);
            } else {
                return sellAtSmallPriceAccumulationFee.mul(amount);
            }
        }
        return 0;
    }

    function _swapAndLiquifyOrCollect(uint256 contractTokenBalance) private lockTheSwap {
        _transfer(address(this), address(reserve), contractTokenBalance);
        if (feeDestination == FeeDestination.Liquify) {
            reserve.swapAndLiquify(contractTokenBalance);
        } else if (feeDestination == FeeDestination.Collect) {
            reserve.swapAndCollect(contractTokenBalance);
        } else {
            revert("Ledgity: invalid feeDestination");
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!isExcludedFromLimits(sender) && isDex(recipient)) {
            uint256 _sold;
            if (block.timestamp.sub(firstSellAt[sender]) > 10 minutes) {
                // _sold = 0;  // is already 0
                firstSellAt[sender] = block.timestamp;
            } else {
                _sold = soldPerPeriod[sender];
            }
            _sold = _sold.add(amount);
            require(_sold <= maxTransactionSize());
            soldPerPeriod[sender] = _sold;
        }

        if (address(priceOracle) != address(0)) {
            priceOracle.tryUpdate();
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 _numTokensToSwap = numTokensToSwap;
        if (
            contractTokenBalance >= _numTokensToSwap &&
            !inSwapAndLiquify &&
            sender != address(uniswapV2Pair)
        ) {
            if (contractTokenBalance > _numTokensToSwap) {
                contractTokenBalance = _numTokensToSwap;
            }
            _swapAndLiquifyOrCollect(contractTokenBalance);
        }

        super._transfer(sender, recipient, amount);
    }

    function _getPrice() private view returns (uint256) {
        if (address(priceOracle) == address(0)) {
            return 0;
        }
        return priceOracle.consult(address(this), 1e18);
    }

    function maxTransactionSize() public view returns (uint256) {
        return maxTransactionSizePercent.mul(totalSupply());
    }
}