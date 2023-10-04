// SPDX-License-Identifier: ---DG----

pragma solidity =0.8.21;

contract AccessController {

    address public ceoAddress;
    mapping (address => bool) public isWorker;

    event CEOSet(
        address newCEO
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    constructor() {

        address creator = msg.sender;
        ceoAddress = creator;
        isWorker[creator] = true;

        emit CEOSet(
            creator
        );

        emit WorkerAdded(
            creator
        );
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            "AccessControl: CEO_DENIED"
        );
        _;
    }

    modifier onlyWorker() {
        require(
            isWorker[msg.sender] == true,
            "AccessControl: WORKER_DENIED"
        );
        _;
    }

    modifier nonZeroAddress(
        address checkingAddress
    ) {
        require(
            checkingAddress != address(0x0),
            "AccessControl: INVALID_ADDRESS"
        );
        _;
    }

    function setCEO(
        address _newCEO
    )
        external
        nonZeroAddress(_newCEO)
        onlyCEO
    {
        ceoAddress = _newCEO;

        emit CEOSet(
            ceoAddress
        );
    }

    function addWorker(
        address _newWorker
    )
        external
        onlyCEO
    {
        _addWorker(
            _newWorker
        );
    }

    function addWorkerBulk(
        address[] calldata _newWorkers
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _newWorkers.length; index++) {
            _addWorker(_newWorkers[index]);
        }
    }

    function _addWorker(
        address _newWorker
    )
        internal
        nonZeroAddress(_newWorker)
    {
        require(
            isWorker[_newWorker] == false,
            'AccessControl: worker already exist'
        );

        isWorker[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    function removeWorker(
        address _existingWorker
    )
        external
        onlyCEO
    {
        _removeWorker(
            _existingWorker
        );
    }

    function removeWorkerBulk(
        address[] calldata _workerArray
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _workerArray.length; index++) {
            _removeWorker(_workerArray[index]);
        }
    }

    function _removeWorker(
        address _existingWorker
    )
        internal
        nonZeroAddress(_existingWorker)
    {
        require(
            isWorker[_existingWorker] == true,
            "AccessControl: worker not detected"
        );

        isWorker[_existingWorker] = false;

        emit WorkerRemoved(
            _existingWorker
        );
    }
}