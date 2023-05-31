// SPDX-License-Identifier: MIT
// Creator: WagmiLabs
// Developer: Nftfede.eth
// Contract: Wagmilabs Trading Hub SUBSCRIPTIONS

/*
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████──────────██████─██████████████─██████████████─██████──────────██████─██████████────██████─────────██████████████─██████████████───██████████████─
─██░░██──────────██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██████████████░░██─██░░░░░░██────██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██───██░░░░░░░░░░██─
─██░░██──────────██░░██─██░░██████░░██─██░░██████████─██░░░░░░░░░░░░░░░░░░██─████░░████────██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─
─██░░██──────────██░░██─██░░██──██░░██─██░░██─────────██░░██████░░██████░░██───██░░██──────██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────
─██░░██──██████──██░░██─██░░██████░░██─██░░██─────────██░░██──██░░██──██░░██───██░░██──────██░░██─────────██░░██████░░██─██░░██████░░████─██░░██████████─
─██░░██──██░░██──██░░██─██░░░░░░░░░░██─██░░██──██████─██░░██──██░░██──██░░██───██░░██──────██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░░░██─██░░░░░░░░░░██─
─██░░██──██░░██──██░░██─██░░██████░░██─██░░██──██░░██─██░░██──██████──██░░██───██░░██──────██░░██─────────██░░██████░░██─██░░████████░░██─██████████░░██─
─██░░██████░░██████░░██─██░░██──██░░██─██░░██──██░░██─██░░██──────────██░░██───██░░██──────██░░██─────────██░░██──██░░██─██░░██────██░░██─────────██░░██─
─██░░░░░░░░░░░░░░░░░░██─██░░██──██░░██─██░░██████░░██─██░░██──────────██░░██─████░░████────██░░██████████─██░░██──██░░██─██░░████████░░██─██████████░░██─
─██░░██████░░██████░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░██──────────██░░██─██░░░░░░██────██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░░░██─██░░░░░░░░░░██─
─██████──██████──██████─██████──██████─██████████████─██████──────────██████─██████████────██████████████─██████──██████─████████████████─██████████████─
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
*/

pragma solidity > 0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

struct AdminSubscribe {
    address subscriptionRecepient;
    uint256 subscriptionMonths;
    uint256 subscriptionType;
}

