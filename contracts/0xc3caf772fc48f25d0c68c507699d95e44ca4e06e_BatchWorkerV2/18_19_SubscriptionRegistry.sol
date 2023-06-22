// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) Team. Subscription Registry Contract V2
pragma solidity 0.8.19;

import "Ownable.sol";
import "SafeERC20.sol";
import "ITrustedWrapper.sol";
import "LibEnvelopTypes.sol";
import "ISubscriptionRegistry.sol";

/// The subscription platform operates with the following role model 
/// (it is assumed that the actor with the role is implemented as a contract).
/// `Service Provider` is a contract whose services are sold by subscription.
/// `Agent` - a contract that sells a subscription on behalf ofservice provider. 
///  May receive sales commission
///  `Platform` - SubscriptionRegistry contract that performs processingsubscriptions, 
///  fares, tickets

    struct SubscriptionType {
        uint256 timelockPeriod;    // in seconds e.g. 3600*24*30*12 = 31104000 = 1 year
        uint256 ticketValidPeriod; // in seconds e.g. 3600*24*30    =  2592000 = 1 month
        uint256 counter;     // For case when ticket valid for N usage, e.g. for Min N NFTs          
        bool isAvailable;    // USe for stop using tariff because we can`t remove tariff from array 
        address beneficiary; // Who will receive payment for tickets
    }
    struct PayOption {
        address paymentToken;   // token contract address or zero address for native token(ETC etc)
        uint256 paymentAmount;  // ticket price exclude any fees
        uint16 agentFeePercent; // 100%-10000, 20%-2000, 3%-300 
    }

    struct Tariff {
        SubscriptionType subscription; // link to subscriptionType
        PayOption[] payWith; // payment option array. Use it for price in defferent tokens
    }

    // native subscribtionManager tickets format
    struct Ticket {
        uint256 validUntil; // Unixdate, tickets not valid after
        uint256 countsLeft; // for tarif with fixed use counter
    }

