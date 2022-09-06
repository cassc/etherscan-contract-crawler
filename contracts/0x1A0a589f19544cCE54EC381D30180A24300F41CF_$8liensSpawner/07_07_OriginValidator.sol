// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title OriginValidator
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract OriginValidator {
    error OneMintCallPerBlockForContracts();

    /// @notice last tx.origin mint block when using contracts
    mapping(address => uint256) private _contractLastBlockMinted;

    // this modifier helps to protect against people using contracts to mint
    // a big amount of NFTs in one call
    // for people minting through contracts (custom or even Gnosis-Safe)
    // we impose a limit on tx.origin of one call per block
    // ensuring a loop can not be used, but still allowing contract minting.
    // This allows Gnosis & other contracts wallets users to still be able to mint
    // This is not the perfect solution, but it's a "not perfect but I'll take it" compromise
    modifier validateOrigin() {
        if (tx.origin != msg.sender) {
            if (block.number == _contractLastBlockMinted[tx.origin]) {
                revert OneMintCallPerBlockForContracts();
            }
            _contractLastBlockMinted[tx.origin] = block.number;
        }
        _;
    }
}