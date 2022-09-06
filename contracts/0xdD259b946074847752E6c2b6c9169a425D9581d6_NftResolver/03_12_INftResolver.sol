// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

error AddressNotFound();
error DuplicateAddress();
error DuplicateEvmAddress();
error NotOwner();
error InvalidAddress();
error InvalidAuth();
error InvalidRegex();
error InvalidSelf();
error ProfileNotFound();

interface IRegex {
    function matches(string memory input) external pure returns (bool);
}

enum Blockchain {
    ETHEREUM,
    HEDERA,
    POLYGON,
    SOLANA,
    TEZOS,
    FLOW
}

struct AddressTuple {
    Blockchain cid;
    string chainAddr;
}

// used for historical tracking and easy on-chain access for associations for verifier
struct RelatedProfiles {
    address addr;
    string profileUrl;
}

interface INftResolver {}