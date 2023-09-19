pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";
import { PackedBets, PackedBet } from "./PackedBets.sol";

/**
 * The library providing RSA-based Verifiable Random Function utilities.
 *
 * The main workhorse of our VRF generation is decrypt() function. Being given RSA modulus chunks and the memory slice
 * of 256 bytes containing encrypted VRF, it attemps to decrypt the data and expand it into a tuple of bet properties.
 *
 * The calling contract can then validate that the bet described by the returned tuple is active and proceed with settling it.
 *
 * The random number source is the hash of encrypted data chunk. The players cannot predict that value since they do not know
 * the secret key corresponding to the RSA modulus hardcoded in the contract; the house cannot tamper with player's bets since
 * the VRF value that passes all the checks is unique due to RSA being a permutation (see Dice9.sol for the proof).
 *
 * The distribution is uniform due to RSA ciphertext being hashed.
 *
 * The above properties allow Dice9 to perform robust and verifiable random number generation using a seed value consisting of bet
 * information such as player address, bet amount, bet options and bet nonce.
 */
library VRF {
  // Extension functions
  using PackedBets for PackedBet;

  // The byte length of the RSA modulus (1024 bits)
  uint constant internal RSA_MODULUS_BYTES = 128;
  // The byte length of the RSA ciphertext (1024 bits)
  uint constant internal RSA_CIPHER_TEXT_BYTES = 128;
  // The byte length of the RSA exponent (we use a hardcoded value of 65537)
  uint constant internal RSA_EXPONENT_BYTES = 32;
  // The RSA exponent value
  uint constant internal RSA_EXPONENT = 65537;
  // The address of EIP-198 modExp precompile contract, which makes RSA decryption gas cost feasible.
  address constant internal EIP198_MODEXP = 0x0000000000000000000000000000000000000005;
  // The value that the first 256 bits of the decrypted text must have (254 ones).
  uint constant internal P0_PADDING_VALUE = 2 ** 254 - 1;
  // The bit number where the contract address value starts in the first 256 bit decoded chunk
  uint constant internal P1_CONTRACT_ADDRESS_BIT_OFFSET = 96;
  // The bit number where the 30 bit (without 2 epoch bits) packed bet data starts in the first 256 bit decoded chunk
  uint constant internal P1_PACKED_BET_BIT_OFFSET = 160;
  // The bit number where the player nonce data starts in the first 256 bit decoded chunk
  uint constant internal P1_PLAYER_NONCE_BIT_OFFSET = 160 + 30;

  // The error indicating that the ciphertext was decrypted into something invalid (e.g. random bytes were submitted to reveal a bet)
  error InvalidSignature();

  /**
   * Being given all the bet attributes, computes a hash sum of the bet, allowing the contract to quickly verify the equivalence
   * of the bets being considered as well as providing a unique identifier for any bet ever placed.
   *
   * @param player the address of the player placing the bet.
   * @param playerNonce the seq number of the bet played by this player against this instance of the contract.
   * @param packedBet an instance of PackedBet representing a bet placed by the player.
   *
   * @return the keccak256 hash of all the parameters prefixed by the chain id and contract address to avoid replay and Bleichenbacher-like attacks.
   */
  function computeVrfInputHash(address player, uint playerNonce, PackedBet packedBet) internal view returns (bytes32) {
    return keccak256(abi.encode(block.chainid, address(this), player, playerNonce, packedBet.toUint()));
  }

  /**
   * Performs RSA "decryption" procedure using BigModExp (https://eips.ethereum.org/EIPS/eip-198) to remain gas-efficient.
   *
   * If the cipherText was produced by a legic signatory (i.e. a party possessing the secret key that corresponds to the hardcoded modulus and exponent),
   * the plaintext produced can further be decoded into a set of bet attributes and a number of checksum-like fields, which get validated as well
   * to make sure the bet attributes descibed are accurate, have not been taken from previous bets and so on.
   *
   * As mentioned above, cipherText gets hashed using keccak256 hash function to further be used as a source of entropy by the smart contract
   * to determine the outcome of the bet, the amount to be paid out, the jackpot roll value and so on.
   *
   * Assuming the hardcoded modulus corresponds to a set of valid RSA parameters (see Dice9.sol for the proof), every set of bet attributes would
   * produce a single cipherText decrypting into that same bet attributes, meaning that any bet a player places would get a single random number
   * associated.
   *
   * @param modulus0 first 32 bytes of the modulus
   * @param modulus1 second 32 bytes of the modulus
   * @param modulus2 third 32 bytes of the modulus
   * @param modulus3 fourth 32 bytes of the modulus
   * @param cipherText the ciphertext received from a Croupier to decrypt.
   *
   * @return vrfHash the hash of cipherText which can be used as the entropy source
   *         vrfInputHash the hash of bet attributes (see computeVrfInputHash() above)
   *         player the address of the player of the bet represented by given ciphertext
   *         playerNonce the player nonce of the bet represented by given ciphertext
   *         packedBet an instance of PackedBet of the bet represented by given ciphertext.
   */
  function decrypt(uint modulus0, uint modulus1, uint modulus2, uint modulus3, bytes calldata cipherText) internal view returns (bytes32 vrfHash, bytes32 vrfInputHash, address player, uint playerNonce, PackedBet packedBet)  {
    vrfHash = keccak256(cipherText);

    // RSA decryption
    bytes memory precompileParams = abi.encodePacked(
      // byte length of the ciphertext
      RSA_CIPHER_TEXT_BYTES,
      // byte length of the exponent value
      RSA_EXPONENT_BYTES,
      // byte length of the modulus
      RSA_MODULUS_BYTES,
      // the ciphertext to decrypt
      cipherText,
      // exponent value
      RSA_EXPONENT,
      // modulus values
      modulus0,
      modulus1,
      modulus2,
      modulus3
    );

    // EIP-198 places BigModExp precompile at 0x5
    (bool modExpSuccess, bytes memory plainText) = EIP198_MODEXP.staticcall(precompileParams);

    // make sure the decryption succeeds
    require(modExpSuccess, "EIP-198 precompile failed!");

    // unpack the bet attributes from the decrypted text
    (player, playerNonce, packedBet, vrfInputHash) = unpack(plainText);
  }

  /**
   * Unpacks the bet attributes from the plaintext (decrypted bytes) presented as an argument.
   *
   * The routine checks that the leading padding is set to a specific value - to make sure the ciphertext produced was actually created with
   * a valid secret key correponding to the contract's public key (RSA modulus).
   *
   * An additional check tests that the ciphertext was produced for this particular contract on this particular chain by checking decoded
   * data – otherwise it is considered a replay attack with data taken from another chain.
   * 
   * Last but not least, decoded parameters are equality tested against the corresponding vrfInputHash in the lowest 256 bits of the plaintext
   * to prevent Bleichenbacher style attacks (bruteforcing the plaintext to obtain a perfect power).
   *
   * @param plainText the decoded array of bytes as returned during the decryption stage.
   *
   * @return player the address of the player placing the bet.
   *         playerNonce the seq number of the player's bet against this instance of the contract.
   *         packedBet the instance of PackedBet describing the bet the player placed.
   *         vrfInputHash the hash of the input parameters of the bet prior to encoding.
   */
  function unpack(bytes memory plainText) private view returns (address player, uint playerNonce, PackedBet packedBet, bytes32 vrfInputHash) {
    uint p0;
    uint p1;
    uint p2;

    // decode the plaintext into 4 uint256 chunks
    (p0, p1, p2, vrfInputHash) = abi.decode(plainText, (uint, uint, uint, bytes32));

    // the first 32 bytes should be equal to a hardcoded value to guarantee the ciphertext was produced by a legit signatory
    if (p0 != P0_PADDING_VALUE) {
      revert InvalidSignature();
    }

    // the second 32 bytes should contain the contract's address (bits 96..256) and chain id (bits 0..96)
    if (p1 != uint(uint160(address(this))) << P1_CONTRACT_ADDRESS_BIT_OFFSET | block.chainid) {
      revert InvalidSignature();
    }

    // the player address is going to be kept in lowest 160 bits of the next 32 bytes
    player = address(uint160(p2));
    // the packed bet occupies 30 bits in positions 161..190, the remaining 2 bits are supposed to store epoch value which we simply discard
    // by masking the value against PackedBets.ALL_BUT_EPOCH_BITS
    packedBet = PackedBet.wrap((p2 >> P1_PACKED_BET_BIT_OFFSET) & PackedBets.ALL_BUT_EPOCH_BITS);
    // the player nonce is the easiest, it takes bites 191..256, so just transfer it over
    playerNonce = p2 >> P1_PLAYER_NONCE_BIT_OFFSET;

    // the last but not least: verify that the ciphertext contained an ecrypted bet attributes for the encoded
    // bet attributes – this disallows the signatory to craft multiple ciphertexts per bet attributes by tampering with vrfInputHash bytes
    if (vrfInputHash != VRF.computeVrfInputHash(player, playerNonce, packedBet)) {
      revert InvalidSignature();
    }
  }
}