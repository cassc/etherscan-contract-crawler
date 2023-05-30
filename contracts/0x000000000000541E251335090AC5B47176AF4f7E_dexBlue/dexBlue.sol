/**
 *Submitted for verification at Etherscan.io on 2019-09-12
*/

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

contract dexBlueEvents{
    // Events

    /** @notice Emitted when a trade is settled
      * @param  makerAsset  The address of the token the maker gave
      * @param  makerAmount The amount of makerAsset the maker gave
      * @param  takerAsset  The address of the token the taker gave
      * @param  takerAmount The amount of takerAsset the taker gave
      */
    event LogTrade(address makerAsset, uint256 makerAmount, address takerAsset, uint256 takerAmount);
    
    /** @notice Emitted when a simple token swap against a reserve is settled
      * @param  soldAsset    The address of the token the maker gave
      * @param  soldAmount   The amount of makerAsset the maker gave
      * @param  boughtAsset  The address of the token the taker gave
      * @param  boughtAmount The amount of takerAsset the taker gave
      */
    event LogSwap(address soldAsset, uint256 soldAmount, address boughtAsset, uint256 boughtAmount);

    /** @notice Emitted when a trade settlement failed
      */
    event LogTradeFailed();

    /** @notice Emitted after a successful deposit of ETH or token
      * @param  account  The address, which deposited the asset
      * @param  token    The address of the deposited token (ETH is address(0))
      * @param  amount   The amount deposited in this transaction 
      */
    event LogDeposit(address account, address token, uint256 amount);

    /** @notice Emitted after a successful multi-sig withdrawal of deposited ETH or token
      * @param  account  The address, which initiated the withdrawal
      * @param  token    The address of the token which is withdrawn (ETH is address(0))
      * @param  amount   The amount withdrawn in this transaction 
      */
    event LogWithdrawal(address account, address token, uint256 amount);

    /** @notice Emitted after a successful direct withdrawal of deposited ETH or token
      * @param  account  The address, which initiated the withdrawal
      * @param  token    The address of the token which is withdrawn (ETH is address(0))
      * @param  amount   The amount withdrawn in this transaction 
      */
    event LogDirectWithdrawal(address account, address token, uint256 amount);

    /** @notice Emitted after a user successfully blocked tokens or ETH for a single signature withdrawal
      * @param  account  The address controlling the tokens
      * @param  token    The address of the token which is blocked (ETH is address(0))
      * @param  amount   The amount blocked in this transaction 
      */
    event LogBlockedForSingleSigWithdrawal(address account, address token, uint256 amount);

    /** @notice Emitted after a successful single-sig withdrawal of deposited ETH or token
      * @param  account  The address, which initiated the withdrawal
      * @param  token    The address of the token which is withdrawn (ETH is address(0))
      * @param  amount   The amount withdrawn in this transaction 
      */
    event LogSingleSigWithdrawal(address account, address token, uint256 amount);

    /** @notice Emitted once an on-chain cancellation of an order was performed
      * @param  hash    The invalidated orders hash 
      */
    event LogOrderCanceled(bytes32 hash);
   
    /** @notice Emitted once a address delegation or dedelegation was performed
      * @param  delegator The delegating address,
      * @param  delegate  The delegated address,
      * @param  status    whether the transaction delegated an address (true) or inactivated an active delegation (false) 
      */
    event LogDelegateStatus(address delegator, address delegate, bool status);
}

contract dexBlueStorage{
    // Storage Variables

    mapping(address => mapping(address => uint256)) balances;                           // Users balances (token address > user address > balance amount) (ETH is address(0))
    mapping(address => mapping(address => uint256)) blocked_for_single_sig_withdrawal;  // Users balances, blocked to withdraw without arbiters multi-sig (token address > user address > blocked amount) (ETH is address(0))
    mapping(address => uint256) last_blocked_timestamp;                                 // The last timestamp a user blocked tokens at, to withdraw with single-sig
    
    mapping(bytes32 => bool) processed_withdrawals;                                     // Processed withdrawal hashes
    mapping(bytes32 => uint256) matched;                                                // Orders matched sell amounts to prevent multiple-/over- matches of the same orders
    
    mapping(address => address) delegates;                                              // Registered Delegated Signing Key addresses
    
    mapping(uint256 => address) tokens;                                                 // Cached token index > address mapping
    mapping(address => uint256) token_indices;                                          // Cached token addresses > index mapping
    address[] token_arr;                                                                // Array of cached token addresses
    
    mapping(uint256 => address payable) reserves;                                       // Reserve index > reserve address mapping
    mapping(address => uint256) reserve_indices;                                        // Reserve address > reserve index mapping
    mapping(address => bool) public_reserves;                                           // Reserves publicly accessible through swap() & swapWithReserve()
    address[] public_reserve_arr;                                                       // Array of the publicly accessible reserves

    address payable owner;                      // Contract owner address (has the right to nominate arbiters and feeCollector addresses)   
    mapping(address => bool) arbiters;          // Mapping of arbiters
    bool marketActive = true;                   // Make it possible to pause the market
    address payable feeCollector;               // feeCollector address
    bool feeCollectorLocked = false;            // Make it possible to lock the feeCollector address (to allow to change the feeCollector to a fee distribution contract)
    uint256 single_sig_waiting_period = 86400;  // waiting period for single sig withdrawas, default (and max) is one day
}

