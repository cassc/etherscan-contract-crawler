//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/TimelockController.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

/**
 * @notice Gnosis Safe Multisig wallet has the Ownership of this contract.
 *      In the future, We can transfer the ownership to a well-formed governance contract.
 *      **Ownership grpah**
 *      TimelockedGovernance -controls-> COMMIT, ContributionBoard, Market, DividendPool, and VisionEmitter
 *      VisionEmitter -controls-> VISION
 */
contract TimelockedGovernance is TimelockController, Initializable {
    mapping(bytes32 => bool) public nonCancelable;

    constructor()
        TimelockController(1 days, new address[](0), new address[](0))
    {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        uint256 delay,
        address multisig,
        address workersUnion
    ) public initializer {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));
        _setupRole(TIMELOCK_ADMIN_ROLE, workersUnion);
        _setupRole(PROPOSER_ROLE, workersUnion);
        _setupRole(PROPOSER_ROLE, multisig);
        _setupRole(EXECUTOR_ROLE, workersUnion);
        _setupRole(EXECUTOR_ROLE, multisig);
        TimelockController(this).updateDelay(delay);
    }

    function cancel(bytes32 id) public override {
        require(!nonCancelable[id], "non-cancelable");
        super.cancel(id);
    }

    function forceSchedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        nonCancelable[id] = true;
        super.schedule(target, value, data, predecessor, salt, delay);
    }

    function forceScheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public {
        bytes32 id = hashOperationBatch(target, value, data, predecessor, salt);
        nonCancelable[id] = true;
        super.scheduleBatch(target, value, data, predecessor, salt, delay);
    }

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public override {
        super.scheduleBatch(target, value, data, predecessor, salt, delay);
    }

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        super.executeBatch(target, value, data, predecessor, salt);
    }
}