//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./MorpherState.sol";
import "./MorpherToken.sol";
import "./MorpherStaking.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherMintingLimiter.sol";
import "./MorpherAccessControl.sol";

// ----------------------------------------------------------------------------------
// Tradeengine of the Morpher platform
// Creates and processes orders, and computes the state change of portfolio.
// Needs writing/reading access to/from Morpher State. Order objects are stored locally,
// portfolios are stored in state.
// ----------------------------------------------------------------------------------

contract MorpherTradeEngine is Initializable, ContextUpgradeable {
    MorpherState public morpherState;

    /**
     * Known Roles to Trade Engine
     */
    
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant POSITIONADMIN_ROLE = keccak256("POSITIONADMIN_ROLE"); //can set and modify positions

// ----------------------------------------------------------------------------
// Precision of prices and leverage
// ----------------------------------------------------------------------------
    uint256 constant PRECISION = 10**8;
    uint256 public orderNonce;
    bytes32 public lastOrderId;
    uint256 public deployedTimeStamp;

    bool public escrowOpenOrderEnabled;

    struct PriceLock {
        uint lockedPrice;
    }
    //we're locking positions in for this price at a market marketId;
    mapping(bytes32 => PriceLock) public priceLockDeactivatedMarket;


// ----------------------------------------------------------------------------
// Order struct contains all order specific varibles. Variables are completed
// during processing of trade. State changes are saved in the order struct as
// well, since local variables would lead to stack to deep errors *sigh*.
// ----------------------------------------------------------------------------
    struct order {
        address userId;
        bytes32 marketId;
        uint256 closeSharesAmount;
        uint256 openMPHTokenAmount;
        bool tradeDirection; // true = long, false = short
        uint256 liquidationTimestamp;
        uint256 marketPrice;
        uint256 marketSpread;
        uint256 orderLeverage;
        uint256 timeStamp;
        uint256 orderEscrowAmount;
        OrderModifier modifyPosition;
    }

    struct OrderModifier {
        uint256 longSharesOrder;
        uint256 shortSharesOrder;
        uint256 balanceDown;
        uint256 balanceUp;
        uint256 newLongShares;
        uint256 newShortShares;
        uint256 newMeanEntryPrice;
        uint256 newMeanEntrySpread;
        uint256 newMeanEntryLeverage;
        uint256 newLiquidationPrice;
    }


    mapping(bytes32 => order) public orders;

     // ----------------------------------------------------------------------------
    // Position struct records virtual futures
    // ----------------------------------------------------------------------------
    struct position {
        uint256 lastUpdated;
        uint256 longShares;
        uint256 shortShares;
        uint256 meanEntryPrice;
        uint256 meanEntrySpread;
        uint256 meanEntryLeverage;
        uint256 liquidationPrice;
        bytes32 positionHash;
    }

    // ----------------------------------------------------------------------------
    // A portfolio is an address specific collection of postions
    // ----------------------------------------------------------------------------
    mapping(address => mapping(bytes32 => position)) public portfolio;

    // ----------------------------------------------------------------------------
    // Record all addresses that hold a position of a market, needed for clean stock splits
    // ----------------------------------------------------------------------------
    struct hasExposure {
        uint256 maxMappingIndex;
        mapping(address => uint256) index;
        mapping(uint256 => address) addy;
    }

    mapping(bytes32 => hasExposure) public exposureByMarket;

// ----------------------------------------------------------------------------
// Events
// Order created/processed events are fired by MorpherOracle.
// ----------------------------------------------------------------------------

    event PositionLiquidated(
        address indexed _address,
        bytes32 indexed _marketId,
        bool _longPosition,
        uint256 _timeStamp,
        uint256 _marketPrice,
        uint256 _marketSpread
    );

    event OrderCancelled(
        bytes32 indexed _orderId,
        address indexed _address
    );

    event OrderIdRequested(
        bytes32 _orderId,
        address indexed _address,
        bytes32 indexed _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
    );

    event OrderProcessed(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newAverageEntry,
        uint256 _newAverageSpread,
        uint256 _newAverageLeverage,
        uint256 _liquidationPrice
    );

    event PositionUpdated(
        address _userId,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newMeanEntryPrice,
        uint256 _newMeanEntrySpread,
        uint256 _newMeanEntryLeverage,
        uint256 _newLiquidationPrice,
        uint256 _mint,
        uint256 _burn
    );

    event SetPosition(
        bytes32 indexed positionHash,
        address indexed sender,
        bytes32 indexed marketId,
        uint256 timeStamp,
        uint256 longShares,
        uint256 shortShares,
        uint256 meanEntryPrice,
        uint256 meanEntrySpread,
        uint256 meanEntryLeverage,
        uint256 liquidationPrice
    );

    
    event EscrowPaid(bytes32 orderId, address user, uint escrowAmount);
    event EscrowReturned(bytes32 orderId, address user, uint escrowAmount);

    event LinkState(address _address);
    
    event LockedPriceForClosingPositions(bytes32 _marketId, uint256 _price);

    function initialize(address _stateAddress, bool _escrowOpenOrderEnabled, uint256 _deployedTimestampOverride) public initializer {
        ContextUpgradeable.__Context_init();

        morpherState = MorpherState(_stateAddress);
        escrowOpenOrderEnabled = _escrowOpenOrderEnabled;
        deployedTimeStamp = _deployedTimestampOverride > 0 ? _deployedTimestampOverride : block.timestamp;
    }

    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(morpherState.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherTradeEngine: Permission denied.");
        _;
    }


// ----------------------------------------------------------------------------
// Administrative functions
// Set state address, get administrator address
// ----------------------------------------------------------------------------

    function setMorpherState(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        morpherState = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function setEscrowOpenOrderEnabled(bool _isEnabled) public onlyRole(ADMINISTRATOR_ROLE) {
        escrowOpenOrderEnabled = _isEnabled;
    }
    
    function paybackEscrow(bytes32 _orderId) private {
        //pay back the escrow to the user so he has it back on his balance/**
        if(orders[_orderId].orderEscrowAmount > 0) {
            //checks effects interaction
            uint256 paybackAmount = orders[_orderId].orderEscrowAmount;
            orders[_orderId].orderEscrowAmount = 0;
            MorpherToken(morpherState.morpherTokenAddress()).mint(orders[_orderId].userId, paybackAmount);
            emit EscrowReturned(_orderId, orders[_orderId].userId, paybackAmount);
        }
    }

    function buildupEscrow(bytes32 _orderId, uint256 _amountInMPH) private {
        if(escrowOpenOrderEnabled && _amountInMPH > 0) {
            MorpherToken(morpherState.morpherTokenAddress()).burn(orders[_orderId].userId, _amountInMPH);
            emit EscrowPaid(_orderId, orders[_orderId].userId, _amountInMPH);
            orders[_orderId].orderEscrowAmount = _amountInMPH;
        }
    }


    function validateClosedMarketOrderConditions(address _address, bytes32 _marketId, uint256 _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection ) internal view {
        //markets active? Still tradeable?
        if(_openMPHTokenAmount > 0) {
            require(morpherState.getMarketActive(_marketId) == true, "MorpherTradeEngine: market unknown or currently not enabled for trading.");
        } else {
            //we're just closing a position, but it needs a forever price locked in if market is not active
            //the user needs to close his complete position
            if(morpherState.getMarketActive(_marketId) == false) {
                require(getDeactivatedMarketPrice(_marketId) > 0, "MorpherTradeEngine: Can't close a position, market not active and closing price not locked");
                if(_tradeDirection) {
                    //long
                    require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                } else {
                    //short
                    require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                }
            }
        }
    }

    //wrapper for stack too deep errors
    function validateClosedMarketOrder(bytes32 _orderId) internal view {
         validateClosedMarketOrderConditions(orders[_orderId].userId, orders[_orderId].marketId, orders[_orderId].closeSharesAmount, orders[_orderId].openMPHTokenAmount, orders[_orderId].tradeDirection);
    }

// ----------------------------------------------------------------------------
// requestOrderId(address _address, bytes32 _marketId, bool _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection, uint256 _orderLeverage)
// Creates a new order object with unique orderId and assigns order information.
// Must be called by MorpherOracle contract.
// ----------------------------------------------------------------------------

    function requestOrderId(
        address _address,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
        ) public onlyRole(ORACLE_ROLE) returns (bytes32 _orderId) {
            
        require(_orderLeverage >= PRECISION, "MorpherTradeEngine: leverage too small. Leverage precision is 1e8");
        require(_orderLeverage <= morpherState.getMaximumLeverage(), "MorpherTradeEngine: leverage exceeds maximum allowed leverage.");

        validateClosedMarketOrderConditions(_address, _marketId, _closeSharesAmount, _openMPHTokenAmount, _tradeDirection);

        //request limits
        //@todo: fix request limit: 3 requests per block

        /**
         * The user can't partially close a position and open another one with MPH
         */
        if(_openMPHTokenAmount > 0) {

            if(_tradeDirection) {
                //long
                require(_closeSharesAmount == portfolio[_address][_marketId].shortShares, "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            } else {
                //short
                require(_closeSharesAmount == portfolio[_address][_marketId].longShares, "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            }
        }

        orderNonce++;
        _orderId = keccak256(
            abi.encodePacked(
                _address,
                block.number,
                _marketId,
                _closeSharesAmount,
                _openMPHTokenAmount,
                _tradeDirection,
                _orderLeverage,
                orderNonce
                )
            );
        lastOrderId = _orderId;
        orders[_orderId].userId = _address;
        orders[_orderId].marketId = _marketId;
        orders[_orderId].closeSharesAmount = _closeSharesAmount;
        orders[_orderId].openMPHTokenAmount = _openMPHTokenAmount;
        orders[_orderId].tradeDirection = _tradeDirection;
        orders[_orderId].orderLeverage = _orderLeverage;
        emit OrderIdRequested(
            _orderId,
            _address,
            _marketId,
            _closeSharesAmount,
            _openMPHTokenAmount,
            _tradeDirection,
            _orderLeverage
        );

        /**
         * put the money in escrow here if given MPH to open an order
         * - also, can only close positions if in shares, so it will
         * definitely trigger a mint there.
         * The money must be put in escrow even though we have an existing position
         */
        buildupEscrow(_orderId, _openMPHTokenAmount);

        return _orderId;
    }

// ----------------------------------------------------------------------------
// Getter functions for orders, shares, and positions
// ----------------------------------------------------------------------------

    function getOrder(bytes32 _orderId) public view returns (
        address _userId,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage
        ) {
        return(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].closeSharesAmount,
            orders[_orderId].openMPHTokenAmount,
            orders[_orderId].marketPrice,
            orders[_orderId].marketSpread,
            orders[_orderId].orderLeverage
            );
    }

    function setDeactivatedMarketPrice(bytes32 _marketId, uint256 _price) public onlyRole(ADMINISTRATOR_ROLE) {
         priceLockDeactivatedMarket[_marketId].lockedPrice = _price;
        emit LockedPriceForClosingPositions(_marketId, _price);

    }

    function getDeactivatedMarketPrice(bytes32 _marketId) public view returns(uint256) {
        return priceLockDeactivatedMarket[_marketId].lockedPrice;
    }

// ----------------------------------------------------------------------------
// liquidate(bytes32 _orderId)
// Checks for bankruptcy of position between its last update and now
// Time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function liquidate(bytes32 _orderId) private {
        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _liquidationTimestamp = orders[_orderId].liquidationTimestamp;
        if (_liquidationTimestamp > portfolio[_address][ _marketId].lastUpdated) {
            if (portfolio[_address][_marketId].longShares > 0) {
                setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    0,
                    portfolio[_address][ _marketId].shortShares,
                    0,
                    0,
                    PRECISION,
                    0);
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    true,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
            if (portfolio[_address][_marketId].shortShares > 0) {
                setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    portfolio[_address][_marketId].longShares,
                    0,
                    0,
                    0,
                    PRECISION,
                    0
                );
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    false,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
        }
    }

// ----------------------------------------------------------------------------
// processOrder(bytes32 _orderId, uint256 _marketPrice, uint256 _marketSpread, uint256 _liquidationTimestamp, uint256 _timeStamp)
// ProcessOrder receives the price/spread/liqidation information from the Oracle and
// triggers the processing of the order. If successful, processOrder updates the portfolio state.
// Liquidation time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function processOrder(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStampInMS
        ) public onlyRole(ORACLE_ROLE) returns (position memory) {
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order has been deleted.");
        require(_marketPrice > 0, "MorpherTradeEngine: market priced at zero. Buy order cannot be processed.");
        require(_marketPrice >= _marketSpread, "MorpherTradeEngine: market price lower then market spread. Order cannot be processed.");
        
        orders[_orderId].marketPrice = _marketPrice;
        orders[_orderId].marketSpread = _marketSpread;
        orders[_orderId].timeStamp = _timeStampInMS;
        orders[_orderId].liquidationTimestamp = _liquidationTimestamp;
        
        /**
        * If the market is deactivated, then override the price with the locked in market price
        * if the price wasn't locked in: error out.
        */
        if(morpherState.getMarketActive(orders[_orderId].marketId) == false) {
            validateClosedMarketOrder(_orderId);
            orders[_orderId].marketPrice = getDeactivatedMarketPrice(orders[_orderId].marketId);
        }
        
        // Check if previous position on that market was liquidated
        if (_liquidationTimestamp > portfolio[orders[_orderId].userId][ orders[_orderId].marketId].lastUpdated) {
            liquidate(_orderId);
        } else {
            require(!MorpherUserBlocking(morpherState.morpherUserBlockingAddress()).userIsBlocked(orders[_orderId].userId), "MorpherTradeEngine: User is blocked from Trading");
        }
    

        paybackEscrow(_orderId);

        if (orders[_orderId].tradeDirection) {
            processBuyOrder(_orderId);
        } else {
            processSellOrder(_orderId);
        }

        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        delete orders[_orderId];
        emit OrderProcessed(
            _orderId,
            _marketPrice,
            _marketSpread,
            _liquidationTimestamp,
            _timeStampInMS,
            portfolio[_address][_marketId].longShares,
            portfolio[_address][_marketId].shortShares,
            portfolio[_address][_marketId].meanEntryPrice,
            portfolio[_address][_marketId].meanEntrySpread,
            portfolio[_address][_marketId].meanEntryLeverage,
            portfolio[_address][_marketId].liquidationPrice
        );

        return portfolio[_address][_marketId];
    }

// ----------------------------------------------------------------------------
// function cancelOrder(bytes32 _orderId, address _address)
// Users or Administrator can delete pending orders before the callback went through
// ----------------------------------------------------------------------------
    function cancelOrder(bytes32 _orderId, address _address) public onlyRole(ORACLE_ROLE) {
        require(_address == orders[_orderId].userId || MorpherAccessControl(morpherState.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, _address), "MorpherTradeEngine: only Administrator or user can cancel an order.");
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order does not exist.");

        /**
         * Pay back any escrow there
         */
        paybackEscrow(_orderId);

        delete orders[_orderId];
        emit OrderCancelled(_orderId, _address);
    }

// ----------------------------------------------------------------------------
// shortShareValue / longShareValue compute the value of a virtual future
// given current price/spread/leverage of the market and mean price/spread/leverage
// at the beginning of the trade
// ----------------------------------------------------------------------------
    function shortShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New short position
            // It costs marketPrice + marketSpread to build up a new short position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            getLiquidationPrice(_averagePrice, _averageLeverage, false, _positionTimeStampInMs) <= _marketPrice
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            // The regular share value is 2x the entry price minus the current price for short positions.
            _shareValue = _averagePrice * (PRECISION + _averageLeverage) / PRECISION;
            _shareValue = _shareValue - _marketPrice * _averageLeverage / PRECISION;
            if (_sell == true) {
                // We have to reduce the share value by the average spread (i.e. the average expense to build up the position)
                // and reduce the value further by the spread for selling.
                _shareValue = _shareValue- _marketSpread * _averageLeverage / PRECISION;
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue - (_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // If a new short position is built up each share costs value + spread
                _shareValue = _shareValue + (_marketSpread * (_orderLeverage) / (PRECISION));
            }
        }
      
        return _shareValue;
    }

    function longShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New long position
            // It costs marketPrice + marketSpread to build up a new long position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            _marketPrice <= getLiquidationPrice(_averagePrice, _averageLeverage, true, _positionTimeStampInMs)
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            _shareValue = _averagePrice * (_averageLeverage - PRECISION) / (PRECISION);
            // The regular share value is market price times leverage minus entry price times entry leverage minus one.
            _shareValue = (_marketPrice * _averageLeverage / PRECISION) - _shareValue;
            if (_sell == true) {
                // We sell a long and have to correct the shareValue with the averageSpread and the currentSpread for selling.
                _shareValue = _shareValue - (_marketSpread * _averageLeverage / PRECISION);
                
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue - (_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // We buy a new long position and have to pay the spread
                _shareValue = _shareValue + (_marketSpread * (_orderLeverage) / (PRECISION));
            }
        }
        return _shareValue;
    }

