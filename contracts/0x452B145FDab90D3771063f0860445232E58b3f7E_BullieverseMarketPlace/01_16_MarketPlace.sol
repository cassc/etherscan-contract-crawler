//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IPaymentERC20Registry.sol";
import "./interfaces/ICancellationRegistry.sol";

/* This contains all data of the BuyOrder */
struct BuyOrder {
    /* Seller of the NFT */
    address payable seller;
    /* Contract address of NFT */
    address contractAddress;
    /* Token id of NFT to sell */
    uint256 tokenId;
    /* Start time in unix timestamp */
    uint256 startTime;
    /* Expiration in unix timestamp */
    uint256 expiration;
    /* Price in wei */
    uint256 price;
    /* Number of tokens to transfer; should be 1 for ERC721 */
    uint256 quantity;
    /* BlockNumber where message is signed */
    uint256 createdAtBlockNumber;
    /* Address of the ERC20 token for the payment. Will be the zero-address for payments in native ETH. */
    address paymentERC20;
}

contract BullieverseMarketPlace is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd; // The ERC-165 identifier for 721
    bytes4 private constant InterfaceId_ERC1155 = 0xd9b67a26; // The ERC-165 identifier for 1155

    IPaymentERC20Registry paymentERC20Registry;
    ICancellationRegistry cancellationRegistry;

    address payable _makerWallet;

    address payable _platformWallet;

    uint256 public platformPercentageFee;

    uint256 public createrPercentageFee;

    bytes32 private constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                keccak256(bytes("Bullieverse")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    event BuyOrderFilled(
        address indexed seller,
        address buyer,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 createdAtBlockNumber,
        uint256 startTime,
        uint256 expiration
    );

    event CancelListing(
        address indexed owner,
        address contractAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 createdAtBlockNumber,
        uint256 startTime,
        uint256 expiration
    );

    event CancelAllPreviousListing(
        address indexed owner,
        address indexed contractAddress,
        uint256 tokenId
    );

    function pauseContract() external onlyOwner {
        super._pause();
    }

    function unPauseContract() external onlyOwner {
        super._unpause();
    }

    // Check if order is already expired
    modifier _isOrderAvailable(uint256 startTime, uint256 expiration) {
        require(block.timestamp < expiration, "Order is Expired");
        require(block.timestamp > startTime, "Order is Yet To Start");
        _;
    }

    /*
     * @dev Sets the registry contracts for the exchange.
     */
    function setRegistryContracts(
        address _cancellationRegistry,
        address _paymentERC20Registry
    ) external onlyOwner {
        cancellationRegistry = ICancellationRegistry(_cancellationRegistry);
        paymentERC20Registry = IPaymentERC20Registry(_paymentERC20Registry);
    }

    /********************
     * Public Functions *
     ********************/

    /*
     * @dev External trade function. This accepts the details of the sell order and signed sell
     * order (the signature) as a meta-transaction.
     *
     * Emits a {BuyOrderFilled} event via `_fillBuyOrder`.
     */
    function fillOrder(
        address payable seller,
        address contractAddress,
        uint256 tokenId,
        uint256 startTime,
        uint256 expiration,
        uint256 price,
        uint256 quantity,
        uint256 createdAtBlockNumber,
        address paymentERC20,
        bytes memory signature
    )
        external
        payable
        whenNotPaused
        nonReentrant
        _isOrderAvailable(startTime, expiration)
    {
        // If the payment ERC20 is the zero address, we check that enough native ETH has been sent
        // with the transaction. Otherwise, we use the supplied ERC20 payment token.
        if (paymentERC20 == address(0)) {
            require(
                msg.value >= price,
                "Transaction doesn't have the required ETH amount."
            );
        } else {
            _checkValidERC20Payment(msg.sender, price, paymentERC20);
        }

        BuyOrder memory buyOrder = BuyOrder(
            seller,
            contractAddress,
            tokenId,
            startTime,
            expiration,
            price,
            quantity,
            createdAtBlockNumber,
            paymentERC20
        );

        /* Check signature */
        require(
            _validateSellerSignature(buyOrder, signature),
            "Signature is not valid for BuyOrder."
        );
        require(
            cancellationRegistry.getSellOrderCancellationBlockNumber(
                seller,
                contractAddress,
                tokenId
            ) < createdAtBlockNumber,
            "This order has been cancelled."
        );

        _fillBuyOrder(buyOrder, signature);
    }

    /*
     * @dev Validate the sell order against the signature of the meta-transaction.
     */
    function _validateSellerSignature(
        BuyOrder memory buyOrder,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 BUYORDER_TYPEHASH = keccak256(
            "BuyOrder(address seller,address contractAddress,uint256 tokenId,uint256 startTime,uint256 expiration,uint256 price,uint256 quantity,uint256 createdAtBlockNumber,address paymentERC20)"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                BUYORDER_TYPEHASH,
                buyOrder.seller,
                buyOrder.contractAddress,
                buyOrder.tokenId,
                buyOrder.startTime,
                buyOrder.expiration,
                buyOrder.price,
                buyOrder.quantity,
                buyOrder.createdAtBlockNumber,
                buyOrder.paymentERC20
            )
        );

        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        address recoveredAddress = ECDSA.recover(digest, signature);
        return recoveredAddress == buyOrder.seller;
    }

    /*
     * @dev Sets the wallet for the exchange.
     */
    function setMakerWallet(address payable _newMakerWallet)
        external
        onlyOwner
    {
        _makerWallet = _newMakerWallet;
    }

    /*
     * @dev Sets the wallet for the platform.
     */
    function setPlatFormWallet(address payable _newPlatformWallet)
        external
        onlyOwner
    {
        _platformWallet = _newPlatformWallet;
    }

    /*
     * @dev Sets the percentage for the platform.
     */
    function setPlatFormPercentage(uint256 _newPlatformPercentage)
        external
        onlyOwner
    {
        platformPercentageFee = _newPlatformPercentage;
    }

    /*
     * @dev Sets the percentage for the creater.
     */
    function setCreaterPercentage(uint256 _newCreaterPercentage)
        external
        onlyOwner
    {
        createrPercentageFee = _newCreaterPercentage;
    }

    function _fillBuyOrder(BuyOrder memory buyOrder, bytes memory signature)
        internal
    {
        /////////////////
        ///  Finalize ///
        /////////////////

        emit BuyOrderFilled(
            buyOrder.seller,
            msg.sender,
            buyOrder.contractAddress,
            buyOrder.tokenId,
            buyOrder.price,
            buyOrder.createdAtBlockNumber,
            buyOrder.startTime,
            buyOrder.expiration
        );

        /////////////////
        ///  Transfer ///
        /////////////////
        _transferNFT(
            buyOrder.contractAddress,
            buyOrder.tokenId,
            buyOrder.seller,
            msg.sender,
            buyOrder.quantity,
            signature
        );

        //////////////////////
        ///  Send Payment ///
        /////////////////////
        if (buyOrder.price > 0) {
            _paySellerAndRoyalties(
                buyOrder.seller,
                msg.sender,
                buyOrder.price,
                buyOrder.paymentERC20
            );
        }
    }

    function _paySellerAndRoyalties(
        address seller,
        address buyer,
        uint256 price,
        address paymentERC20
    ) internal {
        uint256 createrFee = (price * createrPercentageFee) / 10000;
        uint256 platformFee = (price * platformPercentageFee) / 10000;

        if (paymentERC20 == address(0)) {
            if (platformFee > 0) {
                (bool platformFeePaid, ) = _platformWallet.call{
                    value: platformFee
                }("");
                require(platformFeePaid, "Payment Failed For Platform Wallet");
            }
            if (createrFee > 0) {
                (bool isMakerPaid, ) = _makerWallet.call{value: createrFee}("");

                require(isMakerPaid, "Payment Failed for Maker Wallet");
            }

            (bool isSellerPaid, ) = _makerWallet.call{
                value: price - platformFee - createrFee
            }("");
            require(isSellerPaid, "Payment Failed for Seller");
        } else {
            if (platformFee > 0) {
                IERC20(paymentERC20).safeTransferFrom(
                    buyer,
                    _platformWallet,
                    platformFee
                );
            }

            if (createrFee > 0) {
                IERC20(paymentERC20).safeTransferFrom(
                    buyer,
                    _makerWallet,
                    createrFee
                );
            }

            IERC20(paymentERC20).safeTransferFrom(
                buyer,
                seller,
                price - createrFee - platformFee
            );
        }
    }

    function _transferNFT(
        address contractAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 quantity,
        bytes memory signature
    ) internal {
        if (contractAddress.supportsInterface(InterfaceId_ERC721)) {
            /* Make sure the order is not cancelled */

            cancellationRegistry.cancelPreviousSellOrders(
                seller,
                contractAddress,
                tokenId
            );

            IERC721 erc721 = IERC721(contractAddress);

            /* require is approved for all */
            require(
                erc721.isApprovedForAll(seller, address(this)),
                "The Exchange is not approved to operate this NFT"
            );

            /////////////////
            ///  Transfer ///
            /////////////////
            erc721.safeTransferFrom(seller, buyer, tokenId);
        } else if (contractAddress.supportsInterface(InterfaceId_ERC1155)) {
            IERC1155 erc1155 = IERC1155(contractAddress);

            require(
                !cancellationRegistry.isOrderCancelled(signature),
                "This order has been cancelled"
            );

            cancellationRegistry.cancelOrder(signature);

            /////////////////
            ///  Transfer ///
            /////////////////
            erc1155.safeTransferFrom(seller, buyer, tokenId, quantity, "");
        } else {
            revert(
                "We don't recognize the NFT as either an ERC721 or ERC1155."
            );
        }
    }

    /* Checks that the payment is being made with an approved ERC20, and that we are allowed to operate
     * a sufficient amount of it. */
    function _checkValidERC20Payment(
        address buyer,
        uint256 price,
        address paymentERC20
    ) internal view {
        // Checks that the ERC20 payment token is approved in the registry.
        require(
            paymentERC20Registry.isApprovedERC20(paymentERC20),
            "Payment ERC20 is not approved."
        );

        // Checks that the buyer has sufficient funds.
        require(
            IERC20(paymentERC20).balanceOf(buyer) >= price,
            "Buyer has an insufficient balance of the ERC20."
        );

        // Checks that the Exchange contract has a sufficient allowance of the token.
        require(
            IERC20(paymentERC20).allowance(buyer, address(this)) >= price,
            "Exchange is not approved to handle a sufficient amount of the ERC20."
        );
    }

    // Cancel All Previous Listing
    function cancelAllPreviousListing(address contractAddress, uint256 tokenId)
        external
    {
        cancellationRegistry.cancelPreviousSellOrders(
            msg.sender,
            contractAddress,
            tokenId
        );

        emit CancelAllPreviousListing(msg.sender, contractAddress, tokenId);
    }

    /* cancel individual signature of listing for erc1155*/
    function cancelListing(
        address contractAddress,
        uint256 tokenId,
        uint256 startTime,
        uint256 expiration,
        uint256 price,
        uint256 quantity,
        uint256 createdAtBlockNumber,
        address paymentERC20,
        bytes memory signature
    ) public {
        BuyOrder memory buyOrder = BuyOrder(
            payable(msg.sender),
            contractAddress,
            tokenId,
            startTime,
            expiration,
            price,
            quantity,
            createdAtBlockNumber,
            paymentERC20
        );

        /* Check signature */
        require(
            _validateSellerSignature(buyOrder, signature),
            "Signature is not valid for BuyOrder."
        );

        require(
            !cancellationRegistry.isOrderCancelled(signature),
            "This order has been cancelled already"
        );

        cancellationRegistry.cancelOrder(signature);

        emit CancelListing(
            msg.sender,
            contractAddress,
            tokenId,
            quantity,
            createdAtBlockNumber,
            startTime,
            expiration
        );
    }
}