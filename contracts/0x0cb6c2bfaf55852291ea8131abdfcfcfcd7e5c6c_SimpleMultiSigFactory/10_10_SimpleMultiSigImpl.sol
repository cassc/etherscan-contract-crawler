pragma solidity 0.8.18;

import "./BaseSms.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Initializable errors
error IsNotInitialized(); // ---------| 0xc2e93857
error IsDisabled(); // ---------------| 0x09131007

contract SimpleMultiSigImpl is BaseSms, Initializable {
    modifier isInitialized() {
        if (_getInitializedVersion() == 0) {
            revert IsNotInitialized();
        }
        if (_getInitializedVersion() == type(uint8).max) {
            revert IsDisabled();
        }
        _;
    }

    /**
        * To prevent the implementation contract from being used, you should invoke the {_disableInitializers}
        * function in the constructor to automatically lock it when it is deployed:
    */
    constructor() {
        _disableInitializers();
    }

    /**
        * Initialize the contract, and sets the initial params required for the SMS Contract
        * Clones the methods from the parentAddress
    */
    function init(uint threshold_, address[] memory owners_, uint chainId) external initializer {
        super.contractInit(threshold_, owners_, chainId);
    }

    function setOwners(uint threshold_, address[] memory owners_) isInitialized public override {
        super.setOwners(threshold_, owners_);
    }

    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) isInitialized public override {
        super.execute(sigV, sigR, sigS, destination, value, data, executor, gasLimit);
    }

    function executeWithSignatures(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor, uint gasLimit
    ) isInitialized public override {
        super.executeWithSignatures(signatures, destination, value, data, executor, gasLimit);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) isInitialized public view override returns (bytes4) {
        return super.isValidSignature(hash, signature);
    }
}