// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IStrategyContract.sol";
import "./utils/UpgradeableBase.sol";

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
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

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
    UpgradeableBase,
    PausableUpgradeable,
    AutomationCompatibleInterface
{
    address public keeper;

    event SetKeeper(address keeper);

    function __Automation_init() public initializer {
        UpgradeableBase.initialize();
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
        keeper = _keeper;

        emit SetKeeper(_keeper);
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

    /*** Chainlink function ***/

    /**
     * @notice Chainlink call to perform check
     * @param checkData calldata from Chainlink
     * @return upkeepNeeded if true performUpkeep() is run
     * @return performData data passed to performUpkeep()
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        whenNotPaused
        onlyKeeper
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Decode calldata
        address strategy = abi.decode(checkData, (address));

        // Check perform
        bool performUseToken = false;
        bool performRebalance = false;

        if (IStrategy(strategy).checkUseToken()) {
            upkeepNeeded = true;
            performUseToken = true;
        }

        if (IStrategy(strategy).checkRebalance()) {
            upkeepNeeded = true;
            performRebalance = true;
        }

        // Encode performData
        performData = abi.encode(strategy, performUseToken, performRebalance);
    }

    /**
     * @notice Chainlink call to perform keep
     * @param performData calldata from Chainlink, generated from checkUpkeep()
     */
    function performUpkeep(bytes calldata performData)
        external
        override
        whenNotPaused
        onlyKeeper
    {
        // Decode data
        (address strategy, bool performUseToken, bool perfomRebalance) = abi
            .decode(performData, (address, bool, bool));

        // Process perform
        if (performUseToken) IStrategy(strategy).useToken();
        if (perfomRebalance) IStrategy(strategy).rebalance();
    }

    /*** Gelato function ***/
    /**
     * @notice Gelato resolver call to check "useToken()" is possible
     * @param strategy address of strategy
     */
    function gelatoCheckerUseToken(address strategy)
        external
        view
        whenNotPaused
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = IStrategy(strategy).checkUseToken();
        if (canExec) {
            execPayload = abi.encodeWithSelector(IStrategy.useToken.selector);
        }
    }

    /**
     * @notice Gelato resolver call to check "rebalance()" is possible
     * @param strategy address of strategy
     */
    function gelatoCheckerRebalance(address strategy)
        external
        view
        whenNotPaused
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = IStrategy(strategy).checkRebalance();
        if (canExec) {
            execPayload = abi.encodeWithSelector(IStrategy.rebalance.selector);
        }
    }
}