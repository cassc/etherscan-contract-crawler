// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) Subscription Registry Contract V2


/// The subscription platform operates with the following role model 
/// (it is assumed that the actor with the role is implemented as a contract).
/// `Service Provider` is a contract whose services are sold by subscription.
/// `Agent` - a contract that sells a subscription on behalf ofservice provider. 
///  May receive sales commission
///  `Platform` - SubscriptionRegistry contract that performs processingsubscriptions, 
///  fares, tickets


pragma solidity 0.8.19;

import "Ownable.sol";
import "ServiceProvider.sol";

/// @title ServiceProviderOwnable  contract 
/// @author Envelop project Team
/// @notice Contract implements Ownable pattern for service providers.
/// @dev Inherit this code in service provider contract that
/// want use subscription. 
contract ServiceProviderOwnable is ServiceProvider, Ownable {


    constructor(address _subscrRegistry)
        ServiceProvider(_subscrRegistry) 
    {
        
    }

     ///////////////////////////////////////
    //     Admin functions               ///
    ////////////////////////////////////////
    function newTariff(Tariff memory _newTariff) external onlyOwner returns(uint256 tariffIndex) {
        tariffIndex = _registerServiceTariff(_newTariff); 
    }

    function registerServiceTariff(Tariff memory _newTariff) 
        external onlyOwner returns(uint256)
    {
        return _registerServiceTariff(_newTariff);
    }

    function editServiceTariff(
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) external onlyOwner 
    {
        _editServiceTariff(
            _tariffIndex, 
            _timelockPeriod,
            _ticketValidPeriod,
            _counter,
            _isAvailable,
            _beneficiary
        );
    }

    function addPayOption(
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external onlyOwner returns(uint256 index)
    {
        index = _addTariffPayOption(
            _tariffIndex,
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );
    }

    function editPayOption(
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external onlyOwner
    {
        _editTariffPayOption(
            _tariffIndex,
            _payWithIndex, 
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );

    }

    function authorizeAgentForService(
        address _agent,
        uint256[] memory _serviceTariffIndexes
    ) external onlyOwner returns (uint256[] memory actualTariffs)
    {
        actualTariffs = _authorizeAgentForService(
            _agent,
            _serviceTariffIndexes
        );

    }

    function setSubscriptionRegestry(address _subscrRegistry) external onlyOwner {
        subscriptionRegistry = ISubscriptionRegistry(_subscrRegistry);
    }

}