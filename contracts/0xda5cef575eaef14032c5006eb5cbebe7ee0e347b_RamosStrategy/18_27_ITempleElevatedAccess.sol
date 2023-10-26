pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/access/ITempleElevatedAccess.sol)

/**
 * @notice Inherit to add Executor and Rescuer roles for DAO elevated access.
 */ 
interface ITempleElevatedAccess {
    event ExplicitAccessSet(address indexed account, bytes4 indexed fnSelector, bool indexed value);
    event RescueModeSet(bool indexed value);

    event NewRescuerProposed(address indexed oldRescuer, address indexed oldProposedRescuer, address indexed newProposedRescuer);
    event NewRescuerAccepted(address indexed oldRescuer, address indexed newRescuer);

    event NewExecutorProposed(address indexed oldExecutor, address indexed oldProposedExecutor, address indexed newProposedExecutor);
    event NewExecutorAccepted(address indexed oldExecutor, address indexed newExecutor);

    struct ExplicitAccess {
        bytes4 fnSelector;
        bool allowed;
    }

    /**
     * @notice A set of addresses which are approved to execute emergency operations.
     */ 
    function rescuer() external returns (address);

    /**
     * @notice A set of addresses which are approved to execute normal operations on behalf of the DAO.
     */ 
    function executor() external returns (address);

    /**
     * @notice Explicit approval for an address to execute a function.
     * allowedCaller => function selector => true/false
     */
    function explicitFunctionAccess(address contractAddr, bytes4 functionSelector) external returns (bool);

    /**
     * @notice Under normal circumstances, rescuers don't have access to admin/operational functions.
     * However when rescue mode is enabled (by rescuers or executors), they claim the access rights.
     */
    function inRescueMode() external returns (bool);
    
    /**
     * @notice Set the contract into or out of rescue mode.
     * Only the rescuers or executors are allowed to set.
     */
    function setRescueMode(bool value) external;

    /**
     * @notice Proposes a new Rescuer.
     * Can only be called by the current rescuer.
     */
    function proposeNewRescuer(address account) external;

    /**
     * @notice Caller accepts the role as new Rescuer.
     * Can only be called by the proposed rescuer
     */
    function acceptRescuer() external;

    /**
     * @notice Proposes a new Executor.
     * Can only be called by the current executor or resucer (if in resuce mode)
     */
    function proposeNewExecutor(address account) external;

    /**
     * @notice Caller accepts the role as new Executor.
     * Can only be called by the proposed executor
     */
    function acceptExecutor() external;

    /**
     * @notice Grant `allowedCaller` the rights to call the function selectors in the access list.
     * @dev fnSelector == bytes4(keccak256("fn(argType1,argType2,...)"))
     */
    function setExplicitAccess(address allowedCaller, ExplicitAccess[] calldata access) external;
}