/// @title Base contract in Envelop Subscription Platform 
/// @author Envelop Team
/// @notice You can use this contract for make and operate any on-chain subscriptions
/// @dev  Contract that performs processing subscriptions, fares(tariffs), tickets
/// @custom:please see example folder.
contract SubscriptionRegistry is Ownable {
    using SafeERC20 for IERC20;

    uint256 constant public PERCENT_DENOMINATOR = 10000;

    /// @notice Envelop Multisig contract
    address public platformOwner; 
    
    /// @notice Platform owner can receive fee from each payments
    uint16 public platformFeePercent = 50; // 100%-10000, 20%-2000, 3%-300


    /// @notice address used for wrapp & lock incoming assets
    address  public mainWrapper; 
    /// @notice Used in case upgrade this contract
    address  public previousRegistry; 
    /// @notice Used in case upgrade this contract
    address  public proxyRegistry; 

    /// @notice Only white listed assets can be used on platform
    mapping(address => bool) public whiteListedForPayments;
    
    /// @notice from service(=smart contract address) to tarifs
    mapping(address => Tariff[]) public availableTariffs;

    /// @notice from service to agent to available tarifs(tarif index);
    mapping(address => mapping(address => uint256[])) public agentServiceRegistry;
     
    
    /// @notice mapping from user addres to service contract address  to ticket
    mapping(address => mapping(address => Ticket)) public userTickets;

    event PlatfromFeeChanged(uint16 indexed newPercent);
    event WhitelistPaymentTokenChanged(address indexed asset, bool indexed state);
    event TariffChanged(address indexed service, uint256 indexed tariffIndex);
    event TicketIssued(
        address indexed service, 
        address indexed agent, 
        address indexed forUser, 
        uint256 tariffIndex
    );

    constructor(address _platformOwner) {
        require(_platformOwner != address(0),'Zero platform fee receiver');
        platformOwner = _platformOwner;
    } 
   
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
    function registerServiceTariff(Tariff calldata _newTariff) 
        external 
        returns(uint256)
    {
        // TODO
        // Tarif structure check
        // PayWith array whiteList check
        return _addTariff(msg.sender, _newTariff);
    }

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
    ) 
        external
    {
        // TODO
        // Tariff structure check
        // PayWith array whiteList check
        _editTariff(
            msg.sender,
            _tariffIndex, 
            _timelockPeriod,
            _ticketValidPeriod,
            _counter,
            _isAvailable,
            _beneficiary
        );

    }

    
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
    ) external returns(uint256)
    {
        return _addTariffPayOption(
            msg.sender,
            _tariffIndex,
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );
    }

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
    ) external 
    {
        _editTariffPayOption(
            msg.sender,
            _tariffIndex,
            _payWithIndex, 
            _paymentToken,
            _paymentAmount,
            _agentFeePercent
        );
    }

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
    ) external virtual returns (uint256[] memory) 
    {
        // remove previouse tariffs
        delete agentServiceRegistry[msg.sender][_agent];
        uint256[] storage currentServiceTariffsOfAgent = agentServiceRegistry[msg.sender][_agent];
        // check that adding tariffs still available
        for(uint256 i; i < _serviceTariffIndexes.length; ++ i) {
            if (availableTariffs[msg.sender][_serviceTariffIndexes[i]].subscription.isAvailable){
                currentServiceTariffsOfAgent.push(_serviceTariffIndexes[i]);
            }
        }
        return currentServiceTariffsOfAgent;
    }
    
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
    ) external 
      payable
      returns(Ticket memory ticket) {
        // Cant buy ticket for nobody
        require(_buyFor != address(0),'Cant buy ticket for nobody');

        require(
            availableTariffs[_service][_tariffIndex].subscription.isAvailable,
            'This subscription not available'
        );

        // Not used in this implementation
        // require(
        //     availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount > 0,
        //     'This Payment option not available'
        // );

        // Check that agent is authorized for purchace of this service
        require(
            _isAgentAuthorized(msg.sender, _service, _tariffIndex), 
            'Agent not authorized for this service tariff' 
        );
        
        (bool isValid, bool needFix) = _isTicketValid(_buyFor, _service);
        require(!isValid, 'Only one valid ticket at time');

        //lets safe user ticket (only one ticket available in this version)
        ticket = Ticket(
            availableTariffs[_service][_tariffIndex].subscription.ticketValidPeriod + block.timestamp,
            availableTariffs[_service][_tariffIndex].subscription.counter
        );
        userTickets[_buyFor][_service] = ticket;

        // Lets receive payment tokens FROM sender
        if (availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount > 0){
            _processPayment(_service, _tariffIndex, _payWithIndex, _payer);
        }
        emit TicketIssued(_service, msg.sender, _buyFor, _tariffIndex);
    }

    /**
     * @notice Check that `_user` have still valid ticket for this service.
     * Decrement ticket counter in case it > 0
     * @dev Call this method from ServiceProvider
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @return ok True in case ticket is valid
     */
    function checkAndFixUserSubscription(
        address _user
    ) external returns (bool ok){
        
        address _service = msg.sender;
        // Check user ticket
        (bool isValid, bool needFix) = _isTicketValid(_user, msg.sender);
        
        // Proxy to previos
        if (!isValid && previousRegistry != address(0)) {
            (isValid, needFix) = ISubscriptionRegistry(previousRegistry).checkUserSubscription(
                _user, 
                _service
            );
            // Case when valid ticket stored in previousManager
            if (isValid ) {
                if (needFix){
                    ISubscriptionRegistry(previousRegistry).fixUserSubscription(
                        _user, 
                        _service
                    );
                }
                ok = true;
                return ok;
            }
        }
        require(isValid,'Valid ticket not found');
        
        // Fix action (for subscription with counter)
        if (needFix){
            _fixUserSubscription(_user, msg.sender);    
        }
                
        ok = true;
    }

     /**
     * @notice Decrement ticket counter in case it > 0
     * @dev Call this method from new SubscriptionRegistry in case of upgrade
     *
     * @param _user  - address of user who has an ticket and who trying get service 
     * @param _serviceFromProxy  - address of service from more new SubscriptionRegistry contract 
     */
    function fixUserSubscription(
        address _user,
        address _serviceFromProxy
    ) public {
        require(proxyRegistry !=address(0) && msg.sender == proxyRegistry,
            'Only for future registry'
        );
        _fixUserSubscription(_user, _serviceFromProxy);
    }

    ////////////////////////////////////////////////////////////////
    
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
    ) external view returns (bool ok, bool needFix) {
        (ok, needFix)  = _isTicketValid(_user, _service);
        if (!ok && previousRegistry != address(0)) {
            (ok, needFix) = ISubscriptionRegistry(previousRegistry).checkUserSubscription(
                _user, 
                _service
            );
        }
    }

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
    ) public view returns(Ticket memory) 
    {
        return userTickets[_user][_service];
    }

    /**
     * @notice Returns array of Tariff for `_service`
     * @dev Call this method from any context
     *
     * @param _service - address of Service Provider
     * @return Tariff array
     */
    function getTariffsForService(address _service) external view returns (Tariff[] memory) {
        return availableTariffs[_service];
    }

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
    ) public view virtual returns (address, uint256) 
    {
        if (availableTariffs[_service][_tariffIndex].subscription.timelockPeriod != 0)
        {
            return(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );
        } else {
            return(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                + availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                    *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                    /PERCENT_DENOMINATOR
                + availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                        *_platformFeePercent(_service, _tariffIndex, _payWithIndex) 
                        /PERCENT_DENOMINATOR
            );
        }
    }

    /**
     * @notice Returns array of Tariff for `_service` assigned to `_agent`
     * @dev Call this method from any context
     *
     * @param _agent - address of Agent
     * @param _service - address of Service Provider
     * @return tuple with two arrays: indexes and Tariffs
     */
    function getAvailableAgentsTariffForService(
        address _agent, 
        address _service
    ) external view virtual returns(uint256[] memory, Tariff[] memory) 
    {
        //First need get count of tarifs that still available
        uint256 availableCount;
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++i){
            if (availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ].subscription.isAvailable
            ) {++availableCount;}
        }
        
        Tariff[]  memory tariffs = new Tariff[](availableCount);
        uint256[] memory indexes = new uint256[](availableCount);
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++i){
            if (availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ].subscription.isAvailable
            ) 
            {
                tariffs[availableCount - 1] = availableTariffs[_service][
                  agentServiceRegistry[_service][_agent][i]
                ];
                indexes[availableCount - 1] = agentServiceRegistry[_service][_agent][i];
                --availableCount;
            }
        }
        return (indexes, tariffs);
    }    
    ////////////////////////////////////////////////////////////////
    //////////     Admins                                     //////
    ////////////////////////////////////////////////////////////////

    function setAssetForPaymentState(address _asset, bool _isEnable)
        external onlyOwner 
    {
        whiteListedForPayments[_asset] = _isEnable;
        emit WhitelistPaymentTokenChanged(_asset, _isEnable);
    }

    function setMainWrapper(address _wrapper) external onlyOwner {
        mainWrapper = _wrapper;
    }

    function setPlatformOwner(address _newOwner) external {
        require(msg.sender == platformOwner, 'Only platform owner');
        require(_newOwner != address(0),'Zero platform fee receiver');
        platformOwner = _newOwner;
    }

    function setPlatformFeePercent(uint16 _newPercent) external {
        require(msg.sender == platformOwner, 'Only platform owner');
        platformFeePercent = _newPercent;
        emit PlatfromFeeChanged(platformFeePercent);
    }

    

    function setPreviousRegistry(address _registry) external onlyOwner {
        previousRegistry = _registry;
    }

    function setProxyRegistry(address _registry) external onlyOwner {
        proxyRegistry = _registry;
    }
    /////////////////////////////////////////////////////////////////////
    
    function _processPayment(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex,
        address _payer
    ) 
        internal 
        virtual 
        returns(bool)
    {
        // there are two payment method for this implementation.
        // 1. with wrap and lock in asset (no fees)
        // 2. simple payment (agent & platform fee enabled)
        if (availableTariffs[_service][_tariffIndex].subscription.timelockPeriod != 0){
            require(msg.value == 0, 'Ether Not accepted in this method');
            // 1. with wrap and lock in asset
            IERC20(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
            ).safeTransferFrom(
                _payer, 
                address(this),
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );

            // Lets approve received for wrap 
            IERC20(
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
            ).safeApprove(
                mainWrapper,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );

            // Lets wrap with timelock and appropriate params
            ETypes.INData memory _inData;
            ETypes.AssetItem[] memory _collateralERC20 = new ETypes.AssetItem[](1);
            ETypes.Lock[] memory timeLock =  new ETypes.Lock[](1);
            // Only need set timelock for this wNFT
            timeLock[0] = ETypes.Lock(
                0x00, // timelock
                availableTariffs[_service][_tariffIndex].subscription.timelockPeriod + block.timestamp
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
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ),
                0,
                availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
            );
            
            ITrustedWrapper(mainWrapper).wrap(
                _inData,
                _collateralERC20,
                _payer
            );

        } else {
            // 2. simple payment
            if (availableTariffs[_service][_tariffIndex]
                .payWith[_payWithIndex]
                .paymentToken != address(0)
            ) 
            {
                // pay with erc20 
                require(msg.value == 0, 'Ether Not accepted in this method');
                // 2.1. Body payment  
                IERC20(
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ).safeTransferFrom(
                    _payer, 
                    availableTariffs[_service][_tariffIndex].subscription.beneficiary,
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                );

                // 2.2. Agent fee payment
                IERC20(
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                ).safeTransferFrom(
                    _payer, 
                    msg.sender,
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                     *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                     /PERCENT_DENOMINATOR
                );

                // 2.3. Platform fee 
                uint256 _pFee = _platformFeePercent(_service, _tariffIndex, _payWithIndex); 
                if (_pFee > 0) {
                    IERC20(
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentToken
                    ).safeTransferFrom(
                        _payer, 
                        platformOwner, //
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                          *_pFee
                          /PERCENT_DENOMINATOR
                    );
                }

            } else {
                // pay with native token(eth, bnb, etc)
                (, uint256 needPay) = getTicketPrice(_service, _tariffIndex,_payWithIndex);
                require(msg.value >= needPay, 'Not enough ether');
                // 2.4. Body ether payment
                sendValue(
                    payable(availableTariffs[_service][_tariffIndex].subscription.beneficiary),
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                );

                // 2.5. Agent fee payment
                sendValue(
                    payable(msg.sender),
                    availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                      *availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].agentFeePercent
                      /PERCENT_DENOMINATOR
                );

                // 2.3. Platform fee 
                uint256 _pFee = _platformFeePercent(_service, _tariffIndex, _payWithIndex); 
                if (_pFee > 0) {

                    sendValue(
                        payable(platformOwner),
                        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex].paymentAmount
                          *_pFee
                          /PERCENT_DENOMINATOR
                    );
                }
                // return change
                if  ((msg.value - needPay) > 0) {
                    address payable s = payable(_payer);
                    s.transfer(msg.value - needPay);
                }
            }
        }
    }

    // In this impementation params not used. 
    // Can be ovveriden in other cases
    function _platformFeePercent(
        address _service, 
        uint256 _tariffIndex, 
        uint256  _payWithIndex
    ) internal view virtual returns(uint256) 
    {
        return platformFeePercent;
    }

    function _addTariff(address _service, Tariff calldata _newTariff) 
        internal returns(uint256) 
    {
        require (_newTariff.payWith.length > 0, 'No payment method');
        for (uint256 i; i < _newTariff.payWith.length; ++i){
            require(
                whiteListedForPayments[_newTariff.payWith[i].paymentToken],
                'Not whitelisted for payments'
            );      
        }
        require(
            _newTariff.subscription.ticketValidPeriod > 0 
            || _newTariff.subscription.counter > 0,
            'Tariff has no valid ticket option'  
        );
        availableTariffs[_service].push(_newTariff);
        emit TariffChanged(_service, availableTariffs[_service].length - 1);
        return availableTariffs[_service].length - 1;
    }


    function _editTariff(
        address _service,
        uint256 _tariffIndex, 
        uint256 _timelockPeriod,
        uint256 _ticketValidPeriod,
        uint256 _counter,
        bool _isAvailable,
        address _beneficiary
    ) internal  
    {
        availableTariffs[_service][_tariffIndex].subscription.timelockPeriod    = _timelockPeriod;
        availableTariffs[_service][_tariffIndex].subscription.ticketValidPeriod = _ticketValidPeriod;
        availableTariffs[_service][_tariffIndex].subscription.counter = _counter;
        availableTariffs[_service][_tariffIndex].subscription.isAvailable = _isAvailable;    
        availableTariffs[_service][_tariffIndex].subscription.beneficiary = _beneficiary;    
        emit TariffChanged(_service, _tariffIndex);
    }
   
    function _addTariffPayOption(
        address _service,
        uint256 _tariffIndex,
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) internal returns(uint256)
    {
        require(whiteListedForPayments[_paymentToken], 'Not whitelisted for payments');
        availableTariffs[_service][_tariffIndex].payWith.push(
            PayOption(_paymentToken, _paymentAmount, _agentFeePercent)
        ); 
        emit TariffChanged(_service, _tariffIndex);
        return availableTariffs[_service][_tariffIndex].payWith.length - 1;
    }

    function _editTariffPayOption(
        address _service,
        uint256 _tariffIndex,
        uint256 _payWithIndex, 
        address _paymentToken,
        uint256 _paymentAmount,
        uint16 _agentFeePercent
    ) internal  
    {
        require(whiteListedForPayments[_paymentToken], 'Not whitelisted for payments');
        availableTariffs[_service][_tariffIndex].payWith[_payWithIndex] 
        = PayOption(_paymentToken, _paymentAmount, _agentFeePercent);  
        emit TariffChanged(_service, _tariffIndex);  
    }

    function _fixUserSubscription(
        address _user,
        address _service
    ) internal {
       
        // Fix action (for subscription with counter)
        if (userTickets[_user][_service].countsLeft > 0) {
            -- userTickets[_user][_service].countsLeft; 
        }
    }

        
   function _isTicketValid(address _user, address _service) 
        internal 
        view 
        returns (bool isValid, bool needFix ) 
    {
        isValid =  userTickets[_user][_service].validUntil > block.timestamp 
            || userTickets[_user][_service].countsLeft > 0;
        needFix =  userTickets[_user][_service].countsLeft > 0;   
    }

    function _isAgentAuthorized(
        address _agent, 
        address _service, 
        uint256 _tariffIndex
    ) 
        internal
        view
        returns(bool authorized)
    {
        for (uint256 i; i < agentServiceRegistry[_service][_agent].length; ++ i){
            if (agentServiceRegistry[_service][_agent][i] == _tariffIndex){
                authorized = true;
                return authorized;
            }
        }
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}