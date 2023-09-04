// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibCREATE3
 *
 * @notice Library to deploy to deterministic addresses without an initcode
 *         factor
 *
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/CREATE3.sol)
 * @author Modified from Solady (https://github.com/Vectorized/solady/blob/50cbe1909e773b7e4ba76049c75a203e626d55ba/src/utils/CREATE3.sol)
 */
library LibCREATE3 {
    // ╭────────────────────────────────────────────────────────────────────╮
    // │ Opcode      │ Mnemonic         │ Stack        │ Memory             │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ 36          │ CALLDATASIZE     │ cds          │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 cds        │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 0 cds      │                    │
    // │ 37          │ CALLDATACOPY     │              │ [0..cds): calldata │
    // │ 36          │ CALLDATASIZE     │ cds          │ [0..cds): calldata │
    // │ 3d          │ RETURNDATASIZE   │ 0 cds        │ [0..cds): calldata │
    // │ 34          │ CALLVALUE        │ value 0 cds  │ [0..cds): calldata │
    // │ f0          │ CREATE           │ newContract  │ [0..cds): calldata │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ Opcode      │ Mnemonic         │ Stack        │ Memory             │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ 67 bytecode │ PUSH8 bytecode   │ bytecode     │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 bytecode   │                    │
    // │ 52          │ MSTORE           │              │ [0..8): bytecode   │
    // │ 60 0x08     │ PUSH1 0x08       │ 0x08         │ [0..8): bytecode   │
    // │ 60 0x18     │ PUSH1 0x18       │ 0x18 0x08    │ [0..8): bytecode   │
    // │ f3          │ RETURN           │              │ [0..8): bytecode   │
    // ╰────────────────────────────────────────────────────────────────────╯
    bytes private constant _PROXY_BYTECODE =
        hex"67363d3d37363d34f03d5260086018f3";

    bytes32 private constant _PROXY_BYTECODE_HASH = keccak256(_PROXY_BYTECODE);

    /// @dev Deploys `creationCode` deterministically with `salt` and returns the
    ///      deployed contract's address.
    ///
    ///      Note that the address of the deployed contract solely depends on
    ///      `salt`. The deterministic address for `salt` can be computed
    ///      beforehand via `addressOf(bytes32)(address)`.
    function tryDeploy(bytes32 salt, bytes memory creationCode)
        internal
        returns (bool, address)
    {
        // Load proxy's bytecode into memory as direct access not supported in
        // inline assembly.
        bytes memory proxyBytecode = _PROXY_BYTECODE;

        address proxy;
        assembly ("memory-safe") {
            // Deploy a new contract with pre-made bytecode via CREATE2.
            // Start 32 bytes into the code to avoid copying the byte length.
            // forgefmt: disable-next-item
            proxy := create2(
                        0,
                        add(proxyBytecode, 32),
                        mload(proxyBytecode),
                        salt
                     )
        }

        // Fail if deployment failed.
        if (proxy == address(0)) {
            return (false, address(0));
        }

        // Get deployed proxy and initialize creationCode.
        address deployed = addressOf(salt);
        (bool ok,) = proxy.call(creationCode);

        // Fail if call or initialization failed.
        if (!ok || deployed.code.length == 0) {
            return (false, address(0));
        }

        // Otherwise return deployed contract address.
        return (true, deployed);
    }

    /// @dev Returns the deterministic address for `salt`.
    function addressOf(bytes32 salt) internal view returns (address) {
        address proxy = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            // Prefix:
                            bytes1(0xFF),
                            // Creator:
                            address(this),
                            // Salt:
                            salt,
                            // Bytecode hash:
                            _PROXY_BYTECODE_HASH
                        )
                    )
                )
            )
        );

        return address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            // 0xd6 =   0xc0 (short RLP prefix)
                            //        + 0x16 (length of 0x94 ++ proxy ++ 0x01)
                            // 0x94 =   0x80
                            //        + 0x14 (0x14 = 20 = length of address)
                            hex"d694",
                            proxy,
                            // Nonce of proxy contract:
                            hex"01"
                        )
                    )
                )
            )
        );
    }
}