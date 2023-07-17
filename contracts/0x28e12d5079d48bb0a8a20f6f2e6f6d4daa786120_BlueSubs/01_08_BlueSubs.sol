// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*
 _____ _         _____     _       
| __  | |_ _ ___|   __|_ _| |_ ___ 
| __ -| | | | -_|__   | | | . |_ -|
|_____|_|___|___|_____|___|___|___|
                                                                
*/

/// @title BlueSubs NFT contract.
contract BlueSubs is Ownable, PaymentSplitter {

    enum Version {
        None,
        LightTracker,
        CompleteTracker,
        ToolsTracker,
        Full
    }

    struct Subscription {
        string discord_id;
        uint date_of_purchase;
        uint8 month;
        Version version;
    }

    struct Receipt {
        address payer;
        uint8 month_added;
        bool is_community;
        string creator_code_used;
    }

    struct Creator {
        address creator;
        uint reduction_percentage;
        uint cashback_percentage;
        string code;
    }

    // Errors
    error MonthlyPlanError();
    error InvalidCreatorCodeError();
    error NotEnoughFundError();
    error AlreadyActivePlanError();
    error CallerIsContractError();
    error CreatorCodeExistError();
    error InvalidPercentageError();
    error InvalidPlanError();
    error InvalidLengthError();
    error NotValidOwnerError(address, address);

    // Events
    event SubscriptionRegister(Receipt receipt, Subscription subscription_updated);
    event CreatorRegister(Creator creator_updated);
    event CreatorCashbackProof(Creator creator, uint value);

    // Private
    mapping(Version => uint) private _communityPrices;
    mapping(Version => uint) private _individualPrices;
    mapping(string => Subscription) private _subscribers;
    mapping(string => Subscription) private _communities;
    mapping(string => Creator) private _creators;
    uint private immutable _teamLength;

    //Constructor of the collection
    constructor(address[] memory _team, uint[] memory _teamShares) PaymentSplitter(_team, _teamShares) {
        _teamLength = _team.length;
        _communityPrices[Version.LightTracker] = 0.04 ether;
        _communityPrices[Version.CompleteTracker] = 0.1 ether;
        _communityPrices[Version.ToolsTracker] = 0.1 ether;
        _communityPrices[Version.Full] = 0.2 ether;

        _individualPrices[Version.LightTracker] = 0.01 ether;
        _individualPrices[Version.CompleteTracker] = 0.02 ether;
        _individualPrices[Version.Full] = 0.03 ether;
    }

    /**
    * @notice Subscribe for a certain a month to an individual version
    * @param discordUserId The discord user's id covered by the subscription
    * @param version The version the user will subscribe too
    * @param month The amount of month for the subscription plan
    * @param code The creator code that will be applied for a reduction bonus
    **/
    function individualSubscribe(string calldata discordUserId, Version version, uint8 month, string calldata code) external payable {
        if(tx.origin != msg.sender) revert CallerIsContractError();
        if(version == Version.None || version == Version.ToolsTracker) revert InvalidPlanError();
        if(month < 1) revert MonthlyPlanError();

        uint versionPrice = _individualPrices[version];
        bool has_code = _creators[code].reduction_percentage != 0;
        if(has_code) {
            uint reduction_percentage = _creators[code].reduction_percentage;
            if(reduction_percentage == 0) revert InvalidCreatorCodeError();
            if(msg.value != (versionPrice - (versionPrice * reduction_percentage / 100 )) * month) revert NotEnoughFundError();
        }
        else {
            if(msg.value != versionPrice * month) revert NotEnoughFundError();
        }

        uint date_of_purchase = _subscribers[discordUserId].date_of_purchase;
        uint8 month_bought = _subscribers[discordUserId].month;
        uint current_time = block.timestamp;
        if(date_of_purchase + (month_bought * 30 days) > current_time) // Previous subscription is still valid
        {
            if(uint(_subscribers[discordUserId].version) != uint(version)) revert AlreadyActivePlanError();
            _subscribers[discordUserId].month += month;
        }
        else 
        {
            _subscribers[discordUserId].discord_id = discordUserId;
            _subscribers[discordUserId].date_of_purchase = current_time;
            _subscribers[discordUserId].month = month;
            _subscribers[discordUserId].version = version;
        }
        emit SubscriptionRegister(Receipt(msg.sender, month, false, code), _subscribers[discordUserId]);

        if(has_code) {
            uint cashback_value = (msg.value * _creators[code].cashback_percentage) / 100;
            emit CreatorCashbackProof(_creators[code], cashback_value);
            payable(_creators[code].creator).transfer(cashback_value);
        }
    }

    /**
    * @notice Subscribe for a certain a month to the community version
    * @param discordGuildId The discord guild's id covered by the subscription
    * @param version The version the community will subscribe too
    * @param month The amount of month for the subscription plan
    **/
    function communitySubscribe(string calldata discordGuildId, Version version, uint8 month) external payable {
        if(tx.origin != msg.sender) revert CallerIsContractError();
        if(version == Version.None) revert InvalidPlanError();
        if(month < 1) revert MonthlyPlanError();
        uint versionPrice = _communityPrices[version];
        if(msg.value != versionPrice * month) revert NotEnoughFundError();

        uint date_of_purchase = _communities[discordGuildId].date_of_purchase;
        uint month_bought = _communities[discordGuildId].month;
        uint current_time = block.timestamp;
        if(date_of_purchase + (month_bought * 30 days) > current_time) // Previous subscription is still valid
        {
            if(uint(_communities[discordGuildId].version) != uint(version)) revert AlreadyActivePlanError();
            _communities[discordGuildId].month += month;
        }
        else 
        {
            _communities[discordGuildId].discord_id = discordGuildId;
            _communities[discordGuildId].date_of_purchase = current_time;
            _communities[discordGuildId].month = month;
            _communities[discordGuildId].version = version;
        }
        emit SubscriptionRegister(Receipt(msg.sender, month, true, ""), _communities[discordGuildId]);
    }

    /**
    * @notice Add an subscriber
    *
    * @param discordUserId The discord user id that will be added
    * @param version The version the user will subscribe too
    * @param month The amount of month for the subscription plan
    */
    function forceSubscriber(string calldata discordUserId, Version version, uint8 month) external {
        _enforceAdmin();
        _subscribers[discordUserId].discord_id = discordUserId;
        _subscribers[discordUserId].date_of_purchase = block.timestamp;
        _subscribers[discordUserId].month = month;
        _subscribers[discordUserId].version = version;
        emit SubscriptionRegister(Receipt(msg.sender, month, false, ""), _subscribers[discordUserId]);
    }

    /**
    * @notice Remove an existing subscriber
    *
    * @param discordUserId The discord user id that will be removed
    */
    function removeExistingSubscriber(string calldata discordUserId) external {
        _enforceAdmin();
        delete _subscribers[discordUserId];
    }

    /**
    * @notice Add a community
    *
    * @param discordGuildId The discord guild id that will be added
    * @param version The version the user will subscribe too
    * @param month The amount of month for the subscription plan
    */
    function forceCommunity(string calldata discordGuildId, Version version, uint8 month) external {
        _enforceAdmin();
        _communities[discordGuildId].discord_id = discordGuildId;
        _communities[discordGuildId].date_of_purchase = block.timestamp;
        _communities[discordGuildId].month = month;
        _communities[discordGuildId].version = version;
        emit SubscriptionRegister(Receipt(msg.sender, month, true, ""), _communities[discordGuildId]);
    }

    /**
    * @notice Remove an existing community
    *
    * @param discordGuildId The discord guild id that will be removed
    */
    function removeExistingCommunity(string calldata discordGuildId) external {
        _enforceAdmin();
        delete _communities[discordGuildId];
    }

    /**
    * @notice Insert a new creator
    *
    * @param creatorAddresses The address of the creators that will be added
    * @param creatorReductionPercentages The reduction percentage that will be applied for all creators
    * @param creatorCashbackPercentages The cashback percentage that will be applied for all creators
    * @param creatorCodes The creator codes that will need to be used to retrieve the percentage
    */
    function addNewCreators(address[] calldata creatorAddresses, uint[] calldata creatorReductionPercentages, uint[] calldata creatorCashbackPercentages, string[] calldata creatorCodes, uint totalQuantity) external {
        _enforceAdmin();
        uint testLength = creatorAddresses.length;
        if(testLength != totalQuantity) revert InvalidLengthError();
        testLength = creatorReductionPercentages.length;
        if(testLength != totalQuantity) revert InvalidLengthError();
        testLength = creatorCashbackPercentages.length;
        if(testLength != totalQuantity) revert InvalidLengthError();
        testLength = creatorCodes.length;
        if(testLength != totalQuantity) revert InvalidLengthError();
        
        for(uint i = 0; i < totalQuantity; i++)
        {
            uint creatorReductionPercentage = creatorReductionPercentages[i];
            uint creatorCashbackPercentage = creatorCashbackPercentages[i];
            if(creatorReductionPercentage > 100 || creatorCashbackPercentage > 100 || creatorReductionPercentage == 0 || creatorCashbackPercentage == 0) revert InvalidPercentageError();
            string calldata creatorCode = creatorCodes[i];
            if(_creators[creatorCode].reduction_percentage != 0) revert CreatorCodeExistError();
            _creators[creatorCode].creator = creatorAddresses[i];
            _creators[creatorCode].reduction_percentage = creatorReductionPercentage;
            _creators[creatorCode].cashback_percentage = creatorCashbackPercentage;
            _creators[creatorCode].code = creatorCode;
            emit CreatorRegister(_creators[creatorCode]);
        }
    }


    /**
    * @notice Update the wallet of an existing creator
    *
    * @param creatorCode The creator code that will be removed
    * @param newWallet The new address for the creator
    */
    function updateExistingCreator(string calldata creatorCode, address newWallet) external {
        _enforceAdmin();
        if(_creators[creatorCode].reduction_percentage == 0) revert InvalidCreatorCodeError();
        _creators[creatorCode].creator = newWallet;
    }

    /**
    * @notice Remove an existing creator
    *
    * @param creatorCode The creator code that will be removed
    */
    function removeExistingCreator(string calldata creatorCode) external {
        _enforceAdmin();
        delete _creators[creatorCode];
    }

    /**
    * @notice Change the price of an individual specified version
    *
    * @param version The version whose price will change
    * @param newPrice The new price for the version
    */
    function setIndividualPrice(Version version, uint newPrice) external {
        _enforceAdmin();
        _individualPrices[version] = newPrice;
    }

    /**
    * @notice Change the price of a community specified version
    *
    * @param version The version whose price will change
    * @param newPrice The new price for the version
    */
    function setCommunityPrice(Version version, uint newPrice) external {
        _enforceAdmin();
        _communityPrices[version] = newPrice;
    }

    /**
    * @notice Pay everyone in the team
    */
    function releaseAll() external {
        _enforceAdmin();
        for(uint i = 0 ; i < _teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    /**
    * @notice Return the individual price of a specified version
    *
    * @param version The version to get the price of
    *
    * @return price The price of the version
    **/
    function getIndividualPrice(Version version) public view returns (uint price) {
        return _individualPrices[version];
    }

    /**
    * @notice Return the community price of a specified version
    *
    * @param version The version to get the price of
    *
    * @return price The price of the version
    **/
    function getCommunityPrice(Version version) public view returns (uint price) {
        return _communityPrices[version];
    }

    /**
    * @notice Return a creator associated to the creator code
    *
    * @param creatorCode The creator code to search for
    *
    * @return creator The creator associated to the code
    **/
    function getCreator(string memory creatorCode) public view returns (Creator memory creator) {
        return _creators[creatorCode];
    }

    /**
    * @notice Return a subscriber associated to a discord user id
    *    
    * @param discordUserId The discord user id to search for
    *
    * @return subscriber The subscriber associated to the discord user id
    **/
    function getSubscriber(string calldata discordUserId) public view returns (Subscription memory subscriber) {
        return _subscribers[discordUserId];
    }

    /**
    * @notice Return a community associated to a discord guild id
    *    
    * @param discordGuildId The discord guild id to search for
    *
    * @return community The community associated to the discord guild id
    **/
    function getCommunity(string calldata discordGuildId) public view returns (Subscription memory community) {
        return _communities[discordGuildId];
    }

    function _enforceAdmin() internal view {
        if (owner() != msg.sender) revert NotValidOwnerError(address(this), owner());
    }

    receive() override external payable {
        revert('Cannot send money to contract');
    }
}