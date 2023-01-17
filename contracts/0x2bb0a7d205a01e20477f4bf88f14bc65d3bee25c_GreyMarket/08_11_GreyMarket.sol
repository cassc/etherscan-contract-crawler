// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GreyMarketStorage.sol";
import "./GreyMarketEvent.sol";
import "./GreyMarketData.sol";

/**
 * @title GreyMarket
 * @custom:version 0.1
 * @author @bldr
 * @notice The Grey Market is a Peer-To-Peer (P2P) marketplace platform designed to utilise
 *         blockchain technology for proof of transactions and allow users to trade items
 *         (physical/digital assets) using cryptocurrencies.
 */
contract GreyMarket is Ownable, ReentrancyGuard, GreyMarketStorage, GreyMarketEvent {
    using SafeERC20 for IERC20;

    string public constant CONTRACT_NAME = "GreyMarket Contract";
    
    bytes32 public constant DOMAIN_TYPEHASH = 
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    
    bytes32 public constant CREATE_ORDER_TYPEHASH = 
        keccak256(
            "Create(bytes32 id,address buyer,address seller,address paymentToken,uint256 orderType,uint256 amount)"
        );

    bytes32 public constant CLAIM_ORDER_TYPEHASH = 
        keccak256(
            "Claim(bytes32 id,address buyer,address seller,uint256 orderStatus)"
        );
    
    bytes32 public constant WITHDRAW_ORDER_TYPEHASH = 
        keccak256(
            "Withdraw(bytes32 id,address buyer,address seller,uint256 orderStatus)"
        );

    bytes32 public constant RELEASE_DISPUTED_ORDER_TYPEHASH = 
        keccak256(
            "Release(bytes32 id,address buyer,address seller,uint256 orderStatus,address winner)"
        );

    bytes32 public domainSeperator = 
        keccak256(
            abi.encode(
                DOMAIN_TYPEHASH, 
                keccak256(bytes(CONTRACT_NAME)), 
                getChainId(), 
                address(this)
            )
        );
    
    constructor(address _proofSigner, address _usdc) {
        require(_usdc != address(0) && _proofSigner != address(0), "invalid token or signer address");

        proofSigner = _proofSigner;
        paymentTokens[_usdc] = true;
    }

    /**
     * @notice Create the order.
     * @dev Create the order with order information.
     * @param id Order id
     * @param seller Address of the seller
     * @param paymentToken Address of the payment token used for the order
     * @param orderType Type of the order
     * @param amount Payment amount
     * @param sig ECDSA signature
     */
    function createOrder(
        bytes32 id, 
        address seller, 
        address paymentToken,
        OrderType orderType, 
        uint256 amount, 
        Sig calldata sig
    ) external payable {
        require(validateCreateOrder(sig, id, msg.sender, seller, paymentToken, uint256(orderType), amount), "createOrder: invalid signature");
        require(paymentToken == address(0) || paymentTokens[paymentToken], "createOrder: invalid payment token");
        require(orderType < OrderType.COUNT, "createOrder: invalid order type");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_NONE, "createOrder: invalid status");

        orderInfo.id = id;
        orderInfo.createdAt = uint128(block.timestamp);
        orderInfo.buyer = msg.sender;
        orderInfo.orderType = orderType;
        orderInfo.seller = seller;
        orderInfo.status = OrderStatus.ORDER_CREATED;

        if (paymentToken == address(0)) {
            orderInfo.amount = msg.value;
            orderInfo.paymentType = PaymentType.PAYMENT_ETH;
        } else {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
            orderInfo.amount = amount;
            orderInfo.paymentType = PaymentType.PAYMENT_ERC20;
        }

        orderInfo.paymentToken = paymentToken;
        emit OrderCreated(id, orderInfo.buyer, seller, uint8(orderInfo.paymentType), uint8(orderType), orderInfo.createdAt, orderInfo.amount);
    }

    /**
     * @notice Claim the order fund by seller after order is delivered and confirmed.
     * @dev Claim the order fund with order information.
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param sig ECDSA signature
     */
    function claimOrder(
        bytes32 id,
        address buyer,
        address seller,
        Sig calldata sig
    ) public {
        require(validateClaimOrder(sig, id, buyer, seller, uint256(OrderStatus.ORDER_DELIVERED)), "claimOrder: invalid signature");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "claimOrder: invalid status");
        require(orderInfo.seller == msg.sender && orderInfo.seller == seller, "claimOrder: invalid seller");
        require(orderInfo.buyer == buyer, "claimOrder: invalid buyer info");
        require(orderInfo.orderType < OrderType.COUNT, "claimOrder: invalid order type");

        uint256 fee = orderInfo.amount * transactionFee / 100000;

        if(orderInfo.orderType == OrderType.ESCROW) {
            uint256 escrowFee = orderInfo.amount * defaultEscrowFee / 100000;
            fee += escrowFee * 10 / 100;
            escrowFees[orderInfo.seller] = escrowFees[orderInfo.seller] + escrowFee * 90 / 100;
        }

        adminFees[orderInfo.paymentToken] = adminFees[orderInfo.paymentToken] + fee;
        orderInfo.status = OrderStatus.ORDER_COMPLETED;

        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(orderInfo.seller).transfer(orderInfo.amount - fee);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.seller, orderInfo.amount - fee);

        orderInfo.completedAt = uint128(block.timestamp);
        emit OrderCompleted(id, orderInfo.buyer, orderInfo.seller, orderInfo.completedAt);
    }

    /**
     * @notice Claim multiple orders.
     * @dev Claim multiple orders.
     * @param ids Order ids
     * @param buyers The addresses of the buyers
     * @param sellers The addresses of the sellers
     * @param sigs Array of ECDSA signatures
     */
    function claimOrders(
        bytes32[] calldata ids,
        address[] calldata buyers,
        address[] calldata sellers,
        Sig[] calldata sigs
    ) external {
        require(sigs.length == ids.length, "invalid length");
        require(sellers.length == buyers.length, "invalid length");

        uint256 len = ids.length;
        uint256 i;

        unchecked {
            do {
               claimOrder(ids[i], buyers[i], sellers[i], sigs[i]);
            } while(++i < len);
        }
    }

    /**
     * @notice Withdraw funds for a buyer after an order is cancelled
     * @dev Withdraw the order fund with order data
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param sig ECDSA signature
     */
    function withdrawOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        Sig calldata sig
    ) external {
        require(validateWithdrawOrder(sig, id, buyer, seller, uint256(OrderStatus.ORDER_CANCELLED)), "withdrawOrder: invalid signature");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "withdrawOrder: invalid status");
        require(orderInfo.buyer == msg.sender && orderInfo.buyer == buyer, "withdrawOrder: invalid buyer");
        require(orderInfo.seller == seller, "withdrawOrder: invalid seller info");

        orderInfo.status = OrderStatus.ORDER_CANCELLED;

        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(orderInfo.buyer).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.buyer, orderInfo.amount);

        uint256 remainingEscrowFees = escrowFees[orderInfo.seller];
        if(remainingEscrowFees > 0) {
            escrowFees[orderInfo.seller] = 0;
            if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
                payable(orderInfo.seller).transfer(remainingEscrowFees);
            else
                IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.seller, remainingEscrowFees);
        }
            
        orderInfo.cancelledAt = uint128(block.timestamp);
        emit OrderCancelled(id, orderInfo.buyer, orderInfo.seller, orderInfo.cancelledAt);
    }

    /**
     * @notice Release the disputed fund by buyer or seller as admin indicated.
     * @dev Release the disputed fund by buyer or seller as admin indicated.
     * @param id Order id.
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param winner Address of the winner
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     */
    function releaseDisputedOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        address winner, 
        Sig[] calldata sigs
    ) external {
        require(validateReleaseDisputedOrder(sigs, id, buyer, seller, uint256(OrderStatus.ORDER_DISPUTE), winner), "releaseDisputedOrder: invalid signature");
        require(buyer == winner || seller == winner, "releaseDisputedOrder: invalid winner");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "releaseDisputedOrder: invalid status");
        require(winner == msg.sender && orderInfo.buyer == buyer &&  orderInfo.seller == seller, "releaseDisputedOrder: invalid info");

        orderInfo.status = OrderStatus.ORDER_DISPUTE_HANDLED;
        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(winner).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(winner, orderInfo.amount);

        orderInfo.disputedAt = uint128(block.timestamp);
        emit OrderDisputeHandled(id, orderInfo.buyer, orderInfo.seller, winner, orderInfo.disputedAt);
    }

    /**
     * @notice Sets the proof signer address.
     * @dev Admin function to set the proof signer address.
     * @param newProofSigner The new proof signer.
     */
    function _setProofSigner(address newProofSigner) external onlyOwner {
        require(newProofSigner != address(0), "invalid proof signer");
        proofSigner = newProofSigner;
        emit NewProofSigner(proofSigner);
    }

    /**
     * @notice Add new market admin.
     * @dev Admin function to add new market admin.
     * @param newAdmins The new admin.
     */
    function _setNewAdmins(address[] calldata newAdmins) external onlyOwner {
        require(newAdmins.length > 0, "invalid admins length");
        admins = newAdmins;
        emit NewAdmins(admins);
    }

    /**
     * @notice Add new payment token
     * @dev Admin function to add new payment token
     * @param paymentToken Supported payment token
     * @param add Add or remove admin.
     */
    function _addOrRemovePaymentToken(address paymentToken, bool add) external onlyOwner {
        require(paymentToken != address(0), "invalid payment token");
        paymentTokens[paymentToken] = add;
    }

    /**
     * @notice Sets the transaction fee 
     * @dev Admin function to set the transaction fee
     * @param newFee escrow fee recipient.
     */
     function _setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "invalid fee range");
        transactionFee = newFee;
        emit NewTransactionFee(newFee);
     }

    /**
     * @notice Sets the escrow fee.
     * @dev Admin function to set the escrow fee.
     * @param newEscrowFee The new escrow fee, scaled by 1e18.
     */
    function _setEscrowFee(uint256 newEscrowFee) external onlyOwner {
        require(newEscrowFee <= MAX_ESCROW_FEE, "invalid fee range");
        defaultEscrowFee = newEscrowFee;
        emit NewEscrowFee(newEscrowFee);
    }

    /**
     * @notice Sets the escrow pending period.
     * @dev Admin function to set the escrow pending period.
     * @param newEscrowPendingPeriod The new escrow pending period in timestamp
     */
    function _setEscrowPendingPeriod(uint256 newEscrowPendingPeriod) external onlyOwner {
        require(newEscrowPendingPeriod <= MAX_ESCROW_PENDING_PERIOD, "pending period must not exceed maximum period");
        require(newEscrowPendingPeriod >= MIN_ESCROW_PENDING_PERIOD, "pending period must exceed minimum period");
        escrowPendingPeriod = newEscrowPendingPeriod;
        emit NewEscrowPendingPeriod(escrowPendingPeriod);
    }

    /**
     * @notice Sets the escrow lock period.
     * @dev Admin function to set the escrow lock period.
     * @param newEscrowLockPeriod The new escrow lock period in timestamp
     */
    function _setEscrowLockPeriod(uint256 newEscrowLockPeriod) external onlyOwner {
        require(newEscrowLockPeriod <= MAX_ESCROW_LOCK_PERIOD, "lock period must not exceed maximum period");
        require(newEscrowLockPeriod >= MIN_ESCROW_LOCK_PERIOD, "lock period must exceed minimum period");
        escrowLockPeriod = newEscrowLockPeriod;
        emit NewEscrowLockPeriod(escrowLockPeriod);
    }

    /**
     * @notice Withdraw the admin fee.
     * @dev Admin function to withdraw the admin fee.
     * @param recipient The address that will receive the fees.
     * @param token The token address to withdraw, NULL for ETH, token address for ERC20.
     * @param amount The amount to withdraw.
     */
    function _withdrawAdminFee(address recipient, address token, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid recipient address");
        require(adminFees[token] >= amount, "invalid token address or amount");

        if (token == address(0))
            payable(recipient).transfer(amount);
        else
            IERC20(token).safeTransfer(recipient, amount);

        adminFees[token] = adminFees[token] - amount;
        emit WithdrawAdminFee(msg.sender, recipient, token, amount);
    }

    /**
     * @notice Withdraw the unclaimed fund for lock period.
     * @dev Admin function to withdraw the unclaimed fund for lock period.
     * @param id The order id.
     * @param recipient The address that will receive the fees.
     */
    function _withdrawLockedFund(bytes32 id, address recipient) external onlyOwner {
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "invalid order status");
        require(recipient != address(0), "invalid recipient address");
        require(orderInfo.createdAt + escrowLockPeriod >= block.timestamp, "can not withdraw before lock period");
        
        if (orderInfo.paymentToken == address(0))
            payable(recipient).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(recipient, orderInfo.amount);

        orderInfo.status = OrderStatus.ORDER_ADMIN_WITHDRAWN;
        emit WithdrawLockedFund(msg.sender, id, recipient, orderInfo.amount);
    }

    /**
     * @notice Retrieve the chain ID the contract is deployed to
     * @dev Retrieve the chain ID from the EVM
     * @return chainId chain ID
     */
    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @notice Validates a create order signature
     * @dev Validates the signature of a create order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param paymentToken Payment token address
     * @param orderType Order type
     * @param amount Order amount
     * @return bool Whether the signature is valid or not
     */
    function validateCreateOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken, 
        uint256 orderType, 
        uint256 amount
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        CREATE_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        paymentToken,
                        orderType,
                        amount
                    )
                )
            )
        );

        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a claim order signature
     * @dev Validates the signature of a claim order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @return bool Whether the signature is valid or not
     */
    function validateClaimOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        uint256 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        CLAIM_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus
                    )
                )
            )
        );
        
        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a withdraw order signature
     * @dev Validates the signature of a withdraw order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @return bool Whether the signature is valid or not
     */
    function validateWithdrawOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        uint256 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        WITHDRAW_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus
                    )
                )
            )
        );

        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a release disputed order signature
     * @dev Validates the signature of a release disputed order action by verifying the signature
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @param winner Winner address
     * @return bool Whether the signature is valid or not
     */
    function validateReleaseDisputedOrder(
        Sig[] calldata sigs,
        bytes32 id,
        address buyer,
        address seller,
        uint256 orderStatus,
        address winner
    ) internal view returns(bool) {
        require(sigs.length == REQUIRED_SIGNATURE_COUNT, "invalid signature required count");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        RELEASE_DISPUTED_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus,
                        winner
                    )
                )
            )
        );
        
        address signerOne = ecrecover(digest, sigs[0].v, sigs[0].r, sigs[0].s);
        address signerTwo = ecrecover(digest, sigs[1].v, sigs[1].r, sigs[1].s);
        require(signerOne != signerTwo, "same signature");

        uint256 validSignatureCount;
        for(uint256 i; i < admins.length; i++) {
            if(signerOne == admins[i] || signerTwo == admins[i]) {
                validSignatureCount++;
            }
        }

        return validSignatureCount == REQUIRED_SIGNATURE_COUNT;
    }

    /**
     * @notice View function to get order info by ID
     * @dev Retrieves the order struct by ID
     * @param orderId Order ID
     * @return OrderInfo Order struct
     */
    function getOrderInfo(bytes32 orderId) public view returns (OrderInfo memory) {
        return orders[orderId];
    }
    
    /**
     * @notice View function to get the amount of admin fees by a specific token
     * @dev Retrieves the amount of admin fees by a specific token address, either ETH or ERC20
     * @param token Token address
     * @return uint256 Amount of fees in wei
     */
    function getAdminFeeAmount(address token) public view returns (uint256) {
        return adminFees[token];
    }

    /**
     * @dev Internal pure function to retrieve the name of this contract as a
     *      string that will be used to derive the name hash in the constructor.
     * @return The name of this contract as a string.
     */
    function _nameString() public pure returns (string memory) {
        return "GreyMarket";
    }

    /**
     * @notice UUID V4 to bytes32 representation in Solidity
     * @param s UUID V4 string
     */
    function UUIDStringToBytes32(string memory s) public pure returns (bytes32) {
        bytes memory bytesArray = bytes(s);
        bytes memory noDashes = new bytes(32);
        uint index;
        for (uint256 i; i < bytesArray.length; i++) {
            if (bytesArray[i] == "-") {
                continue;
            }
            noDashes[index] = bytesArray[i];
            index++;
        }
        bytes32 result;
        assembly {
            result := mload(add(noDashes, 32))
        }
        return result;
    }
}