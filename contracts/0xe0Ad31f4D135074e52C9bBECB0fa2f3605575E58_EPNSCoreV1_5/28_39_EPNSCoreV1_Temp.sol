pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

/**
 * EPNS Core is the main protocol that deals with the imperative
 * features and functionalities like Channel Creation, pushChannelAdmin etc.
 *
 * This protocol will be specifically deployed on Ethereum Blockchain while the Communicator
 * protocols can be deployed on Multiple Chains.
 * The EPNS Core is more inclined towards the storing and handling the Channel related
 * Functionalties.
 **/
import "./EPNSCoreStorageV1_5.sol";
import "../interfaces/IADai.sol";
import "../interfaces/ITempStorage.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IEPNSCommV1.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

// import "hardhat/console.sol";

contract EPNSCoreV1_Temp is Initializable, EPNSCoreStorageV1_5, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /* ***************
        EVENTS
     *************** */
    event UpdateChannel(address indexed channel, bytes identity);
    event ChannelVerified(address indexed channel, address indexed verifier);
    event ChannelVerificationRevoked(
        address indexed channel,
        address indexed revoker
    );

    event DeactivateChannel(
        address indexed channel,
        uint256 indexed amountRefunded
    );
    event ReactivateChannel(
        address indexed channel,
        uint256 indexed amountDeposited
    );
    event ChannelBlocked(address indexed channel);
    event AddChannel(
        address indexed channel,
        ChannelType indexed channelType,
        bytes identity
    );
    event ChannelNotifcationSettingsAdded(
        address _channel,
        uint256 totalNotifOptions,
        string _notifSettings,
        string _notifDescription
    );

    /* **************
        MODIFIERS
    ***************/
    modifier onlyPushChannelAdmin() {
        require(
            msg.sender == pushChannelAdmin,
            "EPNSCoreV1::onlyPushChannelAdmin: Caller not pushChannelAdmin"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == governance,
            "EPNSCoreV1::onlyGovernance: Caller not Governance"
        );
        _;
    }

    modifier onlyInactiveChannels(address _channel) {
        require(
            channels[_channel].channelState == 0,
            "EPNSCoreV1::onlyInactiveChannels: Channel already Activated"
        );
        _;
    }
    modifier onlyActivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 1,
            "EPNSCoreV1::onlyActivatedChannels: Channel Deactivated, Blocked or Does Not Exist"
        );
        _;
    }

    modifier onlyDeactivatedChannels(address _channel) {
        require(
            channels[_channel].channelState == 2,
            "EPNSCoreV1::onlyDeactivatedChannels: Channel is not Deactivated Yet"
        );
        _;
    }

    modifier onlyUnblockedChannels(address _channel) {
        require(
            ((channels[_channel].channelState != 3) &&
                (channels[_channel].channelState != 0)),
            "EPNSCoreV1::onlyUnblockedChannels: Channel is BLOCKED Already or Not Activated Yet"
        );
        _;
    }

    modifier onlyChannelOwner(address _channel) {
        require(
            ((channels[_channel].channelState == 1 && msg.sender == _channel) ||
                (msg.sender == pushChannelAdmin && _channel == address(0x0))),
            "EPNSCoreV1::onlyChannelOwner: Channel not Exists or Invalid Channel Owner"
        );
        _;
    }

    modifier onlyUserAllowedChannelType(ChannelType _channelType) {
        require(
            (_channelType == ChannelType.InterestBearingOpen ||
                _channelType == ChannelType.InterestBearingMutual),
            "EPNSCoreV1::onlyUserAllowedChannelType: Channel Type Invalid"
        );

        _;
    }

    /* ***************
        INITIALIZER
    *************** */

    function initialize(
        address _pushChannelAdmin,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint256 _referralCode
    ) public initializer returns (bool success) {
        // setup addresses
        pushChannelAdmin = _pushChannelAdmin;
        governance = _pushChannelAdmin; // Will be changed on-Chain governance Address later
        daiAddress = _daiAddress;
        aDaiAddress = _aDaiAddress;
        WETH_ADDRESS = _wethAddress;
        REFERRAL_CODE = _referralCode;
        PUSH_TOKEN_ADDRESS = _pushTokenAddress;
        UNISWAP_V2_ROUTER = _uniswapRouterAddress;
        lendingPoolProviderAddress = _lendingPoolProviderAddress;

        FEE_AMOUNT = 10 ether; // 10 DAI out of total deposited DAIs is charged for Deactivating a Channel
        MIN_POOL_CONTRIBUTION = 50 ether; // 50 DAI or above to create the channel
        ADD_CHANNEL_MIN_FEES = 50 ether; // can never be below MIN_POOL_CONTRIBUTION

        ADJUST_FOR_FLOAT = 10**7;
        groupLastUpdate = block.number;
        groupNormalizedWeight = ADJUST_FOR_FLOAT; // Always Starts with 1 * ADJUST FOR FLOAT

        // Create Channel
        success = true;
    }

    /* ***************

    SETTER FUNCTIONS

    *************** */
    function updateWETHAddress(address _newAddress)
        external
        onlyPushChannelAdmin
    {
        WETH_ADDRESS = _newAddress;
    }

    function updateUniswapRouterAddress(address _newAddress)
        external
        onlyPushChannelAdmin
    {
        UNISWAP_V2_ROUTER = _newAddress;
    }

    function setEpnsCommunicatorAddress(address _commAddress)
        external
        onlyPushChannelAdmin
    {
        epnsCommunicator = _commAddress;
    }

    function setGovernanceAddress(address _governanceAddress)
        external
        onlyPushChannelAdmin
    {
        governance = _governanceAddress;
    }

    function setMigrationComplete() external onlyPushChannelAdmin {
        isMigrationComplete = true;
    }

    function setFeeAmount(uint256 _newFees)
        external
        onlyGovernance
    {
        require(
            _newFees > 0,
            "EPNSCoreV1.5::setFeeAmount: Fee amount must be greater than ZERO"
        );
        FEE_AMOUNT = _newFees;
    }

    function pauseContract() external onlyGovernance {
        _pause();
    }

    function unPauseContract() external onlyGovernance {
        _unpause();
    }

    /**
     * @notice Allows to set the Minimum amount threshold for Creating Channels
     *
     * @dev    Minimum required amount can never be below MIN_POOL_CONTRIBUTION
     *
     * @param _newFees new minimum fees required for Channel Creation
     **/
    function setMinChannelCreationFees(uint256 _newFees)
        external
        onlyGovernance
    {
        require(
            _newFees >= MIN_POOL_CONTRIBUTION,
            "EPNSCoreV1::setMinChannelCreationFees: Fees should be greater than MIN_POOL_CONTRIBUTION"
        );
        ADD_CHANNEL_MIN_FEES = _newFees;
    }

    function transferPushChannelAdminControl(address _newAdmin)
        external
        onlyPushChannelAdmin
    {
        require(
            _newAdmin != address(0),
            "EPNSCoreV1::transferPushChannelAdminControl: Invalid Address"
        );
        require(
            _newAdmin != pushChannelAdmin,
            "EPNSCoreV1::transferPushChannelAdminControl: Admin address is same"
        );
        pushChannelAdmin = _newAdmin;
    }

    /* ***********************************

        CHANNEL RELATED FUNCTIONALTIES

    **************************************/
    function getChannelState(address _channel)
        external
        view
        returns (uint256 state)
    {
        state = channels[_channel].channelState;
    }

    /**
     * @notice Allows Channel Owner to update their Channel Description/Detail
     *
     * @dev    Emits an event with the new identity for the respective Channel Address
     *         Records the Block Number of the Block at which the Channel is being updated with a New Identity
     *
     * @param _channel     address of the Channel
     * @param _newIdentity bytes Value for the New Identity of the Channel
     **/
    function updateChannelMeta(address _channel, bytes calldata _newIdentity)
        external
        onlyChannelOwner(_channel)
    {
        emit UpdateChannel(_channel, _newIdentity);

        _updateChannelMeta(_channel);
    }

    function _updateChannelMeta(address _channel) internal {
        channels[_channel].channelUpdateBlock = block.number;
    }

    function createChannelForPushChannelAdmin() external onlyPushChannelAdmin {
        require(
            !oneTimeCheck,
            "EPNSCoreV1::createChannelForPushChannelAdmin: Channel for Admin is already Created"
        );

        // Add EPNS Channels
        // First is for all users
        // Second is all channel alerter, amount deposited for both is 0
        // to save gas, emit both the events out
        // identity = payloadtype + payloadhash

        // EPNS ALL USERS

        _createChannel(pushChannelAdmin, ChannelType.ProtocolNonInterest, 0); // should the owner of the contract be the channel? should it be pushChannelAdmin in this case?
        emit AddChannel(
            pushChannelAdmin,
            ChannelType.ProtocolNonInterest,
            "1+QmSbRT16JVF922yAB26YxWFD6DmGsnSHm8VBrGUQnXTS74"
        );

        // EPNS ALERTER CHANNEL
        _createChannel(address(0x0), ChannelType.ProtocolNonInterest, 0);
        emit AddChannel(
            address(0x0),
            ChannelType.ProtocolNonInterest,
            "1+QmTCKYL2HRbwD6nGNvFLe4wPvDNuaYGr6RiVeCvWjVpn5s"
        );

        oneTimeCheck = true;
    }

    /**
     * @notice An external function that allows users to Create their Own Channels by depositing a valid amount of DAI
     * @dev    Only allows users to Create One Channel for a specific address.
     *         Only allows a Valid Channel Type to be assigned for the Channel Being created.
     *         Validates and Transfers the amount of DAI from the Channel Creator to this Contract Address
     *         Deposits the Funds the Lending Pool and creates the Channel for the msg.sender.
     * @param  _channelType the type of the Channel Being created
     * @param  _identity the bytes value of the identity of the Channel
     * @param  _amount Amount of DAI to be deposited before Creating the Channel
     **/
    function createChannelWithFees(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount
    )
        external
        whenNotPaused
        onlyInactiveChannels(msg.sender)
        onlyUserAllowedChannelType(_channelType)
    {
        // Save gas, Emit the event out
        emit AddChannel(msg.sender, _channelType, _identity);

        // Bubble down to create channel
        _createChannelWithFees(msg.sender, _channelType, _amount);
    }

    function _createChannelWithFees(
        address _channel,
        ChannelType _channelType,
        uint256 _amount
    ) private {
        // Check if it's equal or above Channel Pool Contribution
        require(
            _amount >= ADD_CHANNEL_MIN_FEES,
            "EPNSCoreV1::_createChannelWithFees: Insufficient Deposit Amount"
        );
        IERC20(daiAddress).safeTransferFrom(_channel, address(this), _amount);
        _depositFundsToPool(_amount);
        _createChannel(_channel, _channelType, _amount);
    }

    /**
     * @notice Migration function that allows pushChannelAdmin to migrate the previous Channel Data to this protocol
     *
     * @dev   can only be Called by the pushChannelAdmin
     *        Channel's identity is simply emitted out
     *        Channel's on-Chain details are stored by calling the "_crateChannel" function
     *        DAI required for Channel Creation will be PAID by pushChannelAdmin
     *
     * @param _startIndex       starting Index for the LOOP
     * @param _endIndex         Last Index for the LOOP
     * @param _channelAddresses array of address of the Channel
     * @param _channelTypeList   array of type of the Channel being created
     * @param _identityList     array of list of identity Bytes
     * @param _amountList       array of amount of DAI to be depositeds
     **/
    function migrateChannelData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelAddresses,
        ChannelType[] calldata _channelTypeList,
        bytes[] calldata _identityList,
        uint256[] calldata _amountList
    ) external onlyPushChannelAdmin returns (bool) {
        require(
            !isMigrationComplete,
            "EPNSCoreV1::migrateChannelData: Migration is already done"
        );

        require(
            (_channelAddresses.length == _channelTypeList.length) &&
                (_channelAddresses.length == _identityList.length) &&
                (_channelAddresses.length == _amountList.length),
            "EPNSCoreV1::migrateChannelData: Unequal Arrays passed as Argument"
        );

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            if (channels[_channelAddresses[i]].channelState != 0) {
                continue;
            } else {
                IERC20(daiAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amountList[i]
                );
                _depositFundsToPool(_amountList[i]);
                emit AddChannel(
                    _channelAddresses[i],
                    _channelTypeList[i],
                    _identityList[i]
                );
                _createChannel(
                    _channelAddresses[i],
                    _channelTypeList[i],
                    _amountList[i]
                );
            }
        }
        return true;
    }

    function swapADaiForPush(uint256 _amountOutMin)
        external
        onlyPushChannelAdmin
        whenPaused
    {
        // get dai from all aDai
        uint256 _contractBalance = IERC20(aDaiAddress).balanceOf(address(this));
        require(
            _contractBalance > 0,
            "EPNSCoreV1::swapADaiForPush: Contract ADai balance is zero"
        );
        swapADaiForDai(_contractBalance);

        address _daiAddress = daiAddress;
        address _uniswap_v2_router = UNISWAP_V2_ROUTER;
        address _push_token_address = PUSH_TOKEN_ADDRESS;

        IERC20(_daiAddress).approve(_uniswap_v2_router, _contractBalance);

        address[] memory path = new address[](3);
        path[0] = _daiAddress;
        path[1] = WETH_ADDRESS;
        path[2] = _push_token_address;

        IUniswapV2Router(_uniswap_v2_router).swapExactTokensForTokens(
            _contractBalance,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Update pool funds
        CHANNEL_POOL_FUNDS = IERC20(_push_token_address).balanceOf(address(this));
    }

    /**
     * @notice Function to adjust the poolContribution and weight of channels after swap of DAI to PUSH in core contract.
     * @dev - Should be called only by the pushChannelAdmin
     *      - Can only be called for channels that are not in Inactive State.
     *      - Can only be called for channels whose version is not 2, i.e., old Channels (created using DAI)
     *      - This function updates/adjusts the pool contribution, new weight and the version of the Channel.
     * 
     * @param _tempStorageAddress address of a temp contract to store and flag the adjusted Channels.
     * @param _startIndex starting Index for the LOOP
     * @param _endIndex   Last Index for the LOOP
     * @param _oldPoolFunds total amount of DAI in the older contract version.
     * @param _newPoolFunds total amount of PUSH in the new contract version.
     * @param _channelAddresses array of address of the Channel
     */
     function adjustChannelPoolContributions(
       address _tempStorageAddress,
       uint256 _startIndex,
       uint256 _endIndex,
       uint256 _oldPoolFunds,
       uint256 _newPoolFunds,
       address[] calldata _channelAddresses
      ) external onlyPushChannelAdmin() whenPaused returns(bool){
        uint256 poolFees = FEE_AMOUNT;
        uint256 poolFundRatio = _newPoolFunds.mul(ADJUST_FOR_FLOAT).div(_oldPoolFunds);

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            if(channels[_channelAddresses[i]].channelState == 0 ||
              ITempStorage(_tempStorageAddress).isChannelAdjusted(_channelAddresses[i]))
              {
                continue;
              } else{
                // Calculating new adjusted poolContribution & channelWeight

                uint256 adjustedPoolContribution = channels[_channelAddresses[i]].poolContribution.mul(poolFundRatio).div(ADJUST_FOR_FLOAT);
                uint256 newPoolContribution = adjustedPoolContribution.sub(poolFees);
                PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(poolFees);
                CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(poolFees);
                uint256 adjustedNewWeight = newPoolContribution.mul(ADJUST_FOR_FLOAT).div(MIN_POOL_CONTRIBUTION);

                channels[_channelAddresses[i]].channelWeight = adjustedNewWeight;
                channels[_channelAddresses[i]].poolContribution = newPoolContribution;
                ITempStorage(_tempStorageAddress).setChannelAdjusted(_channelAddresses[i]);
            }
        }
        return true;
     }

    /**
     * @notice Base Channel Creation Function that allows users to Create Their own Channels and Stores crucial details about the Channel being created
     * @dev    -Initializes the Channel Struct
     *         -Subscribes the Channel's Owner to Imperative EPNS Channels as well as their Own Channels
     *         -Increases Channel Counts and Readjusts the FS of Channels
     * @param _channel         address of the channel being Created
     * @param _channelType     The type of the Channel
     * @param _amountDeposited The total amount being deposited while Channel Creation
     **/
    function _createChannel(
        address _channel,
        ChannelType _channelType,
        uint256 _amountDeposited
    ) private {
        // Calculate channel weight
        uint256 _channelWeight = _amountDeposited.mul(ADJUST_FOR_FLOAT).div(
            MIN_POOL_CONTRIBUTION
        );

        // Next create the channel and mark user as channellized
        channels[_channel].channelState = 1;

        channels[_channel].poolContribution = _amountDeposited;
        channels[_channel].channelType = _channelType;
        channels[_channel].channelStartBlock = block.number;
        channels[_channel].channelUpdateBlock = block.number;
        channels[_channel].channelWeight = _channelWeight;

        // Add to map of addresses and increment channel count
        channelById[channelsCount] = _channel;
        channelsCount = channelsCount.add(1);

        // Readjust fair share if interest bearing
        if (
            _channelType == ChannelType.ProtocolPromotion ||
            _channelType == ChannelType.InterestBearingOpen ||
            _channelType == ChannelType.InterestBearingMutual
        ) {
            (
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            ) = _readjustFairShareOfChannels(
                ChannelAction.ChannelAdded,
                _channelWeight,
                0,
                groupFairShareCount,
                groupNormalizedWeight,
                groupHistoricalZ,
                groupLastUpdate
            );
        }

        // Subscribe them to their own channel as well
        if (_channel != pushChannelAdmin) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(_channel, _channel);
        }

        // All Channels are subscribed to EPNS Alerter as well, unless it's the EPNS Alerter channel iteself
        if (_channel != address(0x0)) {
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                address(0x0),
                _channel
            );
            IEPNSCommV1(epnsCommunicator).subscribeViaCore(
                _channel,
                pushChannelAdmin
            );
        }
    }

    /** @notice - Deliminated Notification Settings string contains -> Total Notif Options + Notification Settings
     * For instance: 5+1-0+2-50-20-100+1-1+2-78-10-150
     *  5 -> Total Notification Options provided by a Channel owner
     *
     *  For Boolean Type Notif Options
     *  1-0 -> 1 stands for BOOLEAN type - 0 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case FALSE.
     *  1-1 stands for BOOLEAN type - 1 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case TRUE.
     *
     *  For SLIDER TYPE Notif Options
     *   2-50-20-100 -> 2 stands for SLIDER TYPE - 50 stands for Default Value for that Option - 20 is the Start Range of that SLIDER - 100 is the END Range of that SLIDER Option
     *  2-78-10-150 -> 2 stands for SLIDER TYPE - 78 stands for Default Value for that Option - 10 is the Start Range of that SLIDER - 150 is the END Range of that SLIDER Option
     *
     *  @param _notifOptions - Total Notification options provided by the Channel Owner
     *  @param _notifSettings- Deliminated String of Notification Settings
     *  @param _notifDescription - Description of each Notification that depicts the Purpose of that Notification
     **/
    function createChannelSettings(
        uint256 _notifOptions,
        string calldata _notifSettings,
        string calldata _notifDescription
    ) external onlyActivatedChannels(msg.sender) {
        string memory notifSetting = string(
            abi.encodePacked(
                Strings.toString(_notifOptions),
                "+",
                _notifSettings
            )
        );
        channelNotifSettings[msg.sender] = notifSetting;
        emit ChannelNotifcationSettingsAdded(
            msg.sender,
            _notifOptions,
            notifSetting,
            _notifDescription
        );
    }

    /**
     * @notice Allows Channel Owner to Deactivate his/her Channel for any period of Time. Channels Deactivated can be Activated again.
     * @dev    - Function can only be Called by Already Activated Channels
     *         - Calculates the Total DAI Deposited by Channel Owner while Channel Creation.
     *         - Deducts FEE_AMOUNT from the total Deposited DAI and Transfers back the remaining amount of DAI in the form of PUSH tokens.
     *         - Calculates the New Channel Weight and Readjusts the FS Ratio accordingly.
     *         - Updates the State of the Channel(channelState) and the New Channel Weight in the Channel's Struct
     *         - In case, the Channel Owner wishes to reactivate his/her channel, they need to Deposit at least the Minimum required DAI while reactivating.
     **/

    function deactivateChannel(uint256 _amountsOutValue)
        external
        whenNotPaused
        onlyActivatedChannels(msg.sender)
    {
        Channel storage channelData = channels[msg.sender];

        uint256 totalAmountDeposited = channelData.poolContribution;
        uint256 totalRefundableAmount = totalAmountDeposited.sub(
            FEE_AMOUNT
        );

        uint256 _oldChannelWeight = channelData.channelWeight;
        uint256 _newChannelWeight = FEE_AMOUNT
            .mul(ADJUST_FOR_FLOAT)
            .div(MIN_POOL_CONTRIBUTION);

        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _newChannelWeight,
            _oldChannelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channelData.channelState = 2;
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(totalRefundableAmount);
        channelData.channelWeight = _newChannelWeight;
        channelData.poolContribution = FEE_AMOUNT;

        swapAndTransferPUSH(
            msg.sender,
            totalRefundableAmount,
            _amountsOutValue
        );
        emit DeactivateChannel(msg.sender, totalRefundableAmount);
    }

    /**
     * @notice Allows Channel Owner to Reactivate his/her Channel again.
     * @dev    - Function can only be called by previously Deactivated Channels
     *         - Channel Owner must Depost at least minimum amount of DAI to reactivate his/her channel.
     *         - Deposited Dai goes thorugh similar procedure and is deposited to AAVE .
     *         - Calculation of the new Channel Weight is performed and the FairShare is Readjusted once again with relevant details
     *         - Updates the State of the Channel(channelState) in the Channel's Struct.
     * @param _amount Amount of Dai to be deposited
     **/

    function reactivateChannel(uint256 _amount)
        external
        whenNotPaused
        onlyDeactivatedChannels(msg.sender)
    {
        uint _minPoolContribution = MIN_POOL_CONTRIBUTION;
        require(
            _amount >= _minPoolContribution,
            "EPNSCoreV1::reactivateChannel: Insufficient Funds Passed for Channel Reactivation"
        );
        IERC20(daiAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _depositFundsToPool(_amount);

        uint256 _oldChannelWeight = channels[msg.sender].channelWeight;
        uint256 newChannelPoolContribution = _amount.add(
            FEE_AMOUNT
        );
        uint256 _channelWeight = newChannelPoolContribution
            .mul(ADJUST_FOR_FLOAT)
            .div(_minPoolContribution);
        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelUpdated,
            _channelWeight,
            _oldChannelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        channels[msg.sender].channelState = 1;
        channels[msg.sender].poolContribution += _amount;
        channels[msg.sender].channelWeight = _channelWeight;

        emit ReactivateChannel(msg.sender, _amount);
    }

    /**
     * @notice ALlows the pushChannelAdmin to Block any particular channel Completely.
     *
     * @dev    - Can only be called by pushChannelAdmin
     *         - Can only be Called for Activated Channels
     *         - Can only Be Called for NON-BLOCKED Channels
     *
     *         - Updates channel's state to BLOCKED ('3')
     *         - Updates Channel's Pool Contribution to ZERO
     *         - Updates Channel's Weight to ZERO
     *         - Increases the Protocol Fee Pool
     *         - Decreases the Channel Count
     *         - Readjusts the FS Ratio
     *         - Emit 'ChannelBlocked' Event
     * @param _channelAddress Address of the Channel to be blocked
     **/

    function blockChannel(address _channelAddress)
        external
        whenNotPaused
        onlyPushChannelAdmin
        onlyUnblockedChannels(_channelAddress)
    {
        Channel storage channelData = channels[_channelAddress];
        uint _channelDeactivationFees = FEE_AMOUNT;

        uint256 totalAmountDeposited = channelData.poolContribution;
        uint256 totalRefundableAmount = totalAmountDeposited.sub(
            _channelDeactivationFees
        );

        uint256 _oldChannelWeight = channelData.channelWeight;
        uint256 _newChannelWeight = _channelDeactivationFees
            .mul(ADJUST_FOR_FLOAT)
            .div(MIN_POOL_CONTRIBUTION);

        channelsCount = channelsCount.sub(1);

        channelData.channelState = 3;
        channelData.channelWeight = _newChannelWeight;
        channelData.channelUpdateBlock = block.number;
        channelData.poolContribution = _channelDeactivationFees;
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(totalRefundableAmount);
        (
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        ) = _readjustFairShareOfChannels(
            ChannelAction.ChannelRemoved,
            _newChannelWeight,
            _oldChannelWeight,
            groupFairShareCount,
            groupNormalizedWeight,
            groupHistoricalZ,
            groupLastUpdate
        );

        emit ChannelBlocked(_channelAddress);
    }

    /* **************
    => CHANNEL VERIFICATION FUNCTIONALTIES <=
    *************** */

    /**
     * @notice    Function is designed to tell if a channel is verified or not
     * @dev       Get if channel is verified or not
     * @param    _channel Address of the channel to be Verified
     * @return   verificationStatus  Returns 0 for not verified, 1 for primary verification, 2 for secondary verification
     **/
    function getChannelVerfication(address _channel)
        public
        view
        returns (uint8 verificationStatus)
    {
        address verifiedBy = channels[_channel].verifiedBy;
        bool logicComplete = false;

        // Check if it's primary verification
        if (
            verifiedBy == pushChannelAdmin ||
            _channel == address(0x0) ||
            _channel == pushChannelAdmin
        ) {
            // primary verification, mark and exit
            verificationStatus = 1;
        } else {
            // can be secondary verification or not verified, dig deeper
            while (!logicComplete) {
                if (verifiedBy == address(0x0)) {
                    verificationStatus = 0;
                    logicComplete = true;
                } else if (verifiedBy == pushChannelAdmin) {
                    verificationStatus = 2;
                    logicComplete = true;
                } else {
                    // Upper drill exists, go up
                    verifiedBy = channels[verifiedBy].verifiedBy;
                }
            }
        }
    }

    function batchVerification(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelList
    ) external onlyPushChannelAdmin returns (bool) {
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            verifyChannel(_channelList[i]);
        }
        return true;
    }

    function batchRevokeVerification(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelList
    ) external onlyPushChannelAdmin returns (bool) {
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            unverifyChannel(_channelList[i]);
        }
        return true;
    }

    /**
     * @notice    Function is designed to verify a channel
     * @dev       Channel will be verified by primary or secondary verification, will fail or upgrade if already verified
     * @param    _channel Address of the channel to be Verified
     **/
    function verifyChannel(address _channel)
        public
        onlyActivatedChannels(_channel)
    {
        // Check if caller is verified first
        uint8 callerVerified = getChannelVerfication(msg.sender);
        require(
            callerVerified > 0,
            "EPNSCoreV1::verifyChannel: Caller is not verified"
        );

        // Check if channel is verified
        uint8 channelVerified = getChannelVerfication(_channel);
        require(
              (channelVerified == 0) ||
                (msg.sender == pushChannelAdmin),
            "EPNSCoreV1::verifyChannel: Channel already verified"
        );

        // Verify channel
        channels[_channel].verifiedBy = msg.sender;

        // Emit event
        emit ChannelVerified(_channel, msg.sender);
    }

    /**
     * @notice    Function is designed to unverify a channel
     * @dev       Channel who verified this channel or Push Channel Admin can only revoke
     * @param    _channel Address of the channel to be unverified
     **/
    function unverifyChannel(address _channel) public {
        require(
            channels[_channel].verifiedBy == msg.sender ||
                msg.sender == pushChannelAdmin,
            "EPNSCoreV1::unverifyChannel: Only channel who verified this or Push Channel Admin can revoke"
        );

        // Unverify channel
        channels[_channel].verifiedBy = address(0x0);

        // Emit Event
        emit ChannelVerificationRevoked(_channel, msg.sender);
    }

    /* **************

    => DEPOSIT & WITHDRAWAL of FUNDS<=

    *************** */
    /**
     * @notice  Function is used for Handling the entire procedure of Depositing the DAI to Lending POOl
     *
     * @dev     Updates the Relevant state variable during Deposit of DAI
     *          Lends the DAI to AAVE protocol.
     * @param   amount - Amount that is to be deposited
     **/
    function _depositFundsToPool(uint256 amount) private {
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.add(amount);

        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
            lendingPoolProviderAddress
        );
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        IERC20(daiAddress).approve(provider.getLendingPoolCore(), amount);
        // Deposit to AAVE
        lendingPool.deposit(daiAddress, amount, uint16(REFERRAL_CODE)); // set to 0 in constructor presently
    }

    /**
     * @notice Swaps aDai to PUSH Tokens and Transfers to the USER Address
     *
     * @param _user address of the user that will recieve the PUSH Tokens
     * @param _userAmount the amount of aDai to be swapped and transferred
     **/
    function swapAndTransferPUSH(
        address _user,
        uint256 _userAmount,
        uint256 _amountsOutValue
    ) internal returns (bool) {
        swapADaiForDai(_userAmount);
        IERC20(daiAddress).approve(UNISWAP_V2_ROUTER, _userAmount);

        address[] memory path = new address[](3);
        path[0] = daiAddress;
        path[1] = WETH_ADDRESS;
        path[2] = PUSH_TOKEN_ADDRESS;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _userAmount,
            _amountsOutValue,
            path,
            _user,
            block.timestamp
        );
        return true;
    }

    function swapADaiForDai(uint256 _amount) private {
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(
            lendingPoolProviderAddress
        );
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        IADai(aDaiAddress).redeem(_amount);
    }

    /* **************

    => FAIR SHARE RATIO CALCULATIONS <=

    *************** */
    /**
     * @notice  Helps keeping trakc of the FAIR Share Details whenever a specific Channel Action occur
     * @dev     Updates some of the imperative Fair Share Data based whenever a paricular channel action is performed.
     *          Takes into consideration 3 major Channel Actions, i.e., Channel Creation, Channel Removal or Channel Deactivation/Reactivation.
     *
     * @param _action                 The type of Channel action for which the Fair Share is being adjusted
     * @param _channelWeight          Weight of the channel on which the Action is being performed.
     * @param _oldChannelWeight       Old Weight of the channel on which the Action is being performed.
     * @param _groupFairShareCount    Fair share count
     * @param _groupNormalizedWeight  Normalized weight value
     * @param _groupHistoricalZ       The Historical Constant - Z
     * @param _groupLastUpdate        Holds the block number of the last update.
     **/
    function _readjustFairShareOfChannels(
        ChannelAction _action,
        uint256 _channelWeight,
        uint256 _oldChannelWeight,
        uint256 _groupFairShareCount,
        uint256 _groupNormalizedWeight,
        uint256 _groupHistoricalZ,
        uint256 _groupLastUpdate
    )
        private
        view
        returns (
            uint256 groupNewCount,
            uint256 groupNewNormalizedWeight,
            uint256 groupNewHistoricalZ,
            uint256 groupNewLastUpdate
        )
    {
        // readjusts the group count and do deconstruction of weight
        uint256 groupModCount = _groupFairShareCount;
        // NormalizedWeight of all Channels at this point
        uint256 adjustedNormalizedWeight = _groupNormalizedWeight;
        // totalWeight of all Channels at this point
        uint256 totalWeight = adjustedNormalizedWeight.mul(groupModCount);

        if (_action == ChannelAction.ChannelAdded) {
            groupModCount = groupModCount.add(1);
            totalWeight = totalWeight.add(_channelWeight);
        } else if (_action == ChannelAction.ChannelRemoved) {
            groupModCount = groupModCount.sub(1);
            totalWeight = totalWeight.add(_channelWeight).sub(
                _oldChannelWeight
            );
        } else if (_action == ChannelAction.ChannelUpdated) {
            totalWeight = totalWeight.add(_channelWeight).sub(
                _oldChannelWeight
            );
        } else {
            revert(
                "EPNSCoreV1::_readjustFairShareOfChannels: Invalid Channel Action"
            );
        }
        // now calculate the historical constant
        // z = z + nxw
        // z is the historical constant
        // n is the previous count of group fair share
        // x is the differential between the latest block and the last update block of the group
        // w is the normalized average of the group (ie, groupA weight is 1 and groupB is 2 then w is (1+2)/2 = 1.5)
        uint256 n = groupModCount;
        uint256 x = block.number.sub(_groupLastUpdate);
        uint256 w = totalWeight.div(groupModCount);
        uint256 z = _groupHistoricalZ;

        uint256 nx = n.mul(x);
        uint256 nxw = nx.mul(w);

        // Save Historical Constant and Update Last Change Block
        z = z.add(nxw);

        if (n == 1) {
            // z should start from here as this is first channel
            z = 0;
        }

        // Update return variables
        groupNewCount = groupModCount;
        groupNewNormalizedWeight = w;
        groupNewHistoricalZ = z;
        groupNewLastUpdate = block.number;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}