pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x1ffdc7ebe04681d451ae0658a6ad27feb63835b0edf90bdfa203cd8d12282ace;
    uint8 constant VK_MAX_INDEX = 3;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) { return getVkAggregated1(); }
        else if (_proofs == uint32(4)) { return getVkAggregated4(); }
        else if (_proofs == uint32(8)) { return getVkAggregated8(); }
    }

    
    function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x16782f42f191b0b1841c2b6a42b7f0564af065d04818526df6c3ad41fe35f8da,
            0x125b9c68c0b931578f8a18fd23ce08e7b7c082ad76404ccece796fa9b3ec0cb0
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2511833eee308a3936b23b27c929942a60aa780747bf32143dc183e873144bfd,
            0x1b8d88d78fcc4a36ebe90fbbdc4547442411e0c8d484727d5c7c6eec27ad2df0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x2945641d0c5556aa333ef6c8431e24379b73eccbed7ff3e9425cc64aee1e92ed,
            0x25bbf079192cc83f160da9375e7aec3d3d2caac8d831a29b50f5497071fc14c6
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x09b3c361e5895a8e074eb9b9a9e57af59966f0464068460adc3f64e58544afa4,
            0x0412a017f775dd05af16cf387a1e822c2a7e0f8b7cfabd0eb4eb0f67b20e4ada
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x244b30447ab3e56bb5a5a7f0ef8463a4047476ea269735a887b3de568b3401a3,
            0x2ba860198d5e6e0fd93355cb5f309e7e4c1113a57222830961999b79b83d700f
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0e13af99775bf5555c366e9c8d4af25a2e195807b766b422856525c01a38b12d,
            0x1787389894222dba5371ab55d512460c5205c1baa0421fc877b183025079a472
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x233a03f89c094cf39c89020772d9b912bd0c303d211002ee5afc5c59e241f02b,
            0x04fa51fca1b17399bbbf2b99f17bbce6af1f50b085add4c41ac4ea64f65f4674
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1ca088ed531e65b722c8b48568359bbe11051b86f1a8e8951eacc615d9faed3b,
            0x074b06c09de93dd79e070a9ded635e21a34d7178e9a670766e8208149c28e339
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x2b4c77c0d47676559061b47968a044aec625cb907181457428e5d08df9b27ef8,
            0x1c1be561bdc3eba16162886a2943882157f98ed8246f2063028497f1c108fa93
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x238fd7f2cbc3c3e5899483633c78f051e6d6d25f31aaa6b32b863d55b20d641a,
            0x1f9877b625eaae7a084582a2ffce326a6a5558f3efdb3367037098c4ca25a647
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x0b126f60653e371f3f2a85301f16e9cf4af04922a2725fc131b17e90e13d0d84,
            0x13bc3f0c7475b74591827463943b35cfd05adb7094a79eeeee2067e8e28a8e84
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x06cae3c1e5b43afb4dda3243c99da693a27eba065fd61a873e99e2c85fd22719,
            0x14343c6bdcc85b01b053f26aa3c473cb2f24747ba6d6b90b2323b24f3dfd127e
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x217564e2c710d050161b57ef2700e1676251a6d457c4b0d94c41a4492d6dcea3,
            0x2365779642d63803d0265a7cc666b3af6ad92b7e9ef38d9113db1208b83f0732
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
    
    function getVkAggregated4() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x1878d6c837a0f16cb055d3a4e79fba0d85de670dacd708dadd55407b0619796d,
            0x0b3282e52a38ecec63ba42710e8d1ad5c8715c7ed07ce217a3eec747a3f37d76
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x07425bcaf480e377886678d5b5432f0945e3fc952126503a7b672dc4b03f2c26,
            0x155b8003ea27945bf43fb5f43291f76e2aa361e0ec81550c0af66dcd1dc8077e
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1292b8795f05fc50782ea7303e2b65a7b2f0e1cc3dead51dfa0b9d2183e5d907,
            0x220d344a384ac53f682e1be6c69407a1fadd0a589de36b95ddc4da05693ba679
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x283412c1942c0cb3fffc935aab313a37510888bd5ae5972d8d67edc2312af895,
            0x1040e655967354e7ae9227c6200c2256cdcbb707e7158b66462aba23d96b8de2
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x2abe282377038904420434202c11a4f849e64babd436b93192d8d9c34d28ce44,
            0x19f0ed010326da1cf8ac93a0f73617ab7c9acb30a0c23a26db9ec19ab6a52fcb
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x236f01e67b19be0e7487100a14fd04a05a83a5660966ace987c5248f8c883459,
            0x0ebe824fb1e778491bcb8091d2adbc18dceda4fa9ee191b71c5834a71c533c41
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x2ad3c37aa0b1335f6c70d0e10f0a123a28ea012e857df30e3ced524ef6562c71,
            0x1b52d7ac4ee6082438deab8ab0f2944c9fd53258de305065f8323a3767dd8234
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x173c39587688a8967e915959df613aecf44ad0c7d2019ec32311bccdf542c78e,
            0x2421a36a67559ed89afbff081cd45b318835e2b0233c047d030abc48b5011c22
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x177d8ef11cac24105d4b38e035b891986d163d9df717fce12d18af324f86d2dc,
            0x02cd01ba1c82c85b4f0f8c7304254de64516857ac4f7bb60f052bb2af98132c5
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x21da2c0f2b7849d4c44dbc487d370cccbae78fbd979e79575e04b7a983f2f68a,
            0x14ffb806769ccf0d2c692cd93653491966525554d79efc37cfba5a5c08b15039
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x184cc2f37e687a9be2404cd367536f14a505f086fd597cb966c5b753f325adb4,
            0x20aaed49755efed4814025ac679570f62b8c98a1b8d977969242c3ffa67884d6
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x0a2dee920031d9cd5ed499dc3cb901657079f6a2dfb0ba389b0181803bb91e24,
            0x272ac2a214f46be0ed7d2b4cf125504ef82d929b1c1ec0a81655c66f39403cd1
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x07e360365c7a5363389b2d2449b9471754591f01a623fd5553c5cfe6bad19aaf,
            0x1b814914958835ef86de3c26c6c4bdc27e947f38cb0d2bfaa421d66cabfb7d55
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
    
    function getVkAggregated8() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x1aab46b9aa3adcac623c360e4d075572e3f56f4c75ac3b8663a7b059bd9b1857,
            0x166ac39283efa3d6cb36423e83e2360f006e5fa374b454dea5fe92cc50d4193f
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x13bce0a7bfbf2e7a81f18e84966c32422446b01f54cc7dc2ad3f64e92fe94cad,
            0x0247234b0cdfd8c95a767f84303c3dd65ce7b15856c2840635d9d4754ba99479
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x08742bad9a7cbcc9dbb49a25bebce179295d1cf70fd8f9c8e82b8a658ee0b67c,
            0x2a467983257850c5fa27f2f52f0c5c5fc98e7d2e0d440a8fd954ad981ff0ce9f
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x16ebdd4b95b872cd09c13b6b54a8b8bf81a01529a71234db26e3b22c6d632723,
            0x034219d7ad9ef204cfb3e32c4a47af82eea40504c2b1bac785104731722ed617
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x2e3a7c4458a8dc1535e68bac5dd5c1c9ff3886df4156bad4a08fcd08ebf1db26,
            0x173859705317db06e5b7d260898ab08e72fae987c272b82345105d72bfd00ab8
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0b830132e3325eaaea73c1095e615358db38dfb39248c90f8ff4afde169e7657,
            0x0bfedf8cfce7260c16bb1f76ad9a39f73a68087e5c68e841020aeaa5ba301a9f
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x1660c850da793add523f7990b983896e50d5549eec7990ec26aabc220ca58d52,
            0x0ba698e78dee0d41cf8aefde82c5bfda38be071e11025b56db779ddb40a4fe92
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x024fe4ce02dd48937e4642b66308ae15d731e0ea82fc5430a0470d9a5dab3694,
            0x177cac2d79a8bfa6aba134e24bded06d06219979c18b2fa4fe71baea9885985d
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x00a848bc76c52faf7d4e7cc4086b50e3ccc9b1cebef130ac1bbf1816502df59d,
            0x02f42f326f82b33cb9e4e7cfb332889eec95c2813f7968b3a50d838b3cbfa676
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x20c176738979e0d1ea9541bf26e6209d3091b618ae94f3c72e13e954a1614f60,
            0x2a7019c81009c00a7412b6a303b2eb118a362a558837e9ecdb912589bc11ff83
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x10a92b3fa2b8280030c9de5cbcab4da3cf9b5b3f63f3ad60284ecded63cc54ea,
            0x1bde2a83db435b8c74e4239b4f8416da88008331a758d8c68a9104f2dfc3e237
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x08e2e513d1e548a627e2d4f74d28dea916d8598415b70543bb3e92429f0111cb,
            0x2fb46898f77e32d7fd646fe31b60320423aa4698501e329e206b6acfcfb01337
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x145b88d324270872b13784fbb7ccdee6e5593d2d5cbc81f4aaa9b4268cfc5094,
            0x197d826aaf2a9853ca98ec9c0e55376eec1a6a0f5dbbbe02afeb1b567d8eafa0
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
        vk.domain_size = 524288;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0cf1526aaafac6bacbb67d11a4077806b123f767e4b0883d14cc0193568fc082);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x114dd473f77a15b602201577dd4b64a32a783cb32fbc02911e512df6a219695d,
            0x04c68f82a5dd7d0cc90318bdff493b3d552d148ad859c373ffe55275e043c43b
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x245e8c882af503cb5421f5135b4295a920ccf68b42ae7fb967f044f54e2aaa29,
            0x071322ee387a9ce49fe7ef2edb6e9237203dee49ec47483af85e356b79fb06fd
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x0187754ab593b07a420b3b4d215c20ed49acf90fc4c97e4b06e8f5bc0a2eb3f4,
            0x0170f9286ce950286a16ea25136c163c0b32019f31b89c256a612d40b863d0b6
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x0defecfae1d2b9ec9b2ee4d4798c625fa50f6a4ddb7747a7293df0c17fcb90c2,
            0x0f91d08fceebf85fb80f12cda78cefa1ee9dbf5cfe7c4f0704b3c6620fa50c55
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x2f7fef3b3fb64af6640f93803a18b3e5ce4e0e60aecd4f924c833fa6fa6da961,
            0x03908fc737113ac7f3529fe3b36efca200c66d1d85d2fc081973214c586de732
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x14ce3c0e9b78fc331327249e707f58fa4bb0ed746bdc9c2262ad0cf905609627,
            0x09e64fdac452b424e98fc4a92f7222693d0d84ab48aadd9c46151dbe5f1a34a9
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1d10bfd923c17d9623ec02db00099355b373021432ae1edef69b0f5f461f78d6,
            0x24e370a93f65f42888781d0158bb6ef9136c8bbd047d7993b8276bc8df8b640a
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x1fd1755ed4d06d91d50db4771d332cfa2bc2ca0e10ac8b77e0d6b73b993e788e,
            0x0bdbf3b7f0d3cffdcf818f1fba18b90914eda59b454bd1858c6c0916b817f883
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x1f3b8d12ffa2ceb2bb42d232ad2cf11bce3183472b622e11cc841d26f42ad507,
            0x0ce815e32b3bd14311cde210cda1bd351617d539ed3e9d96a8605f364f3a29b0
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x123afa8c1cec1956d7330db062498a2a3e3a9862926c02e1228d9cfb63d3c301,
            0x0f5af15ff0a3e35486c541f72956b53ff6d0740384ef6463c866146c1bd2afc8
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x01069e38ea6396af1623921101d3d3d14ee46942fb23bf1d110efb994c3ee573,
            0x232a8ce7151e69601a7867f9dcac8e2de4dd8352d119c90bbb0fb84720c02513
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