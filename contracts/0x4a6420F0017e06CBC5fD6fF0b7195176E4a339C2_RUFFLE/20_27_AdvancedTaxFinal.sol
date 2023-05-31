//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WinOnBuy.sol";
import "./Multisig.sol";

contract AdvancedTax is Ownable, WinOnBuy, Multisig {
    using SafeMath for uint256;

    uint256 _totalSupply;
    //Tax distribution between marketing and lottery. Tax percentage is variable on buy and sell
    uint256 public buyMarketingRate = 20;
    uint256 public buyLotteryRate = 60;
    uint256 public buyAcapRate = 8;
    uint256 public buyApadRate = 12;
    uint256 public sellMarketingRate = 30;
    uint256 public sellLotteryRate = 50;
    uint256 public sellAcapRate = 4;
    uint256 public sellApadRate = 16;
    uint256 public minimumBuyTax = 12;
    uint256 public buyTaxRange = 0;
    uint256 public maximumSellTax = 25; //The selltaxrefund will be deducted so that max effective sell tax is never higher than 20 percent
    uint256 public maximumSellTaxRefund = 0; //dynamic
    uint256[] public tieredTaxPercentage = [10, 10, 10];
    uint256[] public taxTiers = [50, 10]; //Highest bracket, middle bracket. multiplied by TotalSupply divided by 10000

    //Tax balances
    uint256 public totalMarketing;
    uint256 public totalLottery;
    uint256 public totalApad;
    uint256 public totalAcap;

    //Tax wallets
    address payable public lotteryWallet;
    address payable public marketingWallet;
    address payable public apadWallet;
    address payable public acapWallet;

    mapping(address => bool) public _taxExcluded;
    mapping(address => uint256) public taxPercentagePaidByUser;

    //event
    event AddTaxExcluded(address wallet);
    event RemoveTaxExcluded(address wallet);
    event SetBuyRate(
        uint256 buyMarketingRate,
        uint256 buyLotteryRate,
        uint256 buyAcapRate,
        uint256 buyApadRate
    );
    event SetBuyTax(uint256 minimumBuyTax, uint256 buyTaxRange);
    event SetLotteryWallet(address oldLotteryWallet, address newLotteryWallet);
    event SetMarketingWallet(
        address oldMarketingWallet,
        address newMarketingWallet
    );
    event SetSellRates(
        uint256 sellMarketingRate,
        uint256 sellLotteryRate,
        uint256 sellAcapRate,
        uint256 sellApadRate
    );
    event SetSellTax(uint256 _maximumSellTax, uint256 _maximumSellTaxRefund);
    event SetTaxTiers(uint256 tier1, uint256 tier2);
    event SetTieredTaxPercentages(uint256 multiplier1, uint256 multiplier2);

    /// @notice Include an address to paying taxes
    /// @param account The address that we want to start paying taxes
    function removeTaxExcluded(address account) public onlyOwner {
        require(isTaxExcluded(account), "Account must not be excluded");
        _taxExcluded[account] = false;
        emit RemoveTaxExcluded(account);
    }

    /// @notice Change distribution of the buy taxes
    /// @param _marketingRate The new marketing tax rate
    /// @param _buyLotteryRate The new lottery tax rate
    /// @param _buyAcapRate The new acap tax rate
    /// @param _buyApadRate The new apad tax rate
    function setBuyRates(
        uint256 _marketingRate,
        uint256 _buyLotteryRate,
        uint256 _buyAcapRate,
        uint256 _buyApadRate
    ) external onlyMultisig {
        require(_marketingRate <= 25, "_marketingRate cannot exceed 25%");
        require(_buyLotteryRate <= 100, "_lotteryRate cannot exceed 100%");
        require(_buyAcapRate <= 20, "_buyAcapRate cannot exceed 20%");
        require(_buyApadRate <= 20, "_buyApadRate cannot exceed 20%");
        require(
            _marketingRate + _buyLotteryRate + _buyAcapRate + _buyApadRate ==
                100,
            "the sum must be 100"
        );
        buyMarketingRate = _marketingRate;
        buyLotteryRate = _buyLotteryRate;
        buyAcapRate = _buyAcapRate;
        buyApadRate = _buyApadRate;
        emit SetBuyRate(
            _marketingRate,
            _buyLotteryRate,
            _buyAcapRate,
            _buyApadRate
        );
    }

    /// @notice Change the buy tax rate variables
    /// @param _minimumTax The minimum tax on buys
    /// @param _buyTaxRange The new range the buy tax is in [0 - _buyTaxRange]
    function setBuyTax(uint256 _minimumTax, uint256 _buyTaxRange)
        external
        onlyOwner
    {
        require(_minimumTax <= 20, "the minimum tax cannot exceed 20%");
        require(_buyTaxRange <= 20, "The buy tax range cannot exceed 20%");
        require(
            _minimumTax + _buyTaxRange <= 20,
            "The total tax on buys can never exceed 20 percent"
        );
        minimumBuyTax = _minimumTax;
        buyTaxRange = _buyTaxRange;
        emit SetBuyTax(_minimumTax, _buyTaxRange);
    }

    /// @notice Change the address of the lottery wallet
    /// @param _lotteryWallet The new address of the lottery wallet
    function setLotteryWallet(address payable _lotteryWallet)
        external
        onlyMultisig
    {
        require(
            _lotteryWallet != address(0),
            "new lottery wallet can not be the 0 address"
        );
        address _oldLotteryWallet = lotteryWallet;
        removeTaxExcluded(_oldLotteryWallet);
        lotteryWallet = _lotteryWallet;
        addTaxExcluded(_lotteryWallet);
        emit SetLotteryWallet(_oldLotteryWallet, _lotteryWallet);
    }

    /// @notice Change the address of the marketing wallet
    /// @param _marketingWallet The new address of the lottery wallet
    function setMarketingWallet(address payable _marketingWallet)
        external
        onlyOwner
    {
        require(
            _marketingWallet != address(0),
            "new lottery wallet can not be the 0 address"
        );
        address _oldMarketingWallet = marketingWallet;
        removeTaxExcluded(_oldMarketingWallet);
        marketingWallet = _marketingWallet;
        addTaxExcluded(_marketingWallet);
        emit SetMarketingWallet(_oldMarketingWallet, _marketingWallet);
    }

    /// @notice Change the marketing and lottery rate on sells
    /// @param _sellMarketingRate The new marketing tax rate
    /// @param _sellLotteryRate The new treasury tax rate
    function setSellRates(
        uint256 _sellMarketingRate,
        uint256 _sellLotteryRate,
        uint256 _sellAcapRate,
        uint256 _sellApadRate
    ) external onlyMultisig {
        require(_sellMarketingRate <= 25, "_marketingRate cannot exceed 25%");
        require(_sellLotteryRate <= 100, "_lotteryRate cannot exceed 100%");
        require(_sellAcapRate <= 20, "_sellAcapRate cannot exceed 20%");
        require(_sellApadRate <= 20, "_sellApadRate cannot exceed 20%");
        require(
            _sellMarketingRate +
                _sellLotteryRate +
                _sellAcapRate +
                _sellApadRate ==
                100,
            "the sum must be 100"
        );
        sellMarketingRate = _sellMarketingRate;
        sellLotteryRate = _sellLotteryRate;
        sellAcapRate = _sellAcapRate;
        sellApadRate = _sellApadRate;
        emit SetSellRates(
            _sellMarketingRate,
            _sellLotteryRate,
            _sellAcapRate,
            _sellApadRate
        );
    }

    /// @notice Change the sell tax rate variables
    /// @param _maximumSellTax The new minimum sell tax
    /// @param _maximumSellTaxRefund The new range the sell tax is in [0 - _sellTaxRange]
    function setSellTax(uint256 _maximumSellTax, uint256 _maximumSellTaxRefund)
        external
        onlyOwner
    {
        require(
            _maximumSellTax <= 25,
            "the maximum sell tax cannot exceed 25 percent"
        );
        require(
            _maximumSellTaxRefund <= _maximumSellTax,
            "The refund rate must be less than the maximum tax"
        );
        require(
            _maximumSellTax - _maximumSellTaxRefund <= 25,
            "The maximum effective sell tax can never exceed 25 percent"
        );
        maximumSellTax = _maximumSellTax;
        maximumSellTaxRefund = _maximumSellTaxRefund;
    }

    /// @notice Set the three different tax tiers by setting the highest bracket and the lower cutoff. Value multiplied by totalSupply divided by 10000. Example 50 = 5000000 tokens
    function setTaxTiers(uint256[] memory _taxTiers) external onlyOwner {
        require(
            _taxTiers.length == 2,
            "you have to give an array with 2 values"
        );
        taxTiers[0] = _taxTiers[0];
        taxTiers[1] = _taxTiers[1];
        emit SetTaxTiers(_taxTiers[0], _taxTiers[1]);
    }

    /// @notice Set the three different tax tier percentages
    function setTieredTaxPercentages(uint256[] memory _tieredPercentages)
        external
        onlyOwner
    {
        require(
            _tieredPercentages.length == 3,
            "you have to give an array with 3 values"
        );
        require(_tieredPercentages[0] <= 10);
        require(_tieredPercentages[1] == 10);
        require(_tieredPercentages[2] < 20);
        tieredTaxPercentage[0] = _tieredPercentages[0];
        tieredTaxPercentage[1] = _tieredPercentages[1];
        tieredTaxPercentage[2] = _tieredPercentages[2];
    }

    /// @notice Exclude an address from paying taxes
    /// @param account The address that we want to exclude from taxes
    function addTaxExcluded(address account) public onlyOwner {
        _taxExcluded[account] = true;
        emit AddTaxExcluded(account);
    }

    /// @notice Get if an account is excluded from paying taxes
    /// @param account The address that we want to get the value for
    /// @return taxExcluded Boolean that tells if an address has to pay taxes
    function isTaxExcluded(address account)
        public
        view
        returns (bool taxExcluded)
    {
        return _taxExcluded[account];
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @param user the address for which to generate a random number
    /// @return send The raw amount to send
    /// @return buyTax the tax percentage that the user pays on buy
    /// @return marketing The raw marketing tax amount
    /// @return lottery The raw lottery tax amount
    /// @return acap the raw acap tax amount
    /// @return apad the raw apad tax amount
    function _getBuyTaxInfo(uint256 amount, address user)
        internal
        view
        returns (
            uint256 send,
            uint256 buyTax,
            uint256 marketing,
            uint256 lottery,
            uint256 acap,
            uint256 apad
        )
    {
        uint256 _baseBuyTax = _getBuyTaxPercentage(amount, user);
        uint256 _multiplier = _getBuyTaxTier(amount);
        buyTax = _baseBuyTax.mul(_multiplier).div(10);
        uint256 _sendRate = 100 - (buyTax);
        send = amount.mul(_sendRate).div(100);
        uint256 _totalTax = amount.sub(send);
        marketing = _totalTax.mul(buyMarketingRate).div(100);
        lottery = _totalTax.mul(buyLotteryRate).div(100);
        acap = _totalTax.mul(buyAcapRate).div(100);
        apad = _totalTax.mul(buyApadRate).div(100);
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount that is being seend
    /// @param user the address for which to generate a random number
    /// @return buyTaxPercentage
    function _getBuyTaxPercentage(uint256 amount, address user)
        internal
        view
        returns (uint256 buyTaxPercentage)
    {
        if (buyTaxRange > 0) {
            uint256 _randomNumber = _getPseudoRandomNumber(
                buyTaxRange,
                amount,
                user
            );
            return _randomNumber.add(minimumBuyTax);
        } else {
            return minimumBuyTax;
        }
    }

    /// @notice get the tier for the buy tax based on the amount of tokens bought
    /// @param amount the amount of tokens bought
    /// @return taxTier the multiplier that corresponds to the tax tier

    function _getBuyTaxTier(uint256 amount)
        internal
        view
        returns (uint256 taxTier)
    {
        if (amount > _totalSupply.mul(taxTiers[0]).div(10000)) {
            return tieredTaxPercentage[0];
        } else if (amount > _totalSupply.mul(taxTiers[1]).div(10000)) {
            return tieredTaxPercentage[1];
        } else return tieredTaxPercentage[2];
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount that is being transfered.
    /// @param user the address for which to generate a random number
    /// @return send The raw amount to send
    /// @return totalTax the total taxes on the sell tx
    /// @return marketing The raw marketing tax amount
    /// @return lottery The raw lottery tax amount
    /// @return acap the raw acap tax amount
    /// @return apad the raw apad tax amount
    function _getSellTaxInfo(uint256 amount, address user)
        internal
        view
        returns (
            uint256 send,
            uint256 totalTax,
            uint256 marketing,
            uint256 lottery,
            uint256 acap,
            uint256 apad
        )
    {
        bool winner = _get0SellTaxWinner(amount, user);
        uint256 _sendRate;
        if (winner) {
            _sendRate = 100; //0 percent sell tax winner
        } else {
            uint256 _taxMultiplier = _getSellTaxTier(amount);
            uint256 _maximumTax = _taxMultiplier.mul(maximumSellTax).div(10);
            _sendRate = 100 - _maximumTax;
        }
        send = amount.mul(_sendRate).div(100);
        totalTax = amount.sub(send);
        marketing = totalTax.mul(sellMarketingRate).div(100);
        lottery = totalTax.mul(sellLotteryRate).div(100);
        acap = totalTax.mul(sellAcapRate).div(100);
        apad = totalTax.mul(sellApadRate).div(100);
    }

    /// @notice get the tier for the sell tax based on the amount of tokens bought
    /// @param amount the amount of tokens bought
    /// @return taxTier the multiplier that corresponds to the tax tier

    function _getSellTaxTier(uint256 amount)
        internal
        view
        returns (uint256 taxTier)
    {
        if (amount > _totalSupply.mul(taxTiers[0]).div(10000)) {
            return tieredTaxPercentage[2];
        } else if (amount > _totalSupply.mul(taxTiers[1]).div(10000)) {
            return tieredTaxPercentage[1];
        } else return tieredTaxPercentage[0];
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount the amount that is being send. Will be used to generate a more difficult pseudo random number
    /// @param user the address for which to generate a random number
    /// @return sellTaxPercentage
    function _getSellTaxPercentage(uint256 amount, address user)
        internal
        view
        returns (uint256 sellTaxPercentage)
    {
        if (maximumSellTaxRefund > 0) {
            uint256 _randomNumber = _getPseudoRandomNumber(100, amount, user);
            sellTaxPercentage = _randomNumber % maximumSellTaxRefund;
        } else {
            sellTaxPercentage = 0;
        }
        return sellTaxPercentage;
    }
}