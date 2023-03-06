// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/ITreasureLandExchange.sol";
import "./interfaces/IPolicyManager.sol";
import "./interfaces/ICurrencyManager.sol";
import "./policies/TransferPolicy.sol";
import {MakerOrder, TakerOrder, Properties, ItemType, AdvanceOrder} from "./libraries/OrderStructs.sol";

contract TreasureLandExchange is
    ITreasureLandExchange,
    TransferPolicy,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{

    // EIP-712 domain separator for the exchange
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) private userMinOrderNonce;
    mapping(address => mapping(uint256 => bool))
        private _isUserOrderNonceExecutedOrCancelled;

    // ERC1155 filled amount
    mapping(address => mapping(uint256 => uint256))
        private orderFilledAmount;

    address public executionDelegate;
    address public protocolFeeRecipient;
    IPolicyManager public policyManager;
    ICurrencyManager public currencyManager;

    // Events
    event NewPolicyManager(address indexed policyManager);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionDelegate(address indexed executionDelegate);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event OrderMatch(
        bool side, // false: takerBid, true: takerAsk
        bytes32 orderHash, // ask hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address of the taker bid order
        address indexed maker, // maker address of the initial ask order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 amount, // amount of tokens transferred
        uint256 price // unit transacted price
    );

    event OrderCancel(
        address indexed maker, // makerOrder signer
        uint256 nonce // item order nonce
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _executionDelegate,
        address _protocolFeeRecipient,
        address _policyManager,
        address _currencyManager
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x94061a536c65e2de4192e503ad17a8020c4c374ea94f179c4580ffe87e1d6749, // keccak256("TreasureLandExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );
        executionDelegate = _executionDelegate;
        protocolFeeRecipient = _protocolFeeRecipient;
        currencyManager = ICurrencyManager(_currencyManager);
        policyManager = IPolicyManager(_policyManager);
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * required by the openzeppelin UUPS module
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Update policy manager
     * @param _policyManager new policy manager address
     */
    function updatePolicyManager(address _policyManager) external onlyOwner {
        require(
            _policyManager != address(0),
            "updatePolicyManager: Cannot be null address"
        );
        policyManager = IPolicyManager(_policyManager);
        emit NewPolicyManager(_policyManager);
    }

    /**
     * @notice Update currency mananer
     * @param _currencyManager new currency manager address
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(
            _currencyManager != address(0),
            "updateCurrencyManager: Cannot be null address"
        );
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update protocolFeeRecipient
     * @param _protocolFeeRecipient new protocolFee recipient address
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        require(
            _protocolFeeRecipient != address(0),
            "updateProtocolFeeRecipient: Cannot be null address"
        );
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Update executionDelegate
     * @param _executionDelegate new executionDelegate address
     */
    function updateExecutionDelegate(address _executionDelegate) external onlyOwner {
        require(
            _executionDelegate != address(0),
            "updateExecutionDelegate: Cannot be null address"
        );
        executionDelegate = _executionDelegate;
        emit NewExecutionDelegate(_executionDelegate);
    }

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        require((makerAsk.side) && (!takerBid.side), "Order: Wrong Sides");
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );

        require(
            policyManager.isPolicyWhitelisted(makerAsk.policy),
            "Policy: is not whitelisted"
        );

        // Check the maker ask order
        bytes32 askHash = hashStruct(makerAsk);
        _validateOrder(makerAsk);
        AdvanceOrder memory advanceOrder = _convertOrderToAdvancedOrder(
            makerAsk,
            askHash
        );

        require(
            takerBid.offerComponents.length == 1,
            "Order: taker item out of range"
        );
        uint256 itemIndex = takerBid.offerComponents[0].itemIndex;
        require(
            itemIndex < advanceOrder.items.length,
            "Order: item index out of range"
        );
        Properties memory item = advanceOrder.items[itemIndex];
        uint256 itemNonce = makerAsk.nonce + itemIndex;

        require(
            !_isUserOrderNonceExecutedOrCancelled[makerAsk.signer][itemNonce],
            "Order: order nonce is executed or cancelled"
        );

        uint256 buyAmount = takerBid.offerComponents[0].amount;
        uint256 remainAmount = 1;
        // ERC1155 order remain amount
        if (item.itemType == ItemType.ERC1155) {
            remainAmount = item.amount - orderFilledAmount[makerAsk.signer][itemNonce];
            require(
                remainAmount >= buyAmount,
                "Order: ERC1155 insufficient amount"
            );
            orderFilledAmount[makerAsk.signer][itemNonce] += buyAmount;
        }
        if (remainAmount == buyAmount) {
            _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][itemNonce] = true;
        }

        uint256 price = item.price * buyAmount;

        // Execution part 1/2
        _transferFeesAndFunds(
            executionDelegate,
            makerAsk.payment,
            takerBid.taker,
            makerAsk.signer,
            price,
            item.royaltyFee,
            item.royaltyFeeRecipient,
            item.protocolFee,
            protocolFeeRecipient
        );

        // Execution part 2/2
        _transferNonFungibleToken(
            executionDelegate,
            item.itemType,
            item.collection,
            makerAsk.signer,
            takerBid.taker,
            item.tokenId,
            buyAmount
        );

        // emit OrderMatch Event
        _sendOrderMatchEvent(
            false,
            advanceOrder,
            item,
            takerBid.taker,
            itemNonce,
            buyAmount
        );

        // emit RoyaltyPayment Event
        _sendRoyaltyPaymentEvent(
            item.collection,
            item.tokenId,
            item.royaltyFeeRecipient,
            makerAsk.payment,
            price,
            item.royaltyFee
        );
    }

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external override nonReentrant {
        require((!makerBid.side) && (takerAsk.side), "Order: Wrong Sides");
        require(
            msg.sender == takerAsk.taker,
            "Order: Taker must be the sender"
        );

        bytes32 bidHash = hashStruct(makerBid);
        _validateOrder(makerBid);

        require(
            policyManager.isPolicyWhitelisted(makerBid.policy),
            "Policy: is not whitelisted"
        );

        AdvanceOrder memory advanceOrder = _convertOrderToAdvancedOrder(
            makerBid,
            bidHash
        );

        require(
            takerAsk.offerComponents.length == 1,
            "Order: taker item out of range"
        );
        uint256 itemIndex = takerAsk.offerComponents[0].itemIndex;
        require(
            itemIndex < advanceOrder.items.length,
            "Order: item index out of range"
        );
        Properties memory item = advanceOrder.items[itemIndex];
        uint256 itemNonce = makerBid.nonce + itemIndex;

        require(
            !_isUserOrderNonceExecutedOrCancelled[makerBid.signer][itemNonce],
            "Order: order nonce is executed or cancelled"
        );

        uint256 buyAmount = takerAsk.offerComponents[0].amount;
        uint256 remainAmount = 1;
        if (item.itemType == ItemType.ERC1155) {
            remainAmount = item.amount - orderFilledAmount[makerBid.signer][itemNonce];
            require(
                remainAmount >= buyAmount,
                "Order: ERC1155 insufficient amount"
            );
            orderFilledAmount[makerBid.signer][itemNonce] += buyAmount;
        }
        if (remainAmount == buyAmount) {
            _isUserOrderNonceExecutedOrCancelled[makerBid.signer][itemNonce] = true;
        }

        uint256 price = item.price * buyAmount;

        // Execution part 1/2
        _transferFeesAndFunds(
            executionDelegate,
            makerBid.payment,
            makerBid.signer,
            takerAsk.taker,
            price,
            item.royaltyFee,
            item.royaltyFeeRecipient,
            item.protocolFee,
            protocolFeeRecipient
        );

        // Execution part 2/2
        _transferNonFungibleToken(
            executionDelegate,
            item.itemType,
            item.collection,
            takerAsk.taker,
            makerBid.signer,
            item.tokenId,
            buyAmount
        );

        _sendOrderMatchEvent(
            true,
            advanceOrder,
            item,
            takerAsk.taker,
            itemNonce,
            buyAmount
        );

        _sendRoyaltyPaymentEvent(
            item.collection,
            item.tokenId,
            item.royaltyFeeRecipient,
            makerBid.payment,
            price,
            item.royaltyFee
        );
    }

    function batchMatchAskWithTakerBid(
        MakerOrder[] calldata makerAsks,
        TakerOrder calldata takerBid
    )
        external
        payable
        override
        nonReentrant
        returns (bool[] memory successList)
    {
        require(!takerBid.side, "Order: Wrong Sides");
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );
        uint256 ethBalanceBefore;

        assembly {
            ethBalanceBefore := sub(selfbalance(), callvalue())
        }

        successList = new bool[](takerBid.offerComponents.length);
        uint256 orderLength = makerAsks.length;
        AdvanceOrder[] memory advanceOrders = new AdvanceOrder[](orderLength);

        // Check the maker ask order
        for (uint256 i = 0; i < orderLength; i++) {
            require(makerAsks[i].side, "Order: Wrong Sides");
            bytes32 askHash = hashStruct(makerAsks[i]);
            _validateOrder(makerAsks[i]);
            advanceOrders[i] = _convertOrderToAdvancedOrder(
                makerAsks[i],
                askHash
            );
        }

        for (uint256 i = 0; i < takerBid.offerComponents.length; i++) {
            uint256 orderIndex = takerBid.offerComponents[i].orderIndex;
            uint256 itemIndex = takerBid.offerComponents[i].itemIndex;
            require(orderIndex < orderLength, "Order: orderIndex out of range");
            AdvanceOrder memory advanceOrder = advanceOrders[orderIndex];
            require(
                itemIndex < advanceOrder.items.length,
                "Order: itemIndex out of range"
            );
            Properties memory item = advanceOrder.items[itemIndex];
            uint256 itemNonce = advanceOrder.nonce + itemIndex;
            require(
                !_isUserOrderNonceExecutedOrCancelled[advanceOrder.signer][
                    itemNonce
                ],
                "Order: order is executed or cancelled"
            );
            uint256 buyAmount = takerBid.offerComponents[i].amount;
            uint256 remainAmount = 1;
            if (item.itemType == ItemType.ERC1155) {
                remainAmount = item.amount - orderFilledAmount[advanceOrder.signer][itemNonce];
                require(
                    remainAmount >= buyAmount,
                    "Order: ERC1155 insufficient amount"
                );
            }

            address taker =  takerBid.taker;
            address policy = advanceOrder.policy;
            bool success;
            if (advanceOrder.payment != address(0)) {
                (success, ) = policy.call(
                    abi.encodeWithSelector(
                        0x29e4eafe,
                        address(executionDelegate),
                        item,
                        advanceOrder.signer,
                        taker,
                        advanceOrder.payment,
                        buyAmount,
                        protocolFeeRecipient,
                        false
                    )
                );
            } else {
                uint256 price = item.price * buyAmount;
                (success, ) = policy.call{value:price}(
                    abi.encodeWithSelector(
                        0x29e4eafe,
                        address(executionDelegate),
                        item,
                        advanceOrder.signer,
                        taker,
                        advanceOrder.payment,
                        buyAmount,
                        protocolFeeRecipient,
                        false
                    )
                );
            }
            successList[i] = success;
            if (success) {
                if (item.itemType == ItemType.ERC1155) {
                    orderFilledAmount[advanceOrder.signer][itemNonce] += buyAmount;
                }
                if (remainAmount == buyAmount) {
                    _isUserOrderNonceExecutedOrCancelled[advanceOrder.signer][
                        itemNonce
                    ] = true;
                }
                _sendOrderMatchEvent(
                    false,
                    advanceOrder,
                    item,
                    taker,
                    itemNonce,
                    buyAmount
                );
                _sendRoyaltyPaymentEvent(
                    item.collection,
                    item.tokenId,
                    item.royaltyFeeRecipient,
                    advanceOrder.payment,
                    item.price,
                    item.royaltyFee
                );
            }
        }

        assembly {
            if gt(selfbalance(), ethBalanceBefore) {
                if iszero(
                    call(
                        gas(),
                        caller(),
                        sub(selfbalance(), ethBalanceBefore),
                        0,
                        0,
                        0,
                        0
                    )
                ) {

                }
            }
        }
    }

    function batchMatchBidWithTakerAsk(
        MakerOrder[] calldata makerBids,
        TakerOrder calldata takerAsk
    ) external override nonReentrant returns (bool[] memory successList) {
        require(takerAsk.side, "Order: Wrong Sides");
        require(
            msg.sender == takerAsk.taker,
            "Order: Taker must be the sender"
        );

        successList = new bool[](takerAsk.offerComponents.length);

        uint256 orderLength = makerBids.length;
        AdvanceOrder[] memory advanceOrders = new AdvanceOrder[](orderLength);

        // Check the maker bid orders
        for (uint256 i = 0; i < orderLength; i++) {
            require(!makerBids[i].side, "Order: Wrong Sides");
            bytes32 bidHash = hashStruct(makerBids[i]);
            _validateOrder(makerBids[i]);
            advanceOrders[i] = _convertOrderToAdvancedOrder(
                makerBids[i],
                bidHash
            );
        }

        for (uint256 i = 0; i < takerAsk.offerComponents.length; i++) {
            uint256 orderIndex = takerAsk.offerComponents[i].orderIndex;
            uint256 itemIndex = takerAsk.offerComponents[i].itemIndex;
            require(orderIndex < orderLength, "Order: orderIndex out of range");
            AdvanceOrder memory advanceOrder = advanceOrders[orderIndex];
            require(
                itemIndex < advanceOrder.items.length,
                "Order: itemIndex out of range"
            );
            Properties memory item = advanceOrder.items[itemIndex];
            uint256 itemNonce = advanceOrder.nonce + itemIndex;
            require(
                !_isUserOrderNonceExecutedOrCancelled[advanceOrder.signer][
                    itemNonce
                ],
                "Order: order is executed or cancelled"
            );
            uint256 buyAmount = takerAsk.offerComponents[i].amount;
            uint256 remainAmount = 1;
            if (item.itemType == ItemType.ERC1155) {
                remainAmount = advanceOrder.items[itemIndex].amount - orderFilledAmount[advanceOrder.signer][itemNonce];
                require(
                    remainAmount >= buyAmount,
                    "Order: ERC1155 insufficient amount"
                );
            }

            address taker = takerAsk.taker;
            address policy = advanceOrder.policy;
            (bool success, ) = policy.call(
                abi.encodeWithSelector(
                    0x29e4eafe,
                    address(executionDelegate),
                    item,
                    advanceOrder.signer,
                    taker,
                    advanceOrder.payment,
                    buyAmount,
                    protocolFeeRecipient,
                    true
                )
            );
            successList[i] = success;
            if (success) {
                if (item.itemType == ItemType.ERC1155) {
                    orderFilledAmount[advanceOrder.signer][itemNonce] += buyAmount;
                }
                if (remainAmount == buyAmount) {
                    _isUserOrderNonceExecutedOrCancelled[advanceOrder.signer][
                        itemNonce
                    ] = true;
                }
                _sendOrderMatchEvent(
                    true,
                    advanceOrder,
                    item,
                    taker,
                    itemNonce,
                    buyAmount
                );
                _sendRoyaltyPaymentEvent(
                    item.collection,
                    item.tokenId,
                    item.royaltyFeeRecipient,
                    advanceOrder.payment,
                    item.price,
                    item.royaltyFee
                );
            }
        }
    }

    function cancelOrder(uint256 orderNonce) public override {
        _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonce] = true;
        emit OrderCancel(msg.sender, orderNonce);
    }

    function batchCancelOrders(
        uint256[] calldata orderNonces
    ) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelOrder(orderNonces[i]);
        }
    }

    function hashStruct(
        MakerOrder memory makerOrder
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0xec12f49c657620bcbccaad930ac38707dd428b3d0ae44ef9776a1efcfe6535d9, // keccak256("MakerOrder(bool side,address signer,address policy,address payment,uint256 nonce,uint256 startTime,uint256 endTime,bytes params)")
                    makerOrder.side,
                    makerOrder.signer,
                    makerOrder.policy,
                    makerOrder.payment,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    keccak256(bytes(makerOrder.params))
                )
            );
    }

    function _validateOrder(
        MakerOrder calldata makerOrder
    ) internal view {

        require(
            (makerOrder.startTime <= block.timestamp) &&
                (makerOrder.endTime >= block.timestamp),
            "Order: order expired"
        );

        // Verify whether order nonce has expired
        require(
            makerOrder.nonce >= userMinOrderNonce[makerOrder.signer],
            "Order: Matching order expired"
        );

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the validity of the signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct(makerOrder)
            )
        );
        require(
            ecrecover(digest, makerOrder.v, makerOrder.r, makerOrder.s) ==
                makerOrder.signer,
            "Signature: Invalid"
        );

        require(currencyManager.isCurrencyWhitelisted(makerOrder.payment), "Currency: Not whitelisted");

        require(policyManager.isPolicyWhitelisted(makerOrder.policy), "Policy: Not whitelisted");
    }

    /**
     * @notice convert order to advanceOrder
     * @param order origin order
     * @param orderHash order hash
     * @return advanceOrder advance order
     */
    function _convertOrderToAdvancedOrder(
        MakerOrder calldata order,
        bytes32 orderHash
    ) internal pure returns (AdvanceOrder memory advanceOrder) {
        Properties[] memory items = abi.decode(order.params, (Properties[]));
        require(items.length > 0, "items is empty");
        advanceOrder = AdvanceOrder(
            order.policy,
            order.payment,
            order.signer,
            order.nonce,
            items,
            orderHash
        );
    }

    function _sendOrderMatchEvent(
        bool side,
        AdvanceOrder memory advanceOrder,
        Properties memory item,
        address taker,
        uint256 itemNonce,
        uint256 buyAmount
    ) internal {
        emit OrderMatch(
            side,
            advanceOrder.orderHash,
            itemNonce,
            taker,
            advanceOrder.signer,
            advanceOrder.policy,
            advanceOrder.payment,
            item.collection,
            item.tokenId,
            buyAmount,
            item.price
        );
    }

    function _sendRoyaltyPaymentEvent(
        address collection,
        uint256 tokenId,
        address royaltyFeeRecipient,
        address currency,
        uint256 amount,
        uint256 royaltyFee
    ) internal {
        uint256 royaltyFeeAmount = (royaltyFee * amount) / 10000;
        emit RoyaltyPayment(
            collection,
            tokenId,
            royaltyFeeRecipient,
            currency,
            royaltyFeeAmount
        );
    }
}