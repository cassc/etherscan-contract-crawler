// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibSignatures {
    /**
     * @notice A struct containing the recovered Signature
     */
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    /**
     * @notice A struct containing the Allocation info
     * @dev For the array members, need to have the same length.
     * @param sellTokens Array of ERC-20 token addresses to sell
     * @param sellAmounts Array of ERC-20 token amounts to sell
     * @param buyTokens Array of ERC-20 token addresses to buy
     * @param spenders Array of the spenders addresses
     * @param swapTargets Array of the targets to interact with (0x Exchange Proxy)
     * @param swapsCallDAta Array of bytes containing the calldata
     * @param partyValueDA Current value of the Party in denomination asset
     * @param partyTotalSupply Current total supply of the Party
     * @param expiresAt Block timestamp expiration date
     */
    struct Allocation {
        address[] sellTokens;
        uint256[] sellAmounts;
        address[] buyTokens;
        address[] spenders;
        address payable[] swapsTargets;
        bytes[] swapsCallData;
        uint256 partyValueDA;
        uint256 partyTotalSupply;
        uint256 expiresAt;
    }

    /**
     * @notice Returns the address that signed a hashed message with a signature
     */
    function recover(bytes32 _hash, bytes calldata _signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(_hash, _signature);
    }

    /**
     * @notice Returns an Ethereum Signed Message.
     * @dev Produces a hash corresponding to the one signed with the
     * [eth_sign JSON-RPC method](https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]) as part of EIP-191.
     */
    function getMessageHash(bytes memory _abiEncoded)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(_abiEncoded)
                )
            );
    }

    /**
     * @notice Verifies the tx signature against the PartyFi Sentinel address
     * @dev Used by the deposit, join, kick, leave and swap actions
     * @param user The user involved in the allocation
     * @param signer The PartyFi Sentinel singer address
     * @param allocation The allocation struct to verify
     * @param rsv The values for the transaction's signature
     */
    function isValidAllocation(
        address user,
        address signer,
        Allocation memory allocation,
        Sig memory rsv
    ) internal view returns (bool) {
        // 1. Checks if the allocation hasn't expire
        if (allocation.expiresAt < block.timestamp) return false;

        // 2. Hashes the allocation struct to get the allocation hash
        bytes32 allocationHash = getMessageHash(
            abi.encodePacked(
                address(this),
                user,
                allocation.sellTokens,
                allocation.sellAmounts,
                allocation.buyTokens,
                allocation.spenders,
                allocation.swapsTargets,
                allocation.partyValueDA,
                allocation.partyTotalSupply,
                allocation.expiresAt
            )
        );

        // 3. Validates if the recovered signer is the PartyFi Sentinel
        return ECDSA.recover(allocationHash, rsv.v, rsv.r, rsv.s) == signer;
    }
}