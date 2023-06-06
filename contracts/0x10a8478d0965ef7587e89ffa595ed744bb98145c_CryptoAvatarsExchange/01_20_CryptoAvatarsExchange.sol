// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// CryptoAvatars interfaces
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {ICryptoAvatarsExchange} from "./interfaces/ICryptoAvatarsExchange.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";
import {ICollectionManager} from "./interfaces/ICollectionManager.sol";
import {IWETH} from "./interfaces/IWETH.sol";

// CryptoAvatars libraries
import {OrderTypes} from "./libraries/OrderTypes.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

/**
 * @title CryptoAvatars
 * @notice It is the core contract of the CryptoAvatars exchange.
 */
contract CryptoAvatarsExchange is ICryptoAvatarsExchange, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    address public immutable WETH;
    bytes32 public immutable DOMAIN_SEPARATOR;

    address public protocolFeeRecipient;
    address public signer;

    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    ITransferSelectorNFT public transferSelectorNFT;
    ICollectionManager public collectionManager;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionManager(address indexed executionManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewCollectionManager(address indexed collectionManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event MarketSell(
        bytes makerOrder, // maker order data
        bytes takerOrder // taker order data
    );

    /**
     * @notice Constructor
     * @param _currencyManager currency manager address
     * @param _executionManager execution manager address
     * @param _royaltyFeeManager royalty fee manager address
     * @param _WETH wrapped ether address (for other chains, use wrapped native asset)
     * @param _protocolFeeRecipient protocol fee recipient
     */
    constructor(
        address _currencyManager,
        address _executionManager,
        address _royaltyFeeManager,
        address _collectionManager,
        address _WETH,
        address _protocolFeeRecipient,
        address _signer
    ) {
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x479e4b32420d5d35c74f62189f17325d7fd3b51ff82b6be4bcab394dc45ea1d9, // keccak256("CryptoAvatars")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        collectionManager = ICollectionManager(_collectionManager);
        WETH = _WETH;
        protocolFeeRecipient = _protocolFeeRecipient;
        signer = _signer;
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce minimum user nonce
     */
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: Cannot cancel more orders");
        userMinOrderNonce[msg.sender] = minNonce;
        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
        require(orderNonces.length > 0, "Cancel: Cannot be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
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
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(makerAsk.currency == WETH, "Order: Currency must be WETH");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // If not enough ETH to cover the price, use WETH
        if (takerBid.price > msg.value) {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        } else {
            require(takerBid.price == msg.value, "Order: Msg.value too high");
        }

        // Wrap ETH sent to this contract
        IWETH(WETH).deposit{value: msg.value}();

        // Check maker ask and taker bid orders
        _validateOrder(makerAsk, takerBid);

        // Retrieve execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // Execution part 1/2
        _transferFeesAndFundsWithWETH(
           makerAsk,
           takerBid, 
           makerAsk.signer
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        // Emit event
        emit MarketSell(abi.encode(makerAsk), abi.encode(takerBid));

    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        override
        nonReentrant
    {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // Check the maker ask order
        _validateOrder(makerAsk, takerBid);


        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // Execution part 1/2
        _transferFeesAndFunds(makerAsk, takerBid, takerBid.taker, makerAsk.signer);

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        // Emit event
        emit MarketSell(abi.encode(makerAsk), abi.encode(takerBid));
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
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

        // Check the maker bid order
        _validateOrder(makerBid, takerAsk);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerBid.strategy)
            .canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Strategy: Execution invalid");

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        // Execution part 1/2
        _transferNonFungibleToken(makerBid.collection, takerAsk.taker, makerBid.signer, tokenId, amount);
        
        // Execution part 2/2
        _transferFeesAndFunds(makerBid, takerAsk, makerBid.signer, takerAsk.taker);

        // Emit event
        emit MarketSell(abi.encode(makerBid), abi.encode(takerAsk));

    }

    /**
    * @notice Update signer
    * @param _signer new marketplace signer
    */
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Owner: Cannot be null address");
        signer = _signer;
    }

    /**
     * @notice Update currency manager
     * @param _currencyManager new currency manager address
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Owner: Cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update execution manager
     * @param _executionManager new execution manager address
     */
    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Owner: Cannot be null address");
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    /**
     * @notice Update collection manager
     * @param _collectionManager new collection manager address
     */
    function updateCollectionManager(address _collectionManager) external onlyOwner {
        require(_collectionManager != address(0), "Owner: Cannot be null address");
        collectionManager = ICollectionManager(_collectionManager);
        emit NewCollectionManager(_collectionManager);
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
        require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    /**
     * @notice Update transfer selector NFT
     * @param _transferSelectorNFT new transfer selector address
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Owner: Cannot be null address");
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);   
        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param takerOrder taker order 
     * @param makerOrder maker order
     * @param from _msgSender()  
     */
    function _transferFeesAndFunds(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.TakerOrder calldata takerOrder, 
        address from, 
        address to
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = makerOrder.price;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(makerOrder.strategy, makerOrder.price);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(makerOrder.currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {        
            if(!isZeroBytes(takerOrder.dataCryptoAvatars)) { // Is CryptoAvatars, pay a fee to the avatar creator
                (address creator , uint256 royaltyFee) = abi.decode(takerOrder.dataCryptoAvatars, (address, uint256));
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyFee) / 10000 ;
                if ((creator != address(0)) && (royaltyCreatorFeeAmount != 0)) {
                    IERC20(makerOrder.currency).safeTransferFrom(from, creator, royaltyCreatorFeeAmount);
                    finalSellerAmount -= royaltyCreatorFeeAmount;
                }
            }
            else if(!isZeroBytes(takerOrder.dataRemix)) { // Is Remix, pay a fee to the remix creator and to the collection owner
                (address creatorRemix, address ownerRemix) = abi.decode(takerOrder.dataRemix, (address, address));
                uint256 royaltyCreatorFee = royaltyFeeManager.getRemixCreatorRoyaltyFee();
                uint256 royaltyOwnerFee = royaltyFeeManager.getRemixOwnerRoyaltyFee();
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyCreatorFee) / 10000 ;
                uint256 royaltyOwnerFeeAmount =  (makerOrder.price * royaltyOwnerFee) / 10000 ;
                IERC20(makerOrder.currency).safeTransferFrom(from, creatorRemix, royaltyCreatorFeeAmount);
                IERC20(makerOrder.currency).safeTransferFrom(from, ownerRemix, royaltyOwnerFeeAmount);
                finalSellerAmount -= royaltyCreatorFeeAmount + royaltyOwnerFeeAmount;
            }
            else { // It is a non CA collection, pay a fee to the collection owner
                (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
                    .calculateRoyaltyFeeAndGetRecipient(makerOrder.collection, makerOrder.tokenId, makerOrder.price);
                // Check if there is a royalty fee and that it is different to 0
                if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                    IERC20(makerOrder.currency).safeTransferFrom(from, royaltyFeeRecipient, royaltyFeeAmount);
                    finalSellerAmount -= royaltyFeeAmount;
                emit RoyaltyPayment(makerOrder.collection, makerOrder.tokenId, royaltyFeeRecipient, makerOrder.currency, royaltyFeeAmount);
                }
            }
        }
        
        require((finalSellerAmount * 10000) >= (makerOrder.minPercentageToAsk * makerOrder.price), "Fees: Higher than expected");

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(makerOrder.currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param makerOrder maker order
     * @param takerOrder taker order
     */
    function _transferFeesAndFundsWithWETH(
       OrderTypes.MakerOrder calldata makerOrder,
       OrderTypes.TakerOrder calldata takerOrder, 
       address to
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = makerOrder.price;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(makerOrder.strategy, makerOrder.price);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(WETH).safeTransfer(protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {  
            if(!isZeroBytes(takerOrder.dataCryptoAvatars)) { // Is CryptoAvatars, pay a fee to the avatar creator
                (address creator , uint256 royaltyFee) = abi.decode(takerOrder.dataCryptoAvatars, (address, uint256));
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyFee) / 10000 ;
                if ((creator != address(0)) && (royaltyCreatorFeeAmount != 0)) {
                    IERC20(WETH).safeTransfer(creator, royaltyCreatorFeeAmount);
                    finalSellerAmount -= royaltyCreatorFeeAmount;
                }
            }
            else if(!isZeroBytes(takerOrder.dataRemix)) { // Is Remix, pay a fee to the remix creator and to the collection owner
                (address creatorRemix, address ownerRemix) = abi.decode(takerOrder.dataRemix, (address, address));
                uint256 royaltyCreatorFee = royaltyFeeManager.getRemixCreatorRoyaltyFee();
                uint256 royaltyOwnerFee = royaltyFeeManager.getRemixOwnerRoyaltyFee();
                uint256 royaltyCreatorFeeAmount = (makerOrder.price * royaltyCreatorFee) / 10000 ;
                uint256 royaltyOwnerFeeAmount =  (makerOrder.price * royaltyOwnerFee) / 10000 ;
                IERC20(WETH).safeTransfer(creatorRemix, royaltyCreatorFeeAmount);
                IERC20(WETH).safeTransfer(ownerRemix, royaltyOwnerFeeAmount);
                finalSellerAmount -= royaltyCreatorFeeAmount + royaltyOwnerFeeAmount;
            }
            else { // It is a non CA collection, pay a fee to the collection owner
                (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
                    .calculateRoyaltyFeeAndGetRecipient(makerOrder.collection, makerOrder.tokenId, makerOrder.price);
                // Check if there is a royalty fee and that it is different to 0
                if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                    IERC20(WETH).safeTransfer(royaltyFeeRecipient, royaltyFeeAmount);
                    finalSellerAmount -= royaltyFeeAmount;
                emit RoyaltyPayment(makerOrder.collection, makerOrder.tokenId, royaltyFeeRecipient, WETH, royaltyFeeAmount);
                }
            }
        }

        require((finalSellerAmount * 10000) >= (makerOrder.minPercentageToAsk * makerOrder.price), "Fees: Higher than expected");

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(WETH).safeTransfer(to, finalSellerAmount);
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
        address transferManager = transferSelectorNFT.checkTransferManagerForToken(collection);

        // If no transfer manager found, it returns address(0)
        require(transferManager != address(0), "Transfer: No NFT transfer manager available");

        // If one is found, transfer the token
        ITransferManagerNFT(transferManager).transferNonFungibleToken(collection, from, to, tokenId, amount);
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
     * @notice Verify the validity of the maker order and the taker order
     * @param makerOrder maker order
     * @param takerOrder taker order
     */
    function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, 
                            OrderTypes.TakerOrder calldata takerOrder) internal view {
        // Verify whether order nonce has expired
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Order: Matching order expired"
        );

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: Amount cannot be 0");

        // Verify signature max valid time
        require(block.timestamp<=takerOrder.maxValidTime, "Order: Invalid signature");

        bytes32 makerOrderHash = makerOrder.hashMakerOrder();
        // Verify the validity of the signatures
        // Verify makerOrder signature
        require(
            SignatureChecker.verifySignature712(
                makerOrderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "MakerOrder Signature: Invalid"
        );
        bytes32 takerOrderHash = takerOrder.hashTakerOrder();
        // Verify takerOrder signature
        require(
            SignatureChecker.verifySignature191(
                takerOrderHash,
                signer,
                takerOrder.v,
                takerOrder.r,
                takerOrder.s
     ),
            "TakerOrder Signature: Invalid"
        );

        // Verify whether the currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: Not whitelisted");

        // Verify whether strategy can be executed
        require(executionManager.isStrategyWhitelisted(makerOrder.strategy), "Strategy: Not whitelisted");

        // Verify whether the collection is whitelisted
        require(collectionManager.isCollectionWhitelisted(makerOrder.collection),"Collection: Not whitelisted");
    }

    function isZeroBytes(bytes calldata data) public pure returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] != 0) {
                return false;
            }
        }
        return true;
    }
}