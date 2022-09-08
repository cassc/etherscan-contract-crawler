// SPDX-License-Identifier: MIT

/*

  Decentralized digital asset exchange. Supports any digital asset that can be represented on the Ethereum blockchain (i.e. - transferred in an Ethereum transaction or sequence of transactions).

  Let us suppose two agents interacting with a distributed ledger have utility functions preferencing certain states of that ledger over others.
  Aiming to maximize their utility, these agents may construct with their utility functions along with the present ledger state a mapping of state transitions (transactions) to marginal utilities.
  Any composite state transition with positive marginal utility for and enactable by the combined permissions of both agents thus is a mutually desirable trade, and the trustless 
  code execution provided by a distributed ledger renders the requisite atomicity trivial.

  Relative to this model, this instantiation makes two concessions to practicality:
  - State transition preferences are not matched directly but instead intermediated by a standard of tokenized value.
  - A small fee can be charged in WYV for order settlement in an amount configurable by the frontend hosting the orderbook.

  Solidity presently possesses neither a first-class functional typesystem nor runtime reflection (ABI encoding in Solidity), so we must be a bit clever in implementation and work at a lower level of abstraction than would be ideal.

  We elect to utilize the following structure for the initial version of the protocol:
  - Buy-side and sell-side orders each provide calldata (bytes) - for a sell-side order, the state transition for sale, for a buy-side order, the state transition to be bought.
    Along with the calldata, orders provide `replacementPattern`: a bytemask indicating which bytes of the calldata can be changed (e.g. NFT destination address).
    When a buy-side and sell-side order are matched, the desired calldatas are unified, masked with the bytemasks, and checked for agreement.
    This alone is enough to implement common simple state transitions, such as "transfer my CryptoKitty to any address" or "buy any of this kind of nonfungible token".
  - Orders (of either side) can optionally specify a static (no state modification) callback function, which receives configurable data along with the actual calldata as a parameter.
    Although it requires some encoding acrobatics, this allows for arbitrary transaction validation functions.
    For example, a buy-sider order could express the intent to buy any CryptoKitty with a particular set of characteristics (checked in the static call),
    or a sell-side order could express the intent to sell any of three ENS names, but not two others.
    Use of the EVM's STATICCALL opcode, added in Ethereum Metropolis, allows the static calldata to be safely specified separately and thus this kind of matching to happen correctly
    - that is to say, wherever the two (transaction => bool) functions intersect.

  Future protocol versions may improve upon this structure in capability or usability according to protocol user feedback demand, with upgrades enacted by the Wyvern DAO.
 
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/ReentrancyGuarded.sol";
import "../common/StaticCall.sol";
import "./SaleKindInterface.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers
 */
