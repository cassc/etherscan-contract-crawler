// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OrderTypes.sol";

interface IEtchMarket {
    error CurrencyInvalid();
    error MsgValueInvalid();
    error NoncesInvalid();
    error OrderExpired();
    error SignerInvalid();
    error SignatureInvalid();
    error TrustedSignatureInvalid();
    error ETHTransferFailed();
    error EmptyOrderCancelList();
    error OrderNonceTooLow();
    error EthscriptionInvalid();
    error ExpiredSignature();
    error InsufficientConfirmations();

    event CancelAllOrders(address user, uint256 newMinNonce, uint64 timestamp);
    event CancelMultipleOrders(address user, uint256[] orderNonces, uint64 timestamp);
    event NewCurrencyManager(address indexed currencyManager);
    event NewCreatorFeeBps(uint96 creatorFeeBps);
    event NewProtocolFeeBps(uint96 protocolFeeBps);
    event NewProtocolFeeRecipient(address protocolFeeRecipient);
    event NewTrustedVerifier(address trustedVerifier);
    event EthscriptionOrderExecuted(
        bytes32 indexed orderHash,
        uint256 orderNonce,
        bytes32 ethscriptionId,
        uint256 quantity,
        address seller,
        address buyer,
        address currency,
        uint256 price,
        uint64 endTime
    );
    event EthscriptionDeposited(address indexed owner, bytes32 indexed ethscriptionId, uint64 timestamp);
    event EthscriptionWithdrawn(address indexed owner, bytes32 indexed ethscriptionId, uint64 timestamp);
    event ethscriptions_protocol_TransferEthscriptionForPreviousOwner(
        address indexed previousOwner,
        address indexed recipient,
        bytes32 indexed id
    );

    function executeEthscriptionOrder(
        OrderTypes.EthscriptionOrder calldata order,
        bytes calldata trustedSign
    ) external payable;

    function cancelAllOrders() external;

    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external;

    function withdrawEthscription(bytes32 ethscriptionId, uint64 expiration, bytes calldata trustedSign) external;
}