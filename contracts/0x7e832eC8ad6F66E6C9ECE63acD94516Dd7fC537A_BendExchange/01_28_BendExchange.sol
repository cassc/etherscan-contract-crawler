// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Bend interfaces
import {IAuthorizationManager} from "./interfaces/IAuthorizationManager.sol";
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IBendExchange} from "./interfaces/IBendExchange.sol";
import {ITransferManager} from "./interfaces/ITransferManager.sol";
import {IInterceptorManager} from "./interfaces/IInterceptorManager.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {IAuthenticatedProxy} from "./interfaces/IAuthenticatedProxy.sol";

// Bend libraries
import {OrderTypes} from "./libraries/OrderTypes.sol";
import {SafeProxy} from "./libraries/SafeProxy.sol";

/**
 * @title BendExchange
 * @notice It is the core contract of the Bend exchange.
 */
contract BendExchange is IBendExchange, ReentrancyGuard, Ownable {
    using SafeProxy for IAuthenticatedProxy;
    using SafeERC20 for IERC20;

    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    string public constant NAME = "BendExchange";
    string public constant VERSION = "1";

    bytes32 public immutable DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    address public immutable WETH;

    address public protocolFeeRecipient;

    IAuthorizationManager public authorizationManager;
    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    ITransferManager public transferManager;
    IInterceptorManager public interceptorManager;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionManager(address indexed executionManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewTransferManager(address indexed transferManager);
    event NewAuthorizationManager(address indexed authorizationManager);
    event NewInterceptorManager(address indexed interceptorManager);

    event ProtocolFeePayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed protocolFeeRecipient,
        address currency,
        uint256 amount
    );

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event TakerAsk(
        bytes32 makerOrderHash, // bid hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker ask order
        address indexed maker, // maker address of the initial bid order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 amount, // amount of tokens transferred
        uint256 price // final transacted price
    );

    event TakerBid(
        bytes32 makerOrderHash, // ask hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker bid order
        address indexed maker, // maker address of the initial ask order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 amount, // amount of tokens transferred
        uint256 price // final transacted price
    );

    /**
     * @notice Constructor
     * @param _interceptorManager interceptor manager address
     * @param _transferManager transfer manager address
     * @param _currencyManager currency manager address
     * @param _executionManager execution manager address
     * @param _royaltyFeeManager royalty fee manager address
     * @param _WETH wrapped ether address (for other chains, use wrapped native asset)
     * @param _protocolFeeRecipient protocol fee recipient
     */
    constructor(
        address _interceptorManager,
        address _transferManager,
        address _currencyManager,
        address _executionManager,
        address _royaltyFeeManager,
        address _WETH,
        address _protocolFeeRecipient
    ) {
        // Calculate the domain separator

        // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
        // keccak256("BendExchange")
        _HASHED_NAME = 0xba0c660933e3f2279319fe2b72a6f829a2438d726bbe835523453fc0414c6020;
        // keccak256(bytes("1"))
        _HASHED_VERSION = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);

        DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);

        transferManager = ITransferManager(_transferManager);
        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        interceptorManager = IInterceptorManager(_interceptorManager);
        WETH = _WETH;
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce minimum user nonce
     */
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel: order nonce lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: can not cancel more orders");
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
        require(orderNonces.length > 0, "Cancel: can not be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: order nonce lower than current");
            _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }

        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    /**
     * @notice Match ask with a taker bid order using ETH
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: wrong sides");
        require(makerAsk.currency == WETH || makerAsk.currency == address(0), "Order: currency must be WETH or ETH");
        require(msg.sender == takerBid.taker, "Order: taker must be the sender");
        require(takerBid.price >= msg.value, "Order: Msg.value too high");
        if (msg.value > 0) {
            // Wrap ETH sent to this contract
            IWETH(WETH).deposit{value: msg.value}();

            // Sent WETH back to sender
            IERC20(WETH).safeTransfer(msg.sender, msg.value);
        }

        require(takerBid.price <= IWETH(WETH).balanceOf(msg.sender), "Order: price too high and insufficient WETH");

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrders(makerAsk, askHash, takerBid);

        // Retrieve execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.maker][makerAsk.nonce] = true;

        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.maker,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(
            makerAsk.interceptor,
            makerAsk.interceptorExtra,
            makerAsk.collection,
            makerAsk.maker,
            takerBid.taker,
            tokenId,
            amount
        );

        _withdrawFunds(makerAsk.currency, makerAsk.maker);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.maker,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     * @notice Match a takerBid with a makerAsk
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        override
        nonReentrant
    {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: wrong sides");
        require(msg.sender == takerBid.taker, "Order: taker must be the sender");

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrders(makerAsk, askHash, takerBid);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.maker][makerAsk.nonce] = true;

        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.maker,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(
            makerAsk.interceptor,
            makerAsk.interceptorExtra,
            makerAsk.collection,
            makerAsk.maker,
            takerBid.taker,
            tokenId,
            amount
        );

        _withdrawFunds(makerAsk.currency, makerAsk.maker);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.maker,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     * @notice Match a takerAsk with a makerBid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     */
    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        override
        nonReentrant
    {
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Order: wrong sides");
        require(msg.sender == takerAsk.taker, "Order: taker must be the sender");

        // Check the maker bid order
        bytes32 bidHash = makerBid.hash();
        _validateOrders(makerBid, bidHash, takerAsk);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerBid.strategy)
            .canExecuteTakerAsk(takerAsk, makerBid);
        require(isExecutionValid, "Strategy: execution invalid");

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerBid.maker][makerBid.nonce] = true;

        _transferFeesAndFunds(
            makerBid.strategy,
            makerBid.collection,
            tokenId,
            makerBid.currency,
            makerBid.maker,
            takerAsk.taker,
            takerAsk.price,
            takerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(
            takerAsk.interceptor,
            takerAsk.interceptorExtra,
            makerBid.collection,
            msg.sender,
            makerBid.maker,
            tokenId,
            amount
        );

        _withdrawFunds(makerBid.currency, takerAsk.taker);

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.maker,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            takerAsk.price
        );
    }

    /**
     * @notice Update currency manager
     * @param _currencyManager new currency manager address
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Owner: can not be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update execution manager
     * @param _executionManager new execution manager address
     */
    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Owner: can not be null address");
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Update royalty fee manager
     * @param _royaltyFeeManager new fee manager address
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Owner: can not be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    function updateTransferManager(address _transferManager) external onlyOwner {
        require(_transferManager != address(0), "Owner: can not be null address");
        transferManager = ITransferManager(_transferManager);
        emit NewTransferManager(_transferManager);
    }

    function updateAuthorizationManager(address _authorizationManager) external onlyOwner {
        require(_authorizationManager != address(0), "Owner: can not be null address");
        authorizationManager = IAuthorizationManager(_authorizationManager);
        emit NewAuthorizationManager(_authorizationManager);
    }

    function updateInterceptorManager(address _interceptorManager) external onlyOwner {
        require(_interceptorManager != address(0), "Owner: can not be null address");
        interceptorManager = IInterceptorManager(_interceptorManager);
        emit NewInterceptorManager(_interceptorManager);
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    function _withdrawFunds(address currency, address recipient) internal {
        IAuthenticatedProxy proxy = IAuthenticatedProxy(authorizationManager.proxies(recipient));
        if (_isNativeETH(currency)) {
            proxy.withdrawETH();
        } else {
            proxy.withdrawToken(currency);
        }
    }

    function _isNativeETH(address currency) internal pure returns (bool) {
        return currency == address(0);
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param strategy address of the execution strategy
     * @param collection non fungible token address for the transfer
     * @param tokenId tokenId
     * @param currency currency being used for the purchase (e.g., WETH/USDC)
     * @param from sender of the funds
     * @param to seller's recipient
     * @param amount amount being transferred (in currency)
     * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
     */
    function _transferFeesAndFunds(
        address strategy,
        address collection,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        IAuthenticatedProxy fromProxy = IAuthenticatedProxy(authorizationManager.proxies(from));
        IAuthenticatedProxy toProxy = IAuthenticatedProxy(authorizationManager.proxies(to));
        require(address(fromProxy) != address(0), "Authorization: no delegate proxy");
        require(address(toProxy) != address(0), "Authorization: no delegate proxy");

        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        if (_isNativeETH(currency)) {
            currency = WETH;
        }

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                fromProxy.safeTransfer(currency, protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
                emit ProtocolFeePayment(collection, tokenId, protocolFeeRecipient, currency, protocolFeeAmount);
            }
        }

        // 2. Royalty fee
        {
            (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
                .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

            // Check if there is a royalty fee and that it is different to 0
            if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                fromProxy.safeTransfer(currency, royaltyFeeRecipient, royaltyFeeAmount);
                finalSellerAmount -= royaltyFeeAmount;
                emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipient, currency, royaltyFeeAmount);
            }
        }

        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "Fees: higher than expected");

        // 3. Transfer final amount (post-fees) to seller proxy
        {
            fromProxy.safeTransfer(currency, address(toProxy), finalSellerAmount);
        }
    }

    /**
     * @notice Transfer NFT
     * @param collection address of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferNonFungibleToken(
        address interceptor,
        bytes memory InterceptorExtra,
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        IAuthenticatedProxy proxy = IAuthenticatedProxy(authorizationManager.proxies(from));
        require(address(proxy) != address(0), "Authorization: no delegate proxy");

        // Retrieve the transfer manager address
        address transfer = transferManager.checkTransferForToken(collection);

        // If no transfer found, it returns address(0)
        require(transfer != address(0), "Transfer: no NFT transfer available");

        proxy.safeTransferNonFungibleTokenFrom(
            transfer,
            interceptor,
            collection,
            from,
            to,
            tokenId,
            amount,
            InterceptorExtra
        );
    }

    /**
     * @notice Calculate protocol fee for an execution strategy
     * @param executionStrategy strategy
     * @param amount amount to transfer
     */
    function _calculateProtocolFee(address executionStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = IExecutionStrategy(executionStrategy).viewProtocolFee();
        return (protocolFee * amount) / 10000;
    }

    /**
     * @notice Verify the validity of the maker order
     * @param makerOrder maker order
     * @param makerOrderHash computed hash for the order
     */
    function _validateOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        bytes32 makerOrderHash,
        OrderTypes.TakerOrder calldata takerOrder
    ) internal view {
        // Verify whether order nonce has expired
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.maker][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.maker]),
            "Order: matching order expired"
        );

        // Verify the maker is not address(0)
        require(makerOrder.maker != address(0), "Order: invalid maker");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: amount cannot be 0");

        // Verify the validity of the signature
        require(
            SignatureChecker.isValidSignatureNow(
                makerOrder.maker,
                ECDSA.toTypedDataHash(_domainSeparatorV4(), makerOrderHash),
                abi.encodePacked(makerOrder.r, makerOrder.s, makerOrder.v)
            ),
            "Signature: invalid"
        );

        // Verify whether the currency is whitelisted, address(0) means native ETH
        require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: not whitelisted");

        // Verify whether strategy can be executed
        require(executionManager.isStrategyWhitelisted(makerOrder.strategy), "Strategy: not whitelisted");

        if (makerOrder.interceptor != address(0)) {
            require(
                interceptorManager.isInterceptorWhitelisted(makerOrder.interceptor),
                "Interceptor: maker interceptor not whitelisted"
            );
        }
        if (takerOrder.interceptor != address(0)) {
            require(
                interceptorManager.isInterceptorWhitelisted(takerOrder.interceptor),
                "Interceptor: taker interceptor not whitelisted"
            );
        }
    }
}