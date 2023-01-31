// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../../utils/EIP712.sol";
import "./ITradeSignaturesVerifier.sol";

contract TradeSignaturesVerifier is EIP712, ITradeSignaturesVerifier {
    bytes32 private constant PLATFORM_FEES_TYPE_HASH =
        keccak256("PlatformFees(address assetAddress,uint256 tokenId,uint8 buyerFeePermille,uint8 sellerFeePermille)");

    bytes32 private constant SELL_ORDER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "SellOrder(address assetAddress,uint256 tokenId,address paymentAssetAddress,uint256 unitPrice,uint8 sellerFeePermille)"
        );

    bytes32 private constant WITHDRAW_VOUCHER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "WithdrawVoucher(address assetOwner,uint256 nonce,address assetAddress,uint8 assetType,uint256 tokenId,uint256 quantity)"
        );

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param platformFees Struct that has information about platform fees
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifyPlatformFeesSignature(PlatformFees calldata platformFees, address authorizer)
        internal
        view
        virtual
        override
    {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PLATFORM_FEES_TYPE_HASH,
                        platformFees.assetAddress,
                        platformFees.tokenId,
                        platformFees.buyerFeePermille,
                        platformFees.sellerFeePermille
                    )
                )
            );

        address signer = ECDSAUpgradeable.recover(digest, platformFees.signature);
        require(authorizer == signer, "fees sign verification failed");
    }

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param seller address of the seller, should be the current owner of the token
     * @param tokenId id of the tokens to be sold
     * @param unitPrice price per token unit
     * @param paymentAssetAddress address of the ERC20 that is used to pay, ZERO_ADDRESS is used when
     * paying with ethers
     * @param assetAddress address of the NFT's contract
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     * check that the platform does not unilaterally change the fee)
     * @param signature bytes that represent the signature
     */
    function verifySellerSignature(
        address seller,
        uint256 tokenId,
        uint256 unitPrice,
        address paymentAssetAddress,
        address assetAddress,
        uint8 sellerFeePermille,
        bytes memory signature
    ) internal view virtual override {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SELL_ORDER_TYPE_HASH,
                        assetAddress,
                        tokenId,
                        paymentAssetAddress,
                        unitPrice,
                        sellerFeePermille
                    )
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(seller == signer, "seller sign verification failed");
    }

    /**
     * @notice Verifies the custodial authorization for this withdraw for this assetOwner
     * @param assetCustodial current asset holder
     * @param assetOwner real asset owner address
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature bytes that represent the signature
     */
    function verifyWithdrawSignature(
        address assetCustodial,
        address assetOwner,
        WithdrawRequest memory wr,
        bytes memory signature
    ) internal view virtual override {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        WITHDRAW_VOUCHER_TYPE_HASH,
                        assetOwner,
                        wr.nonce,
                        wr.assetAddress,
                        wr.assetType,
                        wr.tokenId,
                        wr.quantity
                    )
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(assetCustodial == signer, "withdraw sign verification failed");
    }
}