// ----------------------------------------------------------------------------
// calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStamp)
// Calculates the interest for leveraged positions
// ----------------------------------------------------------------------------


    function calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStampInMs) public view returns (uint256) {
        uint _marginInterest;
        if (_positionTimeStampInMs / 1000 < deployedTimeStamp) {
            _positionTimeStampInMs = deployedTimeStamp / 1000;
        }
        uint interestRate = MorpherStaking(morpherState.morpherStakingAddress()).getInterestRate(_positionTimeStampInMs / 1000);
        _marginInterest = _averagePrice * (_averageLeverage - PRECISION);
        _marginInterest = _marginInterest * ((block.timestamp - (_positionTimeStampInMs / 1000)) / 86400) + 1;
        _marginInterest = ((_marginInterest * interestRate) / PRECISION) / PRECISION;
        return _marginInterest;
    }

// ----------------------------------------------------------------------------
// processBuyOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of short shares that are sold and long shares that are bought.
// long shares are bought only if the order amount exceeds all open short positions
// ----------------------------------------------------------------------------

    function processBuyOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

             // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares) {
                // Partial closing of short position
                orders[_orderId].modifyPosition.shortSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire short position
                orders[_orderId].modifyPosition.shortSharesOrder = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares;
            }
        }

        //calculate the long shares, but only if the old position is completely closed out (if none exist shortSharesOrder = 0)
        if(
            orders[_orderId].modifyPosition.shortSharesOrder == portfolio[orders[_orderId].userId][ orders[_orderId].marketId].shortShares && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
            orders[_orderId].modifyPosition.longSharesOrder = orders[_orderId].openMPHTokenAmount / (
                longShareValue(
                    orders[_orderId].marketPrice,
                    orders[_orderId].orderLeverage,
                    block.timestamp * (1000),
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread,
                    orders[_orderId].orderLeverage,
                    false
            ));
        }

        // Investment equals number of shares now.
        if (orders[_orderId].modifyPosition.shortSharesOrder > 0) {
            closeShort(_orderId);
        }
        if (orders[_orderId].modifyPosition.longSharesOrder > 0) {
            openLong(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// processSellOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of long shares that are sold and short shares that are bought.
// short shares are bought only if the order amount exceeds all open long positions
// ----------------------------------------------------------------------------

    function processSellOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

            // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares) {
                // Partial closing of long position
                orders[_orderId].modifyPosition.longSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire long position
                orders[_orderId].modifyPosition.longSharesOrder = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares;
            }
        }

        if(
            orders[_orderId].modifyPosition.longSharesOrder == portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
        orders[_orderId].modifyPosition.shortSharesOrder = orders[_orderId].openMPHTokenAmount / (
                    shortShareValue(
                        orders[_orderId].marketPrice,
                        orders[_orderId].orderLeverage,
                        block.timestamp * (1000),
                        orders[_orderId].marketPrice,
                        orders[_orderId].marketSpread,
                        orders[_orderId].orderLeverage,
                        false
                ));
        }
        // Investment equals number of shares now.
        if (orders[_orderId].modifyPosition.longSharesOrder > 0) {
            closeLong(_orderId);
        }
        if (orders[_orderId].modifyPosition.shortSharesOrder > 0) {
            openShort(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// openLong(bytes32 _orderId)
// Opens a new long position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorLongShares is a factor to adjust the existing longShares via virtual liqudiation and reopening at current market price

        uint256 _factorLongShares = portfolio[_userId][ _marketId].meanEntryLeverage;
        if (_factorLongShares < PRECISION) {
            _factorLongShares = PRECISION;
        }
        _factorLongShares = _factorLongShares - (PRECISION);
        _factorLongShares = _factorLongShares * (portfolio[_userId][ _marketId].meanEntryPrice) / (orders[_orderId].marketPrice);
        if (portfolio[_userId][ _marketId].meanEntryLeverage > _factorLongShares) {
            _factorLongShares = portfolio[_userId][ _marketId].meanEntryLeverage - (_factorLongShares);
        } else {
            _factorLongShares = 0;
        }

        uint256 _adjustedLongShares = _factorLongShares * (portfolio[_userId][ _marketId].longShares) / (PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage * (_adjustedLongShares);
        _newMeanLeverage = _newMeanLeverage + (orders[_orderId].orderLeverage * (orders[_orderId].modifyPosition.longSharesOrder));
        _newMeanLeverage = _newMeanLeverage / (_adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread * (portfolio[_userId][ _marketId].longShares);
        _newMeanSpread = _newMeanSpread + (orders[_orderId].marketSpread * (orders[_orderId].modifyPosition.longSharesOrder));
        _newMeanSpread = _newMeanSpread / (_adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder));

        orders[_orderId].modifyPosition.balanceDown = orders[_orderId].modifyPosition.longSharesOrder * (orders[_orderId].marketPrice) + (
            orders[_orderId].modifyPosition.longSharesOrder * (orders[_orderId].marketSpread) * (orders[_orderId].orderLeverage) / (PRECISION)
        );
        orders[_orderId].modifyPosition.balanceUp = 0;
        orders[_orderId].modifyPosition.newLongShares = _adjustedLongShares + (orders[_orderId].modifyPosition.longSharesOrder);
        orders[_orderId].modifyPosition.newShortShares = portfolio[_userId][ _marketId].shortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }
// ----------------------------------------------------------------------------
// closeLong(bytes32 _orderId)
// Closes an existing long position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
     function closeLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newLongShares  = portfolio[_userId][ _marketId].longShares - (orders[_orderId].modifyPosition.longSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        if (orders[_orderId].modifyPosition.longSharesOrder == portfolio[_userId][ _marketId].longShares) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
            _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = portfolio[_userId][ _marketId].meanEntryPrice;
	        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread;
	        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage;
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].modifyPosition.balanceDown = 0;
        orders[_orderId].modifyPosition.balanceUp = _balanceUp;
        orders[_orderId].modifyPosition.newLongShares = _newLongShares;
        orders[_orderId].modifyPosition.newShortShares = portfolio[_userId][ _marketId].shortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

event ResetTimestampInOrder(bytes32 _orderId, uint oldTimestamp, uint newTimestamp);
function resetTimestampInOrderToLastUpdated(bytes32 _orderId) internal {
    address userId = orders[_orderId].userId;
    bytes32 marketId = orders[_orderId].marketId;
    uint lastUpdated = portfolio[userId][ marketId].lastUpdated;
    emit ResetTimestampInOrder(_orderId, orders[_orderId].timeStamp, lastUpdated);
    orders[_orderId].timeStamp = lastUpdated;
}

// ----------------------------------------------------------------------------
// closeShort(bytes32 _orderId)
// Closes an existing short position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
function calculateBalanceUp(bytes32 _orderId) private view returns (uint256 _balanceUp) {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _shareValue;

        if (orders[_orderId].tradeDirection == false) { //we are selling our long shares
            _balanceUp = orders[_orderId].modifyPosition.longSharesOrder;
            _shareValue = longShareValue(
                portfolio[_userId][ _marketId].meanEntryPrice,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                portfolio[_userId][ _marketId].lastUpdated,
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                true
            );
        } else { //we are going long, we are selling our short shares
            _balanceUp = orders[_orderId].modifyPosition.shortSharesOrder;
            _shareValue = shortShareValue(
                portfolio[_userId][ _marketId].meanEntryPrice,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                portfolio[_userId][ _marketId].lastUpdated,
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                portfolio[_userId][ _marketId].meanEntryLeverage,
                true
            );
        }
        return _balanceUp * (_shareValue); 
    }

    function closeShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        uint256 _newShortShares = portfolio[_userId][ _marketId].shortShares - (orders[_orderId].modifyPosition.shortSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        
        if (orders[_orderId].modifyPosition.shortSharesOrder == portfolio[_userId][ _marketId].shortShares) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
	        _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = portfolio[_userId][ _marketId].meanEntryPrice;
	        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread;
	        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage;

            /**
             * we need the timestamp of the old order for partial closes, not the new one
             */
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].modifyPosition.balanceDown = 0;
        orders[_orderId].modifyPosition.balanceUp = _balanceUp;
        orders[_orderId].modifyPosition.newLongShares = portfolio[orders[_orderId].userId][ orders[_orderId].marketId].longShares;
        orders[_orderId].modifyPosition.newShortShares = _newShortShares;
        orders[_orderId].modifyPosition.newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

// ----------------------------------------------------------------------------
// openShort(bytes32 _orderId)
// Opens a new short position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        //
        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorShortShares is a factor to adjust the existing shortShares via virtual liqudiation and reopening at current market price

        uint256 _factorShortShares = portfolio[_userId][ _marketId].meanEntryLeverage;
        if (_factorShortShares < PRECISION) {
            _factorShortShares = PRECISION;
        }
        _factorShortShares = _factorShortShares + (PRECISION);
        _factorShortShares = _factorShortShares * (portfolio[_userId][ _marketId].meanEntryPrice) / (orders[_orderId].marketPrice);
        if (portfolio[_userId][ _marketId].meanEntryLeverage < _factorShortShares) {
            _factorShortShares = _factorShortShares - (portfolio[_userId][ _marketId].meanEntryLeverage);
        } else {
            _factorShortShares = 0;
        }

        uint256 _adjustedShortShares = _factorShortShares * (portfolio[_userId][ _marketId].shortShares) / (PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = portfolio[_userId][ _marketId].meanEntryLeverage * (_adjustedShortShares);
        _newMeanLeverage = _newMeanLeverage + (orders[_orderId].orderLeverage * (orders[_orderId].modifyPosition.shortSharesOrder));
        _newMeanLeverage = _newMeanLeverage / (_adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = portfolio[_userId][ _marketId].meanEntrySpread * (portfolio[_userId][ _marketId].shortShares);
        _newMeanSpread = _newMeanSpread + (orders[_orderId].marketSpread * (orders[_orderId].modifyPosition.shortSharesOrder));
        _newMeanSpread = _newMeanSpread / (_adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder));

        orders[_orderId].modifyPosition.balanceDown = orders[_orderId].modifyPosition.shortSharesOrder * (orders[_orderId].marketPrice) + (
            orders[_orderId].modifyPosition.shortSharesOrder * (orders[_orderId].marketSpread) * (orders[_orderId].orderLeverage) / (PRECISION)
        );
        orders[_orderId].modifyPosition.balanceUp = 0;
        orders[_orderId].modifyPosition.newLongShares = portfolio[_userId][ _marketId].longShares;
        orders[_orderId].modifyPosition.newShortShares = _adjustedShortShares + (orders[_orderId].modifyPosition.shortSharesOrder);
        orders[_orderId].modifyPosition.newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].modifyPosition.newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].modifyPosition.newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

    function computeLiquidationPrice(bytes32 _orderId) public returns(uint256 _liquidationPrice) {
        orders[_orderId].modifyPosition.newLiquidationPrice = 0;
        if (orders[_orderId].modifyPosition.newLongShares > 0) {
            orders[_orderId].modifyPosition.newLiquidationPrice = getLiquidationPrice(orders[_orderId].modifyPosition.newMeanEntryPrice, orders[_orderId].modifyPosition.newMeanEntryLeverage, true, orders[_orderId].timeStamp);
        }
        if (orders[_orderId].modifyPosition.newShortShares > 0) {
            orders[_orderId].modifyPosition.newLiquidationPrice = getLiquidationPrice(orders[_orderId].modifyPosition.newMeanEntryPrice, orders[_orderId].modifyPosition.newMeanEntryLeverage, false, orders[_orderId].timeStamp);
        }
        return orders[_orderId].modifyPosition.newLiquidationPrice;
    }

    function getLiquidationPrice(uint256 _newMeanEntryPrice, uint256 _newMeanEntryLeverage, bool _long, uint _positionTimestampInMs) public view returns (uint256) {
        uint _liquidationPrice;
        uint marginInterest = calculateMarginInterest(_newMeanEntryPrice, _newMeanEntryLeverage, _positionTimestampInMs);
        uint adjustedMarginInterest = marginInterest * PRECISION / _newMeanEntryLeverage;
        if (_long == true) {
            _liquidationPrice = _newMeanEntryPrice * (_newMeanEntryLeverage - (PRECISION)) / (_newMeanEntryLeverage);
            _liquidationPrice += adjustedMarginInterest;
        } else {
            _liquidationPrice = _newMeanEntryPrice * (_newMeanEntryLeverage + (PRECISION)) / (_newMeanEntryLeverage);
            _liquidationPrice -= adjustedMarginInterest;
        }
        return _liquidationPrice;
    }

    
// ----------------------------------------------------------------------------
// setPositionInState(bytes32 _orderId)
// Updates the portfolio in Morpher State. Called by closeLong/closeShort/openLong/openShort
// ----------------------------------------------------------------------------
    function setPositionInState(bytes32 _orderId) private {
        require(MorpherToken(morpherState.morpherTokenAddress()).balanceOf(orders[_orderId].userId) + (orders[_orderId].modifyPosition.balanceUp) >= orders[_orderId].modifyPosition.balanceDown, "MorpherTradeEngine: insufficient funds.");
        computeLiquidationPrice(_orderId);
        // Net balanceUp and balanceDown
        if (orders[_orderId].modifyPosition.balanceUp > orders[_orderId].modifyPosition.balanceDown) {
            orders[_orderId].modifyPosition.balanceUp -= (orders[_orderId].modifyPosition.balanceDown);
            orders[_orderId].modifyPosition.balanceDown = 0;
        } else {
            orders[_orderId].modifyPosition.balanceDown -= (orders[_orderId].modifyPosition.balanceUp);
            orders[_orderId].modifyPosition.balanceUp = 0;
        }
        if (orders[_orderId].modifyPosition.balanceUp > 0) {
            MorpherToken(morpherState.morpherMintingLimiterAddress()).mint(orders[_orderId].userId, orders[_orderId].modifyPosition.balanceUp);
        }
        if (orders[_orderId].modifyPosition.balanceDown > 0) {
            MorpherToken(morpherState.morpherTokenAddress()).burn(orders[_orderId].userId, orders[_orderId].modifyPosition.balanceDown);
        }
        _setPosition(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].modifyPosition.newLongShares,
            orders[_orderId].modifyPosition.newShortShares,
            orders[_orderId].modifyPosition.newMeanEntryPrice,
            orders[_orderId].modifyPosition.newMeanEntrySpread,
            orders[_orderId].modifyPosition.newMeanEntryLeverage,
            orders[_orderId].modifyPosition.newLiquidationPrice
        );
        emit PositionUpdated(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].modifyPosition.newLongShares,
            orders[_orderId].modifyPosition.newShortShares,
            orders[_orderId].modifyPosition.newMeanEntryPrice,
            orders[_orderId].modifyPosition.newMeanEntrySpread,
            orders[_orderId].modifyPosition.newMeanEntryLeverage,
            orders[_orderId].modifyPosition.newLiquidationPrice,
            orders[_orderId].modifyPosition.balanceUp,
            orders[_orderId].modifyPosition.balanceDown
        );
    }

     function setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public onlyRole(POSITIONADMIN_ROLE) {
        _setPosition(_address,
        _marketId,
        _timeStamp,
        _longShares,
        _shortShares,
        _meanEntryPrice,
        _meanEntrySpread,
        _meanEntryLeverage,
        _liquidationPrice);
    }

     function _setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) internal {
        portfolio[_address][_marketId].lastUpdated = _timeStamp;
        portfolio[_address][_marketId].longShares = _longShares;
        portfolio[_address][_marketId].shortShares = _shortShares;
        portfolio[_address][_marketId].meanEntryPrice = _meanEntryPrice;
        portfolio[_address][_marketId].meanEntrySpread = _meanEntrySpread;
        portfolio[_address][_marketId].meanEntryLeverage = _meanEntryLeverage;
        portfolio[_address][_marketId].liquidationPrice = _liquidationPrice;
        portfolio[_address][_marketId].positionHash = getPositionHash(
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
        if (_longShares > 0 || _shortShares > 0) {
            addExposureByMarket(_marketId, _address);
        } else {
            deleteExposureByMarket(_marketId, _address);
        }
        emit SetPosition(
            portfolio[_address][_marketId].positionHash,
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
    }

    function getPosition(address _address, bytes32 _marketId) public view returns (position memory) {
        return portfolio[_address][_marketId];
    }

    function getPositionHash(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public pure returns (bytes32 _hash) {
        return keccak256(
            abi.encodePacked(
                _address,
                _marketId,
                _timeStamp,
                _longShares,
                _shortShares,
                _meanEntryPrice,
                _meanEntrySpread,
                _meanEntryLeverage,
                _liquidationPrice
            )
        );
    }



    function addExposureByMarket(bytes32 _symbol, address _address) private {
        // Address must not be already recored
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        if (_myExposureIndex == 0) {
            uint256 _maxMappingIndex = getMaxMappingIndex(_symbol) + (1);
            setMaxMappingIndex(_symbol, _maxMappingIndex);
            setExposureMapping(_symbol, _address, _maxMappingIndex);
        }
    }


    function deleteExposureByMarket(bytes32 _symbol, address _address) private {
        // Get my index in mapping
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        // Get last element of mapping
        uint256 _lastIndex = getMaxMappingIndex(_symbol);
        address _lastAddress = getExposureMappingAddress(_symbol, _lastIndex);
        // If _myExposureIndex is greater than 0 (i.e. there is an exposure of that address on that market) delete it
        if (_myExposureIndex > 0) {
            // If _myExposureIndex is less than _lastIndex overwrite element at _myExposureIndex with element at _lastIndex in
            // deleted elements position.
            if (_myExposureIndex < _lastIndex) {
                setExposureMappingAddress(_symbol, _lastAddress, _myExposureIndex);
                setExposureMappingIndex(_symbol, _lastAddress, _myExposureIndex);
            }
            // Delete _lastIndex and _lastAddress element and reduce maxExposureIndex
            setExposureMappingAddress(_symbol, address(0), _lastIndex);
            setExposureMappingIndex(_symbol, _address, 0);
            // Shouldn't happen, but check that not empty
            if (_lastIndex > 0) {
                setMaxMappingIndex(_symbol, _lastIndex - (1));
            }
        }
    }

    
    function getMaxMappingIndex(bytes32 _marketId) public view returns(uint256 _maxMappingIndex) {
        return exposureByMarket[_marketId].maxMappingIndex;
    }

    function getExposureMappingIndex(bytes32 _marketId, address _address) public view returns(uint256 _mappingIndex) {
        return exposureByMarket[_marketId].index[_address];
    }

    function getExposureMappingAddress(bytes32 _marketId, uint256 _mappingIndex) public view returns(address _address) {
        return exposureByMarket[_marketId].addy[_mappingIndex];
    }

    function setMaxMappingIndex(bytes32 _marketId, uint256 _maxMappingIndex) private {
        exposureByMarket[_marketId].maxMappingIndex = _maxMappingIndex;
    }

    function setExposureMapping(bytes32 _marketId, address _address, uint256 _index) private {
        setExposureMappingIndex(_marketId, _address, _index);
        setExposureMappingAddress(_marketId, _address, _index);
    }

    function setExposureMappingIndex(bytes32 _marketId, address _address, uint256 _index) private {
        exposureByMarket[_marketId].index[_address] = _index;
    }

    function setExposureMappingAddress(bytes32 _marketId, address _address, uint256 _index) private {
        exposureByMarket[_marketId].addy[_index] = _address;
    }



}