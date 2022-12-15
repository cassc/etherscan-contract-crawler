pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./Plonk4VerifierWithAccessToDNext.sol";
import "../common/libraries/UncheckedMath.sol";

contract Verifier is Plonk4VerifierWithAccessToDNext {
    using UncheckedMath for uint256;

    function get_verification_key() internal pure returns (VerificationKey memory vk) {
        vk.num_inputs = 1;
        vk.domain_size = 67108864;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        // coefficients
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x19af674d98a56e4b530aa94bf82df98768bb214aa1f261b1d1fb6789f9e66d67,
            0x0335e647418f85e76d27feca0cce7027b92b0eabf93888219b9beca066886730
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0503f826267486c0a6d73afb4d9a8f0ed019d5d129fcedcbfa0b2970c8a3d7fa,
            0x008af7d231afc190a96c02da5cc6721fcff5e01ba1ad65540a3fde576802d1cd
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x0198011f9c1c53811036bc8e0e8002c1b8892001e9ce0cd18110af9a03087421,
            0x25933f6eb6db13720269a863a55db5dd31c96b1ee0da61e34e09f83a59297ca2
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x17e76e39a1a2e71f32b5cab55c4eef178a632e7d907153e06f53e364dbd2cbc8,
            0x21fccb59891624d9d9d35d0f661afb120ca1f78628b8aa59beeefd4431107e88
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x1b041d57c56b8521f2520442e462f755721ab4aeb573487618ce09910a8c6354,
            0x0e4ec17897446c4fd1c36559405a0d2def071c4ad5b9124116db5654129ffed5
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2a06f3104a04d0a5272f5e623cdecdce7e06b4aef361be0786f3a6814280d05b,
            0x21541f91d1e19e517d6471dba9f048355896e9a2bf7ececbecbdc63431ecb261
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x204b887749553f1d24bec0f6066088454b586d25fc57d716679517d12082e1ed,
            0x27f989c5dd011c6aaf441068780f3b133eb2bde878843155c85abeec4ab91f11
        );
        vk.gate_setup_commitments[7] = PairingsBn254.new_g1(
            0x1a8cd862024729474b1b5ef122acf86f759433abaefdcfb8fa7e6ad761b112b2,
            0x2a80832c2d1f2e7aa625b720d14b93f628c107ef41d78d492aa123c75d97a848
        );
        // gate selectors
        vk.gate_selectors_commitments[0] = PairingsBn254.new_g1(
            0x1633993f359a7b1738f2fbd69ce7643e423570fb0a6fe55a244bea41596dfc3d,
            0x2cf6203dad1d1295d1793cdd114195c129b0ecc663f4e92917c1490980385a44
        );
        vk.gate_selectors_commitments[1] = PairingsBn254.new_g1(
            0x10f0ab2fda24f693b7851a3c626c5eb3dd1ef9bacc68fdbfe638466f8fc2b949,
            0x15fde64ce1ae3313f039d7b9b7f192fa5a7b0bd80307c67cfed47fae20f008e4
        );
        // permutation
        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x03a5af959e223de35693573bc896f333fac84cfe4f272c4080bc102e4c4752b3,
            0x102cd8e77890c56a99a9cf9bb964ee3e3b60629e35f60b94a97932903b31cbc6
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x0f4c46be8af3e4fa5e0ce6d2985b1db29177975309e55748da391d2b81c98288,
            0x1c5bed67fe034739a649e373e684120495431377c2d4e81689d678635ea737b2
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x2a990254375e7cc9bec8ab68e5a5ec5ee49de5b2a6b0b33cecb557125aa93b43,
            0x046b3e9a530f72b2a8d3226b1285ce7b656bb112e243750664fe066423bcb4ca
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x281baa0297d9c6d6a8d79caa59fa5dd78efe760dfd4a1ae7575b8b996497e4cc,
            0x22a32326f73a3d070184f7da88ebec776d1ef63207bb2b5e04d28307eeed9c47
        );
        // lookup table commitments
        vk.lookup_selector_commitment = PairingsBn254.new_g1(
            0x1035bcc4f67bc18af0db54384cc120d50060121d3b2a4e8698937756b3f73b54,
            0x1b1eebcd824d7b114cd230e0a450b63ff5218a6141bb5bf013a79ba2ab6f7ddb
        );
        vk.lookup_tables_commitments[0] = PairingsBn254.new_g1(
            0x0ebe0de4a2f39df3b903da484c1641ffdffb77ff87ce4f9508c548659eb22d3c,
            0x12a3209440242d5662729558f1017ed9dcc08fe49a99554dd45f5f15da5e4e0b
        );
        vk.lookup_tables_commitments[1] = PairingsBn254.new_g1(
            0x1b7d54f8065ca63bed0bfbb9280a1011b886d07e0c0a26a66ecc96af68c53bf9,
            0x2c51121fff5b8f58c302f03c74e0cb176ae5a1d1730dec4696eb9cce3fe284ca
        );
        vk.lookup_tables_commitments[2] = PairingsBn254.new_g1(
            0x0138733c5faa9db6d4b8df9748081e38405999e511fb22d40f77cf3aef293c44,
            0x269bee1c1ac28053238f7fe789f1ea2e481742d6d16ae78ed81e87c254af0765
        );
        vk.lookup_tables_commitments[3] = PairingsBn254.new_g1(
            0x1b1be7279d59445065a95f01f16686adfa798ec4f1e6845ffcec9b837e88372e,
            0x057c90cb96d8259238ed86b05f629efd55f472a721efeeb56926e979433e6c0e
        );
        vk.lookup_table_type_commitment = PairingsBn254.new_g1(
            0x011967367ae87879d15a58c58e4849bc897764ce3f016d5abc04bc7804d6bdf7,
            0x29775ffa2d2ddd439a664e165294f68ea17d6d754bcf4c20a52fbf766eeb1995
        );
        // non residues
        vk.non_residues[0] = PairingsBn254.new_fr(0x0000000000000000000000000000000000000000000000000000000000000005);
        vk.non_residues[1] = PairingsBn254.new_fr(0x0000000000000000000000000000000000000000000000000000000000000007);
        vk.non_residues[2] = PairingsBn254.new_fr(0x000000000000000000000000000000000000000000000000000000000000000a);

        // g2 elements
        vk.g2_elements[0] = PairingsBn254.new_g2(
            [
                0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
                0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
        vk.g2_elements[1] = PairingsBn254.new_g2(
            [
                0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
                0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0
            ],
            [
                0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
                0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55
            ]
        );
    }

    function deserialize_proof(uint256[] calldata public_inputs, uint256[] calldata serialized_proof)
        internal
        pure
        returns (Proof memory proof)
    {
        // require(serialized_proof.length == 44); TODO
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i = i.uncheckedInc()) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j;
        for (uint256 i = 0; i < STATE_WIDTH; i = i.uncheckedInc()) {
            proof.state_polys_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j.uncheckedInc()]
            );

            j = j.uncheckedAdd(2);
        }
        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);

        proof.lookup_s_poly_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);

        proof.lookup_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);
        for (uint256 i = 0; i < proof.quotient_poly_parts_commitments.length; i = i.uncheckedInc()) {
            proof.quotient_poly_parts_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j.uncheckedInc()]
            );
            j = j.uncheckedAdd(2);
        }

        for (uint256 i = 0; i < proof.state_polys_openings_at_z.length; i = i.uncheckedInc()) {
            proof.state_polys_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }

        for (uint256 i = 0; i < proof.state_polys_openings_at_z_omega.length; i = i.uncheckedInc()) {
            proof.state_polys_openings_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        for (uint256 i = 0; i < proof.gate_selectors_openings_at_z.length; i = i.uncheckedInc()) {
            proof.gate_selectors_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        for (uint256 i = 0; i < proof.copy_permutation_polys_openings_at_z.length; i = i.uncheckedInc()) {
            proof.copy_permutation_polys_openings_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j = j.uncheckedInc();
        }
        proof.copy_permutation_grand_product_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_s_poly_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_grand_product_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_t_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j = j.uncheckedInc();
        proof.lookup_t_poly_opening_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_selector_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.lookup_table_type_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.quotient_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.linearization_poly_opening_at_z = PairingsBn254.new_fr(serialized_proof[j]);
        j = j.uncheckedInc();
        proof.opening_proof_at_z = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
        j = j.uncheckedAdd(2);
        proof.opening_proof_at_z_omega = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j.uncheckedInc()]
        );
    }

    function verify_serialized_proof(uint256[] calldata public_inputs, uint256[] calldata serialized_proof)
        public
        view
        returns (bool)
    {
        VerificationKey memory vk = get_verification_key();
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        return verify(proof, vk);
    }
}