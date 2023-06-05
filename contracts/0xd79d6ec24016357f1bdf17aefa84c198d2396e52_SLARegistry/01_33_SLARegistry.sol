// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './SLA.sol';
import './SLORegistry.sol';
import './interfaces/IPeriodRegistry.sol';
import './interfaces/IMessengerRegistry.sol';
import './interfaces/IStakeRegistry.sol';
import './interfaces/IMessenger.sol';
import './interfaces/ISLARegistry.sol';

/**
 * @title SLARegistry
 * @notice This is a registry contract that deploy SLAs and manage them
 */
contract SLARegistry is ISLARegistry, ReentrancyGuard {
    /// @notice SLO registry
    address private _sloRegistry;
    /// @notice Periods registry
    address private _periodRegistry;
    /// @notice Messengers registry
    address private _messengerRegistry;
    /// @notice Stake registry
    address private _stakeRegistry;
    /// @notice stores the addresses of created SLAs
    SLA[] public SLAs;
    /// @notice stores the indexes of service level agreements owned by an user
    mapping(address => uint256[]) private _userToSLAIndexes;
    /// @notice to check if registered SLA
    mapping(address => bool) private _registeredSLAs;
    /// @notice value to lock past periods on SLA deployment
    bool private immutable _checkPastPeriod;

    /// @notice An event that emitted when creating a new SLA
    event SLACreated(SLA indexed sla, address indexed owner);

    /// @notice An event that is emitted when requesting SLI
    event SLIRequested(
        uint256 periodId,
        address indexed sla,
        address indexed caller
    );

    /// @notice An event that is emitted when returning locked tokens back to sla owner
    event ReturnLockedValue(address indexed sla, address indexed caller);

    /**
     * @notice Constructor
     * @param sloRegistry_ address of SLORegistry
     * @param periodRegistry_ address of PeriodRegistry
     * @param messengerRegistry_ address of MessengerRegistry
     * @param stakeRegistry_ address of StakeRegistry
     * @param checkPastPeriod_ value to lock past periods on SLA deployment
     */
    constructor(
        address sloRegistry_,
        address periodRegistry_,
        address messengerRegistry_,
        address stakeRegistry_,
        bool checkPastPeriod_
    ) {
        require(sloRegistry_ != address(0x0), 'invalid sloRegistry address');
        require(
            periodRegistry_ != address(0x0),
            'invalid periodRegistry address'
        );
        require(
            messengerRegistry_ != address(0x0),
            'invalid messengerRegistry address'
        );
        require(
            stakeRegistry_ != address(0x0),
            'invalid stakeRegistry address'
        );
        _sloRegistry = sloRegistry_;
        SLORegistry(_sloRegistry).setSLARegistry();
        _periodRegistry = periodRegistry_;
        _stakeRegistry = stakeRegistry_;
        IStakeRegistry(_stakeRegistry).setSLARegistry();
        _messengerRegistry = messengerRegistry_;
        IMessengerRegistry(_messengerRegistry).setSLARegistry();
        _checkPastPeriod = checkPastPeriod_;
    }

    /**
     * @notice function to create a new SLA
     * @param sloValue_ slo value
     * @param sloType_ slo type
     * @param whitelisted_ whitelist
     * @param messengerAddress_ address of messenger
     * @param periodType_ period type
     * @param initialPeriodId_ starting period id
     * @param finalPeriodId_ ending period id
     * @param ipfsHash_ ipfshash
     * @param severity_ severity
     * @param penalty_ penalty per severity level
     * @param leverage_ leverage
     */
    function createSLA(
        uint120 sloValue_,
        SLORegistry.SLOType sloType_,
        bool whitelisted_,
        address messengerAddress_,
        IPeriodRegistry.PeriodType periodType_,
        uint128 initialPeriodId_,
        uint128 finalPeriodId_,
        string memory ipfsHash_,
        uint256[] memory severity_,
        uint256[] memory penalty_,
        uint64 leverage_
    ) public nonReentrant {
        require(
            IPeriodRegistry(_periodRegistry).isValidPeriod(
                periodType_,
                initialPeriodId_
            ),
            'first id invalid'
        );
        require(
            IPeriodRegistry(_periodRegistry).isValidPeriod(
                periodType_,
                finalPeriodId_
            ),
            'final id invalid'
        );
        require(
            IPeriodRegistry(_periodRegistry).isInitializedPeriod(periodType_),
            'period not initialized'
        );
        require(finalPeriodId_ >= initialPeriodId_, 'invalid final/initial');

        if (_checkPastPeriod) {
            require(
                !IPeriodRegistry(_periodRegistry).periodHasStarted(
                    periodType_,
                    initialPeriodId_
                ),
                'past period'
            );
        }
        require(
            IMessengerRegistry(_messengerRegistry).registeredMessengers(
                messengerAddress_
            ),
            'invalid messenger'
        );
        require(
            severity_.length == penalty_.length,
            'severity and penalty length should match'
        );

        SLA sla = new SLA(
            msg.sender,
            whitelisted_,
            periodType_,
            messengerAddress_,
            initialPeriodId_,
            finalPeriodId_,
            uint128(SLAs.length),
            ipfsHash_,
            severity_,
            penalty_,
            leverage_
        );

        SLORegistry(_sloRegistry).registerSLO(
            sloValue_,
            sloType_,
            address(sla)
        );
        IStakeRegistry(_stakeRegistry).lockDSLAValue(
            msg.sender,
            address(sla),
            finalPeriodId_ - initialPeriodId_ + 1
        );
        _userToSLAIndexes[msg.sender].push(SLAs.length);
        SLAs.push(sla);
        _registeredSLAs[address(sla)] = true;
        emit SLACreated(sla, msg.sender);
    }

    /**
     * @notice function to request sli for specific period id
     * @dev requested period should be finished && sla shouldn't be verified, and
     * it distributes verification rewards to the caller
     * @param _periodId period id to request
     * @param _sla address of SLA
     * @param _ownerApproval owner approval
     */
    function requestSLI(
        uint256 _periodId,
        SLA _sla,
        bool _ownerApproval
    ) public nonReentrant {
        require(isRegisteredSLA(address(_sla)), 'This SLA is not valid.');
        require(
            _periodId == _sla.nextVerifiablePeriod(),
            'not nextVerifiablePeriod'
        );
        (, , SLA.Status status) = _sla.periodSLIs(_periodId);
        require(
            status == SLA.Status.NotVerified,
            'This SLA has already been verified.'
        );
        require(_sla.isAllowedPeriod(_periodId), 'invalid period');
        require(
            IPeriodRegistry(_periodRegistry).periodIsFinished(
                _sla.periodType(),
                _periodId
            ),
            'period unfinished'
        );
        emit SLIRequested(_periodId, address(_sla), msg.sender);
        IMessenger(_sla.messengerAddress()).requestSLI(
            _periodId,
            address(_sla),
            _ownerApproval,
            msg.sender
        );
        IStakeRegistry(_stakeRegistry).distributeVerificationRewards(
            address(_sla),
            msg.sender,
            _periodId
        );
    }

    /**
     * @notice function to return locked tokens back to sla owner
     * @dev only SLA owner can call this function for only registered SLAs
     * @param _sla address of SLA
     */
    function returnLockedValue(SLA _sla) external {
        require(isRegisteredSLA(address(_sla)), 'This SLA is not valid.');
        require(msg.sender == _sla.owner(), 'Only the SLA owner can do this.');
        require(_sla.contractFinished(), 'This SLA has not finished.');
        emit ReturnLockedValue(address(_sla), msg.sender);
        IStakeRegistry(_stakeRegistry).returnLockedValue(address(_sla));
    }

    /**
     * @notice function to register a new messenger
     * @param _messengerAddress address of messenger to register
     * @param _specificationUrl specification url of messenger
     */
    function registerMessenger(
        address _messengerAddress,
        string memory _specificationUrl
    ) public nonReentrant {
        IMessengerRegistry(_messengerRegistry).registerMessenger(
            msg.sender,
            _messengerAddress,
            _specificationUrl
        );
        IMessenger(_messengerAddress).setSLARegistry();
    }

    /**
     * @notice external view function that returns SLAs created by user
     * @param _user user address
     * @return SLAList an array of SLAs created by _user
     */
    function userSLAs(address _user)
        external
        view
        returns (SLA[] memory SLAList)
    {
        uint256 count = _userToSLAIndexes[_user].length;
        SLAList = new SLA[](count);

        for (uint256 i = 0; i < count; i++) {
            SLAList[i] = (SLAs[_userToSLAIndexes[_user][i]]);
        }
    }

    /**
     * @notice external view function that returns an array of all SLAs
     * @return array of SLAs
     */
    function allSLAs() external view returns (SLA[] memory) {
        return (SLAs);
    }

    /**
     * @notice public view function that returns if the sla is registered
     * @param _slaAddress address of SLA to check registration
     * @return boolean of registration
     */
    function isRegisteredSLA(address _slaAddress)
        public
        view
        override
        returns (bool)
    {
        return _registeredSLAs[_slaAddress];
    }

    /**
     * @notice external view function that returns the address of SLORegistry
     * @return address of SLORegistry
     */
    function sloRegistry() external view override returns (address) {
        return _sloRegistry;
    }

    /**
     * @notice external view function that returns the address of PeriodRegistry
     * @return address of PeriodRegistry
     */
    function periodRegistry() external view override returns (address) {
        return _periodRegistry;
    }

    /**
     * @notice external view function that returns the address of MessengerRegistry
     * @return address of MessengerRegistry
     */
    function messengerRegistry() external view override returns (address) {
        return _messengerRegistry;
    }

    /**
     * @notice external view function that returns the address of StakeRegistry
     * @return address of StakeRegistry
     */
    function stakeRegistry() external view override returns (address) {
        return _stakeRegistry;
    }

    /**
     * @notice external view function that returns the value to lock past periods on SLA deployment
     * @return boolean that represent if it check the past periods or not
     */
    function checkPastPeriod() external view returns (bool) {
        return _checkPastPeriod;
    }
}