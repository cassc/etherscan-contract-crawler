// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "Ownable.sol";
import "Address.sol";
import "EnumerableMap.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "IERC721Receiver.sol";
import "IERC721.sol";
import "EnumerableSet.sol";
import "ListingSetLib.sol";
import "IUniswapV2Router02.sol";

contract SolidoNFTMarketplaceV2 is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using ListingSetLib for ListingSetLib.ListingSet;

    struct PayableTokenPrice {
        IERC20 payableToken;
        uint256 price;
    }

    struct ListItem {
        IERC721 nftContract;
        uint256 tokenId;
        IERC20 payableToken;
        uint256 price;
    }

    struct DelistItem {
        IERC721 nftContract;
        uint256 tokenId;
    }

    event NFTPriceSet(
        address indexed lister,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        IERC20 payableToken,
        uint256 price  // 0 means "no listing"
    );
    event Listed(
        address indexed lister,
        address from,
        IERC721 indexed nftContract,
        uint256 indexed tokenId
    );
    event Delisted(
        address indexed delister,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        address to
    );
    event Purchased(
        address indexed purchaser,
        address to,
        IERC721 indexed nftContract,
        uint256 indexed tokenId,
        IERC20 payableToken,
        uint256 price
    );
    event NativeWithdrawn(
        address indexed to,
        uint256 amount
    );
    event ERC20Withdrawn(
        IERC20 indexed token,
        address indexed to,
        uint256 amount
    );
    event ERC721Recovered(
        IERC721 indexed nftContract,
        address indexed to,
        uint256 tokenId
    );
    event DexSet(IUniswapV2Router02 dex);

    ListingSetLib.ListingSet internal _listingSet;  // for easy querying
    mapping (IERC721 /*nftContract*/ =>
        mapping (uint256 /*tokenId*/ => PayableTokenPrice)
    ) internal _nftContractTokenIdPayableTokenPrice;

    uint256 public totalListedNFT;
    IUniswapV2Router02 public dex;

    error BuyWrongPrice(uint256 actualPrice, uint256 expectedPrice);
    error BuyWrongPayableToken(IERC20 actualPayableToken, IERC20 expectedPayableToken);

    constructor() {
    }

    function setDex(IUniswapV2Router02 _dex) external onlyOwner {
        require(dex != _dex, "not changed");
        dex = _dex;
        emit DexSet(_dex);
    }

    /// @notice update listed NFT price
    /// @param nftContract nft address
    /// @param tokenId token id
    /// @param payableToken payable token (use address(0) to accept native currency)
    /// @param price price (not zero)
    function updateListing(
        IERC721 nftContract,
        uint256 tokenId,
        IERC20 payableToken,
        uint256 price
    ) external onlyOwner {
        PayableTokenPrice memory oldListing = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        require(price > 0, "zero price");
        require(_listingSet.remove(ListingSetLib.Listing({
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: oldListing.payableToken,
            price: oldListing.price
        })), "not listed");
        _listingSet.add(ListingSetLib.Listing({
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price
        }));
        _nftContractTokenIdPayableTokenPrice[nftContract][tokenId] = PayableTokenPrice(payableToken, price);
        emit NFTPriceSet({
            lister: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price
        });
    }

    function list(
        address from,
        IERC721 nftContract,
        uint256 tokenId,
        IERC20 payableToken,
        uint256 price
    ) public onlyOwner {
        _listingSet.add(ListingSetLib.Listing(nftContract, tokenId, payableToken, price));
        _nftContractTokenIdPayableTokenPrice[nftContract][tokenId] = PayableTokenPrice(payableToken, price);
        totalListedNFT += 1;
        emit Listed({
            lister: msg.sender,
            from: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId
        });
        emit NFTPriceSet({
            lister: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price
        });
        nftContract.safeTransferFrom(from, address(this), tokenId);
    }

    function listMany(
        address from,
        ListItem[] memory items
    ) external onlyOwner {
        for (uint256 index = 0; index < items.length;) {
            ListItem memory item = items[index];
            list({
                from: from,
                nftContract: item.nftContract,
                tokenId: item.tokenId,
                payableToken: item.payableToken,
                price: item.price
            });
            unchecked {
                index += 1;
            }
        }
    }

    function delist(
        address to,
        IERC721 nftContract,
        uint256 tokenId
    ) public onlyOwner {
        PayableTokenPrice memory oldListing = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        require(oldListing.price != 0, "NOT_LISTED");
        delete _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        _listingSet.remove(ListingSetLib.Listing(nftContract, tokenId, oldListing.payableToken, oldListing.price));
        totalListedNFT -= 1;
        nftContract.safeTransferFrom(address(this), to, tokenId);
        emit Delisted({
            delister: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            to: to
        });
    }

    function delistMany(
        address to,
        DelistItem[] memory items
    ) external onlyOwner {
        for (uint256 index = 0; index < items.length;) {
            DelistItem memory item = items[index];
            delist({
                to: to,
                nftContract: item.nftContract,
                tokenId: item.tokenId
            });
            unchecked {
                index += 1;
            }
        }
    }

    function _buyUnsafe(
        address to,
        IERC721 nftContract,
        uint256 tokenId,
        PayableTokenPrice memory listing
    ) internal {
        require(listing.price > 0, "no listing");
        _listingSet.remove(ListingSetLib.Listing(nftContract, tokenId, listing.payableToken, listing.price));
        totalListedNFT -= 1;
        delete _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
    }

    function buy(
        address to,
        IERC721 nftContract,
        uint256 tokenId,
        IERC20 payableToken,  // assume there is no transfer fee
        uint256 expectedPrice
    ) external {
        PayableTokenPrice memory listing = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        if (listing.payableToken != payableToken) revert BuyWrongPayableToken({
            actualPayableToken: listing.payableToken,
            expectedPayableToken: payableToken
        });
        if (listing.price != expectedPrice) revert BuyWrongPrice({
            actualPrice: listing.price,
            expectedPrice: expectedPrice
        });
        _buyUnsafe({
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            listing: listing
        });
        payableToken.safeTransferFrom(msg.sender, address(this), expectedPrice);
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: expectedPrice
        });
    }

    function buyForNative(
        address to,
        IERC721 nftContract,
        uint256 tokenId
    ) external payable {
        PayableTokenPrice memory listing = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        if (listing.payableToken != IERC20(address(0))) revert BuyWrongPayableToken({
            actualPayableToken: listing.payableToken,
            expectedPayableToken: IERC20(address(0))
        });
        if (listing.price != msg.value) revert BuyWrongPrice({
            actualPrice: listing.price,
            expectedPrice: msg.value
        });
        _buyUnsafe({
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            listing: listing
        });
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: IERC20(address(0)),
            price: msg.value
        });
    }

    /// @notice withdraw native token, this could be used to withdraw payouts or occasionally sent native tokens
    function withdrawNative(uint256 amount, address payable to) external onlyOwner {
        to.sendValue(amount);
        emit NativeWithdrawn(to, amount);
    }

    /// @notice withdraw erc20 token, this could be used to withdraw payouts or occasionally sent native tokens
    function withdrawERC20(IERC20 _token, uint256 amount, address to) external onlyOwner {
        _token.safeTransfer(to, amount);
        emit ERC20Withdrawn(_token, to, amount);
    }

    /// @notice recover erc721 token
    function recoverERC721(IERC721 _nft, uint256 tokenId, address to) external onlyOwner {
        _nft.safeTransferFrom(address(this), to, tokenId);
        emit ERC721Recovered(_nft, to, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getTotalNFTPayableTokenPriceOffersNumber() external view returns(uint256) {
        return _listingSet.length();
    }

    function getNFTContractTokenIdPayableTokenPrice(
        IERC721 nftContract,
        uint256 tokenId
    ) external view returns(IERC20 payableToken, uint256 price) {
        PayableTokenPrice memory listing = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        return (listing.payableToken, listing.price);
    }

    function getAllOffers() external view returns(ListingSetLib.Listing[] memory) {
        return getAllOffersPaginated(0, _listingSet.length());
    }

    function getAllOffersPaginated(
        uint256 start,
        uint256 end
    ) public view returns(ListingSetLib.Listing[] memory) {
        uint256 _length = _listingSet.length();
        if (end > _length) {
            end = _length;
        }
        require(end >= start, "end < start");
        unchecked {
            ListingSetLib.Listing[] memory result = new ListingSetLib.Listing[](end-start);  // no underflow
            uint256 resultIndex = 0;
            for (uint256 index=start; index<end;) {
                result[resultIndex] = _listingSet.at(index);
                    index += 1;  // no overflow
                    resultIndex += 1;  // no overflow
            }
            return result;
        }
    }
}