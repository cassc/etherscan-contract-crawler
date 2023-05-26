// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ChubbiAuction.sol";

/**
 * @title ChubbiAuction
 * ChubbiFren - The main contract,
 */
contract ChubbiFren is ChubbiAuction {
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ChubbiAuction(_name, _symbol, _proxyRegistryAddress, 8888) {
        setBaseTokenURI("https://www.chubbiverse.com/api/meta/1/");

        reservations[0x0eC5c1691219ffDfC50B6d4E3Bfb1B60b7eD8D5E] = 10;
        reservations[0x7788238091052072d5969Ac7452E46e94B23f7A3] = 5;
        reservations[0x593aB4f8412575d4B2EA36d373C04956A8Fbd3cD] = 5;
        reservations[0xFA6e1eFeD2FcE1337c6b2c0C0E7bFAa3927E6F23] = 5;
        reservations[0xCAe400e06B6D7d1632538C730223e9c06eE69f12] = 5;
        reservations[0x14929281cb3dC7F7E47C95a977C05ed4B85489d0] = 50;
        reservations[0x1Ce99932fD278E00911814dC4bd403e1293d8ED2] = 5;
        reservations[0x387Af9Df1a190CfAF420a0470A55f5cE22C5D356] = 5;
        reservations[0xc55ba66cab0298B3A67e1D0bf6A1613907941B09] = 10;
        reservations[0xea7cEB44004Ce65DEaD925e6Ae12fEdc30c88267] = 10;
        reservations[0x91609451B6a5775608787f3Da9501104935D3b25] = 15;
        reservations[0x60EA59C40efc5b297d3b019FA26c217761d0c266] = 5;
        reservations[0x926d2562Cd25E2a8988449F61271c19fF65d2C04] = 10;
        reservations[0x90E1F595Abc8D731cf82031c974aDD334B84b29E] = 20;
        reservations[0x7F7b32c998083D66De56602D75bC820b768C721B] = 5;
        reservations[0xd8Bca4f14B89d7BE3a5fd5AD97AAA6775D11FC46] = 5;
        reservations[0xA98220f6dC5DFcA27ff19605a0a6D3E1dDE4CFE8] = 5;
        reservations[0xEF30fA2138A725523451688279b11216B0505E98] = 15;
        reservations[0x5D89737E854c860d25E106C498c6DCA0B516eD7a] = 5;
        reservations[0xEC080DbeE8F60c8E6d7c3F52e10832718d2b8D5A] = 5;
        reservations[0x3cf0aCd510F51506D10f28ABb4822238C405Ac61] = 40; // 10 from snapsot, 30 from team
        reservations[0xe86dad56eE5C8F344cCaF348158C6258A965C8aA] = 5;
        reservations[0xF13a69F85075972AbB8435c8bBa1f24D91EFB986] = 10;
        reservations[0x277e1546A1Be3BC1737d0EAb43E6c1c86c0f4207] = 10;
        reservations[0x0bA516f6142C1cC8B6A6443bEf748e244FeaC99E] = 5;
        reservations[0x6Ec30Fd91A504Aad948839B985C7263888B2Ad68] = 15;
        reservations[0x64e714344780B12384597F5bF9aE35F9ADf98863] = 5;
        reservations[0x26A49F3730e2984E9188E220fC3fa4B6A605EA21] = 10;
        reservations[0x77C979931AD12d2B55e5E997a440f43660A21ffa] = 10;
        reservations[0x59b836B2f15C89E1007e011af47607e01C365F71] = 25;
        reservations[0xFe5573C66273313034F7fF6050c54b5402553716] = 5;
        reservations[0x2a92280f7572Ee27b50eb81D8Bd644a5aCcf16F6] = 5;
        reservations[0x3329ca36d37b0DE4228795eFaA490a7763202172] = 5;
        reservations[0xbBDFDE2786afD8858807bDf617C10F9ad521fAb1] = 5;
        reservations[0x5BA17875Ea5F3BAA8E9A06aaf973Ba7c21994C40] = 10;
        reservations[0xd918252c46bf5D399Ce827151B422810388c79ec] = 5;
        reservations[0xb09548d2ea367b0b0dF0FE1AC0C079F7D5354a50] = 5;
        reservations[0xde923Df474661dDF3727C913EbFEe3df0b37BEB8] = 5;
        reservations[0x6A3B82f775D9eFE19518b1F68Fe86FAf0eAf2a90] = 10;
        reservations[0x80207B6ef45dcD6E2d2f5Bf692320C8b46b6bf09] = 5;
        reservations[0x1a330bF19B7865935cd675fD827c6cbC742fFE5a] = 35; // 30 from snapshot, 5 from team
        reservations[0x044DeeAe38e81be36Fe1F0245F4cb14Be0A19Cb0] = 5;
        reservations[0x06644f3054d2579e8b7425436bB6ab13e91999EB] = 10;
        reservations[0x606a90DF26ED6b2680aF64fc63E2887a726703d4] = 10;
        reservations[0xe1b5F0862dc5A2A4e6069C3e31232a34d21Ef2Fb] = 5;
        reservations[0x6e51817Aa02674FE6bA1a790E23AA720c4843804] = 5;
        reservations[0xf305F90B19CF66fC2D038f92a26440B66cF858F6] = 5;
        reservations[0x5D55a50e4A1d7ce19B108aD4a44C60D02fAd9637] = 5;
        reservations[0xE7f2A881a30a1b9D16BebdbE42B226253B4Ca489] = 5;
        reservations[0x45A7A6adA84207c11a29305b18E4DBb16Bd1dd7E] = 5;
        reservations[0x75c8E2dd57927eB0373E8e201ebF582406aDcf45] = 15;
        reservations[0x923de254c1E93D710CCa6115b63712EDc76CE816] = 25;
        reservations[0x9cBd60A51b54aB626cDE7861Afe43D2CD82dA327] = 10; // 5 from snapshot, 5 from team
        reservations[0x1ff13480f8CD08e778755987a648b9D80d78c966] = 5;
        reservations[0xBe27D73FCf696ECf9Febff0C90F7Ac9e05B0E41A] = 25;
        reservations[0x94abB1573c83f9a53cAD661514Ed7F0419EC594A] = 5;
        reservations[0xb71B13b85D2c094B0FDeC64ab891b5BF5f110a8e] = 5;
        reservations[0x25CD302E37a69D70a6Ef645dAea5A7de38c66E2a] = 10;
        reservations[0x88cc77f53A077775bcD8067822Ed02Bd12AC4131] = 10;
        reservations[0x182Eba9213c3A45aEc4a400350EacD2E683f5981] = 5;
        reservations[0x3082a2dd0028231423a5fB470407a89c024B308d] = 5;
        reservations[0x642452Bd55591CD954B2987c70e7f2ccC71dE313] = 5;
        reservations[0xF404Aa7d1eAB3fABA127E57A1E4aFA4D6c31abF8] = 10;
        reservations[0x6f4d8C05aC656cbb2Edc9aDC14743C123A0EB65b] = 10; // 5 from snapshot, 5 from team
        reservations[0x108B9595D1fA09A9a228e011D7768c55D8d989AD] = 5;
        reservations[0x1d69d3CDEbB5c3E2B8b73cC4D49Aa145ecb7950F] = 5;
        reservations[0x3677C1621D49611811BBca58d9b2ac753bE5b3b6] = 5;
        reservations[0x868b2BC9416bBd2E110ad99e4F55C1D51212271a] = 5;
        reservations[0x7FdCA0A469Ea8b50b92322aFc0215b67D56A5e9A] = 5;
        reservations[0x52e0f7339C1BEd710DBD4D84E78F791eBe2df6b9] = 10;
        reservations[0x3df6c1D54ad103233B3c74a12042f67239d69f70] = 45; // 15 from snapshot, 30 from team
        reservations[0xA4c8d9e4Ec5f2831701A81389465498B83f9457d] = 5;
        reservations[0x8DD6629B2272b4fb384c13E982f8e08Bc8EE001E] = 5;
        reservations[0x758f9112899834dB1d5dC1860c06900c3d3bd75a] = 10;
        reservations[0xDCbf721551A937768537458C61005F1CBECb043c] = 5;
        reservations[0x5Cb58a3fA9B02ae11f443b3Adc231172356EcCd7] = 5;
        reservations[0x774237c2a8Fd84c0D4D2C97cB03D3B6C87cB0431] = 5;
        reservations[0x60d727CBfd8Df0af32eFa764ebEc917c59FcEd4F] = 15;
        reservations[0xa11e95CA2bE0793C5AD0C4FF20bd6dab0992C6a2] = 5;
        reservations[0x0bd43F463074e731718f970C35b3fa7c8184c642] = 5;
        reservations[0x68EAbf8B000AbfF6d55Cfa918D2fe0638d4F98af] = 5;
        reservations[0xc6E999FCCF8bc1CD8BEfcfA10Cf2cC1f3b2612e2] = 5;
        reservations[0x3c2B4bDCD2F742C55186fc599Cb733a127E2b8ab] = 5;
        reservations[0x3Ba77787266aE8225805e4b4750fd4E9f800da33] = 20;
        reservations[0xCfCDd074DC974af94fA2b9d56b6A213c0D96EaF9] = 5;
        reservations[0xB135c7E7604A8D4723548d9a5F67D98c110E78A8] = 5;
        reservations[0xBE1e5A07c3Af9b648b2DeC7F193bc0835646725E] = 5;
        reservations[0xc7bc4Aa98eCe00E4F8feC8Fe7B0591F80aBbc855] = 5;
        reservations[0x42d3b1e30f39191F6dA2701E31cfc82574ea14D5] = 5;
        reservations[0x7f55Bd494bed4b4eED2064ECCC1aF75e9d76aD4b] = 5;
        reservations[0x5765bdEFb7EAD33f4Eb7935C5d5eb130f4299568] = 5;
        reservations[0x0c5A9cd5c97F716e2E9F3699Bd2905BCA0059867] = 10;
        reservations[0x5338035c008EA8c4b850052bc8Dad6A33dc2206c] = 15;
        reservations[0x518aE9dC06AF3A4d2DD1B75E2367C0D23257B320] = 8; // 5 from snapshot, 3 from team
        reservations[0xd102C5AD3c42bdFBB1762DB4d0e3707ffB7e1486] = 10;
        reservations[0x8067ea0006949CFF984083A83A56a8B0DEC2eab2] = 5;
        reservations[0x0f1025f754b3eb32ab3105127b563084BFa03A6F] = 10;
        reservations[0xbD912A2B4Aeb0BC7D3827d11D621F79D66eaF633] = 5;
        reservations[0x2d45D1259B4f136F5050CB9dbb3c02253f74c647] = 5;
        reservations[0xa2BFF706Dd94C8E8284314aAf243D8D99cf723DA] = 5;
        reservations[0x1D551AcE62be491Fc49E9A6B3d737e51e2c59E8c] = 5;
        reservations[0x5bEcE23dDf9BDe3e1F735b1b09b5958173D45014] = 10;
        reservations[0x243AE63fed8680067e16F63546d312AAC1f5d716] = 5;
        reservations[0x7CcaCab19ee2B7EC643Ef2d436c235A5c1E76Fa9] = 5;
        reservations[0xDDCCC8CBF91f31FF7639b4E458cF518219eFC7bd] = 5;
        reservations[0xFac137e6753B1C7b210cd1167F221B61D6Eb4638] = 10;
        reservations[0x45e2Aa1483A1C02f1E7D07FF904bb1dEd9350aB7] = 5;
        reservations[0x3b10f088D7a83E92E91D4A84FE2c656AF92a801D] = 5;
        reservations[0xA6D3a33a1C66083859765b9D6E407D095a908193] = 10;
        reservations[0xaf9E021FC76c0aFBf4a520152C5Cf792561503B5] = 5;
        reservations[0xd1B18dD9fCfd0cfaED13D0a107B98B47d3f67eF6] = 5;
        reservations[0x6514304C439565BC6bF5e60dC69dC355a034E6C3] = 5;
        reservations[0xA0Acc2aE14c814d97c766aE2582150c415cef1e6] = 5;
        reservations[0xA309e257Db5C325e4B83510fCc950449447E6BdA] = 5;
        reservations[0xa48AE1c287fa6DE4581Ca3E00f0a481a1AE80778] = 5;
        reservations[0xBaEa3Cf94aBd0D6E0F029ef5B0E54E9424A72985] = 10;
        reservations[0x716eb921F3B346d2C5749B5380dC740d359055D7] = 10;
        reservations[0x4c6FaaAf155AA05A0AF39Dd51ee9E47042d19C64] = 10;
        reservations[0x50F620A98f0514F5cA9ff7B44125F632EE7aC84a] = 5;
        reservations[0x81a4A0655A157B731D06fE0b597F67B5bDDdedf3] = 5;
        reservations[0xfCAD3475520fb54Fc95305A6549A79170DA8B7C0] = 5;
        reservations[0xD5b1BF6c5BA8416D699e016BB99646cA5DbAb8d7] = 5;
        reservations[0x7c7582643E67b443b0c3f82D0513ba3D25c09F92] = 5;
        reservations[0xcDae1Bab521E6aD0756f41166E1Ac68D4b5Ba55a] = 20;
        reservations[0x7D551B4Aa5938d18be5C5e9FdE7fECE9566611ba] = 10;
        reservations[0x6a8b990801daDe9077acB0eA8948D023C72D7060] = 5;
        reservations[0x0F0eAE91990140C560D4156DB4f00c854Dc8F09E] = 10;
        reservations[0x409abF69Bcf740a1cEe04f3f330610fd985BE0c3] = 5;
        reservations[0xb20f6f5F6D624571C000d75bb8081b488f1D9c9a] = 5;
        reservations[0xb51fBfdAc76132eB819c91b0Bfc5A72913B88329] = 5;
        reservations[0x392FA612154CCaDd6b3B34048D4De84A4E2e0d8f] = 5;
        reservations[0xab0e3fE8670583591810689b0a490D8226f0D79B] = 10;
        reservations[0x078ad2Aa3B4527e4996D087906B2a3DA51BbA122] = 10;
        reservations[0x34f6e236880D962726Fdb5996f6a0Bce42ea6Ca5] = 5;
        reservations[0x9874346057faA8C5638694e1c1959f1d4bb48149] = 5;
        reservations[0x000433708645EaaD9f65687CDbe4033d92f6A6d2] = 5;
        reservations[0xE85b14f37ed20f775BEeBf90e657d8A050640623] = 5;
        reservations[0x8104cd18e37f2634257a97338C32EC7BFbfb72bD] = 5;
        reservations[0x97C6f53B75D8243a7CBC1c3bc491c993842db3b3] = 5;
        reservations[0x750A31fA07184CAf87b6Cce251d2F0D7928BADde] = 5;
        reservations[0xfa50E8AE8E380fAd984850F9f2BA7Eb424502d6d] = 5;
        reservations[0x9631b82269c02a7616d990C0bf9Ba1dC1Bed1a73] = 5;
        reservations[0xD8CbcFFe51B0364C50d6a0Ac947A61e3118d10D6] = 5;
        reservations[0x1048fA01899a43821c7aE77Fe96aF45F19A2646B] = 5;
        reservations[0x9Cb737840CF5538942d1dA5576B50A7005382F13] = 5;
        reservations[0x96fc154e9f97541e0b9e76fdd162a8Ecd2F2eD7B] = 5;
        reservations[0xE54c447e47DC308Ff12C478E725C150e1586FfB0] = 10; // 5 from snapshot, 5 from team
        reservations[0x5101F854F670812f2eBca8f6669AfF324F192218] = 5;
        reservations[0xc2363b54f8842a4Da3Cd19D6F3b6F9988c72800D] = 5;
        reservations[0x64c420ABc818E9FCa4a94FF1aD78c5B7E237e44B] = 5;
        reservations[0x2f6e116E6E4BfF7c00402d6B321192BCc4d797FA] = 5;
        reservations[0x95B0D143ac845877DFdb7cE07Fc1549D88783d68] = 5;
        reservations[0x19Eb7FfDcD670Ca917110Bd032463120a5E58C8E] = 5;
        reservations[0x83E84CC194E595B43dCEDfBFfC3e0358366307f1] = 5;
        reservations[0x3916bcCF534a200467D546414Bf93A2BF47DD7CD] = 5;
        reservations[0xa920268fF7Ac82a63fF5070d32401900Ee5626C6] = 5;
        reservations[0xE62c522b0EeA657414faD0a1893223f54CCD5190] = 5;
        reservations[0xAE68B4Ec732c534F5d3D0B990af2E3FB7E25FbE3] = 5;
        reservations[0x8945911b7bd08a9fE75EdCFb94f1a8A4A741b443] = 10;
        reservations[0x88451FDbdb2d002008136D3626aafdA5e85d4dae] = 5;
        reservations[0x52713267FE99E268A3Ce0B1A84C3d3dbC7C47F21] = 5;
        reservations[0x6D938CbE86b4763691f702577d4046F656aCb3c8] = 5;
        reservations[0x6051BE619c976Bf24ff6053693f696C691cfCd24] = 5;
        reservations[0x98367D7B9bC02A5207859Ac11F2a9E504cA729E4] = 5;
        reservations[0xb7608C42C00c87Be4Db7A6D2AF128fd6f0FD74c8] = 5;
        reservations[0x99999990D598B918799f38163204Bbc30611B6b6] = 5;
        reservations[0x905f48CbAAAF881Dbee913cE040c3b26d3bbc6D9] = 5;
        reservations[0x020B899981FA12ad33d6c455d77fe8f53A121464] = 5;
        reservations[0x5c0E408F03709B89b7F5Fa91E4172425F57C75d2] = 5;
        reservations[0x51EDb6E986c31D13838f165737Fe3FbA9F689F38] = 300;
        reservations[0xd6b5E55dd4BEBe68D556EaB12C9916bD4a420406] = 30;
        reservations[0xd148C895462160a260318A7046f78a29F97F8235] = 30;
        reservations[0x7156403C0A30d458Bb4b4796e4412E6A22624b30] = 10;
        reservations[0x13E47EBD58dA3a23ed19d91067168896e6c683F1] = 10;
        reservations[0xC0f1C68f16363974FCaCE9f25DC76a18B5077a9A] = 5;
        reservations[0x749C34697bA3ECbbD80C0BD831F513DFD9E2D5a4] = 2;
        reservations[0xF61AC83177e310e82374f90D5dd00f62FDeA2FBD] = 1;
        reservations[0x1fC18f965F60625f895434FC536Fa50c705F860c] = 1;
        reservations[0x9191588a8F3fa3ffF4f7e4D1ca51034d664850FE] = 1;
    }
}