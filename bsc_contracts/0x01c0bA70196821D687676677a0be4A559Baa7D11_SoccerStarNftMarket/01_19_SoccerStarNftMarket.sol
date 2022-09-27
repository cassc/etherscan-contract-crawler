//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Ownable} from "../deps/Ownable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {ISoccerStarNft} from "../interfaces/ISoccerStarNft.sol";
import {ISoccerStarNftMarket} from "../interfaces/ISoccerStarNftMarket.sol";
import {IBIBOracle} from "../interfaces/IBIBOracle.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";
import {VersionedInitializable} from "../deps/VersionedInitializable.sol";

contract SoccerStarNftMarket is 
ISoccerStarNftMarket, 
OwnableUpgradeable, 
PausableUpgradeable{
    using SafeMath for uint;

    address public treasury;

    IERC20 public bibContract;
    IERC20 public busdContract;
    ISoccerStarNft public tokenContract;
    IFeeCollector public feeCollector;

    event TokenContractChanged(address sender, address oldValue, address newValue);
    event BIBContractChanged(address sender, address oldValue, address newValue);
    event BUSDContractChanged(address sender, address oldValue, address newValue);
    event FeeRatioChanged(address sender, uint oldValue, uint newValue);
    event RoyaltyRatioChanged(address sender, uint oldValue, uint newValue);
    event FeeCollectorChanged(address sender, address oldValue, address newValue);
    event ProtocolTokenChanged(address sender, address oldValue, address newValue);

    uint public nextOrderIndex;
    uint public nextOfferIndex;

    uint public feeRatio;
    uint public royaltyRatio;
    uint public constant FEE_RATIO_DIV = 1000;

    // mapping order_id to order
    mapping(uint=>Order) public orderTb;

    // mapping issure->token->order_id
    mapping(address=>mapping(uint=>uint)) public tokenOrderTb;

    // orders belong to the specfic owner
    mapping(address=>uint[]) public userOrdersTb;

    // maping offer_id to offer
    mapping(uint=>Offer) public offerTb;

    // mapping issurer=>token=>offer_ids
    mapping(address=>mapping(uint=>uint[])) public tokenOffersTb;

    // mapping user=>offer_ids
    mapping(address=>uint[]) public userOffersTb;

    // nft token issuered by the protocol
    address protocolToken;

    function initialize(
        address _tokenContract,
        address _bibContract,
        address _busdContract,
        address _treasury,
        address _protocolToken
        ) public reinitializer(1) {
        treasury = _treasury;
        tokenContract = ISoccerStarNft(_tokenContract);
        bibContract = IERC20(_bibContract);
        busdContract = IERC20(_busdContract);
        protocolToken = _protocolToken;

        nextOrderIndex = 1;
        nextOfferIndex = 1;

        feeRatio = 25;
        royaltyRatio = 75;

        __Pausable_init();
        __Ownable_init();
    }

    function getBlockTime() public override view returns(uint){
        return block.timestamp;
    }

    function setTokenContract(address _tokenContract) public onlyOwner{
        require(address(0) != _tokenContract, "INVALID_ADDRESS");
        emit TokenContractChanged(msg.sender, address(tokenContract), _tokenContract);
        tokenContract = ISoccerStarNft(_tokenContract);
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

    function setFeeCollector(address _feeCollector) public onlyOwner{
        emit FeeCollectorChanged(msg.sender, address(feeCollector), _feeCollector);
        feeCollector = IFeeCollector(_feeCollector);
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

    function setProtocolToken(address _protocolToken) public onlyOwner{
        require(address(0) != _protocolToken, "INVALID_ADDRESS");
        emit ProtocolTokenChanged(msg.sender, protocolToken, _protocolToken);
        protocolToken = _protocolToken;
    }

    function isOwner(address issuer, uint tokenId, address owner)
     internal  view returns(bool){
        return (owner == IERC721(address(issuer)).ownerOf(tokenId));
    }

    function isOriginOwner(address issuer, uint tokenId, address owner)
     public override view returns(bool){
         if(!isOwner(issuer, tokenId, owner)) {
            Order memory order = getOrder(issuer, tokenId);
            if(address(0) == order.owner){
                return false;
            } else {
                return order.owner == owner;
            }
         }
         return true;
    }

    // user create a order
    function openOrder(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration)
     public override payable whenNotPaused{
        require(address(0) != issuer, "INVALID_ISSURE");
        require(expiration > block.timestamp, "EXPIRATION_TOO_SMALL");
        require(price > 0, "PRICE_NOT_BE_ZEROR");
        require(isOwner(issuer, tokenId, msg.sender), 
        "TOKEN_NOT_BELLONG_TO_SENDER");
   
        // delegate token to protocol
        IERC721(address(issuer)).transferFrom(msg.sender, address(this), tokenId);
        require(isOwner(issuer, tokenId, address(this)), "ERC721_FALED_TRANSFER");

        // record order
        Order memory order = Order({
            issuer: issuer,
            orderId: nextOrderIndex++,
            tokenId: tokenId,
            owner: msg.sender,
            payMethod: payMethod,
            price: price,
            mt: block.timestamp,
            expiration: expiration
        });

        orderTb[order.orderId] = order;
        tokenOrderTb[issuer][tokenId] = order.orderId;
        userOrdersTb[msg.sender].push(order.orderId);

        emit OpenOrder(msg.sender, 
        issuer, order.orderId, tokenId, 
        payMethod, price, order.mt, expiration);
    }

    function updateOrder(uint orderId, PayMethod payMethod, uint price, uint expiration)
    public override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(price > 0, "PRICE_LTE_ZERO");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");
        require(expiration > block.timestamp, "EXPIRATION_TOO_EARLY");
        order.payMethod = payMethod;
        order.price = price;
        order.expiration = expiration;
        order.mt = block.timestamp;

       emit UpdateOrder(msg.sender, 
        order.issuer, order.orderId, order.tokenId, 
        payMethod, price, order.mt, expiration);
    }

    function hasOrder(address issuer, uint tokenId) public override view returns(bool){
        return tokenOrderTb[issuer][tokenId] > 0;
    }

    function getOrder(address issuer, uint tokenId) public override view returns(Order memory){
        return orderTb[tokenOrderTb[issuer][tokenId]];
    }   

    // get orders by page
    function getUserOrdersByPage(address user, uint pageSt, uint pageSz) 
    public view override returns(Order[] memory){
        uint[] storage _orders= userOrdersTb[user];
        Order[] memory ret;

        if(pageSt < _orders.length){
            uint end = pageSt + pageSz;
            end = end > _orders.length ? _orders.length : end;
            ret =  new Order[](end - pageSt);
            for(uint i = 0;pageSt < end; i++){
                ret[i] = orderTb[_orders[pageSt]];
                pageSt++;
            } 
        }

        return ret;
    }

    function caculateFees(uint amount) view public returns(uint, uint ){
        // exchange fee + royaltyRatio fee
        return (amount.mul(feeRatio).div(FEE_RATIO_DIV), amount.mul(royaltyRatio).div(FEE_RATIO_DIV));
    }

    // Owner accept the price
    function collectFeeWhenBuyerAsMaker(PayMethod payMethod, uint fees) internal {
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

    // Buyer accept the price
    function collectFeeWhenSellerAsMaker(PayMethod payMethod, uint fees) internal {
        if(payMethod == PayMethod.PAY_BNB) {
            if(address(0) != address(feeCollector)) {
                try feeCollector.handleCollectBNB{value:fees}(fees) {} catch{}
            } else {
                payable(address(treasury)).transfer(fees);
            }
        } else if(payMethod == PayMethod.PAY_BUSD) {
            if(address(0) != address(feeCollector)) {
                busdContract.transferFrom(msg.sender, address(feeCollector), fees);
                try feeCollector.handleCollectBUSD(fees) {}catch{}
            } else {
                busdContract.transferFrom(msg.sender, treasury, fees);
            }
        } else {
            if(address(0) != address(feeCollector)) {
                bibContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBIB(fees) {}catch{}
            } else {
                bibContract.transfer(treasury, fees);
            }
        }
    }

    // Buyer accept the price and makes a deal with the sepcific order
    function acceptOrder(uint orderId) 
    public  override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender != order.owner, "SHOULD_NOT_BE_ORDER_OWNER");
        require(order.expiration > block.timestamp, "ORDER_EXPIRED");

        // caculate fees
        (uint txFee, uint royaltyFee ) = caculateFees(order.price);
        uint fees = txFee.add(royaltyFee);
        uint amount = order.price.sub(fees);

        // fee + royalty goese to BIB treasury
        if(order.payMethod == PayMethod.PAY_BNB){
            require(msg.value >= order.price, "INSUFFICIENT_FUNDS");
            payable(address(order.owner)).transfer(amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BNB, fees);

            // refunds
            if(msg.value > order.price){
                payable(address(msg.sender)).transfer(msg.value.sub(order.price));
            }
        } else if(order.payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(msg.sender, order.owner, amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BUSD, fees);
        } else {
            // walk around to avoid being charged by the bib token
            bibContract.transferFrom(msg.sender, address(this), order.price);
            bibContract.transfer(order.owner, amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BIB, fees);
        }

        // send token 
        IERC721(address(order.issuer)).transferFrom(address(this), msg.sender, order.tokenId);

        emit MakeDeal(
            msg.sender,
            order.owner,
            msg.sender,
            order.issuer,
            order.tokenId,
            order.payMethod,
            order.price,
            fees);

        (bool exist, Offer memory offer) = getOffer(order.issuer, order.tokenId, msg.sender);
        if(exist){
            cancelOffer(offer.offerId);
        }

        // close order
        _closeOrder(orderId);
    }

    // Owner accept the offer and make a deal
    function acceptOffer(uint offerId) 
    public  override payable whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(address(0) != offer.issuer, "INVALID_OFFER");
        require(msg.sender != offer.buyer, "CANT_MAKE_DEAL_WITH_SELF");
        require(offer.expiration > block.timestamp, "OFFER_EXPIRED");

        // check if has order
        Order memory order = getOrder(offer.issuer, offer.tokenId);
        if(address(0) == order.owner){
            require(isOwner(offer.issuer, offer.tokenId, msg.sender), "NOT_OWNER");
        } else {
            require(order.owner == msg.sender, "NOT_OWNER");
        }

        // caculate sales
       (uint txFee, uint royaltyFee )= caculateFees(offer.bid);
        uint fees = txFee.add(royaltyFee);
        uint amount = offer.bid.sub(fees);

        // fee + royalty goese to BIB treasury
        if(offer.payMethod == PayMethod.PAY_BNB){
            payable(address(msg.sender)).transfer(amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BNB, fees);
        } else if(offer.payMethod == PayMethod.PAY_BUSD){
            busdContract.transfer(msg.sender, amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BUSD, fees);
        } else {
            bibContract.transfer(msg.sender, amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BIB, fees);
        }

        // If has no order then send from owner otherwise send from this
         if(address(0) == order.owner){
            IERC721(address(offer.issuer)).transferFrom(msg.sender, offer.buyer, offer.tokenId);
        } else {
            IERC721(address(offer.issuer)).transferFrom(address(this), offer.buyer, offer.tokenId);
        }
        require(isOwner(offer.issuer, offer.tokenId, offer.buyer), "ERC721_FALED_TRANSFER");

        emit MakeDeal(
            msg.sender,
            msg.sender,
            offer.buyer,
            offer.issuer,
            offer.tokenId,
            offer.payMethod,
            offer.bid,
            fees
        );

        // liquadity offer and order if exist
        if(order.owner == msg.sender){
            _closeOrder(order.orderId);
        }

        _cancleOffer(offerId);
    }
    
    // Owner updates order price
    function updateOrderPrice(uint orderId, uint price) 
    public override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");
        require(order.expiration > block.timestamp, "ORDER_EXPIRED");
        require(price > 0, "PRICE_LTE_ZERO");

        emit UpdateOrderPrice(msg.sender, orderId, order.price, price);
        order.price = price;
        order.mt = block.timestamp;
    }

    function _closeOrder(uint orderId) internal {
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");

        uint[] storage userOrders = userOrdersTb[order.owner];
        for(uint i = 0; i < userOrders.length; i++){
           if(orderTb[userOrders[i]].orderId == orderId){
                userOrders[i] = userOrders[userOrders.length - 1];
                userOrders.pop();
                break;
           }
        }

        delete orderTb[orderId];
        delete tokenOrderTb[order.issuer][order.tokenId];
        
        emit CloseOrder(msg.sender, orderId);
    }

    // Owner close the specific order if not dealed
    function closeOrder(uint orderId)
     public override whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");

        IERC721(address(order.issuer)).transferFrom(address(this), order.owner, order.tokenId);
        
        _closeOrder(orderId);
    }

    function hasOffer(address issuer, uint tokenId, address user) 
    public view returns(bool){
        uint[] storage offserIds = tokenOffersTb[issuer][tokenId];
        for(uint i = 0; i < offserIds.length; i++){
            if(offerTb[offserIds[i]].buyer == user){
                return true;
            }
        }
        return false;
    } 

    function getOffer(address issuer, uint tokenId, address user) 
    public view returns(bool, Offer memory){
        Offer memory ret;
        uint[] storage offserIds = tokenOffersTb[issuer][tokenId];
        for(uint i = 0; i < offserIds.length; i++){
            if(offerTb[offserIds[i]].buyer == user){
                return (true, offerTb[offserIds[i]]);
            }
        }
        return (false, ret);
    } 

    // Buyer make a offer to the specific order
    function makeOffer(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration)
     public override payable whenNotPaused{
        require(address(0) != issuer,"INVALID_ADDRESS");
        require(!isOwner(issuer, tokenId, msg.sender), "CANT_MAKE_OFFER_WITH_SELF");
        require(!hasOffer(issuer, tokenId, msg.sender), "HAS_MADE_OFFER");
        require(expiration > block.timestamp, "EXPIRATION_TOOL_SMALL");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        _charge(payMethod, price);

        Offer memory offer = Offer({
            offerId: nextOfferIndex++,
            issuer: issuer,
            tokenId: tokenId,
            buyer: msg.sender,
            payMethod: payMethod,
            bid: price,
            mt: block.timestamp,
            expiration: expiration
        });
        offerTb[offer.offerId] = offer;
        tokenOffersTb[issuer][tokenId].push(offer.offerId);
        userOffersTb[msg.sender].push(offer.offerId);

        emit MakeOffer(msg.sender, offer.issuer, offer.tokenId, 
        offer.offerId, offer.payMethod, offer.bid, offer.mt, offer.expiration);
    }

    function _updateOfferPrice(Offer memory offer, uint price) internal {
        uint delt  = 0;
        if(offer.bid > price){
            delt = offer.bid.sub(price);
            if(offer.payMethod == PayMethod.PAY_BNB){
                payable(address(msg.sender)).transfer(delt);
            } else if(offer.payMethod == PayMethod.PAY_BUSD){
                busdContract.transfer(msg.sender, delt);
            } else {
                bibContract.transfer(msg.sender, delt);
            }
        } else {
            delt = price.sub(offer.bid);
            if(offer.payMethod == PayMethod.PAY_BNB){
                require(msg.value >= delt, "INSUFFICIENT_FUNDS");
                // refunds
                if(msg.value > delt){
                    payable(address(msg.sender)).transfer(msg.value.sub(delt));
                }
            } else if(offer.payMethod == PayMethod.PAY_BUSD){
                busdContract.transferFrom(msg.sender, address(this), delt);
            } else {
                bibContract.transferFrom(msg.sender, address(this), delt);
            }
        }
    }

    // Buyer udpate offer bid price
    function updateOfferPrice(uint offerId, uint price) 
    public override payable whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");
        require(offer.expiration > block.timestamp, "OFFER_EXPIRED");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        _updateOfferPrice(offer, price);
    
        emit UpdateOfferPrice(msg.sender, offer.offerId, offer.bid, price);

        offer.bid = price;
        offer.mt = block.timestamp;
    }

    function _refund(PayMethod payMethod, uint amount) internal {
        if(payMethod == PayMethod.PAY_BNB){
            payable(msg.sender).transfer(amount);
        } else if(payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(address(this), msg.sender, amount);
        } else {
            bibContract.transferFrom(address(this), msg.sender, amount);
        }
    }

    function _charge(PayMethod payMethod, uint amount) internal {
        if(payMethod == PayMethod.PAY_BNB){
            require(msg.value >= amount, "INSUFFICIENT_FUNDS");
            // refunds
            if(msg.value > amount){
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else if(payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(msg.sender, address(this), amount);
        } else {
            bibContract.transferFrom(msg.sender, address(this), amount);
        }
    }

    function updateOffer(uint offerId, PayMethod payMethod, uint price, uint expiration) 
    public override payable{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");
        require(expiration > block.timestamp, "EXPIRATION_TOO_EARLY");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        // update or charge
        if(payMethod == offer.payMethod){
            _updateOfferPrice(offer, price);
        } else {
            // refund 
            _refund(offer.payMethod, offer.bid);
     
            // recharge
            _charge(payMethod, price);
        }
        offer.payMethod = payMethod;
        offer.bid = price;
        offer.expiration = expiration;
        offer.mt = block.timestamp;

        emit UpdateOffer(msg.sender, offer.issuer, offer.tokenId, 
        offer.offerId, offer.payMethod, offer.bid, offer.mt, offer.expiration);
    }

    function _cancleOffer(uint offerId) internal {
        Offer storage offer = offerTb[offerId];

        // remove from token offer tb
        uint[] storage offers = tokenOffersTb[offer.issuer][offer.tokenId];
        for(uint i = 0; i < offers.length; i++){
           if(offerTb[offers[i]].offerId == offerId){
                offers[i] = offers[offers.length - 1];
                offers.pop();
                break;
           }
        }
        delete offerTb[offerId];

        // remove from user offers tb
        uint[] storage offerIds = userOffersTb[offer.buyer];
        for(uint i = 0; i < offerIds.length; i++){
           if(offerIds[i] == offerId){
                offerIds[i] = offerIds[offerIds.length - 1];
                offerIds.pop();
                break;
           }
        }

        emit CancelOffer(msg.sender, offerId);
    }

    // Buyer cancle the specific order
    function cancelOffer(uint offerId) public override whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");

        if(offer.payMethod == PayMethod.PAY_BNB){
            payable(address(offer.buyer)).transfer(offer.bid);
        } else if(offer.payMethod == PayMethod.PAY_BUSD){
            busdContract.transfer(offer.buyer, offer.bid);
        } else {
            bibContract.transfer(offer.buyer, offer.bid);
        }

        _cancleOffer(offerId);
    }

    function cancelAllOffersByIssuer(address issuer)
    public override whenNotPaused {
        uint[] storage offerIds = userOffersTb[msg.sender];

        for(uint i = 0; i < offerIds.length;){
            Offer storage offer = offerTb[offerIds[i]];

            if(offer.issuer != issuer) {
                i++;
                continue;
            }

            // remove from offersByIssuer
            uint[] storage offersByIssuer = tokenOffersTb[offer.issuer][offer.tokenId];
            for(uint j = 0; j < offersByIssuer.length; j++){
                if(offersByIssuer[j] == offerIds[i]){
                    offersByIssuer[j] = offersByIssuer[offersByIssuer.length - 1];
                    offersByIssuer.pop();
                    break;
                }
            }

            // remove form offerTab
            delete offerTb[offerIds[i]];

            emit CancelOffer(msg.sender, offerIds[i]);

            // remove from userOffersTb
            offerIds[i] = offerIds[offerIds.length - 1];
            offerIds.pop();
        }
    }
}