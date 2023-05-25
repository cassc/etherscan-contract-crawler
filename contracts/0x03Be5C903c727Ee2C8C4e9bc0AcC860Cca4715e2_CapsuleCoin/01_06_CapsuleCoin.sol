// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * Capsule Coin is the ERC20 token for the Ternoa platform. It is received and
 * used by early supporters while waiting for the Ternoa chain to be released.
 * Once the Ternoa Chain is live people will have a way to convert their ERC20s
 * to the Ternoa Chain native asset.
 *
 * It should act as a standard ERC20, along with some niceties (read below).
 *
 * Accounts have the ability to sign off-chain "proofs" that can be used by other
 * accounts to do the equivalent of a `transferFrom` operation. This is mostly used
 * for granting coins to presale investors. Indeed, this avoids us having to create
 * hundreds of transactions or deploy a heavy contract just to do so. Instead, people
 * will be able to fetch their "proof of claim" and submit it against the contract to
 * retrieve their coins.
 * A proof of claim is composed of:
 * - the source and destination accounts.
 * - the amount of coins involved.
 * - a block after which it can be executed, if the proof is submitted too early it should
 *   be rejected.
 * - a nonce used to avoid replay attacks, if the nonce was already seen for the same source
 *   account the proof should be discarded.
 */
contract CapsuleCoin is ERC20 {
    using ECDSA for bytes32;

    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    constructor(address vault) ERC20("Capsule Coin", "CAPS") {
        // We create 2.5B coins but the token has 18 decimals.
        _mint(vault, 2500000000 * (10**18));
    }

    /*
     * @description Create the hash that needs to be signed to create a claimable proof.
     * @param from The account we will claim funds from.
     * @param to The account that will receive the funds.
     * @param amount The amount of coins we will transfer.
     * @param validity The block number after which we can use the proof.
     * @param nonce A unique value to avoid replay attacks.
     * @return The hash that needs to be signed by the from account.
     */
    function hashForClaim(
        address from,
        address to,
        uint256 amount,
        uint256 validity,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(from, to, amount, validity, nonce));
    }

    /*
     * @description Verify a proof for a claim and execute it if it is valid.
     * @param proof The result of `hashForClaim` signed by `from` to authorized
     * the transfer.
     * @param from The account we will claim funds from.
     * @param to The account that will receive the funds.
     * @param amount The amount of coins we will transfer.
     * @param validity The block number after which we can use the proof.
     * @param nonce A unique value to avoid replay attacks.
     */
    function claimOffchainGrant(
        bytes calldata proof,
        address from,
        address to,
        uint256 amount,
        uint256 validity,
        uint256 nonce
    ) external {
        require(validity <= block.number, "Ternoa: too early");
        require(!nonceUsed[from][nonce], "Ternoa: nonce already used");

        bytes32 hashThatShouldBeSigned =
            hashForClaim(from, to, amount, validity, nonce)
                .toEthSignedMessageHash();
        require(
            hashThatShouldBeSigned.recover(proof) == from,
            "Ternoa: bad proof"
        );

        nonceUsed[from][nonce] = true;
        _transfer(from, to, amount);
    }
}