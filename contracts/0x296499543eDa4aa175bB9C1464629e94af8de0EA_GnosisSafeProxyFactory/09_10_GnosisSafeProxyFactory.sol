// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./IProxyCreationCallback.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
/// @author adapted by Bastien Silhol for Realt.co - <[email protected]>
contract GnosisSafeProxyFactory is AccessControl {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);
    bytes32 public constant DEPLOYER_ROLE = keccak256("SAFE.DEPLOYER.ROLE");

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(DEPLOYER_ROLE, owner);
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data)
        external
        onlyRole(DEPLOYER_ROLE)
        returns (GnosisSafeProxy proxy)
    {
        proxy = new GnosisSafeProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() external pure returns (bytes memory) {
        return type(GnosisSafeProxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() external pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _singleton Address of singleton contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(address _singleton, uint256 saltNonce)
        private
        returns (GnosisSafeProxy proxy)
    {
        // If the initializer changes the proxy address should not change :)
        bytes32 salt = keccak256(abi.encode(saltNonce));
        bytes memory deploymentData = abi.encodePacked(
            type(GnosisSafeProxy).creationCode,
            uint256(uint160(_singleton))
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(
                0x0,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external onlyRole(DEPLOYER_ROLE) returns (GnosisSafeProxy proxy) {
        return _createProxyWithNonce(_singleton, initializer, saltNonce);
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function _createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) private returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, saltNonce);
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(
                        gas(),
                        proxy,
                        0,
                        add(initializer, 0x20),
                        mload(initializer),
                        0,
                        0
                    ),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create new proxy contact, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoced after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external onlyRole(DEPLOYER_ROLE) returns (GnosisSafeProxy proxy) {
        proxy = _createProxyWithNonce(_singleton, initializer, saltNonce);
        if (address(callback) != address(0))
            callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev Allows to get the address for a new proxy contact created via `createProxyWithNonce`
    ///      This method is only meant for address calculation purpose when you use an initializer that would revert,
    ///      therefore the response is returned with a revert. When calling this method set `from` to the address of the proxy factory.
    /// @param _singleton Address of singleton contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function calculateCreateProxyWithNonceAddress(
        address _singleton,
        bytes calldata, /* initializer */
        uint256 saltNonce
    ) external view returns (address addr) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(GnosisSafeProxy).creationCode,
                uint256(uint160(_singleton))
            )
        );
        bytes32 hashNonce = keccak256(abi.encode(saltNonce));
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | hashNonce              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), hashNonce)
            mstore(ptr, address()) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}