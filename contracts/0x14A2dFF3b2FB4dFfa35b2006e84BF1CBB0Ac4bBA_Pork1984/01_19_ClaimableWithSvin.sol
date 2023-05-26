pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract ClaimableWithSvin is Ownable {
    mapping(address => uint) _svinBalances;

    function initSvinBalances() internal {
        _svinBalances[0x034a45B00000AF335F81A38D1a36cB555D516A92] = 1;
        _svinBalances[0x047cfa189b23203c3d2d16550f4683c50da78392] = 1;
        _svinBalances[0x05AE0683d8B39D13950c053E70538f5810737bC5] = 1;
        _svinBalances[0x05B0319c6f3AA8A895cA30B5eEb29657C1285983] = 1;
        _svinBalances[0x0605ABe3d7F1268b816c1EDfbF96e3e1828b9F22] = 1;
        _svinBalances[0x06899B851e0Cc9B1e9348C0E985E6c5454bBd889] = 3;
        _svinBalances[0x07b24ba3e50Be7b4411138823176f4382163D59a] = 1;
        _svinBalances[0x080E285cBe0B28b06B2F803C59D0CBE541201ADE] = 4;
        _svinBalances[0x094cb885eb92607aF232825c5a9B64318709749F] = 1;
        _svinBalances[0x0C93929360FF8b46a46c2dE1C8eDeA9541B78eB3] = 1;
        _svinBalances[0x0caC9C3D7196f5BbD76FaDcd771fB69b772c0F9d] = 1;
        _svinBalances[0x0E5a1d84eD69067C078596bc6A17452425B005F1] = 1;
        _svinBalances[0x0e8A9d56cEd084A70926A7B5c1c48EAcc441e138] = 1;
        _svinBalances[0x12269196C57e800824762E5ed667b5b8BA5e364E] = 3;
        _svinBalances[0x122b0eaa0a4252CEfcB877f0BF608bAe2cF7CA9e] = 1;
        _svinBalances[0x12417A1213D1863dCA5BA87eE6Fb4da479772e3f] = 11;
        _svinBalances[0x12CCdf3513f8f09f4C0E6Ad7821988a7A8Ac0bE1] = 1;
        _svinBalances[0x12Edc1D51bF2dD34C3703B7521F871E7e9A37C67] = 2;
        _svinBalances[0x17E72A77A84C2705E77C686a3f756ce9d3637C58] = 1;
        _svinBalances[0x1813183E1A2a5a565d09b0F16a868A4e1b7610c0] = 1;
        _svinBalances[0x1a7B50e158a478DcA8A7EE1f5b1c86154692Aba5] = 1;
        _svinBalances[0x1ac59132270545cD927fB7cE80E7C00f278C2673] = 1;
        _svinBalances[0x1b21A4287CBfA8F81753de2A17028Bf2fA231034] = 2;
        _svinBalances[0x1b640c003d3F8Bba7aD69C9121cCbC94203Eb3c4] = 1;
        _svinBalances[0x1b8565F9336Ea2d9145005303520957E254171fe] = 2;
        _svinBalances[0x1BB2f62f9958eC1F875E4B0B42fD775eE3FD955E] = 1;
        _svinBalances[0x1c1382c9aDc5CE1f93c55914F2FBCaD07747aA84] = 2;
        _svinBalances[0x1c2E4b068f69A46d8Cf7995db90D38428163B979] = 2;
        _svinBalances[0x1D5C30676cA03adAe00257568B830C8D424A1e53] = 2;
        _svinBalances[0x1D7B087234D89510bE132F8835C04d696Be4F43a] = 1;
        _svinBalances[0x1dAC5Bf20722e462B3c388d4D1153836926C9b5C] = 6;
        _svinBalances[0x1FC4B87ce7C31507ec1d0cCAE20e674B13840a6C] = 1;
        _svinBalances[0x203019c38E4890E81A5d8C9513b97aEc0fC2FC66] = 1;
        _svinBalances[0x20cca2DfCCa8ed99E559c9f3FB08cC406b3fC2df] = 1;
        _svinBalances[0x21B33d5bfF0B07462bCb3E2613cbeAeC909588d0] = 1;
        _svinBalances[0x22085DdF122BbE0C74bf8822a8B0034B34e7B00c] = 1;
        _svinBalances[0x23a35DCc4dbEeA3CbAC3Ae1db37Cb87c625b8F54] = 1;
        _svinBalances[0x24D8E4a8d59f00C370ca6f9344Ed8Ba47f74D85f] = 5;
        _svinBalances[0x25c84928c5CF3971a4CeAdf26F1808a3E11CF374] = 1;
        _svinBalances[0x26CfD6f7Ae12c677aff5e0eDe78D85054A9351B3] = 4;
        _svinBalances[0x2734a7F407d296311A0FD83e04c05e0CC76b4A34] = 1;
        _svinBalances[0x27f8F53eb60877607A589051B181ec3Df2118d11] = 1;
        _svinBalances[0x28E174a5797C60D34b338F5Fc3155Cb4571B19A9] = 1;
        _svinBalances[0x28E3E03240c4B7101c474BDBCAB13c6Bc42Cc7eb] = 1;
        _svinBalances[0x291121dA7faEEDd25CEfc0E289B359dE52b8050c] = 4;
        _svinBalances[0x2A41282434f89f5bbF272B1091A7A0ceFD22Ccd8] = 1;
        _svinBalances[0x2D036b57ec3713704Db5fBdF0eC3F5991cB79A08] = 4;
        _svinBalances[0x2dF23b2807E421085efF3035191EAfa5a5E17545] = 1;
        _svinBalances[0x2F60d06Fa6795365B7b42B27Fa23e3e8c8b82f66] = 1;
        _svinBalances[0x30b4a5477314e3FbD0C22D6Afcd71EeCF4d9D22F] = 1;
        _svinBalances[0x338F8AdbaEfe63cb4526F693c586c26D77A6dCD9] = 1;
        _svinBalances[0x33F0F57DCd106DF64FA2B8991cd6bDAe8f53dcf5] = 2;
        _svinBalances[0x366c0ae1eDBE7c648Bb63fC343910B4e54eE5F87] = 1;
        _svinBalances[0x38bf30d3F1528BBD2BB8A242E9a0F4405affb8d0] = 1;
        _svinBalances[0x3c2262255793f2b4629F7b9A2D57cE78f7842A8d] = 2;
        _svinBalances[0x3C9A28263B5Becf6b0773BF9736b9d0D5F08Cb06] = 2;
        _svinBalances[0x3D7f2165d3d54eAF9F6af52fd8D91669D4E02ebC] = 1;
        _svinBalances[0x3E1ffCda317FE588F5c217fBA8C22F82B368A249] = 2;
        _svinBalances[0x3f3E2f43f0aC69f30ec38d3E4FEC304bdF330E7A] = 1;
        _svinBalances[0x446a6560f8073919D8402c98dB55dB342A20300B] = 4;
        _svinBalances[0x4518344525d32415F3ebdA186bDB2C375D9443d6] = 2;
        _svinBalances[0x454C66152A110Eb759b2fC09Ddc52cd74Dca3f54] = 3;
        _svinBalances[0x484749B9d349B3053DfE23BAD67137821D128433] = 1;
        _svinBalances[0x48756f98f4b56Da7077d1cE5a71056e9b9b3F0B1] = 1;
        _svinBalances[0x487Ee33B7243A51e7091103dC079C1f5eED7518d] = 1;
        _svinBalances[0x48cb2253e3a83bB312d9AE7797A3FcBE835b7C26] = 2;
        _svinBalances[0x4a93A25509947d0744eFc310ae23C1a15bE7c19b] = 1;
        _svinBalances[0x4D4f9ede676f634DBd36755C4eE5FDB49377df88] = 3;
        _svinBalances[0x4D633603A302C771e600590388606632c9447d76] = 1;
        _svinBalances[0x4d88DBF593A0dAd711AEc4c02A7CEE79eF6e725C] = 1;
        _svinBalances[0x4db09171350Be4f317a67223825abeCC65482E32] = 2;
        _svinBalances[0x4DB0c7466F177ec218d8735Ee4729634Ae434BAa] = 1;
        _svinBalances[0x4F234aE48179a51E02b0566E885fcc8a1487dB02] = 1;
        _svinBalances[0x4F5eC5bd224218ca16b4D9E66858c149a4b6465c] = 7;
        _svinBalances[0x544Ea5eFaC91017A96072E153C279050Fd9bf861] = 2;
        _svinBalances[0x550e970E31A45b06dF01a00b1C89A478D4d5e00A] = 7;
        _svinBalances[0x55594059b44f73c0038699B42132B639262F186B] = 2;
        _svinBalances[0x558c43d33919775f1eb4e26aa488DaB361f95f74] = 2;
        _svinBalances[0x55A9C5180DCAFC98D99d3f3E4B248E9156B12Ac1] = 2;
        _svinBalances[0x573bF0D4D215C2f6cD58dE04c38B81E855F1D7a8] = 2;
        _svinBalances[0x58D49377C74Fe5aA1C098D9ed4161248b73faa30] = 1;
        _svinBalances[0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95] = 1;
        _svinBalances[0x5A4a8f46972ad7eBb1A366680C94AD24e9650c05] = 1;
        _svinBalances[0x5b9b338646317E8BD7E3f2FcB45d793f3363AD1B] = 1;
        _svinBalances[0x5D18C78f374286D1FA6B1880545BFAD714c29273] = 2;
        _svinBalances[0x5f8b9B4541Ecef965424f1dB923806aAD626Add2] = 1;
        _svinBalances[0x5FD2C02689d138547B7b1b9E7d9A309d5A03edCd] = 4;
        _svinBalances[0x61ad944C6520116Fff7d537a789d28391A7A6425] = 1;
        _svinBalances[0x638b2Aa3DFc973c9dc727060cB54D7E39541B7F5] = 1;
        _svinBalances[0x65b89f14C1AADd7E24dD0bd1cA080ce964E1237E] = 4;
        _svinBalances[0x678B8f0026fb7893b249C83a2e89f711b0DDb385] = 1;
        _svinBalances[0x67C6CD886f6F29aa6b124698d84d3E472177BA29] = 2;
        _svinBalances[0x68C62D8db8dB114dD39A1bfac9A43D146b86fC06] = 1;
        _svinBalances[0x69C38C760634C23F3a3D9bE441ecCbD2e50e5F73] = 1;
        _svinBalances[0x6b611D278233CB7ca76FD5C08579c3337C01e577] = 2;
        _svinBalances[0x711bdaFEA11Ca315e29a331d427d9f375b185766] = 1;
        _svinBalances[0x71649d768128DfC64734CB58713e972e045421Dc] = 2;
        _svinBalances[0x719f973d8Fe35F35C56d634B4D70E2791Dc960C4] = 1;
        _svinBalances[0x73dEAEB8aA241b6fcdB992060Ae43193CcCBf638] = 2;
        _svinBalances[0x750364CcecC0250C2160b5e1Cc9F9AFdAA99138b] = 1;
        _svinBalances[0x7675291453DAf025cEF152bef7296D4Ef9d72514] = 3;
        _svinBalances[0x767aE578b41BE33A9acBeF5e70dfaBFC4DACEA5e] = 1;
        _svinBalances[0x7833A725c3d5A2B583CbBeaAF3c50a01E2d81d91] = 1;
        _svinBalances[0x78b95D0e7A72A5C70B3c1d544F2979b47dE3541c] = 2;
        _svinBalances[0x7a277Cf6E2F3704425195caAe4148848c29Ff815] = 1;
        _svinBalances[0x7a6DAAE2255491c56D82c44e522cBaC4b601985F] = 1;
        _svinBalances[0x7D112B3216455499f848ad9371df0667a0d87Eb6] = 4;
        _svinBalances[0x7dAa8740FE15F9A0334Ff2d6210eF65BD61ee8Bf] = 1;
        _svinBalances[0x7DdF9BEB649c25F74C5EAc6CA8B4aa2Dda3b028D] = 1;
        _svinBalances[0x7e00f4110Fb7D02A91632895FB93cd09af3209c6] = 7;
        _svinBalances[0x7f8C2e2AF79E43f957064356c641b07316BE7a2c] = 1;
        _svinBalances[0x7fb6F52996ba02884Fd4Cd136bB2af3D8909c56C] = 1;
        _svinBalances[0x82B3b4BE8033dFB277c70AE9b4e1EFB0ae08cB93] = 1;
        _svinBalances[0x85345e4095dfd7d5252A69a9a7537AfdA09B1280] = 1;
        _svinBalances[0x869c9009A0d8279B63D83040a1aCC96a6Ad8Bf89] = 1;
        _svinBalances[0x886478D3cf9581B624CB35b5446693Fc8A58B787] = 1;
        _svinBalances[0x8DC2ce42b6b2b2255E9B094Dbe79f97774767458] = 5;
        _svinBalances[0x8e101059Bd832496fC443D47ca2B6D0767b288DF] = 1;
        _svinBalances[0x906c2F8e230B61dd183E0696265F8FED8A1a387b] = 1;
        _svinBalances[0x90c19feA1eF7BEBA9274217431F148094795B074] = 6;
        _svinBalances[0x90C40098d9146729506E5B4087F8765e10c13061] = 1;
        _svinBalances[0x913D0C60b9BeFC1b16f551465863fDD643Eb81b4] = 2;
        _svinBalances[0x99df8a2b8d02bADe773Fa7451A69E05e1d86a05D] = 1;
        _svinBalances[0x99ED7190511ac2B714fFbb9e4E1817f6851EF9f5] = 1;
        _svinBalances[0x9A428d7491ec6A669C7fE93E1E331fe881e9746f] = 1;
        _svinBalances[0x9b6faDedcbE50876eaB12F5109E4C370cb97089E] = 4;
        _svinBalances[0x9C0A9b7ffE633AD11963745f2b7c604F8a97194C] = 1;
        _svinBalances[0x9CA26730aa028D098C52C3974ab89eC81c74f56c] = 1;
        _svinBalances[0x9dff008EDA68184Fbc2dA18AB7d31f3BA1A77dB3] = 2;
        _svinBalances[0xa01dd79c6A09CD5d51278dba059114Bc2Cb5eBCe] = 4;
        _svinBalances[0xa1c384289A9cAFB44A4f792aCf2E7f9Ac5E5f3aD] = 1;
        _svinBalances[0xA49958fa14309F3720159c83cD92C5F38B1e3306] = 1;
        _svinBalances[0xa4edADe797b3C429E07527B46eB0a9F60a4D4B8E] = 1;
        _svinBalances[0xA53a742502A374B3916049067EadA96a8Da5c42C] = 1;
        _svinBalances[0xa85819617a048287Ae2f5bA42740D7d71C9e439C] = 1;
        _svinBalances[0xA8b09b62B0ADDB3c89195466Ee15Cc9e825d6877] = 1;
        _svinBalances[0xa9a94502637Fd1642DB5b4416a34b9cAf034D553] = 1;
        _svinBalances[0xaA4681293F717Ec3118892bC475D601ca793D840] = 1;
        _svinBalances[0xAB6cA2017548A170699890214bFd66583A0C1754] = 4;
        _svinBalances[0xABA24Dc8b54B4e5d8B609cacEe3D1dcA6530f36E] = 1;
        _svinBalances[0xacc013315c848293A57641486aEB707e302cBdb5] = 1;
        _svinBalances[0xadA13FC7089745118D55468d8b384f2697c33e14] = 1;
        _svinBalances[0xB00CD8e790eC45971A04695849a17a647eB74463] = 1;
        _svinBalances[0xb104371D5a2680fB0d47eA9A3aA2348392454186] = 30;
        _svinBalances[0xB381dF6c35235AbD138Df31E64B0d7a3104a4AeB] = 1;
        _svinBalances[0xB3ab08E50adaF5d17B4ED045E660a5094a83bc01] = 2;
        _svinBalances[0xb5A2b414B3c4E0fBd905095E6A8CfeA736def914] = 1;
        _svinBalances[0xb5d3947335A87a30fE11f51C99D0B4644716dA71] = 1;
        _svinBalances[0xB6DC34F69d7973eb7C26D173644685F78E3b9858] = 1;
        _svinBalances[0xB71fE696c3967E79fb5A36c7894230882923fD39] = 1;
        _svinBalances[0xb99426903d812A09b8DE7DF6708c70F97D3dD0aE] = 5;
        _svinBalances[0xbA726320a6D963b3a9E7E3685fb12AEA71Af3f6d] = 2;
        _svinBalances[0xBAA02edb7cb6dc2865bC2440de9caf6A9E31f23e] = 4;
        _svinBalances[0xbaaaBce9D8b6e0e7b26E107f33DdfC7Bd582E301] = 1;
        _svinBalances[0xbD6907023e8129C6219536C1Bf2e7FB9e0CEd8E1] = 2;
        _svinBalances[0xc071823c582c2ecdfE5306F20af4e5Bd3C51e25e] = 1;
        _svinBalances[0xC0d5445b157bDcCCa8A3FfE6761925Cf9fc97Df7] = 1;
        _svinBalances[0xc1fA63BD4189a9C49A30010B6a3aB11194A95842] = 1;
        _svinBalances[0xC26241D386dD0c1e711C7104fCf72b7C6e0ECc0b] = 1;
        _svinBalances[0xc3D3f90e2210bbE23690E32B80A81745EB4dB807] = 1;
        _svinBalances[0xC6A50A166Be98087078DaF764417fa4E2b405542] = 3;
        _svinBalances[0xc6Cc7f25Ba045B8c08Fb84aA1494b106Fb6824a5] = 4;
        _svinBalances[0xC792b1a1CD45631b7b9D213Cf108A16DE34Ee9c9] = 1;
        _svinBalances[0xc8F1a199EEb0ECCedfb0F401b828EE6Fb894aaa7] = 1;
        _svinBalances[0xCA50Cc37abaA58d19E3A23CCB086f17F8384cb3C] = 1;
        _svinBalances[0xCA6B710cbeF9ffE90D0Ab865b76D6e6bBa4Db5f9] = 2;
        _svinBalances[0xcAeF892f50DB75582139b5d5145284ad31CD4912] = 4;
        _svinBalances[0xD1216994Acc2e0201c04db6397882791973d8984] = 2;
        _svinBalances[0xD1BBdE3515d075CB2741CAA92ad0C03bad4d9D4A] = 2;
        _svinBalances[0xd36954DF517cFd9D533d4494B0E62B61c02Fc29a] = 1;
        _svinBalances[0xd4Db6d8Ef756141DE0D838808Ddb8fFCd847D7ff] = 2;
        _svinBalances[0xd559eb2bdF862d7a82d716050D56599F03Ef44E7] = 15;
        _svinBalances[0xd5a9C4a92dDE274e126f82b215Fccb511147Cd8e] = 3;
        _svinBalances[0xd5e8A9a3839ba67be8A5fFEACAD5Aa23Acce75bB] = 2;
        _svinBalances[0xd78F0E92C56C45Ff017B7116189eB5712518a7E9] = 2;
        _svinBalances[0xd815FEaeb858838690440F7298Eb0465b27a7Ff4] = 1;
        _svinBalances[0xD83C7bcED50Ba86f1C1FBf29aBba278E3659F72A] = 2;
        _svinBalances[0xDc62e941fDDBDdDFc666B133E24E0C1aFae11847] = 2;
        _svinBalances[0xdC8bBaCAc5142A91637c4ebbDF33946bFB48BC50] = 1;
        _svinBalances[0xdd8b6fB4c5fD3eF7a45B08aa64bDe01Ddc1b207E] = 4;
        _svinBalances[0xDeC51742Cd5B54eECC66b08d0A784488B29e2c89] = 5;
        _svinBalances[0xe288a00DF4b697606078876788e4D64633CD2e01] = 2;
        _svinBalances[0xe2B1081Dc27703F36b444665254b0BDa0eE9ed27] = 1;
        _svinBalances[0xE2bDaE527f99a68724B9D5C271438437FC2A4695] = 1;
        _svinBalances[0xE7c7652969aB78b74c7921041416A82632EA7b2d] = 6;
        _svinBalances[0xe7dAe42Dee2BB6C1ef3c65e68d3E605faBcA875d] = 1;
        _svinBalances[0xe8D6c9f9ad3E7db3545CF15DeF74A2072F30e1Cb] = 1;
        _svinBalances[0xe913a5FE3FAA5F0fa0D420C87337c7CB99A0C6e5] = 9;
        _svinBalances[0xEA2c15B73e07Bdd59cAec75c08f675Fd4cb04229] = 1;
        _svinBalances[0xea39c551834D07EE2EE87f1cEFF843c308e089AF] = 24;
        _svinBalances[0xeAAB59269bD1bA8522E8e5E0FE510F7aa4d47A09] = 1;
        _svinBalances[0xED1f2d7Bc291209131D992De059723f492EE40F5] = 3;
        _svinBalances[0xeEF44ca98EB0c7E412366C020c6bD3cFaff8b33E] = 2;
        _svinBalances[0xEfBb701e123526d087e17bC18F417465fA09876a] = 1;
        _svinBalances[0xf02Cd6f7b3d001b3f81E747e73A06Ad73CbD5E5b] = 10;
        _svinBalances[0xF14c883B4940e0F8c4257D72674f003D8B6Cdb58] = 1;
        _svinBalances[0xf25Ad24b791E37e83F4dadFE212e0e9Bb45a1f8b] = 4;
        _svinBalances[0xF29BA56dC71f2Eeaf12252D94bf0Ad8F7a56AC02] = 7;
        _svinBalances[0xf5493d28b94521fe392F640aA78df3C68531964e] = 1;
        _svinBalances[0xf7785f2e2815ab19143a5Bab3050EDfe0C2bB470] = 1;
        _svinBalances[0xf8B202dE4dBeaeBda8dEf3614e81FB1E8294DCC7] = 1;
        _svinBalances[0xf9570Eb74727A6e08562C3ef799876706d86A5E2] = 4;
        _svinBalances[0xf972D156658508d6096f7576840a70780074bf0c] = 1;
        _svinBalances[0xFa8E37Da2E4cBA1f7B6E8d637Dc39f8df6D18526] = 1;
        _svinBalances[0xfC9dD877930e9799BeB663523BD31EefE3C99597] = 2;
        _svinBalances[0xFCBBdF31E9840807582f1F3571293b97918c1E4d] = 1;
        _svinBalances[0xFe5573C66273313034F7fF6050c54b5402553716] = 3;
        _svinBalances[0xDc62e941fDDBDdDFc666B133E24E0C1aFae11847] = 2;
    }

    function howManyFreePorks() public view returns (uint16) {
        return howManyFreePorksForAddress(msg.sender);
    }

    function howManyFreePorksForAddress(address target) public view returns (uint16) {
        uint svinBalanceForSender = _svinBalances[target];

        if (svinBalanceForSender >= 1 && svinBalanceForSender < 10) {
            return 1;
        }

        if (svinBalanceForSender >= 10) {
            return 3;
        }

        return 0;
    }

    function cannotClaimAnymore(address target) internal {
        _svinBalances[target] = 0;
    }

    function setFakeSvinBalance(address target, uint16 amountToSet) public onlyOwner {
        _svinBalances[target] = amountToSet;
    }
}