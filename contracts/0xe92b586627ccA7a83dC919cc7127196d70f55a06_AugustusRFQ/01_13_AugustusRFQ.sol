pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./IERC20Permit.sol";


contract AugustusRFQ is EIP712("AUGUSTUS RFQ", "1") {
    using SafeERC20 for IERC20;

    struct Order {
        uint256 nonceAndMeta; // Nonce and taker specific metadata
        uint128 expiry;
        address makerAsset;
        address takerAsset;
        address maker;
        address taker;  // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    
    // makerAsset and takerAsset are Packed structures 
    // 0 - 159 bits are address
    // 160 - 161 bits are tokenType (0 ERC20, 1 ERC1155, 2 ERC721)
    struct OrderNFT {
        uint256 nonceAndMeta; // Nonce and taker specific metadata
        uint128 expiry;
        uint256 makerAsset; 
        uint256 makerAssetId; // simply ignored in case of ERC20s
        uint256 takerAsset;
        uint256 takerAssetId; // simply ignored in case of ERC20s
        address maker;
        address taker;  // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    struct OrderInfo {
        Order order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    struct OrderNFTInfo {
        OrderNFT order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }


    uint256 constant public FILLED_ORDER = 1;
    uint256 constant public UNFILLED_ORDER = 0;

    // Keeps track of remaining amounts of each Order
    // 0 -> order unfilled / not exists
    // 1 -> order filled / cancelled 
    mapping(address => mapping (bytes32 => uint256)) public remaining;

    bytes32 constant public RFQ_LIMIT_ORDER_TYPEHASH = keccak256(
        "Order(uint256 nonceAndMeta,uint128 expiry,address makerAsset,address takerAsset,address maker,address taker,uint256 makerAmount,uint256 takerAmount)"
    );

    bytes32 constant public RFQ_LIMIT_NFT_ORDER_TYPEHASH = keccak256(
        "OrderNFT(uint256 nonceAndMeta,uint128 expiry,uint256 makerAsset,uint256 makerAssetId,uint256 takerAsset,uint256 takerAssetId,address maker,address taker,uint256 makerAmount,uint256 takerAmount)"
    );

    event OrderCancelled(bytes32 indexed orderHash, address indexed maker);
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed maker,
        address makerAsset,
        uint256 makerAmount,
        address indexed taker,
        address takerAsset,
        uint256 takerAmount
    );
    event OrderFilledNFT(
        bytes32 indexed orderHash,
        address indexed maker,
        uint256 makerAsset,
        uint256 makerAssetId,
        uint256 makerAmount,
        address indexed taker,
        uint256 takerAsset,
        uint256 takerAssetId,
        uint256 takerAmount
    );

    function getRemainingOrderBalance(address maker, bytes32[] calldata orderHashes) external view returns(uint256[] memory remainingBalances) {
        remainingBalances = new uint256[](orderHashes.length);
        mapping (bytes32 => uint256) storage remainingMaker = remaining[maker]; 
        for (uint i = 0; i < orderHashes.length; i++) {
            remainingBalances[i] = remainingMaker[orderHashes[i]];
        }
    }

    /**
    * @notice Cancel one or more orders using orderHashes
    * @dev Cancelled orderHashes are marked as used
    * @dev Emits a Cancel event
    * @dev Out of gas may occur in arrays of length > 400
    * @param orderHashes bytes32[] List of order hashes to cancel
    */
    function cancelOrders(bytes32[] calldata orderHashes) external {
        for (uint256 i = 0; i < orderHashes.length; i++) {
            cancelOrder(orderHashes[i]);
        }
    }

    function cancelOrder(bytes32 orderHash) public {
        if (_cancelOrder(msg.sender, orderHash)) {
            emit OrderCancelled(orderHash, msg.sender);
        }
    }

    /**  
     @dev Allows taker to partially fill an order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    )
        external
        returns(uint256 makerTokenFilledAmount)
    {

        return partialFillOrderWithTarget(
            order,
            signature,
            takerTokenFillAmount,
            msg.sender
        );
        
    }

    /**  
     @dev Allows taker to partially fill an NFT order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    )
        external
        returns(uint256 makerTokenFilledAmount)
    {

        return partialFillOrderWithTargetNFT(
            order,
            signature,
            takerTokenFillAmount,
            msg.sender
        );
        
    }

    /**  
     @dev Same as `partialFillOrder` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    )
        public
        returns(uint256 makerTokenFilledAmount)
    {
        require(takerTokenFillAmount > 0 && takerTokenFillAmount <= order.takerAmount, "Invalid Taker amount");
        makerTokenFilledAmount = (takerTokenFillAmount * order.makerAmount) / order.takerAmount;     
        require(makerTokenFilledAmount > 0, "Maker token fill amount cannot be 0");
        _fillOrder(
            order,
            signature,
            makerTokenFilledAmount,
            takerTokenFillAmount,
            target
        );

        return makerTokenFilledAmount;
    }

    /**  
     @dev Same as `partialFillOrderWithTarget` but it allows to pass permit 
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    )
        public
        returns(uint256 makerTokenFilledAmount)
    {
        require(takerTokenFillAmount > 0 && takerTokenFillAmount <= order.takerAmount, "Invalid Taker amount");
        makerTokenFilledAmount = (takerTokenFillAmount * order.makerAmount) / order.takerAmount;     
        require(makerTokenFilledAmount > 0, "Maker token fill amount cannot be 0");
        
        _permit(order.takerAsset, permitTakerAsset);
        _permit(order.makerAsset, permitMakerAsset);
        _fillOrder(
            order,
            signature,
            makerTokenFilledAmount,
            takerTokenFillAmount,
            target
        );

        return makerTokenFilledAmount;
        
    }

    /**  
     @dev Same as `partialFillOrderNFT` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    )
        public
        returns(uint256 makerTokenFilledAmount)
    {
        require(takerTokenFillAmount > 0 && takerTokenFillAmount <= order.takerAmount, "Invalid Taker amount");
        makerTokenFilledAmount = (takerTokenFillAmount * order.makerAmount) / order.takerAmount;     
        require(makerTokenFilledAmount > 0, "Maker token fill amount cannot be 0");
        _fillOrderNFT(
            order,
            signature,
            makerTokenFilledAmount,
            takerTokenFillAmount,
            target
        );

        return makerTokenFilledAmount;
    }

    /**  
     @dev Same as `partialFillOrderWithTargetNFT` but it allows to pass token permits
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermitNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    )
        public
        returns(uint256 makerTokenFilledAmount)
    {
        require(takerTokenFillAmount > 0 && takerTokenFillAmount <= order.takerAmount, "Invalid Taker amount");
        makerTokenFilledAmount = (takerTokenFillAmount * order.makerAmount) / order.takerAmount;     
        require(makerTokenFilledAmount > 0, "Maker token fill amount cannot be 0");
        
        _permit(address(uint160(order.takerAsset)), permitTakerAsset);
        _permit(address(uint160(order.makerAsset)), permitMakerAsset);
        _fillOrderNFT(
            order,
            signature,
            makerTokenFilledAmount,
            takerTokenFillAmount,
            target
        );

        return makerTokenFilledAmount;
    }

    /**  
     @dev Allows taker to fill complete RFQ order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrder(
        Order calldata order,
        bytes calldata signature
    )
        external
    {
        fillOrderWithTarget(
            order,
            signature,
            msg.sender
        );
    }

    /**  
     @dev Allows taker to fill Limit order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature
    )
        external
    {
        fillOrderWithTargetNFT(
            order,
            signature,
            msg.sender
        );
    }

    /**  
     @dev Same as fillOrder but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        address target
    )
        public
    {
        uint256 makerTokenFillAmount = order.makerAmount;
        uint256 takerTokenFillAmount = order.takerAmount;

        require(takerTokenFillAmount > 0 && makerTokenFillAmount > 0, "Invalid amount");

        _fillOrder(
            order,
            signature,
            makerTokenFillAmount,
            takerTokenFillAmount,
            target
        );
    }

    /**  
     @dev Same as fillOrderNFT but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        address target
    )
        public
    {
        uint256 makerTokenFillAmount = order.makerAmount;
        uint256 takerTokenFillAmount = order.takerAmount;

        require(takerTokenFillAmount > 0 && makerTokenFillAmount > 0, "Invalid amount");

        _fillOrderNFT(
            order,
            signature,
            makerTokenFillAmount,
            takerTokenFillAmount,
            target
        );
    }

    /**  
     @dev Partial fill multiple orders
     @param orderInfos OrderInfo to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTarget(
        OrderInfo[] calldata orderInfos,
        address target
    )
        public
    {
        for (uint256 i = 0; i < orderInfos.length; i++) {
            OrderInfo calldata orderInfo = orderInfos[i];

            uint256 takerTokenFillAmountOrder = orderInfo.takerTokenFillAmount;
            require(takerTokenFillAmountOrder > 0 && takerTokenFillAmountOrder <= orderInfo.order.takerAmount, "Invalid Taker amount");
            
            uint256 makerTokenFillAmountOrder = (takerTokenFillAmountOrder * orderInfo.order.makerAmount) / orderInfo.order.takerAmount;     
            require(makerTokenFillAmountOrder > 0, "Maker token fill amount cannot be 0");

            _permit(orderInfo.order.takerAsset, orderInfo.permitTakerAsset);
            _permit(orderInfo.order.makerAsset, orderInfo.permitMakerAsset);

            _fillOrder(
                orderInfo.order,
                orderInfo.signature,
                makerTokenFillAmountOrder,
                takerTokenFillAmountOrder,
                target
            );
        }
    }

    /**  
     @dev batch fills orders until the takerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param takerFillAmount total taker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    )
        public
    {
        for (uint256 i = 0; i < orderInfos.length; i++) {
            OrderInfo calldata orderInfo = orderInfos[i];
            uint256 takerFillAmountOrder = takerFillAmount > orderInfo.takerTokenFillAmount ? orderInfo.takerTokenFillAmount : takerFillAmount;

            (bool success,) = address(this).delegatecall(
                abi.encodeWithSelector(
                    this.partialFillOrderWithTargetPermit.selector,
                    orderInfo.order,
                    orderInfo.signature,
                    takerFillAmountOrder,
                    target,
                    orderInfo.permitTakerAsset,
                    orderInfo.permitMakerAsset
                )
            );

            if(success)
                takerFillAmount -= takerFillAmountOrder;
            
            if (takerFillAmount == 0)
                break;
        }
        require(takerFillAmount == 0, "Couldn't swap the requested fill amount");
    }

    /**  
     @dev batch fills orders until the makerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param makerFillAmount total maker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    )
        public
    {
        for (uint256 i = 0; i < orderInfos.length; i++) {
            OrderInfo calldata orderInfo = orderInfos[i];
            uint256 orderMakerAmount = orderInfo.order.makerAmount;
            uint256 orderTakerAmount = orderInfo.order.takerAmount;
            uint256 maxMakerFillAmount = (orderInfo.takerTokenFillAmount * orderMakerAmount) / orderTakerAmount; 
            uint256 makerFillAmountOrder = makerFillAmount > maxMakerFillAmount ? maxMakerFillAmount : makerFillAmount;
            uint256 takerFillAmountOrder = ((makerFillAmountOrder * orderTakerAmount) + (orderMakerAmount - 1)) / orderMakerAmount; 

            (bool success,) = address(this).delegatecall(
                abi.encodeWithSelector(
                    this.partialFillOrderWithTargetPermit.selector,
                    orderInfo.order,
                    orderInfo.signature,
                    takerFillAmountOrder,
                    target,
                    orderInfo.permitTakerAsset,
                    orderInfo.permitMakerAsset
                )
            );
            
            if(success)
                makerFillAmount -= makerFillAmountOrder;
            
            if (makerFillAmount == 0)
                break;
        }
        require(makerFillAmount == 0, "Couldn't swap the requested fill amount");
    }

    /**  
     @dev Partial fill multiple NFT orders
     @param orderInfos Info about each order to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTargetNFT(
        OrderNFTInfo[] calldata orderInfos,
        address target
    )
        public
    {
        for (uint256 i = 0; i < orderInfos.length; i++) {
            OrderNFTInfo calldata orderInfo = orderInfos[i];

            uint256 takerTokenFillAmountOrder = orderInfo.takerTokenFillAmount;
            require(takerTokenFillAmountOrder > 0 && takerTokenFillAmountOrder <= orderInfo.order.takerAmount, "Invalid Taker amount");
            
            uint256 makerTokenFillAmountOrder = (takerTokenFillAmountOrder * orderInfo.order.makerAmount) / orderInfo.order.takerAmount;     
            require(makerTokenFillAmountOrder > 0, "Maker token fill amount cannot be 0");

            _permit(address(uint160(orderInfo.order.takerAsset)), orderInfo.permitTakerAsset);
            _permit(address(uint160(orderInfo.order.makerAsset)), orderInfo.permitMakerAsset);

            _fillOrderNFT(
                orderInfo.order,
                orderInfo.signature,
                makerTokenFillAmountOrder,
                takerTokenFillAmountOrder,
                target
            );
        }
    }



    function _fillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 makerTokenFillAmount,
        uint256 takerTokenFillAmount,
        address target
    )
        private
    {
        address maker = order.maker;
        bytes32 orderHash = _hashTypedDataV4(keccak256(abi.encode(RFQ_LIMIT_ORDER_TYPEHASH, order)));
        _checkOrder(maker, order.taker, orderHash, order.makerAmount, makerTokenFillAmount, order.expiry, signature);

        //Transfer tokens between maker and taker :)
        transferTokens(order.makerAsset, maker, target, makerTokenFillAmount);
        transferTokens(order.takerAsset, msg.sender, maker, takerTokenFillAmount);

        emit OrderFilled(
            orderHash,
            maker,
            order.makerAsset,
            makerTokenFillAmount,
            target,
            order.takerAsset,
            takerTokenFillAmount
        );
    }

    function _fillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 makerTokenFillAmount,
        uint256 takerTokenFillAmount,
        address target
    )
        private
    {
        address maker = order.maker;
        bytes32 orderHash = _hashTypedDataV4(keccak256(abi.encode(RFQ_LIMIT_NFT_ORDER_TYPEHASH, order)));
        _checkOrder(maker, order.taker, orderHash, order.makerAmount, makerTokenFillAmount, order.expiry, signature);

        //Transfer tokens between maker and taker :)
        transferTokensNFT(order.makerAsset, maker, target, makerTokenFillAmount, order.makerAssetId);
        transferTokensNFT(order.takerAsset, msg.sender, maker, takerTokenFillAmount, order.takerAssetId);

        emit OrderFilledNFT(
            orderHash,
            maker,
            order.makerAsset,
            order.makerAssetId,
            makerTokenFillAmount,
            target,
            order.takerAsset,
            order.takerAssetId,
            takerTokenFillAmount
        );
    }


    /**
    * @notice The function assumes orderAmount >= fillRequest, fillRequest > 0
    * and the orderHash is computed correctly 
    * @param maker address Address of the maker
    * @param taker address Address of the taker
    * @param orderHash bytes32 Hash of order
    * @param orderAmount uint256 Max amount the order can fill
    * @param fillRequest uint256 Amount requested for fill
    * @param signature bytes32 Signature for the orderhash
    */
    function _checkOrder(
        address maker,
        address taker,
        bytes32 orderHash,
        uint256 orderAmount,
        uint256 fillRequest,
        uint128 expiry,
        bytes calldata signature
    )
        internal
    {
        // Check time expiration
        require(expiry == 0 || block.timestamp <= expiry, "Order expired");

        // Check if the taker of the order is correct
        require(taker == address(0) || taker == msg.sender, "Access denied");

        mapping (bytes32 => uint256) storage remainingMaker = remaining[maker];
        
        uint256 remainingAmount = remainingMaker[orderHash];
        // You only need to check the signature of the order for the first time
        // For later you already know the orderHash coresponds to the signed order
        if(remainingAmount == UNFILLED_ORDER) {
            require(SignatureChecker.isValidSignatureNow(maker, orderHash, signature), "Invalid Signature");
            remainingMaker[orderHash] = (orderAmount - fillRequest) + 1;
        } else {
            require(remainingAmount > fillRequest, "Order already filled or expired");
            remainingMaker[orderHash] = remainingAmount - fillRequest;
        }
    }



    /**
    * @notice Set remaining[maker][orderHash] = FILLED_ORDER to cancel the order
    * @param maker address Address of the maker for which to cancel the order
    * @param orderHash bytes32 orderHash to be marked as used
    * @return bool True if the orderHash was not marked as used already
    */
    function _cancelOrder(
        address maker,
        bytes32 orderHash
    )
        internal
        returns (bool)
    {
        mapping (bytes32 => uint256) storage remainingMaker = remaining[maker];

        if(remainingMaker[orderHash] == FILLED_ORDER) {
            return false;
        }

        remainingMaker[orderHash] = FILLED_ORDER;
        return true;
    }

    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    )
        private
    {
        IERC20(token).safeTransferFrom(
            from, to, amount
        );
    }

    function transferTokensNFT(
        uint256 token,
        address from,
        address to,
        uint256 amount,
        uint256 id
    )
        private
    {
        uint256 tokenType = token >> 160;
        if (tokenType == 0) {
            IERC20(address(uint160(token))).safeTransferFrom(
                from, to, amount
            );
        } else if (tokenType == 1) {
            IERC1155(address(uint160(token))).safeTransferFrom(
                from, to, id, amount, bytes("")
            );   
        } else if (tokenType == 2) {
            require(amount == 1, "Invalid amount for ERC721 transfer");
            IERC721(address(uint160(token))).safeTransferFrom(
                from, to, id
            );
        } else {
            revert("Invalid token type");
        }
    }

    function _permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }
}