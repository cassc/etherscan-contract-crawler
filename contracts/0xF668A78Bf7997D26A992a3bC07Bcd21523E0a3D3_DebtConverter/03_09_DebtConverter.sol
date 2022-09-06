pragma solidity ^0.8.0;

import { IOracle } from "./IOracle.sol";
import { ICToken } from "./ICToken.sol";
import { ERC20 } from "./ERC20.sol";
import { IERC20 } from "./IERC20.sol";
import { IFeed } from "./IFeed.sol";

contract DebtConverter is ERC20 {
    //Current amount of DOLA-denominated debt accrued by the DebtConverter contract.
    uint public outstandingDebt;

    //Cumulative amount of DOLA-denominated debt accrued by the DebtConverter contract over its lifetime.
    uint public cumDebt;

    //Cumulative amount of DOLA repaid to the DebtConverter contract over its lifetime.
    uint public cumDolaRepaid;

    //Exchange rate of DOLA IOUs to DOLA scaled by 1e18. Default is 1e18.
    //DOLA IOU amount * exchangeRateMantissa / 1e18 = DOLA amount received on redemption
    //Bad Debt $ amount * 1e18 / exchangeRateMantissa = DOLA IOUs received on conversion
    uint public exchangeRateMantissa = 1e18;

    //The amount that exchangeRateMantissa will increase every second. This is how “interest” is accrued.
    uint public exchangeRateIncreasePerSecond;

    //Timestamp of the last time `accrueInterest()` was called.
    uint public lastAccrueInterestTimestamp;

    //Current repayment epoch
    uint public repaymentEpoch;

    //anToken address => maximum price this contract will pay for 1 underlying of the anToken on a call to `convert()`
    //Make sure to use 18 decimals!
    //0 = no maximum price
    mapping(address => uint256) public maxConvertPrice;

    //user address => epoch => Conversion struct
    mapping(address => ConversionData[]) public conversions;
    
    //epoch => Repayment struct
    mapping(uint => RepaymentData) public repayments;

    //user address => bool. True if DOLA IOU transfers to this address are allowed, false by default.
    mapping(address => bool) public transferWhitelist;

    //Can perform repayments and set interest rates.
    address public owner;

    //Treasury address buying the debt.
    address public treasury;

    //Can set privileged roles and sweep tokens.
    address public governance;

    //Frontier master oracle.
    IOracle public immutable oracle;

    //DOLA contract
    address public constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address public constant anEth = 0x697b4acAa24430F254224eB794d2a85ba1Fa1FB8;
    address public constant anYfi = 0xde2af899040536884e062D3a334F2dD36F34b4a4;
    address public constant anBtc = 0x17786f3813E6bA35343211bd8Fe18EC4de14F28b;

    //Errors
    error TransferToAddressNotWhitelisted();
    error OnlyOwner();
    error OnlyGovernance();
    error InsufficientDebtTokens(uint needed, uint actual);
    error InsufficientTreasuryFunds(uint needed, uint actual);
    error InvalidDebtToken();
    error DolaAmountLessThanMinOut(uint minOut, uint amount);
    error InsufficientDebtToBeRepaid(uint repayment, uint debt);
    error ConversionDoesNotExist();
    error ConversionEpochNotEqualToCurrentEpoch(uint conversionEpoch, uint currentEpoch);
    error ThatEpochIsInTheFuture();
    error ConversionHasNotBeenRedeemedBefore();

    //Events
    event NewOwner(address owner);
    event NewTreasury(address treasury);
    event NewGovernance(address governance);
    event NewTransferWhitelistAddress(address whitelistedAddr);
    event NewAnnualExchangeRateIncrease(uint increase);
    event NewMaxConvertPrice(address anToken, uint maxPrice);
    event Repayment(uint dolaAmount, uint epoch);
    event Redemption(address indexed user, uint dolaAmount);
    event Conversion(address indexed user, address indexed anToken, uint epoch, uint dolaAmount, uint underlyingAmount);

    struct RepaymentData {
        uint epoch;
        uint dolaAmount;
        uint pctDolaIOUsRedeemable;
    }

    struct ConversionData {
        uint lastEpochRedeemed;
        uint dolaIOUAmount;
        uint dolaIOUsRedeemed;
    }

    constructor(uint initialIncreasePerYear, address _owner, address _treasury, address _governance, address _oracle) ERC20("DOLA IOU", "DOLAIOU") {
        owner = _owner;
        treasury = _treasury;
        governance = _governance;
        oracle = IOracle(_oracle);
        lastAccrueInterestTimestamp = block.timestamp;
        exchangeRateIncreasePerSecond = initialIncreasePerYear / 365 days;
        emit NewAnnualExchangeRateIncrease(initialIncreasePerYear);
    }

    modifier onlyOwner() {
        if ( msg.sender != owner ) revert OnlyOwner();
        _;
    }

    modifier onlyGovernance() {
        if ( msg.sender != governance ) revert OnlyGovernance();
        _;
    }

    /*
     * @notice function for converting bad debt anTokens to DOLA IOU tokens.
     * @param anToken Address of the bad debt anToken to be converted
     * @param amount Amount of `token` to be converted. 0 = max
     * @param minOut Minimum DOLA amount worth of DOLA IOUs to be received. Will revert if actual amount is lower.
     */
    function convert(address anToken, uint amount, uint minOut) external {
        if (anToken != anYfi && anToken != anBtc && anToken != anEth) revert InvalidDebtToken();
        uint anTokenBal = IERC20(anToken).balanceOf(msg.sender);
        if (amount == 0) amount = anTokenBal;
        if (anTokenBal < amount) revert InsufficientDebtTokens(anTokenBal, amount);

        //Accrue interest so exchange rates are fresh
        accrueInterest();
        
        uint underlyingAmount = ICToken(anToken).balanceOfUnderlying(msg.sender) * amount / ICToken(anToken).balanceOf(msg.sender);
        uint underlyingPrice = oracle.getUnderlyingPrice(anToken);
        
        //Allows operator to set anBtc maxConvertPrice with 18 decimals like other tokens since we normalize it here.
        //This is necessary since underlyingAmount for btc is only 8 decimals, meaning we need 28 decimals in price to offset decimal division we do later
        //`oracle.getUnderlyingPrice()` already returns anBtc price normalized for underlying token decimals, so we use it by itself.
        uint maxConversionPrice = maxConvertPrice[anToken];
        if (anToken == anBtc) {
            maxConversionPrice *= 1e10;
        }
        
        //If underlying is currently worth more than maxConvertPrice[anToken], price becomes maxConvertPrice[anToken]
        if (maxConversionPrice != 0 && underlyingPrice > maxConversionPrice) {
            underlyingPrice = maxConversionPrice;
        }
        uint dolaValueOfDebt = (underlyingPrice * underlyingAmount) / (10 ** 18);
        uint dolaIOUsOwed = convertDolaToDolaIOUs(dolaValueOfDebt);

        if (dolaValueOfDebt < minOut) revert DolaAmountLessThanMinOut(minOut, dolaValueOfDebt);

        outstandingDebt += dolaValueOfDebt;
        cumDebt += dolaValueOfDebt;

        uint epoch = repaymentEpoch;
        ConversionData memory c;
        c.dolaIOUAmount = dolaIOUsOwed;
        c.lastEpochRedeemed = epoch;

        conversions[msg.sender].push(c);

        require(IERC20(anToken).transferFrom(msg.sender, treasury, amount), "failed to transfer anTokens");
        _mint(msg.sender, dolaIOUsOwed);

        emit Conversion(msg.sender, anToken, epoch, dolaValueOfDebt, underlyingAmount);
    }

    /*
     * @notice function for repaying DOLA to this contract. Only callable by owner.
     * @param amount Amount of DOLA to repay & transfer to this contract.
     */
    function repayment(uint amount) external onlyOwner {
        if(amount == 0) return;
        accrueInterest();
        uint _outstandingDebt = outstandingDebt;
        if (amount > _outstandingDebt) revert InsufficientDebtToBeRepaid(amount, _outstandingDebt);
        uint _epoch = repaymentEpoch;

        //Calculate redeemable DOLA ratio for this epoch
        uint pctDolaIOUsRedeemable = amount * 1e18 / _outstandingDebt;

        //Update debt state variables
        outstandingDebt -= amount;
        cumDolaRepaid += amount;

        //Store data from current epoch and update epoch state variables
        repayments[_epoch] = RepaymentData(_epoch, amount, pctDolaIOUsRedeemable);
        repaymentEpoch += 1;
        
        uint senderBalance = IERC20(DOLA).balanceOf(msg.sender);
        if(senderBalance >= amount){
            require(IERC20(DOLA).transferFrom(msg.sender, address(this), amount), "DOLA transfer failed");
        } else {
            revert InsufficientTreasuryFunds(amount, senderBalance);
        }

        emit Repayment(amount, _epoch);
    }

     /*
     * @notice Function for redeeming DOLA IOUs for DOLA. 
     * @param _conversion index of conversion to redeem for
     * @param _epoch repayment epoch to redeem DOLA from
     */
    function redeem(uint _conversion, uint _epoch) internal returns (uint) {
        uint redeemableDolaIOUs = getRedeemableDolaIOUsFor(msg.sender, _conversion, _epoch);
        conversions[msg.sender][_conversion].dolaIOUsRedeemed += redeemableDolaIOUs;
        return redeemableDolaIOUs;
    }

    /*
     * @notice Function wrapper for calling `redeem()`. Will redeem all redeemable epochs for given conversion unless an _endEpoch is provided
     * @param _conversion index of conversion to redeem for
     * @param _endEpoch the last repayment epoch that will be claimed in this call for the given conversion
     */
    function redeemConversion(uint _conversion, uint _endEpoch) public {
        if (_conversion > conversions[msg.sender].length) revert ConversionDoesNotExist();
        accrueInterest();
        ConversionData storage c = conversions[msg.sender][_conversion];
        uint lastEpochRedeemed = c.lastEpochRedeemed;

        uint totalDolaIOUsRedeemable;
        uint totalDolaRedeemable;

        if (_endEpoch > repaymentEpoch) revert ThatEpochIsInTheFuture();

        if (_endEpoch == 0) {
            _endEpoch = repaymentEpoch;
        }

        for (uint i = lastEpochRedeemed; i < _endEpoch;) {
            //Get redeemable DOLA IOUs for this epoch and add to running totals
            uint dolaIOUsRedeemable = redeem(_conversion, i);
            totalDolaIOUsRedeemable += dolaIOUsRedeemable;
            totalDolaRedeemable += convertDolaIOUsToDola(dolaIOUsRedeemable);

            //We keep the loop going
            unchecked { i++; }
        }

        c.lastEpochRedeemed = _endEpoch;

        //After loop breaks: burn DOLA IOUs, transfer DOLA & emit event.
        //This way we don't have to loop these naughty, costly calls
        if (totalDolaIOUsRedeemable > 0) {
            //Handles rounding errors. Will only allow max redemption equal to DOLA balance of this contract
            //User will be able to redeem using this conversion after another repayment to collect their dust
            uint dolaBal = IERC20(DOLA).balanceOf(address(this));
            if (totalDolaRedeemable > dolaBal) {
                //Subtract DOLA difference from dolaRedeemed on this conversion object
                //This way, the user will be able to claim their dust on the next repayment & call to `redeemConversion`
                c.dolaIOUsRedeemed -= convertDolaToDolaIOUs(totalDolaRedeemable - dolaBal);
                totalDolaRedeemable = dolaBal;
                totalDolaIOUsRedeemable = convertDolaToDolaIOUs(totalDolaRedeemable);
            }

            //If user does not have enough DOLA IOUs to fully redeem, will redeem remainder of IOUs
            if (totalDolaIOUsRedeemable > balanceOf(msg.sender)) {
                uint diff = totalDolaIOUsRedeemable - balanceOf(msg.sender);
                c.dolaIOUsRedeemed -= diff;
                totalDolaIOUsRedeemable = balanceOf(msg.sender);
                totalDolaRedeemable = convertDolaIOUsToDola(totalDolaIOUsRedeemable);
            }

            _burn(msg.sender, totalDolaIOUsRedeemable);
            require(IERC20(DOLA).transfer(msg.sender, totalDolaRedeemable), "DOLA transfer failed");
            
            emit Redemption(msg.sender, totalDolaRedeemable);
        }
    }

    /*
     * @notice Redeems all DOLA "dust" leftover from rounding errors.
     * @notice Only redeemable if conversion's lastEpochRedeemed is equal to current repaymentEpoch.
     * Simply call `redeemConversion()` to update your conversions' lastEpochRedeemed
     * @param _conversion index of conversion to redeem dust for
     */
    function redeemConversionDust(uint _conversion) public {
        ConversionData memory c = conversions[msg.sender][_conversion];
        if (c.lastEpochRedeemed != repaymentEpoch) revert ConversionEpochNotEqualToCurrentEpoch(c.lastEpochRedeemed, repaymentEpoch);
        if (c.dolaIOUsRedeemed == 0) revert ConversionHasNotBeenRedeemedBefore();
        accrueInterest();
        uint dolaIOUsLeftToRedeem = c.dolaIOUAmount - c.dolaIOUsRedeemed;
        uint dolaLeftToRedeem = convertDolaIOUsToDola(dolaIOUsLeftToRedeem);
        uint redeemableIOUsPct = dolaIOUsLeftToRedeem * 1e18 / c.dolaIOUsRedeemed;

        //1.2%
        uint dolaBal = IERC20(DOLA).balanceOf(address(this));
        if (redeemableIOUsPct <= .012e18 && dolaLeftToRedeem <= dolaBal) {
            conversions[msg.sender][_conversion].dolaIOUsRedeemed += dolaIOUsLeftToRedeem;

            _burn(msg.sender, dolaIOUsLeftToRedeem);
            require(IERC20(DOLA).transfer(msg.sender, dolaLeftToRedeem), "DOLA transfer failed");
            emit Redemption(msg.sender, dolaLeftToRedeem);
        }
    }

    function redeemAll(uint _conversion) external {
        redeemConversion(_conversion, 0);
        redeemConversionDust(_conversion);
    }

    /*
     * @notice function for accounting interest of DOLA IOU tokens. Called by convert(), repayment(), and redeem().
     * @dev only will apply rate increase once per block.
     */
    function accrueInterest() public {
        if(block.timestamp != lastAccrueInterestTimestamp && exchangeRateIncreasePerSecond > 0) {
            uint rateIncrease = (block.timestamp - lastAccrueInterestTimestamp) * exchangeRateIncreasePerSecond;
            exchangeRateMantissa += rateIncrease;
            uint newDebt = rateIncrease * totalSupply() / 1e18;
            cumDebt += newDebt;
            outstandingDebt  += newDebt;
            lastAccrueInterestTimestamp = block.timestamp;
        }
    }

    /*
     * @notice function for calculating redeemable DOLA IOUs of an account
     * @param _addr Address to view redeemable DOLA IOUs of
     * @param _conversion index of conversion to calculate redeemable DOLA IOUs for
     * @param _epoch repayment epoch to calculate redeemable DOLA IOUs of
     */
    function getRedeemableDolaIOUsFor(address _addr, uint _conversion, uint _epoch) public view returns (uint) {
        ConversionData memory c = conversions[_addr][_conversion];
        uint userRedeemedIOUs = c.dolaIOUsRedeemed;
        uint userConvertedIOUs = c.dolaIOUAmount;
        uint dolaIOUsRemaining = userConvertedIOUs - userRedeemedIOUs;

        uint totalDolaIOUsRedeemable = (repayments[_epoch].pctDolaIOUsRedeemable * userConvertedIOUs / 1e18);

        if (dolaIOUsRemaining >= totalDolaIOUsRedeemable) {
            return totalDolaIOUsRedeemable;
        } else {
            return dolaIOUsRemaining;
        }
    }

    /*
     * @notice function for calculating amount of DOLA equal to a given DOLA IOU amount.
     * @param dolaIOUs DOLA IOU amount to be converted to DOLA
     */
    function convertDolaIOUsToDola(uint dolaIOUs) public view returns (uint) {
        return dolaIOUs * exchangeRateMantissa / 1e18;
    }

    /*
     * @notice function for calculating amount of DOLA IOUs equal to a given DOLA amount.
     * @param dola DOLA amount to be converted to DOLA IOUs
     */
    function convertDolaToDolaIOUs(uint dola) public view returns (uint) {
        return dola * 1e18 / exchangeRateMantissa;
    }

    /*
     * @notice function for calculating amount of DOLA redeemable for an addresses' DOLA IOU balance
     * @param addr Address to return balance of
     */
    function balanceOfDola(address _addr) external view returns (uint) {
        return convertDolaIOUsToDola(balanceOf(_addr));
    }

    // Revert if `to` address is not whitelisted. Transfers between users are not enabled.
    function transfer(address to, uint amount) public override returns (bool) {
        if (!transferWhitelist[to]) revert TransferToAddressNotWhitelisted();

        return super.transfer(to, amount);
    }

    // Revert if `to` address is not whitelisted. Transfers between users are not enabled.
    function transferFrom(address from, address to, uint amount) public override returns (bool) {
        if (!transferWhitelist[to]) revert TransferToAddressNotWhitelisted();

        return super.transferFrom(from, to, amount);
    }

    /*
     * @notice function for transferring `amount` of `token` to the `treasury` address from this contract
     * @param token Address of the token to be transferred out of this contract
     * @param amount Amount of `token` to be transferred out of this contract, 0 = max
     */
    function sweepTokens(address token, uint amount) external onlyGovernance {
        if (amount == 0) { 
            require(IERC20(token).transfer(treasury, IERC20(token).balanceOf(address(this))), "Token transfer failed");
        } else {
            require(IERC20(token).transfer(treasury, amount), "Token transfer failed");
        }
    }

    /*
     * @notice function for setting rate at which `exchangeRateMantissa` increases every year
     * @param increasePerYear The amount `exchangeRateMantissa` will increase every year. 1e18 is the default exchange rate.
     */
    function setExchangeRateIncrease(uint increasePerYear) external onlyGovernance {
        accrueInterest();
        exchangeRateIncreasePerSecond = increasePerYear / 365 days;
        
        emit NewAnnualExchangeRateIncrease(increasePerYear);
    }

    /*
     * @notice function for setting maximum price this contract will pay for 1 underlying of the anToken
     * @param anToken address of the anToken to set maxConvertPrice[anToken]
     * @param maxPrice maximum price this contract will pay for 1 underlying of `anToken`
     */
    function setMaxConvertPrice(address anToken, uint maxPrice) external onlyOwner {
        maxConvertPrice[anToken] = maxPrice;
        
        emit NewMaxConvertPrice(anToken, maxPrice);
    }

    /*
     * @notice function for setting owner address.
     * @param newOwner Address that will become the new owner of the contract.
     */
    function setOwner(address newOwner) external onlyGovernance {
        owner = newOwner;

        emit NewOwner(newOwner);
    }

    /*
     * @notice function for setting treasury address.
     * @param newTreasury Address that will be set as the new treasury of the contract.
     */
    function setTreasury(address newTreasury) external onlyGovernance {
        treasury = newTreasury;

        emit NewTreasury(newTreasury);
    }

    /*
     * @notice function for setting governance address.
     * @param newGovernance Address that will be set as the new treasury of the contract.
     */
    function setGovernance(address newGovernance) external onlyGovernance {
        governance = newGovernance;

        emit NewGovernance(newGovernance);
    }

    /*
     * @notice function for whitelisting IOU token transfers to certain addresses.
     * @param whitelistedAddress Address to be added to whitelist. IOU tokens will be able to be transferred to this address.
     */
    function whitelistTransferFor(address whitelistedAddress) external onlyOwner {
        transferWhitelist[whitelistedAddress] = true;

        emit NewTransferWhitelistAddress(whitelistedAddress);
    }
}
