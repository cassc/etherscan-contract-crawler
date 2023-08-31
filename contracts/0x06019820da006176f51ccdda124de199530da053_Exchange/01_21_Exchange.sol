// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Exchange is ReentrancyGuard, EIP712, Ownable {
    bytes internal constant personalSignPrefix =
        "\x19Ethereum Signed Message:\n";
    address treasurer;
    address marketPlaceCommission;
    bytes32 internal constant domainSeparator = keccak256("artchain");

    /* Struct definitions. */
    constructor() EIP712("artchain", "1.0") Ownable() {
        treasurer = 0x1921f28E460de1ef0f676880c80F909C57cB6a6C;
        marketPlaceCommission = 0x1921f28E460de1ef0f676880c80F909C57cB6a6C;
    }

    /* An order, convenience struct. */
    struct Order {
        /* Order maker address. */
        address maker;
        /* Order maker address. */
        address nftAddress;
        /* NFT tokenId */
        uint256 tokenId;
        /* erc token address */
        address erc20;
        /* Order price. */
        uint256 price;
        /*distribution percentage */
        uint256 percent;
        /* Order listing timestamp. */
        uint256 listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;
    }

    /* Constants */

    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            // solhint-disable-next-line max-line-length
            "Order(address maker,address nftAddress,uint256 tokenId,address erc20,uint256 price,uint256 percent,uint256 listingTime,uint256 expirationTime,uint256 salt)"
        );

    /* Variables */

    /* Order fill status, by maker address then by hash. */
    mapping(address => mapping(bytes32 => uint256)) public fills;

    /* Events */

    event OrdersMatched(
        bytes32 firstHash,
        bytes32 secondHash,
        address indexed firstMaker,
        address indexed secondMaker
    );

    function setTreasurer(address _treasurer) external onlyOwner {
        require(_treasurer != address(0), "treasurer is the zero address");
        treasurer = _treasurer;
    }

    function setMarketPlaceCommission(
        address _marketPlaceCommission
    ) external onlyOwner {
        require(
            _marketPlaceCommission != address(0),
            "market place commission address is the zero address"
        );
        marketPlaceCommission = _marketPlaceCommission;
    }

    function getTreasurer() public view returns (address) {
        return treasurer;
    }

    function getMarketPlaceCommission() public view returns (address) {
        return marketPlaceCommission;
    }

    function hashOrder(Order memory order) public pure returns (bytes32 hash) {
        /* Per EIP 712. */
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.nftAddress,
                    order.tokenId,
                    order.price,
                    order.percent,
                    order.listingTime,
                    order.expirationTime,
                    order.salt
                )
            );
    }

    function hashToSign(bytes32 orderHash) public view returns (bytes32 hash) {
        /* Calculate the string a user must sign. */
        return
            keccak256(abi.encodePacked("\x19\x01", domainSeparator, orderHash));
    }

    function encodeSignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory) {
        return abi.encode(v, r, s);
    }

    function validateOrderParameters(
        Order memory order,
        bytes32 hash_
    ) internal view returns (bool) {
        /* Order must be listed and not be expired. */
        if (
            order.listingTime > block.timestamp ||
            (order.expirationTime != 0 &&
                order.expirationTime <= block.timestamp)
        ) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(
        bytes32 hash,
        address maker,
        bytes memory signature
    ) internal view returns (bool) {
        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);

        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );

        if (
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        personalSignPrefix,
                        "32",
                        calculatedHashToSign
                    )
                ),
                v,
                r,
                s
            ) == maker
        ) {
            return true;
        }

        return false;
    }

    function validateOrdersMatch(
        Order memory seller,
        Order memory buyer
    ) internal pure {
        require(
            seller.nftAddress == buyer.nftAddress,
            "Nft Address must match"
        );
        require(seller.tokenId == buyer.tokenId, "Token Id  must match");
    }

    function atomicMatch(
        Order memory seller,
        Order memory buyer,
        bytes memory sellerSignature,
        bytes memory buyerSignature
    ) public payable nonReentrant {
        IERC1155 collection = IERC1155(seller.nftAddress);

        require(msg.value >= buyer.price, "Price is not correct");

        require(buyer.price >= seller.price, "buyer price is not enough");

        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(seller);

        /* Check first order validity. */
        require(
            validateOrderParameters(seller, firstHash),
            "First order has invalid parameters"
        );

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(buyer);

        /* Check second order validity. */
        require(
            validateOrderParameters(buyer, secondHash),
            "Second order has invalid parameters"
        );

        require(
            fills[seller.maker][firstHash] == 0,
            "this order already filled"
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");
        {
            /* Check first order authorization. */
            require(
                validateOrderAuthorization(
                    firstHash,
                    seller.maker,
                    sellerSignature
                ),
                "First order failed authorization"
            );

            /* Check second order authorization. */
            require(
                validateOrderAuthorization(
                    secondHash,
                    buyer.maker,
                    buyerSignature
                ),
                "Second order failed authorization"
            );
            validateOrdersMatch(seller, buyer);
        }

        require(
            collection.isApprovedForAll(seller.maker, address(this)),
            "Seller must be approve"
        );

        require(
            collection.balanceOf(seller.maker, seller.tokenId) > 0,
            "Seller must be have enough funds"
        );

        (uint256 sellAmount, uint256 shareAmount) = _computePrices(
            buyer,
            seller
        );

        _doSwap(collection, buyer, seller, sellAmount, shareAmount, firstHash);
        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, buyer.maker, seller.maker);
    }

    function atomicMatchWithToken(
        Order memory seller,
        Order memory buyer,
        bytes memory sellerSignature,
        bytes memory buyerSignature
    ) public payable nonReentrant {
        IERC1155 collection = IERC1155(seller.nftAddress);

        require(buyer.price >= seller.price, "buyer price is not enough");

        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(seller);

        /* Check first order validity. */
        require(
            validateOrderParameters(seller, firstHash),
            "First order has invalid parameters"
        );

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(buyer);

        /* Check second order validity. */
        require(
            validateOrderParameters(buyer, secondHash),
            "Second order has invalid parameters"
        );

        require(
            fills[seller.maker][firstHash] == 0,
            "this order already filled"
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");
        {
            /* Check first order authorization. */
            require(
                validateOrderAuthorization(
                    firstHash,
                    seller.maker,
                    sellerSignature
                ),
                "First order failed authorization"
            );

            /* Check second order authorization. */
            require(
                validateOrderAuthorization(
                    secondHash,
                    buyer.maker,
                    buyerSignature
                ),
                "Second order failed authorization"
            );
            validateOrdersMatch(seller, buyer);
        }

        require(
            collection.isApprovedForAll(seller.maker, address(this)),
            "Seller must be approve"
        );

        require(
            collection.balanceOf(seller.maker, seller.tokenId) > 0,
            "Seller must be have enough funds"
        );

        IERC20 token_ = IERC20(seller.erc20);

        (uint256 sellAmount, uint256 shareAmount) = _computePrices(
            buyer,
            seller
        );
        require(
            token_.balanceOf(buyer.maker) >= buyer.price,
            "Buyer must be have enough funds"
        );

        _doSwapWithToken(
            token_,
            collection,
            buyer,
            seller,
            sellAmount,
            shareAmount,
            firstHash
        );
        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, buyer.maker, seller.maker);
    }

    function _computePrices(
        Order memory buyer,
        Order memory seller
    ) internal pure returns (uint256, uint256) {
        uint256 sellmul = SafeMath.mul(buyer.price, seller.percent);
        uint256 sellAmount = SafeMath.div(sellmul, 10 ** 18);
        uint256 sharePerc = SafeMath.sub(10 ** 18, seller.percent);
        uint256 sharemul = SafeMath.mul(buyer.price, sharePerc);
        uint256 shareAmount = SafeMath.div(sharemul, 10 ** 18);
        return (sellAmount, shareAmount);
    }

    function _doSwap(
        IERC1155 collection,
        Order memory buyer,
        Order memory seller,
        uint256 sellAmount,
        uint256 shareAmount,
        bytes32 firstHash
    ) internal {
        uint256 fullAmount = msg.value;

        uint256 wfyAmount = (fullAmount * 1) / 100;

        uint256 mktAmount = (fullAmount * 5) / 100;

        uint256 maAmount = (fullAmount * 9) / 100;

        uint256 sellerAmount = (fullAmount * 85) / 100;

        payable(seller.maker).transfer(sellerAmount);

        payable(0x49c6B1c099b5B3F00787376d4A06f769742afbfd).transfer(wfyAmount);

        payable(marketPlaceCommission).transfer(mktAmount);

        payable(treasurer).transfer(maAmount);

        collection.safeTransferFrom(
            seller.maker,
            buyer.maker,
            seller.tokenId,
            1,
            ""
        );

        // Price will transfer to money transfer contract
        fills[seller.maker][firstHash] = buyer.price;
    }

    function _doSwapWithToken(
        IERC20 token_,
        IERC1155 collection,
        Order memory buyer,
        Order memory seller,
        uint256 sellAmount,
        uint256 shareAmount,
        bytes32 firstHash
    ) internal {
        uint256 fullAmount = seller.price;

        uint256 wfyAmount = (fullAmount * 1) / 100;

        uint256 mktAmount = (fullAmount * 5) / 100;

        uint256 maAmount = (fullAmount * 9) / 100;

        uint256 sellerAmount = (fullAmount * 85) / 100;

        token_.transferFrom(buyer.maker, seller.maker, sellerAmount);

        token_.transferFrom(
            buyer.maker,
            0x49c6B1c099b5B3F00787376d4A06f769742afbfd,
            wfyAmount
        );

        token_.transferFrom(buyer.maker, marketPlaceCommission, mktAmount);

        token_.transferFrom(buyer.maker, treasurer, maAmount);

        collection.safeTransferFrom(
            seller.maker,
            buyer.maker,
            seller.tokenId,
            1,
            ""
        );

        // Price will transfer to money transfer contract
        fills[seller.maker][firstHash] = buyer.price;
    }
}