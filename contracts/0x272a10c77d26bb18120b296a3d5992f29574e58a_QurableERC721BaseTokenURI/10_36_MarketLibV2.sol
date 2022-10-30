//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../tokenInterfaces/IERC20WithExecuteMetaTransaction.sol";
import "./DecimalLib.sol";
import "hardhat/console.sol";

library MarketLibV2 {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 internal constant MAX_ALLOWED_MINTING_COUNT = 1e7;
    uint256 internal constant MAX_ALLOWED_MINTING_COUNT_LOW_COLLECTIONS = 1e6;
    uint256 internal constant MAX_ALLOWED_MINTING_INTX = 1e3;

    bytes32 internal constant OPERATION_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "TransferOperation(uint256 nonce,uint256 deadline,bytes data)"
            )
        );
    bytes32 internal constant SELLORDER_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "SellOrder(uint256 amount,address paymentTokenAddress,string orderId,address from,address tokenContractAddress,uint256 tokenId,string tokenURI,address artistAddress,bytes sellShares)"
            )
        );

    struct PaymentInfo {
        bool payWithToken;
        uint256 amount;
        address tokenAddress;
        address userAddress;
        bool executeTokenApprovalWithMetaTransaction;
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    struct MintOrder {
        string orderId;
        address recipient;
        string tokenUniqueKey;
        address tokenContractAddress;
        uint256 collectionId;
        string tokenURI;
        address artistAddress;
        SellShares sellShares;
        PaymentInfo paymentInfo;
        bytes transferOperatorSignature;
    }

    struct TransferOrder {
        string orderId;
        address from;
        address recipient;
        address tokenContractAddress;
        uint256 tokenId;
        address artistAddress;
        SellShares sellShares;
        PaymentInfo paymentInfo;
        bytes transferOperatorSignature;
    }

    struct LazyMintingInfo {
        address recipient;
        uint256 collectionId;
        uint256 tokenId;
    }

    struct SellShares {
        DecimalLib.D256 artist;
        DecimalLib.D256 qurable;
        DecimalLib.D256 seller;
    }

    function getOperationHash(
        uint256 nonce,
        uint256 deadline,
        bytes memory data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OPERATION_TRANSACTION_TYPEHASH,
                    nonce,
                    deadline,
                    data
                )
            );
    }

    function getSellOrderHash(
        uint256 amount,
        address paymentTokenAddress,
        string memory orderId,
        address from,
        address tokenContractAddress,
        uint256 tokenId,
        string memory tokenURI,
        address artistAddress,
        SellShares memory sellShares
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SELLORDER_TRANSACTION_TYPEHASH,
                    amount,
                    paymentTokenAddress,
                    orderId,
                    from,
                    tokenContractAddress,
                    tokenId,
                    tokenURI,
                    artistAddress,
                    sellShares
                )
            );
    }

    function isValidSellShares(SellShares memory sellShares, uint256 sellValue)
        internal
        pure
        returns (bool)
    {
        return
            sellValue == 0 ||
            (sellValue > 0 &&
                sellShares.artist.value.add(sellShares.qurable.value).add(
                    sellShares.seller.value
                ) ==
                uint256(100).mul(DecimalLib.BASE));
    }

    function transferSellSharesWithPaymentInfo(
        address spender,
        PaymentInfo memory paymentInfo,
        SellShares memory sellShares,
        address payable qurableAddress,
        address payable artistAddress,
        address payable sellerAddress
    ) internal {
        (
            uint256 artistShare,
            uint256 qurableShare,
            uint256 sellerShare
        ) = splitSellSharesFromAmount(sellShares, paymentInfo.amount);

        if (paymentInfo.payWithToken) {
            IERC20WithExecuteMetaTransaction token = IERC20WithExecuteMetaTransaction(
                    paymentInfo.tokenAddress
                );

            require(
                token.balanceOf(paymentInfo.userAddress) >= paymentInfo.amount,
                "NotEnoughBalanceToPay"
            );

            // Execute approve of allowance (allowances should be at least enough to sell value + fees)
            if (
                token.allowance(paymentInfo.userAddress, spender) <
                paymentInfo.amount &&
                paymentInfo.executeTokenApprovalWithMetaTransaction
            ) {
                token.executeMetaTransaction(
                    paymentInfo.userAddress,
                    paymentInfo.functionSignature,
                    paymentInfo.sigR,
                    paymentInfo.sigS,
                    paymentInfo.sigV
                );
            }

            require(
                token.allowance(paymentInfo.userAddress, spender) >=
                    paymentInfo.amount,
                "NotEnoughAllowance"
            );

            require(
                token.transferFrom(
                    paymentInfo.userAddress,
                    artistAddress,
                    artistShare
                ),
                "ErrorTransferToArtists"
            );
            require(
                token.transferFrom(
                    paymentInfo.userAddress,
                    qurableAddress,
                    qurableShare
                ),
                "ErrorTransferToQurable"
            );
            require(
                token.transferFrom(
                    paymentInfo.userAddress,
                    sellerAddress,
                    sellerShare
                ),
                "ErrorTransferToSeller"
            );
        } else {
            require(msg.value >= paymentInfo.amount, "NotEnoughEthersToPay");

            AddressUpgradeable.sendValue(artistAddress, artistShare);
            AddressUpgradeable.sendValue(qurableAddress, qurableShare);
            AddressUpgradeable.sendValue(sellerAddress, sellerShare);
        }
    }

    /**
     * @notice return a % of the specified amount. This function is used to split a bid into shares
     * for a media's shareholders.
     */
    function splitShare(DecimalLib.D256 memory sharePercentage, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return DecimalLib.mul(amount, sharePercentage).div(100);
    }

    function splitSellSharesFromAmount(
        SellShares memory sellShares,
        uint256 amount
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 artistShare = splitShare(sellShares.artist, amount);
        uint256 qurableShare = splitShare(sellShares.qurable, amount);
        uint256 sellerShare = splitShare(sellShares.seller, amount);

        return (artistShare, qurableShare, sellerShare);
    }
}