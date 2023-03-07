// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant OneWord = 0x20;
uint256 constant OneWordShift = 0x5;
uint256 constant ThirtyOneBytes = 0x1f;
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x25f1d312acdce9bb5f11c5585e941709b8456695fe5aacf9998bd3acadfd7fec
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xb7870d22600c57d01e7ff46f87ea8741898e43ce73f7d5bfb269c715ea8d4242
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0xe9ccc656222762d6d2e94ef74311f23818493f907cde851440e6d8773f56c5fe
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0x14300c4bb2d1850e661a7bb2347e8ac0fa0736fa434a6d0ae1017cb485ce1a7c
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0xd2a9fdbc6e34ad83660cd4ad49310a663134bbdaea7c34c7c6a95cf9aa8618b1
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x4c2c782f8c9daf12d0ec87e76fc496ffeed835292ca7ff04ac92375bbc0f4cc7
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xab5bd2a739337f6f3d8743b51df07f176805bae22da4b25be5d8cdd688498382
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x96596fb6c680230945bae686c1776a9920c438436a98dba61ca767f370b6ef0c
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0x40d250b9c55bcc275a49429cae143a873752d755dfa1072e47e10d5252fb8d3b
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xeaf49b43e05b65ffed9bd664ee39555b22fa8ba157aa058f19fc7fee92d386f4
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x9d5d1c872408322fe8c431a1b66583d09e5dd77e0ac5f99b55131b3fe8363ffb
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xdb50e721ad63671fc79a925f372d22d69adfe998243b341129c4ef29a20c7a74
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0x908c5a945faf8d6b1d5aba44fc097fb8c22cca14f60bf75bf680224813809637
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x7968127d641eabf208fbdc9d69f10fed718855c94a809679d41b7bcf18104b74
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0x814b44e912b2ccd234edcf03da0b9d37c459baf9d512034ed96bc93032c37bab
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x3a8ceb52e9851a307cf6bd49c73a2ec0d37712e6c4d68c4dcf84df0ad574f59a
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xdd2197b5843051f931afa0a534e25a1d824e11ccb5e100c716e9e40406c68b3a
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0x84b50d02c0d7ec2a815ec27a71290ad861c7cd3addd94f5f7c0736df33fe1827
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0xdaa31608975cb535532462ce63bbb075b6d81235cd756da2117e745baed067c1
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5089f7eef268ce27189a0f19e64dd8210ecadff4be5176a5bd4fd1f176f483a1
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x907e1899005168c54e8279a0e7fc8f890b1de622a79e1ea1447bde837732da56
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x73ea6321c43a7d88f2d0f797219c7dd3405b1208e89c6d00c6df5c2cc833aa1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0xb2036d7869c41d1588416aba4ce6e52b45a330fd934c05995b14653db5db9293
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x99e8d8ff7ddc6198258cce0fe5930c7fe7799405517eca81dbf14c1707c163ad
);