// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../common/ERC2771ContextUpgradeable.sol";
import "../token/HugmaNFT.sol";
import "../token/MultiNFT.sol";
import "./component/FeeComp.sol";
import "./component/RoyaltyComp.sol";
import "./component/BidComp.sol";
import "./ExchangeDomain.sol";
import "../common/ForwarderUpgradeable.sol";

contract Exchange is ExchangeDomain, Initializable, ERC2771ContextUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, FeeComp, RoyaltyComp, BidComp {
    event CreateAndSell(address seller, address token, uint256 tokenId, uint256 tomenAmount, uint256 price, bool isTimedAuction);
    event BuyMatchSell(address buyer, address seller, address token, uint256 tokenId, uint256 tomenAmount, uint256 price);

    event Sell(address seller, address token, uint256 tokenId, uint256 tomenAmount, uint256 price);
    event Buy(address buyer, address seller, address token, uint256 tokenId, uint256 tomenAmount, uint256 price);
    event Bid(address bider, address token, uint256 tokenId, uint256 tomenAmount, uint256 price);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(address forwarder, address feeReceiver, uint256 feeFraction) initializer public {
        __UUPSUpgradeable_init();
        __ERC2771ContextUpgradeable_init(forwarder);

        __FeeComp_init(feeReceiver, feeFraction);

        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    // 挂单售卖NFT
    function sell(SellRequest calldata sellReq) public {
        if (sellReq.asset.assetType == LibAsset.AssetType.ERC721) {
            HugmaNFT singleNft = HugmaNFT(sellReq.asset.token);
            require(singleNft.getApproved(sellReq.asset.tokenId) == address(this), "Exchange: There is no authorization to swap");
        }
        else if (sellReq.asset.assetType == LibAsset.AssetType.ERC1155){
            MultiNFT multiNft = MultiNFT(sellReq.asset.token);
            require(multiNft.isApprovedForAll(_msgSender(), address(this)),"Exchange: There is no authorization to swap");
            require(multiNft.balanceOf(_msgSender(), sellReq.asset.tokenId) >= sellReq.asset.tokenAmount, "Exchange: The NFT balance is insufficient");
        }
        
        sellinfos[_msgSender()][sellReq.asset.token][sellReq.asset.tokenId] = SellInfo(sellReq.asset.tokenAmount, sellReq.currency, sellReq.price, address(0), 0, sellReq.isTimedAuction, sellReq.expirationTime, false);

        emit Sell(_msgSender(), sellReq.asset.token, sellReq.asset.tokenId, sellReq.asset.tokenAmount, sellReq.price);
    }

    // 下架正在售卖的NFT
    function offmaket(LibAsset.Asset memory asset)
        public
    {
        SellInfo memory sellInfo = sellinfos[_msgSender()][asset.token][asset.tokenId];
        require(sellInfo.tokenAmount >= 1, "Exchange: The NFT is not sold on the platform");

        delete sellinfos[_msgSender()][asset.token][asset.tokenId];
    }

    // 购买已挂单售卖的NFT
    function buy(BuyRequest calldata buyReq) 
        public 
        payable
    {
        _swap(buyReq);

        emit Buy(_msgSender(), buyReq.seller, buyReq.asset.token, buyReq.asset.tokenId, buyReq.asset.tokenAmount, msg.value);
    }

    // 创建并售卖NFT
    function createAndSell(CreateAndSellRequest calldata createAndSellReq) 
        onlyRole(MINTER_ROLE)
        public {
        if (createAndSellReq.isTimedAuction && sellinfos[_msgSender()][createAndSellReq.asset.token][createAndSellReq.asset.tokenId].tokenAmount != 0) {

        }
        else{

            if (createAndSellReq.asset.assetType == LibAsset.AssetType.ERC721) {
                HugmaNFT singleNft = HugmaNFT(createAndSellReq.asset.token);
                singleNft.exchangeMint(_msgSender(), createAndSellReq.asset.tokenId, createAndSellReq.uri, address(this), _msgSender(), createAndSellReq.royalty);
            }
            else if (createAndSellReq.asset.assetType == LibAsset.AssetType.ERC1155){
                MultiNFT multiNft = MultiNFT(createAndSellReq.asset.token);
                multiNft.exchangeMint(_msgSender(), createAndSellReq.asset.tokenId, createAndSellReq.asset.tokenAmount,  createAndSellReq.uri, _msgSender(), createAndSellReq.royalty, address(this));
            }

            sellinfos[_msgSender()][createAndSellReq.asset.token][createAndSellReq.asset.tokenId] = SellInfo(createAndSellReq.asset.tokenAmount, createAndSellReq.currency, createAndSellReq.price, address(0), 0, createAndSellReq.isTimedAuction, createAndSellReq.expirationTime, false);

            emit CreateAndSell(_msgSender(), createAndSellReq.asset.token, createAndSellReq.asset.tokenId, createAndSellReq.asset.tokenAmount, createAndSellReq.price, createAndSellReq.isTimedAuction);
        }
    }

    // 购买通过元交易创建售卖的NFT
    function buyMatchSell(ForwarderUpgradeable.ForwardRequest calldata createAndSellReq, bytes calldata createAndSellSignature, BuyRequest calldata buyReq)
        public
        payable
    {
        bool execOk;
        (execOk, ) = ForwarderUpgradeable(_trustedForwarder).execute(createAndSellReq, createAndSellSignature);
        require(execOk,"Exchange: Exec createAndSell faild");

        _swap(buyReq);

        emit BuyMatchSell(_msgSender(), buyReq.seller, buyReq.asset.token, buyReq.asset.tokenId, buyReq.asset.tokenAmount, msg.value);
    }

    function bid(ForwarderUpgradeable.ForwardRequest calldata createAndSellReq, bytes calldata createAndSellSignature, BidRequest calldata bidReq) 
        public
        payable
    {
        bool execOk;
        (execOk, ) = ForwarderUpgradeable(_trustedForwarder).execute(createAndSellReq, createAndSellSignature);
        require(execOk,"Exchange: Exec createAndSell faild");

        SellInfo storage sellInfo = sellinfos[bidReq.seller][bidReq.asset.token][bidReq.asset.tokenId];
        
        require(sellInfo.isTimedAuction, "Exchange: not timedauction order");

        require(sellInfo.sold == false, "Exchange: token sold");
        require(sellInfo.expirationTime >= block.timestamp, "Exchange: the bid time is over");

        require((bidReq.price >= sellInfo.price),"Exchange: match price faild");
        require((bidReq.price > sellInfo.lastBid),"Exchange: too low price");

        if(sellInfo.currency == address(0)){
            require(bidReq.price == msg.value, "Exchange: eth amount not match");
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(sellInfo.currency);
            require(erc20.transferFrom(_msgSender(), address(this), bidReq.price), "BidComp: Bid with ERC20 token failed");
        }

        if(sellInfo.lastBidder != address(0)){
            _returnBid(sellInfo.lastBidder, sellInfo.currency, sellInfo.lastBid);
        }

        sellInfo.lastBid = bidReq.price;
        sellInfo.lastBidder = _msgSender();
    }

    function rewardBid(RewardBidRequest calldata rewardBidReq) public {
        SellInfo storage sellInfo = sellinfos[rewardBidReq.seller][rewardBidReq.asset.token][rewardBidReq.asset.tokenId];

        require(canReward(CanRewardBidRequest(rewardBidReq.seller,rewardBidReq.asset.token,rewardBidReq.asset.tokenId)),"");

        sellInfo.sold = true;

        if (rewardBidReq.asset.assetType == LibAsset.AssetType.ERC721) {
            HugmaNFT singleNft = HugmaNFT(rewardBidReq.asset.token);
            singleNft.transferFrom(rewardBidReq.seller, _msgSender(), rewardBidReq.asset.tokenId);
        }
        else if (rewardBidReq.asset.assetType == LibAsset.AssetType.ERC1155){
            MultiNFT multiNft = MultiNFT(rewardBidReq.asset.token);
            multiNft.safeTransferFrom(rewardBidReq.seller, _msgSender(), rewardBidReq.asset.tokenId, rewardBidReq.asset.tokenAmount, "Transfer by Exchange");
        }

        uint256 feeAmount = _payFee(sellInfo.currency, sellInfo.lastBid);
        uint256 royaltyAmount = _payRoyalty(rewardBidReq.asset.token, rewardBidReq.asset.tokenId, sellInfo.currency, sellInfo.lastBid);
        uint256 remainingAmount = sellInfo.lastBid - feeAmount - royaltyAmount;

        if(sellInfo.currency == address(0)){
            payable(rewardBidReq.seller).transfer(remainingAmount);
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(sellInfo.currency);
            require(erc20.transfer(rewardBidReq.seller, remainingAmount), "BidComp: Bid with ERC20 token failed");
        }
    }

    function canReward(CanRewardBidRequest memory req) public view returns(bool){
        SellInfo memory sellInfo = sellinfos[req.seller][req.token][req.tokenId];

        require(sellInfo.sold == false, "Exchange: token sold");
        require(sellInfo.expirationTime < block.timestamp, "Exchange: the bid time is not over");
        require(sellInfo.lastBidder == _msgSender(), "Exchange: You are not the winning bidder");

        return true;
    }

    function _swap(BuyRequest calldata buyReq) internal {
        SellInfo memory sellInfo = sellinfos[buyReq.seller][buyReq.asset.token][buyReq.asset.tokenId];

        require(sellInfo.sold == false, "Exchange: token sold");
        require(sellInfo.isTimedAuction == false, "Exchange: not fixedprice order");
        require((sellInfo.tokenAmount == buyReq.asset.tokenAmount),"Exchange: match tokenAmount faild"); 

        sellinfos[buyReq.seller][buyReq.asset.token][buyReq.asset.tokenId].sold = true;

        if (buyReq.asset.assetType == LibAsset.AssetType.ERC721) {
            HugmaNFT singleNft = HugmaNFT(buyReq.asset.token);
            singleNft.transferFrom(buyReq.seller, _msgSender(), buyReq.asset.tokenId);
        }
        else if (buyReq.asset.assetType == LibAsset.AssetType.ERC1155){
            MultiNFT multiNft = MultiNFT(buyReq.asset.token);
            multiNft.safeTransferFrom(buyReq.seller, _msgSender(), buyReq.asset.tokenId, buyReq.asset.tokenAmount, "Transfer by Exchange");
        }

        if(sellInfo.currency != address(0)){
            IERC20Upgradeable erc20 =  IERC20Upgradeable(sellInfo.currency);
            require(erc20.transferFrom(_msgSender(), address(this), sellInfo.price), "Exchange: buy with ERC20 token failed");
        }
        
        uint256 feeAmount = _payFee(sellInfo.currency, sellInfo.price);
        uint256 royaltyAmount = _payRoyalty(buyReq.asset.token, buyReq.asset.tokenId, sellInfo.currency, sellInfo.price);
        uint256 remainingAmount = sellInfo.price - feeAmount - royaltyAmount;

        if(sellInfo.currency == address(0)){
            payable(buyReq.seller).transfer(remainingAmount);
        }else{
            IERC20Upgradeable erc20 =  IERC20Upgradeable(sellInfo.currency);
            require(erc20.transfer(buyReq.seller, remainingAmount), "Exchange: buy with ERC20 token failed");
        }
    }
}