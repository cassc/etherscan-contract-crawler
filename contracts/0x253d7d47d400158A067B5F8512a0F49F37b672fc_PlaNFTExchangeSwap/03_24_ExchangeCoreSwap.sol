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
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/EIP712.sol";
import "../common/ReentrancyGuarded.sol";
import "../common/StaticCall.sol";
import "./SaleKindInterface.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers
 */
contract ExchangeCoreSwap is ReentrancyGuarded, EIP712, Ownable {
    using SafeMath for uint256;

    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(address => mapping(bytes32 => bool)) public cancelledOrFinalized;

    /* Orders verified by on-chain approval.
       Alternative to ECDSA signatures so that smart contracts can place orders directly.
       By maker address, then by hash.
       porting from v3.1 */
    mapping(address => mapping(bytes32 => bool)) public approvedOrders;

    /* User order start time. */
    mapping(address => uint256) public startTimes;

    /* Protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint256 public protocolFee = 10;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address exchange,address maker,address taker,uint8 side,uint8 howToCall,address makerErc20Address,uint256 makerErc20Amount,address takerErc20Address,uint256 takerErc20Amount,address[] makerErc721Targets,bytes[] makerCalldatas,bytes[] makerReplacementPatterns,address[] takerErc721Targets,bytes[] takerCalldatas,bytes[] takerReplacementPatterns,address staticTarget,bytes staticExtradata,uint256 listingTime,uint256 expirationTime,uint256 salt)"
        );

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Token address of maker's erc20. */
        address makerErc20Address;
        /* Amount of maker's erc20. */
        uint256 makerErc20Amount;
        /* Token address of taker's erc20. */
        address takerErc20Address;
        /* Amount of taker's erc20. */
        uint256 takerErc20Amount;
        /* Address of maker's ERC721 tokens. */
        address[] makerErc721Targets;
        /* Calldatas corresponding to maker's ERC721 tokens. */
        bytes[] makerCalldatas;
        /* Calldata replacement patterns for maker's calldatas, or an empty byte array for no replacement. */
        bytes[] makerReplacementPatterns;
        /* Address of taker's ERC721 tokens. */
        address[] takerErc721Targets;
        /* Calldatas corresponding to taker's ERC721 tokens. */
        bytes[] takerCalldatas;
        /* Calldata replacement patterns for taker's calldatas, or an empty byte array for no replacement. */
        bytes[] takerReplacementPatterns;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address indexed makerErc20Address,
        uint256 makerErc20Amount
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        address indexed takerErc20Address,
        uint256 takerErc20Amount,
        address staticTarget,
        bytes staticExtradata,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        bytes32 indexed metadata
    );
    event RelaySetFee(address owner, uint256 relaySetFeeTime, uint256 relayExchangeFee);
    event SetFee(address owner, uint256 exchangeFee);
    event RelaySetRecipientFee(address owner, address relayRewardFeeRecipient, uint256 relaySetFeeRecipientTime);
    event SetFeeRecipient(address owner, address rewardFeeRecipient);
    event SetStartTime(address owner, uint256 startTime);

    constructor(
        string memory name,
        string memory version,
        uint256 chainId,
        bytes32 salt
    ) EIP712(name, version, chainId, salt) {}

    function setExchangeToken(address token) public onlyOwner {
        exchangeToken = ERC20(token);
    }

    function setStartTime(uint256 startTime) public {
        startTimes[msg.sender] = startTime;
        emit SetStartTime(msg.sender, startTime);
    }

    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newProtocolFee New fee to set in basis points
     */
    function changeProtocolFee(uint256 newProtocolFee) public onlyOwner {
        protocolFee = newProtocolFee;
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
     * @dev Hash an address array, returning the keccak256 of encodeData
     * @param addrs arrays of address to hash
     * @return hash of data
     */
    function addresseArrayHash(address[] memory addrs) internal pure returns(bytes32) {
        bytes memory data = new bytes(0x20 * addrs.length);
        uint256 index;
        assembly {
            index := add(data, 0x20)
        }
        for (uint256 i = 0; i < addrs.length; i++) {
            index = ArrayUtils.unsafeWriteAddressWord(index, addrs[i]);
        }

        return keccak256(data);
    }

    /**
     * @dev Hash an bytes array, returning the keccak256 of encodeData
     * @param datas arrays of bytes to hash
     * @return hash of data
     */
    function bytesArrayHash(bytes[] memory datas) internal pure returns(bytes32) {
        bytes memory data = new bytes(0x20 * datas.length);
        uint256 index;
        assembly {
            index := add(data, 0x20)
        }
        for (uint256 i = 0; i < datas.length; i++) {
            index = ArrayUtils.unsafeWriteBytes32(index, keccak256(datas[i]));
        }

        return keccak256(data);
    }

    /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return hash of order
     */
    function hashOrder(Order memory order) internal pure returns (bytes32 hash) {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = 672;
        bytes memory array = new bytes(size);

        uint256 index;
        assembly {
            index := add(array, 0x20)
        }

        index = ArrayUtils.unsafeWriteBytes32(index, ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.makerErc20Address);
        index = ArrayUtils.unsafeWriteUint(index, order.makerErc20Amount);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.takerErc20Address);
        index = ArrayUtils.unsafeWriteUint(index, order.takerErc20Amount);
        index = ArrayUtils.unsafeWriteBytes32(index, addresseArrayHash(order.makerErc721Targets));
        index = ArrayUtils.unsafeWriteBytes32(index, bytesArrayHash(order.makerCalldatas));
        index = ArrayUtils.unsafeWriteBytes32(index, bytesArrayHash(order.makerReplacementPatterns));
        index = ArrayUtils.unsafeWriteBytes32(index, addresseArrayHash(order.takerErc721Targets));
        index = ArrayUtils.unsafeWriteBytes32(index, bytesArrayHash(order.takerCalldatas));
        index = ArrayUtils.unsafeWriteBytes32(index, bytesArrayHash(order.takerReplacementPatterns));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.staticExtradata));
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }

        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashOrder(order)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param signature ECDSA signature
     * @return hash Hash of order require validated
     */
    function requireValidOrder(Order memory order, bytes memory signature) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, signature));
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

        /* Order must contain one maker ERC721 at lease. */
        if (order.makerErc721Targets.length == 0) {
            return false;
        }

        /* Order must contain one taker ERC721 at lease. */
        if (order.takerErc721Targets.length == 0) {
            return false;
        }

        /* Count of maker's ERC721 items must be equal to calldatas. */
        if (order.makerErc721Targets.length != order.makerCalldatas.length) {
            return false;
        }

        /* Count of maker's calldatas must be equal to replacement patterns. */
        if (order.makerCalldatas.length != order.makerReplacementPatterns.length) {
            return false;
        }

        /* Count of taker's ERC721 items must be equal to calldatas. */
        if (order.takerErc721Targets.length != order.takerCalldatas.length) {
            return false;
        }

        /* Count of taker's calldatas must be equal to replacement patterns. */
        if (order.takerCalldatas.length != order.takerReplacementPatterns.length) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param signature ECDSA signature
     * @return valid Valid for hash and order
     */
    function validateOrder(
        bytes32 hash,
        Order memory order,
        bytes memory signature
    ) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[order.maker][hash]) {
            return false;
        }

        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[order.maker][hash]) {
            return true;
        }

        /* (b): Contract-only authentication: EIP/ERC 1271. */
        if (StaticCall.isContract(order.maker)) {
            return (IERC1271(order.maker).isValidSignature(hash, signature) == EIP_1271_MAGICVALUE);
        }

        /* (c): Account-only authentication: ECDSA-signed by maker. */
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x41))
        }

        if (ecrecover(hash, v, r, s) == order.maker) {
            return true;
        }

        return false;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired) internal {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker, "PlaExchange: caller must be order maker");

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[order.maker][hash]);

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[order.maker][hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(
                hash,
                order.exchange,
                order.maker,
                order.taker,
                order.side,
                order.howToCall,
                order.makerErc20Address,
                order.makerErc20Amount
            );
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.takerErc20Address,
                order.takerErc20Amount,
                order.staticTarget,
                order.staticExtradata,
                order.listingTime,
                order.expirationTime,
                order.salt,
                orderbookInclusionDesired
            );
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param signature ECDSA signature
     */
    function cancelOrder(Order memory order, bytes memory signature) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, signature);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[order.maker][hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Return whether or not ERC721 items of two orders can be matched with each other (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function erc721ItemsCanMatch(Order memory buy, Order memory sell) internal pure returns (bool) {
        if (buy.makerErc721Targets.length != sell.takerErc721Targets.length) return false;

        if (buy.takerErc721Targets.length != sell.makerErc721Targets.length) return false;

        for (uint256 i = 0; i < buy.makerErc721Targets.length; ++i) {
            if (buy.makerErc721Targets[i] != sell.takerErc721Targets[i]) return false;
        }

        for (uint256 i = 0; i < buy.takerErc721Targets.length; ++i) {
            if (buy.takerErc721Targets[i] != sell.makerErc721Targets[i]) return false;
        }

        return true;
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
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Must match ERC20. */
            (buy.makerErc20Address == address(0) ||
                (buy.makerErc20Address == sell.takerErc20Address && buy.makerErc20Amount == sell.takerErc20Amount)) &&
            (buy.takerErc20Address == address(0) ||
                (buy.takerErc20Address == sell.makerErc20Address && buy.takerErc20Amount == sell.makerErc20Amount)) &&
            (sell.makerErc20Address == address(0) ||
                (sell.makerErc20Address == buy.takerErc20Address && sell.makerErc20Amount == buy.takerErc20Amount)) &&
            (sell.takerErc20Address == address(0) ||
                (sell.takerErc20Address == buy.makerErc20Address && sell.takerErc20Amount == buy.makerErc20Amount)) &&
            /* ERC721 items must match. */
            erc721ItemsCanMatch(buy, sell) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime));
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by
     *       a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(
        Order memory buy,
        bytes memory buySig,
        Order memory sell,
        bytes memory sellSig,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxySeller = registry.proxies(sell.maker);
        OwnableDelegateProxy delegateProxyBuyer = registry.proxies(buy.maker);

        /* Proxy must exist. */
        require(delegateProxySeller != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for seller");
        require(delegateProxyBuyer != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for buyer");

        /* Assert implementation. */
        require(
            delegateProxySeller.implementation() == registry.delegateProxyImplementation() &&
                delegateProxyBuyer.implementation() == registry.delegateProxyImplementation(),
            "Incorrect delegate proxy implementation for maker"
        );

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buy.maker][buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sell.maker][sellHash] = true;
        }

        /* INTERACTIONS */

        /* Transfer ERC20. */
        transferTokens(sell.makerErc20Address, sell.maker, buy.maker, sell.makerErc20Amount);
        transferTokens(buy.makerErc20Address, buy.maker, sell.maker, buy.makerErc20Amount);

        uint256 fee = protocolFee.mul(10**18).div(INVERSE_BASIS_POINT);
        transferTokens(address(exchangeToken), sell.maker, protocolFeeRecipient, fee);
        transferTokens(address(exchangeToken), buy.maker, protocolFeeRecipient, fee);

        /* Transfer ERC721 items. */
        for (uint256 i = 0; i < sell.makerErc721Targets.length; ++i) {
            require(StaticCall.isContract(sell.makerErc721Targets[i]));

            /* Must match calldata after replacement, if specified. */
            if (sell.makerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    sell.makerCalldatas[i],
                    buy.takerCalldatas[i],
                    sell.makerReplacementPatterns[i]
                );
            }

            if (buy.takerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    buy.takerCalldatas[i],
                    sell.makerCalldatas[i],
                    buy.takerReplacementPatterns[i]
                );
            }

            require(ArrayUtils.arrayEq(sell.makerCalldatas[i], buy.takerCalldatas[i]));

            /* Execute specified call through proxy. */
            require(StaticCall.isContract(sell.makerErc721Targets[i]));
            require(
                AuthenticatedProxy(payable(delegateProxySeller)).proxy(
                    sell.makerErc721Targets[i],
                    sell.howToCall,
                    sell.makerCalldatas[i]
                )
            );
        }

        for (uint256 i = 0; i < sell.takerErc721Targets.length; ++i) {
            require(StaticCall.isContract(sell.takerErc721Targets[i]));

            /* Must match calldata after replacement, if specified. */
            if (sell.takerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    sell.takerCalldatas[i],
                    buy.makerCalldatas[i],
                    sell.takerReplacementPatterns[i]
                );
            }

            if (buy.makerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    buy.makerCalldatas[i],
                    sell.takerCalldatas[i],
                    buy.makerReplacementPatterns[i]
                );
            }

            require(ArrayUtils.arrayEq(sell.takerCalldatas[i], buy.makerCalldatas[i]));

            /* Execute specified call through proxy. */
            require(StaticCall.isContract(sell.takerErc721Targets[i]));
            require(
                AuthenticatedProxy(payable(delegateProxyBuyer)).proxy(
                    sell.takerErc721Targets[i],
                    sell.howToCall,
                    sell.takerCalldatas[i]
                )
            );
        }

        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(StaticCall.staticCall(buy.staticTarget, buy.staticExtradata));
        }

        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(StaticCall.staticCall(sell.staticTarget, sell.staticExtradata));
        }

        /* Log match event. */
        emit OrdersMatched(buyHash, sellHash, sell.maker, buy.maker, metadata);
    }
}