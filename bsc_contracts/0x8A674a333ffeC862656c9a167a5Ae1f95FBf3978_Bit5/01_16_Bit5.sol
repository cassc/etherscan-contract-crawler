// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {Order, OrderStatus, OrderKind, TokenKind} from "./LibOrder.sol";
import "./OrderValidator.sol";
import "./Errors.sol";

contract Bit5 is
    OrderValidator,
    Bit5Errors,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    event FeeChanged(uint256 newFee); // Emitted after every fee changes
    event ListingCanceled(bytes sig, address nftAddress, uint256 tokenId); // Emitted after every cancellation of listings
    event BidCanceled(bytes sig, address nftAddress, uint256 tokenId); // Emitted after every canceled bids
    event Buy(
        bytes sig,
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price
    ); // Emitted after every purchase
    event BidAccepted(
        bytes sig,
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price
    ); // Emitted after every accepted bids
    event PaymentTokenStatusChanged(address tokenAddress, bool status);
    event PrivilegedPercentageChanged(address collection, uint256 newPP);

    // EIP2981 interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // For preventing double-spending and unwanted operations
    mapping(bytes => OrderStatus) public orderStatus;

    // We'll handle payment tokens to protect our users
    mapping(address => bool) public paymentTokens;

    // These nft collection holders have a fee advantage
    mapping(address => uint256) public privileges;

    // Royalties
    mapping(address => Royaltier[]) public royalties;

    // For global bid counts
    mapping(bytes => uint256) public processedGlobalBids;

    // Service fee
    uint256 public FEE;

    // Max royalty percentage
    uint256 public maxRoyalty;

    // Base point
    uint256 private constant BP = 10000;

    struct Royaltier {
        address addr;
        uint256 percentage;
    }

    constructor(address[] memory _paymentTokens) {
        FEE = 200; // 2%
        maxRoyalty = 4000; // 40%

        for (uint256 i; i < _paymentTokens.length; ++i) {
            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    // Users can cancel their bids and listing signatures using this function
    function cancelOrder(Order memory order, bytes memory signature)
        public
        isOrderValid(order, signature)
        whenNotPaused
        nonReentrant
    {
        orderStatus[signature] = OrderStatus.CANCELED;

        if (order.kind == OrderKind.BID) {
            emit BidCanceled(signature, order.nftAddress, order.tokenId);
        } else {
            emit ListingCanceled(signature, order.nftAddress, order.tokenId);
        }
    }

    // A user can buy a listed NFT using this function
    function buy(Order memory order, bytes memory signature)
        public
        isOrderValid(order, signature)
        whenNotPaused
        nonReentrant
    {
        if (msg.sender == order.issuer) {
            revert CanNotBuyOwnedToken();
        }

        orderStatus[signature] = OrderStatus.FILLED;
        _doTransfers(order, msg.sender, order.issuer);

        emit Buy(
            signature,
            order.nftAddress,
            order.tokenId,
            order.issuer,
            msg.sender,
            order.price
        );
    }

    // An NFT owner can accept a bid using this function
    function acceptBid(Order memory order, bytes memory signature)
        public
        isOrderValid(order, signature)
        whenNotPaused
        nonReentrant
    {
        if (msg.sender == order.issuer) {
            revert CanNotBuyOwnedToken();
        }

        _acceptBid(order, signature);
    }

    function acceptGlobalBid(
        Order memory order,
        bytes memory signature,
        uint256[] memory tokenIds
    ) public isOrderValid(order, signature) whenNotPaused nonReentrant {
        if (msg.sender == order.issuer) {
            revert CanNotBuyOwnedToken();
        }
        if (
            order.globalBidAmount - processedGlobalBids[signature] <
            tokenIds.length
        ) {
            revert NotEnoughGlobalBids();
        }

        for (uint256 i; i < tokenIds.length; i++) {
            order.tokenId = tokenIds[i];
            processedGlobalBids[signature] += 1;
            _acceptBid(order, signature);
        }
    }

    function addRoyaltier(
        address collection,
        address user,
        uint256 percentage
    ) external {
        if (Ownable(collection).owner() != msg.sender) {
            revert Unauthorized();
        }
        if (supports2981(collection)) {
            revert CannotAddRoyalties();
        }

        uint256 totalPercentage = percentage;
        Royaltier[] memory _collectionFees = royalties[collection];
        for (uint256 i; i < _collectionFees.length; ++i) {
            if (_collectionFees[i].addr == user) {
                revert AlreadyDefined();
            }
            totalPercentage += _collectionFees[i].percentage;
        }
        if (totalPercentage > maxRoyalty) {
            revert ExceedsMaxRoyaltyPercentage();
        }

        royalties[collection].push(
            Royaltier({addr: user, percentage: percentage})
        );
    }

    function deleteRoyaltier(address collection, address user) external {
        if (Ownable(collection).owner() != msg.sender) {
            revert Unauthorized();
        }
        Royaltier[] memory _collectionFees = royalties[collection];
        for (uint256 i; i < _collectionFees.length; ++i) {
            if (_collectionFees[i].addr == user) {
                royalties[collection][i] = royalties[collection][
                    _collectionFees.length - 1
                ];
                royalties[collection].pop();
                return;
            }
        }
    }

    // Modifiers
    modifier isOrderValid(Order memory order, bytes memory signature) {
        _checkOrderValidity(order, signature);
        _;
    }

    // Internal functions
    function _checkPrivilege(
        address collection,
        uint256 tokenId,
        TokenKind kind,
        address claimant
    ) internal view returns (bool) {
        if (privileges[collection] == 0) {
            return false;
        }
        if (kind == TokenKind.ERC721) {
            if (IERC721(collection).ownerOf(tokenId) != claimant) {
                return false;
            }
        } else {
            if (IERC1155(collection).balanceOf(claimant, tokenId) < 1) {
                return false;
            }
        }

        return true;
    }

    function _acceptBid(Order memory order, bytes memory signature) internal {
        _doesMsgSenderOwnNFT(order);
        _doTransfers(order, order.issuer, msg.sender);
        if (order.globalBidAmount > 0) {
            if (processedGlobalBids[signature] == order.globalBidAmount) {
                orderStatus[signature] = OrderStatus.FILLED;
            }
        } else {
            orderStatus[signature] = OrderStatus.FILLED;
        }
        emit BidAccepted(
            signature,
            order.nftAddress,
            order.tokenId,
            msg.sender,
            order.issuer,
            order.price
        );
    }

    function _doTransfers(
        Order memory order,
        address buyer,
        address seller
    ) internal {
        uint256 standardServiceFee = (order.price * FEE) / BP;
        uint256 privilegedServiceFee;
        uint256 totalRoyaltyAmount;

        // if collection has 2981
        if (supports2981(order.nftAddress)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                order.nftAddress
            ).royaltyInfo(order.tokenId, order.price);
            totalRoyaltyAmount += royaltyAmount;
            IERC20(order.paymentToken).transferFrom(
                buyer,
                receiver,
                royaltyAmount
            );
        } else {
            // Bit5 Royalty Mechanism
            Royaltier[] memory _royalties = royalties[order.nftAddress];
            for (uint256 i; i < _royalties.length; ++i) {
                uint256 royalty = (order.price * _royalties[i].percentage) / BP;
                totalRoyaltyAmount += royalty;

                IERC20(order.paymentToken).transferFrom(
                    buyer,
                    _royalties[i].addr,
                    royalty
                );
            }
        }

        if (order.privileges.privilegedCollection != address(0)) {
            bool isPrivileged = _checkPrivilege(
                order.privileges.privilegedCollection,
                order.privileges.privilegedTokenId,
                order.tokenKind,
                seller
            );

            if (isPrivileged) {
                uint256 oldFee = FEE;

                FEE =
                    (FEE * privileges[order.privileges.privilegedCollection]) /
                    BP;
                privilegedServiceFee = (order.price * FEE) / BP;
                FEE = oldFee;
            }
        }

        IERC20(order.paymentToken).transferFrom(
            buyer,
            seller,
            order.price -
                standardServiceFee -
                totalRoyaltyAmount +
                privilegedServiceFee
        );

        IERC20(order.paymentToken).transferFrom(
            buyer,
            address(this),
            (standardServiceFee - privilegedServiceFee)
        );

        // Give nfts to the buyer
        if (order.tokenKind == TokenKind.ERC721) {
            IERC721(order.nftAddress).transferFrom(
                seller,
                buyer,
                order.tokenId
            );
        } else {
            IERC1155(order.nftAddress).safeTransferFrom(
                seller,
                buyer,
                order.tokenId,
                order.amount,
                ""
            );
        }
    }

    function _checkOrderValidity(Order memory order, bytes memory signature)
        internal
        view
    {
        if (order.end < block.timestamp) {
            revert OrderExpired();
        }
        if (order.issuer != verify(order, signature)) {
            revert WrongSignature();
        }
        if (orderStatus[signature] != OrderStatus.NOT_PROCESSED) {
            revert AlreadyProcessed();
        }
        if (!paymentTokens[order.paymentToken]) {
            revert InvalidPaymentToken();
        }
    }

    function _doesMsgSenderOwnNFT(Order memory order) internal view {
        if (order.tokenKind == TokenKind.ERC721) {
            if (
                IERC721(order.nftAddress).ownerOf(order.tokenId) != msg.sender
            ) {
                revert Unauthorized();
            }
        } else {
            if (
                IERC1155(order.nftAddress).balanceOf(
                    msg.sender,
                    order.tokenId
                ) < order.amount
            ) {
                revert Unauthorized();
            }
        }
    }

    function supports2981(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    // View functions
    function royaltiers(address collection)
        external
        view
        returns (Royaltier[] memory)
    {
        return royalties[collection];
    }

    // Only Owner Functions
    function changeFee(uint256 newFee) external onlyOwner {
        FEE = newFee;
        emit FeeChanged(newFee);
    }

    function changePrivilegePercentage(address collection, uint256 pp)
        external
        onlyOwner
    {
        privileges[collection] = pp;
        emit PrivilegedPercentageChanged(collection, pp);
    }

    function setPaymentToken(address tokenAddress, bool available)
        external
        onlyOwner
    {
        paymentTokens[tokenAddress] = available;
        emit PaymentTokenStatusChanged(tokenAddress, available);
    }

    function withdrawBNB(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}