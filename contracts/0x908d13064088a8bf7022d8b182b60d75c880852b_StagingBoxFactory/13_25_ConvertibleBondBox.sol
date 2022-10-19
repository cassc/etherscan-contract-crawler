//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../utils/CBBImmutableArgs.sol";
import "../interfaces/IConvertibleBondBox.sol";

/**
 * @dev Convertible Bond Box for a ButtonTranche bond
 *
 * Invariants:
 *  - initial Price must be <= $1.00
 *  - penalty ratio must be < 1.0
 *  - safeTranche index must not be Z-tranche
 *
 * Assumptions:
 * - Stabletoken has a market price of $1.00
 * - ButtonToken to be used as collateral in the underlying ButtonBond rebases to $1.00
 *
 * While it is possible to deploy a bond without the above assumptions enforced, it will produce faulty math and repayment prices
 */

contract ConvertibleBondBox is
    OwnableUpgradeable,
    CBBImmutableArgs,
    IConvertibleBondBox
{
    // Set when reinitialized
    uint256 public override s_startDate;
    uint256 public s_initialPrice;

    uint256 public override s_repaidSafeSlips;

    // Changeable by owner
    uint256 public override feeBps;

    uint256 public constant override s_trancheGranularity = 1000;
    uint256 public constant override s_penaltyGranularity = 1000;
    uint256 public constant override s_priceGranularity = 1e8;

    // Denominator for basis points. Used to calculate fees
    uint256 public constant override BPS = 10_000;
    uint256 public constant override maxFeeBPS = 50;

    modifier afterReinitialize() {
        if (s_startDate == 0) {
            revert ConvertibleBondBoxNotStarted({
                given: 0,
                minStartDate: block.timestamp
            });
        }
        _;
    }

    modifier beforeBondMature() {
        if (block.timestamp >= maturityDate()) {
            revert BondIsMature({
                currentTime: block.timestamp,
                maturity: maturityDate()
            });
        }
        _;
    }

    modifier afterBondMature() {
        if (block.timestamp < maturityDate()) {
            revert BondNotMatureYet({
                maturityDate: maturityDate(),
                currentTime: block.timestamp
            });
        }
        _;
    }

    modifier validAmount(uint256 amount) {
        if (amount < 1e6) {
            revert MinimumInput({input: amount, reqInput: 1e6});
        }
        _;
    }

    function initialize(address _owner) external initializer beforeBondMature {
        require(
            _owner != address(0),
            "ConvertibleBondBox: invalid owner address"
        );

        // Revert if penalty too high
        if (penalty() > s_penaltyGranularity) {
            revert PenaltyTooHigh({
                given: penalty(),
                maxPenalty: s_penaltyGranularity
            });
        }

        // Set owner
        __Ownable_init();
        transferOwnership(_owner);

        emit Initialized(_owner);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function reinitialize(uint256 _initialPrice)
        external
        reinitializer(2)
        onlyOwner
        beforeBondMature
    {
        if (_initialPrice > s_priceGranularity)
            revert InitialPriceTooHigh({
                given: _initialPrice,
                maxPrice: s_priceGranularity
            });
        if (_initialPrice == 0)
            revert InitialPriceIsZero({given: 0, maxPrice: s_priceGranularity});

        s_initialPrice = _initialPrice;

        //set ConvertibleBondBox Start Date to be time when init() is called
        s_startDate = block.timestamp;

        emit ReInitialized(_initialPrice, block.timestamp);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function lend(
        address _borrower,
        address _lender,
        uint256 _stableAmount
    )
        external
        override
        afterReinitialize
        beforeBondMature
        validAmount(_stableAmount)
    {
        uint256 price = _currentPrice();

        uint256 safeSlipAmount = (_stableAmount *
            s_priceGranularity *
            trancheDecimals()) /
            price /
            stableDecimals();

        uint256 zTrancheAmount = (safeSlipAmount * riskRatio()) / safeRatio();

        _atomicDeposit(
            _borrower,
            _lender,
            _stableAmount,
            safeSlipAmount,
            zTrancheAmount
        );

        emit Lend(_msgSender(), _borrower, _lender, _stableAmount, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function borrow(
        address _borrower,
        address _lender,
        uint256 _safeTrancheAmount
    )
        external
        override
        afterReinitialize
        beforeBondMature
        validAmount(_safeTrancheAmount)
    {
        uint256 price = _currentPrice();

        uint256 zTrancheAmount = (_safeTrancheAmount * riskRatio()) /
            safeRatio();
        uint256 stableAmount = (_safeTrancheAmount * price * stableDecimals()) /
            s_priceGranularity /
            trancheDecimals();

        _atomicDeposit(
            _borrower,
            _lender,
            stableAmount,
            _safeTrancheAmount,
            zTrancheAmount
        );

        emit Borrow(
            _msgSender(),
            _borrower,
            _lender,
            _safeTrancheAmount,
            price
        );
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function currentPrice()
        public
        view
        override
        afterReinitialize
        returns (uint256)
    {
        return _currentPrice();
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function repay(uint256 _stableAmount)
        external
        override
        afterReinitialize
        validAmount(_stableAmount)
    {
        //Load into memory
        uint256 price = _currentPrice();

        //calculate inputs for internal redeem function
        uint256 stableFees = (_stableAmount * feeBps) / BPS;
        uint256 safeTranchePayout = (_stableAmount *
            s_priceGranularity *
            trancheDecimals()) /
            price /
            stableDecimals();
        uint256 riskTranchePayout = (safeTranchePayout * riskRatio()) /
            safeRatio();

        _repay(_stableAmount, stableFees, safeTranchePayout, riskTranchePayout);
        emit Repay(_msgSender(), _stableAmount, riskTranchePayout, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function repayMax(uint256 _riskSlipAmount)
        external
        override
        afterReinitialize
        validAmount(_riskSlipAmount)
    {
        // Load params into memory
        uint256 price = _currentPrice();

        // Calculate inputs for internal repay function
        uint256 safeTranchePayout = (_riskSlipAmount * safeRatio()) /
            riskRatio();
        uint256 stablesOwed = (safeTranchePayout * price * stableDecimals()) /
            s_priceGranularity /
            trancheDecimals();
        uint256 stableFees = (stablesOwed * feeBps) / BPS;

        _repay(stablesOwed, stableFees, safeTranchePayout, _riskSlipAmount);

        //emit event
        emit Repay(_msgSender(), stablesOwed, _riskSlipAmount, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemRiskTranche(uint256 _riskSlipAmount)
        external
        override
        afterBondMature
        validAmount(_riskSlipAmount)
    {
        //transfer fee to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_riskSlipAmount * feeBps) / BPS;
            riskSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _riskSlipAmount -= feeSlip;
        }

        uint256 zTranchePayout = (_riskSlipAmount *
            (s_penaltyGranularity - penalty())) / (s_penaltyGranularity);

        //transfer Z-tranches from ConvertibleBondBox to msg.sender
        riskTranche().transfer(_msgSender(), zTranchePayout);

        riskSlip().burn(_msgSender(), _riskSlipAmount);

        emit RedeemRiskTranche(_msgSender(), _riskSlipAmount);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemSafeTranche(uint256 _safeSlipAmount)
        external
        override
        afterBondMature
        validAmount(_safeSlipAmount)
    {
        //transfer fee to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_safeSlipAmount * feeBps) / BPS;
            safeSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _safeSlipAmount -= feeSlip;
        }

        uint256 safeSlipSupply = safeSlip().totalSupply();

        //burn safe-slips
        safeSlip().burn(_msgSender(), _safeSlipAmount);

        //transfer safe-Tranche after maturity only
        safeTranche().transfer(_msgSender(), _safeSlipAmount);

        uint256 zPenaltyTotal = riskTranche().balanceOf(address(this)) -
            riskSlip().totalSupply();

        //transfer risk-Tranche penalty after maturity only
        riskTranche().transfer(
            _msgSender(),
            (_safeSlipAmount * zPenaltyTotal) /
                (safeSlipSupply - s_repaidSafeSlips)
        );

        emit RedeemSafeTranche(_msgSender(), _safeSlipAmount);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemStable(uint256 _safeSlipAmount)
        external
        override
        validAmount(_safeSlipAmount)
    {
        //transfer safeSlips to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_safeSlipAmount * feeBps) / BPS;
            safeSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _safeSlipAmount -= feeSlip;
        }

        uint256 stableBalance = stableToken().balanceOf(address(this));

        //transfer stables
        TransferHelper.safeTransfer(
            address(stableToken()),
            _msgSender(),
            (_safeSlipAmount * stableBalance) / (s_repaidSafeSlips)
        );

        //burn safe-slips
        safeSlip().burn(_msgSender(), _safeSlipAmount);
        s_repaidSafeSlips -= _safeSlipAmount;

        emit RedeemStable(_msgSender(), _safeSlipAmount, _currentPrice());
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function setFee(uint256 newFeeBps)
        external
        override
        onlyOwner
        beforeBondMature
    {
        if (newFeeBps > maxFeeBPS)
            revert FeeTooLarge({input: newFeeBps, maximum: maxFeeBPS});

        feeBps = newFeeBps;
        emit FeeUpdate(newFeeBps);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function transferOwnership(address newOwner)
        public
        override(IConvertibleBondBox, OwnableUpgradeable)
        onlyOwner
    {
        _transferOwnership(newOwner);
    }

    function _atomicDeposit(
        address _borrower,
        address _lender,
        uint256 _stableAmount,
        uint256 _safeSlipAmount,
        uint256 _riskSlipAmount
    ) internal {
        //Transfer safeTranche to ConvertibleBondBox
        safeTranche().transferFrom(
            _msgSender(),
            address(this),
            _safeSlipAmount
        );

        //Transfer riskTranche to ConvertibleBondBox
        riskTranche().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        // //Mint safeSlips to the lender
        safeSlip().mint(_lender, _safeSlipAmount);

        // //Mint riskSlips to the borrower
        riskSlip().mint(_borrower, _riskSlipAmount);

        // // Transfer stables to borrower
        if (_msgSender() != _borrower) {
            TransferHelper.safeTransferFrom(
                address(stableToken()),
                _msgSender(),
                _borrower,
                _stableAmount
            );
        }
    }

    function _repay(
        uint256 _stablesOwed,
        uint256 _stableFees,
        uint256 _safeTranchePayout,
        uint256 _riskTranchePayout
    ) internal {
        // Update total repaid safe slips
        s_repaidSafeSlips += _safeTranchePayout;

        // Transfer fees to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            TransferHelper.safeTransferFrom(
                address(stableToken()),
                _msgSender(),
                owner(),
                _stableFees
            );
        }

        // Transfers stables to CBB
        TransferHelper.safeTransferFrom(
            address(stableToken()),
            _msgSender(),
            address(this),
            _stablesOwed
        );

        // Transfer safeTranches to msg.sender (increment state)
        safeTranche().transfer(_msgSender(), _safeTranchePayout);

        // Transfer riskTranches to msg.sender
        riskTranche().transfer(_msgSender(), _riskTranchePayout);

        // Burn riskSlips
        riskSlip().burn(_msgSender(), _riskTranchePayout);
    }

    function _currentPrice() internal view returns (uint256) {
        if (block.timestamp < maturityDate()) {
            uint256 price = s_priceGranularity -
                ((s_priceGranularity - s_initialPrice) *
                    (maturityDate() - block.timestamp)) /
                (maturityDate() - s_startDate);

            return price;
        } else {
            return s_priceGranularity;
        }
    }
}