//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.6.1 <0.7.0;

// We import this library to be able to use console.log
import "hardhat/console.sol";
import "./provableAPI_0.6.sol";
import "./BullrunBabesCoordinator.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./BullrunBabesInterfaces.sol";

contract MockBullrunBabesOracle is AccessControl, BullrunBabesOracleI {
    BullrunBabesCoordinator coordinator;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public nextQueryId;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    function setCoordinator(address _coordinator) public override {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Must have OWNER_ROLE to setCoordinator"
        );
        require(_coordinator != address(0));
        coordinator = BullrunBabesCoordinator(_coordinator);
    }

    function _callback_with_random(uint256 random, bytes32 _queryId) public {
        emit RandomReceived(_queryId);
        coordinator.handleRandom{value: address(this).balance}(
            random,
            _queryId
        );
    }

    function _init_random() public payable override returns (bytes32) {
        require(msg.sender == address(coordinator), "Not coordinator");
        // generate a deterministic queryId
        bytes32 queryId =
            keccak256(abi.encodePacked(block.timestamp, block.number));
        emit RandomInitiated(queryId);
        return queryId;
    }
}

contract BullrunBabesOracle is
    usingProvable,
    AccessControl,
    BullrunBabesOracleIAdmin
{
    BullrunBabesCoordinator coordinator;

    /* Provable integration */
    uint256 constant MAX_INT_FROM_BYTE = 256;
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 32;
    uint256 private gasPrice = 200 * 10**9; // 200 gwei
    uint256 private gas = 800000; // gas required for callback

    /* End Provable integration */

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());

        provable_setProof(proofType_Ledger);
        provable_setCustomGasPrice(gasPrice);
    }

    function getGasPriceAndGas()
        public
        view
        override
        returns (uint256, uint256)
    {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Must have OWNER_ROLE to getGasPrice"
        );
        return (gasPrice, gas);
    }

    function setGasPriceAndGas(uint256 _gasPrice, uint256 _gas)
        public
        override
    {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Must have OWNER_ROLE to setGasPrice"
        );
        gasPrice = _gasPrice;
        gas = _gas;
        provable_setCustomGasPrice(gasPrice);
    }

    function setCoordinator(address _coordinator) public override {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Must have OWNER_ROLE to setCoordinator"
        );
        require(_coordinator != address(0));
        coordinator = BullrunBabesCoordinator(_coordinator);
    }

    /* Provable callback */
    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) public override {
        require(msg.sender == provable_cbAddress());
        if (
            provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        ) {
            revert("Invalid callback");
        } else {
            uint256 ceiling =
                (MAX_INT_FROM_BYTE**NUM_RANDOM_BYTES_REQUESTED) - 1;
            uint256 randomNumber =
                uint256(keccak256(abi.encodePacked(_result))) % ceiling;
            emit RandomReceived(_queryId);
            coordinator.handleRandom{value: address(this).balance}(
                randomNumber,
                _queryId
            );
        }
    }

    function _init_random() public payable override returns (bytes32) {
        require(
            msg.sender == address(coordinator) ||
                hasRole(OWNER_ROLE, _msgSender()),
            "Not coordinator"
        );
        uint256 QUERY_EXECUTION_DELAY = 0; // NOTE: The datasource currently does not support delays > 0!
        uint256 GAS_FOR_CALLBACK = gas; // amount of gas to allocate for the callback

        bytes32 queryId =
            provable_newRandomDSQuery(
                QUERY_EXECUTION_DELAY,
                NUM_RANDOM_BYTES_REQUESTED,
                GAS_FOR_CALLBACK
            );
        emit RandomInitiated(queryId);
        return queryId;
    }
}