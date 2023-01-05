// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./Interfaces/ILogicContract.sol";
import "./Interfaces/IStrategyContract.sol";
import "./Interfaces/IStrategyStatistics.sol";
import "./utils/LogicUpgradeable.sol";

interface AutomationCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

contract Automation is
    LogicUpgradeable,
    PausableUpgradeable,
    AutomationCompatibleInterface
{
    address public keeper;
    address public strategyStatistics;

    bool public isEasy;

    struct KeeperVenusCalldata {
        address venusStrategy;
        uint256 venusBorrowRateMax;
        uint256 venusBorrowRateMin;
        uint256 venusLendingMin;
    }

    event SetKeeper(address keeper);
    event SetStrategyStatistics(address strategyStatistics);

    event VenusLending(address strategy);
    event VenusBuild(address strategy, uint256 amount);
    event VenusDestory(address strategy, uint256 percentage);
    event VenusClaimXVS(address strategy);
    event VenusClaimFarming(address strategy);
    event perform(uint256);

    function __Automation_init() public initializer {
        isEasy = true;
        LogicUpgradeable.initialize();
    }

    receive() external payable {}

    /*** modifiers ***/

    modifier onlyKeeper() {
        require(msg.sender == keeper, "K0");
        _;
    }

    /*** Owner function ***/

    /**
     * @notice set Keeper address
     * @param _keeper venus Strategy address
     */
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "K1");
        keeper = _keeper;

        emit SetKeeper(_keeper);
    }

    /**
     * @notice set StrategyStatistics address
     * @param _strategyStatistics StrategyStatistics address
     */
    function setStrategyStatistics(
        address _strategyStatistics
    ) external onlyOwner {
        require(_strategyStatistics != address(0), "K1");
        strategyStatistics = _strategyStatistics;

        emit SetStrategyStatistics(_strategyStatistics);
    }

    function setIsEasy(bool _isEasy) external onlyOwner {
        isEasy = _isEasy;
    }

    /**
     * @notice Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*** Keeper Perform function ***/

    /**
     * @notice Keeper call to perform claimVenusXVS
     * @param strategy address of Venus Strategy
     */
    function performVenusClaimXVS(
        address strategy
    ) external whenNotPaused onlyKeeper {
        if (!isEasy) {
            IStrategyVenus(strategy).claimRewards(0);
        }

        emit VenusClaimXVS(strategy);
    }

    /**
     * @notice Keeper call to perform claimVenusFarming
     * @param strategy address of Venus Strategy
     */
    function performVenusClaimFarming(
        address strategy
    ) external whenNotPaused onlyKeeper {
        IStrategyVenus(strategy).claimRewards(1);

        emit VenusClaimFarming(strategy);
    }

    /**
     * @notice Keeper call to perform Build/Destroy for borrowRate
     * @param strategy address of Venus Strategy
     * @param _max venusBorrowRateMax (< 10000)
     * @param _min venusBorrowRateMax (< 10000)
     */
    function performVenusBorrowRate(
        address strategy,
        uint256 _max,
        uint256 _min
    ) public whenNotPaused onlyKeeper {
        require(_max >= _min, "K2");
        require(_max <= 10000, "K3");

        (
            uint256 totalBorrowLimitUSD,
            ,
            ,
            uint256 borrowRate,

        ) = IStrategyStatistics(strategyStatistics).getStrategyBalance(
                IStrategyContract(strategy).logic(),
                0
            );

        borrowRate = borrowRate / 1e14;

        // If borrowRate > max, destory (rate - max) / rate + 1%
        if (borrowRate > _max) {
            uint256 destroyPercentage = ((borrowRate - _max) * 10000) /
                borrowRate +
                100;
            IStrategyVenus(strategy).destroy(destroyPercentage);

            emit VenusDestory(strategy, destroyPercentage);
            return;
        }

        // If borrowRate < min, build (min - rate + 1%) * borrowLimit
        if (borrowRate < _min) {
            uint256 buildAmountUSD = (totalBorrowLimitUSD *
                (_min - borrowRate + 100)) / 10000;
            IStrategyVenus(strategy).build(buildAmountUSD);

            emit VenusBuild(strategy, buildAmountUSD);
            return;
        }
    }

    /**
     * @notice Keeper call to perform VenusLending
     * @param strategy address of Venus Strategy
     * @param venusLendingMin min value for venus lending in USD (decimal : 18)
     * @return : true - lending is done, false - available amount is not enough
     */
    function performVenusLending(
        address strategy,
        uint256 venusLendingMin
    ) public whenNotPaused onlyKeeper returns (bool) {
        if (_checkVenusLending(strategy, venusLendingMin)) {
            IStrategyVenus(strategy).lendToken();
            IStrategyVenus(strategy).build(venusLendingMin);

            emit VenusLending(strategy);
            emit VenusBuild(strategy, venusLendingMin);
            return true;
        }

        return false;
    }

    /*** Chainlink function ***/

    /**
     * @notice Chainlink call to perform check
     * @param checkData calldata from Chainlink
     * @return upkeepNeeded if true performUpkeep() is run
     * @return performData data passed to performUpkeep()
     */
    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Decode calldata
        KeeperVenusCalldata memory venusCalldata = abi.decode(
            checkData,
            (KeeperVenusCalldata)
        );
        require(
            venusCalldata.venusBorrowRateMax >=
                venusCalldata.venusBorrowRateMin,
            "K2"
        );

        upkeepNeeded = false;
        uint8 checkResult = 0;

        // Check VenusLending
        if (
            !upkeepNeeded &&
            _checkVenusLending(
                venusCalldata.venusStrategy,
                venusCalldata.venusLendingMin
            )
        ) {
            upkeepNeeded = true;
            checkResult = 1;
        }

        // Check Venus BorrowRate
        if (
            !upkeepNeeded &&
            _checkVenusBorrowRate(
                venusCalldata.venusStrategy,
                venusCalldata.venusBorrowRateMax,
                venusCalldata.venusBorrowRateMin
            )
        ) {
            upkeepNeeded = true;
            checkResult = 2;
        }

        performData = abi.encode(checkResult, venusCalldata);
    }

    /**
     * @notice Chainlink call to perform keep
     * @param performData calldata from Chainlink, generated from checkUpkeep()
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotPaused {
        // Decode data
        (uint256 checkResult, KeeperVenusCalldata memory venusCalldata) = abi
            .decode(performData, (uint256, KeeperVenusCalldata));

        if (isEasy) {
            emit perform(checkResult);
        } else {
            // Venus Lending
            if (
                checkResult == 1 &&
                performVenusLending(
                    venusCalldata.venusStrategy,
                    venusCalldata.venusLendingMin
                )
            ) {
                return;
            }

            // Venus BorrowRate
            if (checkResult == 2) {
                performVenusBorrowRate(
                    venusCalldata.venusStrategy,
                    venusCalldata.venusBorrowRateMax,
                    venusCalldata.venusBorrowRateMin
                );
            }
        }
    }

    /*** Private function ***/

    /**
     * @notice Check venus Lending available
     * @param strategy address of Venus Strategy
     * @param venusLendingMin min value for venus lending in USD (decimal : 18)
     * @return : true - available about is enough - available amount is not enough
     */
    function _checkVenusLending(
        address strategy,
        uint256 venusLendingMin
    ) private view returns (bool) {
        return
            IStrategyStatistics(strategyStatistics).getStrategyAvailable(
                IStrategyContract(strategy).logic(),
                0
            ) > venusLendingMin
                ? true
                : false;
    }

    /**
     * @notice Check venus Borrow Rate available
     * @param strategy address of Venus Strategy
     * @param _max venusBorrowRateMax (< 10000)
     * @param _min venusBorrowRateMax (< 10000)
     * @return : true - build/destory is required, false - no need to perform
     */
    function _checkVenusBorrowRate(
        address strategy,
        uint256 _max,
        uint256 _min
    ) private view returns (bool) {
        // Get Strategy Borrow rate
        (, , , uint256 borrowRate, ) = IStrategyStatistics(strategyStatistics)
            .getStrategyBalance(IStrategyContract(strategy).logic(), 0);

        borrowRate = borrowRate / 1e14;

        // If borrowRate > max, destory ( rate - min)
        if (borrowRate > _max) {
            return true;
        }

        // If borrowRate < min, build (min - rate) * borrowLimit
        if (borrowRate < _min) {
            return true;
        }
        return false;
    }
}