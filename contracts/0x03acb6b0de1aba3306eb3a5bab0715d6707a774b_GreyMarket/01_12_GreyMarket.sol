// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./GreyMarketStorage.sol";
import "./GreyMarketEvent.sol";
import "./GreyMarketData.sol";

/// @dev Error thrown when the signature is invalid.
error InvalidSignature(bytes32 orderId, Sig sig);

/** 
 * @title gm.co
 * @custom:version 1.1
 * @author projectPXN
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarket is Ownable, GreyMarketStorage, GreyMarketEvent, EIP712, ReentrancyGuard {
    constructor(address _proofSigner) EIP712("GreyMarket Contract", "1.1.0") {
        require(_proofSigner != address(0), "invalid token or signer address");
        proofSigner = _proofSigner;
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
        uint8 orderType, 
        uint256 amount, 
        Sig calldata sig
    ) external payable {
        if(!validateCreateOrder(sig, id, msg.sender, seller, paymentToken, orderType, amount))
            revert InvalidSignature(id, sig);
        if (paymentToken == address(0))
            require(msg.value >= amount, "insufficient eth sent");

        if(paymentToken != address(0))
            IERC20(paymentToken).transferFrom(msg.sender, address(this), amount);

        emit OrderCreated(
            id, 
            paymentToken,
            amount
        );
    }

    /**
     * @notice Claim the order fund by seller after order is delivered and confirmed.
     * @dev Claim the order fund with order information.
     * @param id Order id
     * @param seller Address of the seller
     * @param amount Amount of funds to claim
     * @param paymentToken Token used to claim funds
     * @param orderType Type of the order
     * @param sig ECDSA signature
     */
    function claimOrder(
        bytes32 id,
        address seller,
        uint256 amount,
        uint8 orderType,
        address paymentToken,
        Sig calldata sig
    ) public nonReentrant {
        if(orders[id] || !validateClaimOrder(sig, id, seller, amount, paymentToken, orderType))
            revert InvalidSignature(id, sig);
        orders[id] = true;
        if (paymentToken == address(0))
            payable(seller).transfer(amount);
        else
            IERC20(paymentToken).transfer(seller, amount);
        emit OrderCompleted(id);
    }


    /**
     * @notice Claim multiple orders.
     * @dev Claim multiple orders.
     * @param orders Order details
     * @param sigs Array of ECDSA signatures
     */
    function claimOrders(
        Order[] calldata orders,
        Sig[] calldata sigs
    ) external {
        require(sigs.length == orders.length, "invalid length");
        uint256 len = orders.length;
        uint256 i;
        unchecked {
            do {
               claimOrder(orders[i].id,orders[i].seller,orders[i].amount, orders[i].orderType, orders[i].paymentToken,sigs[i]);
            } while(++i < len);
        }
    }
    
    /**
     * @notice Withdraw funds for a buyer after an order is cancelled
     * @dev Withdraw the order fund with order data
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param paymentToken Address of the payment token used for the order
     * @param amount Amount of funds to withdraw
     * @param sig ECDSA signature
     */
    function withdrawOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken,
        uint256 amount,
        Sig calldata sig
    ) external nonReentrant {
        if(orders[id] ||!validateWithdrawOrder(sig, id, buyer, seller, paymentToken, amount))
            revert InvalidSignature(id, sig);
        orders[id] = true;

        if (paymentToken == address(0))
            payable(buyer).transfer(amount);
        else
            IERC20(paymentToken).transfer(buyer, amount);

        emit OrderCancelled(id);
    }


    /**
     * @notice Sets the proof signer address.
     * @dev Admin function to set the proof signer address.
     * @param newProofSigner The new proof signer.
     */
    function setProofSigner(address newProofSigner) external onlyOwner {
        require(newProofSigner != address(0), "invalid proof signer");
        proofSigner = newProofSigner;
        emit NewProofSigner(proofSigner);
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
        uint8 orderType, 
        uint256 amount
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                CREATE_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                paymentToken,
                orderType,
                amount
        )));

        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a claim order signature
     * @dev Validates the signature of a claim order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param seller Seller address
     * @param amount Amount of funds to claim
     * @param paymentToken Payment token address
     * @param orderType Order type
     * @return bool Whether the signature is valid or not
     */
    function validateClaimOrder(
        Sig calldata sig,
        bytes32 id, 
        address seller, 
        uint256 amount,
        address paymentToken,
        uint8 orderType
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                CLAIM_ORDER_TYPEHASH,
                id,
                seller,
                amount,
                paymentToken,
                orderType
        )));
        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a withdraw order signature
     * @dev Validates the signature of a withdraw order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param paymentToken Token used to pay
     * @return bool Whether the signature is valid or not
     */
    function validateWithdrawOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken,
        uint256 amount
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                WITHDRAW_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                paymentToken,
                amount
        )));
        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Expose typed v4 hash function
     */
    function hash(bytes32 _hash) public view returns (bytes32) {
        return _hashTypedDataV4(_hash);
    }

    /**
     * @notice Withdraw the admin fee.
     * @dev Admin function to withdraw the admin fee.
     * @param recipient The address that will receive the fees.
     * @param token The token address to withdraw, NULL for ETH, token address for ERC20.
     * @param amount The amount to withdraw.
     */
    function withdrawAdminFee(address recipient, address token, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid recipient address");
        if (token == address(0))
            payable(recipient).transfer(amount);
        else
            IERC20(token).transfer(recipient, amount);
        emit WithdrawAdminFee(token, amount);
    }
}