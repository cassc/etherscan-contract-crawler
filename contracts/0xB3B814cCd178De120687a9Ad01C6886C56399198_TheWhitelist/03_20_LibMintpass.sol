// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Mintpass Struct definition used to validate EIP712.
 *
 * {minterAddress} is the mintpass owner (It's reommenced to
 * check if it matches msg.sender in your call function)
 * {amount} is the maximum mintable amount, only used for Free Mints.
 * {minterCategory} determines what type of minter is calling:
 * (1, default) Whitelist, (99) Freemint
 */
library LibMintpass {
    bytes32 private constant MINTPASS_TYPE =
        keccak256(
            "Mintpass(address minterAddress,uint256 amount,uint256 minterCategory)"
        );

    struct Mintpass {
        address minterAddress;
        uint256 amount;
        uint256 minterCategory;
    }

    function mintpassHash(Mintpass memory mintpass) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINTPASS_TYPE,
                    mintpass.minterAddress,
                    mintpass.amount,
                    mintpass.minterCategory
                )
            );
    }
}