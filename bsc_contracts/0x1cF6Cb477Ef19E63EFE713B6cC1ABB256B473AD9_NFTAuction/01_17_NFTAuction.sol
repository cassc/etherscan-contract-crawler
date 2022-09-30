// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/INFTAuction.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";
import {SafeMath} from "../lib/SafeMath.sol";


contract NFTAuction is INFTAuction, ERC721Holder, OwnableUpgradeable, PausableUpgradeable{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public treasury;
    IERC20 public bibContract;
    IERC20 public busdContract;
    IFeeCollector public feeCollector;

    mapping(uint256 => Auction) public Auctions;
    // mapping token->token_id->auction_id
    mapping(address=>mapping(uint=>uint)) public tokenAuctionTb;
    uint256 numAuctions;

    uint public feeRatio;
    uint public royaltyRatio;
    uint public constant FEE_RATIO_DIV = 1000;

    // nft token issuered by the protocol
    address protocolToken;

    event BIBContractChanged(address sender, address oldValue, address newValue);
    event BUSDContractChanged(address sender, address oldValue, address newValue);
    event FeeRatioChanged(address sender, uint oldValue, uint newValue);
    event RoyaltyRatioChanged(address sender, uint oldValue, uint newValue);
    event FeeCollectorChanged(address sender, address oldValue, address newValue);
    event ProtocolTokenChanged(address sender, address oldValue, address newValue);

    function initialize(
        address _bibContract,
        address _busdContract,
        address _treasury,
        address _protocolToken
    ) public reinitializer(1){
        treasury = _treasury;
        bibContract = IERC20(_bibContract);
        busdContract = IERC20(_busdContract);
        protocolToken = _protocolToken;

        feeRatio = 25;
        royaltyRatio = 75;
        numAuctions = 1;

        __Pausable_init();
        __Ownable_init();
    }


    function setBIBContract(address _bibContract) public onlyOwner{
        require(address(0) != _bibContract, "INVALID_ADDRESS");
        emit BIBContractChanged(msg.sender, address(bibContract), _bibContract);
        bibContract = IERC20(_bibContract);
    }

    function setBUSDContract(address _busdContract) public onlyOwner{
        require(address(0) != _busdContract, "INVALID_ADDRESS");
        emit BUSDContractChanged(msg.sender, address(busdContract), _busdContract);
        busdContract = IERC20(_busdContract);
    }

    function setProtocolToken(address _protocolToken) public onlyOwner{
        require(address(0) != _protocolToken, "INVALID_ADDRESS");
        emit ProtocolTokenChanged(msg.sender, protocolToken, _protocolToken);
        protocolToken = _protocolToken;
    }

    function setFeeRatio(uint _feeRatio) public override onlyOwner{
        require(_feeRatio <= FEE_RATIO_DIV, "INVALID_RATIO");
        emit FeeRatioChanged(msg.sender,feeRatio, _feeRatio);
        feeRatio = _feeRatio;
    }

    function setRoyaltyRatio(uint _royaltyRatio) override public onlyOwner {
        require(_royaltyRatio <= FEE_RATIO_DIV, "INVALID_ROYALTY_RATIO");
        emit RoyaltyRatioChanged(msg.sender, royaltyRatio, _royaltyRatio);
        royaltyRatio = _royaltyRatio;
    }

    function setFeeCollector(address _feeCollector) public onlyOwner{
        emit FeeCollectorChanged(msg.sender, address(feeCollector), _feeCollector);
        feeCollector = IFeeCollector(_feeCollector);
    }

    function isOwner(address token, uint tokenId, address owner)
    internal  view returns(bool){
        return (owner == IERC721(address(token)).ownerOf(tokenId));
    }

    function isOriginOwner(address token, uint tokenId, address owner)
    public override view returns(bool){
        if(!isOwner(token, tokenId, owner)) {
            Auction memory auction = getAuction(token, tokenId);
            if(address(0) == auction.seller){
                return false;
            } else {
                return auction.seller == owner;
            }
        }
        return true;
    }

    function getAuction(address token, uint tokenId) public override view returns(Auction memory){
        return Auctions[tokenAuctionTb[token][tokenId]];
    }

    function hasAuction(address token, uint tokenId) public override view returns(bool){
        return tokenAuctionTb[token][tokenId] > 0;
    }

    function createAuction(address token, uint256 tokenId, PayMethod payMethod, uint256 minPrice, uint256 expiration) public override whenNotPaused {
        require(token != address(0), "token error");
        require(expiration > block.timestamp, "time error");
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId, "");

        uint256 auctionId = numAuctions++;
        // record auction
        Auction memory auction = Auction({
            token: token,
            tokenId: tokenId,
            seller: payable(msg.sender),
            payMethod: payMethod,
            bidder: payable(address(0)),
            price: minPrice,
            finished: false,
            expiration: expiration
        });

        Auctions[auctionId] = auction;
        tokenAuctionTb[token][tokenId] = auctionId;

        emit CreateAuction(auctionId, msg.sender, token, tokenId, payMethod, minPrice, expiration);
    }

    function bid(uint256 auctionId, uint256 price) public override payable whenNotPaused{
        Auction storage auction = Auctions[auctionId];
        require(auction.expiration >= block.timestamp, "time error");
        if (auction.bidder == address(0)) {
            require(auction.price <= price, "price error");
        } else {
            require(auction.price < price, "price error");
        }
        require(auction.finished == false, "auction finished");

        //BNB
        if (auction.payMethod == PayMethod.PAY_BNB) {
            require(msg.value == price, "value error");
            if (auction.bidder != address(0)) {
                auction.bidder.transfer(auction.price);
            }
        } else if (auction.payMethod == PayMethod.PAY_BUSD) {
            busdContract.safeTransferFrom(msg.sender, address(this), price);
            if (auction.bidder != address(0)) {
                busdContract.safeTransfer(auction.bidder, auction.price);
            }
        } else {
            bibContract.safeTransferFrom(msg.sender, address(this), price);
            if (auction.bidder != address(0)) {
                bibContract.safeTransfer(auction.bidder, auction.price);
            }
        }

        auction.price = price;
        auction.bidder = payable(msg.sender);

        emit Bid(auctionId, msg.sender, price);
    }

    function finishAuction(uint256 auctionId)  public override whenNotPaused {
        Auction memory auction = Auctions[auctionId];
        require(auction.expiration < block.timestamp, "time error");
        require(auction.finished == false, "auction finished");
        require(auction.bidder != address(0), "no bidder");
        require(msg.sender == auction.bidder || msg.sender == auction.seller);
        Auctions[auctionId].finished = true;

        // caculate fees
        (uint txFee, uint royaltyFee ) = caculateFees(auction.price);
        uint fees = txFee.add(royaltyFee);
        uint amount = auction.price.sub(fees);

        if (auction.payMethod == PayMethod.PAY_BNB) {
            auction.seller.transfer(amount);

            distributeFee(PayMethod.PAY_BNB, fees);
        } else if (auction.payMethod == PayMethod.PAY_BUSD) {
            busdContract.safeTransfer(auction.seller, amount);

            distributeFee(PayMethod.PAY_BUSD, fees);
        } else {
            bibContract.safeTransfer(auction.seller, amount);

            distributeFee(PayMethod.PAY_BIB, fees);
        }

        IERC721(auction.token).safeTransferFrom(address(this), auction.bidder, auction.tokenId, "");
        
        // refund gas
        delete tokenAuctionTb[auction.token][auction.tokenId];
        delete Auctions[auctionId];

        emit FinishAuction(auctionId, auction.seller, auction.token, auction.tokenId, auction.bidder, auction.payMethod, auction.price, auction.expiration, fees);
    }

    function cancelAuction(uint256 auctionId) public override whenNotPaused {
        Auction memory auction = Auctions[auctionId];
        require(auction.finished == false, "auction finished");
        require(auction.seller == msg.sender, "no owner");
        require(auction.bidder == address(0), "already have bidder");

        IERC721(auction.token).safeTransferFrom(address(this), auction.seller, auction.tokenId, "");

        // refund gas
        delete tokenAuctionTb[auction.token][auction.tokenId];
        delete Auctions[auctionId];

        emit CancelAuction(auctionId, msg.sender);
    }

    function caculateFees(uint amount) view public returns(uint, uint){
        // exchange fee + royaltyRatio fee
        return (amount.mul(feeRatio).div(FEE_RATIO_DIV), amount.mul(royaltyRatio).div(FEE_RATIO_DIV));
    }

    function distributeFee(PayMethod payMethod, uint fees) internal {
        if(payMethod == PayMethod.PAY_BNB) {
            if(address(0) != address(feeCollector)) {
                try feeCollector.handleCollectBNB{value:fees}(fees){} catch{}
            } else {
                payable(address(treasury)).transfer(fees);
            }
        } else if(payMethod == PayMethod.PAY_BUSD) {
            if(address(0) != address(feeCollector)) {
                busdContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBUSD(fees) {} catch{}
            } else {
                busdContract.transfer(treasury, fees);
            }
        } else {
            if(address(0) != address(feeCollector)) {
                bibContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBIB(fees) {} catch{}
            } else {
                bibContract.transfer(treasury, fees);
            }
        }
    }
}