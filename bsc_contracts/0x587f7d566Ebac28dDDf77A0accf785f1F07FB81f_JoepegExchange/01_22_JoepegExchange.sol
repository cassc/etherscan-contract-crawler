// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Joepeg interfaces
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";
import {IProtocolFeeManager} from "./interfaces/IProtocolFeeManager.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IJoepegExchange} from "./interfaces/IJoepegExchange.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";
import {IWAVAX} from "./interfaces/IWAVAX.sol";

// Joepeg libraries
import {OrderTypes} from "./libraries/OrderTypes.sol";
import {RoyaltyFeeTypes} from "./libraries/RoyaltyFeeTypes.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

/**
 * @title JoepegExchange
 * @notice Fork of the LooksRareExchange contract with some minor additions.
 */
contract JoepegExchange is
    IJoepegExchange,
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    using RoyaltyFeeTypes for RoyaltyFeeTypes.FeeAmountPart;
    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    uint256 public immutable PERCENTAGE_PRECISION = 10000;

    address public WAVAX;
    bytes32 public domainSeparator;

    address public protocolFeeRecipient;

    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;
    IProtocolFeeManager public protocolFeeManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    ITransferSelectorNFT public transferSelectorNFT;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool))
        private _isUserOrderNonceExecutedOrCancelled;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionManager(address indexed executionManager);
    event NewProtocolFeeManager(address indexed protocolFeeManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event TakerAsk(
        bytes32 orderHash, // bid hash of the maker order
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
        bytes32 orderHash, // ask hash of the maker order
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
     * @param _currencyManager currency manager address
     * @param _executionManager execution manager address
     * @param _protocolFeeManager protocol fee manager address
     * @param _royaltyFeeManager royalty fee manager address
     * @param _WAVAX wrapped ether address (for other chains, use wrapped native asset)
     * @param _protocolFeeRecipient protocol fee recipient
     */
    function initialize(
        address _currencyManager,
        address _executionManager,
        address _protocolFeeManager,
        address _royaltyFeeManager,
        address _WAVAX,
        address _protocolFeeRecipient
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        // Calculate the domain separator
        domainSeparator = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x09c73de1316dde4c80e91bee77727ccdf2cbf7435c9e4c7db6c37af85fa4afcb, // keccak256("JoepegExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        protocolFeeManager = IProtocolFeeManager(_protocolFeeManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        WAVAX = _WAVAX;
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce minimum user nonce
     */
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(
            minNonce > userMinOrderNonce[msg.sender],
            "Cancel: Order nonce lower than current"
        );
        require(
            minNonce < userMinOrderNonce[msg.sender] + 500000,
            "Cancel: Cannot cancel more orders"
        );
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces)
        external
    {
        require(orderNonces.length > 0, "Cancel: Cannot be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(
                orderNonces[i] >= userMinOrderNonce[msg.sender],
                "Cancel: Order nonce lower than current"
            );
            _isUserOrderNonceExecutedOrCancelled[msg.sender][
                orderNonces[i]
            ] = true;
        }

        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    /**
     * @notice Match ask with a taker bid order using AVAX
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBidUsingAVAXAndWAVAX(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        // Transfer WAVAX if needed
        _transferWAVAXIfNeeded(takerBid.price);
        // Wrap AVAX sent to this contract
        IWAVAX(WAVAX).deposit{value: msg.value}();
        // Match orders
        _matchAskWithTakerBidUsingAVAXAndWAVAX(takerBid, makerAsk);
    }

    /**
     * @notice Validate order sides, maker ask currency and taker bid sender
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function _validateMakerAskAndTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) internal view {
        require(
            (makerAsk.isOrderAsk) && (!takerBid.isOrderAsk),
            "Order: Wrong sides"
        );
        require(makerAsk.currency == WAVAX, "Order: Currency must be WAVAX");
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );
    }

    /**
     * @notice Match ask with a taker bid order using AVAX and ignore expired asks if any
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function _matchAskWithTakerBidUsingAVAXAndWAVAXIgnoringExpiredAsks(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) internal returns (bool) {
        // Validate orders
        _validateMakerAskAndTakerBid(takerBid, makerAsk);

        // Skip call when maker ask has expired
        if (!_checkMakerOrderNotExpired(makerAsk)) {
            return false;
        }

        // Match orders
        _matchAskWithTakerBidUsingAVAXAndWAVAX(takerBid, makerAsk);
        return true;
    }

    /**
     * @notice Match ask with a taker bid order using AVAX
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function _matchAskWithTakerBidUsingAVAXAndWAVAX(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) internal {
        // Validate orders
        _validateMakerAskAndTakerBid(takerBid, makerAsk);

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        // Retrieve execution parameters
        (
            bool isExecutionValid,
            uint256 tokenId,
            uint256 amount
        ) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(
                takerBid,
                makerAsk
            );

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][
            makerAsk.nonce
        ] = true;

        // Execution part 1/2
        _transferFeesAndFundsWithWAVAX(
            makerAsk.collection,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // Execution part 2/2
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount
        );

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     * @notice Transfer WAVAX from the buyer if not enough AVAX to cover the cost
     * @param cost the total cost of the sale
     */
    function _transferWAVAXIfNeeded(uint256 cost) internal {
        if (cost > msg.value) {
            IERC20(WAVAX).safeTransferFrom(
                msg.sender,
                address(this),
                (cost - msg.value)
            );
        } else {
            require(cost == msg.value, "Order: Msg.value too high");
        }
    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external override nonReentrant {
        require(
            (makerAsk.isOrderAsk) && (!takerBid.isOrderAsk),
            "Order: Wrong sides"
        );
        require(
            msg.sender == takerBid.taker,
            "Order: Taker must be the sender"
        );

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        (
            bool isExecutionValid,
            uint256 tokenId,
            uint256 amount
        ) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(
                takerBid,
                makerAsk
            );

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][
            makerAsk.nonce
        ] = true;

        // Execution part 1/2
        _transferFeesAndFunds(
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // Execution part 2/2
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount
        );

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
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
    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external override nonReentrant {
        require(
            (!makerBid.isOrderAsk) && (takerAsk.isOrderAsk),
            "Order: Wrong sides"
        );
        require(
            msg.sender == takerAsk.taker,
            "Order: Taker must be the sender"
        );

        // Check the maker bid order
        bytes32 bidHash = makerBid.hash();
        _validateOrder(makerBid, bidHash);

        (
            bool isExecutionValid,
            uint256 tokenId,
            uint256 amount
        ) = IExecutionStrategy(makerBid.strategy).canExecuteTakerAsk(
                takerAsk,
                makerBid
            );

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][
            makerBid.nonce
        ] = true;

        // Execution part 1/2
        _transferNonFungibleToken(
            makerBid.collection,
            msg.sender,
            makerBid.signer,
            tokenId,
            amount
        );

        // Execution part 2/2
        _transferFeesAndFunds(
            makerBid.collection,
            tokenId,
            makerBid.currency,
            makerBid.signer,
            takerAsk.taker,
            takerAsk.price,
            takerAsk.minPercentageToAsk
        );

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
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
    function updateCurrencyManager(address _currencyManager)
        external
        onlyOwner
    {
        require(
            _currencyManager != address(0),
            "Owner: Cannot be null address"
        );
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update execution manager
     * @param _executionManager new execution manager address
     */
    function updateExecutionManager(address _executionManager)
        external
        onlyOwner
    {
        require(
            _executionManager != address(0),
            "Owner: Cannot be null address"
        );
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    /**
     * @notice Update protocol fee manager
     * @param _protocolFeeManager new protocol fee manager address
     */
    function updateProtocolFeeManager(address _protocolFeeManager)
        external
        onlyOwner
    {
        require(
            _protocolFeeManager != address(0),
            "Owner: Cannot be null address"
        );
        protocolFeeManager = IProtocolFeeManager(_protocolFeeManager);
        emit NewProtocolFeeManager(_protocolFeeManager);
    }

    /**
     * @notice Update protocol fee recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Update royalty fee manager
     * @param _royaltyFeeManager new fee manager address
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager)
        external
        onlyOwner
    {
        require(
            _royaltyFeeManager != address(0),
            "Owner: Cannot be null address"
        );
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    /**
     * @notice Update transfer selector NFT
     * @param _transferSelectorNFT new transfer selector address
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT)
        external
        onlyOwner
    {
        require(
            _transferSelectorNFT != address(0),
            "Owner: Cannot be null address"
        );
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);

        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(
        address user,
        uint256 orderNonce
    ) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    /**
     * @notice Match multiple asks with their respective taker bid order using AVAX and WAVAX
     * @param trades an array of trades
     */
    function batchBuyWithAVAXAndWAVAX(Trade[] calldata trades)
        external
        payable
        nonReentrant
    {
        // Calculate the total cost of all orders
        uint256 totalCost;
        for (uint256 i; i < trades.length; ++i) {
            totalCost += trades[i].takerBid.price;
        }

        // Transfer WAVAX if needed
        _transferWAVAXIfNeeded(totalCost);

        // Wrap AVAX sent to this contract
        IWAVAX(WAVAX).deposit{value: msg.value}();

        // Match orders
        for (uint256 i; i < trades.length; ++i) {
            _matchAskWithTakerBidUsingAVAXAndWAVAX(
                trades[i].takerBid,
                trades[i].makerAsk
            );
        }
    }

    /**
     * @notice Match multiple asks with their respective taker bid order using AVAX and WAVAX, ignoring expired maker asks
     * @dev Used when the caller doesn't want the transaction to revert if a maker ask already expired
     * @param trades an array of trades
     */
    function batchBuyWithAVAXAndWAVAXIgnoringExpiredAsks(
        Trade[] calldata trades
    ) external payable nonReentrant returns (bool[] memory transferStatus) {
        transferStatus = new bool[](trades.length);

        // Calculate the total cost of all valid orders
        uint256 totalCost;
        for (uint256 i; i < trades.length; ++i) {
            if (_checkMakerOrderNotExpired(trades[i].makerAsk)) {
                totalCost += trades[i].takerBid.price;
            }
        }

        // Transfer WAVAX if needed
        if (totalCost > msg.value) {
            IERC20(WAVAX).safeTransferFrom(
                msg.sender,
                address(this),
                (totalCost - msg.value)
            );

            // Wrap AVAX sent to this contract
            IWAVAX(WAVAX).deposit{value: msg.value}();
        } else {
            // Wrap AVAX needed to pay for valid orders
            IWAVAX(WAVAX).deposit{value: totalCost}();
        }

        // Match orders
        for (uint256 i; i < trades.length; ++i) {
            bool status = _matchAskWithTakerBidUsingAVAXAndWAVAXIgnoringExpiredAsks(
                trades[i].takerBid,
                trades[i].makerAsk
            );
            transferStatus[i] = status;
        }

        // Return remaining AVAX (if any)
        if (msg.value > totalCost) {
            uint256 remainingAVAX = msg.value - totalCost;
            (bool sent, ) = msg.sender.call{value: remainingAVAX}("");
            require(sent, "Batch Buy: Failed to return remaining AVAX");
        }
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param collection non fungible token address for the transfer
     * @param tokenId tokenId
     * @param currency address of token being used for the purchase (e.g., WAVAX/USDC)
     * @param from sender of the funds
     * @param to seller's recipient
     * @param amount amount being transferred (in currency)
     * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
     */
    function _transferFeesAndFunds(
        address collection,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(
                collection,
                amount
            );

            // Check if the protocol fee is different than 0 for this strategy
            if (
                (protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)
            ) {
                IERC20(currency).safeTransferFrom(
                    from,
                    protocolFeeRecipient,
                    protocolFeeAmount
                );
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {
            RoyaltyFeeTypes.FeeAmountPart[]
                memory feeAmountParts = royaltyFeeManager
                    .calculateRoyaltyFeeAmountParts(
                        collection,
                        tokenId,
                        amount
                    );

            for (uint256 i; i < feeAmountParts.length; i++) {
                RoyaltyFeeTypes.FeeAmountPart
                    memory feeAmountPart = feeAmountParts[i];
                IERC20(currency).safeTransferFrom(
                    from,
                    feeAmountPart.receiver,
                    feeAmountPart.amount
                );
                finalSellerAmount -= feeAmountPart.amount;

                emit RoyaltyPayment(
                    collection,
                    tokenId,
                    feeAmountPart.receiver,
                    currency,
                    feeAmountPart.amount
                );
            }
        }

        require(
            (finalSellerAmount * PERCENTAGE_PRECISION) >=
                (minPercentageToAsk * amount),
            "Fees: Higher than expected"
        );

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param collection non fungible token address for the transfer
     * @param tokenId tokenId
     * @param to seller's recipient
     * @param amount amount being transferred (in currency)
     * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
     */
    function _transferFeesAndFundsWithWAVAX(
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(
                collection,
                amount
            );

            // Check if the protocol fee is different than 0 for this strategy
            if (
                (protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)
            ) {
                IERC20(WAVAX).safeTransfer(
                    protocolFeeRecipient,
                    protocolFeeAmount
                );
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {
            RoyaltyFeeTypes.FeeAmountPart[]
                memory feeAmountParts = royaltyFeeManager
                    .calculateRoyaltyFeeAmountParts(
                        collection,
                        tokenId,
                        amount
                    );

            for (uint256 i; i < feeAmountParts.length; i++) {
                RoyaltyFeeTypes.FeeAmountPart
                    memory feeAmountPart = feeAmountParts[i];
                IERC20(WAVAX).safeTransfer(
                    feeAmountPart.receiver,
                    feeAmountPart.amount
                );
                finalSellerAmount -= feeAmountPart.amount;

                emit RoyaltyPayment(
                    collection,
                    tokenId,
                    feeAmountPart.receiver,
                    WAVAX,
                    feeAmountPart.amount
                );
            }
        }

        require(
            (finalSellerAmount * PERCENTAGE_PRECISION) >=
                (minPercentageToAsk * amount),
            "Fees: Higher than expected"
        );

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(WAVAX).safeTransfer(to, finalSellerAmount);
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
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Retrieve the transfer manager address
        address transferManager = transferSelectorNFT
            .checkTransferManagerForToken(collection);

        // If no transfer manager found, it returns address(0)
        require(
            transferManager != address(0),
            "Transfer: No NFT transfer manager available"
        );

        // If one is found, transfer the token
        ITransferManagerNFT(transferManager).transferNonFungibleToken(
            collection,
            from,
            to,
            tokenId,
            amount
        );
    }

    /**
     * @notice Calculate protocol fee for a given collection
     * @param _collection address of collection
     * @param _amount amount to transfer
     */
    function _calculateProtocolFee(address _collection, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 protocolFee = protocolFeeManager.protocolFeeForCollection(
            _collection
        );
        return (protocolFee * _amount) / PERCENTAGE_PRECISION;
    }

    /**
      * @notice Check whether the maker order has expired or not
      * @param makerOrder maker order  
     */
    function _checkMakerOrderNotExpired(OrderTypes.MakerOrder calldata makerOrder)
        internal
        view
        returns (bool)
    {
        return
            !_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
                makerOrder.nonce
            ] && makerOrder.nonce >= userMinOrderNonce[makerOrder.signer];
    }

    /**
     * @notice Verify the validity of the maker order
     * @param makerOrder maker order
     * @param orderHash computed hash for the order
     */
    function _validateOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        bytes32 orderHash
    ) internal view {
        // Verify whether order nonce has expired
        require(
            _checkMakerOrderNotExpired(makerOrder),
            "Order: Matching order expired"
        );

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: Amount cannot be 0");

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                domainSeparator
            ),
            "Signature: Invalid"
        );

        // Verify whether the currency is whitelisted
        require(
            currencyManager.isCurrencyWhitelisted(makerOrder.currency),
            "Currency: Not whitelisted"
        );

        // Verify whether strategy can be executed
        require(
            executionManager.isStrategyWhitelisted(makerOrder.strategy),
            "Strategy: Not whitelisted"
        );
    }
}