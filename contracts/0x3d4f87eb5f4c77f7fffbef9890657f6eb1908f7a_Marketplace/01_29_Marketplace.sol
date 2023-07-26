// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IArtxchainsERC1155.sol";
import "./interfaces/IMarketplace.sol";

contract Marketplace is OwnableUpgradeable, ERC1155Receiver, IMarketplace, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_BASIC_POINTS = 10000;
    uint256 public constant MIN_DURATION_AUCTION = 1 days;
    uint256 public constant MAX_DURATION_AUCTION = 14 days;
    uint256 public constant MIN_DURATION_FIXED = 1 days;
    uint256 public constant MAX_DURATION_FIXED = 180 days;
    uint256 public constant TOKEN_AMOUNT = 1;
    uint256 public constant MARKETPLACE_FIRST_COMMISSION_LIMIT = 1250; //12,5%
    uint256 public constant MARKETPLACE_COMMISSION = 300; //3%

    address public marketplaceSaleBeneficiary;
    uint256 public marketplaceFirstCommission;

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionIdCounter;
    mapping(address=> mapping(uint256 => bool)) public nftFirstTimeSold;
    mapping(uint256 => FixedPriceSale) public fixedPriceSales;
    mapping(address => mapping(uint256 => uint256)) public nftToTokenIdToFixedPriceSaleId;
    uint256 public fixedPriceSaleIdCounter;

    function initialize(address _marketplaceSaleBeneficiary, uint256 _marketplaceFirstCommission /**in basic points*/) public initializer {
        require(_marketplaceFirstCommission <= MARKETPLACE_FIRST_COMMISSION_LIMIT, "Marketplace commission is too high!");
        marketplaceSaleBeneficiary = _marketplaceSaleBeneficiary;
        marketplaceFirstCommission = _marketplaceFirstCommission;
        __Ownable_init();
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4) {
      return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}

    /**
    * @dev Creates an auction for a specified ERC1155 NFT token.
    * @param erc20Address The address of the ERC20 Token witch will be used to bid.
    * @param erc1155NFTAddress The address of the ERC1155 NFT contract.
    * @param tokenId The ID of the token being auctioned.
    * @param minPriceSell The minimum price at which the NFT can be sold.
    * @param minBidStep The minimum increase in the current bid.
    * @param startTime Date of start auction in seconds, if 0 it's now.
    * @param auctionDuration The duration of the auction.
    * @notice The marketplace has to be approved from ArtxchainsERC1155.
    * @notice The NFT being auctioned will be transferred to this contract.
    */
    function createAuction(address erc20Address, address erc1155NFTAddress, uint256 tokenId, uint256 minPriceSell, uint256 minBidStep, uint256 startTime, uint256 auctionDuration) public {
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(erc1155NFTAddress);
        require(erc1155NFT.balanceOf(msg.sender, tokenId) > 0, "You don't own the NFT");
        require(auctionDuration >= MIN_DURATION_AUCTION && auctionDuration <= MAX_DURATION_AUCTION,"Auction duration out of range");
        if(startTime == 0) {
            startTime = block.timestamp;
        }
        require(startTime >= block.timestamp, "Start time must be greater or equal to block time");
        // transfer NFT to this contract
        erc1155NFT.safeTransferFrom(msg.sender, address(this), tokenId, TOKEN_AMOUNT, "");
        auctionIdCounter++;
        Auction storage auction = auctions[auctionIdCounter];
        auction.seller = msg.sender;
        auction.tokenId = tokenId;
        auction.minPriceSell = minPriceSell;
        auction.minBidStep = minBidStep;
        auction.startTime = startTime;
        auction.endTime = startTime + auctionDuration;
        auction.erc1155NFT = erc1155NFTAddress;
        auction.erc20 = erc20Address;
        auction.status = AUCTION_STATUS.IN_PROGRESS;
        emit AuctionCreated(auctionIdCounter, msg.sender, erc1155NFTAddress, tokenId, minPriceSell, minBidStep, startTime, auction.endTime);
    }

    /**
    * @dev Allows a user to place a bid on an auction.
    * @param auctionId The ID of the auction to place a bid on.
    * @param bidValue The value of the bid to place.
    * @notice The marketplace has to be approved to spend the tokens from ERC20 contract.
    */
    function placeBid(uint256 auctionId, uint256 bidValue) public {
        require(auctionId > 0 && auctionId <= auctionIdCounter, "Auction id not exist");
        Auction storage auction = auctions[auctionId];
        IERC20 erc20 = IERC20(auction.erc20);
        require(erc20.balanceOf(msg.sender) >= bidValue, "You don't have enough erc20");
        require(erc20.allowance(msg.sender, address(this)) >= bidValue, "You have to approve Marketplace spend the value of bid");
        require(getAuctionState(auctionId) == AUCTION_STATUS.IN_PROGRESS, "Auction not in progress");
        require(msg.sender != auction.lastBidder, "You are already winning the bid"); 
        require(bidValue >= auction.minPriceSell, "You have to bid at least the minimum price of NFT");
        require(
            bidValue >= auction.currentBid + auction.minBidStep,
            "Bid must be at least minBidStep greater than previous bid"
        );
        if (auction.lastBidder != address(0)) {
            // Refund previous highest bidder
            erc20.transferFrom(address(this), auction.lastBidder, auction.currentBid);
        }
        // Transfer erc20 from msg.sender to this contract
        erc20.transferFrom(msg.sender, address(this), bidValue);
        auction.lastBidder = msg.sender;
        auction.currentBid = bidValue;
        auction.lastBidTime = block.timestamp;
        emit LastBlockNumberBid(auction.blockNumber);
        auction.blockNumber = block.number;
        emit BidPlaced(auctionId, msg.sender, bidValue);
    }
    
    /**
    * @dev Settles an auction, transferring the highest bid to the seller minus commission,
    * and transferring the commission to royalty receiver.
    * Refunds the last bidder if the highest bid is lower than the minimum price.
    * Transfers the NFT to the winner.
    * @param auctionId The ID of the auction to settle.
    */
    function settle(uint256 auctionId) public { 
        require(auctionId > 0 && auctionId <= auctionIdCounter, "Auction id not exist");
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime && block.timestamp - auction.lastBidTime > 15 minutes, "Auction time has not ended yet");
        require(auction.status == AUCTION_STATUS.IN_PROGRESS && getAuctionState(auctionId) == AUCTION_STATUS.SUCCESSFUL, "Auction cannot be settled");        
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(auction.erc1155NFT);
        IERC20 erc20 = IERC20(auction.erc20);
        _concludeSale(erc1155NFT, erc20, auction.tokenId, auction.currentBid, auction.seller, auction.lastBidder, address(this));
        auction.status = AUCTION_STATUS.SUCCESSFUL;
        emit AuctionEnded(auctionId, auction.seller, auction.erc1155NFT, auction.tokenId, auction.lastBidder, auction.currentBid);
    }

    function getAuctionState(uint256 auctionId) public view returns (AUCTION_STATUS) {
        Auction storage auction = auctions[auctionId];
        if (auction.status == AUCTION_STATUS.CANCELLED) {
            return AUCTION_STATUS.CANCELLED;
        }
        if (auction.status == AUCTION_STATUS.SUCCESSFUL) {
            return AUCTION_STATUS.SUCCESSFUL;
        }
        if (block.timestamp >= auction.startTime && (block.timestamp - auction.lastBidTime < 15 minutes)) {
            return AUCTION_STATUS.IN_PROGRESS;
        }
        if (block.timestamp >= auction.endTime && (block.timestamp - auction.lastBidTime > 15 minutes)) { 
            if (auction.currentBid >= auction.minPriceSell) {
                return AUCTION_STATUS.SUCCESSFUL;
            } else {
                return AUCTION_STATUS.FAILED;
            }  
        }
        if (block.timestamp < auction.startTime) {
            return AUCTION_STATUS.IN_PENDING;
        } else {
            return AUCTION_STATUS.IN_PROGRESS;
        }
    }

    /**
    * @dev Creates a fixed price sale for a specified ERC1155 NFT token.
    * @param erc20Address The address of the ERC20 Token witch will be used for purchase.
    * @param erc1155NFTAddress The address of the ERC1155 NFT contract.
    * @param tokenId The ID of the token being sold.
    * @param startTime Date of start fixed sale in seconds, if 0 it's now.
    * @param fixedPriceSaleDuration The duration of fixed sale.
    * @param price The fixed price at which the NFT will be sold.
    * @notice The marketplace has to be approved from ArtxchainsERC1155.
    * @notice The NFT being sold will be transferred to this contract.
    */
    function createFixedPriceSale(address erc20Address, address erc1155NFTAddress, uint256 tokenId, uint256 startTime, uint256 fixedPriceSaleDuration, uint256 price) public {
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(erc1155NFTAddress);
        require(erc1155NFT.balanceOf(msg.sender, tokenId) > 0, "You don't own the NFT");
        require(price > 0, "Price must be greater than zero");
        require(fixedPriceSaleDuration >= MIN_DURATION_FIXED && fixedPriceSaleDuration <= MAX_DURATION_FIXED,"Fixed price sale duration out of range");
        if(startTime == 0) {
            startTime = block.timestamp;
        }
        require(startTime >= block.timestamp, "Start time must be greater or equal to block time");
        erc1155NFT.safeTransferFrom(msg.sender, address(this), tokenId, TOKEN_AMOUNT, "");
        fixedPriceSaleIdCounter++;
        nftToTokenIdToFixedPriceSaleId[erc1155NFTAddress][tokenId] = fixedPriceSaleIdCounter;
        FixedPriceSale storage fixedPriceSale = fixedPriceSales[fixedPriceSaleIdCounter];
        fixedPriceSale.seller = msg.sender;
        fixedPriceSale.erc1155NFT = erc1155NFTAddress;
        fixedPriceSale.tokenId = tokenId;
        fixedPriceSale.startTime = startTime;
        fixedPriceSale.endTime = startTime + fixedPriceSaleDuration;
        fixedPriceSale.price = price;
        fixedPriceSale.erc20 = erc20Address;
        fixedPriceSale.status = FIXED_PRICE_STATUS.IN_PROGRESS;
        emit FixedPriceSaleCreated(fixedPriceSaleIdCounter, msg.sender, erc1155NFTAddress, tokenId, startTime, fixedPriceSale.endTime, price);
    }

    /**
    * @dev Allows a user to place a bid on an auction.
    * @param fixedPriceSaleId The ID of the fixed price sale to buy.
    * @notice The marketplace has to be approved to spend the tokens from ERC20 contract.
    */
    function buyFixedPriceSale(uint256 fixedPriceSaleId) public {
        require(fixedPriceSaleId <= fixedPriceSaleIdCounter, "Fixed price id not exist");
        FixedPriceSale storage fixedPriceSale = fixedPriceSales[fixedPriceSaleId];
        require(fixedPriceSale.status == FIXED_PRICE_STATUS.IN_PROGRESS, "Fixed price sale not available");
        require(block.timestamp >= fixedPriceSale.startTime && block.timestamp <= fixedPriceSale.endTime, "Fixed price sale time error");
        IERC20 erc20 = IERC20(fixedPriceSale.erc20);
        require(erc20.balanceOf(msg.sender) >= fixedPriceSale.price, "You don't have enough erc20");
        require(erc20.allowance(msg.sender, address(this)) >= fixedPriceSale.price, "You have to approve Marketplace spend the price of sale");
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(fixedPriceSale.erc1155NFT);
        _concludeSale(erc1155NFT, erc20, fixedPriceSale.tokenId, fixedPriceSale.price, fixedPriceSale.seller, msg.sender, msg.sender);
        fixedPriceSale.status = FIXED_PRICE_STATUS.SUCCESSFUL;
        emit FixedPriceSaleEnded(fixedPriceSaleId, fixedPriceSale.seller, fixedPriceSale.erc1155NFT, fixedPriceSale.tokenId, msg.sender, fixedPriceSale.price);
    }

    /**
    * @dev Allows the seller to cancel the auction.
    * @param auctionId The ID of the auction to cancel.
    */
    function cancelAuction(uint256 auctionId) public {
        require(auctionId > 0 && auctionId <= auctionIdCounter, "Auction id not exist");
        Auction storage auction = auctions[auctionId];
        require(auction.seller == msg.sender, "You are not the seller of this auction");
        require(block.timestamp < auction.startTime || getAuctionState(auctionId) == AUCTION_STATUS.FAILED, "Cannot delete, auction is still in progress");
        auction.status = AUCTION_STATUS.CANCELLED;
        // Transfer NFT back to seller
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(auction.erc1155NFT);
        erc1155NFT.safeTransferFrom(address(this), auction.seller, auction.tokenId, TOKEN_AMOUNT, "");
        emit AuctionCancelled(auctionId, auction.seller, auction.erc1155NFT, auction.tokenId);
    }

    /**
    * @dev Allows the seller to cancel the fixed price sell.
    * @param fixedPriceSaleId The ID of the fixed price sell to cancel.
    */
    function cancelFixedPriceSale(uint256 fixedPriceSaleId) public {
        require(fixedPriceSaleId <= fixedPriceSaleIdCounter, "Fixed price id not exist");
        FixedPriceSale storage fixedPriceSale = fixedPriceSales[fixedPriceSaleId];
        require(fixedPriceSale.status == FIXED_PRICE_STATUS.IN_PROGRESS, "IS NOT ON SALE");
        require(msg.sender == fixedPriceSale.seller, "Only seller can delete the fixed price sale");
        fixedPriceSale.status = FIXED_PRICE_STATUS.CANCELLED;
        // // Transfer NFT back to seller
        IArtxchainsERC1155 erc1155NFT = IArtxchainsERC1155(fixedPriceSale.erc1155NFT);
        erc1155NFT.safeTransferFrom(address(this), fixedPriceSale.seller, fixedPriceSale.tokenId, TOKEN_AMOUNT, "");
        emit FixedPriceSaleCancelled(fixedPriceSaleId, fixedPriceSale.seller , fixedPriceSale.erc1155NFT, fixedPriceSale.tokenId);
    }

    function _concludeSale(IArtxchainsERC1155 erc1155NFT, IERC20 erc20, uint256 tokenId, uint256 price, address seller, address buyer, address fromAddress) private {
        uint256 marketplaceCommission;
        {
            uint256 standardCommission = price.mul(MARKETPLACE_COMMISSION).div(MAX_BASIC_POINTS);
            if(!nftFirstTimeSold[address(erc1155NFT)][tokenId]) {
                marketplaceCommission = price.mul(marketplaceFirstCommission).div(MAX_BASIC_POINTS) + standardCommission;
                nftFirstTimeSold[address(erc1155NFT)][tokenId] = true;
            } else {
                marketplaceCommission = standardCommission;
            }
        }

        address receiver;
        uint256 royaltyAmount;
        (bool success, bytes memory data) = address(erc1155NFT).call(abi.encodeWithSignature("royaltyInfo(uint256,uint256)", tokenId, price));
        if (success && data.length > 0) {
            (receiver, royaltyAmount) = abi.decode(data, (address, uint256));
        } 
       
        // Transfer sell price to seller minus commission
        uint256 payout = price - marketplaceCommission - royaltyAmount;
        erc20.safeTransferFrom(fromAddress, seller, payout);
        // Transfer commission to treasury
        (success, ) = address(receiver).call(abi.encodeWithSignature("receiveRoyalty(uint256,uint256)", tokenId, royaltyAmount));
        erc20.safeTransferFrom(fromAddress, receiver, royaltyAmount);
        // Transfer marketplaceCommission to marketplaceSaleBeneficiary
        erc20.safeTransferFrom(fromAddress, marketplaceSaleBeneficiary, marketplaceCommission);
        // Transfer NFT to buyer
        erc1155NFT.safeTransferFrom(address(this), buyer, tokenId, TOKEN_AMOUNT, "");
    }

    function getFixedPriceStatus(uint256 fixedPriceSaleId) public view returns (FIXED_PRICE_STATUS) {
        return fixedPriceSales[fixedPriceSaleId].status;
    }

    function setMarketplaceSaleBeneficiary(address _marketplaceSaleBeneficiary) public onlyOwner {
        marketplaceSaleBeneficiary = _marketplaceSaleBeneficiary;
    }
}