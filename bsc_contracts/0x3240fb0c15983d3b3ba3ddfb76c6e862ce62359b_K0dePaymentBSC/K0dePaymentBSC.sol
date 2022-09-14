/**
 *Submitted for verification at BscScan.com on 2022-09-13
*/

// SPDX-License-Identifier: UNLICENSED
// k0de.io 
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract K0dePaymentBSC is Ownable{

    using Address for address payable;

    uint256 public totalPaymentsReceived;

    struct Service{
        address deployer;
        string name;
        uint256 rateInBNBWei;
        bool isPaused;
    }
    uint public serviceID = 0;
    mapping(uint => Service) public services;

    struct Subscription{
        address subscriber;
        bool isCancelled;
        uint256 subscriptionStarted;
    }
    mapping(address => mapping(uint => Subscription)) public subscriptions;

    function getRateForAllServices() public view returns(uint256[] memory){
        uint[] memory rates = new uint[](serviceID);
        for (uint i = 0 ; i < serviceID; i++){
            rates[i] = services[i].rateInBNBWei;
        }
        return rates;
    }

    function getAllSubscriptions(address subscriber) public view returns(Subscription[] memory){
        Subscription[] memory subscriptions_ = new Subscription[](serviceID);
        for(uint i = 0 ; i < serviceID; i++){
            subscriptions_[i] = subscriptions[subscriber][i];
        }
        return subscriptions_;
    }

    function owner_AddService(string memory name_, uint rateInBNBWei_) external onlyOwner{
        require(_msgSender() != address(0),"Deployer cannot be null address");
        services[serviceID] = Service(_msgSender(),name_,rateInBNBWei_,false);
        serviceID++;
        emit ServiceCreated(_msgSender(),name_,rateInBNBWei_);
    }

    function owner_UpdateServiceRate(uint256 serviceID_,uint256 newrateInBNBWei_) external onlyOwner{
        services[serviceID_].rateInBNBWei = newrateInBNBWei_;
        emit ServiceRateUpdated(serviceID, newrateInBNBWei_);
    }

    function owner_UpdateServiceStatus(uint256 serviceID_,bool isPaused_) external onlyOwner{
        services[serviceID_].isPaused = isPaused_;
        emit ServiceStatusUpdated(serviceID_, isPaused_);
    }

    function owner_WhiteListSubscription(uint256 serviceID_, address user_) external onlyOwner{
        subscriptions[user_][serviceID_] = Subscription(user_,false,block.timestamp);
        emit SubscriptionCreated(user_,serviceID_,0);
    }

    function owner_CancelSubscription(address subscriber, uint256 serviceID_,bool isCancelled_) external onlyOwner{
        subscriptions[subscriber][serviceID_].isCancelled = isCancelled_;
        emit SubscriptionCancelled(subscriber);
    }

    function subscribeToService(uint256 serviceID_) external payable returns(bool){
        Service storage _service = services[serviceID_];
        require(!_service.isPaused,"Service is paused at the moment.");
        require(_service.deployer != address(0), "Service doesn't exist");
        require(msg.value >= _service.rateInBNBWei, "Insufficient Balance");

        totalPaymentsReceived+=msg.value;

        subscriptions[_msgSender()][serviceID_] = Subscription(_msgSender(),false,block.timestamp);
        
        emit SubscriptionCreated(_msgSender(),serviceID_,msg.value);
        return true;
    }

    function withdrawPayments(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient Balance");
        payable(_msgSender()).sendValue(weiAmount);
        emit PaymentsWithdrawn(_msgSender(),weiAmount);
    }

    event PaymentsWithdrawn(address receiver, uint256 amountWithdrawn);
    event ServiceCreated(address deployer,string name,uint rateInBNBWei);
    event ServiceRateUpdated(uint256 serviceID, uint256 newrateInBNBWei);
    event ServiceStatusUpdated(uint256 serviceID, bool isPaused);
    event SubscriptionCreated(address subscriber,uint256 serviceID,uint256 tokenPayment);
    event SubscriptionCancelled(address subscriber);
}