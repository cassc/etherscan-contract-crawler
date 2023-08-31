pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x175161c7eb22ac7582ace00443b1ebcda1ad614db26e7aa24522c028ef033a7e;
    uint8 constant VK_MAX_INDEX = 2;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(36)) { return getVkAggregated36(); }
    }

    
    function getVkAggregated36() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 67108864;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x0f8b227a5da7ba4ea89c48f80e007c8ef3baf2046f1c70d08117f014d3562b11,
            0x029d905c0222cd7dba8b7058be29e3c9e27d46569ef6e767b2b68aed94ca28a9
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0692d6f81047f33e794b51f0dba543440ff8edf791de4ef8e44dc07b5caaebe9,
            0x1a3512fbae7189831eb1fa97df18914accd3c6ba1ed12f07c1ee7aca4b9569df
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1925ded902019bdf78a0cc175969098d468f6f710aae3efc33c573fc04d570ed,
            0x121d43a79f3694088ed4284cc55bd14084f345d7413d57ee4d24ca2f5a05b325
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x09ae8147948bcf4e68df41c0d97ec18022090fcd47e6977162b01df46f94a789,
            0x0eb3002e71052c33aeac2d434b9205e3d0df49fc7b9b10eb5ddf4fe78b8fb2bc
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x28a2d952f64c5e2ff4413b66d39f792e155570acf24a5d87d41ecb405e897005,
            0x222d7eb19a8a91eaedad5ecffacd36fa22bfb8a169b59978af6bfdd4949587d6
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x30164a64d9afb271f1c3588cd08f1df70cefed9451b14dd878b04110f98ed688,
            0x267e525295668cf05e3639cb0175dcf0ced15c0d304461674c0e071984d61362
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x07b5f013828927c63adc77b34c253c89750aa0eed6edacbcc9bcfd7faf96636b,
            0x0e494577844feb77dcb7f629de1c3d270318a6624914e36a0df02a82055c0faf
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1b1c983d52616dbf85c89d91956df529d5b6889466d64c887c46d5bcc5f313f3,
            0x0df990c408dc7fd48a6701f339b215049d7cbe3140a924ea9694854b1a8c0bc2
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x0c36170de45e0ca8b5eb40e0057bf7a49251f69053c1d0577bb2c0f47ea38121,
            0x07727b3f5cecf9bc46a1729821d16455e7d83cd11c2e6679b8bbc4ea88c80d17
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x22c588597bbf905285f8d7ef632d37466902cc85c2dede27c7112c375177b0a6,
            0x1eecbaa1568668aac833258a61eb753e162b34b017f9e64cca2d2852f8639921
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x248441946460d343823f14d62f4d79220b4b85e28df6ea090e5da3756cd2cc6a,
            0x1978e132d816af8d06d532d3f2326902e7b93ff432c007bbeef250e87a18ed8d
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x1410ba9f1a7521551eda450dbbe43c05c6d3ffc169ed6983a1531a5e99a6aaef,
            0x1bb07710b27539fd34925d1ae1c34ed55157dbbc4ea581020943166dc92246b1
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x0484ef7dded821fd523e349d14dd69411fd1ea9f91f01c53e5ef09deee390fd6,
            0x2112b9319c459091b6e21c8b8b3193d32054d1be6414d37a2b00ff4a57186d8c
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifierOld is VerifierWithDeserializeOld {

    
    function getVkExit() internal pure returns(VerificationKeyOld memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x3008cf85ebac871ab89a36302f4bbd761f9684f84e95ac98527e1adb194792c5,
            0x291a109fc66c4174c17d1de24831f3b335eb11dfe81a0a1d71d0fd40c547d2d8
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x287adbf1e6e1b03c46beca322ccbd719245c37ea8fbfe6e869ed32e9e034b50c,
            0x137529cf0e0252f8e16aa96976ce5cf7297c688060b3d095a0e6c63ad0aec761
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2aa527278f0772f73ccdc726e48a5676605b9a54b66b0690ef16893167e633ad,
            0x0db4e23439138b957ea8d9149a8e44e6d86abc562b9eb170508341f7241d492e
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x07f7036d3e7b787a51fab25347d29087e291aa40d47a7ce48ee3fc3a898adf63,
            0x15b187b6b5d190c08a9540c630e78d230905a0def16f05ad9d81cc0229661ebc
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0cac78bd72e4a765d0323ef9a46bfc4049f1afaa7f81d3bd0e5178e9b2958b33,
            0x24ac57bc5525dc0c75d2c4e24999bee9170346960454457df118da57145912cc
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x198e4480a4aa93c4085054ad681df348fd574814ddac7c97e1bc81ac705dd7c0,
            0x186fbf8382f9e305b831b0bf9169134c7a49becff4f292d2dd207ef28a4084e1
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1beb80feebc8e72f9a5cf2e96270ffb6a481918984ce04e58ed708f26b84f93e,
            0x14577c2fc6d1c57c6f2d3240d042b2208f964661c4b7ca24b021f66a72dc0ffd
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x2601f4885bc6843bc137c878b1eb82803502ea01dcbc815541bb7a243b40562f,
            0x2c98930cc7f6249fc692590d06e1f3172f8cfe928c4200b88eecf5267a34c304
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x03f08ef0c60e55baf78af5944e43474915f9d4b4dafdffb95c986c1a375acce3,
            0x2a8dd06b3a859bf43978ca45c6a18876074a9defeb153e6441f4243deee83acb
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x011bfe23a0aa76f02b37570af162172dfed5c0da108f890b458670d6662bca63,
            0x181fccff301b4c86188862578d8811f7c6ec47cb92a5015081f76fa054739fa4
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x29038ff88d21d41377caca58f8b00ae9cd5143b6dfbe4e6cb15843e0e74df9a3,
            0x28da7400cfeaaf5d42275220f73bdc3a4556eeff27b62777696e7a607d945ccc
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1, 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4, 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
}