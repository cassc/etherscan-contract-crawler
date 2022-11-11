// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Subscription Manager Contract 

import "Ownable.sol";
import "SafeERC20.sol";
import "ITrustedWrapper.sol";
import "ISubscriptionManager.sol";
import "LibEnvelopTypes.sol";


pragma solidity 0.8.16;

contract SubscriptionManagerV1 is Ownable {
    using SafeERC20 for IERC20;
    
    struct SubscriptionType {
        uint256 timelockPeriod;    // in seconds e.g. 3600*24*30*12 = 31104000 = 1 year
        uint256 ticketValidPeriod; // in seconds e.g. 3600*24*30    =  2592000 = 1 month
        uint256 counter;
        bool isAvailable;
    }

    struct PayOption {
        address paymentToken;
        uint256 paymentAmount;
    }

    struct Tariff {
        SubscriptionType subscription;
        PayOption[] payWith;
        uint256[] services;  // List of service codes available on this tariff
    }

    struct Ticket {
        uint256 validUntil; // Unixdate, tickets not valid after
        uint256 countsLeft; // for tarif with fixed use counter
    }

    address  public mainWrapper;
    address  public previousManager;
    Tariff[] public availableTariffs;
    
    // mapping from user addres to subscription type and ticket
    mapping(address => mapping(uint256 => Ticket)) public userTickets;

    // mapping from external contract address to subscription type that enabled;
    mapping(address => bool) public agentRegistry;

    function buySubscription(
        uint256 _tarifIndex,
        uint256 _payWithIndex,
        address _buyFor
    ) external 
      returns(Ticket memory ticket) {
        // It is possible buy ticket for someone
        address ticketReceiver = msg.sender;
        if (_buyFor != address(0)){
           ticketReceiver = _buyFor;
        }

        require(
            availableTariffs[_tarifIndex].subscription.isAvailable,
            'This subscription not available'
        );

        require(
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentAmount > 0,
            'This Payment option not available'
        );

        
        require(
            !_isTicketValid(ticketReceiver, _tarifIndex),
            'Only one valid ticket at time'
        );

        // Lets receive payment tokens FROM sender
        IERC20(
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentToken
        ).safeTransferFrom(
            msg.sender, 
            address(this),
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentAmount
        );

        // Lets approve received for wrap 
        IERC20(
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentToken
        ).safeApprove(
            mainWrapper,
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentAmount
        );

        // Lets wrap with timelock and appropriate params
        ETypes.INData memory _inData;
        ETypes.AssetItem[] memory _collateralERC20 = new ETypes.AssetItem[](1);
        ETypes.Lock[] memory timeLock =  new ETypes.Lock[](1);
        // Only need set timelock for this wNFT
        timeLock[0] = ETypes.Lock(
            0x00, // timelock
            availableTariffs[_tarifIndex].subscription.timelockPeriod + block.timestamp
        ); 
        _inData = ETypes.INData(
            ETypes.AssetItem(
                ETypes.Asset(ETypes.AssetType.EMPTY, address(0)),
                0,0
            ),          // INAsset
            address(0), // Unwrap destinition    
            new ETypes.Fee[](0), // Fees
            //new ETypes.Lock[](0), // Locks
            timeLock,
            new ETypes.Royalty[](0), // Royalties
            ETypes.AssetType.ERC721, // Out type
            0, // Out Balance
            0x0000 // Rules
        );

        _collateralERC20[0] = ETypes.AssetItem(
            ETypes.Asset(
                ETypes.AssetType.ERC20,
                availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentToken
            ),
            0,
            availableTariffs[_tarifIndex].payWith[_payWithIndex].paymentAmount
        );
        
        ITrustedWrapper(mainWrapper).wrap(
            _inData,
            _collateralERC20,
            msg.sender
        );

        //lets safe user ticket (only one ticket available in this version)
        userTickets[ticketReceiver][_tarifIndex] = Ticket(
            availableTariffs[_tarifIndex].subscription.ticketValidPeriod + block.timestamp,
            availableTariffs[_tarifIndex].subscription.counter
        );

    }

    function checkAndFixUserSubscription(
        address _user, 
        uint256 _serviceCode
    ) external returns (bool ok){
        // Check authorization of caller agent
        require(
            _agentStatus(msg.sender),
            'Unknown agent'
        );

        // Check user ticket
        (bool isValid, uint256 tariffIndex) = _isTicketValidForService(_user, _serviceCode);
        
        // Proxy to previos
        if (!isValid && previousManager != address(0)) {
            isValid = ISubscriptionManager(previousManager).checkUserSubscription(
                _user, 
                _serviceCode
            );
            // Case when valid ticket stored in previousManager
            if (isValid) {
                ISubscriptionManager(previousManager).fixUserSubscription(
                    _user, 
                    tariffIndex
                );
                ok = true;
                return ok;
            }
        }
        require(isValid,'Valid ticket not found');
        
        // Fix action (for subscription with counter)
        fixUserSubscription(_user, tariffIndex);
        
        ok = true;
    }

    function fixUserSubscription(
        address _user, 
        uint256 _tariffIndex
    ) public {
        // Check authorization of caller agent
        require(
            _agentStatus(msg.sender),
            'Unknown agent'
        );
        // Fix action (for subscription with counter)
        if (userTickets[_user][_tariffIndex].countsLeft > 0) {
            -- userTickets[_user][_tariffIndex].countsLeft; 
        }
    }

    ////////////////////////////////////////////////////////////////
    
    function checkUserSubscription(
        address _user, 
        uint256 _serviceCode
    ) external view returns (bool ok) {
        (ok,)  = _isTicketValidForService(_user, _serviceCode);
        if (!ok && previousManager != address(0)) {
            ok = ISubscriptionManager(previousManager).checkUserSubscription(
                _user, 
                _serviceCode
            );
        }
    }

    function getUserTickets(address _user) public view returns(Ticket[] memory) {
        Ticket[] memory userTicketsList = new Ticket[](availableTariffs.length);
        for (uint256 i = 0; i < availableTariffs.length; i ++ ) {
            // TODO check that user have ticket???
            userTicketsList[i] = userTickets[_user][i];
        }
        return userTicketsList;
    }

    function getAvailableTariffs() external view returns (Tariff[] memory) {
        return availableTariffs;
    }

    
    ////////////////////////////////////////////////////////////////
    //////////     Admins                                     //////
    ////////////////////////////////////////////////////////////////

    function setMainWrapper(address _wrapper) external onlyOwner {
        mainWrapper = _wrapper;
    }

    function addTarif(Tariff calldata _newTarif) external onlyOwner {
        require (_newTarif.payWith.length > 0, 'No payment method');
        availableTariffs.push(_newTarif);
    }

    function editTarif(
        uint256 _tarifIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable
    ) external onlyOwner 
    {
        availableTariffs[_tarifIndex].subscription.timelockPeriod    = _timelockPeriod;
        availableTariffs[_tarifIndex].subscription.ticketValidPeriod = _ticketValidPeriod;
        availableTariffs[_tarifIndex].subscription.counter = _counter;
        availableTariffs[_tarifIndex].subscription.isAvailable = _isAvailable;    
    }
   
    function addTarifPayOption(
        uint256 _tarifIndex,
        address _paymentToken,
        uint256 _paymentAmount
    ) external onlyOwner 
    {
        availableTariffs[_tarifIndex].payWith.push(
            PayOption(_paymentToken, _paymentAmount)
        );    
    }

    function editTarifPayOption(
        uint256 _tarifIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount
    ) external onlyOwner 
    {
        availableTariffs[_tarifIndex].payWith[_payWithIndex] 
        = PayOption(_paymentToken, _paymentAmount);    
    }

    function addServiceToTarif(
        uint256 _tarifIndex,
        uint256 _serviceCode
    ) external onlyOwner 
    {
        availableTariffs[_tarifIndex].services.push(_serviceCode);
    }

    function removeServiceFromTarif(
        uint256 _tarifIndex,
        uint256 _serviceIndex
    ) external onlyOwner 
    {
        availableTariffs[_tarifIndex].services[_serviceIndex] 
        = availableTariffs[_tarifIndex].services[
           availableTariffs[_tarifIndex].services.length - 1
        ];
        availableTariffs[_tarifIndex].services.pop();
    }

    function setAgentStatus(address _agent, bool _status)
        external onlyOwner 
    {
        agentRegistry[_agent] = _status;
    }

    function setPreviousManager(address _manager) external onlyOwner {
        previousManager = _manager;
    }
    /////////////////////////////////////////////////////////////////////

    function _getFirstTarifWithService(uint256 _serviceCode) 
        internal 
        view 
        returns(uint256 tariffIndex)
    {
        // Lets check all available tarifs
        for (uint256 i = 0; i < availableTariffs.length; i ++ ) {
            if (_isServiceInTariff(availableTariffs[i], _serviceCode)) {
               tariffIndex = i;
            }
        }

    }

    function _isTicketValidForService(address _user, uint256 _serviceCode) 
        internal 
        view 
        returns (bool, uint256) 
    {
        // Lets check all available tarifs
        for (uint256 i = 0; i < availableTariffs.length; i ++ ) {
            // Check that service exist in tarif
            if (_isServiceInTariff(availableTariffs[i], _serviceCode)) {
                // Check that user have valid ticket 
                // on this Tariff
                if (_isTicketValid(_user, i)){
                    return (true, i);
                }
            }
        }
        return (false, type(uint256).max);
    }

    function _isTicketValid(address _user, uint256 _tarifIndex) 
        internal 
        view 
        returns (bool) 
    {
        return userTickets[_user][_tarifIndex].validUntil > block.timestamp 
            || userTickets[_user][_tarifIndex].countsLeft > 0;
    }

    function _isServiceInTariff(
        Tariff memory _tariff, 
        uint256 _serviceCode
    )
        internal 
        view 
        returns (bool) 
    {
        for (uint256 i = 0; i < _tariff.services.length; i ++){
            if (_tariff.services[i] == _serviceCode) {
                return true;
            }
        }
        return false;
    }

    function _getUserTicket(address _user, uint256 _tarifIndex) 
        internal 
        view 
        returns (Ticket memory) 
    {
        return userTickets[_user][_tarifIndex];
    }

    function _agentStatus(address _agent) 
        internal 
        returns(bool)
    {
        return agentRegistry[_agent];
    } 

}