contract ExchangeCoreBatch is ReentrancyGuarded, Ownable {
    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* Orders match index. */
    mapping(bytes32 => uint256) public matchIndex;

    /* User order start time. */
    mapping(address => uint256) public startTimes;

    /* For split fee orders, minimum required protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumMakerProtocolFee = 0;

    /* For split fee orders, minimum required protocol taker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumTakerProtocolFee = 0;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* Fee method: protocol fee or split fee. */
    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    /* Order type: random order or scope order. */
    enum OrderType {
        RandomOrder,
        ScopeOrder,
        Only
    }

    //exchange fee to owner
    uint256 public _exchangeFee = 250;

    //exchange fee to owner
    uint256 public _relayExchangeFee = 250;

    /* Recipient of protocol fees. */
    address public _rewardFeeRecipient;

    /* Recipient of protocol fees. */
    address public _relayRewardFeeRecipient;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    // Delay to set fee
    uint256 public _delaySetFeeTime = 1 days;

    // Relay to set fee
    uint256 public _relaySetFeeTime = 0;

    // Delay to set fee
    uint256 public _delaySetFeeRecipientTime = 3 days;

    // Relay to set fee
    uint256 public _relaySetFeeRecipientTime = 0;

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Order to address, if specified. */
        address to;
        /* Maker relayer fee of the order, unused for taker order. */
        uint256 makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint256 makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint256 takerProtocolFee;
        /* nft minter. */
        address minter;
        /* OrderType (random order or scope order.). */
        OrderType orderType;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

    event OrderApproved(
        bytes32 indexed hash,
        address indexed maker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        uint256 makerProtocolFee,
        uint256 takerProtocolFee,
        address indexed minter
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        address indexed to,
        address target,
        uint256 tokenId,
        uint256 price
    );
    event RelaySetFee(address owner, uint256 relaySetFeeTime, uint256 relayExchangeFee);
    event SetFee(address owner, uint256 exchangeFee);
    event RelaySetRecipientFee(address owner, address relayRewardFeeRecipient, uint256 relaySetFeeRecipientTime);
    event SetFeeRecipient(address owner, address rewardFeeRecipient);
    event SetStartTime(address owner, uint256 startTime);

    function setExchangeToken(address token) public onlyOwner {
      exchangeToken = ERC20(token);
    }

    function setFee(uint256 exchangeFee_) public onlyOwner {
        require(_relaySetFeeTime != 0, "PlaNFT: _relaySetFee not call");
        require(_relayExchangeFee == exchangeFee_, "PlaNFT: _relayExchangeFee not equal exchangeFee_");
        require(_relaySetFeeTime + _delaySetFeeTime <= block.timestamp, "Pla_TNFT: _delaySetFeeTime not arrive");
        _relaySetFeeTime = 0;
        _exchangeFee = exchangeFee_;
        emit SetFee(msg.sender, _exchangeFee);
    }

    function relaySetFee(uint256 relayExchangeFee_) public onlyOwner {
        _relaySetFeeTime = block.timestamp;
        _relayExchangeFee = relayExchangeFee_;
        emit RelaySetFee(msg.sender, _relayExchangeFee, _relaySetFeeTime);
    }

    function setFeeRecipient(address rewardFeeRecipient_) public onlyOwner {
        require(_relaySetFeeRecipientTime != 0, "PlaNFT: _relaySetFee not call");
        require(
            _relayRewardFeeRecipient == rewardFeeRecipient_,
            "PlaNFT: _relayRewardFeeRecipient not equal rewardFeeRecipient_"
        );
        require(
            _relaySetFeeRecipientTime + _delaySetFeeRecipientTime <= block.timestamp,
            "Pla_TNFT: _delaySetFeeTime not arrive"
        );
        _relaySetFeeRecipientTime = 0;
        _rewardFeeRecipient = rewardFeeRecipient_;
        emit SetFeeRecipient(msg.sender, _rewardFeeRecipient);
    }

    function setStartTime(uint256 startTime) public {
        startTimes[msg.sender] = startTime;
        emit SetStartTime(msg.sender, startTime);
    }

    function relaySetFeeRecipient(address relayRewardFeeRecipient_) public onlyOwner {
        _relaySetFeeRecipientTime = block.timestamp;
        _relayRewardFeeRecipient = relayRewardFeeRecipient_;
        emit RelaySetRecipientFee(msg.sender, _relayRewardFeeRecipient, _relaySetFeeRecipientTime);
    }

    /**
     * @dev Change the minimum maker fee paid to the protocol (owner only)
     * @param newMinimumMakerProtocolFee New fee to set in basis points
     */
    function changeMinimumMakerProtocolFee(uint256 newMinimumMakerProtocolFee) public onlyOwner {
        minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    }

    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newMinimumTakerProtocolFee New fee to set in basis points
     */
    function changeMinimumTakerProtocolFee(uint256 newMinimumTakerProtocolFee) public onlyOwner {
        minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient) public onlyOwner {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Charge a fee in protocol tokens
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function chargeProtocolFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        transferTokens(address(exchangeToken), from, to, amount);
    }

    /**
     * Calculate size of an order struct when tightly packed
     *
     * @param length Length of tokens to calculate size of
     * @return Size in bytes
     */
    function sizeOf(uint256 length) internal pure returns (uint256) {
        return ((0x14 * 7) + (0x20 * (9 + length)) + 5);
    }

    /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @param tokens Tokens to hash
     * @return hash of order
     */
    function hashOrder(Order memory order, uint256[] memory tokens) internal pure returns (bytes32 hash) {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = sizeOf(tokens.length);
        bytes memory array = new bytes(size);

        uint256 index;
        assembly {
            index := add(array, 0x20)
        }

        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteAddress(index, order.to);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.minter);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.orderType));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);

        for (uint256 i = 0; i < tokens.length; i++) {
            index = ArrayUtils.unsafeWriteUint(index, tokens[i]);
        }
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }

        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @param tokens Tokens to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order, uint256[] memory tokens) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order, tokens)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param tokens Tokens to validate
     * @return hash Hash of order require validated
     */
    function requireValidOrder(Order memory order, uint256[] memory tokens) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order, tokens);
        require(validateOrder(hash, order));
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order) internal view returns (bool) {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (order.listingTime < startTimes[order.maker]) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

        /* If using the split fee method, order must have sufficient protocol fees. */
        if (
            order.feeMethod == FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee || order.takerProtocolFee < minimumTakerProtocolFee)
        ) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @return valid Valid for hash and order
     */
    function validateOrder(bytes32 hash, Order memory order) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Order authentication. Order must be either:
            /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }
        return false;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param tokens Tokens to approve
     */
    function approveOrder(Order memory order, uint256[] memory tokens) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, tokens);

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker, "PlaExchangeBatch: caller must be order maker");
        if (order.orderType == OrderType.RandomOrder) {
            require(tokens.length > 0, "PlaExchangeBatch: tokens size must bigger than zero");
            matchIndex[hash] = 0;
        } else if (order.orderType == OrderType.ScopeOrder) {
            require(tokens.length == 2, "PlaExchangeBatch: tokens scope illegal");
            require(tokens[1] > tokens[0], "PlaExchangeBatch: tokens scope must asc");
            matchIndex[hash] = 0;
        } else {
            require(tokens.length == 0, "PlaExchangeBatch: tokens size must be zero");
        }

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash]);

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[hash] = true;

        /* Log approval event. */
        emit OrderApproved(
            hash,
            order.maker,
            order.makerRelayerFee,
            order.takerRelayerFee,
            order.makerProtocolFee,
            order.takerProtocolFee,
            order.minter
        );
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param tokens tokens to cancel
     */
    function cancelOrder(Order memory order, uint256[] memory tokens) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, tokens);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice(Order memory order) internal view returns (uint256) {
        return
            SaleKindInterface.calculateFinalPrice(
                order.side,
                order.saleKind,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime
            );
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell) internal view returns (uint256) {
        /* Calculate sell price. */
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(
            buy.side,
            buy.saleKind,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime
        );

        /* Require price cross. */
        require(buyPrice >= sellPrice);

        /* Maker/taker priority. */
        return sell.minter != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell) internal returns (uint256) {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        uint256 feeToExchange = SafeMath.div(SafeMath.mul(_exchangeFee, price), INVERSE_BASIS_POINT);

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.minter != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee);

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
                require(sell.takerProtocolFee <= buy.takerProtocolFee);

                /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */
                if (sell.makerRelayerFee == 0 && sell.takerRelayerFee == 0) {
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, feeToExchange);
                        payable(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, _rewardFeeRecipient, feeToExchange);
                    }
                }
                if (sell.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(SafeMath.sub(receiveAmount, makerRelayerFee), feeToExchange);
                        payable(sell.minter).transfer(makerRelayerFee);
                        payable(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, sell.minter, makerRelayerFee);
                        transferTokens(sell.paymentToken, sell.maker, address(_rewardFeeRecipient), feeToExchange);
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(SafeMath.add(requiredAmount, takerRelayerFee), feeToExchange);
                        payable(sell.minter).transfer(takerRelayerFee);
                        payable(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, sell.minter, takerRelayerFee);
                        transferTokens(sell.paymentToken, buy.maker, _rewardFeeRecipient, feeToExchange);
                    }
                }

                if (sell.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, makerProtocolFee);
                        payable(protocolFeeRecipient).transfer(makerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, makerProtocolFee);
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(requiredAmount, takerProtocolFee);
                        payable(protocolFeeRecipient).transfer(takerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, takerProtocolFee);
                    }
                }
            } else {
                /* Charge maker fee to seller. */
                chargeProtocolFee(sell.maker, sell.minter, sell.makerRelayerFee);
                chargeProtocolFee(sell.maker, _rewardFeeRecipient, _exchangeFee);
                /* Charge taker fee to buyer. */
                chargeProtocolFee(buy.maker, sell.minter, sell.takerRelayerFee);
                chargeProtocolFee(buy.maker, _rewardFeeRecipient, _exchangeFee);
            }
        } else {
            /* Buy-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee);

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));

                /* Assert taker fee is less than or equal to maximum fee specified by seller. */
                require(buy.takerProtocolFee <= sell.takerProtocolFee);

                if (buy.makerRelayerFee == 0 && buy.takerRelayerFee == 0) {
                    transferTokens(sell.paymentToken, sell.maker, _rewardFeeRecipient, feeToExchange);
                }

                if (buy.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(sell.paymentToken, buy.maker, buy.minter, makerRelayerFee);
                    transferTokens(sell.paymentToken, buy.maker, _rewardFeeRecipient, feeToExchange);
                }

                if (buy.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(sell.paymentToken, sell.maker, buy.minter, takerRelayerFee);
                    transferTokens(sell.paymentToken, sell.maker, _rewardFeeRecipient, feeToExchange);
                }

                if (buy.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, makerProtocolFee);
                }

                if (buy.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, takerProtocolFee);
                }
            } else {
                /* Charge maker fee to buyer. */
                chargeProtocolFee(buy.maker, buy.minter, buy.makerRelayerFee);
                chargeProtocolFee(buy.maker, _rewardFeeRecipient, _exchangeFee);
                /* Charge taker fee to seller. */
                chargeProtocolFee(sell.maker, buy.minter, buy.takerRelayerFee);
                chargeProtocolFee(sell.maker, _rewardFeeRecipient, _exchangeFee);
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            payable(sell.maker).transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                payable(buy.maker).transfer(diff);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell) internal view returns (bool) {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same order type. */
            (buy.orderType == sell.orderType) &&
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.minter == address(0) && buy.minter != address(0)) ||
                (sell.minter != address(0) && buy.minter == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime));
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @param tokens tokens to match
     * @param tokenId tokenId to match
     */
    function atomicMatch2(
        Order memory buy,
        Order memory sell,
        uint256[] memory tokens,
        uint256 tokenId
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash = requireValidOrder(buy, tokens);

        /* Ensure sell order validity and calculate hash if necessary. */
        require(sell.maker == msg.sender, "PlaExchangeBatch: caller is not buy maker");
        require(validateOrderParameters(sell));

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        require(StaticCall.isContract(buy.target));

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(delegateProxy != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for maker");

        /* Assert implementation. */
        require(
            delegateProxy.implementation() == registry.delegateProxyImplementation(),
            "Incorrect delegate proxy implementation for maker"
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

        /* INTERACTIONS */
        cancelledOrFinalized[buyHash] = true;

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);
        /* Execute specified call through proxy. */

        address to = buy.to;
        if (to == address(0)) to = buy.maker;
        require(to != sell.maker, "PlaExchangeBatch: cannot make self-sell");

        require(
            proxy.proxy(
                buy.target,
                buy.howToCall,
                abi.encodeWithSignature("transferFrom(address,address,uint256)", sell.maker, to, tokenId)
            )
        );

        /* Log match event. */
        emit OrdersMatched(buyHash, sell.maker, buy.maker, to, sell.target, tokenId, price);
    }

    function atomicMatch(
        Order memory buy,
        Order memory sell,
        uint256[] memory tokens
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        require(buy.maker == msg.sender, "PlaExchangeBatch: caller is not buy maker");
        require(validateOrderParameters(buy));

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash = requireValidOrder(sell, tokens);

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        require(StaticCall.isContract(sell.target));

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(delegateProxy != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for maker");

        /* Assert implementation. */
        require(
            delegateProxy.implementation() == registry.delegateProxyImplementation(),
            "Incorrect delegate proxy implementation for maker"
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);
        /* Execute specified call through proxy. */

        uint256 tokenId;
        if (sell.orderType == OrderType.RandomOrder) {
            require(matchIndex[sellHash] < tokens.length, "PlaExchangeBatch: illegal match index");
            tokenId = tokens[matchIndex[sellHash]];
        } else {
            require(matchIndex[sellHash] <= tokens[1] - tokens[0], "PlaExchangeBatch: illegal match index");
            tokenId = matchIndex[sellHash] + tokens[0];
        }
        matchIndex[sellHash] = matchIndex[sellHash] + 1;

        address to = buy.to;
        if (to == address(0)) to = buy.maker;
        require(to != sell.maker, "PlaExchangeBatch: cannot make self-sell");

        require(
            proxy.proxy(
                sell.target,
                sell.howToCall,
                abi.encodeWithSignature("transferFrom(address,address,uint256)", sell.maker, to, tokenId)
            )
        );

        /* Log match event. */
        emit OrdersMatched(sellHash, sell.maker, buy.maker, to, sell.target, tokenId, price);
    }
}