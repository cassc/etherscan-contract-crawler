/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Counters.sol";
import "./utils/RoyaltyEngineV1.sol";
import "./access/Ownable.sol";

/**
 *
 * @title NinfaMarketplace                                   *
 *                                                           *
 * @notice On-chain NFT marketplace                          *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 *
 */

contract NinfaMarketplace is Ownable, RoyaltyEngineV1 {
    /*----------------------------------------------------------*|
    |*  # VARIABLES                                             *|
    |*----------------------------------------------------------*/

    using Counters for Counters.Counter;
    /// @notice Orders counter
    Counters.Counter private _orderCount;
    /// @notice Offers counter
    Counters.Counter private _offerCount;
    /// @notice address of admin multisig contract for receiving fees generated
    /// by the marketplace
    address private _feeRecipient;
    /// @notice factory contract for deploying self-sovereign collections.
    address private _factory;
    /// @notice Ninfa's whitelist contract, used for checking if a collection is whitelisted
    address private _whitelist;
    /// @notice Ninfa's external registry, mapping Ninfa's ERC721 sovreign
    /// collection's tokenIds to a boolean value
    /// indicating if the token has been sold on any of Ninfa's contracts, such
    /// as this marketplace or an auction
    /// contract.
    address private immutable _PRIMARY_MARKET_REGISTRY;
    ///@notice constant 10,000 BPS = 100% shares sale price
    uint256 private constant _BPS_DENOMINATOR = 10_000;
    /// @notice Ninfa Marketplace fee percentage on primary sales from orders,
    /// expressed in basis points
    uint256 private _primaryOrdersFee;
    /// @notice Ninfa Marketplace fee percentage on primary sales from offers,
    /// expressed in basis points
    uint256 private _primaryOffersFee;
    /// @notice Ninfa Marketplace fee percentage on all secondary sales,
    /// expressed in basis points
    uint256 private _secondaryMarketFee;
    /// @notice codehash of Ninfa's ERC721 sovreign collection
    bytes32 private _ERC721SovreignV1CodeHash;
    /// @notice `_orderCount` counter to `_Order` struct mapping
    mapping(uint256 => _Order) private _orders;
    /// @notice `_offerCount` counter to `_Offer` struct mapping
    mapping(uint256 => _Offer) public offers;

    /*----------------------------------------------------------*|
    |*  # STRUCTS                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev the `Order` struct is used both for storing order information, as
     * well as trade information when passed as a
     * function parameter to the private `_trade` function
     * @param tokenId the NFT id, for now we only allow trading NINFA NFT's so
     * no erc721 address is needed
     * @param unitPrice ERC-1155 unit price in ETH, or total price if ERC-721
     * since there is only 1 unit of each token.
     * @dev when the `Order` struct is passed as a function parameter to
     * `_trade`, `unitPrice` always refers to the
     * total price of ERC-1155 tokens, i.e. token value * unit price
     * @param collection address of the ERC721 or ERC1155 contract. Doesn't
     * require any access control besides the
     * collection being whitelisted, i.e. msg.sender may be any address.
     * @param erc1155Value the NFT amount, _amount == 0 for ERC721 and _amount >
     * 0 for ERC1155
     * @param commissionBps commission amounts, expressed in basis points 0 -
     * 10000
     * @param commissionReceivers receivers of commission on sales (primary AND
     * secondary)
     * @param collection address of the collection being sold
     * @param from always refers to the seller, who either creater an order or
     * is accepting an offer.
     * @param operator address of an authorized operator, such as a gallery
     * managing an artist; the operator is allowed
     * to change or cancel an order they created on the Marketplace.
     * @dev operator address usually also corresponds to the commission receiver
     * in order to receive sale commissions,
     * unless `commissionReceiver` is set to yet another address, e.g. a payment
     * splitter.
     */
    struct _Order {
        uint256 tokenId;
        uint256 unitPrice;
        uint256 erc1155Value;
        address collection;
        address from;
        address operator;
        uint256[] commissionBps;
        address[] commissionReceivers;
    }

    struct _Offer {
        uint256 tokenId;
        uint256 unitPrice;
        uint256 erc1155Value;
        address collection;
        address from; // buyer
    }

    /*----------------------------------------------------------*|
    |*  # EVENTS                                                *|
    |*----------------------------------------------------------*/

    event OrderCreated(uint256 orderId);

    event OrderUpdated(uint256 orderId);

    event OrderDeleted(uint256 orderId);

    event OfferCreated(uint256 offerId);

    event OfferUpdated(uint256 offerId);

    event OfferDeleted(uint256 offerId);

    // we have order/offer id and all the related data stored in db.
    event Trade( // seller
        address indexed collection,
        uint256 indexed tokenId,
        address indexed from,
        uint256 id,
        uint256 price,
        uint256 erc1155Value
    );

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    /**
     * @notice ERC721 and ERC1155 collections must be whitelisted.
     * @dev if the collection has not been whitelisted, check if it is one of
     * Ninfa's factory clones (Ninfa's
     * self-sovereign collections)
     * @dev by checking the whitelist first with nested `if`s avoids having to
     * make an external call unnecessarily
     */
    modifier isWhitelisted(address _collection) {
        bytes memory authorized;
            (, authorized) = _factory.staticcall(
                abi.encodeWithSelector(0xf6a3d24e, _collection)
            );
        if (abi.decode(authorized, (bool)) == false) {
            (, authorized) = _whitelist.staticcall(
                abi.encodeWithSelector(0x3af32abf, _collection)
            );
            if (abi.decode(authorized, (bool)) == false) revert Unauthorized();
        }
        _;
    }

    /*----------------------------------------------------------*|
    |*  # ORDERS                                                *|
    |*----------------------------------------------------------*/

    /**
     * @notice create a new order on the marketplace by transfering an NFT to
     * it.
     * @dev Will create a new order by sending tokens with data bytes containing
     * function parameters
     *
     * Require:
     *
     * - can only be called by an NFT smart contract transfering an NFT to the
     * marketplace
     * - collection must be whitelisted
     *
     */
    function _createOrder(
        address _operator, //  either the previous owner or operator, i.e.
            // whichever address called safeTransferFrom on
            // the ERC1155 contract
        address _from, // previous owner, i.e. seller
        uint256 _id,
        uint256 _value,
        uint256 _unitPrice,
        uint256[] memory _commissionBps,
        address[] memory _commissionReceivers
    )
        private
        isWhitelisted(msg.sender)
    {
        // `_orderCount` starts at 1
        _orderCount.increment();
        uint256 _orderId = _orderCount.current();

        // create order with new `_orderId` in orders mapping
        _orders[_orderId] = _Order(
            _id,
            _unitPrice,
            _value,
            msg.sender, // collection
            _from,
            _operator,
            _commissionBps,
            _commissionReceivers
        );
        emit OrderCreated(_orderId);
    }

    /// @dev only for 1155 for updating the price and LOWER the amount
    function updateOrder(uint256 _erc1155RedeemAmount, uint256 _unitPrice, uint256 _orderId) external {
        lowerOrderErc1155Amount(_orderId, _erc1155RedeemAmount);

        _orders[_orderId].unitPrice = _unitPrice;
    }

    /**
     * @notice cancels order and transfers NFT back to owner
     * @param _orderId the Id of the order
     * @dev delete `_orders[_orderId]` from storage BEFORE making external calls
     * for transfering the NFT back to the
     * seller (check-effects pattern)
     *
     *
     * SHOULD:
     *
     * This function does not check whether the order exists or not
     *
     */
    function deleteOrder(uint256 _orderId) external {
        _Order memory order = _orders[_orderId];
        require(msg.sender == order.operator);

        delete _orders[_orderId];

        _transferNFT(order.collection, address(this), msg.sender, order.tokenId, order.erc1155Value);

        emit OrderDeleted(_orderId);
    }

    /**
     * @param _unitPrice will override the old price, note that it may be 0
     * although this could only mean that a mistake
     * was made
     * @dev this function doesn't enforce a positive value for `_unitPrice` in
     * order to save a little gas for the users.
     * @dev if `_unitPrice` is set to 0, the order will be deleted from the
     * database (not from the smart contract), see
     * {NinfaMarketplace-OrderUpdated} modifier
     */
    function updateOrderPrice(uint256 _orderId, uint256 _unitPrice) external {
        _Order storage order = _orders[_orderId];
        require(msg.sender == order.operator);

        order.unitPrice = _unitPrice;

        emit OrderUpdated(_orderId);
    }

    /**
     * @notice function to lower an order's amount of the ERC-1155 tokenId on
     * sale, doesn't apply to ERC-721 because it
     * is non-fungible
     * @param _erc1155RedeemAmount is the (negative) difference of tokens to be
     * withdrawn by the seller. Should be
     * different from 0, although not strictly required.
     */
    function lowerOrderErc1155Amount(uint256 _orderId, uint256 _erc1155RedeemAmount) public {
        _Order storage order = _orders[_orderId];
        require(msg.sender == order.operator);

        /// @dev warning, make changes to storage BEFORE making external calls
        /// for transfering the NFT back to the
        /// seller (check-effects-interactions pattern)
        order.erc1155Value -= _erc1155RedeemAmount;

        (bool success,) = order.collection.call(
            abi.encodeWithSelector(
                0xf242432a, // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'))
                address(this),
                msg.sender,
                order.tokenId,
                _erc1155RedeemAmount,
                ""
            )
        );
        require(success);

        if (order.erc1155Value == 0) {
            delete _orders[_orderId]; // it is not possible to delete using
                // storage pointers
                // https://docs.soliditylang.org/en/develop/types.html#data-location
            emit OrderDeleted(_orderId);
        } else {
            emit OrderUpdated(_orderId);
        }
    }

    function setOrderCommission(
        uint256 _orderId, 
        uint256[] memory _commissionBps, 
        address[] memory _commissionReceivers) external {
        // should we check if the total commission is less than 10000?
        // should revert in trade function anyway
        require(msg.sender == _orders[_orderId].operator);
        _orders[_orderId].commissionBps = _commissionBps;
        _orders[_orderId].commissionReceivers = _commissionReceivers;
        emit OrderUpdated(_orderId);
    }

    /*----------------------------------------------------------*|
    |*  # OFFERS                                                *|
    |*----------------------------------------------------------*/

    /**
     * @dev offers can be made independently of whether the token is on sale or
     * not, the msg.value is used to determine
     * the offer amount, so no function parameter is needed for that
     * @dev there is no require to check that an offer or offer doesn't already
     * exist and if so, that the offer amount
     * is not greater than the order itself, this was omitted in order to save
     * gas; the frontend should check this in
     * order to prevent mistakes from the user
     * @param _collection address of the erc721 implementation contract or proxy
     * contract
     * @param _tokenId the token Id to make an offer to
     * @param _amount the NFT amount, _amount == 0 for ERC721 and _amount > 0
     * for ERC1155
     * @param _from needed in order to integrate Wert payment solution, because
     * in every txn Wert is the `msg.sender`.
     *      using _msgSender does not represent a security risk, on the other
     * hand, it is possible for the buyer to use
     * this parameter simply in order to transfer the NFT to an address other
     * than their own, this can be useful for
     * external contract buying NFTs.
     */
    function createOffer(
        address _collection,
        uint256 _tokenId,
        uint256 _amount,
        address _from,
        uint256 _unitPrice
    )
        external
        payable
        isWhitelisted(_collection)
    {
        _offerCount.increment(); // start count at 1

        if (_amount == 0) require(msg.value == _unitPrice);
        else require(msg.value == _unitPrice * _amount);

        offers[_offerCount.current()] = _Offer(
            _tokenId, // uint256 tokenId;
            _unitPrice, // uint256 unitPrice;
            _amount, // uint256 amount;
            _collection, // address collection;
            _from // address from;
        );

        emit OfferCreated(_offerCount.current());
    }

    /**
     * @dev cancels offer and refunds ETH back to bidder. When an order gets
     * filled, the offer isn't marked as
     * cancelled, in order to allow users to claim back their money.
     * @param _offerId the Id of the offer.
     */
    function deleteOffer(uint256 _offerId) external {
        // in memory copy needed so that it is possible to delete the struct
        // inside the storage offers mapping, while
        // keeping check effects interact pattern intact
        _Offer memory offer = offers[_offerId];

        uint256 refund;

        if (offer.erc1155Value == 0) {
            refund = offer.unitPrice;
        } else {
            refund = offer.unitPrice * offer.erc1155Value;
        }
        require(msg.sender == offer.from);
        // mark offer as cancelled forever, updating offer price before external
        // call, Checks Effects Interactions
        // pattern
        delete offers[_offerId];
        // transfer the offer amount back to bidder
        _sendValue(offer.from, refund);

        emit OfferDeleted(_offerId);
    }

    /**
     * @dev this is one of two functions called by a buyer in order to modify
     * their offer, there are two functions,
     * `raiseOffer()` and `lowerOffer()`, because they expect different
     * parameters depending on whether the offer is
     * being raised or lowerd.
     *      A `msg.value` is required, this function will add the amount sent to
     * the old offer amount. The frontend
     * needs to calculate the difference between the old and new offer.
     *      E.g. A buyer calls createOffer() and pays 0.1 ETH. The same buyer
     * later wants to raise the offer to 0.3 ETH,
     * therefore they now need to send 0.2 ETH, because 0.1 was was sent before.
     * @dev anyone can call this function, i.e. requiring that caller is offer
     * creator is not needed
     * @param _offerId the id of the offer
     * call this function only if the new total price is greater than the old
     * total price
     */
    function raiseOfferPrice(uint256 _offerId, uint256 _erc1155Value, uint256 _unitPrice) external payable {
        _Offer storage _offer = offers[_offerId];

        require(msg.sender == _offer.from);

        if (_offer.erc1155Value == 0) {
            require(msg.value == _unitPrice - _offer.unitPrice);
        } else {
            require(msg.value == (_unitPrice * _erc1155Value) - (_offer.unitPrice * _offer.erc1155Value));
        }

        _offer.unitPrice = _unitPrice; // transfer extra amount needed on top of
            // older offer
        _offer.erc1155Value = _erc1155Value;

        emit OfferUpdated(_offerId);
    }

    /**
     * @dev this is one of two functions called by a buyer in order to modify
     * their offer, there are two functions,
     * `raiseOffer()` and `lowerOffer()`, because they expect different
     * parameters depending on whether the offer is
     * being raised or lowerd.
     *      In contrast with `raiseOffer()`, instead of `msg.value` this
     * function expects a uint parameter representing
     * the new (lower) offer; the buyer will get refunded the difference.
     *      E.g. A buyer calls createOffer() and pays 0.3 ETH. The same buyer
     * later wants to lower the offer to 0.1 ETH,
     * therefore they will get refunded 0.2 ETH. I.e. The amount expected by the
     * `_newAmount` paramer is 0.1 ETH (1^17).
     * @param _offerId the id of the offer
     */
    function lowerOfferPrice(uint256 _offerId, uint256 _erc1155Amount, uint256 _unitPrice) external {
        _Offer storage _offer = offers[_offerId];

        require(msg.sender == _offer.from, "hwy");

        uint256 refund;

        if (_erc1155Amount == 0) {
            refund = _offer.unitPrice - _unitPrice;
        } else {
            refund = (_offer.unitPrice * _offer.erc1155Value) - (_unitPrice * _erc1155Amount);
            _offer.erc1155Value = _erc1155Amount;
        }

        _offer.unitPrice = _unitPrice; // needed to store result before offer
            // price is updated
        // transfer the difference between old and new lower offer to the user
        _sendValue(msg.sender, refund);

        emit OfferUpdated(_offerId);
    }

    function acceptListedTokenOffer(
        uint256 _orderId,
        uint256 _offerId,
        uint256[] memory _commissionBps,
        address[] memory _commissionReceivers
    )
        external
    {
        _Order memory order = _orders[_orderId];
        _Offer memory offer = offers[_offerId];

        require(order.operator == msg.sender && order.tokenId == offer.tokenId && order.collection == offer.collection);

        delete _orders[_orderId];
        delete offers[_offerId];

        _trade(
            _Order(
                order.tokenId, // uint256 tokenId
                offer.unitPrice, // offer price, not order price
                0,
                order.collection, // address collection
                msg.sender, // seller
                offer.from, // buyer / nft recipient
                _commissionBps, // uint256 commissionBps
                _commissionReceivers
            ),
            _orderId,
            _primaryOffersFee
        );
    }

    /*----------------------------------------------------------*|
    |*  # TRADING                                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice the collector calls this function to buy an NFT at the ask price,
     * only if an order exists
     * @notice if someone has an open offer but calls fillOrder, the offer will
     * remain open, meaning they will need to
     * call cancelOffer() to get a refund. This is unlikely, as users will
     * likely be aware of this and use the refund in
     * order to pay for part of the order.
     * @param _id avoids having to store a mapping to order id like the
     * deprecated `mapping(address => mapping(uint256
     * => uint256)) private _tokenToOrderId` which would have not worked for
     * erc1155 as each token has a supply.
     * _orderId does not constitute a vulnerability as it is user provided,
     * since A) a regular user will go through the
     * frontend which gets orderId from events
     * @param _buyer needed in order to integrate Wert payment solution, because
     * in every txn Wert is the msg.sender,
     * although using msg.sender would cost less gas.
     * using _msgSender does not represent a security risk, on the other hand,
     * it is possible for the buyer to use this
     * parameter simply in order to transfer the NFT to an address other than
     * their own, this can be useful for external
     * contract buying NFTs.
     *  + @param _erc1155Value market order amount (total or partial fill).
     * `_erc1155Value == 0` corresponds to one erc721 tokenId, `_erc1155Value >
     * 0` for erc1155 tokenIds
     *
     * MUST:
     *
     * - `msg.value` must be equal to `_orders[_orderId]der.unitPrice *
     * buyAmount`
     * - `_orders[_orderId].sellAmount >= buyAmount`
     *
     */
    function fillOrder(uint256 _id, address _buyer, uint256 _erc1155Value) external payable {
        _Order memory order = _orders[_id];

        require(msg.value == order.unitPrice * (_erc1155Value == 0 ? 1 : _erc1155Value));

        // subtracting user-suplied `_erc1155Value` from order amount,
        // transaction will revert if underflow, implicitly
        // requiring `_orders[_id]._erc1155Value >= _erc1155Value`
        if (_orders[_id].erc1155Value - _erc1155Value == 0) delete _orders[_id];
        else _orders[_id].erc1155Value -= _erc1155Value;

        _trade(
            _Order(
                order.tokenId, // uint256 tokenId
                msg.value, // price
                _erc1155Value,
                order.collection, // address collection
                order.from, // seller or from
                _buyer, // address buyer used for nft transfer
                order.commissionBps, // uint256 commissionBps
                order.commissionReceivers // address commissionReceiver
            ),
            _id,
            _primaryOrdersFee // uint256 primaryFee
        );
    }

    /**
     *
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been
     * updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param _operator The address which initiated the transfer (i.e.
     * msg.sender)
     * @param _from     The address which previously owned the token
     * @param _tokenId  The ID of the token being transferred
     * @param _value    The amount of tokens being transferred
     * @param _data     Additional data with no specified format
     * @param _data     `uint256 id` corresponding to an order to be updated or
     * an offer to be accepted, if the `id`
     * parameter is 0 create a new order.
     * @param _data     `uint256 unitPrice` is only required for updating an
     * order, i.e. if `unitPrice == 0` `id` an
     * offer id, if `unitPrice > 0` `id` is an order id
     * @return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * if transfer is allowed
     */
    function onERC1155Received(
        address _operator, //  either the previous owner or operator, whoever
            // called safeTransferFrom on the ERC1155
            // contract
        address _from, // previous owner
        uint256 _tokenId,
        uint256 _value,
        bytes memory _data
    )
        external
        returns (bytes4)
    {
        (uint256 id, uint256 unitPrice, uint256[] memory commissionBps, address[] memory commissionReceivers) =
            abi.decode(_data, (uint256, uint256, uint256[], address[]));

        if (unitPrice == 0) {
            /*----------------------------------------------------------*|
            |*  # ACCEPT OFFER                                          *|
            |*----------------------------------------------------------*/
            // if `_value` is more than the amount the following if check will
            // revert due to underflow,
            // intended to stop someone from sending more erc1155 tokens then
            // there are available in the order

            _Offer memory offer = offers[id];

            require(offer.collection == msg.sender && offer.tokenId == _tokenId);

            // subtracting `_value` from offer amount, transaction will revert
            // if underflow, implicitly requiring
            // `offers[id]._erc1155Value >= _value`
            if (offers[id].erc1155Value - _value == 0) delete offers[id];
            else offers[id].erc1155Value -= _value;

            _trade(
                _Order(
                    _tokenId, // uint256 tokenId
                    offer.unitPrice * _value, // uint256 price (unitPrice *
                        // value)
                    _value,
                    msg.sender, // address collection
                    _from, // seller
                    offer.from, // buyer or operator
                    commissionBps, // uint256 commissionBps
                    commissionReceivers // address commissionReceivers
                ),
                id,
                _primaryOffersFee
            );
        } else if (id == 0) {
            /*----------------------------------------------------------*|
            |*  # CREATE ORDER                                          *|
            |*----------------------------------------------------------*/
            // if the order/offer id parameter is 0, create a new order

            _createOrder(_operator, _from, _tokenId, _value, unitPrice, commissionBps, commissionReceivers);
        } else {
            /*----------------------------------------------------------*|
            |*  # UPDATE ORDER                                          *|
            |*----------------------------------------------------------*/
            // if the user supplied a non-zero value for `unitPrice` then the
            // `id` parameter must correspond to an order
            // that needs to be updated
            // the operator, collection and tokenId of the NFT received by the
            // marketplace must match the ones stored at
            // the id provided by the operator
            // in order to avoid operators increasing allowance for orders with
            // different (more valuable) NFTs
            _Order storage order = _orders[id];

            require(order.operator == _operator && order.collection == msg.sender && order.tokenId == _tokenId);
            order.erc1155Value += _value;
            order.unitPrice = unitPrice;

            emit OrderUpdated(id);
        }

        return 0xf23a6e61;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this
     * contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the
     * recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with
     * `IERC721.onERC721Received.selector`.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        (uint256 id, uint256 unitPrice, uint256[] memory commissionBps, address[] memory commissionReceivers) =
            abi.decode(_data, (uint256, uint256, uint256[], address[]));

        if (id == 0) {
            /*----------------------------------------------------------*|
            |*  # CREATE ORDER                                          *|
            |*----------------------------------------------------------*/
            // if the order/offer id parameter is 0, create a new order
            _createOrder(_operator, _from, _tokenId, 0, unitPrice, commissionBps, commissionReceivers);
        } else {
            /*----------------------------------------------------------*|
            |*  # ACCEPT OFFER                                          *|
            |*----------------------------------------------------------*/
            // if `_value` is more than the amount the following if check will
            // revert due to underflow,
            // intended to stop someone from sending more erc1155 tokens then
            // there are available in the order
            _Offer memory offer = offers[id];

            require(offer.collection == msg.sender && offer.tokenId == _tokenId);

            delete offers[id]; // ERC-721 doesn't have any supply therefore the
                // offer may be deleted after accepting the
                // offer

            _trade(
                _Order(
                    _tokenId, // uint256 tokenId
                    offer.unitPrice, // uint256 price
                    0,
                    msg.sender, // address collection
                    _from, // address buyer or from
                    offer.from, // seller
                    commissionBps, // uint256 commissionBps
                    commissionReceivers
                ),
                id,
                _primaryOffersFee //uint256 primaryFee
            );
        }

        return 0x150b7a02;
    }

    /**
     * @dev ERC-721 tokens are transferred to the buyer via `transferFrom`
     * rather than `safeTransferFrom`
     *      i.e. the caller is responsible to confirm that the recipient is
     * capable of receiving ERC721
     */
    function _transferNFT(
        address _collection,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _erc1155Value
    )
        private
    {
        bool success;
        if (_erc1155Value == 0) {
            // bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
            (success,) = _collection.call(abi.encodeWithSelector(0x42842e0e, _from, _to, _tokenId));
        } else {
            // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
            (success,) = _collection.call(abi.encodeWithSelector(0xf242432a, _from, _to, _tokenId, _erc1155Value, ""));
        }

        require(success);
    }

    function _trade(_Order memory _order, uint256 _id, uint256 _primaryMarketFee) private {
        uint256 marketplaceAmount; // declare `marketplaceAmount`, its value
            // will be calculated based on whether it is a
            // primary or secondary sale
        uint256 sellerAmount = _order.unitPrice; // sellerAmount is set equal to
            // price and reduced at each step by
            // subtracting fees, royalties and commissions, if any.
        address payable[] memory royaltyRecipients; // declare
            // `royaltyRecipients`, its value will be calculated based
            // on whether it is a primary or secondary sale
        uint256[] memory royaltyAmounts; // declare `royaltyAmounts`, its value
            // will be calculated based on whether it
            // is a primary or secondary sale
        bool checkSecondaryMarket = true;

        if (_order.collection.codehash == _ERC721SovreignV1CodeHash) {
            // it's a v1 721 token, check market registry
            (, bytes memory secondaryMarket) = _PRIMARY_MARKET_REGISTRY.call(
                abi.encodeWithSelector(
                    0x7abab711,
                    _order.collection,
                    _order.tokenId
                ) // bytes4(keccak256("secondaryMarketInfo(address,uint256)")) == 0x7abab711
            );

            checkSecondaryMarket = abi.decode(secondaryMarket, (bool));
        }

        /*----------------------------------------------------------*|
        |*  # PAY ROYALTIES                                         *|
        |*----------------------------------------------------------*/
        // > "Marketplaces that support this standard MUST pay royalties no
        // matter where the sale occurred or in what
        // currency" - https://eips.ethereum.org/EIPS/eip-2981.

        /*----------------------------------------------------------*|
        |*  # IF ROYALTIES SUPPORTED                                *|
        |*----------------------------------------------------------*/
        // The collection implements some royalty standard, otherwise the length
        // of the arrays returned would be 0.
        if (checkSecondaryMarket) {
            (royaltyRecipients, royaltyAmounts) = getRoyalty(_order.collection, _order.tokenId, _order.unitPrice);
        }
        
        uint256 royaltyRecipientsLength = royaltyRecipients.length; // assign to
            // memory variable to save gas
        if (royaltyRecipientsLength > 0) {
            if (_secondaryMarketFee > 0) {
                /*----------------------------------------------------------*|
                |*  # PAY MARKETPLACE FEE                                   *|
                |*----------------------------------------------------------*/
                marketplaceAmount = (_order.unitPrice * _secondaryMarketFee) / _BPS_DENOMINATOR;
                // subtracting primary or secondary fee amount from seller
                // amount, this is a security check (will revert
                // on underflow) as well as a variable assignment.
                sellerAmount -= marketplaceAmount; // subtract before external
                    // call
                _sendValue(_feeRecipient, marketplaceAmount);
            }

            do {
                royaltyRecipientsLength--;
                // subtracting royalty amount from seller amount, this is a
                // security check (will revert on
                // underflow) as well as a variable assignment.
                if(royaltyAmounts[royaltyRecipientsLength] > 0){
                    sellerAmount -= royaltyAmounts[royaltyRecipientsLength]; // subtract
                        // before external call
                    _sendValue(royaltyRecipients[royaltyRecipientsLength], royaltyAmounts[royaltyRecipientsLength]);
                }
            } while (royaltyRecipientsLength > 0);
        } else {
            //case primary
            marketplaceAmount = (_order.unitPrice * _primaryMarketFee) / _BPS_DENOMINATOR;
            sellerAmount -= marketplaceAmount; // subtract before external
            // call
            _sendValue(_feeRecipient, marketplaceAmount);
        }

        /*----------------------------------------------------------*|
        |*  # PAY ORDER COMMISSIONS (if any)                        *|
        |*----------------------------------------------------------*/
        uint256 commissionReceiversLength = _order.commissionReceivers.length; // assign
        if (commissionReceiversLength > 0) {
            do {
                commissionReceiversLength--;
                if(_order.commissionBps[commissionReceiversLength] > 0){
                    uint256 commissionAmount = (_order.commissionBps[commissionReceiversLength] * _order.unitPrice) / _BPS_DENOMINATOR; // calculate
                    sellerAmount -= commissionAmount; // subtract before external

                    _sendValue(_order.commissionReceivers[commissionReceiversLength], commissionAmount);
                }
            } while (commissionReceiversLength > 0);
        }

        /*----------------------------------------------------------*|
        |*  # PAY SELLER                                            *|
        |*----------------------------------------------------------*/
        _sendValue(_order.from, sellerAmount);

        /*----------------------------------------------------------*|
        |*  # TRANSFER NFT                                          *|
        |*----------------------------------------------------------*/

        _transferNFT(
            _order.collection,
            address(this),
            _order.operator, // buyer
            _order.tokenId,
            _order.erc1155Value
        );

        emit Trade(
            _order.collection,
            _order.tokenId,
            _order.from, // seller
            _id,
            _order.unitPrice,
            _order.erc1155Value
        );
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `_amount` wei to
     * `_receiver`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] raises the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {_sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn
     * more].
     *
     * IMPORTANT: because control is transferred to `_receiver`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions
     * pattern].
     */
    function _sendValue(address _receiver, uint256 _amount) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = payable(_receiver).call{ value: _amount }("");
        require(success);
    }

    /*----------------------------------------------------------*|
    |*  # ADMIN FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    /**
     * @param feeRecipient_ address (multisig) controlled by Ninfa that will
     * receive any market fees
     */
    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        _feeRecipient = feeRecipient_;
    }

    function setWhitelist(address whitelist_) external onlyOwner {
        _whitelist = whitelist_;
    }

    /**
     * @notice sets market sale fees for NINFA_ERC721_V2 communal collection.
     * @param primaryOrdersFee_ fee BPS for primary market orders, set to 500
     * BPS (5% shares) at deployment.
     * @param primaryOffersFee_ fee BPS for primary market offers, set to 500
     * BPS (5% shares) at deployment.
     */
    function setMarketFees(
        uint256 primaryOrdersFee_,
        uint256 primaryOffersFee_,
        uint256 secondaryMarketFee_
    )
        external
        onlyOwner
    {
        _primaryOrdersFee = primaryOrdersFee_;
        _primaryOffersFee = primaryOffersFee_;
        _secondaryMarketFee = secondaryMarketFee_;
    }

    function orders(uint256 _orderId) external view returns (_Order memory) {
        return _orders[_orderId];
    }

    /*----------------------------------------------------------*|
    |*  # VIEW FUNCTIONS                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     * Interface ID for IERC165 == 0x01ffc9a7
     * Return value from `onERC1155Received` call if a contract accepts receipt
     * (i.e
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
     * In all other cases the ERC1155TokenReceiver rules MUST be followed as
     * appropriate for the implementation (i.e.
     * safe, custom and/or hybrid).
     * Interface ID for IERC721Receiver. A wallet/broker/auction application
     * MUST implement the wallet interface if it
     * will accept safe transfers.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0xf23a6e61 || interfaceId == 0x150b7a02;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`
     * @dev after deployment admin needs to manually whitelist collections.
     * @param _royaltyRegistry see https://royaltyregistry.xyz/lookup for public
     * addresses
     */
    constructor(
        address _royaltyRegistry,
        address _primaryMarketRegistry,
        address factory_,
        address whitelist_,
        bytes32 ERC721SovreignV1CodeHash
    )
        RoyaltyEngineV1(_royaltyRegistry)
    {
        _PRIMARY_MARKET_REGISTRY = _primaryMarketRegistry;
        _factory = factory_;
        _whitelist = whitelist_;
        _ERC721SovreignV1CodeHash = ERC721SovreignV1CodeHash;
    }
}