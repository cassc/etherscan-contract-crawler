// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./RobotsEquipment.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "common-contracts/contracts/Governable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Lootbox is VRFConsumerBaseV2, Governable{
    using EnumerableSet for EnumerableSet.UintSet;

    struct ChainlinkParams{
        address coordinator;
        uint64 subscriptionId;
        bytes32 keyHash;
    }

    struct ContainerInfo{
        uint32[] itemIds;
        uint16[] weights;
    }

    struct RollInfo{
        uint containerId;
        address reciever;
    }

    address payable private paymentReciever;
    RobotsEquipment private equipment;
    IERC20 private paymentToken;
    ERC1155Burnable private containers;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 private keyHash;
    VRFCoordinatorV2Interface private coordinator;
    uint64 public subscriptionId;

    //price for each consecutive roll
    uint[] public rollPrices; 

    //additional payment for chainlink services
    uint chainlinkFee;

    //user => containerId => value
    mapping (address => mapping(uint => uint)) private rollCount;
    mapping (address => mapping(uint => uint)) private pendingItem;

    //chainlink request id => rollInfo
    mapping (uint => RollInfo) private rollInfo;

    //itemId = > nftIds  itemId from our sheet with all items
    mapping(uint => uint16[]) nftIds;
    mapping(uint => uint) pendingNftCount;

    //containerId => containerInfo
    mapping(uint => ContainerInfo) private containersInfo;

    //containers that we allow to open and roll
    EnumerableSet.UintSet private viableContainers;

    event Rolled(address indexed user, uint containerId, uint requestId, uint rollCount);
    event Confirmed(address indexed user, uint containerId, uint itemId, uint nftId);
    event ContainerChanged(uint indexed containerId, ContainerInfo newContainer);

    constructor(
        RobotsEquipment equipment_,
        IERC20 paymentToken_,
        ERC1155Burnable containers_,
        address payable paymentReciever_, 
        uint[] memory prices_,
        ChainlinkParams memory params_)  
        VRFConsumerBaseV2(params_.coordinator) 
    {
        equipment = equipment_;
        paymentToken = paymentToken_;
        paymentReciever = paymentReciever_;
        rollPrices = prices_;
        containers = containers_;

        coordinator = VRFCoordinatorV2Interface(params_.coordinator);
        keyHash = params_.keyHash;
        subscriptionId = params_.subscriptionId;
    }


    /**
     * @notice Burn container and start it opening process
     *
     * @param containerId   Id of container in liquidifty collection
     */
    function open(uint containerId) external payable{
        require(rollCount[msg.sender][containerId] == 0, "Already opening container");

        containers.burn(msg.sender, containerId, 1);

        //will revert if container not viable
        _roll(containerId);
    }
    
    /**
     * @notice Used from user to roll new item, can only be invoked after `open`
     *
     * @param containerId   Id of container in liquidifty collection
     */
    function roll(uint containerId) external payable {
        //Can roll only if container have been opened
        require(rollCount[msg.sender][containerId] > 0, "This container is not opening now");

        //free up pending item count
        uint pendingItemId = pendingItem[msg.sender][containerId];
        pendingNftCount[pendingItemId]--;

        //remove pendingItem so it cannot be confirmed before new random item arrived
        delete pendingItem[msg.sender][containerId];

        //will revert if container not viable
        _roll(containerId);
    }

    /**
     * @notice Uses chainlink to roll new item. Can require token to proceed. Require viable container id
     *
     * @param containerId   Id of container in liquidifty collection
     */
    function _roll(uint containerId) internal {
        //If container not in viable list, you can only confirm
        require(viableContainers.contains(containerId), "This container are not viable");

        uint curRollCount = rollCount[msg.sender][containerId];

        //get price for current roll and pay if it > 0
        uint price = getRollPrice(curRollCount);
        if(price > 0){
            paymentToken.transferFrom(msg.sender, paymentReciever, price);
        }

        uint linkFee = chainlinkFee;
        if(linkFee > 0){
            Address.sendValue(paymentReciever, linkFee);
        }

        uint32[] memory counts = getAvailableItemsNftCount(containersInfo[containerId].itemIds);
        if((counts[0] + counts[1] + counts[2] + counts[3] + counts[4]) == 0 || (counts[5] + counts[6]) == 0){
            revert("Contact support: equipment gone");
        }

        //increment roll count
        rollCount[msg.sender][containerId]++;

        uint requestId = requestRandomWords();

        //put roll info in storage, so sender and id can be recieved in `fulfillRandomness`
        rollInfo[requestId] = RollInfo(containerId, msg.sender);

        emit Rolled(msg.sender, containerId, requestId, curRollCount);
    }

    /**
     * @notice Recieve item that was rolled. This function can be invoked
     * even if containerId not viable anymore.
     *
     * @param containerId   Id of container in liquidifty collection
     */
    function confirm(uint containerId) external {
        uint pendingItemId = pendingItem[msg.sender][containerId];

        //This means that we can't have pending item with zero id
        require(pendingItemId != 0, "No pending item"); 

        //get last nft id of item
        uint len = nftIds[pendingItemId].length;
        uint id = nftIds[pendingItemId][len - 1];
        nftIds[pendingItemId].pop();

        //mint concrete nft id to user
        equipment.mint(msg.sender, id);

        delete pendingItem[msg.sender][containerId];
        delete rollCount[msg.sender][containerId];
        pendingNftCount[pendingItemId]--;

        emit Confirmed(msg.sender, containerId, pendingItemId, id);
    }


    /**
     * @notice set roll prices
     *
     * @param prices array of prices for each roll, first element is first roll 
     * that happens right after open function
     */
    function setRollPrices(uint[] calldata prices) external onlyGovernance {
        rollPrices = prices;
    }

    /**
     * @notice set viable containers
     *
     * @param newViableContainers array of containers Id from liquidifty collection.
     * Only containers listed in this array could be opened or rolled. 
     */
    function setViableContainers(uint[] calldata newViableContainers) external onlyGovernance {
        uint length = viableContainers.length();

        //purge previous values. Can't use 'delete' as it can broke storage
        for (uint i = 0; i < length; i++) {
            uint value = viableContainers.at(0);
            viableContainers.remove(value);
        }

        length = newViableContainers.length;

        //add new values
        for (uint i = 0; i < length; i++) {
            viableContainers.add(newViableContainers[i]);
        }
    }

    /**
     * @notice set nft Ids for certain item Id
     *
     * @param itemId item id, this is id from our sheet of all items
     * @param newNftIds array of nftId that represents instances of itemId in equip collection
     */
    function setItemIds(uint itemId, uint16[] calldata newNftIds) external onlyGovernance {
        nftIds[itemId] = newNftIds;
    }

    function setPaymentReciever(address payable newAddress) external onlyGovernance {
        paymentReciever = newAddress;
    }

    function setSubscriptionId(uint64 newId) external onlyGovernance {
        subscriptionId = newId;
    }

    function setLinkFee(uint newValue) external onlyGovernance {
        chainlinkFee = newValue;
    }

    function setItemIdsBatch(uint[] calldata itemId, uint16[][] calldata newNftIds) external onlyGovernance {
        for (uint i = 0; i < itemId.length; i++) {
            nftIds[itemId[i]] = newNftIds[i];
        }
    }

    /**
     * @notice set item array and item weights for a certain container Id
     *
     * @param containerId   Id of container in liquidifty collection
     * @param itemIds item ids, this is ids from our sheet of all items
     * @param weights weights that represents probability of each item to be rolled
     */
    function setContainer(uint containerId, uint32[] calldata itemIds, uint16[] calldata weights) external onlyGovernance {
        require(itemIds.length == weights.length, "items and weights are not same length");

        ContainerInfo memory newContainer = ContainerInfo(itemIds, weights);

        containersInfo[containerId] = newContainer;
        emit ContainerChanged(containerId, newContainer);
    }

    function getRollPrice(uint rollIndex) public view returns(uint){
        return rollIndex >= rollPrices.length ? rollPrices[rollPrices.length - 1] : rollPrices[rollIndex];
    }

    function getNextRollPrice(address user, uint containerId) public view returns(uint){
        return getRollPrice(getRollCount(user, containerId));
    }

    function getItemNftIds(uint itemId) external view returns(uint16[] memory){
        return nftIds[itemId];
    }

    function getItemsNftCount(uint32[] memory itemIds) external view returns(uint32[] memory result){
        result = new uint32[](itemIds.length);
        uint len = itemIds.length;

        for (uint i = 0; i < len; ) {
            result[i] = uint32(nftIds[itemIds[i]].length);
            unchecked {
                i++;
            }
        }
    }

    function getAvailableItemsNftCount(uint32[] memory itemIds) public view returns(uint32[] memory result){
        result = new uint32[](itemIds.length);
        uint len = itemIds.length;

        for (uint i = 0; i < len; ) {
            result[i] = uint32(nftIds[itemIds[i]].length - pendingNftCount[itemIds[i]]);
            unchecked {
                i++;
            }
        }
    }

    function getViableContainers() external view returns (uint[] memory){
        return viableContainers.values();
    }

    function getRollCount(address user, uint containerId) public view returns(uint){
        return rollCount[user][containerId];
    }

    function getPendingItem(address user, uint containerId) external view returns(uint){
        return pendingItem[user][containerId];
    }

    function getContainerInfo(uint id) external view returns(uint32[] memory ids, uint16[] memory weights){
        ContainerInfo memory info = containersInfo[id];
        (ids, weights) = (info.itemIds, info.weights);
    }

    function requestRandomWords() private returns(uint id){
            // Will revert if subscription is not set and funded.
            id = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            500000,
            1
        );
    }
  
    function fulfillRandomWords(
        uint256 requestId, 
        uint256[] memory randomWords
    ) internal override {
        RollInfo memory userRollInfo = rollInfo[requestId];
        uint containerId = userRollInfo.containerId;
        ContainerInfo memory containerInfo = containersInfo[containerId];
        uint weightsSum;
        uint itemId;

        //calculate weight sum without empty slots 
        for (uint i = 0; i < containerInfo.weights.length; i++) {
            itemId = containerInfo.itemIds[i];
            if(nftIds[itemId].length - pendingNftCount[itemId] > 0){
                weightsSum += containerInfo.weights[i];
            }
        }

        uint random = randomWords[0] % weightsSum;
        uint32 selectedSlot;
        uint accumulatedWeight;

        for (; selectedSlot < containerInfo.weights.length; selectedSlot++) {
            itemId = containerInfo.itemIds[selectedSlot];
            accumulatedWeight += (nftIds[itemId].length - pendingNftCount[itemId] > 0) ? containerInfo.weights[selectedSlot] : 0;
            if(random < accumulatedWeight){
                break;
            }
        }

        pendingItem[userRollInfo.reciever][containerId] = itemId;
        pendingNftCount[itemId]++;

        delete rollInfo[requestId];
    }  
}