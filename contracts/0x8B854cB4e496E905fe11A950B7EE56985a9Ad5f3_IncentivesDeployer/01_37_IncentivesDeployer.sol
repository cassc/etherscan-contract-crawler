//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../incentives/ExternalBalanceIncentives.sol";
import "../incentives/TokenLocker.sol";
import "../incentives/TradingFeeIncentives.sol";
import "../upgrade/FsBase.sol";
import "../upgrade/FsProxy.sol";
import "../exchange41/IncentivesHook.sol";

/// @title IncentivesDeployer deploys incentives contracts.
contract IncentivesDeployer is FsBase {
    /// @notice address of the proxy admin that will be authorized to upgrade the contracts this deployer creates.
    /// Proxy admin should be owned by the voting executor so only governance ultimately has the ability to upgrade
    /// contracts.
    address public immutable proxyAdmin;
    address public immutable treasury;
    address public openInterestIncentivesLogic;
    address public tradingFeeIncentivesLogic;
    address public tokenLockerLogic;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[997] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    /// @notice Emitted when an incentives hook contract is deployed.
    event IncentivesHookAdded(address indexed incentivesHook, address creator);

    /// @notice Emitted when a trading fee incentives contract is deployed.
    event TradingFeeIncentivesAdded(address indexed tradingFeeIncentives, address creator);

    /// @notice Emitted when a trading incentives contract is deployed.
    event OpenInterestIncentivesAdded(address indexed openInterestIncentives, address creator);

    /// @notice Emitted when the logic contracts are updated
    /// @param openInterestIncentivesLogic address of the new balanceIncentives logic contract
    /// @param tradingFeeIncentivesLogic address of the new tradingFeeIncentives logic contract
    /// @param tokenLockerLogic address of the new tokenlocker logic contract
    event LogicContractsUpdated(
        address openInterestIncentivesLogic,
        address tradingFeeIncentivesLogic,
        address tokenLockerLogic
    );

    /// @dev We use immutables as these parameters will not change. Immutables are not stored in storage, but directly
    /// embedded in the deployed code and thus save storage reads. If, somehow, these need to be updated this can still
    /// be done through a implementation update of the IncentivesDeployer proxy.
    constructor(address _proxyAdmin, address _treasury) {
        //slither-disable-next-line missing-zero-check
        proxyAdmin = nonNull(_proxyAdmin);
        //slither-disable-next-line missing-zero-check
        treasury = nonNull(_treasury);
    }

    /// @dev initialize the owner and the logic contracts
    /// @param _openInterestIncentivesLogic The address of the new balance incentive contract.
    /// @param _tradingFeeIncentivesLogic The address of the new trading fee incentives contract.
    /// @param _tokenLockerLogic The address of the new token locker contract.
    function initialize(
        address _openInterestIncentivesLogic,
        address _tradingFeeIncentivesLogic,
        address _tokenLockerLogic
    ) external initializer {
        initializeFsOwnable();
        setLogicContractsImpl(
            _openInterestIncentivesLogic,
            _tradingFeeIncentivesLogic,
            _tokenLockerLogic
        );
    }

    /// @notice Set the logic contracts to a new version so newly deployed contracts use the new logic.
    /// @param _openInterestIncentivesLogic The address of the new balance incentive contract.
    /// @param _tradingFeeIncentivesLogic The address of the new trading fee incentives contract.
    /// @param _tokenLockerLogic The address of the new token locker contract.
    function setLogicContracts(
        address _openInterestIncentivesLogic,
        address _tradingFeeIncentivesLogic,
        address _tokenLockerLogic
    ) external onlyOwner {
        setLogicContractsImpl(
            _openInterestIncentivesLogic,
            _tradingFeeIncentivesLogic,
            _tokenLockerLogic
        );
    }

    /// @notice Deploy a new trade balance incentives contract.
    /// @return The address of the newly deployed trade balance incentives.
    function deployOpenInterestIncentives(
        address incentivesHook,
        address rewardsToken,
        uint256 rewardsLockupTime
    ) public returns (address) {
        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        bytes memory callData =
            abi.encodeWithSelector(
                ExternalBalanceIncentives(openInterestIncentivesLogic).initialize.selector,
                treasury,
                rewardsToken
            );
        address openInterestIncentives =
            deployProxy(openInterestIncentivesLogic, proxyAdmin, callData);
        ExternalBalanceIncentives(openInterestIncentives).setMaxLockupTime(rewardsLockupTime);
        // Only the incentives hook has the rights to update incentives contracts.
        ExternalBalanceIncentives(openInterestIncentives).setBalanceUpdaterAddress(incentivesHook);

        // Transfer ownership to voting executor.
        ExternalBalanceIncentives(openInterestIncentives).transferOwnership(owner());

        // We rely on our contracts not to start another deployment inside of their initialization
        // functions, causing events to be emitted in an incorrect order.  This is the issue Slither
        // is flagging here.
        // slither-disable-next-line reentrancy-events
        emit OpenInterestIncentivesAdded(openInterestIncentives, msg.sender);
        return openInterestIncentives;
    }

    /// @notice Deploy a new trading fee incentives contract.
    /// @return The address of the newly deployed trading fee incentives.
    function deployTradingFeeIncentives(
        address incentivesHook,
        address rewardsToken,
        uint256 rewardsLockupTime
    ) public returns (address) {
        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        bytes memory callData =
            abi.encodeWithSelector(
                TokenLocker(tokenLockerLogic).initialize.selector,
                treasury,
                rewardsToken
            );
        address tradingFeeIncentivesTokenLocker =
            deployProxy(tokenLockerLogic, proxyAdmin, callData);
        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        callData = abi.encodeWithSelector(
            TradingFeeIncentives(tradingFeeIncentivesLogic).initialize.selector,
            tradingFeeIncentivesTokenLocker,
            rewardsToken,
            // Only the incentives hook has the rights to update incentives contracts.
            incentivesHook
        );
        TokenLocker(tradingFeeIncentivesTokenLocker).setMaxLockupTime(rewardsLockupTime);
        address tradingFeeIncentives = deployProxy(tradingFeeIncentivesLogic, proxyAdmin, callData);

        // Transfer ownership to voting executor.
        address ownerAddress = owner();
        TradingFeeIncentives(tradingFeeIncentives).transferOwnership(ownerAddress);
        TokenLocker(tradingFeeIncentivesTokenLocker).transferOwnership(ownerAddress);

        // We rely on our contracts not to start another deployment inside of their initialization
        // functions, causing events to be emitted in an incorrect order.  This is the issue Slither
        // is flagging here.
        // slither-disable-next-line reentrancy-events
        emit TradingFeeIncentivesAdded(tradingFeeIncentives, msg.sender);
        return tradingFeeIncentives;
    }

    /// @dev Deploy incentives hook with default trade and trading fee incentives contracts for given rewards token.
    /// If we want to create more incentives contracts with other tokens (e.g. AVAX), we can call the deploy them
    /// separately and then add them to the incentives hook.
    function deployIncentivesHook(
        address exchange,
        address _rewardsToken,
        uint256 rewardsLockupTime
    )
        external
        returns (
            address incentivesHook,
            address openInterestIncentives,
            address tradingFeeIncentives
        )
    {
        address rewardsToken = nonNull(_rewardsToken);

        incentivesHook = address(new IncentivesHook(exchange));
        openInterestIncentives = deployOpenInterestIncentives(
            incentivesHook,
            rewardsToken,
            rewardsLockupTime
        );
        tradingFeeIncentives = deployTradingFeeIncentives(
            incentivesHook,
            rewardsToken,
            rewardsLockupTime
        );
        IncentivesHook(incentivesHook).addOpenInterestIncentives(openInterestIncentives);
        IncentivesHook(incentivesHook).addTradingFeeIncentives(tradingFeeIncentives);
        IncentivesHook(incentivesHook).transferOwnership(owner());

        // We rely on our contracts not to start another deployment inside of their initialization
        // functions, causing events to be emitted in an incorrect order.  This is the issue Slither
        // is flagging here.
        // slither-disable-next-line reentrancy-events
        emit IncentivesHookAdded(incentivesHook, msg.sender);
    }

    function setLogicContractsImpl(
        address _openInterestIncentivesLogic,
        address _tradingFeeIncentivesLogic,
        address _tokenLockerLogic
    ) private {
        //slither-disable-next-line missing-zero-check
        openInterestIncentivesLogic = nonNull(_openInterestIncentivesLogic);
        //slither-disable-next-line missing-zero-check
        tradingFeeIncentivesLogic = nonNull(_tradingFeeIncentivesLogic);
        //slither-disable-next-line missing-zero-check
        tokenLockerLogic = nonNull(_tokenLockerLogic);

        emit LogicContractsUpdated(
            _openInterestIncentivesLogic,
            _tradingFeeIncentivesLogic,
            _tokenLockerLogic
        );
    }

    /// @notice Deploy a transparent proxy, set the logic contract, and execute a call on it (usually used to call
    /// initialize).
    function deployProxy(
        address logic,
        address admin,
        bytes memory callData
    ) private returns (address) {
        return address(new FsProxy(logic, admin, callData));
    }
}