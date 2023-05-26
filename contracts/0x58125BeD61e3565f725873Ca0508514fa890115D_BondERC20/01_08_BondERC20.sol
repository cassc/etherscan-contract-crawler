import "./libraries/SafeMath.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import "./interface/IHATETreasury.sol";

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

contract BondERC20 {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /* ======== EVENTS ======== */

    event BondCreated(uint deposit, uint payout, uint expires);
    event BondRedeemed(address recipient, uint payout, uint remaining);
    event BondPriceChanged(uint internalPrice, uint debtRatio);
    event ControlVariableAdjustment(uint initialBCV, uint newBCV, uint adjustment, bool addition);

    /* ======== STATE VARIABLES ======== */

    address public owner;

    IERC20 private immutable HATE; // token paid for principal
    IERC20 private immutable principalToken; // inflow token
    IHATETreasury private immutable treasury; // pays for and receives principal

    address public feeTo;
    // in thousandths of a %. i.e. 500 = 0.5%
    uint public feePercent;

    uint public totalPrincipalBonded;
    uint public totalPayoutGiven;
    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference timestamp for debt decay

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in seconds
        uint minimumPrice; // vs principal value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // payout token decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint payout; // payout token remaining to be paid
        uint vesting; // seconds left to vest
        uint lastBlockTimestamp; // Last interaction
        uint truePricePaid; // Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in seconds) between adjustments
        uint lastBlockTimestamp; // timestamp when last adjustment made
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(address _treasury, address _principalToken) {
        require(_treasury != address(0));
        treasury = IHATETreasury(_treasury);
        HATE = IERC20(IHATETreasury(_treasury).HATE());
        require(_principalToken != address(0));
        principalToken = IERC20(_principalToken);
        owner = msg.sender;
    }

    /* ======== INITIALIZATION ======== */

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBond(
        uint _controlVariable,
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyOwner {
        require(currentDebt() == 0, "Debt must be 0 for initialization");
        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setFeeAndFeeTo(address feeTo_, uint256 feePercent_) external onlyOwner {
        feeTo = feeTo_;
        feePercent = feePercent_;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    enum PARAMETER {
        VESTING,
        PAYOUT,
        DEBT
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint _input) external onlyOwner {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 129600, "Vesting must be longer than 36 hours");
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {
            // 1
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 2
            terms.maxDebt = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(bool _addition, uint _increment, uint _target, uint _buffer) external onlyOwner {
        require(_increment <= terms.controlVariable.mul(30).div(1000), "Increment too large");

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlockTimestamp: block.timestamp
        });
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint) {
        require(_depositor != address(0), "Invalid address");

        decayDebt();

        uint nativePrice = bondPrice();

        require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

        uint value = treasury.valueOfToken(address(principalToken), _amount);

        uint payout = payoutFor(value);

        require(payout >= 10 ** HATE.decimals() / 100, "Bond too small"); // must be > 0.01 payout token ( underflow protection )
        require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // total debt is increased
        totalDebt = totalDebt.add(value);

        require(totalDebt <= terms.maxDebt, "Max capacity reached");

        // depositor info is stored
        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: terms.vestingTerm,
            lastBlockTimestamp: block.timestamp,
            truePricePaid: bondPrice()
        });

        totalPrincipalBonded = totalPrincipalBonded.add(_amount); // total bonded increased
        totalPayoutGiven = totalPayoutGiven.add(payout); // total payout increased

        treasury.mintHATE(address(this), payout);

        if (feeTo != address(0) && feePercent > 0) {
            uint256 _fee = payout.mul(feePercent).div(100000);
            treasury.mintHATE(feeTo, _fee);
        }

        principalToken.safeTransferFrom(msg.sender, address(treasury), _amount); // transfer principal bonded to custom treasury

        // indexed events are emitted
        emit BondCreated(_amount, payout, block.timestamp.add(terms.vestingTerm));
        emit BondPriceChanged(_bondPrice(), debtRatio());

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _depositor address
     *  @return uint
     */
    function redeem(address _depositor) external returns (uint) {
        Bond memory info = bondInfo[_depositor];
        uint percentVested = percentVestedFor(_depositor); // (seconds since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_depositor]; // delete user info
            emit BondRedeemed(_depositor, info.payout, 0); // emit bond data
            HATE.safeTransfer(_depositor, info.payout);
            return info.payout;
        } else {
            // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul(percentVested).div(10000);

            // store updated deposit info
            bondInfo[_depositor] = Bond({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.timestamp.sub(info.lastBlockTimestamp)),
                lastBlockTimestamp: block.timestamp,
                truePricePaid: info.truePricePaid
            });

            emit BondRedeemed(_depositor, payout, bondInfo[_depositor].payout);
            HATE.safeTransfer(_depositor, payout);
            return payout;
        }
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timestampCanAdjust = adjustment.lastBlockTimestamp.add(adjustment.buffer);
        if (adjustment.rate != 0 && block.timestamp >= timestampCanAdjust) {
            uint initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(adjustment.rate);
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlockTimestamp = block.timestamp;
            emit ControlVariableAdjustment(initial, terms.controlVariable, adjustment.rate, adjustment.add);
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.timestamp;
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns (uint price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(10 ** (uint256(HATE.decimals()).sub(5)));
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        } else if (terms.minimumPrice != 0) {
            terms.minimumPrice = 0;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(10 ** (uint256(HATE.decimals()).sub(5)));
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        return HATE.totalSupply().mul(terms.maxPayout).div(100000);
    }

    /*
     *  @param _value uint
     *  @return _payout uint
     */
    function payoutFor(uint _value) public view returns (uint _payout) {
        _payout = FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e9);
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint debtRatio_) {
        debtRatio_ = FixedPoint
            .fraction(currentDebt().mul(10 ** HATE.decimals()), HATE.totalSupply())
            .decode112with18()
            .div(1e18);
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint decay_) {
        uint timestampSinceLast = block.timestamp.sub(lastDecay);
        decay_ = totalDebt.mul(timestampSinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view returns (uint percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint timestampSinceLast = block.timestamp.sub(bond.lastBlockTimestamp);
        uint vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = timestampSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint pendingPayout_) {
        uint percentVested = percentVestedFor(_depositor);
        uint payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }
}