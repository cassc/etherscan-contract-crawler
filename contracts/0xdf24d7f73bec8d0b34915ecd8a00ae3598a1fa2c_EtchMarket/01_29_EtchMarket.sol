// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./interfaces/ICurrencyManager.sol";
import "./interfaces/IEtchMarket.sol";
import "./libraries/OrderTypes.sol";
import "./libraries/SignatureChecker.sol";

/**
 * @title EtchMarket
 * @notice It is the core contract of the etch.market ethscription exchange.
 */
contract EtchMarket is
    IEtchMarket,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using OrderTypes for OrderTypes.EthscriptionOrder;

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    bytes32 internal constant WITHDRAW_ETHSCRIPTION_HASH =
        keccak256("WithdrawEthscription(bytes32 ethscriptionId,address recipient,uint64 expiration)");

    ICurrencyManager public currencyManager;
    uint16 public creatorFeeBps;
    uint16 public protocolFeeBps;
    address public protocolFeeRecipient;
    address private trustedVerifier;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;
    mapping(address => mapping(bytes32 => uint256)) private _ethscriptionDepositedOnBlockNumber;

    uint256 internal constant TRANSFER_BLOCK_CONFIRMATIONS = 5;

    function initialize() public initializer {
        __EIP712_init("EtchMarket", "1");
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    fallback(bytes calldata data) external whenNotPaused returns (bytes memory) {
        if (data.length != 32) revert EthscriptionInvalid();

        bytes32 ethscriptionId = abi.decode(data, (bytes32));
        _ethscriptionDepositedOnBlockNumber[msg.sender][ethscriptionId] = block.number;
        emit EthscriptionDeposited(msg.sender, ethscriptionId, uint64(block.timestamp));
        return data;
    }

    function executeEthscriptionOrder(
        OrderTypes.EthscriptionOrder calldata order,
        bytes calldata trustedSign
    ) public payable override nonReentrant whenNotPaused {
        // Check the maker ask order
        bytes32 orderHash = _verifyOrderHash(order, trustedSign);

        // Execute the transaction
        _executeOrder(order, orderHash);

        // Refund dust token to sender
        _returnDust();
    }

    /**
     * @notice Cancel all pending orders for a sender
     */
    function cancelAllOrders() public override {
        userMinOrderNonce[msg.sender] = block.timestamp;
        emit CancelAllOrders(msg.sender, block.timestamp, uint64(block.timestamp));
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) public override {
        if (orderNonces.length == 0) {
            revert EmptyOrderCancelList();
        }
        for (uint256 i = 0; i < orderNonces.length; i++) {
            if (orderNonces[i] < userMinOrderNonce[msg.sender]) {
                revert OrderNonceTooLow();
            }
            _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }
        emit CancelMultipleOrders(msg.sender, orderNonces, uint64(block.timestamp));
    }

    function withdrawEthscription(
        bytes32 ethscriptionId,
        uint64 expiration,
        bytes calldata trustedSign
    ) public override nonReentrant whenNotPaused {
        if (expiration < block.timestamp) {
            revert ExpiredSignature();
        }
        if (
            _ethscriptionDepositedOnBlockNumber[msg.sender][ethscriptionId] + TRANSFER_BLOCK_CONFIRMATIONS >
            block.number
        ) {
            revert InsufficientConfirmations();
        }

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(trustedSign);
        bytes32 digest = keccak256(abi.encode(WITHDRAW_ETHSCRIPTION_HASH, ethscriptionId, msg.sender, expiration));
        (bool isValid, ) = SignatureChecker.verify(digest, trustedVerifier, v, r, s, _domainSeparatorV4());
        if (!isValid) {
            revert TrustedSignatureInvalid();
        }
        emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(msg.sender, msg.sender, ethscriptionId);
        emit EthscriptionWithdrawn(msg.sender, ethscriptionId, uint64(block.timestamp));
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    function updateCreatorFeeBps(uint16 _creatorFeeBps) external onlyOwner {
        creatorFeeBps = _creatorFeeBps;
        emit NewCreatorFeeBps(_creatorFeeBps);
    }

    function updateProtocolFeeBps(uint16 _protocolFeeBps) external onlyOwner {
        protocolFeeBps = _protocolFeeBps;
        emit NewProtocolFeeBps(_protocolFeeBps);
    }

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    function updateTrustedVerifier(address _trustedVerifier) external onlyOwner {
        trustedVerifier = _trustedVerifier;
        emit NewTrustedVerifier(_trustedVerifier);
    }

    function pause() public onlyOwner {
        PausableUpgradeable._pause();
    }

    function unpause() public onlyOwner {
        PausableUpgradeable._unpause();
    }

    function _executeOrder(OrderTypes.EthscriptionOrder calldata order, bytes32 orderHash) internal {
        // Verify whether the currency is allowed for trading.
        address currency = order.currency;
        if (!currencyManager.isCurrencyWhitelisted(currency)) {
            revert CurrencyInvalid();
        }
        if (currency == address(0) && order.price != msg.value) {
            revert MsgValueInvalid();
        }

        // Verify whether order has expired
        if ((order.startTime > block.timestamp) || (order.endTime < block.timestamp)) {
            revert OrderExpired();
        }

        // Verify whether order nonce has expired
        address signer = order.signer;
        if (_isUserOrderNonceExecutedOrCancelled[signer][order.nonce] || (order.nonce < userMinOrderNonce[signer])) {
            revert NoncesInvalid();
        }

        // Update order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[signer][order.nonce] = true;

        // Pay fees
        _transferFees(order);

        emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(signer, msg.sender, order.ethscriptionId);

        emit EthscriptionOrderExecuted(
            orderHash,
            order.nonce,
            order.ethscriptionId,
            order.quantity,
            order.signer,
            msg.sender,
            order.currency,
            order.price,
            uint64(block.timestamp)
        );
    }

    function _transferFees(OrderTypes.EthscriptionOrder calldata order) internal {
        uint256 finalSellerAmount = order.price;

        // Pay protocol fee
        uint256 protocolFeeAmount = _calculateProtocolFee(order.protocolFeeDiscounted, order.price);
        if (protocolFeeRecipient != address(0) && protocolFeeAmount != 0) {
            // Transfer remaining protocol fee to the protocol fee recipient
            _transferFungibleTokens(order.currency, msg.sender, protocolFeeRecipient, protocolFeeAmount);
            finalSellerAmount -= protocolFeeAmount;
        }

        // Pay creator fee
        // If the creator recipient is address(0), the fee is set to 0
        uint256 creatorFeeAmount = _calculateCreatorFee(order.creatorFee, order.price);
        if (order.creator != address(0) && creatorFeeAmount != 0) {
            _transferFungibleTokens(order.currency, msg.sender, order.creator, creatorFeeAmount);
            finalSellerAmount -= creatorFeeAmount;
        }

        _transferFungibleTokens(order.currency, msg.sender, order.signer, finalSellerAmount);
    }

    /**
     * @notice This function is internal and is used to transfer fungible tokens.
     * @param currency Currency address
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Amount (in fungible tokens)
     */
    function _transferFungibleTokens(address currency, address sender, address recipient, uint256 amount) internal {
        if (currency == address(0)) {
            _transferETHWithGasLimit(recipient, amount, _GAS_STIPEND_NO_STORAGE_WRITES);
        } else {
            IERC20Upgradeable(currency).safeTransferFrom(sender, recipient, amount);
        }
    }

    /**
     * @notice Calculate protocol fee
     * @param amount amount to transfer
     */
    function _calculateProtocolFee(uint16 feeDiscount, uint256 amount) internal view returns (uint256) {
        if (feeDiscount > 0) {
            return (feeDiscount * amount) / 10000;
        } else {
            return (protocolFeeBps * amount) / 10000;
        }
    }

    /**
     * @notice Calculate creator fee
     * @param amount amount to transfer
     */
    function _calculateCreatorFee(uint16 dynamicCreatorFee, uint256 amount) internal view returns (uint256) {
        if (dynamicCreatorFee > 0) {
            return (dynamicCreatorFee * amount) / 10000;
        } else {
            return (creatorFeeBps * amount) / 10000;
        }
    }

    /**
     * @notice It transfers ETH to a recipient with a specified gas limit.
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param gasLimit Gas limit to perform the ETH transfer
     */
    function _transferETHWithGasLimit(address to, uint256 amount, uint256 gasLimit) internal {
        bool success;
        assembly {
            success := call(gasLimit, to, amount, 0, 0, 0, 0)
        }
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @notice Verify the validity of the ethscription order
     * @param order maker ethscription order
     * @param trustedSign trusted signature for the ethscription order
     */
    function _verifyOrderHash(
        OrderTypes.EthscriptionOrder calldata order,
        bytes calldata trustedSign
    ) internal view returns (bytes32) {
        // Verify the signer is not address(0)
        if (order.signer == address(0)) {
            revert SignerInvalid();
        }
        bytes32 orderHash = order.hash();

        // Verify the validity of the signature
        (bool isValid, bytes32 digest) = SignatureChecker.verify(
            orderHash,
            order.signer,
            order.v,
            order.r,
            order.s,
            _domainSeparatorV4()
        );
        if (!isValid) {
            revert SignatureInvalid();
        }

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(trustedSign);
        // Verify the validity of the trusted signature
        (bool isValidTrusted, ) = SignatureChecker.verify(orderHash, trustedVerifier, v, r, s, _domainSeparatorV4());
        if (!isValidTrusted) {
            revert TrustedSignatureInvalid();
        }
        return digest;
    }

    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature.length != 65) {
            revert SignatureInvalid();
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    function _returnDust() internal {
        // return remaining native token (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function withdrawUnexpectedERC20(address token, address to, uint256 amount) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
}