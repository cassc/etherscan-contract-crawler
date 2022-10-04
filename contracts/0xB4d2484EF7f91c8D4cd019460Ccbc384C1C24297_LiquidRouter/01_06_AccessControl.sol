// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract AccessControl {

    // Managed by WISE
    address public multisig;

    // Mapping to store authorised workers
    mapping(address => mapping(address => bool)) public workers;

    event MultisigUpdated(
        address newMultisig
    );

    event WorkerAdded(
        address wiseGroup,
        address newWorker
    );

    event WorkerRemoved(
        address wiseGroup,
        address existingWorker
    );

    /**
     * @dev Set to address that deploys Factory
     */
    constructor() {
        multisig = tx.origin;
    }

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisig,
            "AccessControl: NOT_MULTISIG"
        );
        _;
    }

    /**
     * @dev requires that sender is authorised
     */
    modifier onlyWiseWorker(
        address _group
    ) {
        require(
            workers[_group][msg.sender] == true,
            "AccessControl: NOT_WORKER"
        );
        _;
    }

    /**
     * @dev Transfer Multisig permission
     * Call internal function that does the work
     */
    function updateMultisig(
        address _newMultisig
    )
        external
        onlyMultisig
    {
        require(
            _newMultisig > address(0),
            "AccessControl: EMPTY_ADDRESS"
        );

        multisig = _newMultisig;

        emit MultisigUpdated(
            _newMultisig
        );
    }

    /**
     * @dev Add a worker address to the system.
     * Set the bool for the worker to true.
     */
    function addWorker(
        address _group,
        address _worker
    )
        external
        onlyMultisig
    {
        _addWorker(
            _group,
            _worker
        );
    }

    function _addWorker(
        address _group,
        address _worker
    )
        internal
    {
        workers[_group][_worker] = true;

        emit WorkerAdded(
            _group,
            _worker
        );
    }

    /**
     * @dev Remove a worker address from the system.
     * Set the bool for the worker to false.
     */
    function removeWorker(
        address _group,
        address _worker
    )
        external
        onlyMultisig
    {
        workers[_group][_worker] = false;

        emit WorkerRemoved(
            _group,
            _worker
        );
    }
}
