// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./interfaces/IERC2981.sol";

/**
 * @title FixedPriceAuction
 * @notice A fixed price "auction". The first person to call `buy()` successfully will be the winner and will
 *         immediately receive the specified NFT.
 */
contract FixedPriceAuction is EIP712, Ownable, Pausable, ReentrancyGuard {
    struct Lot {
        uint256 tokenId;
        uint256 price;
        uint128 nonce;
        uint64 notBefore;
        uint64 deadline;
        address payable seller;
        address tokenAddress;
    }

    uint256 private _auctionFeeBps;

    // Lot digest uniqueness constraint: set to 1 when this lot has already been sold
    mapping(bytes32 => bool) private _lotDigestNonce;

    // Auction and royalty fees escrowed by the contract.
    mapping(address => uint256) private _balances;

    // solhint-disable-next-line no-empty-blocks
    constructor(uint256 auctionFeeBps_)
        EIP712("Sloika Fixed Price Auction", "1")
        Ownable()
        Pausable()
        ReentrancyGuard()
    {
        _auctionFeeBps = auctionFeeBps_;
    }

    function buy(
        Lot memory lot_,
        bytes memory signature_,
        address buyer_
    ) external payable whenNotPaused nonReentrant {
        // CHECKS
        require(msg.value == lot_.price, "FPA: incorrect amount sent");

        require(lot_.notBefore <= block.timestamp, "FPA: auction not yet started");
        require(lot_.deadline == 0 || lot_.deadline >= block.timestamp, "FPA: auction already ended");

        bytes32 digest = _getLotDigest(lot_);
        require(_lotDigestNonce[digest] == false, "FPA: lot already sold");
        require(ECDSA.recover(digest, signature_) == lot_.seller, "FPA: invalid signature");

        // PRE-EFFECTS
        // Get amounts
        uint256 auctionFee = (lot_.price * _auctionFeeBps) / 10000;

        // Get royalty amount
        (address royaltyReceiver, uint256 royaltyAmount) = _getRoyaltyInfo(
            lot_.tokenAddress,
            lot_.tokenId,
            lot_.price - auctionFee
        );

        if (royaltyReceiver == address(0) || royaltyReceiver == lot_.seller) {
            // No royalty, or royalty goes to seller
            royaltyAmount = 0;
        }

        uint256 sellerShare = lot_.price - (auctionFee + royaltyAmount);
        assert(sellerShare + auctionFee + royaltyAmount <= lot_.price);

        // EFFECTS
        _lotDigestNonce[digest] = true;

        // INTERACTIONS
        // Transfer the token and ensure delivery of the token
        IERC721(lot_.tokenAddress).safeTransferFrom(lot_.seller, buyer_, lot_.tokenId);
        require(IERC721(lot_.tokenAddress).ownerOf(lot_.tokenId) == buyer_, "FixedPriceAuction: token transfer failed"); // ensure delivery

        // Ensure delivery of the payment
        // solhint-disable-next-line avoid-low-level-calls
        (bool paymentSent, ) = lot_.seller.call{value: sellerShare}("");
        require(paymentSent, "FixedPriceAuction: payment failed");
    }

    function _getLotDigest(Lot memory lot_) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Lot(uint256 tokenId,uint256 price,uint128 nonce,uint64 notBefore,uint64 deadline,address seller,address tokenAddress)"
                        ),
                        lot_.tokenId,
                        lot_.price,
                        lot_.nonce,
                        lot_.notBefore,
                        lot_.deadline,
                        lot_.seller,
                        lot_.tokenAddress
                    )
                )
            );
    }

    function _getRoyaltyInfo(
        address tokenAddress_,
        uint256 tokenId_,
        uint256 price_
    ) private view returns (address, uint256) {
        try IERC2981(tokenAddress_).royaltyInfo(tokenId_, price_) returns (
            address royaltyReceiver,
            uint256 royaltyAmount
        ) {
            return (royaltyReceiver, royaltyAmount);
        } catch (bytes memory reason) {
            // EIP 2981's `royaltyInfo()` function is not implemented
            // treatment the same as here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.1/contracts/token/ERC721/ERC721.sol#L379
            if (reason.length == 0) {
                return (address(0), 0);
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @dev Auction fee setters and getters
    function auctionFeeBps() public view returns (uint256) {
        return _auctionFeeBps;
    }

    function setAuctionFeeBps(uint256 newAuctionFeeBps_) public onlyOwner {
        _auctionFeeBps = newAuctionFeeBps_;
    }

    /// @dev Auction fee withdrawal
    function withdraw(address payable account_, uint256 amount_) public nonReentrant onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool paymentSent, ) = account_.call{value: amount_}("");
        require(paymentSent, "FixedPriceAuction: withdrawal failed");
    }

    /// @dev The following functions relate to pausing of the contract
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}