contract WagmilabsSubscriptions is ReentrancyGuard {

    using EnumerableMap for EnumerableMap.AddressToUintMap;


    address owner;

    constructor(){
        owner = msg.sender;
        subscriptionsProPrice[1] = 0.03 ether;
    }

    uint256 monthInMilliSeconds =  2629800000; // 1 month in milliseconds

    bool public subscriptionsOpen = true;

    uint256 discountPerc = 30;

    bytes32 discountRoot;

    EnumerableMap.AddressToUintMap private basicAddressExpiration;
    EnumerableMap.AddressToUintMap private proAddressExpiration;

    mapping(uint256 months => uint256 monthPrice) public subscriptionsBasicPrice;
    mapping(uint256 months => uint256 monthPrice) public subscriptionsProPrice;


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }


    modifier hasSubscriptionsOpen() {
        require(subscriptionsOpen, "Subscriptions not open yet");
        _;
    }

    
    function setOpen(bool _open) public onlyOwner {
        subscriptionsOpen = _open;
    }

    function setDiscountRoot(bytes32 _root) public onlyOwner {
        discountRoot = _root;
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setDiscountPerc(uint256 _discountPerc) public {
        discountPerc = _discountPerc;
    }


    // 0 basic, 1 pro
    function changePriceWei(uint256 monthlyPrice, uint256 monthsAmount, uint256 planType) public onlyOwner{
        if(planType == 0){
            subscriptionsBasicPrice[monthsAmount] = monthlyPrice * 1 wei;
        }
        else if(planType == 1){
            subscriptionsProPrice[monthsAmount] = monthlyPrice * 1 wei;
        }
        else revert("Invalid type");
    }
    

    function subscribeBasic(uint256 months, bytes32[] memory proof) public payable hasSubscriptionsOpen{

        uint256 requiredPrice;

        if(isDiscounted(proof, keccak256(abi.encodePacked(msg.sender)))) requiredPrice = (subscriptionsBasicPrice[months] * months) * discountPerc / 100;
        else requiredPrice = subscriptionsBasicPrice[months] * months;

        require(requiredPrice != 0, "Invalid month");

        require(msg.value >= requiredPrice, "Insufficient value");
        require(!hasValidBasicSubscription(msg.sender), "Wallet is already subscribed");

        uint256 expiration = (block.timestamp * 1000) + months * monthInMilliSeconds;
        basicAddressExpiration.set(msg.sender, expiration);
    }

    function subscribePro(uint256 months, bytes32[] memory proof) public payable hasSubscriptionsOpen{
        uint256 requiredPrice;

        if(isDiscounted(proof, keccak256(abi.encodePacked(msg.sender)))) requiredPrice = (subscriptionsProPrice[months] * months) * discountPerc / 100;
        else requiredPrice = subscriptionsProPrice[months] * months;

        require(requiredPrice != 0, "Invalid month");

        require(msg.value >= requiredPrice, "Insufficient value");
        require(!hasValidProSubscription(msg.sender), "Wallet is already subscribed");

        uint256 expiration = (block.timestamp * 1000) + months * monthInMilliSeconds;
        proAddressExpiration.set(msg.sender, expiration);
    }

    
    function isDiscounted(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, discountRoot, leaf);
    }



    function getBasicSubscriptionOfAddress(address addr) public view returns (uint256) {
        if (basicAddressExpiration.contains(addr)) {
            return basicAddressExpiration.get(addr);
        } else {
            return 0; // or any other default value
        }
    }
    function getproSubscriptionOfAddress(address addr) public view returns (uint256) {
        if (proAddressExpiration.contains(addr)) {
            return proAddressExpiration.get(addr);
        } else {
            return 0; // or any other default value
        }
    }

    function hasValidBasicSubscription(address walletAddress) public view returns(bool){
        uint256 expirationTimestamp = getBasicSubscriptionOfAddress(walletAddress);
        uint256 currentTimestamp = block.timestamp * 1000;
        bool isValidSubscription = expirationTimestamp >= currentTimestamp;
        return isValidSubscription;
    }

    function hasValidProSubscription(address walletAddress) public view returns(bool){
        uint256 expirationTimestamp = getproSubscriptionOfAddress(walletAddress);
        uint256 currentTimestamp = block.timestamp * 1000;
        bool isValidSubscription = expirationTimestamp >= currentTimestamp;
        return isValidSubscription;
    }

    function checkSubscriptionAdvanced(address ownerAddress) public view returns (bool, uint256, uint256) {
        bool hasSubscription = false;

        // 1 basic, 2 pro
        uint256 subscriptionType = 1;

        uint256 subscriptionExpiration = 0;
        

        if (hasValidProSubscription(ownerAddress)) {
            hasSubscription = true;
            subscriptionType = 2;
            subscriptionExpiration = getproSubscriptionOfAddress(ownerAddress);
        }
        if (!hasSubscription) {
            if (hasValidBasicSubscription(ownerAddress)){
                hasSubscription = true;
                subscriptionExpiration = getBasicSubscriptionOfAddress(ownerAddress);
            }
        }
        return (hasSubscription, subscriptionType, subscriptionExpiration);
    }
    

    function getActiveBasics() public view returns (uint256) {
        uint256 numKeys = basicAddressExpiration.length();
        uint256 allKeys;
        for (uint256 i = 0; i < numKeys; i++) {
            (,uint256 expiration) = basicAddressExpiration.at(i);
            if(expiration >= block.timestamp * 1000) allKeys ++;
        }
        return allKeys;
    }

    function getActivePros() public view returns (uint256) {
        uint256 numKeys = proAddressExpiration.length();
        uint256 allKeys;
        for (uint256 i = 0; i < numKeys; i++) {
            (,uint256 expiration) = proAddressExpiration.at(i);
            if(expiration >= block.timestamp * 1000) allKeys ++;
        }
        return allKeys;
    }


    function getAllActiveAmount() public view returns(uint256, uint256){
        uint256 activeBasics = getActiveBasics();
        uint256 activePros = getActivePros();

        return (activeBasics, activePros);
    }

    function adminSubscribe(AdminSubscribe[] memory data) public onlyOwner {
        for(uint256 i = 0; i < data.length; i++){
            uint256 subscriptionType = data[i].subscriptionType;
            uint256 subscriptionDuration = data[i].subscriptionMonths;
            address subscriptionRecepient = data[i].subscriptionRecepient;

            uint256 expiration = (block.timestamp * 1000) + subscriptionDuration * monthInMilliSeconds;

            if(subscriptionType == 0){
                require(!hasValidBasicSubscription(subscriptionRecepient), "Wallet is already subscribed");

                basicAddressExpiration.set(subscriptionRecepient, expiration);
            }
            else if(subscriptionType == 1){
                require(!hasValidProSubscription(subscriptionRecepient), "Wallet is already subscribed");

                proAddressExpiration.set(subscriptionRecepient, expiration);
            }
        }
    }
    // whithdraw function
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }  
    
}