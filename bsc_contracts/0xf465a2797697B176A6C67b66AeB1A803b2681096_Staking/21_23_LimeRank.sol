//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title LimeRank
    @author iMe Lab

    @notice Library for working with LIME ranks
 */
library LimeRank {
    /**
        @notice Yields proof for **subject** that **issuer** has LIME **rank**
        in a timespan, not later than **deadline**

        @dev "Proofs" make sense only if they are signed. Signing example:

        ```typescript
          const hash = ethers.utils.solidityKeccak256(
            ["address", "address", "uint256", "uint8"],
            [subject, issuer, deadline, rank]
          );
          const proof = ethers.utils.arrayify(hash);
          const sig = await arbiter.signMessage(proof);
          const { v, r, s } = ethers.utils.splitSignature(sig);
        ```

        @param subject Address of entity that performs check
        @param issuer Address of account who proofs his rank
        @param deadline Proof expiration timestamp
        @param rank LIME rank that being proofed
    */
    function proof(
        address subject,
        address issuer,
        uint256 deadline,
        uint8 rank
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(subject, issuer, deadline, rank))
                )
            );
    }
}