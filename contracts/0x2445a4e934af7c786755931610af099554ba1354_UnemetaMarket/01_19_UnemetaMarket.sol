// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TheCurrencyManager} from "./interface/TheCurrencyManager.sol";
import {TheExManager} from "./interface/TheExManager.sol";
import {TheExStrategy} from "./execution/interface/TheExecutionStrategy.sol";
import {TheRoyaltyManager} from "./interface/TheRoyaltyFeeManager.sol";
import {TheUnemetaExchange} from "./interface/TheUnemetaExchange.sol";
import {TheTransferManager} from "./interface/TheTransferManager.sol";
import {TheTransferSelector} from "./trans/interface/TheTransFerSelector.sol";
import {IWETH} from "./interface/IWETH.sol";

import {OrderTypes} from "../libraries/OrderTypes.sol";
import {SignatureChecker} from "../libraries/SignatureChecker.sol";


//UnemetaExchange
contract UnemetaMarket is TheUnemetaExchange, ReentrancyGuard, Ownable {
    // Load safe erc20
    using SafeERC20 for IERC20;
    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    //Cancel all orders
    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    // Cancel some orders
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    // New currency manager address
    event NewCurrencyManager(address indexed currencyManager);
    // New execution manager address
    event NewExecutionManager(address indexed executionManager);
    // new platform transaction fee receipient address
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    // New royalty fee receipient address
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    // New NFT transfer selector
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    // Defaulty wetg address
    address public immutable WETH;
    // Defualt eip712 domain hash
    address public protocolFeeRecipient;


    TheCurrencyManager public currencyManager;
    TheExManager public executionManager;
    TheRoyaltyManager public royaltyFeeManager;
    TheTransferSelector public transferSelectorNFT;


    // Users' minimal nonce map
    mapping(address => uint256) public userMinOrderNonce;
    // User proceeds to execution or cancellation
    mapping(address => mapping(uint256 => bool)) private _theUserOrderExecutedOrCancelled;

    /*Royalty fee payment structure*/
    event RoyaltyPayment(
        address indexed collection, //collection address
        uint256 indexed tokenId, //token id
        address indexed royaltyRecipient, //recipient wallet address
        address currency, //currency
        uint256 amount//amount
    );

    //Ask price structure
    event TakerAsk(
        bytes32 orderHash,
        uint256 orderNonce,
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    //Bid price structure
    event TakerBid(
        bytes32 orderHash,
        uint256 orderNonce,
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    //—————————————————————————————————constructor function—————————————————————————————————
    // Initialize contract using the input parameters
    // Including currency manager, execution manager, royalty manager, NFT transfer selector, weth address, platform transaction fee receipient
    constructor(
        address _currencyManager, //currency manager
        address _executionManager, //execution manager
        address _royaltyFeeManager, //royalty fee manager
        address _WETH, //WETH address
        address _protocolFeeRecipient// platform transaction fee recipient
    ) {
        currencyManager = TheCurrencyManager(_currencyManager);
        executionManager = TheExManager(_executionManager);
        royaltyFeeManager = TheRoyaltyManager(_royaltyFeeManager);
        WETH = _WETH;
        protocolFeeRecipient = _protocolFeeRecipient;
    }



    //
    // function matchSellerOrdersWETH
    //  @Description: Match seller order with weth and eth
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchSellerOrdersWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Error About Order Side");
        // Confirm using weth
        require(makerAsk.currency == WETH, "Currency must be WETH");
        require(msg.sender == takerBid.taker, "Order must be the sender");

        // if the balance of eth is low then use weth
        if (takerBid.price > msg.value) {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        } else {
            require(takerBid.price == msg.value, "Msg.value is too high");
        }

        //deposit weth
        IWETH(WETH).deposit{value : msg.value}();

        // Confirm users of offer and make
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        // Confirm execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerAsk.strategy)
        .canExecuteSell(takerBid, makerAsk);

        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // transfer fund
        _transferFeesAndFundsWithWETH(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // transfer nft
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount);

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

    //
    // function matchSellerOrders
    //  @Description: matchi seller order
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchSellerOrders(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
    external
    override
    nonReentrant
    {
        //Confirm the listing is valid and not a bid order
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Error About Order Side");
        // order must be from the bidder
        require(msg.sender == takerBid.taker, "Order must be the sender");

        //  validate signature
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        //
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerAsk.strategy)
        .canExecuteSell(takerBid, makerAsk);

        // Confirm valid execution
        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // transfer fund
        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        //transfer nft
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount);

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

    //
    // function matchesBuyerOrder
    //  @Description: match buyer order
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchesBuyerOrder(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
    external
    override
    nonReentrant
    {
        // validate paramenters of both sides
        // This step ensures matching seller order to buyer order
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Error About Order Side");
        // order must be from the seller
        require(msg.sender == takerAsk.taker, "Order must be the sender");

        // confirm bid is signed
        bytes32 bidHash = makerBid.hash();
        // confirm bid signature is valid
        _validateOrder(makerBid, bidHash);

        // confirm trading strategy can be effectively executed
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerBid.strategy)
        .canExecuteBuy(takerAsk, makerBid);

        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        // transfer nft
        _transferNonFungibleToken(
            makerBid.collection,
            msg.sender,
            makerBid.signer,
            tokenId,
            amount);

        // transfer fund
        _transferFeesAndFunds(
            makerBid.strategy,
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

    //
    // function cancelAllOrdersForSender
    //  @Description: 取消所有的order
    //  @param uint256
    //  @return external
    //
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel Order nonce cannot lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cannot cancel too many orders");
        // maintain a minimal nonce, to confirm the current order has reached the minimal nonce
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    //
    // function cancelMultipleMakerOrders
    //  @Description: cancel multiple orders
    //  @param uint256[] orderNonces
    //  @return external
    //
    function cancelMultipleMakerOrders(uint256[] calldata NonceList) external {
        require(NonceList.length > 0, "Cannot be empty Cancel list");

        for (uint256 i = 0; i < NonceList.length; i++) {
            require(NonceList[i] >= userMinOrderNonce[msg.sender], "Cancel Order nonce cannot lower than current");
            _theUserOrderExecutedOrCancelled[msg.sender][NonceList[i]] = true;
        }

        emit CancelMultipleOrders(msg.sender, NonceList);
    }
    //
    // function isUserOrderNonceExecutedOrCancelled
    //  @Description: Check if the current order is cancelled or was previously executed using map
    //  @param address  user address
    //  @param uint256  random number status of current order
    //  @return external
    //
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        //view viewing does not consume gas
        return _theUserOrderExecutedOrCancelled[user][orderNonce];
    }

    //
    // tion _transferFeesAndFunds
    //  @Description: using specific erc20 method to transfer fund(platform transaction fee or other fee)
    //  @param address  _strategy trading strategy address
    //  @param address  _collection nft contract address
    //  @param uint256  _tokenId nft if
    //  @param address  _currency erc20 contract address
    //  @param address  _seller seller address
    //  @param address  _buyer buyer address
    //  @param uint256  _price price
    //  @param uint256  _minPercentageToAsk minimal percentage accepted by the seller
    //  @return internal
    //
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
        // initialize final price
        uint256 finalSellerAmount = amount;

        //2，calculate platform transaction fee

        uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);
        // Confirm strategy is not null, platform transaction fee recipient is not null, platform transaction fee is not 0, before charging platform transaction fee
        // If current strategy is not null, but platform transaction fee is 0, then pass
        if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
            IERC20(currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
            finalSellerAmount -= protocolFeeAmount;
        }


        //3。 calculate royalty fee

        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
        .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        // Pass only when current royalty recipient exists and royalty fee is 0
        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            IERC20(currency).safeTransferFrom(from, royaltyFeeRecipient, royaltyFeeAmount);
            finalSellerAmount -= royaltyFeeAmount;

            emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipient, currency, royaltyFeeAmount);
        }

        // confirm the final amount is higher than the price set by user
        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "The fee is too high for the seller");

        //4  transfer final amount

        IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);

    }


    //
    // function _transferFeesAndFundsWithWETH
    //  @Description: use weth to transfer fee and fund, including different types of fee
    //  @param address execution strategy address
    //  @param address  collection address
    //  @param uint256  tokenId
    //  @param address  target wallet(seller)
    //  @param uint256  amount
    //  @param uint256  minimal percentage accepted by the seller
    //  @return internal
    //
    function _transferFeesAndFundsWithWETH(
        address strategy,
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        //1. initialize final amount
        uint256 finalSellerAmount = amount;


        //2，calculate platform transaction fee
        uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);

        // Confirm strategy is not null, platform transaction fee recipient is not null, platform transaction fee is not 0, before charging platform transaction fee
        // If current strategy is not null, but platform transaction fee is 0, then pass
        if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
            IERC20(WETH).safeTransfer(protocolFeeRecipient, protocolFeeAmount);
            finalSellerAmount -= protocolFeeAmount;
        }


        //3. calculate royalty fee
        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
        .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        // Pass only when current royalty recipient exists and royalty fee is 0
        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            IERC20(WETH).safeTransfer(royaltyFeeRecipient, royaltyFeeAmount);
            finalSellerAmount -= royaltyFeeAmount;

            emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipient, address(WETH), royaltyFeeAmount);
        }


        // confirm the final amount is higher than the price set by user
        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "The fee is too high for the seller");

        //4  transfer final amount
        IERC20(WETH).safeTransfer(to, finalSellerAmount);

    }


    //
    // function _transferNonFungibleToken
    //  @Description: transfer nft
    //  @param address  collection address
    //  @param address  source address
    //  @param address  target address
    //  @param uint256  tokenId
    //  @param uint256  amount
    //  @return internal
    //
    function _transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        //  check contract manager in initialization
        address Manager = transferSelectorNFT.checkTransferManagerForToken(collection);

        // ensure manager contract exists
        require(Manager != address(0), "Can't fount transfer manager");

        // If one is found, transfer the token
        TheTransferManager(Manager).transferNonFungibleToken(collection, from, to, tokenId, amount);
    }

    //
    // function _calculateProtocolFee
    //  @Description:  calculate platform transaction fee according to strategy
    //  @param address  execution stratgey address
    //  @param uint256  trading amount
    //  @return internal
    //
    function _calculateProtocolFee(address theStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = TheExStrategy(theStrategy).viewProtocolFee();
        return (protocolFee * amount) / 10000;
    }

    //
    // function _validateOrder
    //  @Description: validate using order infor
    //  @param OrderTypes.MakerOrder memory order order information
    //  @param bytes32 hash order hash
    //  @return internal
    //
    function _validateOrder(OrderTypes.MakerOrder calldata Make, bytes32 Hash) internal view {
        // Verify whether order nonce has expired
        require(
        // check if the order is cancelled or timeout
            (!_theUserOrderExecutedOrCancelled[Make.signer][Make.nonce]) &&
            (Make.nonce >= userMinOrderNonce[Make.signer]),
            "Order: Matching order expired"
        );

        //order signature cannot be null
        require(Make.signer != address(0), "The Order signer cannot be the zero address");

        //confirm if amount is larger than 0
        require(Make.amount > 0, "The order amount should be greater than 0");

        bytes32 Domain = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x2e3445393f211d11d7f88d325bc26ce78976b4decd39029feb202d9b409fc3c5,
            // keccak256("UnemetaMarket")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
            // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        //validate signature
        //because the eip712 signature stored in the server is used, must restore using teh same structure
        //ensures signature is valid
        require(
            SignatureChecker.
            verify(
                Hash, //hash
                Make.signer, // listing signer
                Make.v, //signature parameter, from eip712 standard
                Make.r,
                Make.s,
                Domain
            ),
            "Signature: Invalid"
        );

        // confirm currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(Make.currency), " Not in Currency whitelist");

        // confirm trading strategy is whitelisted and can execute correctly
        require(executionManager.isStrategyWhitelisted(Make.strategy), " Not in Strategy whitelist");
    }



    //
    // function updateCurrencyManager
    //  @Description: Update a currency manager
    //  @param address
    //  @return external
    //
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Cannot update to a null address");
        currencyManager = TheCurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    //
    // function updateExecutionManager
    //  @Description: Update an execution manager
    //  @param address
    //  @return external
    //
    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Cannot update to a null address");
        executionManager = TheExManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    //
    // function updateProtocolFeeRecipient
    //  @Description: Update platform transaction fee recipient
    //  @param address
    //  @return external
    //
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    //
    // function updateRoyaltyFeeManager
    //  @Description: update royalty fee manager
    //  @param address
    //  @return external
    //
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Cannot update to a null address");
        royaltyFeeManager = TheRoyaltyManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    //
    // function updateTransferSelectorNFT
    //  @Description: update transfer manager
    //  @param address
    //  @return external
    //
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Cannot update to a null address");
        transferSelectorNFT = TheTransferSelector(_transferSelectorNFT);
        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

}