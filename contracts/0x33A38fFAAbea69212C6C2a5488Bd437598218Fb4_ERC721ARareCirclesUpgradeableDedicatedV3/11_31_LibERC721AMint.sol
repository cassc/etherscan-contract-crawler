// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibERC721AMint {
    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
    keccak256(
        "Mint721A(uint256 cost,uint256 amount,uint256 limit,uint256 fee,address recipient)"
    );

    struct Mint721AData {
        uint256 cost;
        uint256 amount;
        uint256 limit;
        uint256 fee;
        address recipient;
        bytes signature;
    }

    function hash(Mint721AData memory data) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.cost,
                data.amount,
                data.limit,
                data.fee,
                data.recipient
            )
        );
    }
}