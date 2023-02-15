// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafeL2.sol";
import "./GnosisSafeProxy.sol";
import "./Create2.sol";

abstract contract GnosisSafeOwner is Initializable {
    event ContractSignatureUpdated(
        bytes indexed oldContractSignature,
        bytes indexed newContractSignature
    );
    event SetupUpdated(bytes indexed oldSetup, bytes indexed newSetup);
    event SingletonUpdated(
        address indexed oldSingleton,
        address indexed newSingleton
    );

    bytes internal _contractSignature;
    bytes internal _setup;
    address internal _singleton;

    /**
     * @dev Initializes the contract
     */
    function __GnosisSafeOwner_init(address singleton_)
        internal
        onlyInitializing
    {
        __GnosisSafeOwner_init_unchained(singleton_);
    }

    function __GnosisSafeOwner_init_unchained(address singleton_)
        internal
        onlyInitializing
    {
        _singleton = singleton_;
        _computeSignature();
        _computeSetup();
    }

    function _computeSignature() private {
        bytes memory s = new bytes(65);
        bytes memory contractAddress = abi.encodePacked(address(this));
        uint8 i = 0;
        uint8 j = 0;
        while (i < 44) {
            if (i != 12) s[i + j] = 0x00;
            else
                while (j < 20) {
                    s[i + j] = contractAddress[j];
                    unchecked {
                        ++j;
                    }
                }
            unchecked {
                ++i;
            }
        }
        s[i + j] = 0x01;
        _contractSignature = s;
    }

    function _computeSetup() private {
        address[] memory _owners = new address[](1);
        _owners[0] = address(this);
        _setup = abi.encodeWithSelector(
            GnosisSafe.setup.selector,
            _owners,
            uint256(1),
            address(0),
            new bytes(0),
            address(0),
            address(0),
            uint256(0),
            address(0)
        );
    }

    function computeAddress(uint256 saltNonce) internal view returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(_setup), saltNonce)
        );
        bytes32 deploymentData = keccak256(
            abi.encodePacked(
                type(GnosisSafeProxy).creationCode,
                uint256(uint160(_singleton))
            )
        );
        return Create2.computeAddress(salt, deploymentData, address(this));
    }

    function execTransactionWrapper(
        GnosisSafeL2 safe,
        address toContract,
        bytes memory data
    ) internal {
        _execTransaction(
            safe,
            toContract,
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            _contractSignature
        );
    }

    function _execTransaction(
        GnosisSafeL2 target,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) private {
        require(
            target.execTransaction(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                signatures
            ),
            "CMD: execTransaction failed"
        );
    }

    /// @param contractSignature_ new address of contractSignature
    function setContractSignature(bytes memory contractSignature_) external {
        _checkAdminRole();
        emit ContractSignatureUpdated(_contractSignature, contractSignature_);
        _contractSignature = contractSignature_;
    }

    /// @param setup_ new address of setup
    function setSetup(bytes memory setup_) external {
        _checkAdminRole();
        emit SetupUpdated(_setup, setup_);
        _setup = setup_;
    }

    /// @param singleton_ new address of singleton
    function setSingleton(address singleton_) external {
        _checkAdminRole();
        emit SingletonUpdated(_singleton, singleton_);
        _singleton = singleton_;
    }

    /// @return contractSignature which is the signature of the contract to sign execTransaction
    function contractSignature() external view returns (bytes memory) {
        return _contractSignature;
    }

    /// @return setup Payload for message call sent to new proxy contract.
    function setup() external view returns (bytes memory) {
        return _setup;
    }

    /// @return singleton Address of singleton contract.
    function singleton() external view returns (address) {
        return _singleton;
    }

    // Implement this for auth function
    function _checkAdminRole() internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}