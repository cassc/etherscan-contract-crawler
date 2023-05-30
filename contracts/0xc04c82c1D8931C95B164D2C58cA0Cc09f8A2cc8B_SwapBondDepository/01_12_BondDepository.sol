// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./external/Ownable.sol";
import "./interface/IERC20Metadata.sol";
import "./interface/IBondingCalculator.sol";
import "./library/SafeMath.sol";
import "./library/SafeERC20.sol";
import "./library/FixedPoint.sol";

contract SwapBondDepository is Ownable, ReentrancyGuard {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable SWAP; // token given as payment for bond
    address public immutable principal; // token used to create bond
    address public immutable treasury; // mints SWAP when receives principal
    address public immutable DAO; // receives profit share from bond

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public immutable bondCalculator; // calculates value of LP tokens
    address private pairAddressSwap;
    address private pairAddressPrinciple;

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( uint => mapping(address => Bond)) public bondInfo; // stores bond information for depositors
    mapping( address => bool ) public whitelist; // stores whitelist for minters

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference timestamp for debt decay
    uint public constant CONTROL_VARIABLE_PRECISION = 10_000;


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price, in hundreths
        uint[] vestingTerm; // in time
        uint minimumPrice; // vs principal value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint[] fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint payout; // SWAP remaining to be paid
        uint vesting; // Time left to vest
        uint lastTimestamp; // Last interaction
        uint pricePaid; // In USDT, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in blocks) between adjustments
        uint lastTimestamp; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( 
        address _SWAP,
        address _principal,
        address _treasury, 
        address _DAO, 
        address _bondCalculator,
        address _pairAddressSwap,
        address _pairAddressPrinciple
    ) {
        require( _SWAP != address(0) );
        SWAP = _SWAP;
        require( _principal != address(0) );
        principal = _principal;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        pairAddressSwap = _pairAddressSwap;
        pairAddressPrinciple = _pairAddressPrinciple;
        isLiquidityBond = ( _bondCalculator != address(0) );
        whitelist[_msgSender()] = true;
    }

    /**
     *  @notice whitelist modifier
     */
    modifier onlyWhitelisted() {
        require(whitelist[_msgSender()], "Not Whitelisted");
        _;
    }

    /**
     *  @notice contract checker modifier
     */
    modifier notContract(address _addr) {
        require(!isContract(_addr), "Contract address");
        _;
    }

    /**
     *  @notice update whitelist
     *  @param _target address
     *  @param _value bool
     */
    function updateWhitelist(address _target, bool _value) external onlyOwner {
        whitelist[_target] = _value;
    }

    /**
     *  @notice update pair address
     *  @param _pair address
     */
    function updatePairAddress(address _pair, bool _swap) external onlyOwner {
        if (_swap) {
            pairAddressSwap = _pair;
        } else {
            pairAddressPrinciple = _pair;
        }
    }

    /**
     *  @notice update whitelistfor multiple addresses
     *  @param _target address[]
     *  @param _value bool[]
     */
    function updateBatchWhitelist(address[] calldata _target, bool[] calldata _value) external onlyOwner {
        require(_target.length == _value.length, "Invalid request");
        for (uint256 index = 0; index < _target.length; index++) {
            whitelist[_target[index]] = _value[index];
        }
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms( 
        uint _controlVariable, 
        uint[] calldata _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint[] calldata _fee,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyOwner {
        require( terms.controlVariable == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input, uint _term ) external onlyOwner {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 3, "Vesting must be longer than 3 days" );
            terms.vestingTerm[_term] = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee[_term] = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
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
    function setAdjustment ( 
        bool _addition,
        uint _increment, 
        uint _target,
        uint _buffer 
    ) external onlyOwner {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTimestamp: block.timestamp
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
    function deposit( 
        uint _amount, 
        uint _maxPrice,
        address _depositor,
        uint _term
    ) external onlyWhitelisted nonReentrant notContract(_msgSender()) returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );

        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
        uint priceInUSD = bondPriceInUSD(_term); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = tokenValue( principal, _amount );

        require( value >= 1e16, "Bond too small" ); // must be > 0.01 SWAP ( underflow protection )
        require( value <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint payout = value.mul( nativePrice ).div( priceInUSD );

        /**
            principal is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) SWAP
         */
        IERC20( principal ).safeTransferFrom( msg.sender, address( treasury ), _amount );

        IERC20( SWAP ).safeTransferFrom(address( treasury ), address(this), payout);

        // total debt is increased
        totalDebt = totalDebt.add( value ); 
                
        // depositor info is stored
        bondInfo[_term][ _depositor ] = Bond({ 
            payout: bondInfo[_term][ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm[_term] * 1 days,
            lastTimestamp: block.timestamp,
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm[_term] * 1 days ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(_term), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */ 
    function redeem( address _recipient, uint _term ) external onlyWhitelisted nonReentrant notContract(_msgSender()) returns ( uint ) {        
        Bond memory info = bondInfo[_term][ _recipient ];
        uint percentVested = percentVestedFor( _recipient, _term ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 1e9 ) { // if fully vested
            delete bondInfo[_term][ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return sendTo( _recipient, info.payout ); // pay user everything due
        }
    }


    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to payout automatically
     *  @param _amount uint
     *  @return uint
     */
    function sendTo( address _recipient, uint _amount ) internal returns ( uint ) {
        IERC20( SWAP ).transfer( _recipient, _amount ); // send payout
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint blockCanAdjust = adjustment.lastTimestamp.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= blockCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTimestamp = block.timestamp;
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt;
        lastDecay = block.timestamp;
    }


    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice contract checker viewer
     */
    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( SWAP ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() internal view returns ( uint price_ ) {
        uint bondTokenPrice;
        if (pairAddressPrinciple != address(0)) {
            bondTokenPrice = IBondingCalculator( bondCalculator ).getBondTokenPrice( pairAddressSwap, pairAddressPrinciple );
        } else {
            bondTokenPrice = IBondingCalculator( bondCalculator ).getBondTokenPrice( pairAddressSwap );
        }
        price_ = CONTROL_VARIABLE_PRECISION.sub(terms.controlVariable).mul(bondTokenPrice).div(CONTROL_VARIABLE_PRECISION);

        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        if (pairAddressPrinciple != address(0)) {
            price_ = IBondingCalculator( bondCalculator ).getBondTokenPrice( pairAddressSwap, pairAddressPrinciple );
        } else {
            price_ = IBondingCalculator( bondCalculator ).getBondTokenPrice( pairAddressSwap );
        }
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     * @notice returns SWAP valuation of asset
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function tokenValue(address _token, uint256 _amount) internal view returns (uint256 value_) {
        if ( !isLiquidityBond ) {
            // convert amount to match SWAP decimals
            value_ = _amount.mul( 10 ** IERC20Metadata( SWAP ).decimals() ).div( 10 ** IERC20Metadata( _token ).decimals() );
        } else {
            if (pairAddressPrinciple != address(0)) {
                value_ = IBondingCalculator( bondCalculator ).getPrincipleTokenValue( pairAddressSwap, pairAddressPrinciple, _amount );
            } else {
                value_ = IBondingCalculator( bondCalculator ).getPrincipleTokenValue( pairAddressSwap, _amount );
            }
        }
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD(uint _term) public view returns ( uint price_ ) {
        if( isLiquidityBond ) {
            price_ = bondPrice().mul( CONTROL_VARIABLE_PRECISION - terms.fee[_term] ).div( CONTROL_VARIABLE_PRECISION );
        } else {
            price_ = bondPrice().mul( 10 ** IERC20Metadata( principal ).decimals() ).div( 100 );
        }
    }

    /**
     *  @notice calculate current ratio of debt to SWAP supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( SWAP ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt;
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor, uint _term ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[_term][ _depositor ];
        uint blocksSinceLast = block.timestamp.sub( bond.lastTimestamp );
        uint vesting = bond.vesting;

        if ( vesting > 0 && blocksSinceLast >= vesting ) {
            percentVested_ = 1e9;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of SWAP available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor, uint _term ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor, _term );
        uint payout = bondInfo[_term][ _depositor ].payout;

        if ( percentVested >= 1e9 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 1e9 );
        }
    }


    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principal or SWAP) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != SWAP );
        require( _token != principal );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}