// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Marketplace is Ownable, Initializable, UUPSUpgradeable {
    
 
    function initialize(
        string memory _domain,
        address _factory,
        address _owner,
        address _signer,
        address _guarantor,
        address _arbitrator
    ) public initializer {
        _transferOwnership(_owner);
        domain = _domain;
        factory = _factory;
        signer = _signer;
        guarantor = _guarantor;
        arbitrator = _arbitrator;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override  {
        require(newImplementation != address(0), "Marketplace: new implementation is the zero address");
        require(msg.sender == owner() || msg.sender == factory, "Marketplace: not owner or factory");
    }


    using ECDSA for bytes32;
    string  public domain;
    address public factory;
    address public signer;
    address public guarantor;
    address public arbitrator;
    
    enum Status {OnGoing,PostJudgment,InArbitration}
    struct Order {
        string   offerID;
        address  token;
        uint256  amount;
        address  buyer;
        address  seller;
        address  receiver;
        uint256  lockTime;
        uint256  judgmentTime;
        Status status;
    }

    struct OrderFee {
        address  marketplaceFeeReceiver;
        uint256  marketplaceBuyerFee;
        uint256  marketplaceSellerFee;
        address  feeReceiver;
        uint256  buyerFee;
        uint256  sellerFee;
    }

    mapping(string => Order) public orders;
    string[] public offers;
    mapping(string => uint256) public offersIndex;
    mapping(string => OrderFee) public ordersFee;



    event NewOrder(
        string offerID,
        address token,
        uint256 amount,
        address buyer,
        address seller,
        uint256 marketplaceBuyerFee,
        uint256 marketplaceSellerFee,
        uint256 buyerFee,
        uint256 sellerFee,
        uint256 lockTime
        );
    event CancelOrder(string offerID,address buyer,address seller);
    event CompleteOrder(string offerID,address buyer,address seller);
    event JudgeOrder(string offerID,address buyer,address seller,bool isCancel,uint256 judgmentTime);
    event Withdrawal(string offerID,address buyer,address seller,address operator);
    event ApplyArbitrateOrder(string offerID,address buyer,address seller,address operator);
    event ArbitrateOrder(string offerID,address buyer,address seller,bool isCancel);
    event ReceiveFee(
        string  offerID,
        address buyer,
        address seller,
        uint256 marketplaceBuyerFee,
        uint256 marketplaceSellerFee,
        uint256 buyerFee,
        uint256 sellerFee);
    event Received(address indexed sender, uint256 value);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getOrder(string memory _offerID) external view returns(Order memory) {
        return orders[_offerID];
    }

    function getOrderFee(string memory _offerID) external view returns(OrderFee memory) {
        return ordersFee[_offerID];
    }

    struct NewOrderParams {
        string  offerID;
        address token;
        uint256 amount;
        address seller;
        uint256 lockTime;
        address marketplaceFeeReceiver;
        uint256 marketplaceBuyerFee;
        uint256 marketplaceSellerFee;
        address feeReceiver;
        uint256 buyerFee;
        uint256 sellerFee;
        bytes   signature;
    }



    /**
    * @dev This function creates a new order.
    * @param _params The parameters of the new order.
    */
    function newOrder(
        NewOrderParams calldata _params
    ) payable external {
        require(orders[_params.offerID].seller == address(0),"Marketplace: order already exists");
        require(_verify(msg.sender,_params),"Marketplace: invalid signature");
        uint256 needInput =  _params.amount + _params.buyerFee + _params.marketplaceBuyerFee;
        if (_params.token == address(0)) {
            require(msg.value >= needInput,"Marketplace: invalid eth amount");
        }else{
            IERC20 token = IERC20(_params.token);
            require(token.allowance(msg.sender,address(this)) >= needInput,"Marketplace: invalid token amount");
            token.transferFrom(msg.sender,address(this),needInput);
        }
        orders[_params.offerID] = Order(
            _params.offerID,
            _params.token,
            _params.amount,
            msg.sender,
            _params.seller,
            address(0),
            _params.lockTime,
            0,
            Status.OnGoing);

        ordersFee[_params.offerID] = OrderFee(
            _params.marketplaceFeeReceiver,
            _params.marketplaceBuyerFee,
            _params.marketplaceSellerFee,
            _params.feeReceiver,
            _params.buyerFee,
            _params.sellerFee);    

        offers.push(_params.offerID);
        offersIndex[_params.offerID] = offers.length - 1;
        emit NewOrder(
            _params.offerID,
            _params.token,
            _params.amount,
            msg.sender,
            _params.seller,
            _params.marketplaceBuyerFee,
            _params.marketplaceSellerFee,
            _params.buyerFee,
            _params.sellerFee,
            _params.lockTime
            );
    }

    function _verify(
        address _buyer,
        NewOrderParams calldata _params
        ) internal view returns(bool){
       bytes32 message = keccak256(abi.encodePacked(
        _params.offerID,
        _params.token,
        _params.amount,
        _buyer,
        _params.seller, 
        _params.lockTime,
        _params.marketplaceFeeReceiver,
        _params.marketplaceBuyerFee,
        _params.marketplaceSellerFee,
        _params.feeReceiver,
        _params.buyerFee,
        _params.sellerFee
        ));
         return message.toEthSignedMessageHash().recover(_params.signature) == signer;
    }


    /**
    * @dev This function allows the seller to cancel an order.
    * @param _offerID The ID of the offer to be cancelled.
    */
    function cancel(string memory _offerID) external {
        Order storage order = orders[_offerID];
        require(msg.sender == order.seller,"Marketplace: only seller can cancel order");
        require(order.status == Status.OnGoing,"Marketplace: order status is not on going");
        _toBuyer(_offerID);
        emit CancelOrder(_offerID,order.buyer,order.seller);
        
        delete orders[_offerID];
        _removeOffer(_offerID);
    }

    function _removeOffer(string memory _offerID) internal { 
        uint256 index = offersIndex[_offerID];
        offers[index] = offers[offers.length - 1];
        offersIndex[offers[index]] = index;
        offers.pop();
        delete offersIndex[_offerID];
        delete ordersFee[_offerID];
        delete orders[_offerID];
    }

    function _toBuyer(string memory _offerID) internal {
        Order storage order = orders[_offerID];
        OrderFee storage orderFee = ordersFee[_offerID];
        uint256 refund = order.amount  + orderFee.buyerFee + orderFee.marketplaceBuyerFee;
        if (order.token == address(0)) {
           (bool success,) = order.buyer.call{value:refund}("");
            require(success,"Marketplace: refund eth failed");
        }else{
            IERC20 token = IERC20(order.token);
            token.transfer(order.buyer,refund);
        }
    }


    /**
    * @dev Completes an order by the buyer.
    * 
    * Requirements:
    * - Only the buyer can complete the order.
    * - The order must be ongoing.
    */
    function complete(string memory _offerID) external {
        Order storage order = orders[_offerID];
        require(msg.sender == order.buyer,"Marketplace: only buyer can complete order");
        require(order.status == Status.OnGoing,"Marketplace: order is not on going");
        _toSeller(_offerID);
        emit CompleteOrder(_offerID,order.buyer,order.seller);
        delete orders[_offerID];
        _removeOffer(_offerID);
       
    }

    function _toSeller(string memory _offerID) internal {
        Order storage order = orders[_offerID];
        OrderFee storage orderFee = ordersFee[_offerID];
       
        
        if (order.token == address(0)) {
            (bool sent, ) = payable(orderFee.marketplaceFeeReceiver).call{value: orderFee.marketplaceBuyerFee+orderFee.marketplaceSellerFee}("");
            require(sent, "Marketplace: failed to send eth to marketplace fee receiver");
            (sent, ) = payable(orderFee.feeReceiver).call{value:orderFee.buyerFee + orderFee.sellerFee}("");
            require(sent, "Marketplace: failed to send eth to fee receiver");
            (sent, ) = payable(order.seller).call{value: order.amount - orderFee.marketplaceSellerFee-orderFee.sellerFee}("");
            require(sent, "Marketplace: failed to send eth to seller");
        }else{
            IERC20 token = IERC20(order.token);
            token.transfer(orderFee.marketplaceFeeReceiver,orderFee.marketplaceBuyerFee+orderFee.marketplaceSellerFee);
            token.transfer(orderFee.feeReceiver,orderFee.buyerFee+orderFee.sellerFee);
            token.transfer(order.seller,order.amount - orderFee.marketplaceSellerFee-orderFee.sellerFee);
        }
        emit ReceiveFee(_offerID,order.buyer, order.seller, orderFee.marketplaceBuyerFee, orderFee.marketplaceSellerFee,orderFee.buyerFee,orderFee.sellerFee);

    }

    /**
    * @notice Allows the guarantor to judge an order.
    * @param _offerID The ID of the order.
    * @param _isCancel Whether the order should be canceled or not.
    */
    function judge(string memory _offerID,bool _isCancel) external {
        Order storage order = orders[_offerID];
        require(msg.sender == guarantor,"Marketplace: only guarantor can judge order");
        require(order.status == Status.OnGoing,"Marketplace: order is not on going");
        order.status = Status.PostJudgment;
        if (_isCancel) {
            order.receiver = order.buyer;
        } else {
            order.receiver = order.seller;
        }
        order.judgmentTime = block.timestamp;
        emit JudgeOrder(_offerID,order.buyer,order.seller,_isCancel,order.judgmentTime);
    }

    /**
    * @dev Allows the receiver of the order to withdraw funds.
    * @param _offerID The ID of the offer.
    */
    function withdraw(string memory _offerID) external {
        Order storage order = orders[_offerID];
        require(order.status == Status.PostJudgment,"Marketplace: order is not post judgment");
        require(block.timestamp >= order.lockTime + order.judgmentTime,"Marketplace: order is not unlock");
        require(msg.sender == order.receiver,"Marketplace: only receiver can withdraw");
        if (order.receiver == order.buyer) {
            _toBuyer(_offerID);
        } else {
            _toSeller(_offerID);
        }
        emit Withdrawal(_offerID,order.buyer,order.seller,msg.sender);
        delete orders[_offerID];
        _removeOffer(_offerID);
    }

    /**
    * @dev Apply for arbitration on a specific order.
    * @param _offerID The ID of the offer to apply arbitration on.
    */
    function applyArbitrate(string memory _offerID) external {
        Order storage order = orders[_offerID];
        require(order.status == Status.PostJudgment,"Marketplace: order is not post judgment");
        require(block.timestamp < order.lockTime+order.judgmentTime,"Marketplace: order is unlock");
        require(msg.sender == order.buyer || msg.sender == order.seller,"Marketplace: only buyer or seller can apply arbitrate order");
        require(msg.sender != order.receiver,"Marketplace: receiver can not apply arbitrate order");
        order.status = Status.InArbitration;
        emit ApplyArbitrateOrder(_offerID,order.buyer,order.seller,msg.sender); 

    }

    /**
    * @dev This function is used by the arbitrator to arbitrate an order.
    * @param _offerID The ID of the offer being arbitrated.
    * @param _isCancel Boolean indicating whether the order should be canceled or not.
    */
    function arbitrate(string memory _offerID,bool _isCancel)  external {
        require(msg.sender == arbitrator,"Marketplace: only arbitrator can arbitrate order");
        Order storage order = orders[_offerID];
        require(order.status == Status.InArbitration,"Marketplace: order is not in arbitration");
       if (_isCancel) {
            _toBuyer(_offerID); 
        } else {
            _toSeller(_offerID);
        }
        emit ArbitrateOrder(_offerID,order.buyer,order.seller,_isCancel);
        delete orders[_offerID];
        _removeOffer(_offerID);
    }

}