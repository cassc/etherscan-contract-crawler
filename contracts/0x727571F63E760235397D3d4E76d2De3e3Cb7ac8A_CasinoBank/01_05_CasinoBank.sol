// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./abstract/CreationTracked.sol";

//
contract CasinoBank is Ownable, Pausable, CreationTracked {
    /// address controlled by the backend service in charge of the users chips balance
    address public validator;

    /** 
     * price of a single chip 
     * @dev should not be un-constant-ed
     */
    uint256 public immutable singleChipPrice;

    /// how much chips max you can be buy per tx
    uint16 public maxChipsBuyableAtOnce = 200;

    /// tax applied on chips conversion to currency in base points
    uint16 public taxInBasePoints = 500;

    //
    struct BalanceAccountability {
        uint32 bought;
        uint32 airdropped;
    }

    /// how much chips bought / airdropped ever by addresses
    mapping(address => BalanceAccountability) public account;

    /// maximum amount of chips we can bet on a single bet
    uint16 public maxChipsPerBet = 20;

    /// how much of the current contract balance is tax revenue
    uint256 public taxRevenue;

    receive() external payable {}

    fallback() external payable {}

    /** @notice thrown if trying to set a chip price to 0 */
    error InvalidChipPrice();

    //
    constructor(address validator_, uint256 singleChipPrice_) {
        if (singleChipPrice_ == 0) revert("InvalidChipPrice");
        singleChipPrice = singleChipPrice_;
        _updateValidator(validator_);
    }

    //
    // PLAYER ONLY
    //

    /**
     * checks whenever withdrawal is possible for a specified amount of coin
     */
    function isWithdrawPossible(uint16 amountOfCoins_)
        external
        view
        returns (bool)
    {
        //
        uint256 balance_ = address(this).balance;
        uint256 taxR_ = taxRevenue;

        // tax revenue should never exceed the balance
        if (taxR_ >= balance_) return false;

        //
        uint256 available_ = balance_ - taxR_;
        uint256 toWithdraw_ = singleChipPrice * amountOfCoins_;

        //
        return available_ >= toWithdraw_;
    }

    /**
     * Returns price components of a single chip
     * @return taxIncluded_ price of a single chip, tax included
     * @return taxPart_ represents tax fraction of the full price
     */
    function singleChipBuyPrice()
        public
        view
        returns (uint256 taxIncluded_, uint256 taxPart_)
    {
        uint256 singleChipPrice_ = singleChipPrice;
        taxPart_ = (singleChipPrice_ * taxInBasePoints) / 10_000;
        taxIncluded_ = singleChipPrice_ + taxPart_;
    }

    /** @notice thrown when enclosed currency while buying coins does not match exactly a set amount of coins */
    error InvalidPaymentForCoins();

    /** @notice thrown if trying to buy more coins at once than the configured limit */
    error BuyingTooMuchCoinsAtOnce();

    /**
     * @param buyer who bought chips
     * @param trackerId who / what brought buyer
     * @param amount how much chips has been bought
     * @param taxes what buyer paid as tax
     */
    event ChipsBought(address indexed buyer, uint16 indexed trackerId, uint32 amount, uint256 taxes);

    /**
     *
     */
    function buyCasinoChips(uint16 trackerId_) external payable whenNotPaused {
        //
        (uint256 taxIncluded_, uint256 taxPart_) = singleChipBuyPrice();

        //
        if (msg.value % taxIncluded_ != 0) revert("InvalidPaymentForCoins");

        //
        uint16 howManyChipsToBuy_ = uint16(msg.value / taxIncluded_);

        //
        if (howManyChipsToBuy_ > maxChipsBuyableAtOnce)
            revert("BuyingTooMuchCoinsAtOnce");

        //
        account[_msgSender()].bought += howManyChipsToBuy_;

        //
        uint256 revenue_ = taxPart_ * howManyChipsToBuy_;
        taxRevenue += revenue_;

        //
        emit ChipsBought(_msgSender(), trackerId_, howManyChipsToBuy_, revenue_);
    }

    //
    // VALIDATOR ONLY
    //

    /** @notice thrown when anyone but a validator tries to call bound function*/
    error OnlyValidator();

    //
    modifier onlyValidator() {
        if (_msgSender() != validator) revert("OnlyValidator");
        _;
    }

    /** @notice */
    event ChipsConverted(address indexed grantedTo, uint16 coinsAmount, uint256 convertedAmount);

    /**
     * VALIDATOR ONLY
     * Allows the validator, which controls the actual state of any player chips balance, to give back currency in exchange of chips
     */
    function convertChips(address payable withdrawer_, uint16 amountOfCoins_)
        external
        onlyValidator
        whenNotPaused
    {
        //
        uint256 owed_ = singleChipPrice * amountOfCoins_;

        //
        emit ChipsConverted(withdrawer_, amountOfCoins_, owed_);

        //
        (bool success, ) = withdrawer_.call{
            value: owed_
        }("");
        require(success, "convertChips() transfer failed.");
    }

    //
    // OWNER ONLY
    //

    /** @notice */
    event BankBalanceSustained(uint256 amount);

    /**
     * OWNER ONLY
     * Feeds the bank with excedentary funds that backs the sustainability of said contract
     * @dev allows tracking of intent and amount via event emission, instead of using silent fallback() or receive()
     */
    function feedBank() external payable onlyOwner {
        emit BankBalanceSustained(msg.value);
    }

    /** @notice */
    event TaxOnChipsChanged(uint16 taxInBasePoints);

    /** @notice thrown when new tax exceeds 100% */
    error NewTaxTooHigh();

    /**
     * OWNER ONLY
     * self-explainatory
     */
     function updateTaxInBasePoints(uint16 taxInBasePoints_) external onlyOwner {
        if(taxInBasePoints_ > 10_000) revert("NewTaxTooHigh");

        //
        taxInBasePoints = taxInBasePoints_;

        //
        emit TaxOnChipsChanged(taxInBasePoints_);
     }


    /** @notice */
    event MaxChipsPetBetChanged(uint16 newMax);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setMaxChipsPerBet(uint16 maxChipsPerBet_) external onlyOwner {
        //
        maxChipsPerBet = maxChipsPerBet_;

        //
        emit MaxChipsPetBetChanged(maxChipsPerBet_);
    }

    /** @notice emitted whenever validator changed */
    event ValidatorChanged(address validator);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setValidator(address validator_) external onlyOwner {
        //
        _updateValidator(validator_);

        //
        emit ValidatorChanged(validator_);
    }

    /** @notice */
    event MaxChipsBuyableAtOnceChanged(uint16 newMaximum);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setMaxChipsBuyableAtOnce(uint16 maxBuyableChips_)
        external
        onlyOwner
    {
        //
        maxChipsBuyableAtOnce = maxBuyableChips_;

        //
        emit MaxChipsBuyableAtOnceChanged(maxBuyableChips_);
    }

    /** @notice */
    event EmergencyTransferToOwner(address owner, uint256 amount);

    /**
     * OWNER ONLY
     * Failsafe withdrawal method
     * @dev most likely to break tax revenue accountability, use with care and extreme caution in extreme cases !
     * @dev no reentracy-guard needed
     */
    function emergencyTransferToOwner(uint256 amount_) external onlyOwner {
        //
        emit EmergencyTransferToOwner(owner(), amount_);

        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = owner().call{value: amount_}("");
        require(success, "emergencyTransferToOwner() failed.");
    }

    /** @notice */
    event TaxRevenueReleased(uint256 amount);

    /**
     * OWNER ONLY
     * Releases tax revenue accumulated at chips buys, allow it to be usable as player withdrawal counterpart
     * Should be used to alleviate pressure on temporary deficitary trends
     */
    function releaseTaxRevenue(uint256 toRelease_) external onlyOwner {
        //
        _releaseTaxRevenue(toRelease_);

        //
        emit TaxRevenueReleased(toRelease_);
    }

    /** @notice */
    event TaxRevenueTransfered(address indexed receiver, uint16 indexed sponsorId, uint256 amount);

    /**
     * OWNER ONLY
     * transfer part of the tax revenue accumulated to current owner
     * @param amount_ can be 0, means that we want to transfer all tax revenue
     */
    function transferTaxGainsToOwner(uint256 amount_)
        external
        onlyOwner
    {
        transferTaxGainsTo(owner(), 0, amount_);
    }

    /**
     * OWNER ONLY
     * transfer part of the tax revenue accumulated to another account / contract
     * @param amount_ can be 0, means that we want to transfer all tax revenue
     * @param sponsorId_ id of corresponding sponsor
     * @dev no reentracy-guard needed
     */
    function transferTaxGainsTo(address receiver_, uint16 sponsorId_, uint256 amount_)
        public
        onlyOwner
    {
        // @dev: make sure to update internal state before calling external entities
        amount_ = _releaseTaxRevenue(amount_);

        // emiting before
        emit TaxRevenueTransfered(receiver_, sponsorId_, amount_);

        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = receiver_.call{value: amount_}("");
        require(success, "transferTaxGainsTo() failed.");
    }

    /** */
    event ChipsAirdropped(address indexed grantedTo, uint32 granted);

    /**
     * OWNER ONLY
     */
    function manyAirdropChips(address[] calldata receivers_, uint32 amount_) external onlyOwner {
        for (uint256 i_; i_ < receivers_.length; i_++) {
            airdropChipsTo(receivers_[i_], amount_);
        }
    }

    /**
     * OWNER ONLY
     */
    function airdropChipsTo(address receiver_, uint32 amount_) public onlyOwner {
        //
        account[receiver_].airdropped += amount_;

        //
        emit ChipsAirdropped(receiver_, amount_);
    }

    /**
     * OWNER ONLY
     */
    function doUnpause() public onlyOwner {
        _unpause();
    }

    /**
     * OWNER ONLY
     */
    function doPause() public onlyOwner {
        _pause();
    }

    //
    // PRIVATE
    //

    /** @notice thrown when trying to release more than tax revenue available */
    error ReleasingTooMuchRevenue();

    /** @notice thrown when trying to release when no revenue has been made */
    error NoRevenue();

    /**
     *
     * @param toRelease_ can be 0, means takes whatever can be taken from tax revenue
     */
    function _releaseTaxRevenue(uint256 toRelease_) private returns (uint256) {
        //
        uint256 taxRevenue_ = taxRevenue;
        if (taxRevenue_ == 0) revert("NoRevenue");
        if (toRelease_ > taxRevenue_) revert("ReleasingTooMuchRevenue");

        // zero means take all available tax revenue
        if (toRelease_ == 0) {
            toRelease_ = taxRevenue_;
        }

        //
        taxRevenue -= toRelease_;

        // ack for zero-means-all
        return toRelease_;
    }

    /**
     *
     */
    function _updateValidator(address validator_) private {
        validator = validator_;
    }
}