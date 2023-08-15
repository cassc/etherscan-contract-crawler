// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IForwarder} from "./IForwarder.sol";
import {RuleChecker} from "./RuleChecker.sol";

/// @author pintak.eth
/// @title Abstract contract for rules, that are used to validate and modify forwarding parameters, can be implemented by protocol users
abstract contract RuleBase is RuleChecker {
    /// @dev address of Forwarder contract, which is used to create clones
    address public immutable forwarderImplementation;

    constructor(address _forwarderImplementation) {
        forwarderImplementation = _forwarderImplementation;
    }

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ RuleChecker methods ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // @dev implementation of public `exec` function
    function _exec(address forwarder, uint256 value, address dest) internal view virtual returns (address, uint256);

    // @dev implementation of public `execERC20` function
    function _execERC20(address forwarder, address token, uint256 value, address dest)
        internal
        view
        virtual
        returns (address, uint256);

    // @dev implementation of public `execERC721 function
    function _execERC721(address forwarder, address token, uint256 id, address dest)
        internal
        view
        virtual
        returns (address);

    // @dev implementation of public `execERC1155` function
    function _execERC1155(address forwarder, address token, uint256 id, uint256 value, address dest)
        internal
        view
        virtual
        returns (address, uint256);

    /// @inheritdoc RuleChecker
    function exec(address forwarder, uint256 value, address dest) public view override returns (address, uint256) {
        return _exec(forwarder, value, dest);
    }

    /// @inheritdoc RuleChecker
    function execERC20(address forwarder, address token, uint256 value, address dest)
        public
        view
        override
        returns (address, uint256)
    {
        return _execERC20(forwarder, token, value, dest);
    }

    /// @inheritdoc RuleChecker
    function execERC721(address forwarder, address token, uint256 id, address dest)
        public
        view
        override
        returns (address)
    {
        return _execERC721(forwarder, token, id, dest);
    }

    /// @inheritdoc RuleChecker
    function execERC1155(address forwarder, address token, uint256 id, uint256 value, address dest)
        public
        view
        override
        returns (address, uint256)
    {
        return _execERC1155(forwarder, token, id, value, dest);
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ CREATE2 utilities ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function deployForwarder(bytes32 salt) internal virtual returns (address instance) {
        address implementation = forwarderImplementation;

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)

            instance := create2(0, 0x0c, 0x35, salt)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Predicts forwarder address using CREATE2
    function computeForwarderAddress(bytes32 salt) public view returns (address computed) {
        address deployer = address(this);
        address implementation = forwarderImplementation;

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            let hash := keccak256(0x0c, 0x35)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)

            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            computed := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ ERC20 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function forwardERC20(bytes32 forwarderSalt, address token, uint256 value, address dest) public {
        address forwarderAddress = computeForwarderAddress(forwarderSalt);
        (address d, uint256 v) = _execERC20(forwarderAddress, token, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC20(token, v, d);
    }

    function createForwarderERC20(bytes32 forwarderSalt, address token, uint256 value, address dest) public {
        address forwarderAddress = deployForwarder(forwarderSalt);
        (address d, uint256 v) = _execERC20(forwarderAddress, token, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC20(token, v, d);
    }

    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ Coins ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function forward(bytes32 forwarderSalt, uint256 value, address dest) public {
        address forwarderAddress = computeForwarderAddress(forwarderSalt);
        (address d, uint256 v) = _exec(forwarderAddress, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forward(d, v);
    }

    function createForwarder(bytes32 forwarderSalt, uint256 value, address dest) public {
        address forwarderAddress = deployForwarder(forwarderSalt);
        (address d, uint256 v) = _exec(forwarderAddress, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forward(d, v);
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ ERC721 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function forwardERC721(bytes32 forwarderSalt, address token, uint256 id, address dest) public {
        address forwarderAddress = computeForwarderAddress(forwarderSalt);
        address d = _execERC721(forwarderAddress, token, id, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC721(token, id, d);
    }

    function createForwarderERC721(bytes32 forwarderSalt, address token, uint256 id, address dest) public {
        address forwarderAddress = deployForwarder(forwarderSalt);
        address d = _execERC721(forwarderAddress, token, id, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC721(token, id, d);
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ ERC1155 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function forwardERC1155(bytes32 forwarderSalt, address token, uint256 id, uint256 value, address dest) public {
        address forwarderAddress = computeForwarderAddress(forwarderSalt);
        (address d, uint256 v) = _execERC1155(forwarderAddress, token, id, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC1155(token, id, v, d);
    }

    function createForwarderERC1155(bytes32 forwarderSalt, address token, uint256 id, uint256 value, address dest)
        public
    {
        address forwarderAddress = deployForwarder(forwarderSalt);
        (address d, uint256 v) = _execERC1155(forwarderAddress, token, id, value, dest);
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.forwardERC1155(token, id, v, d);
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    /**
     * @notice function to run above operations in batches
     * @dev the batch function is a bit more complex than the others, but it allows to save gas using custom calldata encoding, which allows to reuse function parameters
     * @dev 1nd part of calldata is 1 byte that is allocated for headers count
     * @dev 2nd part of calldata is actually headers, each header is 13 bytes long, and contains following data: [operation (1 byte), token data index (1), value data index (1), nft id index (1), dest data index (1), salt (8)]
     * @dev 3nd part of calldata is data which headers refer to, each data element is 32 bytes long
     */
    function batch() external {
        uint256 headersCount;
        uint256 dataStart;

        // read first byte of calldata to get headers count, and calculate data start position using next formula (headersCount * 13 bytes) + 1 bytes for count + 4 bytes for function selector
        /// @solidity memory-safe-assembly
        assembly {
            headersCount := shr(248, calldataload(4))
            dataStart := add(mul(headersCount, 13), 5)
        }

        // temporary variables to share memory across loops
        uint8 op;
        address token;
        uint256 value;
        uint256 id;
        address dest;
        bytes32 salt;

        for (uint256 i = 0; i < headersCount; i++) {
            /// @solidity memory-safe-assembly
            assembly {
                // read 13 bytes of header
                let header := calldataload(add(5, mul(i, 13)))

                // 1nd byte of header is operation
                op := shr(248, header)
                // 2nd byte of header is token address data index
                token := calldataload(add(dataStart, mul(shr(248, shl(8, header)), 32)))
                // 3nd byte of header is value data index
                value := calldataload(add(dataStart, mul(shr(248, shl(16, header)), 32)))
                // 4nd byte of header is id data index
                id := calldataload(add(dataStart, mul(shr(248, shl(24, header)), 32)))
                // 5nd byte of header is dest data index
                dest := calldataload(add(dataStart, mul(shr(248, shl(32, header)), 32)))
                // Last 8 bytes of header is salt
                salt := shr(192, shl(40, header))
            }

            if (op == 0) {
                createForwarderERC20(salt, token, value, dest);
            } else if (op == 1) {
                forwardERC20(salt, token, value, dest);
            } else if (op == 2) {
                createForwarder(salt, value, dest);
            } else if (op == 3) {
                forward(salt, value, dest);
            } else if (op == 4) {
                createForwarderERC721(salt, token, id, dest);
            } else if (op == 5) {
                forwardERC721(salt, token, id, dest);
            } else if (op == 6) {
                createForwarderERC1155(salt, token, id, value, dest);
            } else if (op == 7) {
                forwardERC1155(salt, token, id, value, dest);
            }
        }
    }
}