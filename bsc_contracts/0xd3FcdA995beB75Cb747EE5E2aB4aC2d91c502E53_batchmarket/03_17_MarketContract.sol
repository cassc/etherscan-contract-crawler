//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketEvents.sol";
import "./Verification.sol";
import "./ILazymint.sol";
import "./verifySignature.sol";
//import "hardhat/console.sol";

/// @title An Auction Contract for bidding and selling single and batched NFTs
/// @notice This contract can be used for auctioning any NFTs, and accepts any ERC20 token as payment
/// @author Disruptive Studios
/// @author Modified from Avo Labs GmbH (https://github.com/avolabs-io/nft-auction/blob/master/contracts/NFTAuction.sol)
contract NFTMarket is MarketEvents, verification, VerifySignature {
    ///@notice Map each auction with the token ID
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    ///@notice If transfer fail save to withdraw later
    mapping(address => uint256) public failedTransferCredits;

    ///@notice Each Auction is unique to each NFT (contract + id pairing).
    ///@param auctionBidPeriod Increments the length of time the auction is open,
    ///in which a new bid can be made after each bid.
    ///@param ERC20Token The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
    struct Auction {
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod;
        uint64 auctionEnd;
        uint256 minPrice;
        uint256 buyNowPrice;
        uint256 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address ERC20Token;
        address[] feeRecipients;
        uint32[] feePercentages;
        bool lazymint;
        string metadata;
    }

    ///@notice Default values market fee
    address payable public addressmarketfee;
    uint256 public feeMarket = 250; //Equal 2.5%

    /*///////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
                msg.sender,
            "Initiated by the owner"
        );

        if (
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
            address(0)
        ) {
            require(
                msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Sender doesn't own NFT"
            );
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              END MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // constructor
    constructor(address payable _addressmarketfee) {
        addressmarketfee = _addressmarketfee;
    }

    /*///////////////////////////////////////////////////////////////
                    AUCTION/SELL CHECK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    ///@dev If the buy now price is set by the seller, check that the highest bid meets that price.
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        return
            buyNowPrice > 0 &&
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >=
            buyNowPrice;
    }

    ///@dev Check that a bid is applicable for the purchase of the NFT.
    ///@dev In the case of a sale: the bid needs to meet the buyNowPrice.
    ///@dev if buyNowPrice is met, ignore increase percentage
    ///@dev In the case of an auction: the bid needs to be a % higher than the previous bid.
    ///@dev if the NFT is up for auction, the bid needs to be a % higher than the previous bid
    function _bidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        bool _sign
    ) internal view returns (bool) {
        if (_sign) {
            return true;
        } else {
            uint256 buyNowPrice = nftContractAuctions[_nftContractAddress][
                _tokenId
            ].buyNowPrice;
            if (
                buyNowPrice > 0 &&
                (msg.value >= buyNowPrice || _tokenAmount >= buyNowPrice)
            ) {
                return true;
            }
            uint32 bidIncreasePercentage = nftContractAuctions[
                _nftContractAddress
            ][_tokenId].bidIncreasePercentage;

            uint256 bidIncreaseAmount = (nftContractAuctions[
                _nftContractAddress
            ][_tokenId].nftHighestBid * (10000 + bidIncreasePercentage)) /
                10000;
            return (msg.value >= bidIncreaseAmount ||
                _tokenAmount >= bidIncreaseAmount);
        }
    }

    ///@dev Payment is accepted in the following scenarios:
    ///@dev (1) Auction already created - can accept ETH or Specified Token
    ///@dev  --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
    ///@dev (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
    ///@dev (3) Cannot make a zero bid (no ETH or Token amount)
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint256 _tokenAmount,
        bool _sign
    ) internal view returns (bool) {
        if (_sign) {
            return true;
        } else {
            address auctionERC20Token = nftContractAuctions[
                _nftContractAddress
            ][_tokenId].ERC20Token;
            if (auctionERC20Token != address(0)) {
                return
                    msg.value == 0 &&
                    auctionERC20Token == _bidERC20Token &&
                    _tokenAmount > 0;
            } else {
                return
                    msg.value != 0 &&
                    _bidERC20Token == address(0) &&
                    _tokenAmount == 0;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                     END
                            AUCTION CHECK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                      TRANSFER NFTS TO CONTRACT
    //////////////////////////////////////////////////////////////*/

    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(
                _nftSeller,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "nft transfer failed"
            );
        } else {
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                                END
                      TRANSFER NFTS TO CONTRACT
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                          AUCTION CREATION
    //////////////////////////////////////////////////////////////*/

    ///@dev Setup parameters applicable to all auctions and whitelised sales:
    ///@dev --> ERC20 Token for payment (if specified by the seller) : _erc20Token
    ///@dev --> minimum price : _minPrice
    ///@dev --> buy now price : _buyNowPrice
    ///@dev --> the nft seller: msg.sender
    ///@dev --> The fee recipients & their respective percentages for a sucessful auction/sale
    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint32 _bidIncreasePercentage,
        uint32 _auctionBidPeriod,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal isFeePercentagesLessThanMaximum(_feePercentages) {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = _bidIncreasePercentage;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .auctionBidPeriod = _auctionBidPeriod;
    }

    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token, //change to BEP20Token
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint32 _bidIncreasePercentage,
        uint32 _auctionBidPeriod,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        bool _lazymint,
        string memory _metadata
    ) internal {
        string memory _uri;
        if (!_lazymint) {
            _uri = metadata(_nftContractAddress, _tokenId);
        } else {
            _uri = _metadata;
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].lazymint = _lazymint;
        nftContractAuctions[_nftContractAddress][_tokenId].metadata = _metadata;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = (uint64(
            block.timestamp
        ) + _auctionBidPeriod);
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _bidIncreasePercentage,
            _auctionBidPeriod,
            _feeRecipients,
            _feePercentages
        );
        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _auctionBidPeriod,
            _bidIncreasePercentage,
            _feeRecipients,
            _feePercentages,
            _lazymint,
            _uri
        );
    }

    ///@param _bidIncreasePercentage It is the percentage for an offer to be validated.
    ///@param _auctionBidPeriod this is the time that the auction lasts until another bid occurs
    function createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        bool _lazymint,
        string memory _metadata
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_minPrice)
    {
        require(
            _bidIncreasePercentage >= 100, //Equal 1%
            "Bid increase percentage too low"
        );
        _createNewNftAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _bidIncreasePercentage,
            _auctionBidPeriod,
            _feeRecipients,
            _feePercentages,
            _lazymint,
            _metadata
        );
        if (!_lazymint) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        }
    }

    /*///////////////////////////////////////////////////////////////
                              END
                       AUCTION CREATION
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                              SALES
    //////////////////////////////////////////////////////////////*/
    function _setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal isFeePercentagesLessThanMaximum(_feePercentages) {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
    }

    ///@notice Allows for a standard sale mechanism.
    ///@dev For sale the min price must be 0
    ///@dev _isABidMade check if buyNowPrice is meet and conclude sale, otherwise reverse the early bid
    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        address _nftSeller,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        bool _lazymint,
        string memory _metadata
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_buyNowPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].lazymint = _lazymint;
        nftContractAuctions[_nftContractAddress][_tokenId].metadata = _metadata;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller = _nftSeller;
        _setupSale(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
        string memory _uri;
        if (!_lazymint) {
            _uri = metadata(_nftContractAddress, _tokenId);
        } else {
            _uri = _metadata;
        }

        emit SaleCreated(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _erc20Token,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages,
            _lazymint,
            _uri
        );
        if (!_lazymint) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        }
    }

    /*///////////////////////////////////////////////////////////////
                              END  SALES
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                              BID FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Make bids with ETH or an ERC20 Token specified by the NFT seller.
    ///@notice Additionally, a buyer can pay the asking price to conclude a sale of an NFT.
    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount,
        uint256 _value,
        uint256 _coupon,
        bytes memory _signature,
        uint256 _nonce,
        bool _discount
    ) external payable {
        bool verify = false;
        address seller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        bool _sign = false;
        if (_discount) {
            verify = validate(_value, _coupon, _signature, seller, _nonce);
        }
        if (verify) {
            _sign = true;
        }
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionEnd;
        if (auctionEndTimestamp != 0) {
            require(
                (block.timestamp < auctionEndTimestamp),
                "Auction has ended"
            );
        }
        require(msg.sender != seller, "Owner cannot bid on own NFT");
        require(
            _bidMeetBidRequirements(
                _nftContractAddress,
                _tokenId,
                _tokenAmount,
                _sign
            ),
            "Not enough funds to bid on NFT"
        );
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount,
                _sign
            ),
            "Bid to be in specified ERC20/ETH"
        );
        _reversePreviousBidAndUpdateHighestBid(
            _nftContractAddress,
            _tokenId,
            _tokenAmount,
            _sign
        );
        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value,
            _erc20Token,
            _tokenAmount,
            _coupon
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId, _sign, _value);
    }

    /*///////////////////////////////////////////////////////////////
                        END BID FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                        UPDATE AUCTION
    //////////////////////////////////////////////////////////////*/

    ///@notice Settle an auction or sale if the buyNowPrice is met or set
    ///@dev min price not set, nft not up for auction yet
    function _updateOngoingAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        bool _sign,
        uint256 _value
    ) internal {
        uint256 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        if (_sign) {
            if (_value >= buyNowPrice) {
                _transferNFT(_nftContractAddress, _tokenId);
            } else {
                _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                return;
            }
        } else {
            if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
                _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                return;
            }
        }
    }

    ///@dev the auction end is always set to now + the bid period
    /*function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        uint32 auctionBidPeriod = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd =
            auctionBidPeriod +
            uint64(block.timestamp);
        emit AuctionPeriodUpdated(
            _nftContractAddress,
            _tokenId,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
        );
    }*/

    /*///////////////////////////////////////////////////////////////
                           END UPDATE AUCTION
   //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                           RESET FUNCTIONS
   //////////////////////////////////////////////////////////////*/

    ///@notice Reset all auction related parameters for an NFT.
    ///@notice This effectively removes an NFT as an item up for auction
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(
            0
        );
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(
            0
        );
    }

    ///@notice Reset all bid related parameters for an NFT.
    ///@notice This effectively sets an NFT as having no active bids
    function _resetBids(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
    }

    /*///////////////////////////////////////////////////////////////
                        END RESET FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                        UPDATE BIDS
    //////////////////////////////////////////////////////////////*/
    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        bool _sign
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_sign) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBidder = msg.sender;
            if (auctionERC20Token != address(0)) {
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBid = _tokenAmount;
                IERC20(auctionERC20Token).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
            } else {
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBid = msg.value;
            }
        } else {
            address prevNftHighestBidder = nftContractAuctions[
                _nftContractAddress
            ][_tokenId].nftHighestBidder;
            uint256 prevNftHighestBid = nftContractAuctions[
                _nftContractAddress
            ][_tokenId].nftHighestBid;

            if (auctionERC20Token != address(0)) {
                IERC20(auctionERC20Token).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenAmount
                );
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBid = _tokenAmount;
            } else {
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBid = msg.value;
            }
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBidder = msg.sender;

            if (prevNftHighestBidder != address(0)) {
                _payout(
                    _nftContractAddress,
                    _tokenId,
                    prevNftHighestBidder,
                    prevNftHighestBid
                );
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                          END UPDATE BIDS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                    TRANSFER NFT, PAY SELLER & MARKET
    //////////////////////////////////////////////////////////////*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        bool lazymint = nftContractAuctions[_nftContractAddress][_tokenId]
            .lazymint;

        _resetBids(_nftContractAddress, _tokenId);
        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid
        );
        if (!lazymint) {
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                _nftHighestBidder,
                _tokenId
            );
        } else {
            //This is the lazyminting function
            ILazyNFT(_nftContractAddress).redeem(
                _nftHighestBidder,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId].metadata
            );
        }
        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder
        );
    }

    function _transferNFT(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        bool lazymint = nftContractAuctions[_nftContractAddress][_tokenId]
            .lazymint;

        if (!lazymint) {
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                _nftHighestBidder,
                _tokenId
            );
        } else {
            //This is the lazyminting function
            ILazyNFT(_nftContractAddress).redeem(
                _nftHighestBidder,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId].metadata
            );
        }
        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTTransferred(_nftContractAddress, _tokenId, _nftHighestBidder);
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) internal {
        uint256 feesPaid = 0;
        uint256 minusfee = _getPortionOfBid(_highestBid, feeMarket);

        uint256 subtotal = _highestBid - minusfee;

        feesPaid = _payoutroyalties(_nftContractAddress, _tokenId, subtotal);

        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            (subtotal - feesPaid)
        );
        sendpayment(_nftContractAddress, _tokenId, minusfee);
    }

    function sendpayment(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 minusfee
    ) internal {
        uint256 amount = minusfee;
        minusfee = 0;
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;

        if (auctionERC20Token != address(0)) {
            IERC20(auctionERC20Token).transfer(addressmarketfee, amount);
        } else {
            (bool success, ) = payable(addressmarketfee).call{value: amount}(
                ""
            );
            if (!success) {
                failedTransferCredits[addressmarketfee] =
                    failedTransferCredits[addressmarketfee] +
                    amount;
            }
        }
    }

    function _payoutroyalties(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 subtotal
    ) internal returns (uint256) {
        uint256 feesPaid = 0;
        uint256 length = nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients
            .length;
        for (uint256 i = 0; i < length; i++) {
            uint256 fee = _getPortionOfBid(
                subtotal,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feeRecipients[i],
                fee
            );
        }
        return feesPaid;
    }

    ///@dev if the call failed, update their credit balance so they the seller can pull it later
    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;

        if (auctionERC20Token != address(0)) {
            IERC20(auctionERC20Token).transfer(_recipient, _amount);
        } else {
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                      END TRANSFER NFT, PAY SELLER & MARKET
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                        SETTLE & WITHDRAW
    //////////////////////////////////////////////////////////////*/
    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
    {
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionEnd;
        require(
            (block.timestamp > auctionEndTimestamp),
            "Auction has not ended"
        );
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, msg.sender);
    }

    ///@dev Only the owner of the NFT can prematurely close the sale or auction.
    function withdrawAuction(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBidder ==
                address(0) &&
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller ==
                msg.sender,
            "cannot cancel an auction"
        );
        bool lazymint = nftContractAuctions[_nftContractAddress][_tokenId]
            .lazymint;
        if (lazymint) {
            _resetAuction(_nftContractAddress, _tokenId);
            _resetBids(_nftContractAddress, _tokenId);
        } else {
            if (
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this)
            ) {
                IERC721(_nftContractAddress).transferFrom(
                    address(this),
                    nftContractAuctions[_nftContractAddress][_tokenId]
                        .nftSeller,
                    _tokenId
                );
            }
            _resetAuction(_nftContractAddress, _tokenId);
            _resetBids(_nftContractAddress, _tokenId);
        }
        emit AuctionWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                         END  SETTLE & WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                          UPDATE AUCTION
    //////////////////////////////////////////////////////////////*/
    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newMinPrice
    ) public priceGreaterThanZero(_newMinPrice) {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        require(
            (nftContractAuctions[_nftContractAddress][_tokenId].minPrice != 0),
            "Not applicable a sale"
        );
         require(
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBidder != address(0), 
                "auction with bidder"
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice = _newMinPrice;
        nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBid = _newMinPrice;

        emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);
    }

    function updateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newBuyNowPrice
    ) external priceGreaterThanZero(_newBuyNowPrice) {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            bool lazymint = nftContractAuctions[_nftContractAddress][_tokenId]
                .lazymint;
            if (!lazymint) {
                _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            }
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        }
    }

    ///@notice The NFT seller can opt to end an auction by taking the current highest bid.
    function takeHighestBid(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        require(
            (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >
                0),
            "cannot payout 0 bid"
        );
        bool lazymint = nftContractAuctions[_nftContractAddress][_tokenId]
            .lazymint;
        if (!lazymint) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        }
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestBidTaken(_nftContractAddress, _tokenId);
    }

    ///@notice If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{value: amount}("");
        require(successfulWithdraw, "withdraw failed");
    }

    /*///////////////////////////////////////////////////////////////
                        END UPDATE AUCTION
    //////////////////////////////////////////////////////////////*/
}