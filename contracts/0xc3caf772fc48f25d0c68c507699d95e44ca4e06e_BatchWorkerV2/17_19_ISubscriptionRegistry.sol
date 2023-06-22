// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SubscriptionType, PayOption, Tariff, Ticket} from "SubscriptionRegistry.sol";
interface ISubscriptionRegistry   {

    /**
     * @notice Add new tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _newTariff full encded Tariff object
     * @return last added tariff index in  Tariff[] array 
     * for current Service Provider (msg.sender)
     */
    function registerServiceTariff(Tariff calldata _newTariff) external returns(uint256);
    
    
    /**
     * @notice Authorize agent for caller service provider
     * @dev Call this method from ServiceProvider
     *
     * @param _agent  - address of contract that implement Agent role 
     * @param _serviceTariffIndexes  - array of index in `availableTariffs` array
     * that available for given `_agent` 
     * @return full array of actual tarifs for this agent 
     */
    function authorizeAgentForService(
        address _agent,
        uint256[] calldata _serviceTariffIndexes
    ) external returns (uint256[] memory);

    /**
     * @notice By Ticket for subscription
     * @dev Call this method from Agent
     *
     * @param _service  - Service Provider address 
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _buyFor - address for whome this ticket would be bought 
     * @param _payer - address of payer for this ticket
     * @return ticket structure that would be use for validate service process
     */ 
    function buySubscription(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex,
        address _buyFor,
        address _payer
    ) external payable returns(Ticket memory ticket);

    /**
     * @notice Edit tariff for caller
     * @dev Call this method from ServiceProvider
     * for setup new tariff 
     * using `Tariff` data type(please see above)
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _timelockPeriod - see SubscriptionType notice above
     * @param _ticketValidPeriod - see SubscriptionType notice above
     * @param _counter - see SubscriptionType notice above
     * @param _isAvailable - see SubscriptionType notice above
     * @param _beneficiary - see SubscriptionType notice above
     */
    function editServiceTariff(
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) external;

    /**
     * @notice Add tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for add tariff PayOption 
     *
     * @param _tariffIndex  - index in `availableTariffs` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * @return last added PaymentOption index in array 
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function addTariffPayOption(
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external returns(uint256);
    
    /**
     * @notice Edit tariff PayOption for exact service
     * @dev Call this method from ServiceProvider
     * for edit tariff PayOption 
     *
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @param _paymentToken - see PayOption notice above
     * @param _paymentAmount - see PayOption notice above
     * @param _agentFeePercent - see PayOption notice above
     * for _tariffIndex Tariff of caller Service Provider (msg.sender)
     */
    function editTariffPayOption(
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) external; 
    
    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ok True in case ticket is valid
     * @return needFix True in case ticket has counter > 0
     */
    function checkUserSubscription(
        address _user, 
        address _service
    ) external view returns (bool ok, bool needFix);


    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * Decrement ticket counter in case it > 0
     * @dev Call this method from ServiceProvider
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @return ok True in case ticket is valid
     */
    function checkAndFixUserSubscription(address _user) external returns (bool ok);

    /**
     * @notice Decrement ticket counter in case it > 0
     * @dev Call this method from new SubscriptionRegistry in case of upgrade
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _serviceFromProxy  - address of service from more new SubscriptionRegistry contract 
     */
    function fixUserSubscription(address _user, address _serviceFromProxy) external;


    /**
     * @notice Returns `_user` ticket for this service.
     * @dev Call this method from any context
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _service - address of Service Provider
     * @return ticket
     */
    function getUserTicketForService(
        address _service,
        address _user
    ) external view returns(Ticket memory); 
    
    /**
     * @notice Returns array of Tariff for `_service`
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getTariffsForService(address _service) external view returns (Tariff[] memory);

    /**
     * @notice Returns ticket price include any fees
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @param _tariffIndex  - index in  `availableTariffs` array 
     * @param _payWithIndex  - index in `tariff.payWith` array 
     * @return tulpe with payment token an ticket price 
     */
    function getTicketPrice(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex
    ) external view returns (address, uint256);

    /**
     * @notice Returns array of Tariff for `_service` assigned to `_agent`
     * @dev Call this method from any context
     *
     * @param _agent - address of Agent
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getAvailableAgentsTariffForService(
        address _agent, 
        address _service
    ) external view returns(Tariff[] memory); 
}