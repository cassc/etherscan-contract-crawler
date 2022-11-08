// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Mintpass Struct definition used to validate EIP712.
 *
 * {minterAddress} is the mintpass owner (It's reommenced to
 * check if it matches msg.sender in your call function)
 * {minterCategory} determines what type of minter is calling:
 * (1, default) AllowList
 */
library LibMintpass {
    bytes32 private constant MINTPASS_TYPE =
        keccak256(
            "Mintpass(address wallet,uint256 tier)"
        );

    struct Mintpass {
        address wallet;
        uint256 tier;
    }

    function mintpassHash(Mintpass memory mintpass) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINTPASS_TYPE,
                    mintpass.wallet,
                    mintpass.tier
                )
            );
    }
}