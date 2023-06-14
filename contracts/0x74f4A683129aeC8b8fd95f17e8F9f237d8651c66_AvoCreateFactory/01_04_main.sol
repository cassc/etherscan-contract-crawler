// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { CREATE3 } from "solmate/src/utils/CREATE3.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/// @title  AvoCreateFactory
/// @notice Factory for deploying contracts via CREATE, CREATE2 and CREATE3.
contract AvoCreateFactory {
    /// @notice Deploys a contract using CREATE3. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE3}.
    /// Resulting deterministic address is independent of constructor args.
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @param bytecode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deployCREATE3(bytes32 salt, bytes memory bytecode) external payable returns (address deployed) {
        return CREATE3.deploy(salt, bytecode, msg.value);
    }

    /// @notice Predicts the address of a deployed contract via {deployCREATE3}
    /// @param salt The deployer-specific salt for determining the deployed contract's address
    /// @return deployed The address of the contract that will be deployed
    function computeAddressCREATE3(bytes32 salt) external view returns (address deployed) {
        return CREATE3.getDeployed(salt);
    }

    /// @notice Deploys a contract using `CREATE2`. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE2}.
    /// The bytecode for a contract can be obtained from Solidity with
    /// `type(contractName).creationCode`.
    /// Requirements:
    /// - `bytecode` must not be empty.
    /// - `salt` must have not been used for `bytecode` already.
    /// - if `msg.value` is non-zero, `bytecode` must have a `payable` constructor.
    function deployCREATE2(bytes32 salt, bytes memory bytecode) external payable returns (address deployed) {
        return Create2.deploy(msg.value, salt, bytecode);
    }

    /// @notice Returns the address where a contract will be stored if deployed via {deployCREATE2}. Any change in the
    /// `bytecode` or `salt` will result in a new destination address.
    function computeAddressCREATE2(bytes32 salt, bytes memory bytecode) external view returns (address deployed) {
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(bytecode)));
    }

    /// @notice Deploys a contract using `CREATE`. The address where the contract
    /// will be deployed can be known in advance via {computeAddressCREATE}.
    function deployCREATE(bytes memory bytecode) external payable returns (address deployed) {
        uint256 amount_ = msg.value;
        assembly {
            deployed := create(amount_, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployed != address(0), "Create: Failed on deploy");
    }

    /// @notice Returns the address where a contract will be stored if deployed via {deployCREATE}
    function computeAddressCREATE(uint256 nonce_) external view returns (address deployed) {
        // @dev based on https://ethereum.stackexchange.com/a/61413
        bytes memory data;
        if (nonce_ == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), bytes1(0x80));
        } else if (nonce_ <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), uint8(nonce_));
        } else if (nonce_ <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), address(this), bytes1(0x81), uint8(nonce_));
        } else if (nonce_ <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), address(this), bytes1(0x82), uint16(nonce_));
        } else if (nonce_ <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), address(this), bytes1(0x83), uint24(nonce_));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), address(this), bytes1(0x84), uint32(nonce_));
        }

        return address(uint160(uint256(keccak256(data))));
    }
}