contract dexBlueUtils is dexBlueStorage{
    /** @notice Get the balance of a user for a specific token
      * @param  token  The token address (ETH is address(0))
      * @param  holder The address holding the token
      * @return The amount of the specified token held by the user 
      */
    function getBalance(address token, address holder) view public returns(uint256){
        return balances[token][holder];
    }
    
    /** @notice Get index of a cached token address
      * @param  token  The token address (ETH is address(0))
      * @return The index of the token
      */
    function getTokenIndex(address token) view public returns(uint256){
        return token_indices[token];
    }
    
    /** @notice Get a cached token address from an index
      * @param  index  The index of the token
      * @return The address of the token
      */
    function getTokenFromIndex(uint256 index) view public returns(address){
        return tokens[index];
    }
    
    /** @notice Get the array containing all indexed token addresses
      * @return The array of all indexed token addresses
      */
    function getTokens() view public returns(address[] memory){
        return token_arr;
    }
    
    /** @notice Get index of a cached reserve address
      * @param  reserve  The reserve address
      * @return The index of the reserve
      */
    function getReserveIndex(address reserve) view public returns(uint256){
        return reserve_indices[reserve];
    }
    
    /** @notice Get a cached reserve address from an index
      * @param  index  The index of the reserve
      * @return The address of the reserve
      */
    function getReserveFromIndex(uint256 index) view public returns(address){
        return reserves[index];
    }
    
    /** @notice Get the array containing all publicly available reserve addresses
      * @return The array of addresses of all publicly available reserves
      */
    function getReserves() view public returns(address[] memory){
        return public_reserve_arr;
    }
    
    /** @notice Get the balance a user blocked for a single-signature withdrawal (ETH is address(0))
      * @param  token  The token address (ETH is address(0))
      * @param  holder The address holding the token
      * @return The amount of the specified token blocked by the user 
      */
    function getBlocked(address token, address holder) view public returns(uint256){
        return blocked_for_single_sig_withdrawal[token][holder];
    }
    
    /** @notice Returns the timestamp of the last blocked balance
      * @param  user  Address of the user which blocked funds
      * @return The last unix timestamp the user blocked funds at, which starts the waiting period for single-sig withdrawals 
      */
    function getLastBlockedTimestamp(address user) view public returns(uint256){
        return last_blocked_timestamp[user];
    }
    
    /** @notice We have to check returndatasize after ERC20 tokens transfers, as some tokens are implemented badly (dont return a boolean)
      * @return Whether the last ERC20 transfer failed or succeeded
      */
    function checkERC20TransferSuccess() pure internal returns(bool){
        uint256 success = 0;

        assembly {
            switch returndatasize               // Check the number of bytes the token contract returned
                case 0 {                        // Nothing returned, but contract did not throw > assume our transfer succeeded
                    success := 1
                }
                case 32 {                       // 32 bytes returned, result is the returned bool
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
        }

        return success != 0;
    }
}

contract dexBlueStructs is dexBlueStorage{

    // EIP712 Domain
    struct EIP712_Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32          EIP712_DOMAIN_SEPARATOR;
    // Order typehash
    bytes32 constant EIP712_ORDER_TYPEHASH = keccak256("Order(address sellTokenAddress,uint128 sellTokenAmount,address buyTokenAddress,uint128 buyTokenAmount,uint32 expiry,uint64 nonce)");
    // Withdrawal typehash
    bytes32 constant EIP712_WITHDRAWAL_TYPEHASH = keccak256("Withdrawal(address token,uint256 amount,uint64 nonce)");

    
    struct Order{
        address     sellToken;     // The token, the order signee wants to sell
        uint256     sellAmount;    // The total amount the signee wants to give for the amount he wants to buy (the orders "rate" is implied by the ratio between the two amounts)
        address     buyToken;      // The token, the order signee wants to buy
        uint256     buyAmount;     // The total amount the signee wants to buy
        uint256     expiry;        // The expiry time of the order (after which it is not longer valid)
        bytes32     hash;          // The orders hash
        address     signee;        // The orders signee
    }

    struct OrderInputPacked{
        /*
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0 - 15    | sell amount
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff | 16 - 31    | buy amount
        */  
        bytes32     packedInput1;
        /*
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffff000000000000000000000000000000000000000000000000000000000000 |  0 -  1    | sell token identifier
            0x0000ffff00000000000000000000000000000000000000000000000000000000 |  2 -  3    | buy token identifier
            0x00000000ffffffff000000000000000000000000000000000000000000000000 |  4 -  7    | expiry
            0x0000000000000000ffffffffffffffff00000000000000000000000000000000 |  8 - 15    | nonce
            0x00000000000000000000000000000000ff000000000000000000000000000000 | 16 - 16    | v
            0x0000000000000000000000000000000000ff0000000000000000000000000000 | 17 - 17    | signing scheme 0x00 = personal.sign, 0x01 = EIP712
            0x000000000000000000000000000000000000ff00000000000000000000000000 | 18 - 18    | signed by delegate
        */
        bytes32     packedInput2;
        
        bytes32     r;                          // Signature r
        bytes32     s;                          // Signature s
    }
    
    /** @notice Helper function parse an Order struct from an OrderInputPacked struct
      * @param   orderInput  The OrderInputPacked struct to parse
      * @return The parsed Order struct
      */
    function orderFromInput(OrderInputPacked memory orderInput) view public returns(Order memory){
        // Parse packed input
        Order memory order = Order({
            sellToken  : tokens[uint256(orderInput.packedInput2 >> 240)],
            sellAmount : uint256(orderInput.packedInput1 >> 128),
            buyToken   : tokens[uint256((orderInput.packedInput2 & 0x0000ffff00000000000000000000000000000000000000000000000000000000) >> 224)],
            buyAmount  : uint256(orderInput.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            expiry     : uint256((orderInput.packedInput2 & 0x00000000ffffffff000000000000000000000000000000000000000000000000) >> 192), 
            hash       : 0x0,
            signee     : address(0x0)
        });
        
        // Restore order hash
        if(
            orderInput.packedInput2[17] == byte(0x00)   // Signing scheme
        ){                                              // Order is hashed after signature scheme personal.sign()
            order.hash = keccak256(abi.encodePacked(    // Restore the hash of this order
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    order.sellToken,
                    uint128(order.sellAmount),
                    order.buyToken,
                    uint128(order.buyAmount),
                    uint32(order.expiry), 
                    uint64(uint256((orderInput.packedInput2 & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000) >> 128)), // nonce     
                    address(this)                       // This contract's address
                ))
            ));
        }else{                                          // Order is hashed after EIP712
            order.hash = keccak256(abi.encodePacked(
                "\x19\x01",
                EIP712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    EIP712_ORDER_TYPEHASH,
                    order.sellToken,
                    order.sellAmount,
                    order.buyToken,
                    order.buyAmount,
                    order.expiry, 
                    uint256((orderInput.packedInput2 & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000) >> 128) // nonce   
                ))
            ));
        }
        
        // Restore the signee of this order
        order.signee = ecrecover(
            order.hash,                             // Order hash
            uint8(orderInput.packedInput2[16]),     // Signature v
            orderInput.r,                           // Signature r
            orderInput.s                            // Signature s
        );
        
        // When the signature was delegated restore delegating address
        if(
            orderInput.packedInput2[18] == byte(0x01)  // Is delegated
        ){
            order.signee = delegates[order.signee];
        }
        
        return order;
    }
    
    struct Trade{
        uint256 makerAmount;
        uint256 takerAmount; 
        uint256 makerFee; 
        uint256 takerFee;
        uint256 makerRebate;
    }
    
    struct ReserveReserveTrade{
        address makerToken;
        address takerToken; 
        uint256 makerAmount;
        uint256 takerAmount; 
        uint256 makerFee; 
        uint256 takerFee;
        uint256 gasLimit;
    }
    
    struct ReserveTrade{
        uint256 orderAmount;
        uint256 reserveAmount; 
        uint256 orderFee; 
        uint256 reserveFee;
        uint256 orderRebate;
        uint256 reserveRebate;
        bool    orderIsMaker;
        uint256 gasLimit;
    }
    
    struct TradeInputPacked{
        /* 
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0 - 15    | maker amount
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff | 16 - 31    | taker amount
        */
        bytes32     packedInput1;  
        /*
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0-15      | maker fee
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff | 16-31      | taker fee
        */
        bytes32     packedInput2; 
        /*
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0 - 15    | maker rebate           (optional)
            0x00000000000000000000000000000000ff000000000000000000000000000000 | 16 - 16    | counterparty types:
                                                                               |            |   0x11 : maker=order,   taker=order, 
                                                                               |            |   0x10 : maker=order,   taker=reserve, 
                                                                               |            |   0x01 : maker=reserve, taker=order
                                                                               |            |   0x00 : maker=reserve, taker=reserve
            0x0000000000000000000000000000000000ffff00000000000000000000000000 | 17 - 18    | maker_identifier
            0x00000000000000000000000000000000000000ffff0000000000000000000000 | 19 - 20    | taker_identifier
            0x000000000000000000000000000000000000000000ffff000000000000000000 | 21 - 22    | maker_token_identifier (optional)
            0x0000000000000000000000000000000000000000000000ffff00000000000000 | 23 - 24    | taker_token_identifier (optional)
            0x00000000000000000000000000000000000000000000000000ffffff00000000 | 25 - 27    | gas_limit              (optional)
            0x00000000000000000000000000000000000000000000000000000000ff000000 | 28 - 28    | burn_gas_tokens        (optional)
        */
        bytes32     packedInput3; 
    }

    /** @notice Helper function parse an Trade struct from an TradeInputPacked struct
      * @param  packed      The TradeInputPacked struct to parse
      * @return The parsed Trade struct
      */
    function tradeFromInput(TradeInputPacked memory packed) public pure returns (Trade memory){
        return Trade({
            makerAmount : uint256(packed.packedInput1 >> 128),
            takerAmount : uint256(packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerFee    : uint256(packed.packedInput2 >> 128),
            takerFee    : uint256(packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerRebate : uint256(packed.packedInput3 >> 128)
        });
    }
    
    /** @notice Helper function parse an ReserveTrade struct from an TradeInputPacked struct
      * @param  packed      The TradeInputPacked struct to parse
      * @return The parsed ReserveTrade struct
      */
    function reserveTradeFromInput(TradeInputPacked memory packed) public pure returns (ReserveTrade memory){
        if(packed.packedInput3[16] == byte(0x10)){
            // maker is order, taker is reserve
            return ReserveTrade({
                orderAmount   : uint256( packed.packedInput1 >> 128),
                reserveAmount : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                orderFee      : uint256( packed.packedInput2 >> 128),
                reserveFee    : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                orderRebate   : uint256((packed.packedInput3 & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128),
                reserveRebate : 0,
                orderIsMaker  : true,
                gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
            });
        }else{
            // taker is order, maker is reserve
            return ReserveTrade({
                orderAmount   : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                reserveAmount : uint256( packed.packedInput1 >> 128),
                orderFee      : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                reserveFee    : uint256( packed.packedInput2 >> 128),
                orderRebate   : 0,
                reserveRebate : uint256((packed.packedInput3 & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128),
                orderIsMaker  : false,
                gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
            });
        }
    }

    /** @notice Helper function parse an ReserveReserveTrade struct from an TradeInputPacked struct
      * @param  packed      The TradeInputPacked struct to parse
      * @return The parsed ReserveReserveTrade struct
      */
    function reserveReserveTradeFromInput(TradeInputPacked memory packed) public view returns (ReserveReserveTrade memory){
        return ReserveReserveTrade({
            makerToken    : tokens[uint256((packed.packedInput3 & 0x000000000000000000000000000000000000000000ffff000000000000000000) >> 72)],
            takerToken    : tokens[uint256((packed.packedInput3 & 0x0000000000000000000000000000000000000000000000ffff00000000000000) >> 56)],
            makerAmount   : uint256( packed.packedInput1 >> 128),
            takerAmount   : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerFee      : uint256( packed.packedInput2 >> 128),
            takerFee      : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
        });
    }
    
    struct RingTrade {
        bool    isReserve;      // 1 if this trade is from a reserve, 0 when from an order
        uint256 identifier;     // identifier of the reserve or order
        address giveToken;      // the token this trade gives, the receive token is the givetoken of the previous ring element
        uint256 giveAmount;     // the amount of giveToken, this ring element is giving for the amount it reeives from the previous element
        uint256 fee;            // the fee this ring element has to pay on the giveToken giveAmount of the previous ring element
        uint256 rebate;         // the rebate on giveAmount this element receives
        uint256 gasLimit;       // the gas limit for the reserve call (if the element is a reserve)
    }

    struct RingTradeInputPacked{
        /* 
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0 - 15    | give amount
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff | 16 - 31    | fee
        */
        bytes32     packedInput1;    
        /* 
            BITMASK                                                            | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0 - 15    | rebate
            0x00000000000000000000000000000000ff000000000000000000000000000000 | 16 - 16    | is reserve
            0x0000000000000000000000000000000000ffff00000000000000000000000000 | 17 - 18    | identifier
            0x00000000000000000000000000000000000000ffff0000000000000000000000 | 19 - 20    | giveToken identifier
            0x000000000000000000000000000000000000000000ffffff0000000000000000 | 21 - 23    | gas_limit
            0x000000000000000000000000000000000000000000000000ff00000000000000 | 24 - 24    | burn_gas_tokens
        */
        bytes32     packedInput2;   
    }
    
    /** @notice Helper function parse an RingTrade struct from an RingTradeInputPacked struct
      * @param  packed  The RingTradeInputPacked struct to parse
      * @return The parsed RingTrade struct
      */
    function ringTradeFromInput(RingTradeInputPacked memory packed) view public returns(RingTrade memory){
        return RingTrade({
            isReserve     : (packed.packedInput2[16] == bytes1(0x01)),
            identifier    : uint256((       packed.packedInput2 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104),
            giveToken     : tokens[uint256((packed.packedInput2 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            giveAmount    : uint256(        packed.packedInput1                                                                       >> 128),
            fee           : uint256(        packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            rebate        : uint256(        packed.packedInput2                                                                       >> 128),
            gasLimit      : uint256((       packed.packedInput2 & 0x000000000000000000000000000000000000000000ffffff0000000000000000) >> 64)
        });
    }
}

contract dexBlueSettlementModule is dexBlueStorage, dexBlueEvents, dexBlueUtils, dexBlueStructs{
    
    /** @notice Internal helper function to settle a trade between two orders
      * @param  makerOrder  The maker order
      * @param  takerOrder  The taker order
      * @param  trade       The trade to settle between the two
      * @return Whether the trade succeeded or failed
      */
    function matchOrders(
        Order memory makerOrder,
        Order memory takerOrder,
        Trade memory trade
    ) internal returns (bool){
        // Load the orders previously matched amounts into memory
        uint makerOrderMatched = matched[makerOrder.hash];
        uint takerOrderMatched = matched[takerOrder.hash];

        if( // Check if the arbiter has matched following the conditions of the two order signees
            // Do maker and taker want to trade the same tokens with each other
               makerOrder.buyToken == takerOrder.sellToken
            && takerOrder.buyToken == makerOrder.sellToken
            
            // Are both of the orders still valid
            && makerOrder.expiry > block.timestamp
            && takerOrder.expiry > block.timestamp 
            
            // Do maker and taker hold the required balances
            && balances[makerOrder.sellToken][makerOrder.signee] >= trade.makerAmount - trade.makerRebate
            && balances[takerOrder.sellToken][takerOrder.signee] >= trade.takerAmount
            
            // Are they both matched at a rate better or equal to the one they signed
            && trade.makerAmount - trade.makerRebate <= makerOrder.sellAmount * trade.takerAmount / makerOrder.buyAmount + 1  // Check maker doesn't overpay (+ 1 to deal with rouding errors for very smal amounts)
            && trade.takerAmount                     <= takerOrder.sellAmount * trade.makerAmount / takerOrder.buyAmount + 1  // Check taker doesn't overpay (+ 1 to deal with rouding errors for very smal amounts)
            
            // Check if the order was cancelled
            && makerOrder.sellAmount > makerOrderMatched
            && takerOrder.sellAmount > takerOrderMatched

            // Check if the matched amount + previously matched trades doesn't exceed the amount specified by the order signee
            && trade.makerAmount - trade.makerRebate + makerOrderMatched <= makerOrder.sellAmount
            && trade.takerAmount                     + takerOrderMatched <= takerOrder.sellAmount
                
            // Check if the charged fee is not too high
            && trade.makerFee <= trade.takerAmount / 20
            && trade.takerFee <= trade.makerAmount / 20
            
            // Check if maker_rebate is smaller than or equal to the taker's fee which compensates it
            && trade.makerRebate <= trade.takerFee
        ){
            // Settle the trade:
            
            // Substract sold amounts
            balances[makerOrder.sellToken][makerOrder.signee] -= trade.makerAmount - trade.makerRebate;     // Substract maker's sold amount minus the makers rebate
            balances[takerOrder.sellToken][takerOrder.signee] -= trade.takerAmount;                         // Substract taker's sold amount
            
            // Add bought amounts
            balances[makerOrder.buyToken][makerOrder.signee] += trade.takerAmount - trade.makerFee;         // Give the maker his bought amount minus the fee
            balances[takerOrder.buyToken][takerOrder.signee] += trade.makerAmount - trade.takerFee;         // Give the taker his bought amount minus the fee
            
            // Save sold amounts to prevent double matching
            matched[makerOrder.hash] += trade.makerAmount - trade.makerRebate;                              // Prevent maker order from being reused
            matched[takerOrder.hash] += trade.takerAmount;                                                  // Prevent taker order from being reused
            
            // Give fee to feeCollector
            balances[takerOrder.buyToken][feeCollector] += trade.takerFee - trade.makerRebate;              // Give the feeColletor the taker fee minus the maker rebate 
            balances[makerOrder.buyToken][feeCollector] += trade.makerFee;                                  // Give the feeColletor the maker fee
            
            // Set potential previous blocking of these funds to 0
            blocked_for_single_sig_withdrawal[makerOrder.sellToken][makerOrder.signee] = 0;                 // If the maker tried to block funds which he/she used in this order we have to unblock them
            blocked_for_single_sig_withdrawal[takerOrder.sellToken][takerOrder.signee] = 0;                 // If the taker tried to block funds which he/she used in this order we have to unblock them
            
            emit LogTrade(makerOrder.sellToken, trade.makerAmount, takerOrder.sellToken, trade.takerAmount);

            return true;                                                                         
        }else{
            return false;                                                                                   
        }
    }

    /** @notice Internal helper function to settle a trade between an order and a reserve
      * @param  order    The order
      * @param  reserve  The reserve
      * @param  trade    The trade to settle between the two
      * @return Whether the trade succeeded or failed
      */
    function matchOrderWithReserve(
        Order memory order,
        address      reserve,
        ReserveTrade memory trade
    ) internal returns(bool){
        // Load the orders previously matched amount into memory
        uint orderMatched = matched[order.hash];

        if( // Check if the arbiter matched the conditions of the order signee
            // Does the order signee has the required balances deposited
            balances[order.sellToken][order.signee] >= trade.orderAmount - trade.orderRebate
            
            // Is the order still valid
            && order.expiry > block.timestamp 
            
            // Is the order matched at a rate better or equal to the one specified by the signee
            && trade.orderAmount - trade.orderRebate <= order.sellAmount * trade.reserveAmount / order.buyAmount + 1  // + 1 to deal with rouding errors
            
            // Check if the order was cancelled
            && order.sellAmount > orderMatched

            // Check if the matched amount + previously matched trades doesn't exceed the amount specified by the order signee
            && trade.orderAmount - trade.orderRebate + orderMatched <= order.sellAmount
                
            // Check if the charged fee is not too high
            && trade.orderFee   <= trade.reserveAmount / 20
            && trade.reserveFee <= trade.orderAmount   / 20
            
            // Check if the rebates can be compensated by the fees
            && trade.orderRebate   <= trade.reserveFee
            && trade.reserveRebate <= trade.orderFee
        ){
            balances[order.sellToken][order.signee] -= trade.orderAmount - trade.orderRebate;  // Substract users's sold amount minus the makers rebate
            
            (bool txSuccess, bytes memory returnData) = address(this).call.gas(
                    trade.gasLimit                                              // The gas limit for the call
                )(
                    abi.encodePacked(                                           // This encodes the function to call and the parameters we are passing to the settlement function
                        dexBlue(address(0)).executeReserveTrade.selector,       // This function executes the call to the reserve
                        abi.encode(                            
                            order.sellToken,                                    // The token the order signee wants to exchange with the reserve
                            trade.orderAmount   - trade.reserveFee,             // The reserve receives the sold amount minus the fee
                            order.buyToken,                                     // The token the order signee wants to receive from the reserve
                            trade.reserveAmount - trade.reserveRebate,          // The reserve has to return the amount the order want to receive minus
                            reserve                                             // The reserve the trade is settled with
                        )
                    )
                );
            
            if(
               txSuccess                                    // The call to the reserve did not fail
               && abi.decode(returnData, (bool))            // The call returned true (we are sure its a contract we called)
               // executeReserveTrade checks whether the reserve deposited the funds
            ){
                // Substract the deposited amount from reserves balance
                balances[order.buyToken][reserve]      -= trade.reserveAmount - trade.reserveRebate;    // Substract reserves's sold amount
                
                // The amount to the order signees balance
                balances[order.buyToken][order.signee] += trade.reserveAmount - trade.orderFee;         // Give the users his bought amount minus the fee
                
                // Save sold amounts to prevent double matching
                matched[order.hash] += trade.orderAmount - trade.orderRebate;                           // Prevent maker order from being reused
                
                // Give fee to feeCollector
                balances[order.buyToken][feeCollector]  += trade.orderFee   - trade.reserveRebate;      // Give the feeColletor the fee minus the maker rebate
                balances[order.sellToken][feeCollector] += trade.reserveFee - trade.orderRebate;        // Give the feeColletor the fee minus the maker rebate
                
                // Set potential previous blocking of these funds to 0
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                   // If the user blocked funds which he/she used in this order we have to unblock them

                if(trade.orderIsMaker){
                    emit LogTrade(order.sellToken, trade.orderAmount, order.buyToken, trade.reserveAmount);
                }else{
                    emit LogTrade(order.buyToken, trade.reserveAmount, order.sellToken, trade.orderAmount);
                }
                emit LogDirectWithdrawal(reserve, order.sellToken, trade.orderAmount - trade.reserveFee);
                
                return true;
            }else{
                balances[order.sellToken][order.signee] += trade.orderAmount - trade.orderRebate;  // Refund substracted amount
                
                return false;
            }
        }else{
            return false;
        }
    }
    
    /** @notice Internal helper function to settle a trade between an order and a reserve, passing some additional data to the reserve
      * @param  order    The order
      * @param  reserve  The reserve
      * @param  trade    The trade to settle between the two
      * @param  data     The data to pass along to the reserve
      * @return Whether the trade succeeded or failed
      */
    function matchOrderWithReserveWithData(
        Order        memory order,
        address      reserve,
        ReserveTrade memory trade,
        bytes32[]    memory data
    ) internal returns(bool){
        // Load the orders previously matched amount into memory
        uint orderMatched = matched[order.hash];

        if( // Check if the arbiter matched the conditions of the order signee
            // Does the order signee has the required balances deposited
            balances[order.sellToken][order.signee] >= trade.orderAmount - trade.orderRebate
            
            // Is the order still valid
            && order.expiry > block.timestamp 
            
            // Is the order matched at a rate better or equal to the one specified by the signee
            && trade.orderAmount - trade.orderRebate <= order.sellAmount * trade.reserveAmount / order.buyAmount + 1  // + 1 to deal with rouding errors
            
            // Check if the order was cancelled
            && order.sellAmount > orderMatched

            // Check if the matched amount + previously matched trades doesn't exceed the amount specified by the order signee
            && trade.orderAmount - trade.orderRebate + orderMatched <= order.sellAmount
                
            // Check if the charged fee is not too high
            && trade.orderFee   <= trade.reserveAmount / 20
            && trade.reserveFee <= trade.orderAmount   / 20
            
            // Check if the rebates can be compensated by the fees
            && trade.orderRebate   <= trade.reserveFee
            && trade.reserveRebate <= trade.orderFee
        ){
            balances[order.sellToken][order.signee] -= trade.orderAmount - trade.orderRebate;  // Substract users's sold amount minus the makers rebate
            
            (bool txSuccess, bytes memory returnData) = address(this).call.gas(
                    trade.gasLimit                                                  // The gas limit for the call
                )(
                    abi.encodePacked(                                               // This encodes the function to call and the parameters we are passing to the settlement function
                        dexBlue(address(0)).executeReserveTradeWithData.selector,   // This function executes the call to the reserve
                        abi.encode(                            
                            order.sellToken,                                        // The token the order signee wants to exchange with the reserve
                            trade.orderAmount   - trade.reserveFee,                 // The reserve receives the sold amount minus the fee
                            order.buyToken,                                         // The token the order signee wants to receive from the reserve
                            trade.reserveAmount - trade.reserveRebate,              // The reserve has to return the amount the order want to receive minus
                            reserve,                                                // The reserve the trade is settled with
                            data                                                    // The data passed on to the reserve
                        )
                    )
                );
            
            if(
               txSuccess                                    // The call to the reserve did not fail
               && abi.decode(returnData, (bool))            // The call returned true (we are sure its a contract we called)
               // executeReserveTrade checks whether the reserve deposited the funds
            ){
                // substract the deposited amount from reserves balance
                balances[order.buyToken][reserve]      -= trade.reserveAmount - trade.reserveRebate;    // Substract reserves's sold amount
                
                // the amount to the order signees balance
                balances[order.buyToken][order.signee] += trade.reserveAmount - trade.orderFee;         // Give the users his bought amount minus the fee
                
                // Save sold amounts to prevent double matching
                matched[order.hash] += trade.orderAmount - trade.orderRebate;                           // Prevent maker order from being reused
                
                // Give fee to feeCollector
                balances[order.buyToken][feeCollector]  += trade.orderFee   - trade.reserveRebate;      // Give the feeColletor the fee minus the maker rebate
                balances[order.sellToken][feeCollector] += trade.reserveFee - trade.orderRebate;        // Give the feeColletor the fee minus the maker rebate
                
                // Set potential previous blocking of these funds to 0
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                   // If the user blocked funds which he/she used in this order we have to unblock them

                if(trade.orderIsMaker){
                    emit LogTrade(order.sellToken, trade.orderAmount, order.buyToken, trade.reserveAmount);
                }else{
                    emit LogTrade(order.buyToken, trade.reserveAmount, order.sellToken, trade.orderAmount);
                }
                emit LogDirectWithdrawal(reserve, order.sellToken, trade.orderAmount - trade.reserveFee);
                
                return true;
            }else{
                balances[order.sellToken][order.signee] += trade.orderAmount - trade.orderRebate;  // Refund substracted amount
                
                return false;
            }
        }else{
            return false;
        }
    }
    
    /** @notice internal helper function to settle a trade between two reserves
      * @param  makerReserve  The maker reserve
      * @param  takerReserve  The taker reserve
      * @param  trade         The trade to settle between the two
      * @return Whether the trade succeeded or failed
      */
    function matchReserveWithReserve(
        address             makerReserve,
        address             takerReserve,
        ReserveReserveTrade memory trade
    ) internal returns(bool){

        (bool txSuccess, bytes memory returnData) = address(this).call.gas(
            trade.gasLimit                                                      // The gas limit for the call
        )(
            abi.encodePacked(                                                   // This encodes the function to call and the parameters we are passing to the settlement function
                dexBlue(address(0)).executeReserveReserveTrade.selector,     // This function executes the call to the reserves
                abi.encode(                            
                    makerReserve,
                    takerReserve,
                    trade
                )
            )
        );

        return (
            txSuccess                                    // The call to the reserve did not fail
            && abi.decode(returnData, (bool))            // The call returned true (we are sure its a contract we called)
        );
    }

    
    /** @notice internal helper function to settle a trade between two reserves
      * @param  makerReserve  The maker reserve
      * @param  takerReserve  The taker reserve
      * @param  trade         The trade to settle between the two
      * @param  makerData     The data to pass on to the maker reserve
      * @param  takerData     The data to pass on to the taker reserve
      * @return Whether the trade succeeded or failed
      */
    function matchReserveWithReserveWithData(
        address             makerReserve,
        address             takerReserve,
        ReserveReserveTrade memory trade,
        bytes32[] memory    makerData,
        bytes32[] memory    takerData
    ) internal returns(bool){

        (bool txSuccess, bytes memory returnData) = address(this).call.gas(
            trade.gasLimit                                                       // The gas limit for the call
        )(
            abi.encodePacked(                                                    // This encodes the function to call and the parameters we are passing to the settlement function
                dexBlue(address(0)).executeReserveReserveTradeWithData.selector, // This function executes the call to the reserves
                abi.encode(                            
                    makerReserve,
                    takerReserve,
                    trade,
                    makerData,
                    takerData
                )
            )
        );

        return (
            txSuccess                                    // The call to the reserve did not fail
            && abi.decode(returnData, (bool))            // The call returned true (we are sure its a contract we called)
        );
    }
    
    /** @notice Allows an arbiter to settle multiple trades between multiple orders and reserves
      * @param  orderInput     Array of all orders involved in the transactions
      * @param  tradeInput     Array of the trades to be settled
      */   
    function batchSettleTrades(OrderInputPacked[] calldata orderInput, TradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        Order[] memory orders = new Order[](orderInput.length);
        uint256 i = orderInput.length;

        while(i-- != 0){                                // Loop through the orderInput array, to parse the infos and restore all signees
            orders[i] = orderFromInput(orderInput[i]);  // Parse this orders infos
        }
        
        uint256 makerIdentifier;
        uint256 takerIdentifier;
        
        for(i = 0; i < tradeInput.length; i++){
            makerIdentifier = uint256((tradeInput[i].packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104);
            takerIdentifier = uint256((tradeInput[i].packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88);
            
            if(tradeInput[i].packedInput3[16] == byte(0x11)){       // Both are orders
                if(!matchOrders(
                    orders[makerIdentifier],
                    orders[takerIdentifier],
                    tradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else if(tradeInput[i].packedInput3[16] == byte(0x10)){ // Maker is order, taker is reserve
                if(!matchOrderWithReserve(
                    orders[makerIdentifier],
                    reserves[takerIdentifier],
                    reserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else if(tradeInput[i].packedInput3[16] == byte(0x01)){ // Taker is order, maker is reserve
                if(!matchOrderWithReserve(
                    orders[takerIdentifier],
                    reserves[makerIdentifier],
                    reserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else{                                                  // Both are reserves
                if(!matchReserveWithReserve(
                    reserves[makerIdentifier],
                    reserves[takerIdentifier],
                    reserveReserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }
        }
    }

    /** @notice Allows an arbiter to settle a trade between two orders
      * @param  makerOrderInput  The packed maker order input
      * @param  takerOrderInput  The packed taker order input
      * @param  tradeInput       The packed trade to settle between the two
      */ 
    function settleTrade(OrderInputPacked calldata makerOrderInput, OrderInputPacked calldata takerOrderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        if(!matchOrders(
            orderFromInput(makerOrderInput),
            orderFromInput(takerOrderInput),
            tradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }
        
    /** @notice Allows an arbiter to settle a trade between an order and a reserve
      * @param  orderInput  The packed maker order input
      * @param  tradeInput  The packed trade to settle between the two
      */ 
    function settleReserveTrade(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        if(!matchOrderWithReserve(
            orderFromInput(orderInput),
            reserves[
                tradeInput.packedInput3[16] == byte(0x01) ? // is maker reserve
                    // maker is reserve
                    uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104) :
                    // taker is reserve
                    uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)
            ],
            reserveTradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }

    /** @notice Allows an arbiter to settle a trade between an order and a reserve
      * @param  orderInput  The packed maker order input
      * @param  tradeInput  The packed trade to settle between the two
      * @param  data        The data to pass on to the reserve
      */ 
    function settleReserveTradeWithData(
        OrderInputPacked calldata orderInput, 
        TradeInputPacked calldata tradeInput,
        bytes32[] calldata        data
    ) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        if(!matchOrderWithReserveWithData(
            orderFromInput(orderInput),
            reserves[
                tradeInput.packedInput3[16] == byte(0x01) ? // Is maker reserve
                    // maker is reserve
                    uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104) :
                    // taker is reserve
                    uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)
            ],
            reserveTradeFromInput(tradeInput),
            data
        )){
            emit LogTradeFailed();      
        }
    }
    
    /** @notice Allows an arbiter to settle a trade between two reserves
      * @param  tradeInput  The packed trade to settle between the two
      */ 
    function settleReserveReserveTrade(
        TradeInputPacked calldata tradeInput
    ) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        if(!matchReserveWithReserve(
            reserves[uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104)],
            reserves[uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            reserveReserveTradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }
    
    /** @notice Allows an arbiter to settle a trade between two reserves
      * @param  tradeInput  The packed trade to settle between the two
      * @param  makerData   The data to pass on to the maker reserve
      * @param  takerData   The data to pass on to the taker reserve
      */ 
    function settleReserveReserveTradeWithData(
        TradeInputPacked calldata tradeInput,
        bytes32[] calldata        makerData,
        bytes32[] calldata        takerData
    ) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        if(!matchReserveWithReserveWithData(
            reserves[uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104)],
            reserves[uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            reserveReserveTradeFromInput(tradeInput),
            makerData,
            takerData
        )){
            emit LogTradeFailed();      
        }
    }
    
    /** @notice Allow arbiters to settle a ring of order and reserve trades
      * @param  orderInput Array of OrderInputPacked structs
      * @param  tradeInput Array of RingTradeInputPacked structs
      */
    function settleRingTrade(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        // Parse Orders from packed input
        uint256 i = orderInput.length;
        Order[] memory orders = new Order[](i);
        while(i-- != 0){
            orders[i] = orderFromInput(orderInput[i]);
        }
        
        // Parse RingTrades from packed input
        i = tradeInput.length;
        RingTrade[] memory trades = new RingTrade[](i);
        while(i-- != 0){
            trades[i] = ringTradeFromInput(tradeInput[i]);
        }
        
        uint256 prev = trades.length - 1;
        uint256 next = 1;
         // Loop through the RingTrades array and settle each participants trade
        for(i = 0; i < trades.length; i++){
            
            require(
                // Check if the charged fee is not too high
                trades[i].fee       <= trades[prev].giveAmount / 20
                
                // Check if maker_rebate is smaller than or equal to the taker's fee which compensates it
                && trades[i].rebate <= trades[next].fee
            );
            
            if(trades[i].isReserve){ // Ring element is a reserve
                address reserve = reserves[trades[i].identifier];

                if(i == 0){
                    require(
                        dexBlueReserve(reserve).offer(
                            trades[i].giveToken,                                   // The token the reserve would sell
                            trades[i].giveAmount - trades[i].rebate,               // The amount the reserve would sell
                            trades[prev].giveToken,                                // The token the reserve would receive
                            trades[prev].giveAmount - trades[i].fee                // The amount the reserve would receive
                        )
                        && balances[trades[i].giveToken][reserve] >= trades[i].giveAmount
                    );
                }else{
                    uint256 receiveAmount = trades[prev].giveAmount - trades[i].fee;

                    if(trades[prev].giveToken != address(0)){
                        Token(trades[prev].giveToken).transfer(reserve, receiveAmount);  // Send collateral to reserve
                        require(                                                         // Revert if the send failed
                            checkERC20TransferSuccess(),
                            "ERC20 token transfer failed."
                        );
                    }

                    require(
                        dexBlueReserve(reserve).trade.value(
                            trades[prev].giveToken == address(0) ? receiveAmount : 0
                        )(             
                            trades[prev].giveToken,
                            receiveAmount,                                      // Reserve gets the reserve_buy_amount minus the fee
                            trades[i].giveToken,    
                            trades[i].giveAmount - trades[i].rebate             // Reserve has to give reserve_sell_amount minus the rebate
                        )
                    );
                }

                // Substract deposited amount from reserves balance
                balances[trades[i].giveToken][reserve] -= trades[i].giveAmount - trades[i].rebate;

                emit LogDirectWithdrawal(reserve, trades[prev].giveToken, trades[prev].giveAmount - trades[i].fee);
            }else{ // Ring element is an order
                
                Order memory order = orders[trades[i].identifier];  // Cache order

                uint256 orderMatched = matched[order.hash];
                
                require(
                    // Does the order signee want to trade the last elements giveToken and this elements giveToken
                       order.buyToken  == trades[prev].giveToken
                    && order.sellToken == trades[i].giveToken
                    
                    // Is the order still valid
                    && order.expiry > block.timestamp
                    
                    // Does the order signee hold the required balances
                    && balances[order.sellToken][order.signee] >= trades[i].giveAmount - trades[i].rebate
                    
                    // Is the order matched at a rate better or equal to the one the order signee signed
                    && trades[i].giveAmount - trades[i].rebate <= order.sellAmount * trades[prev].giveAmount / order.buyAmount + 1  // Check order doesn't overpay (+ 1 to deal with rouding errors for very smal amounts)
                    
                    // Check if the order was cancelled
                    && order.sellAmount > orderMatched
                    
                    // Do the matched amount + previously matched trades not exceed the amount specified by the order signee
                    && trades[i].giveAmount - trades[i].rebate + orderMatched <= order.sellAmount
                );
                
                // Substract the sold amounts
                balances[order.sellToken       ][order.signee] -= trades[i].giveAmount - trades[i].rebate;      // Substract sold amount minus the makers rebate from order signees balance
                
                // Add bought amounts
                balances[trades[prev].giveToken][order.signee] += trades[prev].giveAmount - trades[i].fee;      // Give the order signee his bought amount minus the fee
                
                // Save sold amounts to prevent double matching
                matched[order.hash] += trades[i].giveAmount - trades[i].rebate;                                 // Prevent order from being reused
                
                // Set potential previous blocking of these funds to 0
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                           // If the order signee tried to block funds which he/she used in this order we have to unblock them
            }

            emit LogTrade(trades[prev].giveToken, trades[prev].giveAmount, trades[i].giveToken, trades[i].giveAmount);
            
            // Give fee to feeCollector
            balances[trades[prev].giveToken][feeCollector] += trades[i].fee - trades[prev].rebate;              // Give the feeColletor the fee minus the maker rebate 
            
            prev = i;
            if(i == trades.length - 2){
                next = 0;
            }else{
                next = i + 2;
            }
        }

        if(trades[0].isReserve){
            address payable reserve = reserves[trades[0].identifier];
            prev = trades.length - 1;
            
            if(trades[prev].giveToken == address(0)){                                                       // Is the withdrawal token ETH
                require(
                    reserve.send(trades[prev].giveAmount - trades[0].fee),                                  // Withdraw ETH
                    "Sending of ETH failed."
                );
            }else{
                Token(trades[prev].giveToken).transfer(reserve, trades[prev].giveAmount - trades[0].fee);   // Withdraw ERC20
                require(                                                                                    // Revert if the withdrawal failed
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

            // Notify the reserve, that the offer got executed
            dexBlueReserve(reserve).offerExecuted(
                trades[0].giveToken,                                   // The token the reserve sold
                trades[0].giveAmount - trades[0].rebate,               // The amount the reserve sold
                trades[prev].giveToken,                                // The token the reserve received
                trades[prev].giveAmount - trades[0].fee                // The amount the reserve received
            );
        }
    }
    
    
    /** @notice Allow arbiters to settle a ring of order and reserve trades, passing on some data to the reserves
      * @param  orderInput Array of OrderInputPacked structs
      * @param  tradeInput Array of RingTradeInputPacked structs
      * @param  data       Array of data to pass along to the reserves
      */
    function settleRingTradeWithData(
        OrderInputPacked[]     calldata orderInput,
        RingTradeInputPacked[] calldata tradeInput,
        bytes32[][]            calldata data
    ) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        // Parse Orders from packed input
        uint256 i = orderInput.length;
        Order[] memory orders = new Order[](i);
        while(i-- != 0){
            orders[i] = orderFromInput(orderInput[i]);
        }
        
        // Parse RingTrades from packed input
        i = tradeInput.length;
        RingTrade[] memory trades = new RingTrade[](i);
        while(i-- != 0){
            trades[i] = ringTradeFromInput(tradeInput[i]);
        }
        
        uint256 prev = trades.length - 1;
        uint256 next = 1;
         // Loop through the RingTrades array and settle each participants trade
        for(i = 0; i < trades.length; i++){
            
            require(
                // Check if the charged fee is not too high
                trades[i].fee       <= trades[prev].giveAmount / 20
                
                // Check if maker_rebate is smaller than or equal to the taker's fee which compensates it
                && trades[i].rebate <= trades[next].fee
            );
            
            if(trades[i].isReserve){ // ring element is a reserve
                address reserve = reserves[trades[i].identifier];

                if(i == 0){
                    require(
                        dexBlueReserve(reserve).offerWithData(
                            trades[i].giveToken,                                   // The token the reserve would sell
                            trades[i].giveAmount - trades[i].rebate,               // The amount the reserve would sell
                            trades[prev].giveToken,                                // The token the reserve would receive
                            trades[prev].giveAmount - trades[i].fee,               // The amount the reserve would receive
                            data[i]                                                // The data to pass along to the reserve
                        )
                        && balances[trades[i].giveToken][reserve] >= trades[i].giveAmount
                    );
                }else{
                    uint256 receiveAmount = trades[prev].giveAmount - trades[i].fee;

                    if(trades[prev].giveToken != address(0)){
                        Token(trades[prev].giveToken).transfer(reserve, receiveAmount);  // Send collateral to reserve
                        require(                                                         // Revert if the send failed
                            checkERC20TransferSuccess(),
                            "ERC20 token transfer failed."
                        );
                    }

                    require(
                        dexBlueReserve(reserve).tradeWithData.value(
                            trades[prev].giveToken == address(0) ? receiveAmount : 0
                        )(             
                            trades[prev].giveToken,
                            receiveAmount,                                      // Reserve gets the reserve_buy_amount minus the fee
                            trades[i].giveToken,    
                            trades[i].giveAmount - trades[i].rebate,            // Reserve has to give reserve_sell_amount minus the reserve rebate
                            data[i]                                             // The data to pass along to the reserve
                        )
                    );
                }

                // Substract deposited amount from reserves balance
                balances[trades[i].giveToken][reserve] -= trades[i].giveAmount - trades[i].rebate;

                emit LogDirectWithdrawal(reserve, trades[prev].giveToken, trades[prev].giveAmount - trades[i].fee);
            }else{ // Ring element is an order
                
                Order memory order = orders[trades[i].identifier];  // Cache order

                uint256 orderMatched = matched[order.hash];
                
                require(
                    // Does the order signee want to trade the last elements giveToken and this elements giveToken
                       order.buyToken  == trades[prev].giveToken
                    && order.sellToken == trades[i].giveToken
                    
                    // Is the order still valid
                    && order.expiry > block.timestamp
                    
                    // Does the order signee hold the required balances
                    && balances[order.sellToken][order.signee] >= trades[i].giveAmount - trades[i].rebate
                    
                    // Is the order matched at a rate better or equal to the one the order signee signed
                    && trades[i].giveAmount - trades[i].rebate <= order.sellAmount * trades[prev].giveAmount / order.buyAmount + 1  // Check order doesn't overpay (+ 1 to deal with rouding errors for very smal amounts)
                    
                    // Check if the order was cancelled
                    && order.sellAmount > orderMatched
                    
                    // Do the matched amount + previously matched trades not exceed the amount specified by the order signee
                    && trades[i].giveAmount - trades[i].rebate + orderMatched <= order.sellAmount
                );
                
                // Substract the sold amounts
                balances[order.sellToken       ][order.signee] -= trades[i].giveAmount - trades[i].rebate;      // Substract sold amount minus the makers rebate from order signees balance
                
                // Add bought amounts
                balances[trades[prev].giveToken][order.signee] += trades[prev].giveAmount - trades[i].fee;      // Give the order signee his bought amount minus the fee
                
                // Save sold amounts to prevent double matching
                matched[order.hash] += trades[i].giveAmount - trades[i].rebate;                                 // Prevent order from being reused
                
                // Set potential previous blocking of these funds to 0
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                           // If the order signee tried to block funds which he/she used in this order we have to unblock them
            }

            emit LogTrade(trades[prev].giveToken, trades[prev].giveAmount, trades[i].giveToken, trades[i].giveAmount);
            
            // Give fee to feeCollector
            balances[trades[prev].giveToken][feeCollector] += trades[i].fee - trades[prev].rebate;              // Give the feeColletor the fee minus the maker rebate 
            
            prev = i;
            if(i == trades.length - 2){
                next = 0;
            }else{
                next = i + 2;
            }
        }

        if(trades[0].isReserve){
            address payable reserve = reserves[trades[0].identifier];
            prev = trades.length - 1;
            
            if(trades[prev].giveToken == address(0)){                                                       // Is the withdrawal token ETH
                require(
                    reserve.send(trades[prev].giveAmount - trades[0].fee),                                  // Withdraw ETH
                    "Sending of ETH failed."
                );
            }else{
                Token(trades[prev].giveToken).transfer(reserve, trades[prev].giveAmount - trades[0].fee);   // Withdraw ERC20
                require(                                                                                    // Revert if the withdrawal failed
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

            // Notify the reserve, that the offer got executed
            dexBlueReserve(reserve).offerExecuted(
                trades[0].giveToken,                                   // The token the reserve sold
                trades[0].giveAmount - trades[0].rebate,               // The amount the reserve sold
                trades[prev].giveToken,                                // The token the reserve received
                trades[prev].giveAmount - trades[0].fee                // The amount the reserve received
            );
        }
    }
    
    
    // Swapping functions
    
    /** @notice Queries best output for a trade currently available from the reserves
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @return The output amount the reserve with the best price offers
    */
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns (uint256){
        (, uint256 output) = getBestReserve(sell_token, sell_amount, buy_token);
        return output;
    }
    
    /** @notice Queries the reserve address and output of trade, of the reserve which offers the best deal on a trade
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @return The address of the reserve offering the best deal and the expected output of the trade
    */
    function getBestReserve(address sell_token, uint256 sell_amount, address buy_token) public view returns (address, uint256){
        address bestReserve;
        uint256 bestOutput = 0;
        uint256 output;
        
        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            output = dexBlueReserve(public_reserve_arr[i]).getSwapOutput(sell_token, sell_amount, buy_token);
            if(output > bestOutput){
                bestOutput  = output;
                bestReserve = public_reserve_arr[i];
            }
        }
        
        return (bestReserve, bestOutput);
    }
    
    /** @notice Allows users to swap a token or ETH with the reserve offering the best price for his trade
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @param  min_output   The minimum amount of buy_token, the trade should result in 
      * @param  deadline     The timestamp after which the transaction should not be executed
      * @return The amount of buy_token the user receives
    */
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, uint256 deadline) external payable returns(uint256){        
        require(
            (
                deadline == 0                               // No deadline is set         
                || deadline > block.timestamp               // Deadline is met
            ),                                              // Check whether the deadline is met
            "Call deadline exceeded."
        );
        
        (address reserve, uint256 amount) = getBestReserve(sell_token, sell_amount, buy_token);     // Check which reserve offers the best deal on the trade
        
        require(
            amount >= min_output,                                                                   // Check whether the best reserves deal is good enough
            "Too much slippage"
        );
        
        return swapWithReserve(sell_token, sell_amount, buy_token,  min_output, reserve, deadline); // Execute the swap with the best reserve
    }
    
    /** @notice Allows users to swap a token or ETH with a specified reserve
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @param  min_output   The minimum amount of buy_token, the trade should result in 
      * @param  reserve      The address of the reserve to trade with
      * @param  deadline     The timestamp after which the transaction should not be executed
    */
    function swapWithReserve(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, address reserve, uint256 deadline) public payable returns (uint256){
        require(
            (
                deadline == 0                               // No deadline is set         
                || deadline > block.timestamp               // Deadline is met
            ),
            "Call deadline exceeded."
        );
        
        require(
            public_reserves[reserve],                       // Check whether the reserve is registered
            "Unknown reserve."
        );
        
        if(sell_token == address(0)){                       // Caller wants to swap ETH
            require(
                msg.value == sell_amount,                   // Check whether the caller sent the required ETH
                "ETH amount not sent with the call."
            );
        }else{                                              // Caller wants to swap a token
            require(
                msg.value == 0,                             // Check the caller hasn't sent any ETH with the call
                "Don't send ETH when swapping a token."
            );
            
            Token(sell_token).transferFrom(msg.sender, reserve, sell_amount);   // Deposit ERC20 into the reserve
            
            require(
                checkERC20TransferSuccess(),                // Check whether the ERC20 token transfer was successful
                "ERC20 token transfer failed."
            );
        }
        
        // Execute the swap with the reserve
        uint256 output = dexBlueReserve(reserve).swap.value(msg.value)(
            sell_token,
            sell_amount,
            buy_token,
            min_output
        );
        
        if(
            output >= min_output                                // Check whether the output amount is sufficient 
            && balances[buy_token][reserve] >= output           // Check whether the reserve deposited the output amount
        ){
            balances[buy_token][reserve] -= output;             // Substract the amount from the reserves balance
            
            if(buy_token == address(0)){                        // Is the bought asset ETH
                require(
                    msg.sender.send(output),                    // Send the output ETH of the swap to msg.sender
                    "Sending of ETH failed."
                );
            }else{
                Token(buy_token).transfer(msg.sender, output);  // Transfer the output token of the swap msg.sender
                require(                                        // Revert if the transfer failed
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

            emit LogSwap(sell_token, sell_amount, buy_token, output);
            
            return output;
        }else{
            revert("Too much slippage.");
        }
    }
}

contract dexBlue is dexBlueStorage, dexBlueEvents, dexBlueUtils, dexBlueStructs{
    // Hardcode settlement module contract:
    address constant settlementModuleAddress = 0x9e3d5C6ffACA00cAf136609680b536DC0Eb20c66;

    // Deposit functions:

    /** @notice Deposit Ether into the smart contract 
      */
    function depositEther() public payable{
        balances[address(0)][msg.sender] += msg.value;          // Add the received ETH to the users balance
        emit LogDeposit(msg.sender, address(0), msg.value);     // emit LogDeposit event
    }
    
    /** @notice Fallback function to credit ETH sent to the contract without data 
      */
    function() external payable{
        if(msg.sender != wrappedEtherContract){     // ETH sends from WETH contract are handled in the depositWrappedEther() function
            depositEther();                 // Call the deposit function to credit ETH sent in this transaction
        }
    }
    
    /** @notice Deposit Wrapped Ether (remember to set allowance in the token contract first)
      * @param  amount  The amount of WETH to deposit 
      */
    address constant wrappedEtherContract = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // We hardcode the address, to prevent misbehaviour through custom contracts (reentrancy etc)
    function depositWrappedEther(uint256 amount) external {
        
        Token(wrappedEtherContract).transferFrom(msg.sender, address(this), amount);    // Transfer WETH to this contract
        
        require(
            checkERC20TransferSuccess(),                                        // Check whether the ERC20 token transfer was successful
            "WETH deposit failed."
        );
        
        uint balanceBefore = address(this).balance;                             // Remember ETH balance before the call
        
        WETH(wrappedEtherContract).withdraw(amount);                            // Unwrap the WETH
        
        require(balanceBefore + amount == address(this).balance);               // Check whether the ETH was deposited
        
        balances[address(0)][msg.sender] += amount;                             // Credit the deposited eth to users balance
        
        emit LogDeposit(msg.sender, address(0), amount);                        // emit LogDeposit event
    }
    
    /** @notice Deposit ERC20 tokens into the smart contract (remember to set allowance in the token contract first)
      * @param  token   The address of the token to deposit
      * @param  amount  The amount of tokens to deposit 
      */
    function depositToken(address token, uint256 amount) external {
        Token(token).transferFrom(msg.sender, address(this), amount);    // Deposit ERC20
        require(
            checkERC20TransferSuccess(),                                 // Check whether the ERC20 token transfer was successful
            "ERC20 token transfer failed."
        );
        balances[token][msg.sender] += amount;                           // Credit the deposited token to users balance
        emit LogDeposit(msg.sender, token, amount);                      // emit LogDeposit event
    }
        
    // Multi-sig withdrawal functions:

    /** @notice User-submitted withdrawal with arbiters signature, which withdraws to the users address
      * @param  token   The token to withdraw (ETH is address(address(0)))
      * @param  amount  The amount of tokens to withdraw
      * @param  nonce   The nonce (to salt the hash)
      * @param  v       Multi-signature v
      * @param  r       Multi-signature r
      * @param  s       Multi-signature s 
      */
    function multiSigWithdrawal(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s) external {
        multiSigSend(token, amount, nonce, v, r, s, msg.sender); // Call multiSigSend to send funds to msg.sender
    }    

    /** @notice User-submitted withdrawal with arbiters signature, which sends tokens to specified address
      * @param  token              The token to withdraw (ETH is address(address(0)))
      * @param  amount             The amount of tokens to withdraw
      * @param  nonce              The nonce (to salt the hash)
      * @param  v                  Multi-signature v
      * @param  r                  Multi-signature r
      * @param  s                  Multi-signature s
      * @param  receiving_address  The address to send the withdrawn token/ETH to
      */
    function multiSigSend(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address payable receiving_address) public {
        bytes32 hash = keccak256(abi.encodePacked(                      // Calculate the withdrawal hash from the parameters 
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                msg.sender,
                token,
                amount,
                nonce,
                address(this)
            ))
        ));
        if(
            !processed_withdrawals[hash]                                // Check if the withdrawal was initiated before
            && arbiters[ecrecover(hash, v,r,s)]                         // Check if the multi-sig is valid
            && balances[token][msg.sender] >= amount                    // Check if the user holds the required balance
        ){
            processed_withdrawals[hash]  = true;                        // Mark this withdrawal as processed
            balances[token][msg.sender] -= amount;                      // Substract the withdrawn balance from the users balance
            
            if(token == address(0)){                                    // Process an ETH withdrawal
                require(
                    receiving_address.send(amount),
                    "Sending of ETH failed."
                );
            }else{                                                      // Withdraw an ERC20 token
                Token(token).transfer(receiving_address, amount);       // Transfer the ERC20 token
                require(
                    checkERC20TransferSuccess(),                        // Check whether the ERC20 token transfer was successful
                    "ERC20 token transfer failed."
                );
            }

            blocked_for_single_sig_withdrawal[token][msg.sender] = 0;   // Set potential previous blocking of these funds to 0
            
            emit LogWithdrawal(msg.sender,token,amount);                // emit LogWithdrawal event
        }else{
            revert();                                                   // Revert the transaction if checks fail
        }
    }

    /** @notice User-submitted transfer with arbiters signature, which sends tokens to another addresses account in the smart contract
      * @param  token              The token to transfer (ETH is address(address(0)))
      * @param  amount             The amount of tokens to transfer
      * @param  nonce              The nonce (to salt the hash)
      * @param  v                  Multi-signature v
      * @param  r                  Multi-signature r
      * @param  s                  Multi-signature s
      * @param  receiving_address  The address to transfer the token/ETH to
      */
    function multiSigTransfer(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address receiving_address) external {
        bytes32 hash = keccak256(abi.encodePacked(                      // Calculate the withdrawal/transfer hash from the parameters 
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                msg.sender,
                token,
                amount,
                nonce,
                address(this)
            ))
        ));
        if(
            !processed_withdrawals[hash]                                // Check if the withdrawal was initiated before
            && arbiters[ecrecover(hash, v,r,s)]                         // Check if the multi-sig is valid
            && balances[token][msg.sender] >= amount                    // Check if the user holds the required balance
        ){
            processed_withdrawals[hash]         = true;                 // Mark this withdrawal as processed
            balances[token][msg.sender]        -= amount;               // Substract the balance from the withdrawing account
            balances[token][receiving_address] += amount;               // Add the balance to the receiving account
            
            blocked_for_single_sig_withdrawal[token][msg.sender] = 0;   // Set potential previous blocking of these funds to 0
            
            emit LogWithdrawal(msg.sender,token,amount);                // emit LogWithdrawal event
            emit LogDeposit(receiving_address,token,amount);            // emit LogDeposit event
        }else{
            revert();                                                   // Revert the transaction if checks fail
        }
    }
    
    /** @notice Arbiter submitted withdrawal with users multi-sig to users address
      * @param  packedInput1 tightly packed input arguments:
      *             amount  The amount of tokens to withdraw
      *             fee     The fee, covering the gas cost of the arbiter
      * @param  packedInput2 tightly packed input arguments:
      *             token           The token to withdraw (ETH is address(address(0)))
      *             nonce           The nonce (to salt the hash)
      *             v               Multi-signature v (either 27 or 28. To identify the different signing schemes an offset of 10 is applied for EIP712)
      *             signing_scheme  The signing scheme of the users signature
      *             burn_gas_tokens The amount of gas tokens to burn
      * @param  r       Multi-signature r
      * @param  s       Multi-signature s
      */
    function userSigWithdrawal(bytes32 packedInput1, bytes32 packedInput2, bytes32 r, bytes32 s) external {
        /* 
            BITMASK packedInput1                                               | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 |  0-15      | amount
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff | 16-31      | gas fee
            
            BITMASK packedInput2                                               | BYTE RANGE | DESCRIPTION
            -------------------------------------------------------------------|------------|----------------------------------
            0xffff000000000000000000000000000000000000000000000000000000000000 |  0- 1      | token identifier
            0x0000ffffffffffffffff00000000000000000000000000000000000000000000 |  2- 9      | nonce
            0x00000000000000000000ff000000000000000000000000000000000000000000 | 10-10      | v
            0x0000000000000000000000ff0000000000000000000000000000000000000000 | 11-11      | signing scheme 0x00 = personal.sign, 0x01 = EIP712
            0x000000000000000000000000ff00000000000000000000000000000000000000 | 12-12      | burn_gas_tokens
        */
        // parse the packed input parameters
        uint256 amount = uint256(packedInput1 >> 128);
        uint256 fee    = uint256(packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
        address token  = tokens[uint256(packedInput2 >> 240)];
        uint64  nonce  = uint64(uint256((packedInput2 & 0x0000ffffffffffffffff00000000000000000000000000000000000000000000) >> 176));
        uint8   v      = uint8(packedInput2[10]);

        bytes32 hash;
        if(packedInput2[11] == byte(0x00)){                             // Standard signing scheme (personal.sign())
            hash = keccak256(abi.encodePacked(                          // Restore multi-sig hash
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    token,
                    amount,
                    nonce,
                    address(this)
                ))
            ));
        }else{                                                          // EIP712 signing scheme
            hash = keccak256(abi.encodePacked(                          // Restore multi-sig hash
                "\x19\x01",
                EIP712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    EIP712_WITHDRAWAL_TYPEHASH,
                    token,
                    amount,
                    nonce
                ))
            ));
        }

        address payable account = address(uint160(ecrecover(hash, v, r, s)));   // Restore signing address
        
        if(
            !processed_withdrawals[hash]                                // Check if the withdrawal was initiated before
            && arbiters[msg.sender]                                     // Check if transaction comes from arbiter
            && fee <= amount / 20                                       // Check if fee is not too big
            && balances[token][account] >= amount                       // Check if the user holds the required tokens
        ){
            processed_withdrawals[hash]    = true;                      // Mark the withdrawal as processed
            balances[token][account]      -= amount;                    // Deduct the withdrawn tokens from the users balance
            balances[token][feeCollector] += fee;                       // Fee to cover gas costs for the withdrawal
            
            if(token == address(0)){                                    // Send ETH
                require(
                    account.send(amount - fee),
                    "Sending of ETH failed."
                );
            }else{
                Token(token).transfer(account, amount - fee);           // Withdraw ERC20
                require(
                    checkERC20TransferSuccess(),                        // Check if the transfer was successful
                    "ERC20 token transfer failed."
                );
            }
        
            blocked_for_single_sig_withdrawal[token][account] = 0;      // Set potential previous blocking of these funds to 0
            
            emit LogWithdrawal(account,token,amount);                   // emit LogWithdrawal event
            
            // burn gas tokens
            if(packedInput2[12] != byte(0x00)){
                spendGasTokens(uint8(packedInput2[12]));
            }
        }else{
            revert();                                                   // Revert the transaction is checks fail
        }
    }
    
    // Single-sig withdrawal functions:

    /** @notice Allows user to block funds for single-sig withdrawal after 24h waiting period 
      *         (This period is necessary to ensure all trades backed by these funds will be settled.)
      * @param  token   The address of the token to block (ETH is address(address(0)))
      * @param  amount  The amount of the token to block
      */
    function blockFundsForSingleSigWithdrawal(address token, uint256 amount) external {
        if (balances[token][msg.sender] - blocked_for_single_sig_withdrawal[token][msg.sender] >= amount){  // Check if the user holds the required funds
            blocked_for_single_sig_withdrawal[token][msg.sender] += amount;                                 // Block funds for manual withdrawal
            last_blocked_timestamp[msg.sender] = block.timestamp;                                           // Start waiting period
            emit LogBlockedForSingleSigWithdrawal(msg.sender, token, amount);                               // emit LogBlockedForSingleSigWithdrawal event
        }else{
            revert();                                                                                       // Revert the transaction if the user does not hold the required balance
        }
    }
    
    /** @notice Allows user to withdraw blocked funds without multi-sig after the waiting period
      * @param  token   The address of the token to withdraw (ETH is address(address(0)))
      * @param  amount  The amount of the token to withdraw
      */
    function initiateSingleSigWithdrawal(address token, uint256 amount) external {
        if (
            balances[token][msg.sender] >= amount                                   // Check if the user holds the funds
            && (
                (
                    blocked_for_single_sig_withdrawal[token][msg.sender] >= amount                          // Check if these funds are blocked
                    && last_blocked_timestamp[msg.sender] + single_sig_waiting_period <= block.timestamp    // Check if the waiting period has passed
                )
                || single_sig_waiting_period == 0                                                           // or the waiting period is disabled
            )
        ){
            balances[token][msg.sender] -= amount;                                  // Substract the tokens from users balance

            if(blocked_for_single_sig_withdrawal[token][msg.sender] >= amount){
                blocked_for_single_sig_withdrawal[token][msg.sender] = 0;     // Substract the tokens from users blocked balance
            }
            
            if(token == address(0)){                                                // Withdraw ETH
                require(
                    msg.sender.send(amount),
                    "Sending of ETH failed."
                );
            }else{                                                                  // Withdraw ERC20 tokens
                Token(token).transfer(msg.sender, amount);                          // Transfer the ERC20 tokens
                require(
                    checkERC20TransferSuccess(),                                    // Check if the transfer was successful
                    "ERC20 token transfer failed."
                );
            }
            
            emit LogSingleSigWithdrawal(msg.sender, token, amount);                 // emit LogSingleSigWithdrawal event
        }else{
            revert();                                                               // Revert the transaction if the required checks fail
        }
    } 

    //Trade settlement structs and function

    /** @notice Allows an arbiter to settle a trade between two orders
      * @param  makerOrderInput  The packed maker order input
      * @param  takerOrderInput  The packed taker order input
      * @param  tradeInput       The packed trade to settle between the two
      */ 
    function settleTrade(OrderInputPacked calldata makerOrderInput, OrderInputPacked calldata takerOrderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);   // Check if msg.sender is an arbiter and the market is active

        settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module
        
        // burn gas tokens
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }

    /** @notice Allows an arbiter to settle a trade between an order and a reserve
      * @param  orderInput  The packed maker order input
      * @param  tradeInput  The packed trade to settle between the two
      */ 
    function settleReserveTrade(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);   // Check if msg.sender is an arbiter and the market is active

        settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module
        
        // burn gas tokens
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }

    /** @notice Allows an arbiter to settle a trade between an order and a reserve, passing some additional data to the reserve
      * @param  orderInput  The packed maker order input
      * @param  tradeInput  The packed trade to settle between the two
      * @param  data        The data to pass on to the reserve
      */ 
    function settleReserveTradeWithData(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput, bytes32[] calldata data) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module
        
        // burn gas tokens
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    
    /** @notice Allows an arbiter to settle a trade between two reserves
      * @param  tradeInput  The packed trade to settle between the two
      */ 
    function settleReserveReserveTrade(TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);          // Check if msg.sender is an arbiter and the market is active

        settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module
        
        // burn gas tokens
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    
    /** @notice Allows an arbiter to settle a trade between two reserves
      * @param  tradeInput  The packed trade to settle between the two
      * @param  makerData   The data to pass on to the maker reserve
      * @param  takerData   The data to pass on to the taker reserve
      */ 
    function settleReserveReserveTradeWithData(TradeInputPacked calldata tradeInput, bytes32[] calldata makerData, bytes32[] calldata takerData) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active
        
        settlementModuleAddress.delegatecall(msg.data);     // delegate the call to the settlement module
        
        // burn gas tokens
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    

    /** @notice Allows an arbiter to settle multiple trades between multiple orders and reserves
      * @param  orderInput     Array of all orders involved in the transactions
      * @param  tradeInput     Array of the trades to be settled
      */   
    function batchSettleTrades(OrderInputPacked[] calldata orderInput, TradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);          // Check if msg.sender is an arbiter and the market is active
        
        settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module
        
        // Loop through the trades and calc the gasToken sum
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput3[28]);
        }
        
        // burn gas tokens
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }

    /** @notice Allow arbiters to settle a ring of order and reserve trades
      * @param  orderInput Array of OrderInputPacked structs
      * @param  tradeInput Array of RingTradeInputPacked structs
      */
    function settleRingTrade(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active

        settlementModuleAddress.delegatecall(msg.data);
        
        // Loop through the trades and calc the gasToken sum
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput2[24]);
        }
        
        // burn gas tokens
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }

    /** @notice Allow arbiters to settle a ring of order and reserve trades, passing on some data to the reserves
      * @param  orderInput Array of OrderInputPacked structs
      * @param  tradeInput Array of RingTradeInputPacked structs
      * @param  data       Array of data to pass along to the reserves
      */
    function settleRingTradeWithData(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput, bytes32[][] calldata data) external {
        require(arbiters[msg.sender] && marketActive);      // Check if msg.sender is an arbiter and the market is active

        settlementModuleAddress.delegatecall(msg.data);
        
        // Loop through the trades and calc the gasToken sum
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput2[24]);
        }
        
        // burn gas tokens
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }


    /** @notice Helper function, callable only by the contract itself, to execute a trade between two reserves
      * @param  makerReserve  The maker reserve
      * @param  takerReserve  The taker reserve
      * @param  trade         The trade to settle between the two
      * @return Whether the trade succeeded or failed
      */
    function executeReserveReserveTrade(
        address             makerReserve,
        address payable     takerReserve,
        ReserveReserveTrade calldata trade
    ) external returns(bool){
        // this method is only callable from the contract itself
        // a call is used vs a jump, to be able to revert the sending of funds to the reserve without throwing the entire transaction
        require(msg.sender == address(this));                       // Check that the caller is the contract itself
        
        // Check whether the taker reserve accepts the trade
        require(
            dexBlueReserve(takerReserve).offer(                     
                trade.takerToken,                                   // The token we offer the reserve to sell
                trade.takerAmount,                                  // The amount the reserve could sell
                trade.makerToken,                                   // The token the reserve would receive
                trade.makerAmount - trade.takerFee                  // The amount the reserve would receive
            )
            && balances[trade.takerToken][takerReserve] >= trade.takerAmount    // Check whether the taker reserve deposited the collateral
        );
        
        balances[trade.takerToken][takerReserve] -= trade.takerAmount;          // Substract the deposited amount from the taker reserve
        
        if(trade.takerToken != address(0)){
            Token(trade.takerToken).transfer(makerReserve, trade.takerAmount - trade.makerFee);     // Send the taker reserves collateral to the maker reserve
            require(                                                                                // Revert if the send failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }
        
        // Check whether the maker reserve accepts the trade
        require(
            dexBlueReserve(makerReserve).trade.value(               // Execute the trade in the maker reserve
                trade.takerToken == address(0) ? 
                    trade.takerAmount - trade.makerFee              // Send the taker reserves collateral to the maker reserve
                    : 0
            )(
                trade.takerToken,                                   // The token the taker reserve is selling
                trade.takerAmount - trade.makerFee,                 // The amount of sellToken the taker reserve wants to sell
                trade.makerToken,                                   // The token the taker reserve wants in return
                trade.makerAmount                                   // The amount of token the taker reserve wants in return
            )
            && balances[trade.makerToken][makerReserve] >= trade.makerAmount  // Check whether the maker reserve deposited the collateral
        );

        balances[trade.makerToken][makerReserve] -= trade.makerAmount;                              // Substract the maker reserves's sold amount
        
        // Send the acquired amount to the taker reserve
        if(trade.makerToken == address(0)){                                                         // Is the acquired token ETH
            require(
                takerReserve.send(trade.makerAmount - trade.takerFee),                              // Send ETH
                "Sending of ETH failed."
            );
        }else{
            Token(trade.makerToken).transfer(takerReserve, trade.makerAmount - trade.takerFee);     // Transfer ERC20
            require(                                                                                // Revert if the transfer failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }

        // Notify the reserve, that the offer got executed
        dexBlueReserve(takerReserve).offerExecuted(                     
            trade.takerToken,                                   // The token the reserve sold
            trade.takerAmount,                                  // The amount the reserve sold
            trade.makerToken,                                   // The token the reserve received
            trade.makerAmount - trade.takerFee                  // The amount the reserve received
        );
        
        // Give fee to feeCollector
        balances[trade.makerToken][feeCollector] += trade.takerFee;  // Give feeColletor the taker fee
        balances[trade.takerToken][feeCollector] += trade.makerFee;  // Give feeColletor the maker fee
        
        emit LogTrade(trade.makerToken, trade.makerAmount, trade.takerToken, trade.takerAmount);
        
        emit LogDirectWithdrawal(makerReserve, trade.takerToken, trade.takerAmount - trade.makerFee);
        emit LogDirectWithdrawal(takerReserve, trade.makerToken, trade.makerAmount - trade.takerFee);
        
        return true;
    }

    /** @notice Helper function, callable only by the contract itself, to execute a trade between two reserves
      * @param  makerReserve  The maker reserve
      * @param  takerReserve  The taker reserve
      * @param  trade         The trade to settle between the two
      * @param  makerData     The data to pass on to the maker reserve
      * @param  takerData     The data to pass on to the taker reserve
      * @return Whether the trade succeeded or failed
      */
    function executeReserveReserveTradeWithData(
        address             makerReserve,
        address payable     takerReserve,
        ReserveReserveTrade calldata trade,
        bytes32[] calldata  makerData,
        bytes32[] calldata  takerData
    ) external returns(bool){
        // this method is only callable from the contract itself
        // a call is used vs a jump, to be able to revert the sending of funds to the reserve without throwing the entire transaction
        require(msg.sender == address(this));                       // Check that the caller is the contract itself
        
        // Check whether the taker reserve accepts the trade
        require(
            dexBlueReserve(takerReserve).offerWithData(                     
                trade.takerToken,                                   // The token we offer the reserve to sell
                trade.takerAmount,                                  // The amount the reserve could sell
                trade.makerToken,                                   // The token the reserve would receive
                trade.makerAmount - trade.takerFee,                 // The amount the reserve would receive
                takerData
            )
            && balances[trade.takerToken][takerReserve] >= trade.takerAmount    // Check whether the taker reserve deposited the collateral
        );
        
        balances[trade.takerToken][takerReserve] -= trade.takerAmount;          // Substract the deposited amount from the taker reserve
        
        if(trade.takerToken != address(0)){
            Token(trade.takerToken).transfer(makerReserve, trade.takerAmount - trade.makerFee);     // Send the taker reserves collateral to the maker reserve
            require(                                                                                // Revert if the send failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }
        
        // Check whether the maker reserve accepts the trade
        require(
            dexBlueReserve(makerReserve).tradeWithData.value(       // Execute the trade in the maker reserve
                trade.takerToken == address(0) ? 
                    trade.takerAmount - trade.makerFee              // Send the taker reserves collateral to the maker reserve
                    : 0
            )(
                trade.takerToken,                                   // The token the taker reserve is selling
                trade.takerAmount - trade.makerFee,                 // The amount of sellToken the taker reserve wants to sell
                trade.makerToken,                                   // The token the taker reserve wants in return
                trade.makerAmount,                                  // The amount of token the taker reserve wants in return
                makerData
            )
            && balances[trade.makerToken][makerReserve] >= trade.makerAmount  // Check whether the maker reserve deposited the collateral
        );

        balances[trade.makerToken][makerReserve] -= trade.makerAmount;                              // Substract the maker reserves's sold amount
        
        // Send the acquired amount to the taker reserve
        if(trade.makerToken == address(0)){                                                         // Is the acquired token ETH
            require(
                takerReserve.send(trade.makerAmount - trade.takerFee),                              // Send ETH
                "Sending of ETH failed."
            );
        }else{
            Token(trade.makerToken).transfer(takerReserve, trade.makerAmount - trade.takerFee);     // Transfer ERC20
            require(                                                                                // Revert if the transfer failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }

        // Notify the reserve, that the offer got executed
        dexBlueReserve(takerReserve).offerExecuted(                     
            trade.takerToken,                                   // The token the reserve sold
            trade.takerAmount,                                  // The amount the reserve sold
            trade.makerToken,                                   // The token the reserve received
            trade.makerAmount - trade.takerFee                  // The amount the reserve received
        );
        
        // Give fee to feeCollector
        balances[trade.makerToken][feeCollector] += trade.takerFee;  // Give feeColletor the taker fee
        balances[trade.takerToken][feeCollector] += trade.makerFee;  // Give feeColletor the maker fee
        
        emit LogTrade(trade.makerToken, trade.makerAmount, trade.takerToken, trade.takerAmount);
        
        emit LogDirectWithdrawal(makerReserve, trade.takerToken, trade.takerAmount - trade.makerFee);
        emit LogDirectWithdrawal(takerReserve, trade.makerToken, trade.makerAmount - trade.takerFee);
        
        return true;
    }

    /** @notice Helper function, callable only by the contract itself, to execute a trade with a reserve contract
      * @param  sellToken   The address of the token we want to sell (ETH is address(address(0)))
      * @param  sellAmount  The amount of sellToken we want to sell
      * @param  buyToken    The address of the token we want to buy (ETH is address(address(0)))
      * @param  buyAmount   The amount of buyToken we want in exchange for sellAmount
      * @param  reserve     The address of the reserve, we want to trade with
      */
    function executeReserveTrade(
        address    sellToken,
        uint256    sellAmount,
        address    buyToken,
        uint256    buyAmount,
        address    reserve
    ) external returns(bool){
        // this method is only callable from the contract itself
        // a call is used vs a jump, to be able to revert the sending of funds to the reserve without throwing the entire transaction
        require(msg.sender == address(this));                   // check that the caller is the contract itself
        
        if(sellToken == address(0)){
            require(dexBlueReserve(reserve).trade.value(        // execute the trade in the reserve
                                                                // if the reserve accepts the trade, it will deposit the buyAmount and return true
                sellAmount                                      // send collateral to reserve
            )(
                sellToken,                                      // the token we want to sell
                sellAmount,                                     // the amount of sellToken we want to exchange
                buyToken,                                       // the token we want to receive
                buyAmount                                       // the quantity of buyToken we demand in return
            ));
        }else{
            Token(sellToken).transfer(reserve, sellAmount);     // send collateral to reserve
            require(                                            // revert if the send failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
            
            require(dexBlueReserve(reserve).trade(              // execute the trade in the reserve
                sellToken,                                      // the token we want to sell
                sellAmount,                                     // the amount of sellToken we want to exchange
                buyToken,                                       // the token we want to receive
                buyAmount                                       // the quantity of buyToken we demand in return
            ));
        }
        
        require(balances[buyToken][reserve] >= buyAmount);      // check if the reserve delivered on the request, else revert
        
        return true;                                            // return true if all checks are passed and the trade was executed successfully
    }
    
    /** @notice private function to execute a trade with a reserve contract
      * @param  sellToken   The address of the token we want to sell (ETH is address(address(0)))
      * @param  sellAmount  The amount of sellToken we want to sell
      * @param  buyToken    The address of the token we want to buy (ETH is address(address(0)))
      * @param  buyAmount   The amount of buyToken we want in exchange for sellAmount
      * @param  reserve     The address of the reserve, we want to trade with
      * @param  data        The data passed on to the reserve
      */
    function executeReserveTradeWithData(
        address    sellToken,
        uint256    sellAmount,
        address    buyToken,
        uint256    buyAmount,
        address    reserve,
        bytes32[]  calldata data
    ) external returns(bool){
        // this method is only callable from the contract itself
        // a call is used vs a jump, to be able to revert the sending of funds to the reserve without throwing the entire transaction
        require(msg.sender == address(this));                   // check that the caller is the contract itself
        
        if(sellToken == address(0)){
            require(dexBlueReserve(reserve).tradeWithData.value(// execute the trade in the reserve
                                                                // if the reserve accepts the trade, it will deposit the buyAmount and return true
                sellAmount                                      // send collateral to reserve
            )(
                sellToken,                                      // the token we want to sell
                sellAmount,                                     // the amount of sellToken we want to exchange
                buyToken,                                       // the token we want to receive
                buyAmount,                                      // the quantity of buyToken we demand in return
                data                                            // the data passed on to the reserve
            ));
        }else{
            Token(sellToken).transfer(reserve, sellAmount);     // send collateral to reserve
            require(                                            // revert if the send failed
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
            require(dexBlueReserve(reserve).tradeWithData(      // execute the trade in the reserve
                sellToken,                                      // the token we want to sell
                sellAmount,                                     // the amount of sellToken we want to exchange
                buyToken,                                       // the token we want to receive
                buyAmount,                                      // the quantity of buyToken we demand in return
                data                                            // the data passed on to the reserve
            ));
        }
        
        require(balances[buyToken][reserve] >= buyAmount);      // check if the reserve delivered on the request, else revert
        
        return true;                                            // return true if all checks are passed and the trade was executed successfully
    }


    // Token swapping functionality

    /** @notice Queries best output for a trade currently available from the reserves
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @return The output amount the reserve with the best price offers
    */
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns (uint256){
        (, uint256 output) = getBestReserve(sell_token, sell_amount, buy_token);
        return output;
    }

    /** @notice Queries the reserve address and output of trade, of the reserve which offers the best deal on a trade
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @return The address of the reserve offering the best deal and the expected output of the trade
    */
    function getBestReserve(address sell_token, uint256 sell_amount, address buy_token) public view returns (address, uint256){
        address bestReserve;
        uint256 bestOutput = 0;
        uint256 output;
        
        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            output = dexBlueReserve(public_reserve_arr[i]).getSwapOutput(sell_token, sell_amount, buy_token);
            if(output > bestOutput){
                bestOutput  = output;
                bestReserve = public_reserve_arr[i];
            }
        }
        
        return (bestReserve, bestOutput);
    }

    /** @notice Allows users to swap a token or ETH with the reserve offering the best price for his trade
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @param  min_output   The minimum amount of buy_token, the trade should result in 
      * @param  deadline     The timestamp after which the transaction should not be executed
      * @return The amount of buy_token the user receives
    */
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, uint256 deadline) external payable returns(uint256){

        (bool success, bytes memory returnData) = settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module

        require(success);

        return abi.decode(returnData, (uint256));
    }

    /** @notice Allows users to swap a token or ETH with a specified reserve
      * @param  sell_token   The token the user wants to sell (ETH is address(0))
      * @param  sell_amount  The amount of sell_token to sell
      * @param  buy_token    The token the user wants to acquire (ETH is address(0))
      * @param  min_output   The minimum amount of buy_token, the trade should result in 
      * @param  reserve      The address of the reserve to trade with
      * @param  deadline     The timestamp after which the transaction should not be executed
    */
    function swapWithReserve(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, address reserve, uint256 deadline) public payable returns (uint256){
        
        (bool success, bytes memory returnData) = settlementModuleAddress.delegatecall(msg.data);  // delegate the call to the settlement module

        require(success);

        return abi.decode(returnData, (uint256));
    }

    
    // Order cancellation functions

    /** @notice Give the user the option to perform multiple on-chain cancellations of orders at once with arbiters multi-sig
      * @param  orderHashes Array of orderHashes of the orders to be canceled
      * @param  v           Multi-sig v
      * @param  r           Multi-sig r
      * @param  s           Multi-sig s
      */
    function multiSigOrderBatchCancel(bytes32[] calldata orderHashes, uint8 v, bytes32 r, bytes32 s) external {
        if(
            arbiters[                                               // Check if the signee is an arbiter
                ecrecover(                                          // Restore the signing address
                    keccak256(abi.encodePacked(                     // Restore the signed hash (hash of all orderHashes)
                        "\x19Ethereum Signed Message:\n32", 
                        keccak256(abi.encodePacked(orderHashes))
                    )),
                    v, r, s
                )
            ]
        ){
            uint256 len = orderHashes.length;
            for(uint256 i = 0; i < len; i++){
                matched[orderHashes[i]] = 2**256 - 1;               // Set the matched amount of all orders to the maximum
                emit LogOrderCanceled(orderHashes[i]);              // emit LogOrderCanceled event
            }
        }else{
            revert();
        }
    }
    
    
    // Gastoken functionality
    
    // This is heavily inspired and based on the work of the gastoken.io team @ initc3.org, kudos!
    // Why not use their implementation?
    // We can safe even more gas through: having a even shorter contract address (1 byte less), saving the call to their contract, their token logic, and other minor optimisations
    
    uint256 gas_token_nonce_head;
    uint256 gas_token_nonce_tail;
    
    /** @notice Get the available amount of gasTokens
      * @return The array of all indexed token addresses
      */
    function getAvailableGasTokens() view public returns (uint256 amount){
        return gas_token_nonce_head - gas_token_nonce_tail;
    }
    
    /** @notice Mint new gasTokens
      * @param  amount  The amount of gasTokens to mint
      */
    function mintGasTokens(uint amount) public {
        gas_token_nonce_head += amount;
        while(amount-- > 0){
            createChildContract();   
        }
    }
    
    /** @notice internal function to burn gasTokens
      * @param  amount  The amount of gasTokens to burn
      */
    function spendGasTokens(uint256 amount) internal {
        uint256 tail = gas_token_nonce_tail;
        
        if(amount <= gas_token_nonce_head - tail){
            
            // tail points to slot behind the last contract in the queue
            for (uint256 i = tail + 1; i <= tail + amount; i++) {
                restoreChildContractAddress(i).call("");
            }
    
            gas_token_nonce_tail = tail + amount;
        }
    }
    
    /** @notice internal helper function to create a child contract
      * @return The address of the created contract
      */
    function createChildContract() internal returns (address addr) {
        assembly {
            let solidity_free_mem_ptr := mload(0x40)
            mstore(solidity_free_mem_ptr, 0x746d541e251335090ac5b47176af4f7e3318585733ff6000526015600bf3) // Load contract bytecode into memory
            addr := create(0, add(solidity_free_mem_ptr, 2), 30)                                          // Create child contract
        }
    }
    
    /** @notice internal helper function to restore the address of a child contract for a given nonce
      * @param  nonce   The nonce of the child contract
      * @return The address of the child contract
      */
    function restoreChildContractAddress(uint256 nonce) view internal returns (address) {
        require(nonce <= 256**9 - 1);

        uint256 encoded;
        uint256 tot_bytes;

        if (nonce < 128) {
            // RLP(nonce) = nonce
            // add the encoded nonce to the encoded word
            encoded = nonce * 256**9;
            
            // [address_length(1) address(20) nonce_length(0) nonce(1)]
            tot_bytes = 22;
        } else {
            // RLP(nonce) = [num_bytes_in_nonce nonce]
            uint nonce_bytes = 1;
            // count nonce bytes
            uint mask = 256;
            while (nonce >= mask) {
                nonce_bytes += 1;
                mask        *= 256;
            }
            
            // add the encoded nonce to the word
            encoded = ((128 + nonce_bytes) * 256**9) +  // nonce length
                      (nonce * 256**(9 - nonce_bytes)); // nonce
                   
            // [address_length(1) address(20) nonce_length(1) nonce(1-9)]
            tot_bytes = 22 + nonce_bytes;
        }

        // add the prefix and encoded address to the encoded word
        encoded += ((192 + tot_bytes) * 256**31) +     // total length
                   ((128 + 20) * 256**30) +            // address length
                   (uint256(address(this)) * 256**10); // address(this)

        uint256 hash;

        assembly {
            let mem_start := mload(0x40)        // get a pointer to free memory
            mstore(0x40, add(mem_start, 0x20))  // update the pointer

            mstore(mem_start, encoded)          // store the rlp encoding
            hash := keccak256(mem_start,
                         add(tot_bytes, 1))     // hash the rlp encoding
        }

        // interpret hash as address (20 least significant bytes)
        return address(hash);
    }
    
        
    // Signature delegation

    /** @notice delegate an address to allow it to sign orders on your behalf
      * @param delegate  The address to delegate
      */
    function delegateAddress(address delegate) external {
        // set as delegate
        require(delegates[delegate] == address(0), "Address is already a delegate");
        delegates[delegate] = msg.sender;
        
        emit LogDelegateStatus(msg.sender, delegate, true);
    }
    
    /** @notice revoke the delegation of an address
      * @param  delegate  The delegated address
      * @param  v         Multi-sig v
      * @param  r         Multi-sig r
      * @param  s         Multi-sig s
      */
    function revokeDelegation(address delegate, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(              // Restore the signed hash
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                delegate,
                msg.sender,
                address(this)
            ))
        ));

        require(
            arbiters[ecrecover(hash, v, r, s)],     // Check if signee is an arbiter
            "MultiSig is not from known arbiter"
        );
        
        delegates[delegate] = address(1);           // Set to 1 not 0 to prevent double delegation, which would make old signed orders valid for the new delegator
        
        emit LogDelegateStatus(msg.sender, delegate, false);
    }
    

    // Management functions:

    /** @notice Constructor function. Sets initial roles and creates EIP712 Domain.
      */
    constructor() public {
        owner = msg.sender;             // Nominate sender to be the contract owner
        
        // create EIP712 domain seperator
        EIP712_Domain memory eip712Domain = EIP712_Domain({
            name              : "dex.blue",
            version           : "1",
            chainId           : 1,
            verifyingContract : address(this)
        });
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }
    
    /** @notice Allows the owner to change / disable the waiting period for a single sig withdrawal
      * @param  waiting_period The new waiting period
      */
    function changeSingleSigWaitingPeriod(uint256 waiting_period) external {
        require(
            msg.sender == owner             // only owner can set waiting period
            && waiting_period <= 86400      // max period owner can set is one day
        );
        
        single_sig_waiting_period = waiting_period;
    }
    
    /** @notice Allows the owner to handle over the ownership to another address
      * @param  new_owner The new owner address
      */
    function changeOwner(address payable new_owner) external {
        require(msg.sender == owner);
        owner = new_owner;
    }
    
    /** @notice Allows the owner to register & cache a new reserve address in the smart conract
      * @param  reserve   The address of the reserve to add
      * @param  index     The index under which the reserve should be indexed
      * @param  is_public Whether the reserve should publicly available through swap() & swapWithReserve()
      */
    function cacheReserveAddress(address payable reserve, uint256 index, bool is_public) external {
        require(arbiters[msg.sender]);
        
        reserves[index] = reserve;
        reserve_indices[reserve] = index;
        
        if(is_public){
            public_reserves[reserve] = true;
            public_reserve_arr.push(reserve);  // append the reserve to the reserve array
        }
    }
    
    /** @notice Allows the owner to remove a reserve from the array swap() and getSwapOutput() need to loop through
      * @param  reserve The address of the reserve to remove
      */
    function removePublicReserveAddress(address reserve) external {
        require(arbiters[msg.sender]);
        
        public_reserves[reserve] = false;

        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            if(public_reserve_arr[i] == reserve){
                public_reserve_arr[i] = public_reserve_arr[public_reserve_arr.length - 1]; // array order does not matter, so we just move the last element in the slot of the element we are removing
                
                delete public_reserve_arr[public_reserve_arr.length-1];                    // delete the last element of the array
                public_reserve_arr.length--;                             
                
                return;
            }
        }
    }
        
    /** @notice Allows an arbiterto cache a new token address
      * @param  token   The address of the token to add
      * @param  index   The index under which the token should be indexed
      */
    function cacheTokenAddress(address token, uint256 index) external {
        require(arbiters[msg.sender]);
        
        tokens[index]        = token;
        token_indices[token] = index;
        
        token_arr.push(token);  // append the token to the array
    }

    /** @notice Allows arbiters to remove a token from the token array
      * @param  token The address of the token to remove
      */
    function removeTokenAddressFromArr(address token) external {
        require(arbiters[msg.sender]);
        
        for(uint256 i = 0; i < token_arr.length; i++){
            if(token_arr[i] == token){
                token_arr[i] = token_arr[token_arr.length - 1]; // array order does not matter, so we just move the last element in the slot of the element we are removing
                
                delete token_arr[token_arr.length-1];           // delete the last element of the array
                token_arr.length--;                             
                
                return;
            }
        }
    }
    
    /** @notice Allows the owner to nominate or denominate trade arbiting addresses
      * @param  arbiter The arbiter whose status to change
      * @param  status  whether the address should be an arbiter (true) or not (false)
      */
    function nominateArbiter(address arbiter, bool status) external {
        require(msg.sender == owner);                           // Check if sender is owner
        arbiters[arbiter] = status;                             // Update address status
    }
    
    /** @notice Allows the owner to pause / unpause the market
      * @param  state  whether the the market should be active (true) or paused (false)
      */
    function setMarketActiveState(bool state) external {
        require(msg.sender == owner);                           // Check if sender is owner
        marketActive = state;                                   // pause / unpause market
    }
    
    /** @notice Allows the owner to nominate the feeCollector address
      * @param  collector The address to nominate as feeCollector
      */
    function nominateFeeCollector(address payable collector) external {
        require(msg.sender == owner && !feeCollectorLocked);    // Check if sender is owner and feeCollector address is not locked
        feeCollector = collector;                               // Update feeCollector address
    }
    
    /** @notice Allows the owner to lock the feeCollector address
    */
    function lockFeeCollector() external {
        require(msg.sender == owner);                           // Check if sender is owner
        feeCollectorLocked = true;                              // Lock feeCollector address
    }
    
    /** @notice Get the feeCollectors address
      * @return The feeCollectors address
      */
    function getFeeCollector() public view returns (address){
        return feeCollector;
    }

    /** @notice Allows an arbiter or feeCollector to directly withdraw his own funds (would allow e.g. a fee distribution contract the withdrawal of collected fees)
      * @param  token   The token to withdraw
      * @param  amount  The amount of tokens to withdraw
    */
    function directWithdrawal(address token, uint256 amount) external returns(bool){
        if (
            (
                msg.sender == feeCollector                        // Check if the sender is the feeCollector
                || arbiters[msg.sender]                           // Check if the sender is an arbiter
            )
            && balances[token][msg.sender] >= amount              // Check if feeCollector has the sufficient balance
        ){
            balances[token][msg.sender] -= amount;                // Substract the feeCollectors balance
            
            if(token == address(0)){                              // Is the withdrawal token ETH
                require(
                    msg.sender.send(amount),                      // Withdraw ETH
                    "Sending of ETH failed."
                );
            }else{
                Token(token).transfer(msg.sender, amount);        // Withdraw ERC20
                require(                                          // Revert if the withdrawal failed
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }
            
            emit LogDirectWithdrawal(msg.sender, token, amount);     // emit LogDirectWithdrawal event
            return true;
        }else{
            return false;
        }
    }
}

// dexBlueReserve
contract dexBlueReserve{
    // insured trade function with fixed outcome
    function trade(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public payable returns(bool success){}
    
    // insured trade function with fixed outcome, passes additional data to the reserve
    function tradeWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public payable returns(bool success){}
    
    // offer the reserve to enter a trade a a taker
    function offer(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public returns(bool accept){}
    
    // offer the reserve to enter a trade a a taker, passes additional data to the reserve
    function offerWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public returns(bool accept){}
    
    // callback function, to inform the reserve that an offer has been accepted by the maker reserve
    function offerExecuted(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public{}

    // uninsured swap
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output) public payable returns(uint256 output){}
    
    // get output amount of swap
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns(uint256 output){}
}

// Standart ERC20 token interface to interact with ERC20 token contracts
// To support badly implemented tokens (which dont return a boolean on the transfer functions)
// we have to expect a badly implemented token and then check with checkERC20TransferSuccess() whether the transfer succeeded

contract Token {
    /** @return total amount of tokens
      */
    function totalSupply() view public returns (uint256 supply) {}

    /** @param _owner The address from which the balance will be retrieved
      * @return The balance
      */
    function balanceOf(address _owner) view public returns (uint256 balance) {}

    /** @notice send `_value` token to `_to` from `msg.sender`
      * @param  _to     The address of the recipient
      * @param  _value  The amount of tokens to be transferred
      * @return whether the transfer was successful or not
      */
    function transfer(address _to, uint256 _value) public {}

    /** @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
      * @param  _from   The address of the sender
      * @param  _to     The address of the recipient
      * @param  _value  The amount of tokens to be transferred
      * @return whether the transfer was successful or not
      */
    function transferFrom(address _from, address _to, uint256 _value)  public {}

    /** @notice `msg.sender` approves `_addr` to spend `_value` tokens
      * @param  _spender The address of the account able to transfer the tokens
      * @param  _value   The amount of wei to be approved for transfer
      * @return whether the approval was successful or not
      */
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /** @param  _owner   The address of the account owning tokens
      * @param  _spender The address of the account able to transfer the tokens
      * @return Amount of remaining tokens allowed to spend
      */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 public decimals;
    string public name;
}

// Wrapped Ether interface
contract WETH is Token{
    function deposit() public payable {}
    function withdraw(uint256 amount) public {}
}